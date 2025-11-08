/**
 * Duplicate Detection Service
 * Uses Firebase Cloud Functions for server-side duplicate detection
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';
import type { Transaction } from '@/core/types';

export type DuplicateConfidence = 'exact' | 'high' | 'possible';

export interface DuplicateMatch {
  existingTransaction: Transaction;
  confidence: DuplicateConfidence;
  matchReasons: string[];
  score: number;
}

export interface DuplicateCheckResult {
  isDuplicate: boolean;
  matches: DuplicateMatch[];
  // Extended properties for UI
  isNewTransaction?: boolean;
  duplicateMatches?: DuplicateMatch[];
  bestMatch?: DuplicateMatch;
}

interface CloudFunctionDuplicateResult {
  isDuplicate: boolean;
  confidence: number;
  matchType: 'exact' | 'fuzzy' | 'none';
  matchedTransactionId?: string;
  reason?: string;
}

/**
 * Check if a transaction is a duplicate using Cloud Function
 */
export async function checkForDuplicates(
  transaction: Partial<Transaction>
): Promise<DuplicateCheckResult> {
  try {
    const checkDuplicate = httpsCallable<
      { transaction: Partial<Transaction>; accountId: string },
      CloudFunctionDuplicateResult
    >(functions, 'checkDuplicateTransaction');
    
    if (!transaction.account_id) {
      console.warn('Cannot check duplicate: account_id is required');
      return {
        isDuplicate: false,
        matches: [],
        isNewTransaction: true,
      };
    }

    const result = await checkDuplicate({
      transaction: {
        date: typeof transaction.date === 'string' ? transaction.date : transaction.date?.toISOString() || new Date().toISOString(),
        amount: transaction.amount || 0,
        description: transaction.description || '',
        reference: transaction.import_reference || transaction.import_transaction_id,
        type: transaction.type || 'expense',
      } as any, // Type assertion needed due to reference field difference
      accountId: transaction.account_id,
    });

    const data = result.data;
    
    // Convert Cloud Function result to UI format
    const confidence: DuplicateConfidence = 
      data.matchType === 'exact' ? 'exact' :
      data.confidence >= 80 ? 'high' : 'possible';

    if (!data.isDuplicate) {
      return {
        isDuplicate: false,
        matches: [],
        isNewTransaction: true,
      };
    }

    // Note: We don't have the full transaction object from the Cloud Function
    // Only the ID and match details. The UI can fetch full details if needed.
    const match: DuplicateMatch = {
      existingTransaction: {
        id: data.matchedTransactionId || '',
      } as Transaction,
      confidence,
      matchReasons: data.reason ? [data.reason] : [],
      score: data.confidence,
    };

    return {
      isDuplicate: true,
      matches: [match],
      isNewTransaction: false,
      duplicateMatches: [match],
      bestMatch: match,
    };
  } catch (error) {
    console.error('Error checking for duplicates:', error);
    // Return safe default on error
    return {
      isDuplicate: false,
      matches: [],
      isNewTransaction: true,
    };
  }
}

/**
 * Batch check multiple transactions for duplicates
 */
export async function batchCheckDuplicates(
  transactions: Partial<Transaction>[],
  accountId: string
): Promise<DuplicateCheckResult[]> {
  try {
    const batchCheck = httpsCallable<
      { 
        transactions: Array<{
          date: string;
          amount: number;
          description: string;
          reference?: string;
          type: 'income' | 'expense' | 'transfer';
        }>;
        accountId: string;
      },
      {
        success: boolean;
        summary: {
          total: number;
          duplicates: number;
          unique: number;
        };
        results: Array<{
          transaction: any;
          result: CloudFunctionDuplicateResult;
        }>;
      }
    >(functions, 'batchCheckDuplicates');
    
    const result = await batchCheck({
      transactions: transactions.map(t => ({
        date: typeof t.date === 'string' ? t.date : t.date?.toISOString() || new Date().toISOString(),
        amount: t.amount || 0,
        description: t.description || '',
        reference: t.import_reference || t.import_transaction_id,
        type: t.type || 'expense',
      })) as any, // Type assertion needed due to reference field difference
      accountId,
    });

    // Convert Cloud Function results to UI format
    return result.data.results.map(item => {
      const data = item.result;
      
      if (!data.isDuplicate) {
        return {
          isDuplicate: false,
          matches: [],
          isNewTransaction: true,
        };
      }

      const confidence: DuplicateConfidence = 
        data.matchType === 'exact' ? 'exact' :
        data.confidence >= 80 ? 'high' : 'possible';

      const match: DuplicateMatch = {
        existingTransaction: {
          id: data.matchedTransactionId || '',
        } as Transaction,
        confidence,
        matchReasons: data.reason ? [data.reason] : [],
        score: data.confidence,
      };

      return {
        isDuplicate: true,
        matches: [match],
        isNewTransaction: false,
        duplicateMatches: [match],
        bestMatch: match,
      };
    });
  } catch (error) {
    console.error('Error batch checking duplicates:', error);
    // Return safe defaults on error
    return transactions.map(() => ({
      isDuplicate: false,
      matches: [],
      isNewTransaction: true,
    }));
  }
}

/**
 * Find duplicates by reference ID
 */
export async function findDuplicatesByReference(
  referenceId: string
): Promise<Transaction[]> {
  try {
    // This would need a separate Cloud Function
    // For now, use checkForDuplicates with a transaction containing the reference
    const result = await checkForDuplicates({
      import_reference: referenceId,
      // Provide minimal data to avoid false matches
      amount: 0,
      description: '',
      date: new Date().toISOString(),
    } as Partial<Transaction>);

    if (result.isDuplicate && result.matches.length > 0) {
      return result.matches.map(m => m.existingTransaction);
    }
    return [];
  } catch (error) {
    console.error('Error finding duplicates by reference:', error);
    return [];
  }
}

/**
 * Find duplicates by amount within date range
 * Note: This is a placeholder - full implementation requires additional Cloud Function
 */
export async function findDuplicatesByAmount(
  _amount: number,
  _dateRange: { start: Date; end: Date }
): Promise<Transaction[]> {
  try {
    // This would need a separate Cloud Function or Firestore query
    console.warn('findDuplicatesByAmount: Full implementation requires additional Cloud Function');
    return [];
  } catch (error) {
    console.error('Error finding duplicates by amount:', error);
    return [];
  }
}

/**
 * Find similar transactions
 */
export async function findSimilarTransactions(
  transaction: Partial<Transaction>
): Promise<DuplicateMatch[]> {
  try {
    const result = await checkForDuplicates(transaction);
    return result.matches;
  } catch (error) {
    console.error('Error finding similar transactions:', error);
    return [];
  }
}
