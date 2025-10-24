/**
 * Reports Page Component
 * Financial reports and analytics dashboard
 */

import {
  BarChart3,
  Calendar,
  Coins,
  Target,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { generateReport /* getDashboardAnalytics */ } from '@/core/api';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import {
  Card,
  EmptyState,
  SegmentedControl,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { TimeRange } from '../types';
import {
  formatMonthLabel,
  getDateRangeForPeriod,
} from '../utils/reportHelpers';
import './ReportsPage.css';

interface CategoryBreakdown {
  category: string;
  amount: number;
  percentage: number;
  count: number;
}

interface MonthlyTrend {
  month: string;
  income: number;
  expense: number;
  net: number;
}

const TIME_RANGE_OPTIONS = [
  {
    value: 'week' as TimeRange,
    label: 'Last 7 Days',
    icon: <Calendar size={16} />,
  },
  { value: 'month' as TimeRange, label: 'Last 30 Days' },
  { value: 'quarter' as TimeRange, label: 'Last 3 Months' },
  { value: 'year' as TimeRange, label: 'Last Year' },
];

export function ReportsPage() {
  const { t } = useTranslation();
  const { transactions } = useTransactionStore();
  const { accounts } = useAccountStore();
  const [selectedPeriod, setSelectedPeriod] = useState<TimeRange>('week');
  // const [loading, setLoading] = useState(false);
  const [reportData, setReportData] = useState<any>(null);
  // const [dashboardData, setDashboardData] = useState<any>(null);

  const dateRange = useMemo(
    () => getDateRangeForPeriod(selectedPeriod),
    [selectedPeriod]
  );

  // Fetch reports from Cloud Functions
  useEffect(() => {
    const fetchReports = async () => {
      // setLoading(true);
      try {
        // Fetch income-expense report
        const incomeExpenseReport = await generateReport({
          startDate: dateRange.start.toISOString(),
          endDate: dateRange.end.toISOString(),
          reportType: 'income-expense',
        });

        // Fetch category breakdown
        const categoryReport = await generateReport({
          startDate: dateRange.start.toISOString(),
          endDate: dateRange.end.toISOString(),
          reportType: 'category-breakdown',
        });

        // Fetch monthly trends
        const trendReport = await generateReport({
          startDate: new Date(
            Date.now() - 180 * 24 * 60 * 60 * 1000
          ).toISOString(), // Last 6 months
          endDate: new Date().toISOString(),
          reportType: 'monthly-trend',
        });

        // Fetch dashboard analytics
        // const analytics = await getDashboardAnalytics();

        setReportData({
          incomeExpense: incomeExpenseReport.report.data,
          categoryBreakdown: categoryReport.report.data,
          monthlyTrends: trendReport.report.data,
        });

        // setDashboardData(analytics.analytics);
      } catch (error) {
        console.error('Error fetching reports:', error);
      } finally {
        // setLoading(false);
      }
    };

    fetchReports();
  }, [dateRange]);

  const summary = useMemo(() => {
    if (!reportData?.incomeExpense) {
      return {
        totalIncome: 0,
        totalExpenses: 0,
        netCashFlow: 0,
        savingsRate: 0,
      };
    }

    const { summary: reportSummary } = reportData.incomeExpense;
    return {
      totalIncome: reportSummary.totalIncome,
      totalExpenses: reportSummary.totalExpense,
      netCashFlow: reportSummary.netSavings,
      savingsRate: reportSummary.savingsRate,
    };
  }, [reportData]);

  const expenseBreakdown = useMemo(() => {
    if (!reportData?.categoryBreakdown) return [];

    return reportData.categoryBreakdown.categories
      .filter((cat: any) => cat.category !== 'Income')
      .map((cat: any) => ({
        category: cat.category,
        amount: cat.total,
        percentage: cat.percentage,
        count: cat.count,
      }));
  }, [reportData]) as CategoryBreakdown[];

  const incomeBreakdown = useMemo(() => {
    // For income, we'll show a simplified view since it's usually fewer categories
    if (!reportData?.categoryBreakdown) return [];

    const incomeCategories = reportData.categoryBreakdown.categories.filter(
      (cat: any) =>
        cat.category === 'Income' ||
        cat.category === 'Salary' ||
        cat.category === 'Bonus'
    );

    return incomeCategories.map((cat: any) => ({
      category: cat.category,
      amount: cat.total,
      percentage: cat.percentage,
      count: cat.count,
    }));
  }, [reportData]) as CategoryBreakdown[];

  const monthlyTrends = useMemo(() => {
    if (!reportData?.monthlyTrends) return [];

    return reportData.monthlyTrends.trends.map((trend: any) => ({
      month: trend.month,
      income: trend.income,
      expense: trend.expense,
      net: trend.income - trend.expense,
    }));
  }, [reportData]) as MonthlyTrend[];

  const accountBalances = useMemo(() => {
    return accounts.map((account) => ({
      id: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance,
    }));
  }, [accounts]);

  const hasData = transactions.length > 0;

  return (
    <div className="reports-page">
      <div className="reports-page__header">
        <h1 className="reports-page__title">Financial Reports</h1>
        <p className="reports-page__description">
          Analyze your financial data and track trends
        </p>
      </div>

      {/* Period Selector with SegmentedControl */}
      <div className="reports-page__period-selector">
        <SegmentedControl
          options={TIME_RANGE_OPTIONS}
          value={selectedPeriod}
          onChange={setSelectedPeriod}
          size="medium"
          aria-label="Select time range"
        />
      </div>

      {!hasData ? (
        <EmptyState
          icon={<BarChart3 size={48} />}
          title="No Financial Data Yet"
          description="Start adding accounts and transactions to see your financial reports and analytics"
        />
      ) : (
        <>
          {/* Summary Stats */}
          <section className="reports-page__summary">
            <h2 className="reports-page__section-title">Summary</h2>
            <div className="reports-page__stats-grid">
              <StatCard
                label="Total Income"
                value={formatCurrency(summary.totalIncome)}
                icon={<TrendingUp size={24} />}
                variant="success"
              />
              <StatCard
                label="Total Expenses"
                value={formatCurrency(summary.totalExpenses)}
                icon={<TrendingDown size={24} />}
                variant="danger"
              />
              <StatCard
                label="Net Cash Flow"
                value={formatCurrency(summary.netCashFlow)}
                icon={<Coins size={24} />}
                variant={summary.netCashFlow >= 0 ? 'success' : 'danger'}
              />
              <StatCard
                label="Savings Rate"
                value={`${Math.round(summary.savingsRate)}%`}
                icon={<Target size={24} />}
                variant={summary.savingsRate >= 20 ? 'success' : 'warning'}
                description={
                  summary.savingsRate >= 50
                    ? 'Excellent!'
                    : summary.savingsRate >= 20
                      ? 'Good'
                      : 'Can improve'
                }
              />
            </div>
          </section>

          {/* Expense Breakdown */}
          <section className="reports-page__section">
            <Card>
              <h2 className="reports-page__section-title">
                Top Expense Categories
              </h2>
              {expenseBreakdown.length > 0 ? (
                <div className="reports-page__category-list">
                  {expenseBreakdown.slice(0, 10).map((category) => (
                    <div key={category.category} className="category-item">
                      <div className="category-item__header">
                        <span className="category-item__name">
                          {category.category}
                        </span>
                        <span className="category-item__amount">
                          {formatCurrency(category.amount)}
                        </span>
                      </div>
                      <div className="category-item__bar-container">
                        <div
                          className="category-item__bar"
                          style={{ width: `${category.percentage}%` }}
                        />
                      </div>
                      <div className="category-item__footer">
                        <span className="category-item__percentage">
                          {Math.round(category.percentage)}%
                        </span>
                        <span className="category-item__count">
                          {category.count} transaction
                          {category.count !== 1 ? 's' : ''}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="reports-page__empty">
                  No expense data for this period
                </p>
              )}
            </Card>
          </section>

          {/* Income Breakdown */}
          <section className="reports-page__section">
            <Card>
              <h2 className="reports-page__section-title">Income Sources</h2>
              {incomeBreakdown.length > 0 ? (
                <div className="reports-page__category-list">
                  {incomeBreakdown.slice(0, 5).map((category) => (
                    <div
                      key={category.category}
                      className="category-item category-item--income"
                    >
                      <div className="category-item__header">
                        <span className="category-item__name">
                          {category.category}
                        </span>
                        <span className="category-item__amount">
                          {formatCurrency(category.amount)}
                        </span>
                      </div>
                      <div className="category-item__bar-container">
                        <div
                          className="category-item__bar"
                          style={{ width: `${category.percentage}%` }}
                        />
                      </div>
                      <div className="category-item__footer">
                        <span className="category-item__percentage">
                          {Math.round(category.percentage)}%
                        </span>
                        <span className="category-item__count">
                          {category.count} transaction
                          {category.count !== 1 ? 's' : ''}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="reports-page__empty">
                  No income data for this period
                </p>
              )}
            </Card>
          </section>

          {/* Monthly Trends */}
          <section className="reports-page__section">
            <Card>
              <h2 className="reports-page__section-title">6-Month Trend</h2>
              <div className="reports-page__trends">
                {monthlyTrends.map((trend) => (
                  <div key={trend.month} className="trend-item">
                    <div className="trend-item__month">
                      {formatMonthLabel(trend.month)}
                    </div>
                    <div className="trend-item__bars">
                      <div className="trend-item__bar-row">
                        <span className="trend-item__label">Income</span>
                        <div className="trend-item__bar-bg">
                          <div
                            className="trend-item__bar trend-item__bar--income"
                            style={{
                              width: `${Math.min((trend.income / 100000) * 100, 100)}%`,
                            }}
                          />
                        </div>
                        <span className="trend-item__value">
                          {formatCurrency(trend.income)}
                        </span>
                      </div>
                      <div className="trend-item__bar-row">
                        <span className="trend-item__label">Expenses</span>
                        <div className="trend-item__bar-bg">
                          <div
                            className="trend-item__bar trend-item__bar--expense"
                            style={{
                              width: `${Math.min((trend.expense / 100000) * 100, 100)}%`,
                            }}
                          />
                        </div>
                        <span className="trend-item__value">
                          {formatCurrency(trend.expense)}
                        </span>
                      </div>
                    </div>
                    <div className="trend-item__savings">
                      Net: {formatCurrency(trend.net)} (
                      {trend.income > 0
                        ? Math.round((trend.net / trend.income) * 100)
                        : 0}
                      %)
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          </section>

          {/* Account Balances */}
          <section className="reports-page__section">
            <Card>
              <h2 className="reports-page__section-title">Account Balances</h2>
              {accountBalances.length > 0 ? (
                <div className="reports-page__accounts">
                  {accountBalances.map((account) => (
                    <div key={account.id} className="account-balance">
                      <div className="account-balance__header">
                        <span className="account-balance__name">
                          {account.name}
                        </span>
                        <span className="account-balance__type">
                          {account.type}
                        </span>
                      </div>
                      <div className="account-balance__amount">
                        {formatCurrency(account.balance)}
                      </div>
                    </div>
                  ))}
                  <div className="account-balance account-balance--total">
                    <div className="account-balance__header">
                      <span className="account-balance__name">
                        Total Balance
                      </span>
                    </div>
                    <div className="account-balance__amount">
                      {formatCurrency(
                        accountBalances.reduce((sum, a) => sum + a.balance, 0)
                      )}
                    </div>
                  </div>
                </div>
              ) : (
                <p className="reports-page__empty">
                  {t('emptyState.accounts.title')}
                </p>
              )}
            </Card>
          </section>
        </>
      )}
    </div>
  );
}
