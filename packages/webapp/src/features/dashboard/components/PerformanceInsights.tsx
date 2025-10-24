/**
 * Performance Insights Component
 * Shows monthly financial performance with trends
 */

import {
  ArrowDown,
  ArrowUp,
  PiggyBank,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import { useMemo } from 'react';
import { useTransactionStore } from '@/core/stores';
import { formatCurrency } from '@/shared/utils';
import './PerformanceInsights.css';

interface MonthlyPerformance {
  income: number;
  expenses: number;
  savings: number;
  savingsRate: number;
  previousIncome: number;
  previousExpenses: number;
  previousSavings: number;
  incomeTrend: number;
  expenseTrend: number;
  savingsTrend: number;
}

export function PerformanceInsights() {
  const { transactions, isLoading } = useTransactionStore();

  const performance: MonthlyPerformance = useMemo(() => {
    const now = new Date();
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);

    // Current month transactions
    const currentMonthTxns = transactions.filter(
      (t) => t.date >= currentMonthStart
    );

    const income = currentMonthTxns
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);

    const expenses = currentMonthTxns
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);

    const savings = income - expenses;
    const savingsRate = income > 0 ? (savings / income) * 100 : 0;

    // Previous month transactions
    const prevMonthTxns = transactions.filter(
      (t) => t.date >= prevMonthStart && t.date <= prevMonthEnd
    );

    const previousIncome = prevMonthTxns
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);

    const previousExpenses = prevMonthTxns
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);

    const previousSavings = previousIncome - previousExpenses;

    // Calculate trends
    const incomeTrend =
      previousIncome > 0
        ? ((income - previousIncome) / previousIncome) * 100
        : 0;
    const expenseTrend =
      previousExpenses > 0
        ? ((expenses - previousExpenses) / previousExpenses) * 100
        : 0;
    const savingsTrend =
      previousSavings > 0
        ? ((savings - previousSavings) / previousSavings) * 100
        : 0;

    return {
      income,
      expenses,
      savings,
      savingsRate,
      previousIncome,
      previousExpenses,
      previousSavings,
      incomeTrend,
      expenseTrend,
      savingsTrend,
    };
  }, [transactions]);

  if (isLoading) {
    return (
      <section className="performance-insights">
        <div className="performance-insights__header">
          <h2 className="performance-insights__title">Performance Insights</h2>
        </div>
        <div className="performance-insights__grid">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="performance-insights__card performance-insights__card--loading"
            />
          ))}
        </div>
      </section>
    );
  }

  return (
    <section className="performance-insights">
      <div className="performance-insights__header">
        <h2 className="performance-insights__title">
          This Month's Performance
        </h2>
        <p className="performance-insights__subtitle">
          Track your financial health and savings progress
        </p>
      </div>

      <div className="performance-insights__grid">
        {/* Income Card */}
        <div className="performance-insights__card performance-insights__card--income">
          <div className="performance-insights__card-header">
            <div className="performance-insights__card-icon performance-insights__card-icon--income">
              <TrendingUp size={24} />
            </div>
            <div className="performance-insights__card-meta">
              <span className="performance-insights__card-label">Income</span>
              <div
                className={`performance-insights__card-trend ${
                  performance.incomeTrend >= 0 ? 'positive' : 'negative'
                }`}
              >
                {performance.incomeTrend >= 0 ? (
                  <ArrowUp size={14} />
                ) : (
                  <ArrowDown size={14} />
                )}
                <span>{Math.abs(performance.incomeTrend).toFixed(1)}%</span>
              </div>
            </div>
          </div>
          <div className="performance-insights__card-value">
            {formatCurrency(performance.income)}
          </div>
          <div className="performance-insights__card-footer">
            <span className="performance-insights__card-comparison">
              vs {formatCurrency(performance.previousIncome)} last month
            </span>
          </div>
        </div>

        {/* Expenses Card */}
        <div className="performance-insights__card performance-insights__card--expense">
          <div className="performance-insights__card-header">
            <div className="performance-insights__card-icon performance-insights__card-icon--expense">
              <TrendingDown size={24} />
            </div>
            <div className="performance-insights__card-meta">
              <span className="performance-insights__card-label">Expenses</span>
              <div
                className={`performance-insights__card-trend ${
                  performance.expenseTrend <= 0 ? 'positive' : 'negative'
                }`}
              >
                {performance.expenseTrend <= 0 ? (
                  <ArrowDown size={14} />
                ) : (
                  <ArrowUp size={14} />
                )}
                <span>{Math.abs(performance.expenseTrend).toFixed(1)}%</span>
              </div>
            </div>
          </div>
          <div className="performance-insights__card-value">
            {formatCurrency(performance.expenses)}
          </div>
          <div className="performance-insights__card-footer">
            <span className="performance-insights__card-comparison">
              vs {formatCurrency(performance.previousExpenses)} last month
            </span>
          </div>
        </div>

        {/* Savings Card */}
        <div className="performance-insights__card performance-insights__card--savings">
          <div className="performance-insights__card-header">
            <div className="performance-insights__card-icon performance-insights__card-icon--savings">
              <PiggyBank size={24} />
            </div>
            <div className="performance-insights__card-meta">
              <span className="performance-insights__card-label">Savings</span>
              <div
                className={`performance-insights__card-trend ${
                  performance.savingsTrend >= 0 ? 'positive' : 'negative'
                }`}
              >
                {performance.savingsTrend >= 0 ? (
                  <ArrowUp size={14} />
                ) : (
                  <ArrowDown size={14} />
                )}
                <span>{Math.abs(performance.savingsTrend).toFixed(1)}%</span>
              </div>
            </div>
          </div>
          <div className="performance-insights__card-value">
            {formatCurrency(performance.savings)}
          </div>
          <div className="performance-insights__card-footer">
            <div className="performance-insights__savings-rate">
              <div className="performance-insights__savings-rate-bar">
                <div
                  className="performance-insights__savings-rate-fill"
                  style={{
                    width: `${Math.min(performance.savingsRate, 100)}%`,
                  }}
                />
              </div>
              <span className="performance-insights__savings-rate-label">
                {performance.savingsRate.toFixed(0)}% savings rate
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
