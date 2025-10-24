import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';

export interface ReportParams {
  startDate: string;
  endDate: string;
  reportType:
    | 'income-expense'
    | 'category-breakdown'
    | 'monthly-trend'
    | 'account-summary';
}

export interface ReportResult {
  success: boolean;
  report: {
    type: string;
    startDate: string;
    endDate: string;
    generatedAt: any;
    data: any;
  };
}

export interface DashboardAnalytics {
  success: boolean;
  analytics: {
    totalBalance: number;
    monthlyIncome: number;
    monthlyExpense: number;
    netSavings: number;
    savingsRate: number;
    accountCount: number;
    activeBudgetCount: number;
    recentTransactionCount: number;
    accountsByType: Record<string, number>;
  };
}

/**
 * Generate a financial report
 */
export async function generateReport(
  params: ReportParams
): Promise<ReportResult> {
  const callable = httpsCallable<ReportParams, ReportResult>(
    functions,
    'generateReport'
  );
  const result = await callable(params);
  return result.data;
}

/**
 * Get dashboard analytics
 */
export async function getDashboardAnalytics(): Promise<DashboardAnalytics> {
  const callable = httpsCallable<void, DashboardAnalytics>(
    functions,
    'getDashboardAnalytics'
  );
  const result = await callable();
  return result.data;
}
