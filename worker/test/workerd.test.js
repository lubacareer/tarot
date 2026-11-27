import assert from 'node:assert/strict';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';

test('the packaged Worker serves a reading through its real SQLite Durable Object', async t => {
  const bundle = await build({
    entryPoints: [fileURLToPath(new URL('../src/index.js', import.meta.url))],
    bundle: true, format: 'esm', write: false,
  });
  let paidCalls = 0;
  const service = new Miniflare(convertV4MiniflareOptions({
    cf: false,
    modules: true,
    script: bundle.outputFiles[0].text,
    compatibilityDate: '2026-11-25',
    durableObjects: { READINGS: {className: 'ReadingService', useSQLite: true} },
    bindings: { GEMINI_API_KEY: 'offline-test-key' },
    outboundService: async request => {
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
    },
  }));
  t.after(() => service.dispose());
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
