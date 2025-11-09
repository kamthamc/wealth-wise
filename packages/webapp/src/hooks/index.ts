/**
 * Custom React Hooks for TanStack Query Integration
 * 
 * This module provides a centralized export of all query and mutation hooks
 * for data management in the WealthWise application.
 * 
 * Usage:
 * ```typescript
 * import { useAccounts, useCreateAccount } from '@/hooks';
 * ```
 */

// Account hooks
export { useAccounts } from './useAccounts';
export {
  useCreateAccount,
  useUpdateAccount,
  useDeleteAccount,
  useTransferBetweenAccounts,
} from './useAccountMutations';

// Transaction hooks
export { useTransactions, useTransaction } from './useTransactions';
export {
  useCreateTransaction,
  useUpdateTransaction,
  useDeleteTransaction,
  useBulkDeleteTransactions,
  useImportTransactions,
} from './useTransactionMutations';

// Budget hooks
export { useBudgets, useBudget } from './useBudgets';
export {
  useCreateBudget,
  useUpdateBudget,
  useDeleteBudget,
} from './useBudgetMutations';

// Goal hooks
export { useGoals, useGoal } from './useGoals';
export {
  useCreateGoal,
  useUpdateGoal,
  useDeleteGoal,
  useContributeToGoal,
} from './useGoalMutations';
