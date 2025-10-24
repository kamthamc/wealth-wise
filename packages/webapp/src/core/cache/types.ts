/**
 * Cache system types
 */

export interface CacheEntry<T = unknown> {
  data: T;
  expires: number;
  createdAt: number;
}

export interface CacheOptions {
  ttl?: number; // Time to live in milliseconds
  prefix?: string;
}

export interface CacheStats {
  hits: number;
  misses: number;
  size: number;
  hitRate: number;
}
