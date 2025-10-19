/**
 * Goals Progress Component
 * Display active financial goals with progress tracking
 */

import { useMemo } from 'react';
import { Link } from '@tanstack/react-router';
import { useGoalStore } from '@/core/stores';
import { Card, ProgressBar, EmptyState } from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import {
  calculateGoalProgress,
  formatGoalPercentage,
  getGoalPriorityIcon,
} from '@/features/goals';
import './GoalsProgress.css';

export function GoalsProgress() {
  const { goals } = useGoalStore();

  // Get active goals sorted by priority and progress
  const activeGoals = useMemo(() => {
    const priorityOrder = { high: 3, medium: 2, low: 1 };
    
    return goals
      .filter((g) => g.status === 'active')
      .map((goal) => {
        const percentage = (goal.current_amount / goal.target_amount) * 100;
        const progressStatus = calculateGoalProgress(
          goal.current_amount,
          goal.target_amount
        );
        return {
          ...goal,
          percentage,
          progressStatus,
          priorityValue: priorityOrder[goal.priority || 'medium'],
        };
      })
      .sort((a, b) => {
        // Sort by priority first, then by progress percentage
        if (a.priorityValue !== b.priorityValue) {
          return b.priorityValue - a.priorityValue;
        }
        return b.percentage - a.percentage;
      })
      .slice(0, 5); // Top 5 goals
  }, [goals]);

  const getVariant = (
    status: ReturnType<typeof calculateGoalProgress>
  ): 'success' | 'warning' | 'default' => {
    if (status === 'completed') return 'success';
    if (status === 'near-completion') return 'warning';
    return 'default';
  };

  return (
    <section className="goals-progress">
      <Card>
        <div className="goals-progress__header">
          <h2 className="goals-progress__title">Goals Progress</h2>
          <Link to="/goals" className="goals-progress__link">
            View All →
          </Link>
        </div>

        {activeGoals.length > 0 ? (
          <div className="goals-progress__list">
            {activeGoals.map((goal) => {
              const variant = getVariant(goal.progressStatus);
              const remaining = goal.target_amount - goal.current_amount;

              return (
                <div key={goal.id} className="goal-item">
                  <div className="goal-item__header">
                    <div className="goal-item__info">
                      <div className="goal-item__title-row">
                        {goal.icon && (
                          <span className="goal-item__icon">{goal.icon}</span>
                        )}
                        {goal.priority && (
                          <span className="goal-item__priority">
                            {getGoalPriorityIcon(goal.priority)}
                          </span>
                        )}
                        <span className="goal-item__name">{goal.name}</span>
                      </div>
                      <span className="goal-item__category">{goal.category}</span>
                    </div>
                    <div className="goal-item__amounts">
                      <span className="goal-item__current">
                        {formatCurrency(goal.current_amount)}
                      </span>
                      <span className="goal-item__target">
                        of {formatCurrency(goal.target_amount)}
                      </span>
                    </div>
                  </div>
                  <ProgressBar
                    value={goal.current_amount}
                    max={goal.target_amount}
                    variant={variant}
                    size="medium"
                    showValue
                    label={formatGoalPercentage(
                      goal.current_amount,
                      goal.target_amount
                    )}
                  />
                  <div className="goal-item__footer">
                    <span className="goal-item__remaining">
                      {formatCurrency(remaining)} remaining
                    </span>
                    {goal.target_date && (
                      <span className="goal-item__deadline">
                        Due:{' '}
                        {new Date(goal.target_date).toLocaleDateString('en-IN', {
                          month: 'short',
                          year: 'numeric',
                        })}
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <EmptyState
            icon="🎯"
            title="No active goals"
            description="Set financial goals to track your progress"
          />
        )}
      </Card>
    </section>
  );
}
