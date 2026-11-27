const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const LEASE = 120 * 1000;
const MONTHLY_LIMIT = 500;
const HOURLY_LIMIT = 30;

async function digest(parts) {
  const bytes = new TextEncoder().encode(JSON.stringify(parts));
  const hash = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return Array.from(hash, byte => byte.toString(16).padStart(2, '0')).join('');
}

export class ReadingGate {
  constructor(storage, generate, clock = Date.now) {
    this.storage = storage;
    this.sql = storage.sql;
    this.generate = generate;
    this.clock = clock;
    this.active = new Map();
    this.sql.exec('CREATE TABLE IF NOT EXISTS meter (bucket TEXT PRIMARY KEY, used INTEGER NOT NULL, expires INTEGER NOT NULL)');
    this.sql.exec('CREATE TABLE IF NOT EXISTS reading (fingerprint TEXT PRIMARY KEY, result TEXT, expires INTEGER NOT NULL)');
  }

  prune(now = this.clock()) {
    this.sql.exec('DELETE FROM meter WHERE expires <= ?', now);
    this.sql.exec('DELETE FROM reading WHERE expires <= ?', now);
  }

  async run(prepared, source) {
    const { sessionId, deckId, spreadId, language, question, cards } = prepared;
    const identities = cards.map(card => [card.id, card.reversed]);
    const [fingerprint, sourceHash] = await Promise.all([
      digest([sessionId, deckId, spreadId, language, question, identities]),
      digest([source]),
    ]);
    // No awaits between checking the live job, its durable reservation, and
    // registering the producer. Concurrent callers receive independent HTTP
    // responses backed by the same plain result.
    const active = this.active.get(fingerprint);
    if (active) return active;
    const { reply, lease } = this.reserve(fingerprint, sourceHash);
    if (reply) return reply;
    const job = this.finish(fingerprint, lease, prepared);
    this.active.set(fingerprint, job);
    try {
      return await job;
    } finally {
      this.active.delete(fingerprint);
    }
  }

  reserve(fingerprint, sourceHash) {
    return this.storage.transactionSync(() => {
      const now = this.clock();
      const date = new Date(now);
      const nextMonth = Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1);
      const nextHour = (Math.floor(now / HOUR) + 1) * HOUR;
      const buckets = [
        { key: 'month:' + nextMonth, expires: nextMonth, limit: MONTHLY_LIMIT, error: 'quota' },
        { key: 'hour:' + nextHour + ':' + sourceHash, expires: nextHour, limit: HOURLY_LIMIT, error: 'rate_limit' },
      ];
      this.prune(now);
      const [cached] = this.sql.exec('SELECT result FROM reading WHERE fingerprint = ?', fingerprint).toArray();
      if (cached) {
        // A pending row with no local producer can survive a Worker restart.
        // Let its lease expire before allowing another paid attempt.
        const reply = cached.result === null
          ? { status: 503, body: { error: 'unavailable' } }
          : { status: 200, body: JSON.parse(cached.result) };
        return { reply };
      }
      for (const bucket of buckets) {
        const [row] = this.sql.exec('SELECT used FROM meter WHERE bucket = ?', bucket.key).toArray();
        if (row && row.used >= bucket.limit) {
          return { reply: { status: 429, body: { error: bucket.error } } };
        }
      }
      for (const bucket of buckets) {
        this.sql.exec(
          'INSERT INTO meter (bucket, used, expires) VALUES (?, 1, ?) ON CONFLICT(bucket) DO UPDATE SET used = used + 1',
          bucket.key, bucket.expires,
        );
      }
      const lease = now + LEASE;
      this.sql.exec('INSERT INTO reading (fingerprint, expires) VALUES (?, ?)', fingerprint, lease);
      return { lease };
    });
  }

  async finish(fingerprint, lease, prepared) {
    let body;
    try {
      body = await this.generate(prepared);
    } catch {
      // Keep the counters. Even an upstream timeout may have been billable.
      this.sql.exec('DELETE FROM reading WHERE fingerprint = ? AND expires = ? AND result IS NULL', fingerprint, lease);
      return { status: 503, body: { error: 'unavailable' } };
    }
    try {
      // An old producer may finish after a cold instance has obtained a new
      // lease. Only the owning attempt can publish its result.
      const [written] = this.sql.exec(
        'UPDATE reading SET result = ?, expires = ? WHERE fingerprint = ? AND expires = ? AND result IS NULL RETURNING fingerprint',
        JSON.stringify(body), this.clock() + DAY, fingerprint, lease,
      ).toArray();
      if (written) return { status: 200, body };
      const [current] = this.sql.exec('SELECT result FROM reading WHERE fingerprint = ?', fingerprint).toArray();
      if (current?.result) return { status: 200, body: JSON.parse(current.result) };
    } catch {
      // Retain the reservation if storing an already-paid response failed.
      return { status: 503, body: { error: 'unavailable' } };
    }
    return { status: 503, body: { error: 'unavailable' } };
  }
}
