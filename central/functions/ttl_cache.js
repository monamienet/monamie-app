/**
 * A small in-memory cache whose entries expire after `ttlMs`. Each function
 * instance has its own; it only spares repeated calls in a short window.
 */
class TtlCache {
  constructor(ttlMs, now = Date.now) {
    this._ttlMs = ttlMs;
    this._now = now;
    this._entries = new Map();
  }

  /**
   * Returns the cached value of `key`, or computes, stores and returns it.
   * Failures are not cached.
   */
  async getOrCompute(key, compute) {
    const entry = this._entries.get(key);
    if (entry && entry.expires > this._now()) return entry.value;
    const value = await compute();
    this._entries.set(key, { value, expires: this._now() + this._ttlMs });
    return value;
  }
}

module.exports = { TtlCache };
