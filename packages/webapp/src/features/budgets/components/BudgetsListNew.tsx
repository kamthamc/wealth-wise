/**
 * Enhanced Budgets List Component
 * Multi-category budget management
 */

import {
  AlertCircle,
  Calendar,
  Plus,
  TrendingDown,
  TrendingUp,
  Wallet,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import {
  Button,
  EmptyState,
  Input,
  SegmentedControl,
  type SegmentedControlOption,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { BudgetPeriodType, BudgetWithProgress } from '../types';
import {
  formatBudgetPercentage,
  formatDateRange,
  getBudgetPeriodIcon,
  getBudgetPeriodName,
} from '../utils/budgetHelpers';
import './BudgetsList.css';

// Period filter options
const PERIOD_OPTIONS: SegmentedControlOption<BudgetPeriodType | 'all'>[] = [
  { value: 'all', label: 'All' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'annual', label: 'Annual' },
  { value: 'event', label: 'Event' },
];

export function BudgetsList() {
  // TODO: Replace with actual store
  const budgets: BudgetWithProgress[] = [];
  const isLoading = false;

  const [periodFilter, setPeriodFilter] = useState<BudgetPeriodType | 'all'>(
    'all'
  );
  const [searchQuery, setSearchQuery] = useState('');
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter budgets
  const filteredBudgets = useMemo(() => {
    let filtered = budgets;

    // Filter by period
    if (periodFilter !== 'all') {
      filtered = filtered.filter(
        (budget) => budget.period_type === periodFilter
      );
    }

    // Only show active budgets by default
    filtered = filtered.filter((budget) => budget.is_active);

    // Search by name
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter((budget) =>
        budget.name.toLowerCase().includes(query)
      );
    }

    return filtered;
  }, [budgets, periodFilter, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const activeBudgets = budgets.filter((b) => b.is_active);
    const totalAllocated = activeBudgets.reduce(
      (sum, b) => sum + b.total_allocated,
      0
    );
    const totalSpent = activeBudgets.reduce((sum, b) => sum + b.total_spent, 0);
    const totalRemaining = totalAllocated - totalSpent;
    const budgetsOverLimit = activeBudgets.filter(
      (b) => b.total_spent > b.total_allocated
    ).length;
    const budgetsAtWarning = activeBudgets.filter((b) =>
      b.alerts.some((a) => a.severity === 'warning')
    ).length;

    return {
      totalAllocated,
      totalSpent,
      totalRemaining,
      activeBudgets: activeBudgets.length,
      budgetsOverLimit,
      budgetsAtWarning,
    };
  }, [budgets]);

  if (isLoading) {
    return <div className="budgets-page">Loading...</div>;
  }

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div className="page-header-content">
          <h1 className="page-title">Budgets</h1>
          <p className="page-subtitle">
            Track spending across multiple categories
          </p>
        </div>
        <div className="page-actions">
          <Button onClick={() => setIsFormOpen(true)}>
            <Plus size={18} />
            Add Budget
          </Button>
        </div>
      </div>

      <div className="page-content">
        {/* Stats */}
        <div className="stats-grid">
          <StatCard
            label="Total Allocated"
            value={formatCurrency(stats.totalAllocated)}
            icon={<Wallet size={24} />}
          />
          <StatCard
            label="Total Spent"
            value={formatCurrency(stats.totalSpent)}
            icon={<TrendingDown size={24} />}
            description={`${stats.activeBudgets} active budgets`}
          />
          <StatCard
            label="Remaining"
            value={formatCurrency(stats.totalRemaining)}
            icon={<TrendingUp size={24} />}
            variant={stats.totalRemaining < 0 ? 'danger' : 'success'}
          />
          {(stats.budgetsOverLimit > 0 || stats.budgetsAtWarning > 0) && (
            <StatCard
              label="Alerts"
              value={`${stats.budgetsOverLimit + stats.budgetsAtWarning}`}
              icon={<AlertCircle size={24} />}
              variant="warning"
              description={`${stats.budgetsOverLimit} over, ${stats.budgetsAtWarning} warning`}
            />
          )}
        </div>

        {/* Filters */}
        <div className="budgets-filters">
          <div className="budgets-filters__search">
            <Input
              placeholder="Search budgets..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <div className="budgets-filters__period">
            <SegmentedControl
              options={PERIOD_OPTIONS}
              value={periodFilter}
              onChange={setPeriodFilter}
            />
          </div>
        </div>

        {/* Budgets List */}
        {filteredBudgets.length === 0 ? (
          <EmptyState
            icon={<Calendar size={48} />}
            title="No budgets found"
            description={
              searchQuery || periodFilter !== 'all'
                ? 'Try adjusting your filters'
                : 'Create your first budget to start tracking spending'
            }
            action={
              !searchQuery && periodFilter === 'all' ? (
                <Button onClick={() => setIsFormOpen(true)}>
                  <Plus size={18} />
                  Create Budget
                </Button>
              ) : undefined
            }
          />
        ) : (
          <div className="budgets-list">
            {filteredBudgets.map((budget) => (
              <BudgetCard key={budget.id} budget={budget} />
            ))}
          </div>
        )}
      </div>

      {/* Add Budget Modal */}
      {isFormOpen && (
        <div className="modal-overlay" onClick={() => setIsFormOpen(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            {/* TODO: Add budget form */}
            <p>Budget form coming soon...</p>
            <Button onClick={() => setIsFormOpen(false)}>Close</Button>
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * Budget Card Component
 */
function BudgetCard({ budget }: { budget: BudgetWithProgress }) {
  const overallPercentUsed = budget.overall_percent_used;
  const hasAlerts = budget.alerts.length > 0;

  return (
    <div className="budget-card">
      {/* Header */}
      <div className="budget-card__header">
        <div className="budget-card__title">
          <span className="budget-card__icon">
            {getBudgetPeriodIcon(budget.period_type)}
          </span>
          <div>
            <h3 className="budget-card__name">{budget.name}</h3>
            <p className="budget-card__period">
              {getBudgetPeriodName(budget.period_type)} •{' '}
              {formatDateRange(budget.start_date, budget.end_date)}
            </p>
          </div>
        </div>
        {hasAlerts && (
          <div className="budget-card__alerts">
            <AlertCircle size={20} className="text-warning" />
            <span>{budget.alerts.length}</span>
          </div>
        )}
      </div>

      {/* Progress Bar */}
      <div className="budget-card__progress">
        <div className="progress-bar">
          <div
            className={`progress-bar__fill progress-bar__fill--${
              overallPercentUsed > 100
                ? 'danger'
                : overallPercentUsed > 80
                  ? 'warning'
                  : 'success'
            }`}
            style={{ width: `${Math.min(overallPercentUsed, 100)}%` }}
          />
        </div>
        <div className="budget-card__progress-text">
          <span className="text-muted">
            {formatCurrency(budget.total_spent)} /{' '}
            {formatCurrency(budget.total_allocated)}
          </span>
          <span className="text-bold">
            {formatBudgetPercentage(overallPercentUsed)}
          </span>
        </div>
      </div>

      {/* Categories */}
      <div className="budget-card__categories">
        {budget.progress.slice(0, 3).map((cat) => (
          <div key={cat.category} className="budget-category-chip">
            <span className="budget-category-chip__name">{cat.category}</span>
            <span
              className={`budget-category-chip__status budget-category-chip__status--${cat.status}`}
            >
              {formatBudgetPercentage(cat.percent_used)}
            </span>
          </div>
        ))}
        {budget.progress.length > 3 && (
          <div className="budget-category-chip budget-category-chip--more">
            +{budget.progress.length - 3} more
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="budget-card__footer">
        <div className="budget-card__remaining">
          <span className="text-muted">Remaining:</span>
          <span
            className={`text-bold ${
              budget.total_remaining < 0 ? 'text-danger' : 'text-success'
            }`}
          >
            {formatCurrency(Math.abs(budget.total_remaining))}
            {budget.total_remaining < 0 && ' over'}
          </span>
        </div>
        <Button variant="ghost">View Details</Button>
      </div>
    </div>
  );
}
