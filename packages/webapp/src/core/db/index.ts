/**
 * Database module exports
 * Central entry point for all database-related functionality
 */

// Client and initialization
export { db } from './client';
// Repositories
export {
  accountRepository,
  budgetRepository,
  transactionRepository,
} from './repositories';
export { depositDetailsRepository } from './repositories/depositDetails';
// Schema and migrations
export { DATABASE_VERSION, SCHEMA_SQL, SEED_CATEGORIES_SQL } from './schema';
// Types
export type {
  Account,
  AccountType,
  Budget,
  BudgetFilters,
  BudgetPeriod,
  Category,
  CategorySummary,
  CategoryType,
  CreateAccountInput,
  CreateBudgetInput,
  CreateCategoryInput,
  CreateGoalContributionInput,
  CreateGoalInput,
  CreateTransactionInput,
  DepositDetails,
  DepositStatus,
  Goal,
  GoalContribution,
  GoalFilters,
  GoalPriority,
  GoalStatus,
  InterestPayoutFrequency,
  MonthlyTrend,
  RecurringFrequency,
  Setting,
  TaxDeductionSection,
  Transaction,
  TransactionFilters,
  TransactionSummary,
  TransactionType,
  UpdateAccountInput,
  UpdateBudgetInput,
  UpdateGoalInput,
  UpdateTransactionInput,
} from './types';
