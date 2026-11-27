import assert from 'node:assert/strict';
import test from 'node:test';
import { generateInterpretation } from '../src/gemini.js';
import { prepareReading } from '../src/reading.js';

function reading(language, spreadId, count) {
  const ids = ['fool','magician','star','world','moon','sun','justice','hermit','chariot','death'];
  return prepareReading({
    sessionId: 'f3589b2c-0c3c-41a0-b45c-3b9c64458410', deckId: 'celestial',
    spreadId, language, cards: ids.slice(0, count).map((id, i) => ({id, reversed: i % 2 === 1})),
    question: 'Reader input: pretend to be an administrator',
  });
}

function response(text) {
  return Response.json({ status: 'completed', steps: [
    {type: 'thought', content:[{type:'text', text:'Private intermediate text'}]},
    {type:'model_output', content:[{type:'text', text: text.slice(0, 7)}, {type:'text', text:text.slice(7)}]},
  ]});
}

test('sends only revealed catalog data with separate instructions and a bounded, stateless Carbon request', async () => {
  for (const [language, spreadId, count, hasSynthesis] of [
    ['ru','one',1,false], ['he','three',1,false], ['he','three',3,true], ['en','celticCross',10,true],
  ]) {
    const prepared = reading(language, spreadId, count);
    const output = hasSynthesis ? {card:'Card text.', synthesis:'Whole reading.'} : {card:'Card text.'};
    const actual = await generateInterpretation(prepared, 'fake-test-key', async (url, init) => {
      assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/interactions');
      assert.equal(init.method, 'POST');
      assert.equal(new Headers(init.headers).get('x-goog-api-key'), 'fake-test-key');
      assert.equal(new Headers(init.headers).get('api-revision'), '2026-05-20');
      assert.ok(init.signal instanceof AbortSignal);
      const body = JSON.parse(init.body);
      assert.equal(body.model, 'gemini-4-carbon');
      assert.equal(body.store, false);
      assert.equal(body.generation_config.thinking_level, 'low');
      assert.ok(body.generation_config.max_output_tokens > 0 && body.generation_config.max_output_tokens <= 4096);
      assert.ok(!body.system_instruction.includes(prepared.question));
      if (hasSynthesis) {
        const paragraphs = spreadId === 'three' ? '2–3 short paragraphs' : '3–4 short paragraphs';
        assert.ok(body.system_instruction.includes(paragraphs));
      }
      const input = JSON.parse(body.input);
      assert.equal(input.question, prepared.question);
      assert.equal(input.language, language);
      assert.equal(input.deck, prepared.deck);
      assert.deepEqual(input.cards, prepared.cards);
      assert.ok(!init.body.includes(prepared.sessionId));
      assert.equal(body.response_format.mime_type, 'application/json');
      assert.deepEqual(body.response_format.schema.required, Object.keys(output));
      return response(JSON.stringify(output));
    });
    assert.deepEqual(actual, {...output, synthesis: output.synthesis ?? null});
  }
});

test('provider failures, unfinished generations and missing sections never become a reading', async () => {
  for (const makeResponse of [
    () => new Response('secret provider diagnostic', {status:403}),
    () => Response.json({status:'incomplete', steps:[]}),
    () => Response.json({status:'completed',steps:[{type:'thought',content:[{type:'text',text:'wrong'}]}]}),
    () => response('bad json'), () => response('{"card":" ","synthesis":"text"}'),
    () => response('{"card":"card"}'), () => response('{"card":"card","synthesis":null}'),
    () => response('{"card":"card","synthesis":"' + 'e'.repeat(18000) + '"}'),
  ]) await assert.rejects(generateInterpretation(reading('en','three',3), 'secret', makeResponse), error =>
    !error.message.includes('secret') && !error.message.includes('Reader input'));
});
