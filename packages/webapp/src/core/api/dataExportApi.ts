import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';

export interface ExportParams {
  format?: 'json' | 'csv';
  includeDeleted?: boolean;
}

export interface ImportParams {
  data: any;
  replaceExisting?: boolean;
}

export interface ExportResult {
  success: boolean;
  format: string;
  data: {
    exportedAt: string;
    userId: string;
    summary: {
      accountsCount: number;
      transactionsCount: number;
      budgetsCount: number;
      goalsCount: number;
    };
    accounts: any[];
    transactions: any[];
    budgets: any[];
    goals: any[];
  };
}

export interface ImportResult {
  success: boolean;
  summary: {
    accountsImported: number;
    transactionsImported: number;
    budgetsImported: number;
    goalsImported: number;
  };
}

export interface UserStatistics {
  success: boolean;
  statistics: {
    totalAccounts: number;
    totalTransactions: number;
    totalBudgets: number;
    totalGoals: number;
    totalBalance: number;
    accountsByType: Record<string, number>;
    firstTransactionDate: string | null;
    lastTransactionDate: string | null;
    dataQuality: {
      accountsWithoutBalance: number;
      transactionsWithoutCategory: number;
    };
  };
}

/**
 * Export user data
 */
export async function exportUserData(
  params: ExportParams = {}
): Promise<ExportResult> {
  const callable = httpsCallable<ExportParams, ExportResult>(
    functions,
    'exportUserData'
  );
  const result = await callable(params);
  return result.data;
}

/**
 * Import user data
 */
export async function importUserData(
  params: ImportParams
): Promise<ImportResult> {
  const callable = httpsCallable<ImportParams, ImportResult>(
    functions,
    'importUserData'
  );
  const result = await callable(params);
  return result.data;
}

/**
 * Get user statistics
 */
export async function getUserStatistics(): Promise<UserStatistics> {
  const callable = httpsCallable<void, UserStatistics>(
    functions,
    'getUserStatistics'
  );
  const result = await callable();
  return result.data;
}
