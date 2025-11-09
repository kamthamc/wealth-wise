import { create } from 'zustand';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';
import type { Goal, GoalContribution } from '@/core/types';

interface CreateGoalInput {
  name: string;
  target_amount: number;
  current_amount?: number;
  target_date?: string;
  priority?: 'low' | 'medium' | 'high';
  category?: string;
  description?: string;
}

interface UpdateGoalInput {
  goalId: string;
  updates: {
    name?: string;
    target_amount?: number;
    current_amount?: number;
    target_date?: string;
    priority?: 'low' | 'medium' | 'high';
    category?: string;
    description?: string;
    status?: 'active' | 'completed' | 'paused' | 'cancelled';
  };
}

interface AddContributionInput {
  goalId: string;
  amount: number;
  date?: string;
  notes?: string;
}

interface GoalProgress {
  goalId: string;
  name: string;
  currentAmount: number;
  targetAmount: number;
  progress: number;
  contributions: number;
  totalContributions: number;
  estimatedCompletionDate: string | null;
  daysRemaining: number | null;
  isOnTrack: boolean | null;
  status: string;
  currency: string;
  recentContributions: GoalContribution[];
}

interface GoalState {
  goals: Goal[];
  isLoading: boolean;
  error: string | null;
  fetchGoals: () => Promise<void>;
  createGoal: (input: CreateGoalInput) => Promise<Goal>;
  updateGoal: (input: UpdateGoalInput) => Promise<Goal>;
  deleteGoal: (goalId: string) => Promise<void>;
  addContribution: (input: AddContributionInput) => Promise<GoalContribution>;
  calculateProgress: (goalId: string) => Promise<GoalProgress>;
}

export const useGoalStore = create<GoalState>((set) => ({
  goals: [],
  isLoading: false,
  error: null,

  fetchGoals: async () => {
    set({ isLoading: true, error: null });
    try {
      const getGoals = httpsCallable<void, { goals: Goal[] }>(
        functions,
        'getGoals'
      );
      const result = await getGoals();
      set({ goals: result.data.goals, isLoading: false });
    } catch (error: any) {
      console.error('Error fetching goals:', error);
      set({ error: error.message || 'Failed to fetch goals', isLoading: false });
      throw error;
    }
  },

  createGoal: async (input: CreateGoalInput) => {
    set({ isLoading: true, error: null });
    try {
      const createGoalFn = httpsCallable<CreateGoalInput, Goal>(
        functions,
        'createGoal'
      );
      const result = await createGoalFn(input);
      const newGoal = result.data;
      
      // Add to local state
      set((state) => ({
        goals: [...state.goals, newGoal],
        isLoading: false,
      }));
      
      return newGoal;
    } catch (error: any) {
      console.error('Error creating goal:', error);
      set({ error: error.message || 'Failed to create goal', isLoading: false });
      throw error;
    }
  },

  updateGoal: async (input: UpdateGoalInput) => {
    set({ isLoading: true, error: null });
    try {
      const updateGoalFn = httpsCallable<UpdateGoalInput, Goal>(
        functions,
        'updateGoal'
      );
      const result = await updateGoalFn(input);
      const updatedGoal = result.data;
      
      // Update local state
      set((state) => ({
        goals: state.goals.map((g) =>
          g.id === input.goalId ? updatedGoal : g
        ),
        isLoading: false,
      }));
      
      return updatedGoal;
    } catch (error: any) {
      console.error('Error updating goal:', error);
      set({ error: error.message || 'Failed to update goal', isLoading: false });
      throw error;
    }
  },

  deleteGoal: async (goalId: string) => {
    set({ isLoading: true, error: null });
    try {
      const deleteGoalFn = httpsCallable<{ goalId: string }, { success: boolean }>(
        functions,
        'deleteGoal'
      );
      await deleteGoalFn({ goalId });
      
      // Remove from local state
      set((state) => ({
        goals: state.goals.filter((g) => g.id !== goalId),
        isLoading: false,
      }));
    } catch (error: any) {
      console.error('Error deleting goal:', error);
      set({ error: error.message || 'Failed to delete goal', isLoading: false });
      throw error;
    }
  },

  addContribution: async (input: AddContributionInput) => {
    set({ isLoading: true, error: null });
    try {
      const addContributionFn = httpsCallable<
        AddContributionInput,
        GoalContribution & { goalUpdated: { current_amount: number; status: string } }
      >(functions, 'addGoalContribution');
      
      const result = await addContributionFn(input);
      const contribution = result.data;
      
      // Update goal in local state with new current_amount and status
      set((state) => ({
        goals: state.goals.map((g) =>
          g.id === input.goalId
            ? {
                ...g,
                current_amount: contribution.goalUpdated.current_amount,
                status: contribution.goalUpdated.status as any,
              }
            : g
        ),
        isLoading: false,
      }));
      
      return contribution;
    } catch (error: any) {
      console.error('Error adding contribution:', error);
      set({ error: error.message || 'Failed to add contribution', isLoading: false });
      throw error;
    }
  },

  calculateProgress: async (goalId: string) => {
    try {
      const calculateProgressFn = httpsCallable<
        { goalId: string },
        GoalProgress
      >(functions, 'calculateGoalProgress');
      
      const result = await calculateProgressFn({ goalId });
      return result.data;
    } catch (error: any) {
      console.error('Error calculating progress:', error);
      throw error;
    }
  },
}));
