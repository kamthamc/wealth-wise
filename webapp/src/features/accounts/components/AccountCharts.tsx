/**
 * Account Charts Component
 * Visualizations for account data with theme support
 */

import { useMemo } from 'react';
import type { Transaction } from '@/core/db/types';
import {
  GroupedBarChart,
  type GroupedBarDataPoint,
  LineChart,
  type LineChartDataPoint,
} from '@/shared/components';
import { calculateMonthlyStats } from '@/shared/utils';
import './AccountCharts.css';

export interface AccountChartsProps {
  transactions: Transaction[];
  currentBalance: number;
  currency: string;
}

const MONTH_NAMES = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

export function AccountCharts({
  transactions,
  currentBalance,
}: AccountChartsProps) {
  // Calculate monthly statistics with initial balance
  const monthlyStats = useMemo(
    () => calculateMonthlyStats(transactions, 6, currentBalance),
    [transactions, currentBalance]
  );

  // Balance history data - use the balance directly from stats
  const balanceHistory: LineChartDataPoint[] = useMemo(() => {
    return monthlyStats.map((stat) => ({
      label: MONTH_NAMES[stat.month - 1] || '',
      value: stat.balance,
    }));
  }, [monthlyStats]);

  // Income vs Expenses data
  const incomeExpenseData: GroupedBarDataPoint[] = useMemo(() => {
    return monthlyStats.map((stat) => ({
      label: MONTH_NAMES[stat.month - 1] || '',
      values: [
        {
          key: 'Expenses',
          value: stat.expenses,
          color: 'var(--color-danger)',
        },
        {
          key: 'Income',
          value: stat.income,
          color: 'var(--color-success)',
        },
      ],
    }));
  }, [monthlyStats]);

  const hasTransactions = transactions.length > 0;

  return (
    <div className="account-charts">
      {/* Balance History */}
      <div className="account-charts__card">
        <h3 className="account-charts__title">Balance History</h3>
        <p className="account-charts__subtitle">Last 6 months</p>
        {!hasTransactions ? (
          <div className="account-charts__empty">
            <p>Start adding transactions to see your balance trend over time</p>
          </div>
        ) : (
          <LineChart
            data={balanceHistory}
            height={250}
            showGrid
            showLabels
            color="var(--color-primary)"
            fillArea
          />
        )}
      </div>

      {/* Monthly Income/Expense Trend */}
      <div className="account-charts__card">
        <h3 className="account-charts__title">Income vs Expenses</h3>
        <p className="account-charts__subtitle">
          Monthly comparison (last 6 months)
        </p>
        {!hasTransactions ? (
          <div className="account-charts__empty">
            <p>Add income and expense transactions to track your cash flow</p>
          </div>
        ) : (
          <GroupedBarChart data={incomeExpenseData} height={300} showLegend />
        )}
      </div>
    </div>
  );
}
