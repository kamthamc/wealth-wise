/**
 * Budget Progress Component
 * Display budget progress for different categories
 */

import { Link } from '@tanstack/react-router';
import { useEffect, useMemo, useState } from 'react';
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

interface BudgetWithProgress {
  id: string;
  name: string;
  period_type: 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event';
  categories?: any[];
  is_active: boolean;
  total_spent: number;
  total_allocated: number;
  percentage: number;
  status: 'on-track' | 'warning' | 'danger' | 'over';
}

export function BudgetProgress() {
  const { t } = useTranslation();
  const { budgets, isLoading, calculateProgress } = useBudgetStore();
  const { preferences, loading: prefsLoading } = usePreferences();
  const [budgetsWithProgress, setBudgetsWithProgress] = useState<BudgetWithProgress[]>([]);

  // Calculate progress for all active budgets
  useEffect(() => {
    const loadBudgetProgress = async () => {
      const activeBudgets = budgets.filter((b) => b.is_active);
      if (activeBudgets.length === 0) return;

      try {
        const progressPromises = activeBudgets.map(async (budget) => {
          try {
            const progressData = await calculateProgress(budget.id);
            const total_allocated = budget.categories?.reduce(
              (sum, cat: any) => sum + (cat.allocated_amount || 0), 
              0
            ) || 0;
            const total_spent = progressData.total_spent || 0;
            const percentage = total_allocated > 0 ? (total_spent / total_allocated) * 100 : 0;
            const status = calculateBudgetProgress(total_spent, total_allocated, {});

            return {
              id: budget.id,
              name: budget.name,
              period_type: budget.period_type,
              categories: budget.categories,
              is_active: budget.is_active,
              total_spent,
              total_allocated,
              percentage,
              status,
            };
          } catch (error) {
            console.error(`Error calculating progress for budget ${budget.id}:`, error);
            // Return budget with zero progress on error
            const total_allocated = budget.categories?.reduce(
              (sum, cat: any) => sum + (cat.allocated_amount || 0), 
              0
            ) || 0;
            return {
              id: budget.id,
              name: budget.name,
              period_type: budget.period_type,
              categories: budget.categories,
              is_active: budget.is_active,
              total_spent: 0,
              total_allocated,
              percentage: 0,
              status: 'on-track' as const,
            };
          }
        });

        const results = await Promise.all(progressPromises);
        setBudgetsWithProgress(results.sort((a, b) => b.percentage - a.percentage).slice(0, 5));
      } catch (error) {
        console.error('Error loading budget progress:', error);
      }
    };

    if (!isLoading && budgets.length > 0) {
      loadBudgetProgress();
    }
  }, [budgets, isLoading, calculateProgress]);

  // Get active budgets with progress
  const activeBudgets = useMemo(() => {
    return budgetsWithProgress;
  }, [budgetsWithProgress]);

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
