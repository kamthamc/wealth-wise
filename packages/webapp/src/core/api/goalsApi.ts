import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

// Types
export interface Goal {
  id: string;
  user_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: string;
  priority?: 'low' | 'medium' | 'high';
  category?: string;
  description?: string;
  status: 'active' | 'completed' | 'paused' | 'cancelled';
  created_at: string;
  updated_at: string;
}

export interface GoalContribution {
  id: string;
  goal_id: string;
  amount: number;
  date: string;
  notes?: string;
  created_at: string;
}

export interface GoalProgress {
  goalId: string;
  name: string;
  currentAmount: number;
  targetAmount: number;
  progress: number;
  contributions: number;
  totalContributions: number;
  estimatedCompletionDate?: string;
  daysRemaining?: number;
  isOnTrack?: boolean;
  status: string;
  recentContributions: GoalContribution[];
}

// API Functions

/**
 * Create a new goal
 */
export async function createGoal(goalData: {
  name: string;
  target_amount: number;
  current_amount?: number;
  target_date?: string;
  priority?: 'low' | 'medium' | 'high';
  category?: string;
  description?: string;
}): Promise<Goal> {
  const createGoalFn = httpsCallable<typeof goalData, Goal>(
    functions,
    'createGoal'
  );
  const result = await createGoalFn(goalData);
  return result.data;
}

/**
 * Update an existing goal
 */
export async function updateGoal(
  goalId: string,
  updates: Partial<{
    name: string;
    target_amount: number;
    current_amount: number;
    target_date: string;
    priority: 'low' | 'medium' | 'high';
    category: string;
    description: string;
    status: 'active' | 'completed' | 'paused' | 'cancelled';
  }>
): Promise<Goal> {
  const updateGoalFn = httpsCallable<
    { goalId: string; updates: typeof updates },
    Goal
  >(functions, 'updateGoal');
  const result = await updateGoalFn({ goalId, updates });
  return result.data;
}

/**
 * Delete a goal and all its contributions
 */
export async function deleteGoal(
  goalId: string
): Promise<{ success: boolean; goalId: string }> {
  const deleteGoalFn = httpsCallable<
    { goalId: string },
    { success: boolean; goalId: string }
  >(functions, 'deleteGoal');
  const result = await deleteGoalFn({ goalId });
  return result.data;
}

/**
 * Calculate goal progress and statistics
 */
export async function calculateGoalProgress(
  goalId: string
): Promise<GoalProgress> {
  const calculateGoalProgressFn = httpsCallable<
    { goalId: string },
    GoalProgress
  >(functions, 'calculateGoalProgress');
  const result = await calculateGoalProgressFn({ goalId });
  return result.data;
}

/**
 * Add a contribution to a goal
 */
export async function addGoalContribution(
  goalId: string,
  amount: number,
  date?: string,
  notes?: string
): Promise<{
  id: string;
  goal_id: string;
  amount: number;
  date: string;
  notes?: string;
  created_at: string;
  goalUpdated: {
    current_amount: number;
    status: string;
  };
}> {
  const addGoalContributionFn = httpsCallable<
    { goalId: string; amount: number; date?: string; notes?: string },
    any
  >(functions, 'addGoalContribution');
  const result = await addGoalContributionFn({ goalId, amount, date, notes });
  return result.data;
}

export const goalsApi = {
  createGoal,
  updateGoal,
  deleteGoal,
  calculateGoalProgress,
  addGoalContribution,
};
