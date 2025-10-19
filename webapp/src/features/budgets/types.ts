/**
 * Budget Feature Types
 * Type definitions for budget management
 */

import type { BudgetPeriod as DbBudgetPeriod } from '@/core/db/types';

// Re-export database budget period type
export type BudgetPeriod = DbBudgetPeriod;

export interface BudgetFormData {
  name: string;
  category: string;
  amount: number;
  period: BudgetPeriod;
  start_date: string; // ISO date string
  end_date?: string; // ISO date string
  alert_threshold: number; // Percentage (0-100)
  is_active: boolean;
}

export interface BudgetFilters {
  period?: BudgetPeriod;
  category?: string;
  is_active?: boolean;
  search?: string;
}

export interface BudgetStats {
  totalBudget: number;
  totalSpent: number;
  remainingBudget: number;
  budgetCount: number;
  overBudgetCount: number;
}

export interface BudgetProgress {
  budget_id: string;
  percentage: number;
  remaining: number;
  status: 'safe' | 'warning' | 'danger' | 'over';
}
