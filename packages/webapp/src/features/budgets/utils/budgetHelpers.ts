/**
 * Budget Helper Functions
 * Utilities for budget calculations and formatting
 */

import type { BudgetStatus } from '@/core/types';
import type { BudgetFormData, BudgetPeriodType } from '../types';

/**
 * Get icon emoji for budget period
 */
export function getBudgetPeriodIcon(period: BudgetPeriodType): string {
  const icons: Record<BudgetPeriodType, string> = {
    monthly: '�️',
    quarterly: '📆',
    annual: '�',
    custom: '�',
    event: '🎉',
  };
  return icons[period] || '💰';
}

/**
 * Get display name for budget period
 */
export function getBudgetPeriodName(period: BudgetPeriodType): string {
  const names: Record<BudgetPeriodType, string> = {
    monthly: 'Monthly',
    quarterly: 'Quarterly',
    annual: 'Annual',
    custom: 'Custom Period',
    event: 'Event Budget',
  };
  return names[period] || 'Budget';
}

/**
 * Get color variant for budget status
 */
export function getStatusColor(status?: BudgetStatus | 'under' | 'near' | 'over'): string {
  if (!status) return 'success';
  
  const colors: Record<string, string> = {
    on_track: 'success',
    under: 'success',
    warning: 'warning',
    near: 'warning',
    over_budget: 'danger',
    over: 'danger',
  };

  return colors[status] || 'success';
}

export function getStatusIcon(status?: BudgetStatus): string {
  if (!status) return '✓';
  
  const icons: Record<string, string> = {
    on_track: '✓',
    warning: '⚠',
    over_budget: '✗',
  };

  return icons[status] || '✓';
}

/**
 * Format budget percentage
 */
export function formatBudgetPercentage(percentUsed: number): string {
  return `${Math.round(percentUsed)}%`;
}

/**
 * Calculate overall budget progress from category progress
 */
export function calculateOverallProgress(
  categories: Array<{ allocated: number; spent: number }>
): {
  totalAllocated: number;
  totalSpent: number;
  totalRemaining: number;
  percentUsed: number;
} {
  const totalAllocated = categories.reduce(
    (sum, cat) => sum + cat.allocated,
    0
  );
  const totalSpent = categories.reduce((sum, cat) => sum + cat.spent, 0);
  const totalRemaining = totalAllocated - totalSpent;
  const percentUsed =
    totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

  return {
    totalAllocated,
    totalSpent,
    totalRemaining,
    percentUsed,
  };
}

export function calculateBudgetProgress(
  totalSpent: number,
  totalAllocated: number,
  alerts?: {
    warning_threshold?: number; // e.g., 0.8 for 80%
    danger_threshold?: number; // e.g., 0.95 for 95%
  }
): 'on-track' | 'warning' | 'danger' | 'over' {
  if (totalAllocated === 0) {
    return 'on-track';
  }

  const percentUsed = totalSpent / totalAllocated;

  if (percentUsed >= 1) {
    return 'over';
  }

  if (alerts?.danger_threshold && percentUsed >= alerts.danger_threshold) {
    return 'danger';
  }

  if (alerts?.warning_threshold && percentUsed >= alerts.warning_threshold) {
    return 'warning';
  }

  return 'on-track';
}

/**
 * Validate budget form data
 */
export function validateBudgetForm(
  data: BudgetFormData
): Record<string, string> {
  const errors: Record<string, string> = {};

  if (!data.name || data.name.trim().length === 0) {
    errors.name = 'Budget name is required';
  } else if (data.name.trim().length < 3) {
    errors.name = 'Budget name must be at least 3 characters';
  }

  if (!data.period_type) {
    errors.period_type = 'Budget period is required';
  }

  if (!data.start_date) {
    errors.start_date = 'Start date is required';
  }

  if (data.categories.length === 0) {
    errors.categories = 'At least one category is required';
  }

  // Validate each category
  data.categories.forEach((cat, index) => {
    if (!cat.category || cat.category.trim().length === 0) {
      errors[`category_${index}`] = 'Category name is required';
    }
    if (!cat.allocated_amount || cat.allocated_amount <= 0) {
      errors[`amount_${index}`] = 'Amount must be greater than 0';
    }
    if (cat.alert_threshold < 0 || cat.alert_threshold > 1) {
      errors[`threshold_${index}`] = 'Alert threshold must be between 0 and 1';
    }
  });

  // Validate date range for custom periods
  if (data.period_type === 'custom' && !data.end_date) {
    errors.end_date = 'End date is required for custom periods';
  }

  if (data.start_date && data.end_date) {
    const start = new Date(data.start_date);
    const end = new Date(data.end_date);
    if (end <= start) {
      errors.end_date = 'End date must be after start date';
    }
  }

  return errors;
}

/**
 * Calculate end date based on period type
 */
export function calculateEndDate(
  startDate: Date,
  period: BudgetPeriodType
): Date {
  const end = new Date(startDate);

  switch (period) {
    case 'monthly':
      end.setMonth(end.getMonth() + 1);
      break;
    case 'quarterly':
      end.setMonth(end.getMonth() + 3);
      break;
    case 'annual':
      end.setFullYear(end.getFullYear() + 1);
      break;
    default:
      // For custom and event, return 30 days as default
      end.setDate(end.getDate() + 30);
  }

  return end;
}

/**
 * Format date range display
 */
export function formatDateRange(startDate: Date, endDate?: Date): string {
  const formatter = new Intl.DateTimeFormat('en-IN', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  if (!endDate) {
    return `From ${formatter.format(startDate)}`;
  }

  return `${formatter.format(startDate)} - ${formatter.format(endDate)}`;
}
