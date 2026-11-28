import { ReadingGate } from './gate.js';
import { generateInterpretation } from './gemini.js';
import { handleRequest, json } from './http.js';
import { prepareReading } from './reading.js';

const HEARTBEAT_MS = 30_000;
const DAY_MS = 24 * 60 * 60 * 1000;

export default {
  fetch(request, env) {
    return handleRequest(request, env, prepareReading);
  },
};

export class ReadingService {
  constructor(ctx, env) {
    this.storage = ctx.storage;
    this.gate = new ReadingGate(ctx.storage, prepared => generateInterpretation(prepared, env.GEMINI_API_KEY),
      Date.now, job => ctx.waitUntil(job));
  }

  async fetch(request) {
    const {prepared, source, token} = await request.json();
    if (!prepared) return this.response(await this.gate.status(token));
    // Arm a wakeup before dispatch, including when a daily cleanup was
    // already scheduled. A mobile client may disappear as soon as it submits.
    const wakeBy = Date.now() + HEARTBEAT_MS;
    const alarm = await this.storage.getAlarm();
    if (alarm === null || alarm > wakeBy) {
      await this.storage.setAlarm(wakeBy);
    }
    return this.response(await this.gate.run(prepared, source, token));
  }

  response({status, body, terminal}) {
    return json(body, status, terminal ? {'X-Reading-State': 'terminal'} : {});
  }

  async alarm() {
    this.gate.prune();
    const [row] = this.storage.sql.exec(
      `SELECT MIN(expires) AS next,
              EXISTS (SELECT 1 FROM reading WHERE result IS NULL) AS pending
       FROM (SELECT expires FROM reading UNION ALL SELECT expires FROM meter UNION ALL SELECT expires FROM receipt)`,
    ).toArray();
    if (row.next !== null) {
      // Each alarm is a fresh event while work is pending. It keeps a quiet
      // object active without storing the question or dispatching another call.
      const interval = row.pending ? HEARTBEAT_MS : DAY_MS;
      await this.storage.setAlarm(Math.min(row.next, Date.now() + interval));
    }
  }
}
