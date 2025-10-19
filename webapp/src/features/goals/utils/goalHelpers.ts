/**
 * Goal Helper Utilities
 * Helper functions for goal management
 */

import type { GoalPriority, GoalProgress, GoalStatus } from '../types';

/**
 * Get icon emoji for goal status
 */
export function getGoalStatusIcon(status: GoalStatus): string {
  const icons: Record<GoalStatus, string> = {
    active: '🎯',
    completed: '✅',
    paused: '⏸️',
    cancelled: '❌',
  };
  return icons[status] || '🎯';
}

/**
 * Get display name for goal status
 */
export function getGoalStatusName(status: GoalStatus): string {
  const names: Record<GoalStatus, string> = {
    active: 'Active',
    completed: 'Completed',
    paused: 'Paused',
    cancelled: 'Cancelled',
  };
  return names[status] || 'Unknown';
}

/**
 * Get color variant for goal status
 */
export function getGoalStatusColor(
  status: GoalStatus
): 'success' | 'warning' | 'danger' | 'default' {
  const colors: Record<
    GoalStatus,
    'success' | 'warning' | 'danger' | 'default'
  > = {
    active: 'default',
    completed: 'success',
    paused: 'warning',
    cancelled: 'danger',
  };
  return colors[status];
}

/**
 * Get icon emoji for goal priority
 */
export function getGoalPriorityIcon(priority: GoalPriority): string {
  const icons: Record<GoalPriority, string> = {
    low: '🔵',
    medium: '🟡',
    high: '🔴',
  };
  return icons[priority] || '⚪';
}

/**
 * Get display name for goal priority
 */
export function getGoalPriorityName(priority: GoalPriority): string {
  const names: Record<GoalPriority, string> = {
    low: 'Low',
    medium: 'Medium',
    high: 'High',
  };
  return names[priority] || 'Unknown';
}

/**
 * Calculate goal progress
 */
export function calculateGoalProgress(
  currentAmount: number,
  targetAmount: number
): GoalProgress['status'] {
  const percentage = (currentAmount / targetAmount) * 100;

  if (percentage >= 100) return 'completed';
  if (percentage >= 80) return 'near-completion';
  if (percentage > 0) return 'in-progress';
  return 'not-started';
}

/**
 * Get color variant for goal progress status
 */
export function getGoalProgressColor(
  status: GoalProgress['status']
): 'success' | 'warning' | 'default' {
  const colors: Record<
    GoalProgress['status'],
    'success' | 'warning' | 'default'
  > = {
    'not-started': 'default',
    'in-progress': 'default',
    'near-completion': 'warning',
    completed: 'success',
  };
  return colors[status];
}

/**
 * Format goal percentage
 */
export function formatGoalPercentage(
  currentAmount: number,
  targetAmount: number
): string {
  const percentage = (currentAmount / targetAmount) * 100;
  return `${Math.min(Math.round(percentage), 100)}%`;
}

/**
 * Calculate days remaining until target date
 */
export function calculateDaysRemaining(targetDate: Date): number {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const target = new Date(targetDate);
  target.setHours(0, 0, 0, 0);

  const diffTime = target.getTime() - today.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays;
}

/**
 * Format days remaining text
 */
export function formatDaysRemaining(targetDate: Date): string {
  const days = calculateDaysRemaining(targetDate);

  if (days < 0) return `${Math.abs(days)} days overdue`;
  if (days === 0) return 'Due today';
  if (days === 1) return '1 day left';
  if (days <= 30) return `${days} days left`;

  const months = Math.floor(days / 30);
  if (months === 1) return '1 month left';
  if (months < 12) return `${months} months left`;

  const years = Math.floor(months / 12);
  return years === 1 ? '1 year left' : `${years} years left`;
}

/**
 * Validate goal form data
 */
export function validateGoalForm(data: {
  name: string;
  target_amount: number;
  category: string;
  target_date?: string;
}): Record<string, string> {
  const errors: Record<string, string> = {};

  if (!data.name || data.name.trim().length === 0) {
    errors.name = 'Goal name is required';
  } else if (data.name.trim().length < 3) {
    errors.name = 'Goal name must be at least 3 characters';
  }

  if (!data.target_amount || data.target_amount <= 0) {
    errors.target_amount = 'Target amount must be greater than 0';
  }

  if (!data.category || data.category.trim().length === 0) {
    errors.category = 'Category is required';
  }

  if (data.target_date) {
    const targetDate = new Date(data.target_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (targetDate < today) {
      errors.target_date = 'Target date must be in the future';
    }
  }

  return errors;
}
