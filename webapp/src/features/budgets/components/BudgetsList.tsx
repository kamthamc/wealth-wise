/**
 * Budgets List Component
 * Main budgets management page
 */

import { useMemo, useState } from 'react';
import { useBudgetStore } from '@/core/stores';
import {
  Button,
  EmptyState,
  Input,
  Spinner,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { BudgetFilters, BudgetPeriod } from '../types';
import {
  calculateBudgetProgress,
  formatBudgetPercentage,
  getBudgetPeriodIcon,
  getBudgetPeriodName,
} from '../utils/budgetHelpers';
import './BudgetsList.css';

const PERIOD_OPTIONS: (BudgetPeriod | 'all')[] = [
  'all',
  'daily',
  'weekly',
  'monthly',
  'yearly',
];

export function BudgetsList() {
  const { budgets, isLoading } = useBudgetStore();

  const [filters, setFilters] = useState<BudgetFilters>({});
  const [searchQuery, setSearchQuery] = useState('');
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter and search budgets
  const filteredBudgets = useMemo(() => {
    let filtered = budgets;

    // Filter by period
    if (filters.period) {
      filtered = filtered.filter((budget) => budget.period === filters.period);
    }

    // Filter by active status
    if (filters.is_active !== undefined) {
      filtered = filtered.filter(
        (budget) => budget.is_active === filters.is_active
      );
    }

    // Search by name or category
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (budget) =>
          budget.name.toLowerCase().includes(query) ||
          budget.category.toLowerCase().includes(query)
      );
    }

    return filtered;
  }, [budgets, filters, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const activeBudgets = budgets.filter((b) => b.is_active);
    const totalBudget = activeBudgets.reduce((sum, b) => sum + b.amount, 0);
    const totalSpent = activeBudgets.reduce((sum, b) => sum + b.spent, 0);
    const overBudget = activeBudgets.filter((b) => b.spent >= b.amount).length;

    return {
      totalBudget,
      totalSpent,
      remainingBudget: totalBudget - totalSpent,
      budgetCount: activeBudgets.length,
      overBudgetCount: overBudget,
    };
  }, [budgets]);

  if (isLoading) {
    return (
      <div className="budgets-page__loading">
        <Spinner size="large" />
        <p style={{ color: 'var(--color-text-secondary)' }}>
          Loading budgets...
        </p>
      </div>
    );
  }

  return (
    <div className="budgets-page">
      {/* Header */}
      <div className="budgets-page__header">
        <h1 className="budgets-page__title">Budgets</h1>
        <Button onClick={() => setIsFormOpen(true)}>+ Add Budget</Button>
      </div>

      {/* Stats */}
      <div className="budgets-page__stats">
        <StatCard
          label="Total Budget"
          value={formatCurrency(stats.totalBudget)}
          icon="💰"
        />
        <StatCard
          label="Total Spent"
          value={formatCurrency(stats.totalSpent)}
          icon="💸"
          variant="danger"
        />
        <StatCard
          label="Remaining"
          value={formatCurrency(stats.remainingBudget)}
          icon="📊"
          variant={stats.remainingBudget >= 0 ? 'success' : 'danger'}
        />
        <StatCard
          label="Over Budget"
          value={stats.overBudgetCount.toString()}
          icon="⚠️"
          variant={stats.overBudgetCount > 0 ? 'danger' : 'success'}
        />
      </div>

      {/* Controls */}
      <div className="budgets-page__controls">
        <div className="budgets-page__search">
          <Input
            type="search"
            placeholder="🔍 Search budgets..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="budgets-page__filters">
          {PERIOD_OPTIONS.map((period) => (
            <button
              key={period}
              type="button"
              className={`budgets-page__filter-button ${
                (period === 'all' && !filters.period) ||
                filters.period === period
                  ? 'budgets-page__filter-button--active'
                  : ''
              }`}
              onClick={() =>
                setFilters({
                  ...filters,
                  period: period === 'all' ? undefined : period,
                })
              }
            >
              {period !== 'all' && (
                <span className="budgets-page__filter-icon">
                  {getBudgetPeriodIcon(period)}
                </span>
              )}
              {period === 'all' ? 'All' : getBudgetPeriodName(period)}
            </button>
          ))}
        </div>

        <div className="budgets-page__status-filters">
          <button
            type="button"
            className={`budgets-page__status-button ${
              filters.is_active === undefined
                ? 'budgets-page__status-button--active'
                : ''
            }`}
            onClick={() =>
              setFilters({ ...filters, is_active: undefined })
            }
          >
            All Status
          </button>
          <button
            type="button"
            className={`budgets-page__status-button ${
              filters.is_active === true
                ? 'budgets-page__status-button--active'
                : ''
            }`}
            onClick={() => setFilters({ ...filters, is_active: true })}
          >
            Active
          </button>
          <button
            type="button"
            className={`budgets-page__status-button ${
              filters.is_active === false
                ? 'budgets-page__status-button--active'
                : ''
            }`}
            onClick={() => setFilters({ ...filters, is_active: false })}
          >
            Inactive
          </button>
        </div>
      </div>

      {/* Budgets List */}
      {filteredBudgets.length === 0 ? (
        <div className="budgets-page__empty">
          <EmptyState
            icon="💰"
            title={
              searchQuery || filters.period
                ? 'No budgets found'
                : 'No budgets yet'
            }
            description={
              searchQuery || filters.period
                ? 'Try adjusting your filters or search query'
                : 'Create your first budget to start tracking spending'
            }
            action={
              !searchQuery && !filters.period ? (
                <Button onClick={() => setIsFormOpen(true)}>
                  Create Your First Budget
                </Button>
              ) : undefined
            }
          />
        </div>
      ) : (
        <div className="budgets-page__grid">
          {filteredBudgets.map((budget) => {
            const status = calculateBudgetProgress(
              budget.spent,
              budget.amount,
              budget.alert_threshold
            );
            const percentage = (budget.spent / budget.amount) * 100;

            return (
              <div key={budget.id} className="budget-card">
                <div className="budget-card__header">
                  <div className="budget-card__title-section">
                    <h3 className="budget-card__name">{budget.name}</h3>
                    <span className="budget-card__category">
                      {budget.category}
                    </span>
                  </div>
                  <div className="budget-card__period">
                    <span className="budget-card__period-icon">
                      {getBudgetPeriodIcon(budget.period)}
                    </span>
                    <span className="budget-card__period-name">
                      {getBudgetPeriodName(budget.period)}
                    </span>
                  </div>
                </div>

                <div className="budget-card__progress">
                  <div className="budget-card__progress-bar">
                    <div
                      className={`budget-card__progress-fill budget-card__progress-fill--${status}`}
                      style={{ width: `${Math.min(percentage, 100)}%` }}
                    />
                  </div>
                  <div className="budget-card__progress-text">
                    <span>{formatBudgetPercentage(budget.spent, budget.amount)}</span>
                    <span className="budget-card__progress-label">
                      {formatCurrency(budget.spent)} of {formatCurrency(budget.amount)}
                    </span>
                  </div>
                </div>

                <div className="budget-card__footer">
                  <div className="budget-card__remaining">
                    <span className="budget-card__remaining-label">
                      Remaining:
                    </span>
                    <span
                      className={`budget-card__remaining-amount budget-card__remaining-amount--${status}`}
                    >
                      {formatCurrency(budget.amount - budget.spent)}
                    </span>
                  </div>
                  {!budget.is_active && (
                    <span className="budget-card__inactive-badge">
                      Inactive
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* TODO: Add Budget Form Modal */}
      {isFormOpen && (
        <div>Budget form placeholder - to be implemented</div>
      )}
    </div>
  );
}
