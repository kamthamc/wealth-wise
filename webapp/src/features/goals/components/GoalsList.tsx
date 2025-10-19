/**
 * Goals List Component
 * Main goals management page
 */

import { useMemo, useState } from 'react';
import { useGoalStore } from '@/core/stores';
import {
  Button,
  EmptyState,
  Input,
  SkeletonList,
  SkeletonStats,
  SkeletonText,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { GoalFilters, GoalStatus } from '../types';
import {
  calculateGoalProgress,
  formatDaysRemaining,
  formatGoalPercentage,
  getGoalPriorityIcon,
  getGoalStatusIcon,
  getGoalStatusName,
} from '../utils/goalHelpers';
import './GoalsList.css';

const STATUS_OPTIONS: (GoalStatus | 'all')[] = [
  'all',
  'active',
  'completed',
  'paused',
  'cancelled',
];

export function GoalsList() {
  const { goals, isLoading } = useGoalStore();

  const [filters, setFilters] = useState<GoalFilters>({});
  const [searchQuery, setSearchQuery] = useState('');
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter and search goals
  const filteredGoals = useMemo(() => {
    let filtered = goals;

    // Filter by status
    if (filters.status) {
      filtered = filtered.filter((goal) => goal.status === filters.status);
    }

    // Filter by priority
    if (filters.priority) {
      filtered = filtered.filter((goal) => goal.priority === filters.priority);
    }

    // Search by name or category
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (goal) =>
          goal.name.toLowerCase().includes(query) ||
          goal.category.toLowerCase().includes(query)
      );
    }

    return filtered;
  }, [goals, filters, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const activeGoals = goals.filter((g) => g.status === 'active');
    const completedGoals = goals.filter((g) => g.status === 'completed');
    const totalTarget = activeGoals.reduce(
      (sum, g) => sum + g.target_amount,
      0
    );
    const totalCurrent = activeGoals.reduce(
      (sum, g) => sum + g.current_amount,
      0
    );
    const overallProgress =
      totalTarget > 0 ? (totalCurrent / totalTarget) * 100 : 0;

    return {
      totalGoals: goals.length,
      completedGoals: completedGoals.length,
      activeGoals: activeGoals.length,
      totalTargetAmount: totalTarget,
      totalCurrentAmount: totalCurrent,
      overallProgress,
    };
  }, [goals]);

  if (isLoading) {
    return (
      <div className="goals-page">
        {/* Header */}
        <div className="goals-page__header">
          <SkeletonText width="150px" />
        </div>

        {/* Stats Skeleton */}
        <SkeletonStats count={4} />

        {/* List Skeleton */}
        <SkeletonList items={6} />
      </div>
    );
  }

  return (
    <div className="goals-page">
      {/* Header */}
      <div className="goals-page__header">
        <h1 className="goals-page__title">Goals</h1>
        <Button onClick={() => setIsFormOpen(true)}>+ Add Goal</Button>
      </div>

      {/* Stats */}
      <div className="goals-page__stats">
        <StatCard
          label="Active Goals"
          value={stats.activeGoals.toString()}
          icon="🎯"
        />
        <StatCard
          label="Completed"
          value={stats.completedGoals.toString()}
          icon="✅"
          variant="success"
        />
        <StatCard
          label="Total Target"
          value={formatCurrency(stats.totalTargetAmount)}
          icon="💰"
        />
        <StatCard
          label="Overall Progress"
          value={`${Math.round(stats.overallProgress)}%`}
          icon="📊"
          variant={stats.overallProgress >= 80 ? 'success' : 'default'}
        />
      </div>

      {/* Controls */}
      <div className="goals-page__controls">
        <div className="goals-page__search">
          <Input
            type="search"
            placeholder="🔍 Search goals..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="goals-page__filters">
          {STATUS_OPTIONS.map((status) => (
            <button
              key={status}
              type="button"
              className={`goals-page__filter-button ${
                (status === 'all' && !filters.status) ||
                filters.status === status
                  ? 'goals-page__filter-button--active'
                  : ''
              }`}
              onClick={() =>
                setFilters({
                  ...filters,
                  status: status === 'all' ? undefined : status,
                })
              }
            >
              {status !== 'all' && (
                <span className="goals-page__filter-icon">
                  {getGoalStatusIcon(status)}
                </span>
              )}
              {status === 'all' ? 'All' : getGoalStatusName(status)}
            </button>
          ))}
        </div>
      </div>

      {/* Goals List */}
      {filteredGoals.length === 0 ? (
        <div className="goals-page__empty">
          <EmptyState
            icon="🎯"
            title={
              searchQuery || filters.status ? 'No goals found' : 'No goals yet'
            }
            description={
              searchQuery || filters.status
                ? 'Try adjusting your filters or search query'
                : 'Set your first financial goal and start saving'
            }
            action={
              !searchQuery && !filters.status ? (
                <Button onClick={() => setIsFormOpen(true)}>
                  Create Your First Goal
                </Button>
              ) : undefined
            }
          />
        </div>
      ) : (
        <div className="goals-page__grid">
          {filteredGoals.map((goal) => {
            const progressStatus = calculateGoalProgress(
              goal.current_amount,
              goal.target_amount
            );
            const percentage = (goal.current_amount / goal.target_amount) * 100;

            return (
              <div key={goal.id} className="goal-card">
                <div className="goal-card__header">
                  <div className="goal-card__title-section">
                    <div className="goal-card__icon-wrapper">
                      {goal.icon && (
                        <span className="goal-card__icon">{goal.icon}</span>
                      )}
                      {goal.priority && (
                        <span className="goal-card__priority">
                          {getGoalPriorityIcon(goal.priority)}
                        </span>
                      )}
                    </div>
                    <div>
                      <h3 className="goal-card__name">{goal.name}</h3>
                      <span className="goal-card__category">
                        {goal.category}
                      </span>
                    </div>
                  </div>
                  <span
                    className={`goal-card__status goal-card__status--${goal.status}`}
                  >
                    {getGoalStatusIcon(goal.status)}{' '}
                    {getGoalStatusName(goal.status)}
                  </span>
                </div>

                <div className="goal-card__amounts">
                  <div className="goal-card__amount-item">
                    <span className="goal-card__amount-label">Current</span>
                    <span className="goal-card__amount-value">
                      {formatCurrency(goal.current_amount)}
                    </span>
                  </div>
                  <div className="goal-card__amount-item">
                    <span className="goal-card__amount-label">Target</span>
                    <span className="goal-card__amount-value">
                      {formatCurrency(goal.target_amount)}
                    </span>
                  </div>
                </div>

                <div className="goal-card__progress">
                  <div className="goal-card__progress-bar">
                    <div
                      className={`goal-card__progress-fill goal-card__progress-fill--${progressStatus}`}
                      style={{ width: `${Math.min(percentage, 100)}%` }}
                    />
                  </div>
                  <div className="goal-card__progress-text">
                    <span>
                      {formatGoalPercentage(
                        goal.current_amount,
                        goal.target_amount
                      )}
                    </span>
                    <span className="goal-card__progress-label">
                      {formatCurrency(goal.target_amount - goal.current_amount)}{' '}
                      remaining
                    </span>
                  </div>
                </div>

                {goal.target_date && goal.status === 'active' && (
                  <div className="goal-card__deadline">
                    <span className="goal-card__deadline-icon">📅</span>
                    <span className="goal-card__deadline-text">
                      {formatDaysRemaining(goal.target_date)}
                    </span>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* TODO: Add Goal Form Modal */}
      {isFormOpen && <div>Goal form placeholder - to be implemented</div>}
    </div>
  );
}
