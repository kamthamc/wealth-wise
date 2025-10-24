/**
 * Reports Feature Types
 * Type definitions for financial reports and analytics
 */

export type TimeRange = 'week' | 'month' | 'quarter' | 'year' | 'custom';

export interface DateRange {
  start: Date;
  end: Date;
}

export interface IncomeExpenseData {
  date: string;
  income: number;
  expenses: number;
  net: number;
}

export interface CategoryBreakdown {
  category: string;
  amount: number;
  percentage: number;
  count: number;
}

export interface MonthlyTrend {
  month: string;
  income: number;
  expenses: number;
  savings: number;
  savingsRate: number;
}

export interface AccountBalance {
  accountId: string;
  accountName: string;
  balance: number;
  change: number;
}

export interface ReportSummary {
  totalIncome: number;
  totalExpenses: number;
  netCashFlow: number;
  savingsRate: number;
  transactionCount: number;
  averageTransaction: number;
  topCategory: CategoryBreakdown | null;
  period: DateRange;
}
