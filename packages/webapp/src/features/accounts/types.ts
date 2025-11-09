/**
 * Account Feature Types
 * Type definitions for account management
 */

import type {
  AccountType as DbAccountType,
  InterestPayoutFrequency,
} from '@/core/types';

// Re-export the database account type
export type AccountType = DbAccountType;

export interface AccountFormData {
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  icon?: string;
  color?: string;

  // Deposit-specific fields (optional, only for deposit accounts)
  depositDetails?: {
    principal_amount: number;
    interest_rate: number;
    start_date: Date;
    tenure_months: number;
    interest_payout_frequency?: InterestPayoutFrequency;
    bank_name?: string;
    auto_renewal?: boolean;
    is_tax_saving?: boolean;
    tax_deduction_section?: string;
    nominee_name?: string;
    notes?: string;
  };

  // Credit card-specific fields (optional, only for credit_card accounts)
  creditCardDetails?: {
    credit_limit: number;
    billing_cycle_day?: number;
    payment_due_day?: number;
    card_network?: string;
    card_type?: string;
    interest_rate?: number;
    annual_fee?: number;
    reward_rate?: number;
  };

  // Brokerage-specific fields (optional, only for brokerage accounts)
  brokerageDetails?: {
    broker_name?: string;
    demat_account_number?: string;
    trading_account_number?: string;
    dp_id?: string;
    client_id?: string;
    account_type?: string;
  };
}

export interface AccountFilters {
  types?: AccountType[]; // Changed from single 'type' to array 'types'
  accountIds?: string[]; // NEW: Filter by specific account IDs
  search?: string;
}

export interface AccountStats {
  totalBalance: number;
  totalAccounts: number;
  accountsByType: Partial<Record<AccountType, number>>;
}
