/**
 * Transaction computation cache
 * Caches expensive calculations like balance computations
 */

import type { CacheEntry, CacheOptions, CacheStats } from './types';

export class TransactionCache {
  private cache = new Map<string, CacheEntry>();
  private readonly defaultTTL = 5 * 60 * 1000; // 5 minutes
  private stats = {
    hits: 0,
    misses: 0,
  };

  /**
   * Get cached value
   */
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);

    if (!entry) {
      this.stats.misses++;
      return null;
    }

    // Check if expired
    if (Date.now() > entry.expires) {
      this.cache.delete(key);
      this.stats.misses++;
      return null;
    }

    this.stats.hits++;
    return entry.data as T;
  }

  /**
   * Set cached value
   */
  set<T>(key: string, data: T, options: CacheOptions = {}): void {
    const ttl = options.ttl || this.defaultTTL;
    const prefix = options.prefix || '';
    const fullKey = prefix ? `${prefix}:${key}` : key;

    this.cache.set(fullKey, {
      data,
      expires: Date.now() + ttl,
      createdAt: Date.now(),
    });
  }

  /**
   * Check if key exists and is valid
   */
  has(key: string): boolean {
    const entry = this.cache.get(key);
    if (!entry) return false;

    if (Date.now() > entry.expires) {
      this.cache.delete(key);
      return false;
    }

    return true;
  }

  /**
   * Invalidate cache entries matching pattern
   */
  invalidate(pattern: string): number {
    let deleted = 0;

    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
        deleted++;
      }
    }

    return deleted;
  }

  /**
   * Invalidate all entries for a specific account
   */
  invalidateAccount(accountId: string): number {
    return this.invalidate(`account_${accountId}`);
  }

  /**
   * Clear all cache
   */
  clear(): void {
    this.cache.clear();
    this.stats.hits = 0;
    this.stats.misses = 0;
  }

  /**
   * Clean up expired entries
   */
  cleanup(): number {
    let deleted = 0;
    const now = Date.now();

    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expires) {
        this.cache.delete(key);
        deleted++;
      }
    }

    return deleted;
  }

  /**
   * Get cache statistics
   */
  getStats(): CacheStats {
    const total = this.stats.hits + this.stats.misses;
    const hitRate = total > 0 ? (this.stats.hits / total) * 100 : 0;

    return {
      hits: this.stats.hits,
      misses: this.stats.misses,
      size: this.cache.size,
      hitRate: Number(hitRate.toFixed(2)),
    };
  }

  /**
   * Get cache size in bytes (approximate)
   */
  getSize(): number {
    return this.cache.size;
  }
}

// Export singleton instance
export const transactionCache = new TransactionCache();

// Run cleanup every 5 minutes
if (typeof window !== 'undefined') {
  setInterval(
    () => {
      const deleted = transactionCache.cleanup();
      if (deleted > 0) {
        console.log(`[Cache] Cleaned up ${deleted} expired entries`);
      }
    },
    5 * 60 * 1000
  );
}
