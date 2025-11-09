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

export interface BudgetProgress {
  total_spent: number;
  total_allocated: number;
  percentage: number;
  remaining: number;
  is_over_budget: boolean;
  // Also include category-level fields for compatibility
  category?: string;
  allocated?: number;
  spent?: number;
  percent_used?: number;
  variance?: number;
  status?: 'under' | 'near' | 'over';
}

export interface BudgetCategoryProgress {
  category: string;
  allocated: number;
  spent: number;
  percent_used: number;
  remaining: number;
  variance: number;
  is_over_budget: boolean;
  status?: 'good' | 'warning' | 'danger';
}

export interface BudgetWithProgress extends Budget {
  total_spent: number;
  total_allocated: number;
  progress: BudgetProgress;
  category_progress?: BudgetCategoryProgress[];
  status?: 'under' | 'near' | 'over' | 'exceeded';
  variance?: number;
}

export type BudgetStatus = 'on-track' | 'warning' | 'danger' | 'over';

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
  id: string;
  budget_id: string;
  category?: string;
  severity: 'info' | 'warning' | 'danger';
  message: string;
  timestamp: any;
  percent_used?: number; // For displaying usage in alerts
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

// Deposit types - match DepositDetails from shared-types
export interface CreateDepositDetailsInput {
  account_id: string;
  principal_amount: number;
  current_value?: number; // Optional - will be calculated if not provided
  maturity_amount?: number; // Optional - will be calculated if not provided
  start_date: Date;
  maturity_date: Date;
  last_interest_date?: Date;
  interest_rate: number;
  interest_payout_frequency: InterestPayoutFrequency;
  total_interest_earned?: number; // Optional - will be calculated if not provided
  tenure_months: number;
  completed_months?: number; // Optional - will be calculated if not provided
  remaining_months?: number; // Optional - will be calculated if not provided
  tds_deducted: number;
  tax_deduction_section?: TaxDeductionSection;
  is_tax_saving: boolean;
  status?: DepositStatus; // Optional - defaults to 'active'
  auto_renewal: boolean;
  premature_withdrawal_allowed: boolean;
  loan_against_deposit_allowed: boolean;
  bank_name?: string;
  branch?: string;
  account_number?: string;
  certificate_number?: string;
  nominee_name?: string;
  nominee_relationship?: string;
  notes?: string;
}

export type UpdateDepositDetailsInput = Partial<Omit<CreateDepositDetailsInput, 'account_id'>>;

export interface CreateDepositInterestPayment {
  deposit_id: string;
  payment_date: Date;
  amount: number;
  quarter?: string;
  financial_year?: string;
  tds_deducted?: number;
  net_amount?: number;
}

// Type aliases for backward compatibility
export type CreateDepositDetails = CreateDepositDetailsInput;
export type UpdateDepositDetails = UpdateDepositDetailsInput;
export type CreateDepositInterestPaymentInput = CreateDepositInterestPayment;

export interface DepositCalculation {
  principal: number;
  interest_rate: number;
  rate?: number; // Alias for interest_rate
  tenure_months: number;
  payout_frequency: InterestPayoutFrequency;
  frequency?: InterestPayoutFrequency; // Alias for payout_frequency
  compound_frequency?: InterestPayoutFrequency;
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
// Investment asset type
export type InvestmentAssetType = 
  | 'stock'
  | 'mutual_fund'
  | 'bond'
  | 'etf'
  | 'commodity'
  | 'reit';

export interface InvestmentHolding {
  id?: string;
  account_id?: string;
  asset_type?: InvestmentAssetType | string;
  asset_name: string;
  quantity?: number;
  average_cost?: number;
  current_price?: number;
  current_value?: number;
  total_invested?: number;
  absolute_return?: number;
  percentage_return?: number;
  purchase_date?: Date;
  isin?: string;
  ticker?: string;
  notes?: string;
}

export interface CreateInvestmentAccount {
  name: string;
  broker: string;
  account_number: string;
  opening_balance: number;
}

export interface InvestmentTransactionInput {
  holding_id?: string;
  type: 'buy' | 'sell' | 'dividend' | 'ipo';
  symbol?: string;
  quantity?: number;
  price?: number;
  date: Date;
  total_amount?: number;
  fees?: number;
  taxes?: number;
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
