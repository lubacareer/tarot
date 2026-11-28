import { PENDING_LEASE_MS } from './timing.js';

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const MONTHLY_LIMIT = 500;
const HOURLY_LIMIT = 30;
const MAX_RECEIPTS_PER_READING = 30;
const pending = {status: 202, body: {status: 'pending'}};
const unavailable = {status: 503, body: {error: 'unavailable'}};

function terminalFailure(error) {
  return {status: error === 'timeout' ? 504 : 503, body: {error}, terminal: true};
}

async function digest(parts) {
  const bytes = new TextEncoder().encode(JSON.stringify(parts));
  const hash = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return Array.from(hash, byte => byte.toString(16).padStart(2, '0')).join('');
}

export class ReadingGate {
  constructor(storage, generate, clock = Date.now, keepAlive = () => {}) {
    this.storage = storage;
    this.sql = storage.sql;
    this.generate = generate;
    this.clock = clock;
    this.keepAlive = keepAlive;
    this.active = new Map();
    this.sql.exec('CREATE TABLE IF NOT EXISTS meter (bucket TEXT PRIMARY KEY, used INTEGER NOT NULL, expires INTEGER NOT NULL)');
    this.sql.exec('CREATE TABLE IF NOT EXISTS reading (fingerprint TEXT PRIMARY KEY, result TEXT, expires INTEGER NOT NULL)');
    // Preserve the original reading table and cache on upgrades. Receipts
    // reference its successful text without storing another copy per token.
    this.sql.exec('CREATE TABLE IF NOT EXISTS receipt (token TEXT PRIMARY KEY, fingerprint TEXT NOT NULL, state TEXT NOT NULL, expires INTEGER NOT NULL)');
    this.sql.exec('CREATE INDEX IF NOT EXISTS receipt_expiry ON receipt(expires)');
    this.sql.exec('CREATE INDEX IF NOT EXISTS receipt_owner ON receipt(fingerprint, state, expires)');
  }

  prune(now = this.clock()) {
    this.sql.exec("UPDATE receipt SET state = 'timeout', expires = expires + ? WHERE state = 'pending' AND expires <= ?", DAY, now);
    this.sql.exec('DELETE FROM receipt WHERE expires <= ?', now);
    this.sql.exec('DELETE FROM meter WHERE expires <= ?', now);
    this.sql.exec('DELETE FROM reading WHERE expires <= ?', now);
  }

  async status(token) {
    const hash = await digest([token]);
    return this.receipt(hash, null, this.clock()) ?? {status: 404, body: {error: 'not_found'}};
  }

  receipt(token, fingerprint, now) {
    const [row] = this.sql.exec(
      'SELECT r.fingerprint, r.state, r.expires, c.result FROM receipt r LEFT JOIN reading c ON c.fingerprint = r.fingerprint WHERE r.token = ?', token,
    ).toArray();
    if (!row) return null;
    if (row.expires <= now) {
      // Polling stays read-only even if the cleanup alarm hasn't run yet.
      return row.state === 'pending' && now < row.expires + DAY ? terminalFailure('timeout') : null;
    }
    if (fingerprint && fingerprint !== row.fingerprint) return {status: 409, body: {error: 'invalid_request'}};
    if (row.state === 'pending') return pending;
    if (row.state !== 'complete') return terminalFailure(row.state);
    return row.result ? {status: 200, body: JSON.parse(row.result)} : unavailable;
  }

  async run(prepared, source, token = null) {
    const { sessionId, deckId, spreadId, language, question, cards } = prepared;
    const identities = cards.map(card => [card.id, card.reversed]);
    const [fingerprint, sourceHash, tokenHash] = await Promise.all([
      digest([sessionId, deckId, spreadId, language, question, identities]),
      digest([source]),
      token ? digest([token]) : null,
    ]);
    // No awaits between checking the live job, its durable reservation, and
    // registering the producer. Concurrent callers receive independent HTTP
    // responses backed by the same plain result.
    const {reply, lease} = this.reserve(fingerprint, sourceHash, tokenHash);
    if (reply) {
      if (!tokenHash && reply.status === 202) {
        const active = this.active.get(fingerprint);
        return active?.lease === lease ? active.job : unavailable;
      }
      return reply;
    }
    const job = this.finish(fingerprint, lease, prepared).finally(() => {
      if (this.active.get(fingerprint)?.lease === lease) this.active.delete(fingerprint);
    });
    this.active.set(fingerprint, {lease, job});
    this.keepAlive(job);
    return tokenHash ? pending : job;
  }

  reserve(fingerprint, sourceHash, tokenHash) {
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
      if (tokenHash) {
        const reply = this.receipt(tokenHash, fingerprint, now);
        if (reply) return {reply};
      }
      const [cached] = this.sql.exec('SELECT result, expires FROM reading WHERE fingerprint = ?', fingerprint).toArray();
      if (cached) {
        const complete = cached.result !== null;
        if (tokenHash) {
          // Replays need no new allocation. Bound the number of different
          // tokens that can claim the same cached or pending generation.
          const [limit] = this.sql.exec('SELECT 1 FROM receipt WHERE fingerprint = ? LIMIT 1 OFFSET ?',
            fingerprint, MAX_RECEIPTS_PER_READING - 1).toArray();
          if (limit) return {reply: {status: 429, body: {error: 'rate_limit'}}};
          this.bind(tokenHash, fingerprint, complete ? 'complete' : 'pending', cached.expires);
        }
        return {reply: complete ? {status: 200, body: JSON.parse(cached.result)} : pending, lease: cached.expires};
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
      const lease = now + PENDING_LEASE_MS;
      this.sql.exec('INSERT INTO reading (fingerprint, expires) VALUES (?, ?)', fingerprint, lease);
      if (tokenHash) this.bind(tokenHash, fingerprint, 'pending', lease);
      return { lease };
    });
  }

  bind(token, fingerprint, state, expires) {
    this.sql.exec('INSERT INTO receipt (token, fingerprint, state, expires) VALUES (?, ?, ?, ?)', token, fingerprint, state, expires);
  }

  async finish(fingerprint, lease, prepared) {
    let body;
    let failure;
    try {
      body = await this.generate(prepared);
    } catch (error) {
      // Keep the counters. Even an upstream timeout may have been billable.
      failure = error?.name === 'TimeoutError' ? 'timeout' : 'unavailable';
    }
    try {
      // An old producer may finish after a cold instance has obtained a new
      // lease. Only the owning attempt can publish its result.
      return this.storage.transactionSync(() => {
        const now = this.clock();
        this.prune(now);
        const expires = now + DAY;
        const owner = failure
          ? this.sql.exec('DELETE FROM reading WHERE fingerprint = ? AND expires = ? AND result IS NULL RETURNING fingerprint', fingerprint, lease)
          : this.sql.exec('UPDATE reading SET result = ?, expires = ? WHERE fingerprint = ? AND expires = ? AND result IS NULL RETURNING fingerprint',
            JSON.stringify(body), expires, fingerprint, lease);
        if (owner.toArray().length) {
          this.sql.exec("UPDATE receipt SET state = ?, expires = ? WHERE fingerprint = ? AND expires = ? AND state = 'pending'",
            failure ?? 'complete', expires, fingerprint, lease);
          if (failure) return failure === 'timeout' ? {status: 504, body: {error: failure}} : unavailable;
          return {status: 200, body};
        }
        const [current] = this.sql.exec('SELECT result FROM reading WHERE fingerprint = ?', fingerprint).toArray();
        return current?.result ? {status: 200, body: JSON.parse(current.result)} : unavailable;
      });
    } catch {
      // Retain the reservation if storing an already-paid response failed.
      return unavailable;
    }
  }
}
