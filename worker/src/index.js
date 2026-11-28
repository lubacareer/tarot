import { ReadingGate } from './gate.js';
import { generateInterpretation } from './gemini.js';
import { handleRequest, json } from './http.js';
import { prepareReading } from './reading.js';

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
    if (await this.storage.getAlarm() === null) {
      await this.storage.setAlarm(Date.now() + 24 * 60 * 60 * 1000);
    }
    return this.response(await this.gate.run(prepared, source, token));
  }

  response({status, body, terminal}) {
    return json(body, status, terminal ? {'X-Reading-State': 'terminal'} : {});
  }

  async alarm() {
    this.gate.prune();
    const [row] = this.storage.sql.exec(
      'SELECT MIN(expires) AS next FROM (SELECT expires FROM reading UNION ALL SELECT expires FROM meter UNION ALL SELECT expires FROM receipt)',
    ).toArray();
    if (row.next !== null) {
      await this.storage.setAlarm(Math.min(row.next, Date.now() + 24 * 60 * 60 * 1000));
    }
  }
}
