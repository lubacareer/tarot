const BODY_LIMIT = 16 * 1024;

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

export async function handleRequest(request, env, prepare) {
  if (new URL(request.url).pathname !== '/v1/interpret') return json({error: 'invalid_request'}, 404);
  if (request.method !== 'POST') return json({error: 'invalid_request'}, 405, {Allow: 'POST'});
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
  try {
    const stub = env.READINGS.getByName('monthly-shared-service');
    return await stub.fetch(new Request('https://readings.internal/', {
      method: 'POST', body: JSON.stringify({prepared, source}),
    }));
  } catch {
    return json({error: 'unavailable'}, 503);
  }
}
