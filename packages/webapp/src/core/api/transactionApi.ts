import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

/**
 * Transaction Types
 */
export interface CreateTransactionData {
  account_id: string;
  type: 'income' | 'expense' | 'transfer';
  category: string;
  amount: number;
  description?: string;
  date: string; // ISO date string
  tags?: string[];
  location?: string;
  receipt_url?: string;
  is_recurring?: boolean;
  recurring_frequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  // For transfers
  to_account_id?: string;
}

export interface UpdateTransactionData {
  transactionId: string;
  updates: Partial<CreateTransactionData>;
}

export interface TransactionStatsParams {
  startDate: string; // ISO date string
  endDate: string; // ISO date string
}

/**
 * Cloud Functions API for Transactions
 */
export const transactionFunctions = {
  /**
   * Create a new transaction
   */
  createTransaction: async (data: CreateTransactionData) => {
    const callable = httpsCallable(functions, 'createTransaction');
    const result = await callable(data);
    return result.data;
  },

  /**
   * Update an existing transaction
   */
  updateTransaction: async (data: UpdateTransactionData) => {
    const callable = httpsCallable(functions, 'updateTransaction');
    const result = await callable(data);
    return result.data;
  },

  /**
   * Delete a transaction
   */
  deleteTransaction: async (transactionId: string) => {
    const callable = httpsCallable(functions, 'deleteTransaction');
    const result = await callable({ transactionId });
    return result.data;
  },

  /**
   * Get transaction statistics for a date range
   */
  getTransactionStats: async (params: TransactionStatsParams) => {
    const callable = httpsCallable(functions, 'getTransactionStats');
    const result = await callable(params);
    return result.data;
  },
};
