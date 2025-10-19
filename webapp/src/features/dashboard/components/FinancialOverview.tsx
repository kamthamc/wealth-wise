/**
 * Financial Overview Component
 * Display key financial statistics
 */

import { useMemo } from 'react';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { StatCard } from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import './FinancialOverview.css';

export function FinancialOverview() {
  const { accounts } = useAccountStore();
  const { transactions } = useTransactionStore();

  const stats = useMemo(() => {
    // Calculate total balance from all accounts
    const totalBalance = accounts.reduce(
      (sum, account) => sum + account.balance,
      0
    );

    // Get current month transactions
    const now = new Date();
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const currentMonthTransactions = transactions.filter(
      (t) => t.date >= currentMonthStart
    );

    // Calculate income and expenses
    const income = currentMonthTransactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);

    const expenses = currentMonthTransactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);

    // Calculate savings rate
    const savingsRate = income > 0 ? ((income - expenses) / income) * 100 : 0;

    // Get previous month data for trends
    const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);
    const prevMonthTransactions = transactions.filter(
      (t) => t.date >= prevMonthStart && t.date <= prevMonthEnd
    );

    const prevIncome = prevMonthTransactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);

    const prevExpenses = prevMonthTransactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);

    // Calculate trends
    const incomeTrend =
      prevIncome > 0 ? ((income - prevIncome) / prevIncome) * 100 : 0;
    const expenseTrend =
      prevExpenses > 0 ? ((expenses - prevExpenses) / prevExpenses) * 100 : 0;

    return [
      {
        label: 'Total Balance',
        value: formatCurrency(totalBalance),
        description: `Across ${accounts.length} account${accounts.length !== 1 ? 's' : ''}`,
        variant: 'primary' as const,
        icon: '💰',
      },
      {
        label: 'This Month Income',
        value: formatCurrency(income),
        trend: prevIncome > 0 ? {
          value: Math.abs(incomeTrend),
          label: 'vs last month',
          isPositive: incomeTrend >= 0,
        } : undefined,
        variant: 'success' as const,
        icon: '📈',
      },
      {
        label: 'This Month Expenses',
        value: formatCurrency(expenses),
        trend: prevExpenses > 0 ? {
          value: Math.abs(expenseTrend),
          label: 'vs last month',
          isPositive: expenseTrend <= 0, // Lower expenses is positive
        } : undefined,
        variant: 'danger' as const,
        icon: '📉',
      },
      {
        label: 'Savings Rate',
        value: `${Math.round(savingsRate)}%`,
        description:
          savingsRate >= 50
            ? 'Excellent savings!'
            : savingsRate >= 20
              ? 'Good savings'
              : 'Try to save more',
        variant: savingsRate >= 50
          ? ('success' as const)
          : savingsRate >= 20
            ? ('default' as const)
            : ('warning' as const),
        icon: '🎯',
      },
    ];
  }, [accounts, transactions]);

  return (
    <section className="financial-overview">
      <h2 className="financial-overview__title">Financial Overview</h2>
      <div className="financial-overview__grid">
        {stats.map((stat) => (
          <StatCard
            key={stat.label}
            label={stat.label}
            value={stat.value}
            trend={stat.trend}
            description={stat.description}
            variant={stat.variant}
            icon={<span className="financial-overview__icon">{stat.icon}</span>}
          />
        ))}
      </div>
    </section>
  );
}
