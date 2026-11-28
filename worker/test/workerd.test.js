import assert from 'node:assert/strict';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';

async function localWorker(t, outboundService) {
  const bundle = await build({
    entryPoints: [fileURLToPath(new URL('../src/index.js', import.meta.url))],
    bundle: true, format: 'esm', write: false,
  });
  const service = new Miniflare(convertV4MiniflareOptions({
    cf: false,
    modules: true,
    script: bundle.outputFiles[0].text,
    compatibilityDate: '2026-11-25',
    durableObjects: { READINGS: {className: 'ReadingService', useSQLite: true} },
    bindings: { GEMINI_API_KEY: 'offline-test-key' },
    outboundService,
  }));
  t.after(() => service.dispose());
  return service;
}

test('the packaged Worker serves a reading through its real SQLite Durable Object', async t => {
  let paidCalls = 0;
  const service = await localWorker(t, async request => {
    assert.equal(request.url, 'https://generativelanguage.googleapis.com/v1beta/interactions');
    assert.equal(request.headers.get('x-goog-api-key'), 'offline-test-key');
    const prompt = await request.json();
    assert.equal(prompt.model, 'gemini-4-carbon');
    assert.equal(prompt.store, false);
    paidCalls++;
    return Response.json({
      status: 'completed',
      steps: [{type: 'model_output', content: [{type: 'text', text: JSON.stringify({card: 'A specific reading.'})}]}],
    });
  });
  const payload = {
    sessionId: crypto.randomUUID(), language: 'en', deckId: 'celestial', spreadId: 'one',
    question: '', cards: [{id: 'fool', reversed: true}],
  };
  const send = () => service.dispatchFetch('https://tarot.example/v1/interpret', {
    method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify(payload),
  });
  const expected = {card: 'A specific reading.', synthesis: null};
  for (const reply of await Promise.all([send(), send()])) {
    assert.equal(reply.status, 200);
    assert.deepEqual(await reply.json(), expected);
  }
  assert.equal(paidCalls, 1);
});

test('a short submission returns before Gemini finishes and a status request retrieves the same job', async t => {
  const release = Promise.withResolvers();
  const started = Promise.withResolvers();
  let calls = 0;
  const service = await localWorker(t, async request => {
    calls++;
    if (JSON.parse((await request.json()).input).question === 'Timeout fixture') {
      return new Response(null, {status: 504});
    }
    started.resolve();
    await release.promise;
    return Response.json({status: 'completed', steps: [
      {type: 'model_output', content: [{type: 'text', text: '{"card":"Finished"}'}]},
    ]});
  });
  const url = 'https://tarot.example/v1/interpret';
  const headers = {'X-Reading-Token': crypto.randomUUID()};
  const payload = {sessionId: crypto.randomUUID(), language: 'en', deckId: 'celestial', spreadId: 'one',
    cards: [{id: 'fool', reversed: false}]};
  const status = () => service.dispatchFetch(url + '/status', {headers});
  const send = (question = '') => service.dispatchFetch(url, {
    method: 'POST', headers: {...headers, 'content-type': 'application/json'},
    body: JSON.stringify({...payload, question}),
  });
  assert.equal((await service.dispatchFetch(url + '/status')).status, 400);
  assert.equal((await status()).status, 404);
  let watchdog;
  try {
    // An implementation that waits for Gemini must fail instead of hanging this test.
    watchdog = setTimeout(() => release.resolve(), 2500);
    const accepted = await send();
    assert.equal(accepted.status, 202);
    assert.deepEqual(await accepted.json(), {status: 'pending'});
    await started.promise;
    assert.equal((await send('Changed')).status, 409);
    assert.equal((await status()).status, 202);
    assert.equal((await send()).status, 202);
  } finally {
    clearTimeout(watchdog);
    release.resolve();
  }
  const reply = await waitForResult(status);
  assert.equal(reply.status, 200);
  assert.equal(reply.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await reply.json(), {card: 'Finished', synthesis: null});
  assert.equal(calls, 1);
  headers['X-Reading-Token'] = crypto.randomUUID();
  assert.equal((await send('Timeout fixture')).status, 202);
  const timeout = await waitForResult(status);
  assert.equal(timeout.status, 504);
  assert.equal(timeout.headers.get('x-reading-state'), 'terminal');
  assert.deepEqual(await timeout.json(), {error: 'timeout'});
  assert.equal((await send('Timeout fixture')).status, 504);
  assert.equal(calls, 2);
});

async function waitForResult(status) {
  for (let i = 0; i < 80; i++) {
    const reply = await status();
    if (reply.status !== 202) return reply;
    await reply.arrayBuffer();
    await new Promise(resolve => setTimeout(resolve, 20));
  }
  assert.fail('The local provider completed but the job stayed pending');
}

test('a generation survives over 105 seconds with no client requests', {timeout: 150_000}, async t => {
  // workerd can evict a quiet object even though a provider promise is
  // outstanding. A fake clock or frequent status checks would hide this.
  const providerReturned = Promise.withResolvers();
  let calls = 0;
  const service = await localWorker(t, async request => {
    await request.arrayBuffer();
    calls++;
    await new Promise(resolve => setTimeout(resolve, 110_000));
    providerReturned.resolve();
    return Response.json({status: 'completed', steps: [
      {type: 'model_output', content: [{type: 'text', text: '{"card":"Original result"}'}]},
    ]});
  });
  const url = 'https://tarot.example/v1/interpret';
  const headers = {'X-Reading-Token': crypto.randomUUID()};
  const accepted = await service.dispatchFetch(url, {
    method: 'POST', headers: {...headers, 'content-type': 'application/json'},
    body: JSON.stringify({sessionId: crypto.randomUUID(), language: 'en', deckId: 'celestial',
      spreadId: 'one', cards: [{id: 'fool', reversed: false}]}),
  });
  assert.equal(accepted.status, 202);
  await accepted.arrayBuffer();
  await providerReturned.promise;
  const result = await waitForResult(() => service.dispatchFetch(url + '/status', {headers}));
  assert.equal(result.status, 200);
  assert.deepEqual(await result.json(), {card: 'Original result', synthesis: null});
  assert.equal(calls, 1);
});
