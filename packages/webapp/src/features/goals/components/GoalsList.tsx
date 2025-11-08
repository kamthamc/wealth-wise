/**
 * Goals List Component
 * Main goals management page
 */

import {
  CheckCircle2,
  DollarSign,
  Flag,
  Plus,
  Search,
  Target,
  TrendingUp,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useGoalStore } from '@/core/stores';
import { timestampToDate } from '@/core/utils/firebase';
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
import type { GoalStatus } from '../types';
import {
  calculateGoalProgress,
  formatDaysRemaining,
  formatGoalPercentage,
  getGoalPriorityIcon,
  getGoalStatusIcon,
  getGoalStatusName,
} from '../utils/goalHelpers';
import { AddGoalForm } from './AddGoalForm';
import './GoalsList.css';

export function GoalsList() {
  const { t } = useTranslation();
  const { goals, isLoading, fetchGoals } = useGoalStore();

  // Fetch goals on mount
  useEffect(() => {
    fetchGoals();
  }, [fetchGoals]);

  // Status filter options with icons
  const STATUS_OPTIONS: SegmentedControlOption<GoalStatus | 'all'>[] = useMemo(
    () => [
      { value: 'all', label: t('pages.goals.filters.all', 'All'), icon: <Flag size={16} /> },
      { value: 'active', label: t('pages.goals.filters.active', 'Active'), icon: <Target size={16} /> },
      { value: 'completed', label: t('pages.goals.filters.completed', 'Completed'), icon: <CheckCircle2 size={16} /> },
    ],
    [t]
  );

  const [statusFilter, setStatusFilter] = useState<GoalStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter and search goals
  const filteredGoals = useMemo(() => {
    let filtered = goals;

    // Filter by status
    if (statusFilter !== 'all') {
      filtered = filtered.filter((goal) => goal.status === statusFilter);
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
  }, [goals, statusFilter, searchQuery]);

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
            {/* Page Header */}
      <div className="goals-page__header">
        <div className="goals-page__header-content">
          <h1 className="goals-page__title">{t('pages.goals.title', 'Goals')}</h1>
        </div>
        <Button variant="primary" onClick={() => setIsFormOpen(true)}>
          <Plus size={18} />
          {t('pages.goals.addButton', 'Add Goal')}
        </Button>
      </div>

      {/* Stats */}
      <div className="goals-page__stats">
        <StatCard
          label={t('pages.goals.stats.activeGoals', 'Active Goals')}
          value={stats.activeGoals.toString()}
          icon={<Target size={24} />}
        />
        <StatCard
          label={t('pages.goals.stats.completed', 'Completed')}
          value={stats.completedGoals.toString()}
          icon={<CheckCircle2 size={24} />}
          variant="success"
        />
        <StatCard
          label={t('pages.goals.stats.totalTarget', 'Total Target')}
          value={formatCurrency(stats.totalTargetAmount)}
          icon={<DollarSign size={24} />}
        />
        <StatCard
          label={t('pages.goals.stats.overallProgress', 'Overall Progress')}
          value={`${Math.round(stats.overallProgress)}%`}
          icon={<TrendingUp size={24} />}
          variant={stats.overallProgress >= 80 ? 'success' : 'default'}
        />
      </div>

      {/* Controls */}
      <div className="goals-page__controls">
        <div className="goals-page__search">
          <div className="goals-page__search-icon">
            <Search size={20} />
          </div>
          <Input
            type="search"
            placeholder={t('pages.goals.searchPlaceholder', 'Search goals...')}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="goals-page__filters">
          <SegmentedControl
            options={STATUS_OPTIONS}
            value={statusFilter}
            onChange={setStatusFilter}
            size="medium"
            aria-label="Filter goals by status"
          />
        </div>
      </div>

      {/* Goals List */}
      {filteredGoals.length === 0 ? (
        <div className="goals-page__empty">
          <EmptyState
            icon={<Target size={48} />}
            title={
              searchQuery || statusFilter !== 'all'
                ? t('emptyState.goals.filtered.title', 'No goals found')
                : t('emptyState.goals.title', 'No goals yet')
            }
            description={
              searchQuery || statusFilter !== 'all'
                ? t('emptyState.goals.filtered.description', 'Try adjusting your filters or search query')
                : t('emptyState.goals.description', 'Set your first financial goal and start saving toward it')
            }
            action={
              !searchQuery && statusFilter === 'all' ? (
                <Button onClick={() => setIsFormOpen(true)}>
                  <Plus size={20} />
                  {t('emptyState.goals.action', 'Create Your First Goal')}
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
                      {formatDaysRemaining(timestampToDate(goal.target_date))}
                    </span>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Goal Form Modal */}
      <AddGoalForm isOpen={isFormOpen} onClose={() => setIsFormOpen(false)} />
    </div>
  );
}
