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
    this.gate = new ReadingGate(ctx.storage, prepared => generateInterpretation(prepared, env.GEMINI_API_KEY));
  }

  async fetch(request) {
    const {prepared, source} = await request.json();
    if (await this.storage.getAlarm() === null) {
      await this.storage.setAlarm(Date.now() + 24 * 60 * 60 * 1000);
    }
    const {status, body} = await this.gate.run(prepared, source);
    return json(body, status);
  }

  async alarm() {
    this.gate.prune();
    const [row] = this.storage.sql.exec(
      'SELECT MIN(expires) AS next FROM (SELECT expires FROM reading UNION ALL SELECT expires FROM meter)',
    ).toArray();
    if (row.next !== null) {
      await this.storage.setAlarm(Math.min(row.next, Date.now() + 24 * 60 * 60 * 1000));
    }
  }
}
