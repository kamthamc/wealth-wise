/**
 * Reports Helper Utilities
 * Helper functions for report calculations and data processing
 */

import { timestampToDate } from '@/core/utils/firebase';
import type { Transaction } from '@/core/types';
import type {
  CategoryBreakdown,
  DateRange,
  IncomeExpenseData,
  MonthlyTrend,
  ReportSummary,
  TimeRange,
} from '../types';

/**
 * Get date range for a time period
 */
export function getDateRangeForPeriod(period: TimeRange): DateRange {
  const end = new Date();
  end.setHours(23, 59, 59, 999);

  const start = new Date();
  start.setHours(0, 0, 0, 0);

  switch (period) {
    case 'week':
      start.setDate(end.getDate() - 7);
      break;
    case 'month':
      start.setMonth(end.getMonth() - 1);
      break;
    case 'quarter':
      start.setMonth(end.getMonth() - 3);
      break;
    case 'year':
      start.setFullYear(end.getFullYear() - 1);
      break;
    default:
      start.setMonth(end.getMonth() - 1);
  }

  return { start, end };
}

/**
 * Filter transactions by date range
 */
export function filterTransactionsByDateRange(
  transactions: Transaction[],
  range: DateRange
): Transaction[] {
  return transactions.filter(
    (t) => t.date >= range.start && t.date <= range.end
  );
}

/**
 * Calculate income vs expense data for chart
 */
export function calculateIncomeExpenseData(
  transactions: Transaction[],
  range: DateRange
): IncomeExpenseData[] {
  const dayMap = new Map<string, IncomeExpenseData>();

  // Initialize all days in range
  const current = new Date(range.start);
  while (current <= range.end) {
    const dateKey = current.toISOString().split('T')[0];
    if (dateKey) {
      dayMap.set(dateKey, {
        date: dateKey,
        income: 0,
        expenses: 0,
        net: 0,
      });
    }
    current.setDate(current.getDate() + 1);
  }

  // Aggregate transactions
  transactions.forEach((t) => {
    const date = timestampToDate(t.date);
    const dateKey = date.toISOString().split('T')[0];
    if (dateKey) {
      const data = dayMap.get(dateKey);

      if (data) {
        if (t.type === 'income') {
          data.income += t.amount;
        } else if (t.type === 'expense') {
          data.expenses += t.amount;
        }
        data.net = data.income - data.expenses;
      }
    }
  });

  return Array.from(dayMap.values()).sort(
    (a, b) => timestampToDate(a.date).getTime() - timestampToDate(b.date).getTime()
  );
}

/**
 * Calculate category breakdown
 */
export function calculateCategoryBreakdown(
  transactions: Transaction[],
  type: 'income' | 'expense'
): CategoryBreakdown[] {
  const categoryMap = new Map<string, { amount: number; count: number }>();
  const filtered = transactions.filter((t) => t.type === type);

  filtered.forEach((t) => {
    const category = t.category || 'Uncategorized';
    const existing = categoryMap.get(category) || { amount: 0, count: 0 };
    categoryMap.set(category, {
      amount: existing.amount + t.amount,
      count: existing.count + 1,
    });
  });

  const total = filtered.reduce((sum, t) => sum + t.amount, 0);

  return Array.from(categoryMap.entries())
    .map(([category, data]) => ({
      category,
      amount: data.amount,
      percentage: total > 0 ? (data.amount / total) * 100 : 0,
      count: data.count,
    }))
    .sort((a, b) => b.amount - a.amount);
}

/**
 * Calculate monthly trends
 */
export function calculateMonthlyTrends(
  transactions: Transaction[],
  months: number = 6
): MonthlyTrend[] {
  const monthMap = new Map<string, { income: number; expenses: number }>();

  // Initialize months
  const now = new Date();
  for (let i = months - 1; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    monthMap.set(key, { income: 0, expenses: 0 });
  }

  // Aggregate transactions
  transactions.forEach((t) => {
    const date = timestampToDate(t.date);
    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    const data = monthMap.get(key);

    if (data) {
      if (t.type === 'income') {
        data.income += t.amount;
      } else if (t.type === 'expense') {
        data.expenses += t.amount;
      }
    }
  });

  return Array.from(monthMap.entries()).map(([month, data]) => {
    const savings = data.income - data.expenses;
    const savingsRate = data.income > 0 ? (savings / data.income) * 100 : 0;

    return {
      month,
      income: data.income,
      expenses: data.expenses,
      savings,
      savingsRate,
    };
  });
}

/**
 * Calculate report summary
 */
export function calculateReportSummary(
  transactions: Transaction[],
  range: DateRange
): ReportSummary {
  const filtered = filterTransactionsByDateRange(transactions, range);

  const totalIncome = filtered
    .filter((t) => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpenses = filtered
    .filter((t) => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  const netCashFlow = totalIncome - totalExpenses;
  const savingsRate = totalIncome > 0 ? (netCashFlow / totalIncome) * 100 : 0;

  const categoryBreakdown = calculateCategoryBreakdown(filtered, 'expense');
  const topCategory =
    categoryBreakdown.length > 0 ? categoryBreakdown[0] : null;

  const averageTransaction =
    filtered.length > 0
      ? filtered.reduce((sum, t) => sum + t.amount, 0) / filtered.length
      : 0;

  return {
    totalIncome,
    totalExpenses,
    netCashFlow,
    savingsRate,
    transactionCount: filtered.length,
    averageTransaction,
    topCategory: topCategory ?? null,
    period: range,
  };
}

/**
 * Format month label for display
 */
export function formatMonthLabel(monthKey: string): string {
  const [year, month] = monthKey.split('-');
  const date = new Date(Number(year), Number(month) - 1);
  return date.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' });
}

/**
 * Get period label
 */
export function getPeriodLabel(period: TimeRange): string {
  const labels: Record<TimeRange, string> = {
    week: 'Last 7 Days',
    month: 'Last 30 Days',
    quarter: 'Last 3 Months',
    year: 'Last Year',
    custom: 'Custom Range',
  };
  return labels[period];
}
