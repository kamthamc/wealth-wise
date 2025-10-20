/**
 * TypeScript types for database entities
 * Matches the SQL schema definitions
 */

export type AccountType =
  | 'bank'
  | 'credit_card'
  | 'upi'
  | 'brokerage'
  | 'cash'
  | 'wallet'
  | 'fixed_deposit'
  | 'recurring_deposit'
  | 'ppf'
  | 'nsc'
  | 'kvp'
  | 'scss'
  | 'post_office';

export type DepositStatus = 'active' | 'matured' | 'pre_closed' | 'renewed';

export type InterestPayoutFrequency =
  | 'monthly'
  | 'quarterly'
  | 'annually'
  | 'maturity';

export type TaxDeductionSection = '80C' | '80D' | '80G' | 'none';

export type TransactionType = 'income' | 'expense' | 'transfer';

export type RecurringFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly';

export type BudgetPeriod = 'daily' | 'weekly' | 'monthly' | 'yearly';

export type GoalPriority = 'low' | 'medium' | 'high';

export type GoalStatus = 'active' | 'completed' | 'paused' | 'cancelled';

export type CategoryType = 'income' | 'expense';

/**
 * Account entity
 */
export interface Account {
  id: string;
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  icon?: string;
  color?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

/**
 * Deposit Account Details
 * Tracks Fixed Deposits, Recurring Deposits, PPF, NSC, and other deposit schemes
 */
export interface DepositDetails {
  id: string;
  account_id: string;

  // Principal and maturity
  principal_amount: number;
  maturity_amount: number;
  current_value: number;

  // Dates
  start_date: Date;
  maturity_date: Date;
  last_interest_date?: Date;

  // Interest details
  interest_rate: number; // Annual interest rate (percentage)
  interest_payout_frequency: InterestPayoutFrequency;
  total_interest_earned: number;

  // Tenure
  tenure_months: number;
  completed_months: number;
  remaining_months: number;

  // Tax information
  tds_deducted: number;
  tax_deduction_section?: TaxDeductionSection;
  is_tax_saving: boolean;

  // Status and options
  status: DepositStatus;
  auto_renewal: boolean;
  premature_withdrawal_allowed: boolean;
  loan_against_deposit_allowed: boolean;

  // Institution details
  bank_name?: string;
  branch?: string;
  account_number?: string;
  certificate_number?: string;

  // Nominee
  nominee_name?: string;
  nominee_relationship?: string;

  // Additional metadata
  notes?: string;

  created_at: Date;
  updated_at: Date;
}

/**
 * Deposit Interest Payment
 * Tracks individual interest payments/credits
 */
export interface DepositInterestPayment {
  id: string;
  deposit_id: string;
  payment_date: Date;
  interest_amount: number;
  tds_deducted: number;
  net_amount: number;
  quarter?: number;
  financial_year: string;
  created_at: Date;
}

/**
 * Deposit Calculator Input
 * Helper type for FD/RD calculator
 */
export interface DepositCalculation {
  principal: number;
  interest_rate: number;
  tenure_months: number;
  payout_frequency: InterestPayoutFrequency;
  compound_frequency?: number; // times per year
}

/**
 * Deposit Calculator Result
 */
export interface DepositCalculationResult {
  principal: number;
  total_interest: number;
  maturity_amount: number;
  effective_rate: number;
  interest_breakdown: {
    month: number;
    interest: number;
    cumulative_interest: number;
  }[];
}

/**
 * Transaction entity
 */
export interface Transaction {
  id: string;
  account_id: string;
  type: TransactionType;
  category: string;
  amount: number;
  description?: string;
  date: Date;
  tags?: string[];
  location?: string;
  receipt_url?: string;
  is_recurring: boolean;
  recurring_frequency?: RecurringFrequency;
  linked_transaction_id?: string; // For linking transfer transactions
  created_at: Date;
  updated_at: Date;
}

/**
 * Budget entity
 */
export interface Budget {
  id: string;
  name: string;
  category: string;
  amount: number;
  spent: number;
  period: BudgetPeriod;
  start_date: Date;
  end_date?: Date;
  alert_threshold: number;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

/**
 * Goal entity
 */
export interface Goal {
  id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: Date;
  category: string;
  priority?: GoalPriority;
  status: GoalStatus;
  icon?: string;
  color?: string;
  created_at: Date;
  updated_at: Date;
}

/**
 * Goal contribution entity
 */
export interface GoalContribution {
  id: string;
  goal_id: string;
  amount: number;
  date: Date;
  note?: string;
  created_at: Date;
}

/**
 * Category entity
 */
export interface Category {
  id: string;
  name: string;
  type: CategoryType;
  icon?: string;
  color?: string;
  parent_id?: string;
  is_default: boolean;
  created_at: Date;
}

/**
 * Settings entity
 */
export interface Setting {
  key: string;
  value: string;
  updated_at: Date;
}

/**
 * Input types for creating entities (without auto-generated fields)
 */
export type CreateAccountInput = Omit<
  Account,
  'id' | 'created_at' | 'updated_at' | 'balance'
> & {
  balance?: number;
};

export type CreateTransactionInput = Omit<
  Transaction,
  'id' | 'created_at' | 'updated_at'
> & {
  date?: Date;
};

export type CreateBudgetInput = Omit<
  Budget,
  'id' | 'created_at' | 'updated_at' | 'spent'
> & {
  spent?: number;
};

export type CreateGoalInput = Omit<
  Goal,
  'id' | 'created_at' | 'updated_at' | 'current_amount'
> & {
  current_amount?: number;
};

export type CreateGoalContributionInput = Omit<
  GoalContribution,
  'id' | 'created_at'
> & {
  date?: Date;
};

export type CreateCategoryInput = Omit<Category, 'id' | 'created_at'>;

export type CreateDepositDetailsInput = Omit<
  DepositDetails,
  | 'id'
  | 'created_at'
  | 'updated_at'
  | 'current_value'
  | 'completed_months'
  | 'remaining_months'
> & {
  current_value?: number;
};

export type CreateDepositInterestPaymentInput = Omit<
  DepositInterestPayment,
  'id' | 'created_at'
>;

/**
 * Update types (all fields optional except id)
 */
export type UpdateAccountInput = Partial<
  Omit<Account, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

export type UpdateTransactionInput = Partial<
  Omit<Transaction, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

export type UpdateBudgetInput = Partial<
  Omit<Budget, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

export type UpdateGoalInput = Partial<
  Omit<Goal, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

export type UpdateDepositDetailsInput = Partial<
  Omit<DepositDetails, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

/**
 * Query filter types
 */
export interface DateRangeFilter {
  start?: Date;
  end?: Date;
}

export interface TransactionFilters {
  account_id?: string;
  type?: TransactionType;
  category?: string;
  dateRange?: DateRangeFilter;
  minAmount?: number;
  maxAmount?: number;
  tags?: string[];
  search?: string;
}

export interface BudgetFilters {
  category?: string;
  period?: BudgetPeriod;
  is_active?: boolean;
}

export interface GoalFilters {
  status?: GoalStatus;
  priority?: GoalPriority;
  category?: string;
}

/**
 * Aggregation types
 */
export interface TransactionSummary {
  total_income: number;
  total_expense: number;
  net_income: number;
  transaction_count: number;
}

export interface CategorySummary {
  category: string;
  total: number;
  count: number;
  percentage: number;
}

export interface MonthlyTrend {
  month: string;
  income: number;
  expense: number;
  net: number;
}

/**
 * Investment Types
 */
export type InvestmentAssetType =
  | 'stock'
  | 'mutual_fund'
  | 'etf'
  | 'commodity'
  | 'reit'
  | 'bond'
  | 'crypto';

export type InvestmentTransactionType =
  | 'buy'
  | 'sell'
  | 'dividend'
  | 'bonus'
  | 'split'
  | 'rights'
  | 'ipo';

/**
 * Investment Holding entity
 */
export interface InvestmentHolding {
  id: string;
  account_id: string;
  symbol: string;
  name: string;
  asset_type: InvestmentAssetType;
  quantity: number;
  average_cost: number;
  current_price: number;
  currency: string;
  exchange?: string;
  isin?: string;
  created_at: Date;
  updated_at: Date;
}

/**
 * Investment Transaction entity
 */
export interface InvestmentTransaction {
  id: string;
  holding_id: string;
  account_id: string;
  transaction_type: InvestmentTransactionType;
  quantity: number;
  price: number;
  total_amount: number;
  fees?: number;
  taxes?: number;
  date: Date;
  notes?: string;
  created_at: Date;
  updated_at: Date;
}

/**
 * Investment Price Cache entity (for Firebase)
 */
export interface InvestmentPrice {
  symbol: string;
  price: number;
  currency: string;
  exchange?: string;
  last_updated: Date;
  source?: string;
}

/**
 * Investment Performance Metrics
 */
export interface InvestmentPerformance {
  holding_id: string;
  symbol: string;
  total_invested: number;
  current_value: number;
  absolute_return: number;
  percentage_return: number;
  realized_gains: number;
  unrealized_gains: number;
  dividends_received: number;
  xirr?: number; // Extended Internal Rate of Return
}

/**
 * Portfolio Summary
 */
export interface PortfolioSummary {
  total_invested: number;
  current_value: number;
  total_return: number;
  return_percentage: number;
  day_change: number;
  day_change_percentage: number;
  holdings_count: number;
  by_asset_type: Record<
    InvestmentAssetType,
    {
      value: number;
      percentage: number;
      count: number;
    }
  >;
}

/**
 * Input types for creating investment entities
 */
export type CreateInvestmentHoldingInput = Omit<
  InvestmentHolding,
  'id' | 'created_at' | 'updated_at' | 'current_price'
> & {
  current_price?: number;
};

export type CreateInvestmentTransactionInput = Omit<
  InvestmentTransaction,
  'id' | 'created_at' | 'updated_at'
> & {
  date?: Date;
};

/**
 * Update types for investment entities
 */
export type UpdateInvestmentHoldingInput = Partial<
  Omit<InvestmentHolding, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

export type UpdateInvestmentTransactionInput = Partial<
  Omit<InvestmentTransaction, 'id' | 'created_at' | 'updated_at'>
> & {
  id: string;
};

/**
 * Investment Filter Types
 */
export interface InvestmentFilters {
  account_ids?: string[];
  asset_types?: InvestmentAssetType[];
  symbols?: string[];
  dateRange?: DateRangeFilter;
  minValue?: number;
  maxValue?: number;
  search?: string;
}
