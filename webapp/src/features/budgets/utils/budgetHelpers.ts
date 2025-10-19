/**
 * Budget Helper Utilities
 * Helper functions for budget management
 */

import type { BudgetPeriod, BudgetProgress } from '../types';

/**
 * Get icon emoji for budget period
 */
export function getBudgetPeriodIcon(period: BudgetPeriod): string {
  const icons: Record<BudgetPeriod, string> = {
    daily: '📅',
    weekly: '📆',
    monthly: '🗓️',
    yearly: '📊',
  };
  return icons[period] || '💰';
}

/**
 * Get display name for budget period
 */
export function getBudgetPeriodName(period: BudgetPeriod): string {
  const names: Record<BudgetPeriod, string> = {
    daily: 'Daily',
    weekly: 'Weekly',
    monthly: 'Monthly',
    yearly: 'Yearly',
  };
  return names[period] || 'Budget';
}

/**
 * Calculate budget progress
 */
export function calculateBudgetProgress(
  spent: number,
  amount: number,
  alertThreshold: number
): BudgetProgress['status'] {
  const percentage = (spent / amount) * 100;

  if (percentage >= 100) return 'over';
  if (percentage >= alertThreshold) return 'danger';
  if (percentage >= alertThreshold * 0.8) return 'warning';
  return 'safe';
}

/**
 * Get color variant for budget status
 */
export function getBudgetStatusColor(
  status: BudgetProgress['status']
): 'success' | 'warning' | 'danger' | 'default' {
  const colors: Record<
    BudgetProgress['status'],
    'success' | 'warning' | 'danger' | 'default'
  > = {
    safe: 'success',
    warning: 'warning',
    danger: 'danger',
    over: 'danger',
  };
  return colors[status];
}

/**
 * Format budget percentage
 */
export function formatBudgetPercentage(spent: number, amount: number): string {
  const percentage = (spent / amount) * 100;
  return `${Math.round(percentage)}%`;
}

/**
 * Validate budget form data
 */
export function validateBudgetForm(data: {
  name: string;
  category: string;
  amount: number;
  period: string;
  start_date: string;
  alert_threshold: number;
}): Record<string, string> {
  const errors: Record<string, string> = {};

  if (!data.name || data.name.trim().length === 0) {
    errors.name = 'Budget name is required';
  } else if (data.name.trim().length < 3) {
    errors.name = 'Budget name must be at least 3 characters';
  }

  if (!data.category || data.category.trim().length === 0) {
    errors.category = 'Category is required';
  }

  if (!data.amount || data.amount <= 0) {
    errors.amount = 'Budget amount must be greater than 0';
  }

  if (!data.period) {
    errors.period = 'Budget period is required';
  }

  if (!data.start_date) {
    errors.start_date = 'Start date is required';
  }

  if (data.alert_threshold < 0 || data.alert_threshold > 100) {
    errors.alert_threshold = 'Alert threshold must be between 0 and 100';
  }

  return errors;
}

/**
 * Calculate end date based on period
 */
export function calculateEndDate(startDate: Date, period: BudgetPeriod): Date {
  const endDate = new Date(startDate);

  switch (period) {
    case 'daily':
      endDate.setDate(endDate.getDate() + 1);
      break;
    case 'weekly':
      endDate.setDate(endDate.getDate() + 7);
      break;
    case 'monthly':
      endDate.setMonth(endDate.getMonth() + 1);
      break;
    case 'yearly':
      endDate.setFullYear(endDate.getFullYear() + 1);
      break;
  }

  return endDate;
}
