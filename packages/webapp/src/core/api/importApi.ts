import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

// Types
export interface ImportTransaction {
  date: string;
  description: string;
  amount: number;
  type: 'income' | 'expense' | 'transfer';
  category?: string;
  notes?: string;
  import_transaction_id?: string;
}

export interface ImportResult {
  total: number;
  imported: number;
  skipped: number;
  duplicates: string[];
  errors: string[];
  importReference: string;
  accountId: string;
}

export interface BatchImportResult {
  batchId: string;
  totalTransactions: number;
  totalChunks: number;
  processedChunks: number;
  imported: number;
  skipped: number;
  errors: string[];
}

export interface ExportResult {
  format: 'json' | 'csv';
  data: any;
  count: number;
}

export interface ClearDataResult {
  success: boolean;
  deletedCollections: Record<string, number>;
  totalDeleted: number;
  timestamp: string;
}

// API Functions

/**
 * Import transactions from CSV/JSON data
 */
export async function importTransactions(
  transactions: ImportTransaction[],
  accountId: string,
  detectDuplicates = true
): Promise<ImportResult> {
  const importTransactionsFn = httpsCallable<
    {
      transactions: ImportTransaction[];
      accountId: string;
      detectDuplicates?: boolean;
    },
    ImportResult
  >(functions, 'importTransactions');

  const result = await importTransactionsFn({
    transactions,
    accountId,
    detectDuplicates,
  });

  return result.data;
}

/**
 * Batch import transactions in chunks for large imports
 */
export async function batchImportTransactions(
  transactions: ImportTransaction[],
  accountId: string,
  chunkSize = 100
): Promise<BatchImportResult> {
  const batchImportTransactionsFn = httpsCallable<
    {
      transactions: ImportTransaction[];
      accountId: string;
      chunkSize?: number;
    },
    BatchImportResult
  >(functions, 'batchImportTransactions');

  const result = await batchImportTransactionsFn({
    transactions,
    accountId,
    chunkSize,
  });

  return result.data;
}

/**
 * Export transactions with optional filtering
 */
export async function exportTransactions(params?: {
  accountId?: string;
  startDate?: string;
  endDate?: string;
  format?: 'json' | 'csv';
}): Promise<ExportResult> {
  const exportTransactionsFn = httpsCallable<typeof params, ExportResult>(
    functions,
    'exportTransactions'
  );

  const result = await exportTransactionsFn(params || {});
  return result.data;
}

/**
 * Clear all user data
 * WARNING: This is a destructive operation and cannot be undone
 */
export async function clearUserData(
  confirmation: string,
  collections: string[] = ['all']
): Promise<ClearDataResult> {
  if (confirmation !== 'DELETE_ALL_MY_DATA') {
    throw new Error(
      'Must confirm deletion with exact phrase: DELETE_ALL_MY_DATA'
    );
  }

  const clearUserDataFn = httpsCallable<
    {
      confirmation: string;
      collections?: string[];
    },
    ClearDataResult
  >(functions, 'clearUserData');

  const result = await clearUserDataFn({ confirmation, collections });
  return result.data;
}

export const importApi = {
  importTransactions,
  batchImportTransactions,
  exportTransactions,
  clearUserData,
};
