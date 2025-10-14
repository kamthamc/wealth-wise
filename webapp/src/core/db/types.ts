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
  | 'wallet';

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
