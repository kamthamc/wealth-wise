/**
 * Budget Detail View Component
 * Comprehensive view of budget with all categories, transactions, and alerts
 */

import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import {
  AlertCircle,
  ArrowLeft,
  Calendar,
  ChevronDown,
  ChevronUp,
  Edit,
  MoreVertical,
  Trash2,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import { Button, Card, EmptyState, StatCard } from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { BudgetAlert, BudgetProgress, BudgetWithProgress } from '../types';
import {
  formatBudgetPercentage,
  formatDateRange,
  getBudgetPeriodIcon,
  getBudgetPeriodName,
} from '../utils/budgetHelpers';
import './BudgetDetailView.css';

interface BudgetDetailViewProps {
  budget: BudgetWithProgress;
  onBack: () => void;
  onEdit?: (budgetId: string) => void;
  onDelete?: (budgetId: string) => void;
}

type CategorySort = 'name' | 'spent' | 'percent';
type SortDirection = 'asc' | 'desc';

export function BudgetDetailView({
  budget,
  onBack,
  onEdit,
  onDelete,
}: BudgetDetailViewProps) {
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(
    new Set()
  );
  const [categorySort, setCategorySort] = useState<CategorySort>('percent');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');

  // Sort categories
  const sortedCategories = useMemo(() => {
    const sorted = [...budget.progress];
    sorted.sort((a, b) => {
      let comparison = 0;
      switch (categorySort) {
        case 'name':
          comparison = a.category.localeCompare(b.category);
          break;
        case 'spent':
          comparison = a.spent - b.spent;
          break;
        case 'percent':
          comparison = a.percent_used - b.percent_used;
          break;
      }
      return sortDirection === 'asc' ? comparison : -comparison;
    });
    return sorted;
  }, [budget.progress, categorySort, sortDirection]);

  // Group alerts by severity
  const alertsBySeverity = useMemo(() => {
    const groups = {
      error: budget.alerts.filter((a) => a.severity === 'error'),
      warning: budget.alerts.filter((a) => a.severity === 'warning'),
      info: budget.alerts.filter((a) => a.severity === 'info'),
    };
    return groups;
  }, [budget.alerts]);

  const toggleCategory = (category: string) => {
    const newExpanded = new Set(expandedCategories);
    if (newExpanded.has(category)) {
      newExpanded.delete(category);
    } else {
      newExpanded.add(category);
    }
    setExpandedCategories(newExpanded);
  };

  const handleSort = (sort: CategorySort) => {
    if (categorySort === sort) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setCategorySort(sort);
      setSortDirection('desc');
    }
  };

  const handleEdit = () => {
    onEdit?.(budget.id);
  };

  const handleDelete = () => {
    if (window.confirm('Are you sure you want to delete this budget?')) {
      onDelete?.(budget.id);
    }
  };

  return (
    <div className="budget-detail">
      {/* Header */}
      <div className="budget-detail__header">
        <Button
          variant="ghost"
          onClick={onBack}
          className="budget-detail__back"
        >
          <ArrowLeft size={18} />
          Back to Budgets
        </Button>

        <div className="budget-detail__actions">
          <DropdownMenu.Root>
            <DropdownMenu.Trigger asChild>
              <Button variant="ghost">
                <MoreVertical size={18} />
              </Button>
            </DropdownMenu.Trigger>

            <DropdownMenu.Portal>
              <DropdownMenu.Content
                className="budget-detail__menu-dropdown"
                align="end"
              >
                <DropdownMenu.Item className="menu-item" onSelect={handleEdit}>
                  <Edit size={16} />
                  Edit Budget
                </DropdownMenu.Item>
                <DropdownMenu.Separator className="menu-separator" />
                <DropdownMenu.Item
                  className="menu-item menu-item--danger"
                  onSelect={handleDelete}
                >
                  <Trash2 size={16} />
                  Delete Budget
                </DropdownMenu.Item>
              </DropdownMenu.Content>
            </DropdownMenu.Portal>
          </DropdownMenu.Root>
        </div>
      </div>

      {/* Title Section */}
      <div className="budget-detail__title">
        <div className="budget-detail__title-content">
          <span className="budget-detail__icon">
            {getBudgetPeriodIcon(budget.period_type)}
          </span>
          <div>
            <h1 className="budget-detail__name">{budget.name}</h1>
            {budget.description && (
              <p className="budget-detail__description">{budget.description}</p>
            )}
            <p className="budget-detail__period">
              {getBudgetPeriodName(budget.period_type)} •{' '}
              {formatDateRange(budget.start_date, budget.end_date)}
            </p>
          </div>
        </div>
      </div>

      {/* Overview Stats */}
      <div className="budget-detail__stats">
        <StatCard
          label="Total Allocated"
          value={formatCurrency(budget.total_allocated)}
          icon={<Calendar size={24} />}
        />
        <StatCard
          label="Total Spent"
          value={formatCurrency(budget.total_spent)}
          icon={<TrendingDown size={24} />}
          description={formatBudgetPercentage(budget.overall_percent_used)}
        />
        <StatCard
          label="Remaining"
          value={formatCurrency(Math.abs(budget.total_remaining))}
          icon={<TrendingUp size={24} />}
          variant={budget.total_remaining < 0 ? 'danger' : 'success'}
          description={
            budget.total_remaining < 0 ? 'Over budget' : 'Under budget'
          }
        />
      </div>

      {/* Alerts Section */}
      {budget.alerts.length > 0 && (
        <div className="budget-detail__alerts">
          <h2 className="section-title">Alerts</h2>
          <div className="alerts-list">
            {alertsBySeverity.error.map((alert, idx) => (
              <AlertCard key={`error-${idx}`} alert={alert} />
            ))}
            {alertsBySeverity.warning.map((alert, idx) => (
              <AlertCard key={`warning-${idx}`} alert={alert} />
            ))}
            {alertsBySeverity.info.map((alert, idx) => (
              <AlertCard key={`info-${idx}`} alert={alert} />
            ))}
          </div>
        </div>
      )}

      {/* Categories Section */}
      <div className="budget-detail__categories">
        <div className="section-header">
          <h2 className="section-title">
            Categories ({budget.progress.length})
          </h2>
          <div className="category-sort">
            <button
              className={categorySort === 'percent' ? 'active' : ''}
              onClick={() => handleSort('percent')}
            >
              % Used
              {categorySort === 'percent' &&
                (sortDirection === 'asc' ? (
                  <ChevronUp size={14} />
                ) : (
                  <ChevronDown size={14} />
                ))}
            </button>
            <button
              className={categorySort === 'spent' ? 'active' : ''}
              onClick={() => handleSort('spent')}
            >
              Spent
              {categorySort === 'spent' &&
                (sortDirection === 'asc' ? (
                  <ChevronUp size={14} />
                ) : (
                  <ChevronDown size={14} />
                ))}
            </button>
            <button
              className={categorySort === 'name' ? 'active' : ''}
              onClick={() => handleSort('name')}
            >
              Name
              {categorySort === 'name' &&
                (sortDirection === 'asc' ? (
                  <ChevronUp size={14} />
                ) : (
                  <ChevronDown size={14} />
                ))}
            </button>
          </div>
        </div>

        <div className="categories-list">
          {sortedCategories.length === 0 ? (
            <EmptyState
              icon={<Calendar size={48} />}
              title="No categories"
              description="Add categories to start tracking spending"
            />
          ) : (
            sortedCategories.map((category) => (
              <CategoryCard
                key={category.category}
                category={category}
                isExpanded={expandedCategories.has(category.category)}
                onToggle={() => toggleCategory(category.category)}
              />
            ))
          )}
        </div>
      </div>

      {/* Budget Settings */}
      <div className="budget-detail__settings">
        <h2 className="section-title">Settings</h2>
        <Card className="settings-card">
          <div className="setting-item">
            <div className="setting-label">Recurring</div>
            <div className="setting-value">
              {budget.is_recurring ? 'Yes' : 'No'}
            </div>
          </div>
          {budget.rollover_enabled && (
            <div className="setting-item">
              <div className="setting-label">Rollover</div>
              <div className="setting-value">
                Enabled
                {budget.rollover_amount > 0 && (
                  <span className="rollover-amount">
                    {formatCurrency(budget.rollover_amount)} carried over
                  </span>
                )}
              </div>
            </div>
          )}
          <div className="setting-item">
            <div className="setting-label">Status</div>
            <div className="setting-value">
              <span
                className={`status-badge status-badge--${budget.is_active ? 'active' : 'inactive'}`}
              >
                {budget.is_active ? 'Active' : 'Inactive'}
              </span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

/**
 * Alert Card Component
 */
function AlertCard({ alert }: { alert: BudgetAlert }) {
  const severityColors = {
    error: 'danger',
    warning: 'warning',
    info: 'info',
  };

  return (
    <div className={`alert-card alert-card--${severityColors[alert.severity]}`}>
      <div className="alert-card__icon">
        <AlertCircle size={20} />
      </div>
      <div className="alert-card__content">
        <div className="alert-card__category">{alert.category}</div>
        <div className="alert-card__message">{alert.message}</div>
        {alert.percent_used !== undefined && (
          <div className="alert-card__percent">
            {formatBudgetPercentage(alert.percent_used)} used
          </div>
        )}
      </div>
    </div>
  );
}

/**
 * Category Card Component
 */
function CategoryCard({
  category,
  isExpanded,
  onToggle,
}: {
  category: BudgetProgress;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'over-budget':
        return 'danger';
      case 'warning':
        return 'warning';
      default:
        return 'success';
    }
  };

  return (
    <div className="category-card">
      <div className="category-card__header" onClick={onToggle}>
        <div className="category-card__info">
          <h3 className="category-card__name">{category.category}</h3>
          <div className="category-card__amounts">
            <span className="spent">{formatCurrency(category.spent)}</span>
            <span className="separator">/</span>
            <span className="allocated">
              {formatCurrency(category.allocated)}
            </span>
          </div>
        </div>
        <div className="category-card__status">
          <span
            className={`status-badge status-badge--${getStatusColor(category.status)}`}
          >
            {formatBudgetPercentage(category.percent_used)}
          </span>
          {isExpanded ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
        </div>
      </div>

      <div className="category-card__progress">
        <div className="progress-bar">
          <div
            className={`progress-bar__fill progress-bar__fill--${getStatusColor(category.status)}`}
            style={{ width: `${Math.min(category.percent_used, 100)}%` }}
          />
        </div>
      </div>

      {isExpanded && (
        <div className="category-card__details">
          <div className="detail-row">
            <span className="detail-label">Remaining:</span>
            <span
              className={`detail-value ${category.remaining < 0 ? 'text-danger' : 'text-success'}`}
            >
              {formatCurrency(Math.abs(category.remaining))}
              {category.remaining < 0 && ' over'}
            </span>
          </div>
          {category.variance !== 0 && (
            <div className="detail-row">
              <span className="detail-label">Variance:</span>
              <span
                className={`detail-value ${category.variance < 0 ? 'text-success' : 'text-danger'}`}
              >
                {category.variance > 0 ? '+' : ''}
                {formatCurrency(category.variance)}
              </span>
            </div>
          )}
          {category.is_over_budget && (
            <div className="detail-row">
              <span className="detail-label">Over by:</span>
              <span className="detail-value text-danger">
                {formatCurrency(Math.abs(category.remaining))}
              </span>
            </div>
          )}
          <div className="detail-row">
            <span className="detail-label">Status:</span>
            <span className="detail-value">
              {category.status === 'over-budget'
                ? 'Over Budget'
                : category.status === 'warning'
                  ? 'At Warning'
                  : 'On Track'}
            </span>
          </div>

          {/* TODO: Add transaction list for this category */}
          <div className="category-transactions">
            <div className="transactions-header">
              <span className="text-muted">Recent Transactions</span>
            </div>
            <EmptyState
              icon={<TrendingDown size={24} />}
              title="No transactions"
              description="Transactions will appear here"
            />
          </div>
        </div>
      )}
    </div>
  );
}
