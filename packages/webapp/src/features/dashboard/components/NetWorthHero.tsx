/**
 * Net Worth Hero Component
 * Primary dashboard metric showing total net worth with performance trends
 */

import { ArrowDown, ArrowUp, TrendingDown, TrendingUp } from 'lucide-react';
import { useEffect, useMemo } from 'react';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { LineChart } from '@/shared/components';
import {
  calculateMonthlyStats,
  calculateNetWorth,
  formatCurrency,
} from '@/shared/utils';
import './NetWorthHero.css';
import { getAccountTypes } from '@/core/functions/accounts';

interface NetWorthData {
  current: number;
  change: number;
  changePercent: number;
  isPositive: boolean;
  periodLabel: string;
}

export function NetWorthHero() {
  const { accounts, isLoading: accountsLoading } = useAccountStore();
  const { transactions } = useTransactionStore();

  const netWorthData: NetWorthData = useMemo(() => {
    // Calculate current net worth using calculateNetWorth function
    const current = calculateNetWorth(accounts, transactions);

    // Calculate net worth from previous month
    const now = new Date();
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    // Get all transactions from current month
    const currentMonthTransactions = transactions.filter(
      (t) => new Date(t.date) >= currentMonthStart
    );

    // Calculate net change this month (income - expenses)
    const income = currentMonthTransactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + Number(t.amount || 0), 0);

    const expenses = currentMonthTransactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + Number(t.amount || 0), 0);

    const change = income - expenses;
    const previousNetWorth = current - change;
    const changePercent =
      previousNetWorth !== 0 ? (change / previousNetWorth) * 100 : 0;

    return {
      current,
      change,
      changePercent,
      isPositive: change >= 0,
      periodLabel: 'This Month',
    };
  }, [accounts, transactions]);

  // Calculate 6-month net worth trend for the sparkline
  const netWorthTrend = useMemo(() => {
    const monthlyStats = calculateMonthlyStats(transactions, 6);

    // Calculate net worth at each month
    return monthlyStats.map((stat) => {
      // Sum initial balances
      const initialTotal = accounts
        .filter((acc) => acc.is_active)
        .reduce((sum, acc) => sum + Number(acc.balance || 0), 0);

      // Add the running balance from transactions
      return {
        label:
          [
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
          ][stat.month - 1] || '',
        value: initialTotal + stat.balance,
      };
    });
  }, [accounts, transactions]);

  useEffect(() => {
    getAccountTypes().then((types) => {
      console.log('Account Types:', types);
    });
  }, []);

  if (accountsLoading) {
    return (
      <div className="networth-hero networth-hero--loading">
        <div className="networth-hero__skeleton">
          <div className="networth-hero__skeleton-label" />
          <div className="networth-hero__skeleton-value" />
          <div className="networth-hero__skeleton-change" />
        </div>
      </div>
    );
  }

  return (
    <section className="networth-hero">
      <div className="networth-hero__container">
        <div className="networth-hero__main">
          <div className="networth-hero__label">
            <span className="networth-hero__label-icon">💎</span>
            <span className="networth-hero__label-text">Total Net Worth</span>
          </div>

          <div className="networth-hero__value">
            {formatCurrency(netWorthData.current)}
          </div>

          <div
            className={`networth-hero__change ${
              netWorthData.isPositive
                ? 'networth-hero__change--positive'
                : 'networth-hero__change--negative'
            }`}
          >
            <div className="networth-hero__change-icon">
              {netWorthData.isPositive ? (
                <ArrowUp size={20} />
              ) : (
                <ArrowDown size={20} />
              )}
            </div>
            <div className="networth-hero__change-content">
              <span className="networth-hero__change-amount">
                {formatCurrency(Math.abs(netWorthData.change))}
              </span>
              <span className="networth-hero__change-percent">
                ({Math.abs(netWorthData.changePercent).toFixed(2)}%)
              </span>
              <span className="networth-hero__change-period">
                {netWorthData.periodLabel}
              </span>
            </div>
          </div>
        </div>

        <div className="networth-hero__visual">
          <div className="networth-hero__trend-icon">
            {netWorthData.isPositive ? (
              <TrendingUp size={64} className="networth-hero__trend-icon--up" />
            ) : (
              <TrendingDown
                size={64}
                className="networth-hero__trend-icon--down"
              />
            )}
          </div>
          <div className="networth-hero__sparkline">
            <LineChart
              data={netWorthTrend}
              height={120}
              showGrid={false}
              showLabels={false}
              color={
                netWorthData.isPositive
                  ? 'var(--color-success)'
                  : 'var(--color-danger)'
              }
              fillArea
            />
          </div>
        </div>
      </div>
    </section>
  );
}
