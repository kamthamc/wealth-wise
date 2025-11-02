/**
 * Account Breakdown Component
 * Visual breakdown of accounts and asset allocation
 */

import { useNavigate } from '@tanstack/react-router';
import { ChevronRight, PieChart } from 'lucide-react';
import { useMemo } from 'react';
import type { AccountType } from '@/core/db/types';
import { useAccountStore } from '@/core/stores';
import {
  getAccountIcon,
  getAccountTypeName,
} from '@/features/accounts/utils/accountHelpers';
import { formatCurrency } from '@/utils';
import { usePreferences } from '@/hooks/usePreferences';
import './AccountBreakdown.css';

interface AccountTypeData {
  type: AccountType;
  count: number;
  balance: number;
  percentage: number;
  color: string;
}

const ACCOUNT_TYPE_COLORS: Record<AccountType, string> = {
  // Banking & Cash
  bank: '#3b82f6',
  credit_card: '#f59e0b',
  upi: '#8b5cf6',
  cash: '#6366f1',
  wallet: '#ec4899',
  // Deposits & Savings
  fixed_deposit: '#f97316',
  recurring_deposit: '#34d399',
  ppf: '#eab308',
  nsc: '#22d3ee',
  kvp: '#14b8a6',
  scss: '#f87171',
  post_office: '#f43f5e',
  ssy: '#fbbf24',
  // Investments & Brokerage
  brokerage: '#10b981',
  mutual_fund: '#059669',
  stocks: '#84cc16',
  bonds: '#06b6d4',
  etf: '#14b8a6',
  // Insurance
  term_insurance: '#6366f1',
  endowment: '#8b5cf6',
  money_back: '#a855f7',
  ulip: '#c026d3',
  child_plan: '#d946ef',
  // Retirement
  nps: '#f59e0b',
  apy: '#f97316',
  epf: '#fb923c',
  vpf: '#fdba74',
  // Real Estate
  property: '#78716c',
  reit: '#a8a29e',
  invit: '#d6d3d1',
  // Precious Metals
  gold: '#fbbf24',
  silver: '#d1d5db',
  // Alternative Investments
  p2p_lending: '#4ade80',
  chit_fund: '#22d3ee',
  cryptocurrency: '#a78bfa',
  commodity: '#fb7185',
  hedge_fund: '#f472b6',
  angel_investment: '#e879f9',
};

export function AccountBreakdown() {
  const navigate = useNavigate();
  const { accounts, isLoading } = useAccountStore();
  const { preferences, loading: prefsLoading } = usePreferences();

  const breakdown: AccountTypeData[] = useMemo(() => {
    const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);

    // Group accounts by type
    const typeMap = new Map<AccountType, { count: number; balance: number }>();

    accounts.forEach((acc) => {
      const existing = typeMap.get(acc.type) || { count: 0, balance: 0 };
      typeMap.set(acc.type, {
        count: existing.count + 1,
        balance: existing.balance + acc.balance,
      });
    });

    // Convert to array and calculate percentages
    const data: AccountTypeData[] = Array.from(typeMap.entries())
      .map(([type, data]) => ({
        type,
        count: data.count,
        balance: data.balance,
        percentage: totalBalance > 0 ? (data.balance / totalBalance) * 100 : 0,
        color: ACCOUNT_TYPE_COLORS[type],
      }))
      .sort((a, b) => b.balance - a.balance);

    return data;
  }, [accounts]);

  const totalBalance = useMemo(
    () => accounts.reduce((sum, acc) => sum + acc.balance, 0),
    [accounts]
  );

  if (isLoading || prefsLoading) {
    return (
      <section className="account-breakdown">
        <div className="account-breakdown__header">
          <h2 className="account-breakdown__title">Asset Breakdown</h2>
        </div>
        <div className="account-breakdown__loading">
          <div className="account-breakdown__skeleton-chart" />
          <div className="account-breakdown__skeleton-list">
            {[1, 2, 3].map((i) => (
              <div key={i} className="account-breakdown__skeleton-item" />
            ))}
          </div>
        </div>
      </section>
    );
  }

  if (accounts.length === 0) {
    return (
      <section className="account-breakdown">
        <div className="account-breakdown__header">
          <h2 className="account-breakdown__title">Asset Breakdown</h2>
        </div>
        <div className="account-breakdown__empty">
          <PieChart size={48} className="account-breakdown__empty-icon" />
          <p className="account-breakdown__empty-text">
            Add accounts to see your asset breakdown
          </p>
        </div>
      </section>
    );
  }

  return (
    <section className="account-breakdown">
      <div className="account-breakdown__header">
        <h2 className="account-breakdown__title">Asset Breakdown</h2>
        <p className="account-breakdown__subtitle">
          {formatCurrency(
            totalBalance,
            preferences?.currency || 'INR',
            preferences?.locale || 'en-IN'
          )} across {accounts.length} accounts
        </p>
      </div>

      <div className="account-breakdown__content">
        {/* Donut Chart Visualization */}
        <div className="account-breakdown__chart">
          <div className="account-breakdown__donut">
            {breakdown.map((item, index) => {
              // Calculate stroke-dasharray for donut segments
              const circumference = 2 * Math.PI * 45; // radius = 45
              const offset = breakdown
                .slice(0, index)
                .reduce(
                  (sum, b) => sum + (b.percentage / 100) * circumference,
                  0
                );

              return (
                <circle
                  key={item.type}
                  className="account-breakdown__donut-segment"
                  cx="50"
                  cy="50"
                  r="45"
                  fill="none"
                  stroke={item.color}
                  strokeWidth="10"
                  strokeDasharray={`${(item.percentage / 100) * circumference} ${circumference}`}
                  strokeDashoffset={-offset}
                  style={{
                    transform: 'rotate(-90deg)',
                    transformOrigin: '50% 50%',
                  }}
                />
              );
            })}
          </div>
          <div className="account-breakdown__chart-center">
            <PieChart size={32} className="account-breakdown__chart-icon" />
            <span className="account-breakdown__chart-label">Assets</span>
          </div>
        </div>

        {/* Breakdown List */}
        <div className="account-breakdown__list">
          {breakdown.map((item) => (
            <button
              key={item.type}
              type="button"
              className="account-breakdown__item"
              onClick={() => navigate({ to: '/accounts' })}
            >
              <div className="account-breakdown__item-icon-wrapper">
                <span
                  className="account-breakdown__item-color"
                  style={{ backgroundColor: item.color }}
                />
                <span className="account-breakdown__item-icon">
                  {getAccountIcon(item.type)}
                </span>
              </div>
              <div className="account-breakdown__item-content">
                <div className="account-breakdown__item-header">
                  <span className="account-breakdown__item-name">
                    {getAccountTypeName(item.type)}
                  </span>
                  <span className="account-breakdown__item-count">
                    {item.count} {item.count === 1 ? 'account' : 'accounts'}
                  </span>
                </div>
                <div className="account-breakdown__item-footer">
                  <span className="account-breakdown__item-amount">
                    {formatCurrency(
                      item.balance,
                      preferences?.currency || 'INR',
                      preferences?.locale || 'en-IN'
                    )}
                  </span>
                  <span className="account-breakdown__item-percentage">
                    {item.percentage.toFixed(1)}%
                  </span>
                </div>
                <div className="account-breakdown__item-bar">
                  <div
                    className="account-breakdown__item-bar-fill"
                    style={{
                      width: `${item.percentage}%`,
                      backgroundColor: item.color,
                    }}
                  />
                </div>
              </div>
              <ChevronRight
                size={20}
                className="account-breakdown__item-arrow"
              />
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
