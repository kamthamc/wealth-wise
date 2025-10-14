/**
 * Account Feature Types
 * Type definitions for account management
 */

import type { AccountType as DbAccountType } from '@/core/db/types';

// Re-export the database account type
export type AccountType = DbAccountType;

export interface AccountFormData {
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  icon?: string;
  color?: string;
}

export interface AccountFilters {
  type?: AccountType;
  search?: string;
}

export interface AccountStats {
  totalBalance: number;
  totalAccounts: number;
  accountsByType: Partial<Record<AccountType, number>>;
}
