/**
 * Goals Feature Types
 * Type definitions for goal management
 */

import type {
  GoalPriority as DbGoalPriority,
  GoalStatus as DbGoalStatus,
} from '@/core/db/types';

// Re-export database types
export type GoalPriority = DbGoalPriority;
export type GoalStatus = DbGoalStatus;

export interface GoalFormData {
  name: string;
  target_amount: number;
  target_date?: string; // ISO date string
  category: string;
  priority?: GoalPriority;
  icon?: string;
  color?: string;
}

export interface GoalFilters {
  status?: GoalStatus;
  priority?: GoalPriority;
  category?: string;
  search?: string;
}

export interface GoalStats {
  totalGoals: number;
  completedGoals: number;
  activeGoals: number;
  totalTargetAmount: number;
  totalCurrentAmount: number;
  overallProgress: number;
}

export interface GoalProgress {
  goal_id: string;
  percentage: number;
  remaining: number;
  status: 'not-started' | 'in-progress' | 'near-completion' | 'completed';
}
