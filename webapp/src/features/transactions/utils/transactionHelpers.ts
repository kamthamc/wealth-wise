/**
 * Transaction Helper Utilities
 * Helper functions for transaction management
 */

import type { TransactionType } from '../types';

/**
 * Get icon emoji for transaction type
 */
export function getTransactionIcon(type: TransactionType): string {
  const icons: Record<TransactionType, string> = {
    income: '💰',
    expense: '💸',
    transfer: '🔄',
  };
  return icons[type] || '💳';
}

/**
 * Get display name for transaction type
 */
export function getTransactionTypeName(type: TransactionType): string {
  const names: Record<TransactionType, string> = {
    income: 'Income',
    expense: 'Expense',
    transfer: 'Transfer',
  };
  return names[type] || 'Transaction';
}

/**
 * Get color variant for transaction type
 */
export function getTransactionTypeColor(
  type: TransactionType
): 'primary' | 'success' | 'warning' | 'danger' | 'default' {
  const colors: Record<
    TransactionType,
    'primary' | 'success' | 'warning' | 'danger' | 'default'
  > = {
    income: 'success',
    expense: 'danger',
    transfer: 'primary',
  };
  return colors[type] || 'default';
}

/**
 * Format transaction amount with sign
 */
export function formatTransactionAmount(
  amount: number,
  type: TransactionType,
  currency = 'INR'
): string {
  const sign = type === 'income' ? '+' : type === 'expense' ? '-' : '';
  const formatter = new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  return `${sign}${formatter.format(Math.abs(amount))}`;
}

/**
 * Validate transaction form data
 */
export function validateTransactionForm(data: {
  amount: number;
  type: string;
  account_id: string;
  description: string;
  date: string;
}): Record<string, string> {
  const errors: Record<string, string> = {};

  if (!data.amount || data.amount <= 0) {
    errors.amount = 'Amount must be greater than 0';
  }

  if (!data.type) {
    errors.type = 'Transaction type is required';
  }

  if (!data.account_id) {
    errors.account_id = 'Account is required';
  }

  if (!data.description || data.description.trim().length === 0) {
    errors.description = 'Description is required';
  } else if (data.description.trim().length < 3) {
    errors.description = 'Description must be at least 3 characters';
  }

  if (!data.date) {
    errors.date = 'Date is required';
  }

  return errors;
}
