/**
 * Core Types
 * Re-exports types from shared-types and defines webapp-specific types
 * Replaces the old @/core/types imports
 */

import type {
  Account,
  Transaction,
  Budget,
  BudgetCategory,
  Goal,
  GoalContribution,
  Category,
  DepositDetails,
  CreditCardDetails,
  BrokerageDetails,
  InsuranceDetails,
  PensionAccount,
  RealEstateInvestment,
  PreciousMetal,
  AlternativeInvestment,
  InvestmentTransaction,
  AccountType,
  Currency,
  TransactionType,
  RecurringFrequency,
  GoalPriority,
  GoalStatus,
  CategoryType,
  BudgetPeriodType,
  DepositStatus,
  CreditCardStatus,
  BrokerageStatus,
  InsuranceStatus,
  PensionStatus,
  RealEstateStatus,
  AlternativeInvestmentStatus,
  InterestPayoutFrequency,
  PremiumFrequency,
  CardNetwork,
  CardType,
  BrokerageAccountType,
  TaxDeductionSection,
  CreateAccountInput,
  UpdateAccountInput,
  CreateTransactionInput,
  UpdateTransactionInput,
  CreateBudgetInput,
  UpdateBudgetInput,
  CreateGoalInput,
  UpdateGoalInput,
} from '@svc/wealth-wise-shared-types';

// Re-export for convenience
export type {
  Account,
  Transaction,
  Budget,
  BudgetCategory,
  Goal,
  GoalContribution,
  Category,
  DepositDetails,
  CreditCardDetails,
  BrokerageDetails,
  InsuranceDetails,
  PensionAccount,
  RealEstateInvestment,
  PreciousMetal,
  AlternativeInvestment,
  InvestmentTransaction,
  AccountType,
  Currency,
  TransactionType,
  RecurringFrequency,
  GoalPriority,
  GoalStatus,
  CategoryType,
  BudgetPeriodType,
  DepositStatus,
  CreditCardStatus,
  BrokerageStatus,
  InsuranceStatus,
  PensionStatus,
  RealEstateStatus,
  AlternativeInvestmentStatus,
  InterestPayoutFrequency,
  PremiumFrequency,
  CardNetwork,
  CardType,
  BrokerageAccountType,
  TaxDeductionSection,
  CreateAccountInput,
  UpdateAccountInput,
  CreateTransactionInput,
  UpdateTransactionInput,
  CreateBudgetInput,
  UpdateBudgetInput,
  CreateGoalInput,
  UpdateGoalInput,
};

// Webapp-specific types that extend shared types

export interface BudgetWithProgress extends Budget {
  total_allocated: number;
  total_spent: number;
  percentage: number;
  status: 'on-track' | 'warning' | 'danger' | 'over';
}

export interface AccountWithBalance extends Account {
  calculated_balance?: number;
}

export interface TransactionWithAccount extends Transaction {
  account_name?: string;
  account_type?: AccountType;
}

// Filter types for queries
export interface TransactionFilters {
  account_id?: string;
  type?: TransactionType;
  category?: string;
  date_from?: Date;
  date_to?: Date;
  min_amount?: number;
  max_amount?: number;
  search?: string;
}

export interface BudgetFilters {
  is_active?: boolean;
  period_type?: BudgetPeriodType;
}

export interface GoalFilters {
  status?: GoalStatus;
  priority?: GoalPriority;
}

// Pagination
export interface PaginationState {
  page: number;
  pageSize: number;
  total: number;
}

// UI-specific types
export interface CategorySpending {
  category: string;
  amount: number;
  percentage: number;
  transaction_count: number;
}

export interface MonthlyStats {
  month: string;
  income: number;
  expense: number;
  net: number;
  balance: number;
}

export interface BudgetAlert {
  budget_id: string;
  budget_name: string;
  category?: string;
  severity: 'info' | 'warning' | 'danger';
  message: string;
}

// Deposit-specific types
export interface DepositInterestPayment {
  id: string;
  deposit_id: string;
  account_id: string;
  payment_date: Date;
  interest_amount: number;
  principal_amount: number;
  balance_after: number;
  transaction_id?: string;
  created_at: Date;
}

export interface DepositCalculation {
  principal: number;
  rate: number;
  tenure_months: number;
  frequency: InterestPayoutFrequency;
  deposit_type: 'fd' | 'rd';
  monthly_deposit?: number;
}

export interface DepositCalculationResult {
  maturity_amount: number;
  total_interest: number;
  effective_rate: number;
  monthly_interest?: number;
  payment_schedule?: Array<{
    month: number;
    interest: number;
    principal: number;
    balance: number;
  }>;
}

// Investment-specific types
export interface InvestmentHolding {
  symbol: string;
  name: string;
  quantity: number;
  average_price: number;
  current_price: number;
  invested_value: number;
  current_value: number;
  unrealized_gain: number;
  unrealized_gain_percentage: number;
}

export interface InvestmentPrice {
  symbol: string;
  price: number;
  change: number;
  change_percentage: number;
  last_updated: Date;
}

export interface InvestmentPerformance {
  total_invested: number;
  current_value: number;
  total_returns: number;
  returns_percentage: number;
  realized_gains: number;
  unrealized_gains: number;
}

export interface PortfolioSummary {
  total_value: number;
  total_invested: number;
  total_returns: number;
  returns_percentage: number;
  holdings_count: number;
  asset_allocation: Array<{
    type: string;
    value: number;
    percentage: number;
  }>;
}

// Settings
export interface Setting {
  key: string;
  value: string;
  updated_at: Date;
}

// Export/Import types
export interface ImportResult {
  success: number;
  failed: number;
  duplicates: number;
  errors: Array<{
    row: number;
    error: string;
  }>;
}

export interface ExportOptions {
  format: 'json' | 'csv' | 'pdf';
  dateRange?: {
    start: Date;
    end: Date;
  };
  accounts?: string[];
  includeCategories?: boolean;
}

// Firebase-specific: Date conversion type
export type FirebaseDate = Date | { toDate(): Date; toMillis(): number };
