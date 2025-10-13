/**
 * Export all stores from a central location
 */

export {
  selectAccountById,
  selectAccountsByType,
  selectActiveAccounts,
  selectIsLoading as selectAccountsLoading,
  selectSelectedAccount,
  selectTotalBalance,
  useAccountStore,
} from './accountStore'
export { selectCurrency, selectIsReady, selectTheme, useAppStore } from './appStore'
export {
  selectActiveBudgets,
  selectBudgetById,
  selectBudgetsByCategory,
  selectIsLoading as selectBudgetsLoading,
  selectSelectedBudget,
  useBudgetStore,
} from './budgetStore'
export {
  selectActiveGoals,
  selectCompletedGoals,
  selectGoalById,
  selectGoalProgress,
  selectIsLoading as selectGoalsLoading,
  selectSelectedGoal,
  useGoalStore,
} from './goalStore'
export {
  selectFilters,
  selectIsLoading as selectTransactionsLoading,
  selectPagination,
  selectSelectedTransaction,
  selectTransactionById,
  useTransactionStore,
} from './transactionStore'
