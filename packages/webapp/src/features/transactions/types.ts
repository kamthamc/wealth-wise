/**
 * Transaction Feature Types
 * Type definitions for transaction management
 */

import type { TransactionType as DbTransactionType } from '@/core/types';

// Re-export database transaction type
export type TransactionType = DbTransactionType;

export interface TransactionFormData {
  amount: number;
  type: TransactionType;
  account_id: string;
  category_id?: string;
  description: string;
  date: string; // ISO date string
  tags?: string[];
}

export interface TransactionFilters {
  type?: TransactionType;
  account_id?: string;
  category_id?: string;
  startDate?: string;
  endDate?: string;
  search?: string;
}

export interface TransactionStats {
  totalIncome: number;
  totalExpenses: number;
  netCashFlow: number;
  transactionCount: number;
}
