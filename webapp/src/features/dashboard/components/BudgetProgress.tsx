/**
 * Budget Progress Component
 * Display budget progress for different categories
 */

import { Link } from '@tanstack/react-router';
import { useMemo } from 'react';
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
import { formatCurrency } from '@/shared/utils';
import './BudgetProgress.css';

export function BudgetProgress() {
  const { budgets, isLoading } = useBudgetStore();

  // Get active budgets sorted by progress percentage
  const activeBudgets = useMemo(() => {
    return budgets
      .filter((b) => b.is_active)
      .map((budget) => {
        const percentage = (budget.spent / budget.amount) * 100;
        const status = calculateBudgetProgress(
          budget.spent,
          budget.amount,
          budget.alert_threshold
        );
        return {
          ...budget,
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
          <h2 className="budget-progress__title">Budget Progress</h2>
          <Link to="/budgets" className="budget-progress__link">
            View All →
          </Link>
        </div>

        {isLoading ? (
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
                        {getBudgetPeriodIcon(budget.period)}
                      </span>
                      <span className="budget-item__name">{budget.name}</span>
                    </div>
                    <span className="budget-item__amount">
                      {formatCurrency(budget.spent)} /{' '}
                      {formatCurrency(budget.amount)}
                    </span>
                  </div>
                  <ProgressBar
                    value={budget.spent}
                    max={budget.amount}
                    variant={variant}
                    size="medium"
                    showValue
                  />
                  {budget.percentage >= 100 && (
                    <p className="budget-item__warning">⚠️ Budget exceeded!</p>
                  )}
                  {budget.percentage >= 80 && budget.percentage < 100 && (
                    <p className="budget-item__warning budget-item__warning--mild">
                      ⚡ Approaching limit
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        ) : (
          <EmptyState
            icon="💰"
            title="No budgets yet"
            description="Create budgets to track your spending"
          />
        )}
      </Card>
    </section>
  );
}
