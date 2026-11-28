import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';
import { ReadingGate } from '../src/gate.js';
import { handleRequest } from '../src/http.js';
import { ReadingService } from '../src/index.js';

// Execute the same SQLite statements used by the Durable Object against an
// in-memory database, including commit and rollback of each quota reservation.
function storage() {
  const db = new DatabaseSync(':memory:');
  return {
    sql: {
      exec(statement, ...values) {
        const rows = db.prepare(statement).all(...values);
        return { toArray: () => rows };
      },
    },
    transactionSync(fn) {
      db.exec('BEGIN');
      try {
        const value = fn();
        db.exec('COMMIT');
        return value;
      } catch (error) {
        db.exec('ROLLBACK');
        throw error;
      }
    },
  };
}

const words = { card: 'One reading', synthesis: null };
function reading(id, language = 'en') {
  return { sessionId: String(id), language, deckId: 'celestial', spreadId: 'one',
    question: '', cards: [{ id: 'the-fool', reversed: false }] };
}

test('overlapping requests and a later cold instance reuse a successful response', async () => {
  const database = storage();
  const started = Promise.withResolvers();
  const upstream = Promise.withResolvers();
  let calls = 0;
  const generate = async () => { calls++; started.resolve(); return upstream.promise; };
  const gate = new ReadingGate(database, generate);
  const a = gate.run(reading(1), 'reader');
  await started.promise;
  const b = gate.run(reading(1), 'reader');
  upstream.resolve(words);
  assert.deepEqual(await Promise.all([a, b]), [
    {status: 200, body: words}, {status: 200, body: words},
  ]);
  const reopened = new ReadingGate(database, generate);
  assert.deepEqual((await reopened.run(reading(1), 'reader')).body, words);
  assert.equal(calls, 1);
  await reopened.run(reading(1, 'he'), 'reader');
  await reopened.run({...reading(1), question: 'A different question'}, 'reader');
  await reopened.run({...reading(1), cards: [{id: 'the-fool', reversed: true}]}, 'reader');
  assert.equal(calls, 4);
});

test('an orphaned upstream attempt fails closed during its lease', async () => {
  const database = storage();
  const started = Promise.withResolvers();
  const upstream = Promise.withResolvers();
  const first = new ReadingGate(database, () => { started.resolve(); return upstream.promise; });
  const a = first.run(reading(1), 'reader');
  await started.promise;
  const next = new ReadingGate(database, () => assert.fail('duplicate upstream attempt'));
  assert.equal((await next.run(reading(1), 'reader')).status, 503);
  upstream.resolve(words);
  await a;
});

test('accepted receipts bind the token to a reading and status never triggers generation', async () => {
  const database = storage();
  const upstream = Promise.withResolvers();
  const jobs = [];
  let calls = 0;
  const gate = new ReadingGate(database, () => { calls++; return upstream.promise; }, Date.now, job => jobs.push(job));
  const token = crypto.randomUUID();
  const other = crypto.randomUUID();
  const pending = {status: 202, body: {status: 'pending'}};
  assert.equal((await gate.status(token)).status, 404);
  const replies = await Promise.all([token, token, other].map(id => gate.run(reading(1), 'reader', id)));
  assert.deepEqual(replies, [pending, pending, pending]);
  assert.equal((await gate.run(reading(2), 'reader', token)).status, 409);
  const cold = new ReadingGate(database, () => assert.fail('status dispatched a new job'));
  assert.deepEqual(await cold.status(other), pending);
  assert.equal(jobs.length, 1);
  upstream.resolve(words);
  await Promise.all(jobs);
  for (const id of [token, other]) assert.deepEqual(await cold.status(id), {status: 200, body: words});
  assert.equal(calls, 1);
  assert.equal(database.sql.exec("SELECT used FROM meter WHERE bucket LIKE 'month:%'").toArray()[0].used, 1);
  for (const row of database.sql.exec('SELECT token FROM receipt').toArray()) {
    assert.match(row.token, /^[a-f0-9]{64}$/);
    assert.notEqual(row.token, token);
  }
});

test('a restart turns an expired 210-second lease into a terminal timeout for its original tokens', async () => {
  const database = storage();
  let now = 0;
  const jobs = [];
  const upstream = Promise.withResolvers();
  const first = new ReadingGate(database, () => upstream.promise, () => now, job => jobs.push(job));
  const token = crypto.randomUUID();
  assert.equal((await first.run(reading(1), 'reader', token)).status, 202);
  const cold = new ReadingGate(database, async () => words, () => now);
  now = 209_999;
  assert.equal((await cold.status(token)).status, 202);
  now++;
  assert.deepEqual((await cold.status(token)).body, {error: 'timeout'});
  assert.equal((await cold.run(reading(1), 'reader', token)).status, 504);
  assert.equal((await cold.run(reading(1), 'reader')).status, 200);
  upstream.resolve({card: 'Stale', synthesis: null});
  await Promise.all(jobs);
  assert.equal((await cold.status(token)).status, 504);
  now += 86_400_000;
  assert.equal((await cold.status(token)).status, 404);
});

test('polling an unknown token performs only a keyed read', async () => {
  const database = storage();
  const gate = new ReadingGate(database, () => assert.fail('poll generated a reading'));
  const exec = database.sql.exec;
  database.sql.exec = (query, ...values) => {
    assert.match(query, /^SELECT /);
    return exec(query, ...values);
  };
  assert.deepEqual(await gate.status(crypto.randomUUID()), {status: 404, body: {error: 'not_found'}});
});

test('a cached reading cannot create unlimited receipts, and existing tokens still replay', async () => {
  const database = storage();
  const jobs = [];
  const gate = new ReadingGate(database, async () => words, Date.now, job => jobs.push(job));
  const original = crypto.randomUUID();
  assert.equal((await gate.run(reading(1), 'reader', original)).status, 202);
  await jobs[0];
  for (let i = 1; i < 30; i++) {
    assert.equal((await gate.run(reading(1), 'reader', crypto.randomUUID())).status, 200);
  }
  const refused = crypto.randomUUID();
  assert.deepEqual(await gate.run(reading(1), 'reader', refused), {status: 429, body: {error: 'rate_limit'}});
  assert.equal((await gate.status(refused)).status, 404);
  assert.equal((await gate.run(reading(1), 'reader', original)).status, 200);
});

for (const [cause, status] of [[new DOMException('timeout', 'TimeoutError'), 504], [Error('failed'), 503]]) {
  test(`an upstream ${status} is terminal per token, and a new attempt can succeed`, async () => {
    const jobs = [];
    let calls = 0;
    const generate = async () => { if (++calls === 1) throw cause; return words; };
    const gate = new ReadingGate(storage(), generate, Date.now, job => jobs.push(job));
    const token = crypto.randomUUID();
    const replacement = crypto.randomUUID();
    assert.equal((await gate.run(reading(1), 'reader', token)).status, 202);
    await jobs[0];
    assert.equal((await gate.run(reading(1), 'reader', token)).status, status);
    assert.equal((await gate.run(reading(1), 'reader', replacement)).status, 202);
    await jobs[1];
    assert.equal((await gate.status(token)).status, status);
    assert.deepEqual((await gate.status(replacement)).body, words);
    assert.equal(calls, 2);
  });
}

test('the UTC monthly cap is shared across sources and cannot be overshot concurrently', async () => {
  let now = Date.UTC(2026, 0, 31, 23, 59);
  let calls = 0;
  const gate = new ReadingGate(storage(), async () => { calls++; return words; }, () => now);
  const results = await Promise.all(Array.from({length: 502}, (_, i) => gate.run(reading(i), String(i))));
  assert.equal(results.filter(x => x.status === 200).length, 500);
  assert.equal(results.filter(x => x.body.error === 'quota').length, 2);
  assert.equal(calls, 500);
  now += 60_000;
  assert.equal((await gate.run(reading(503), 'reader')).status, 200);
  assert.equal(calls, 501);
});

test('a failed durable cache write keeps the paid reservation during recovery', async () => {
  const database = storage();
  const exec = database.sql.exec;
  database.sql.exec = (statement, ...values) => {
    if (statement.startsWith('UPDATE reading SET result')) throw Error('Unavailable');
    return exec(statement, ...values);
  };
  let calls = 0;
  const generate = async () => { calls++; return words; };
  assert.equal((await new ReadingGate(database, generate).run(reading(1), 'reader')).status, 503);
  assert.equal((await new ReadingGate(database, generate).run(reading(1), 'reader')).status, 503);
  assert.equal(calls, 1);
});

test('a late producer cannot replace a successful second attempt after its lease expires', async () => {
  const database = storage();
  let now = 0;
  const started = Promise.withResolvers();
  const upstream = Promise.withResolvers();
  const first = new ReadingGate(database, () => { started.resolve(); return upstream.promise; }, () => now);
  const pending = first.run(reading(1), 'reader');
  await started.promise;
  now += 211_000;
  const second = new ReadingGate(database, async () => words, () => now);
  assert.deepEqual((await second.run(reading(1), 'reader')).body, words);
  upstream.resolve({card: 'Old producer', synthesis: null});
  await pending;
  assert.deepEqual((await second.run(reading(1), 'reader')).body, words);
});

test('failed upstream attempts count against the hourly source limit, and retries can recover', async () => {
  let now = Date.UTC(2026, 0, 1, 0, 59);
  let calls = 0;
  const gate = new ReadingGate(storage(), async () => {
    if (++calls === 1) throw Error('private text');
    return words;
  }, () => now);
  assert.deepEqual(await gate.run(reading(1), 'source'), {status: 503, body: {error: 'unavailable'}});
  for (let i = 1; i < 30; i++) assert.equal((await gate.run(reading(i), 'source')).status, 200);
  assert.equal((await gate.run(reading(30), 'source')).body.error, 'rate_limit');
  assert.equal((await gate.run(reading(1), 'source')).status, 200);
  assert.equal((await gate.run(reading(31), 'other')).status, 200);
  now += 60_000;
  assert.equal((await gate.run(reading(30), 'source')).status, 200);
});

test('only a bounded JSON POST is sent to the single shared meter', async () => {
  let visits = 0;
  const env = { GEMINI_API_KEY: 'fake', READINGS: { getByName(name) {
    assert.equal(name, 'monthly-shared-service');
    return {async fetch(request) {
      visits++;
      const data = await request.json();
      assert.deepEqual(data.prepared, reading(1));
      assert.equal(data.source, '198.51.100.10');
      return Response.json(words);
    }};
  }} };
  const url = 'https://arcana.example/v1/interpret';
  const send = (body, options = {}) => handleRequest(new Request(url, {
    method: 'POST', headers: { 'content-type': 'application/json', 'cf-connecting-ip': '198.51.100.10',
      'x-forwarded-for': 'spoofed' }, body, ...options,
  }), env, value => { if (!value.sessionId) throw Error('Invalid'); return value; });
  assert.equal((await handleRequest(new Request(url), env)).status, 405);
  assert.equal((await handleRequest(new Request(url + '/other'), env)).status, 404);
  for (const token of ['', 'invalid', '12345678-1234-1234-1234-123456789012']) {
    assert.equal((await handleRequest(new Request(url + '/status', {headers: {'X-Reading-Token': token}}), env)).status, 400);
  }
  assert.equal((await send('{bad')).status, 400);
  assert.equal((await send('{}')).status, 400);
  assert.equal((await send('{}', { headers: {'content-type': 'text/plain'} })).status, 415);
  assert.equal((await send('x'.repeat(17_000))).status, 413);
  assert.equal((await send(JSON.stringify(reading(1)))).status, 200);
  assert.equal(visits, 1);
  const lostConnection = {READINGS: {getByName() { throw Error('Binding disconnected'); }}};
  const uncertain = await handleRequest(new Request(url + '/status', {
    headers: {'X-Reading-Token': crypto.randomUUID()},
  }), lostConnection);
  assert.equal(uncertain.status, 503);
  assert.equal(uncertain.headers.get('x-reading-state'), null);
});

test('an hour rollover during hashing cannot create two buckets for the same source and hour', async () => {
  const after = Date.UTC(2026, 1, 5, 9);
  let now = after - 1;
  const database = storage();
  const transaction = database.transactionSync;
  database.transactionSync = work => {
    now = after;
    return transaction(work);
  };
  const gate = new ReadingGate(database, async () => words, () => now);
  await gate.run(reading(0), 'reader');
  for (let i = 1; i < 30; i++) await gate.run(reading(i), 'reader');
  assert.equal((await gate.run(reading(30), 'reader')).body.error, 'rate_limit');
});

test('cleanup wakes for the first cached reading to expire even when a month counter remains', async () => {
  const database = storage();
  let alarm;
  database.setAlarm = async value => { alarm = value; };
  const service = new ReadingService({storage: database}, {});
  const expiry = Date.now() + 600_000;
  database.sql.exec('INSERT INTO reading VALUES (?, ?, ?)', 'result', JSON.stringify(words), expiry);
  database.sql.exec('INSERT INTO meter VALUES (?, ?, ?)', 'month', 1, expiry + 3 * 86_400_000);
  await service.alarm();
  assert.equal(alarm, expiry);
});
