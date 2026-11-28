const BODY_LIMIT = 16 * 1024;
const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function json(body, status = 200, headers = {}) {
  return Response.json(body, {status, headers: {'Cache-Control': 'no-store', ...headers}});
}

async function readBody(request) {
  const reader = request.body?.getReader();
  if (!reader) return {status: 400};
  const chunks = [];
  let length = 0;
  try {
    while (true) {
      const {done, value} = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > BODY_LIMIT) {
        await reader.cancel();
        return {status: 413};
      }
      chunks.push(value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.byteLength;
    }
    return {payload: JSON.parse(new TextDecoder('utf-8', {fatal: true}).decode(bytes))};
  } catch {
    return {status: 400};
  } finally {
    reader.releaseLock();
  }
}

async function forward(env, data) {
  try {
    const stub = env.READINGS.getByName('monthly-shared-service');
    return await stub.fetch(new Request('https://readings.internal/', {
      method: 'POST', body: JSON.stringify(data),
    }));
  } catch {
    // The DO may already own a submission. Only a durable receipt may mark
    // the response terminal and authorize a fresh paid attempt.
    return json({error: 'unavailable'}, 503);
  }
}

export async function handleRequest(request, env, prepare) {
  const path = new URL(request.url).pathname;
  const lookup = path === '/v1/interpret/status';
  if (!lookup && path !== '/v1/interpret') return json({error: 'invalid_request'}, 404);
  const method = lookup ? 'GET' : 'POST';
  if (request.method !== method) return json({error: 'invalid_request'}, 405, {Allow: method});
  const token = request.headers.get('X-Reading-Token')?.toLowerCase() ?? null;
  if (token !== null && !UUID_V4.test(token)) return json({error: 'invalid_request'}, 400);
  if (lookup) return token ? forward(env, {token}) : json({error: 'invalid_request'}, 400);
  const type = request.headers.get('content-type')?.split(';', 1)[0].trim().toLowerCase();
  if (type !== 'application/json') return json({error: 'invalid_request'}, 415);
  const {status, payload} = await readBody(request);
  if (status) return json({error: 'invalid_request'}, status);
  let prepared;
  try {
    prepared = prepare(payload);
  } catch {
    return json({error: 'invalid_request'}, 400);
  }
  if (!env.GEMINI_API_KEY) return json({error: 'unavailable'}, 503);

  // This header is supplied by Cloudflare's edge. Sources without it share
  // a single bucket, including local development traffic.
  const source = request.headers.get('CF-Connecting-IP') || 'unknown';
  return forward(env, {prepared, source, token});
}
