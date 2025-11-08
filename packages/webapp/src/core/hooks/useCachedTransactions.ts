/**
 * Cached Transactions Hook
 * Provides cached transaction data with automatic cache management
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { transactionCache } from '@/core/cache';
import type { Transaction } from '@/core/types';
import { timestampToDate } from '@/core/utils/firebase';

interface UseCachedTransactionsOptions {
  accountId?: string;
  category?: string;
  dateRange?: {
    start: Date;
    end: Date;
  };
  enabled?: boolean;
}

interface CachedTransactionsResult {
  transactions: Transaction[];
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
  invalidate: () => void;
}

export function useCachedTransactions(
  baseTransactions: Transaction[],
  options: UseCachedTransactionsOptions = {}
): CachedTransactionsResult {
  const { accountId, category, dateRange, enabled = true } = options;
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Generate cache key based on filters
  const cacheKey = useMemo(() => {
    const parts = ['transactions'];
    if (accountId) parts.push(`account:${accountId}`);
    if (category) parts.push(`category:${category}`);
    if (dateRange) {
      parts.push(`date:${dateRange.start.toISOString()}_${dateRange.end.toISOString()}`);
    }
    return parts.join(':');
  }, [accountId, category, dateRange]);

  // Filter transactions based on options
  const filteredTransactions = useMemo(() => {
    if (!enabled) return [];

    let filtered = [...baseTransactions];

    if (accountId) {
      filtered = filtered.filter(t => t.account_id === accountId);
    }

    if (category) {
      filtered = filtered.filter(t => t.category === category);
    }

    if (dateRange) {
      const startTime = dateRange.start.getTime();
      const endTime = dateRange.end.getTime();
      filtered = filtered.filter(t => {
        const txnTime = timestampToDate(t.date).getTime();
        return txnTime >= startTime && txnTime <= endTime;
      });
    }

    return filtered;
  }, [baseTransactions, accountId, category, dateRange, enabled]);

  // Try to get from cache first
  const cachedResult = useMemo(() => {
    if (!enabled) return null;
    return transactionCache.get<Transaction[]>(cacheKey);
  }, [cacheKey, enabled]);

  // Use cached data if available, otherwise use filtered data
  const transactions = cachedResult || filteredTransactions;

  // Cache the filtered results if not already cached
  useEffect(() => {
    if (enabled && !cachedResult && filteredTransactions.length > 0) {
      transactionCache.set(cacheKey, filteredTransactions, {
        ttl: 5 * 60 * 1000, // 5 minutes
        prefix: 'filtered'
      });
    }
  }, [cacheKey, cachedResult, filteredTransactions, enabled]);

  const refetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Invalidate cache for this key
      transactionCache.invalidate(`filtered:${cacheKey}`);

      // The useMemo will automatically recalculate
      setIsLoading(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to refetch transactions');
      setIsLoading(false);
    }
  }, [cacheKey]);

  const invalidate = useCallback(() => {
    transactionCache.invalidate(`filtered:${cacheKey}`);
  }, [cacheKey]);

  return {
    transactions,
    isLoading,
    error,
    refetch,
    invalidate,
  };
}