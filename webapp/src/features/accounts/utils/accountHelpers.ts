/**
 * Account Helper Utilities
 * Helper functions for account management
 */

import type { AccountType } from '../types';

/**
 * Get icon emoji for account type
 */
export function getAccountIcon(type: AccountType): string {
  const icons: Partial<Record<AccountType, string>> = {
    bank: '🏦',
    credit_card: '💳',
    upi: '📱',
    brokerage: '📈',
    cash: '💵',
    wallet: '👛',
  };
  return icons[type] || '💼';
}

/**
 * Get display name for account type
 */
export function getAccountTypeName(type: AccountType): string {
  const names: Partial<Record<AccountType, string>> = {
    bank: 'Bank Account',
    credit_card: 'Credit Card',
    upi: 'UPI Account',
    brokerage: 'Brokerage',
    cash: 'Cash',
    wallet: 'Wallet',
  };
  return names[type] || 'Account';
}

/**
 * Get color variant for account type
 */
export function getAccountTypeColor(
  type: AccountType
): 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'default' {
  const colors: Partial<
    Record<
      AccountType,
      'primary' | 'success' | 'warning' | 'danger' | 'info' | 'default'
    >
  > = {
    bank: 'primary',
    credit_card: 'warning',
    upi: 'success',
    brokerage: 'danger',
    cash: 'info',
    wallet: 'default',
  };
  return colors[type] || 'default';
}

/**
 * Format account identifier (use account ID or custom display)
 */
export function formatAccountIdentifier(accountId: string): string {
  // Show last 8 characters of UUID
  return accountId.slice(-8).toUpperCase();
}

/**
 * Validate account form data
 */
export function validateAccountForm(data: {
  name: string;
  type: string;
  balance: number;
}): Record<string, string> {
  const errors: Record<string, string> = {};

  if (!data.name || data.name.trim().length === 0) {
    errors.name = 'Account name is required';
  } else if (data.name.trim().length < 2) {
    errors.name = 'Account name must be at least 2 characters';
  }

  if (!data.type) {
    errors.type = 'Account type is required';
  }

  if (data.balance === undefined || data.balance === null) {
    errors.balance = 'Initial balance is required';
  }

  return errors;
}
