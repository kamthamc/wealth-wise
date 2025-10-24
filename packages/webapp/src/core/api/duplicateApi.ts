import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';

export interface DuplicateCheckParams {
  transaction: {
    date: string;
    amount: number;
    description: string;
    reference?: string;
    type: 'income' | 'expense' | 'transfer';
  };
  accountId: string;
}

export interface DuplicateCheckResult {
  isDuplicate: boolean;
  confidence: number;
  matchType: 'exact' | 'fuzzy' | 'none';
  matchedTransactionId?: string;
  reason?: string;
}

export interface BatchCheckParams {
  transactions: Array<{
    date: string;
    amount: number;
    description: string;
    reference?: string;
    type: 'income' | 'expense' | 'transfer';
  }>;
  accountId: string;
}

export interface BatchCheckResult {
  success: boolean;
  summary: {
    total: number;
    duplicates: number;
    unique: number;
  };
  results: Array<{
    transaction: any;
    result: DuplicateCheckResult;
  }>;
}

/**
 * Check if a transaction is a duplicate
 */
export async function checkDuplicateTransaction(
  params: DuplicateCheckParams
): Promise<DuplicateCheckResult> {
  const callable = httpsCallable<DuplicateCheckParams, DuplicateCheckResult>(
    functions,
    'checkDuplicateTransaction'
  );
  const result = await callable(params);
  return result.data;
}

/**
 * Batch check for duplicate transactions
 */
export async function batchCheckDuplicates(
  params: BatchCheckParams
): Promise<BatchCheckResult> {
  const callable = httpsCallable<BatchCheckParams, BatchCheckResult>(
    functions,
    'batchCheckDuplicates'
  );
  const result = await callable(params);
  return result.data;
}
