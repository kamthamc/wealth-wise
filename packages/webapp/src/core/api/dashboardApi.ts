import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

// Types
export interface DashboardSummary {
  totalBalance: number;
  accountsCount: number;
  activeGoalsCount: number;
  activeBudgetsCount: number;
  recentIncome: number;
  recentExpenses: number;
  netCashFlow: number;
}

export interface AccountTypeBreakdown {
  [type: string]: {
    count: number;
    balance: number;
  };
}

export interface BudgetProgress {
  id: string;
  name: string;
  amount: number;
  spent: number;
  remaining: number;
  progress: number;
  status: 'on_track' | 'warning' | 'exceeded';
}

export interface GoalProgress {
  id: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  remaining: number;
  progress: number;
  status: string;
}

export interface MonthlyTrend {
  month: string;
  income: number;
  expenses: number;
  net: number;
}

export interface DashboardData {
  summary: DashboardSummary;
  accountsByType: AccountTypeBreakdown;
  categorySpending: Record<string, number>;
  budgetProgress: BudgetProgress[];
  goalProgress: GoalProgress[];
  monthlyTrends: MonthlyTrend[];
  recentTransactions: any[];
  cached: boolean;
  computedAt: string;
  expiresAt: string;
}

export interface AccountSummary {
  account: any;
  statistics: {
    totalTransactions: number;
    totalIncome: number;
    totalExpenses: number;
    averageTransaction: number;
    largestIncome: number;
    largestExpense: number;
    categoryBreakdown: Record<string, number>;
  };
  recentTransactions: any[];
}

export interface TransactionSummaryPeriod {
  period: string;
  income: number;
  expenses: number;
  net: number;
  transactions: number;
  categories: Record<string, number>;
}

export interface TransactionSummary {
  summary: TransactionSummaryPeriod[];
  totalPeriods: number;
  totalTransactions: number;
  overallIncome: number;
  overallExpenses: number;
  overallNet: number;
}

// API Functions

/**
 * Compute and cache comprehensive dashboard data
 */
export async function computeAndCacheDashboard(params?: {
  forceRefresh?: boolean;
  cacheTTL?: number;
}): Promise<DashboardData> {
  const computeAndCacheDashboardFn = httpsCallable<
    typeof params,
    DashboardData
  >(functions, 'computeAndCacheDashboard');

  const result = await computeAndCacheDashboardFn(params || {});
  return result.data;
}

/**
 * Get account summary with transaction statistics
 */
export async function getAccountSummary(
  accountId: string
): Promise<AccountSummary> {
  const getAccountSummaryFn = httpsCallable<
    { accountId: string },
    AccountSummary
  >(functions, 'getAccountSummary');

  const result = await getAccountSummaryFn({ accountId });
  return result.data;
}

/**
 * Get transaction summary with advanced analytics
 */
export async function getTransactionSummary(params?: {
  startDate?: string;
  endDate?: string;
  groupBy?: 'day' | 'week' | 'month' | 'year';
}): Promise<TransactionSummary> {
  const getTransactionSummaryFn = httpsCallable<
    typeof params,
    TransactionSummary
  >(functions, 'getTransactionSummary');

  const result = await getTransactionSummaryFn(params || {});
  return result.data;
}

/**
 * Invalidate dashboard cache to force refresh
 */
export async function invalidateDashboardCache(): Promise<{
  success: boolean;
  invalidated: boolean;
}> {
  const invalidateDashboardCacheFn = httpsCallable<
    {},
    { success: boolean; invalidated: boolean }
  >(functions, 'invalidateDashboardCache');

  const result = await invalidateDashboardCacheFn({});
  return result.data;
}

export const dashboardApi = {
  computeAndCacheDashboard,
  getAccountSummary,
  getTransactionSummary,
  invalidateDashboardCache,
};
