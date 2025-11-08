/**
 * Budget Progress Component
 * Display budget progress for different categories
 */

import { Link } from '@tanstack/react-router';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useBudgetStore } from '@/core/stores';
import {
  calculateBudgetProgress,
  getBudgetPeriodIcon,
} from '@/features/budgets';
import {
  Card,
  EmptyState,
  ProgressBar,
  SkeletonList,
} from '@/shared/components';
import { formatCurrency } from '@/utils';
import { usePreferences } from '@/hooks/usePreferences';
import './BudgetProgress.css';

export function BudgetProgress() {
  const { t } = useTranslation();
  const { budgets, isLoading } = useBudgetStore();
  const { preferences, loading: prefsLoading } = usePreferences();

  // Get active budgets sorted by progress percentage
  const activeBudgets = useMemo(() => {
    return budgets
      .filter((b) => b.is_active)
      .map((budget) => {
        // TODO: Calculate these from transactions or get from store
        const total_spent = 0;
        const total_allocated = budget.categories?.reduce((sum, cat: any) => sum + (cat.allocated_amount || 0), 0) || 0;
        const percentage = total_allocated > 0 ? (total_spent / total_allocated) * 100 : 0;
        const status = calculateBudgetProgress(
          total_spent,
          total_allocated,
          {}
        );
        return {
          ...budget,
          total_spent,
          total_allocated,
          percentage,
          status,
        };
      })
      .sort((a, b) => b.percentage - a.percentage)
      .slice(0, 5); // Top 5 budgets
  }, [budgets]);

  const getVariant = (
    status: ReturnType<typeof calculateBudgetProgress>
  ): 'success' | 'warning' | 'danger' => {
    if (status === 'over') return 'danger';
    if (status === 'danger') return 'danger';
    if (status === 'warning') return 'warning';
    return 'success';
  };

  return (
    <section className="budget-progress">
      <Card>
        <div className="budget-progress__header">
          <h2 className="budget-progress__title">{t('pages.dashboard.budgetProgress.title', 'Budget Progress')}</h2>
          <Link to="/budgets" className="budget-progress__link">
            {t('pages.dashboard.budgetProgress.viewAll', 'View All')} →
          </Link>
        </div>

        {isLoading || prefsLoading ? (
          <SkeletonList items={5} />
        ) : activeBudgets.length > 0 ? (
          <div className="budget-progress__list">
            {activeBudgets.map((budget) => {
              const variant = getVariant(budget.status);

              return (
                <div key={budget.id} className="budget-item">
                  <div className="budget-item__header">
                    <div className="budget-item__category">
                      <span className="budget-item__icon">
                        {getBudgetPeriodIcon(budget.period_type)}
                      </span>
                      <span className="budget-item__name">{budget.name}</span>
                    </div>
                    <span className="budget-item__amount">
                      {formatCurrency(
                        budget.total_spent,
                        preferences?.currency || 'INR',
                        preferences?.locale || 'en-IN'
                      )} /{' '}
                      {formatCurrency(
                        budget.total_allocated,
                        preferences?.currency || 'INR',
                        preferences?.locale || 'en-IN'
                      )}
                    </span>
                  </div>
                  <ProgressBar
                    value={budget.total_spent}
                    max={budget.total_allocated}
                    variant={variant}
                    size="medium"
                    showValue
                  />
                  {budget.percentage >= 100 && (
                    <p className="budget-item__warning">⚠️ {t('pages.dashboard.budgetProgress.exceeded', 'Budget exceeded!')}</p>
                  )}
                  {budget.percentage >= 80 && budget.percentage < 100 && (
                    <p className="budget-item__warning budget-item__warning--mild">
                      ⚡ {t('pages.dashboard.budgetProgress.approachingLimit', 'Approaching limit')}
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        ) : (
          <EmptyState
            icon="💰"
            title={t('emptyState.budgets.title', 'No budgets yet')}
            description={t('emptyState.budgets.description', 'Create your first budget to start tracking spending')}
          />
        )}
      </Card>
    </section>
  );
}
