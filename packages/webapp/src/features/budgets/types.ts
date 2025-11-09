/**
 * Budget Feature Types
 * Type definitions for enhanced multi-category budget management
 */

import type {
  Budget,
  BudgetAlert,
  BudgetCategory,
  BudgetProgress,
  BudgetStatus,
  CategorySpending,
} from '@/core/types';

// Re-export database types
export type {
  Budget,
  BudgetCategory,
  BudgetProgress,
  BudgetStatus,
  BudgetAlert,
  CategorySpending,
};

// Budget period type for UI
export type BudgetPeriodType =
  | 'monthly'
  | 'quarterly'
  | 'annual'
  | 'custom'
  | 'event';

/**
 * Form data for creating/editing budgets
 */
export interface BudgetFormData {
  name: string;
  description?: string;
  period_type: BudgetPeriodType;
  start_date: string; // ISO date string
  end_date?: string; // ISO date string
  is_recurring: boolean;
  rollover_enabled: boolean;
  categories: Array<{
    category: string;
    allocated_amount: number;
    alert_threshold: number; // 0.8 = 80%
    notes?: string;
  }>;
}

/**
 * Filters for budget list
 */
export interface BudgetFilters {
  period_type?: BudgetPeriodType;
  is_active?: boolean;
  is_recurring?: boolean;
  search?: string;
}

/**
 * Budget statistics for dashboard
 */
export interface BudgetStats {
  totalBudgets: number;
  activeBudgets: number;
  totalAllocated: number;
  totalSpent: number;
  totalRemaining: number;
  overallPercentUsed: number;
  budgetsOverLimit: number;
  budgetsAtWarning: number;
}

/**
 * Template for quick budget creation
 */
export interface BudgetTemplate {
  name: string;
  description: string;
  period_type: BudgetPeriodType;
  categories: Array<{
    category: string;
    percent: number;
  }>;
}

/**
 * Budget with calculated progress
 */
export interface BudgetWithProgress extends Budget {
  progress: BudgetProgress[];
  total_allocated: number;
  total_spent: number;
  total_remaining: number;
  overall_percent_used: number;
  alerts: BudgetAlert[];
}
