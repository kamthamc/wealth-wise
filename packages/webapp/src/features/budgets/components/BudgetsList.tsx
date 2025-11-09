/**
 * Budgets List Component
 * Main budgets management page
 */

import {
  BarChart3,
  Calendar,
  CalendarDays,
  CalendarRange,
  PiggyBank,
  Plus,
  Search,
  TrendingDown,
  Wallet,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useBudgetStore } from '@/core/stores';
import {
  Button,
  EmptyState,
  Input,
  SegmentedControl,
  type SegmentedControlOption,
  SkeletonList,
  SkeletonStats,
  SkeletonText,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { BudgetPeriodType } from '../types';
import {
  calculateBudgetProgress,
  formatBudgetPercentage,
  getBudgetPeriodIcon,
  getBudgetPeriodName,
} from '../utils/budgetHelpers';
import { AddBudgetForm } from './AddBudgetForm';
import './BudgetsList.css';

export function BudgetsList() {
  const { t } = useTranslation();
  const { budgets, isLoading } = useBudgetStore();

  // Period filter options with icons
  const PERIOD_OPTIONS: SegmentedControlOption<BudgetPeriodType | 'all'>[] = useMemo(() => [
    { value: 'all', label: t('pages.budgets.filters.period.all', 'All Periods'), icon: <Calendar size={16} /> },
    { value: 'monthly', label: t('pages.budgets.filters.period.monthly', 'Monthly'), icon: <CalendarDays size={16} /> },
    { value: 'quarterly', label: t('pages.budgets.filters.period.quarterly', 'Quarterly'), icon: <CalendarRange size={16} /> },
  ], [t]);

  const [periodFilter, setPeriodFilter] = useState<BudgetPeriodType | 'all'>(
    'all'
  );
  const [searchQuery, setSearchQuery] = useState('');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingBudgetId, setEditingBudgetId] = useState<string | undefined>(
    undefined
  );

  // Filter and search budgets
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

    // Search by name or category
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (budget) => budget.name.toLowerCase().includes(query) // ||
        // budget.category.toLowerCase().includes(query)
      );
    }

    return filtered;
  }, [budgets, periodFilter, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const activeBudgets = budgets.filter((b) => b.is_active);
    const totalBudget = activeBudgets.reduce(
      (sum, b) => sum + Number(b.total_allocated),
      0
    );
    const totalSpent = activeBudgets.reduce(
      (sum, b) => sum + Number(b.total_spent),
      0
    );
    const overBudget = activeBudgets.filter(
      (b) => Number(b.total_spent) >= Number(b.total_allocated)
    ).length;

    return {
      totalBudget,
      totalSpent,
      remainingBudget: totalBudget - totalSpent,
      budgetCount: activeBudgets.length,
      overBudgetCount: overBudget,
    };
  }, [budgets]);

  // Handlers
  const handleAddBudget = () => {
    setEditingBudgetId(undefined);
    setIsFormOpen(true);
  };

  const handleEditBudget = (budgetId: string) => {
    setEditingBudgetId(budgetId);
    setIsFormOpen(true);
  };

  const handleCloseForm = () => {
    setIsFormOpen(false);
    setEditingBudgetId(undefined);
  };

  if (isLoading) {
    return (
      <div className="budgets-page">
        {/* Header */}
        <div className="budgets-page__header">
          <SkeletonText width="180px" />
        </div>

        {/* Stats Skeleton */}
        <SkeletonStats count={3} />

        {/* List Skeleton */}
        <SkeletonList items={6} />
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div className="page-header-content">
          <h1 className="page-title">{t('pages.budgets.title', 'Budgets')}</h1>
          <p className="page-subtitle">{t('pages.budgets.subtitle', 'Track and manage your spending limits')}</p>
        </div>
        <div className="page-actions">
          <Button onClick={handleAddBudget}>{t('pages.budgets.addButton', '+ Add Budget')}</Button>
        </div>
      </div>
      <div className="page-content">
        {/* Stats */}
        <div className="stats-grid">
          <StatCard
            label={t('pages.budgets.stats.totalBudget', 'Total Budget')}
            value={formatCurrency(stats.totalBudget)}
            icon={<Wallet size={24} />}
          />
          <StatCard
            label={t('pages.budgets.stats.totalSpent', 'Total Spent')}
            value={formatCurrency(stats.totalSpent)}
            icon={<TrendingDown size={24} />}
            variant="danger"
          />
          <StatCard
            label={t('pages.budgets.stats.remaining', 'Remaining')}
            value={formatCurrency(stats.remainingBudget)}
            icon={<BarChart3 size={24} />}
            variant={stats.remainingBudget >= 0 ? 'success' : 'danger'}
          />
          <StatCard
            label={t('pages.budgets.stats.overBudget', 'Over Budget')}
            value={stats.overBudgetCount.toString()}
            icon={<PiggyBank size={24} />}
            variant={stats.overBudgetCount > 0 ? 'danger' : 'success'}
          />
        </div>

        {/* Controls */}
        <div className="filter-bar">
          <div className="filter-bar__search">
            <div className="filter-bar__search-icon">
              <Search size={20} />
            </div>
            <Input
              type="search"
              placeholder={t('pages.budgets.searchPlaceholder', 'Search budgets...')}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="filter-bar__controls">
            <SegmentedControl
              options={PERIOD_OPTIONS}
              value={periodFilter}
              onChange={setPeriodFilter}
              size="medium"
              aria-label="Filter budgets by period"
            />
          </div>
        </div>

        {/* Budgets List */}
        {filteredBudgets.length === 0 ? (
          <div className="budgets-page__empty">
            <EmptyState
              icon={<PiggyBank size={48} />}
              title={
                searchQuery || periodFilter !== 'all'
                  ? t('emptyState.budgets.filtered.title', 'No budgets found')
                  : t('emptyState.budgets.title', 'No budgets yet')
              }
              description={
                searchQuery || periodFilter !== 'all'
                  ? t('emptyState.budgets.filtered.description', 'Try adjusting your filters or search query')
                  : t('emptyState.budgets.description', 'Create your first budget to start tracking spending')
              }
              action={
                !searchQuery && periodFilter === 'all' ? (
                  <Button onClick={handleAddBudget}>
                    <Plus size={20} />
                    {t('emptyState.budgets.actionButton', 'Create Budget')}
                  </Button>
                ) : undefined
              }
            />
          </div>
        ) : (
          <div className="budgets-page__grid">
            {filteredBudgets.map((budget) => {
              const status = calculateBudgetProgress(
                budget.total_spent || 0,
                budget.total_allocated || 0
                // budget.alert_threshold
              );
              const percentage =
                ((budget.total_spent || 0) / (budget.total_allocated || 1)) * 100;

              return (
                <div key={budget.id} className="budget-card">
                  <div className="budget-card__header">
                    <div className="budget-card__title-section">
                      <h3 className="budget-card__name">{budget.name}</h3>
                      {/* <span className="budget-card__category">
                        {budget.category}
                      </span> */}
                    </div>
                    <div className="budget-card__actions">
                      <button
                        className="budget-card__edit-button"
                        onClick={() => handleEditBudget(budget.id)}
                        aria-label={t('common.edit', 'Edit') + ' ' + budget.name}
                      >
                        ✏️
                      </button>
                      <div className="budget-card__period">
                        <span className="budget-card__period-icon">
                          {getBudgetPeriodIcon(budget.period_type)}
                        </span>
                        <span className="budget-card__period-name">
                          {getBudgetPeriodName(budget.period_type)}
                        </span>
                      </div>
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
                      <span>
                        {formatBudgetPercentage(
                          (Number(budget.total_spent) * 100) /
                            Number(budget.total_allocated || 1)
                        )}
                      </span>
                      <span className="budget-card__progress-label">
                        {formatCurrency(budget.total_spent || 0)} of{' '}
                        {formatCurrency(budget.total_allocated || 0)}
                      </span>
                    </div>
                  </div>

                  <div className="budget-card__footer">
                    <div className="budget-card__remaining">
                      <span className="budget-card__remaining-label">
                        {t('pages.budgets.stats.remaining', 'Remaining')}:
                      </span>
                      <span
                        className={`budget-card__remaining-amount budget-card__remaining-amount--${status}`}
                      >
                        {formatCurrency(
                          Number(budget.total_allocated) -
                            Number(budget.total_spent)
                        )}
                      </span>
                    </div>
                    {!budget.is_active && (
                      <span className="budget-card__inactive-badge">
                        {t('common.inactive', 'Inactive')}
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>{' '}
      {/* Close page-content */}
      {/* Budget Form Modal */}
      <AddBudgetForm
        isOpen={isFormOpen}
        onClose={handleCloseForm}
        budgetId={editingBudgetId}
      />
    </div>
  );
}
