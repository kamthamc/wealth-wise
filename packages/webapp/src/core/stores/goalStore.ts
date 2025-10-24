/**
 * Goal state store
 * Manages financial goals data and operations
 */

import { create } from 'zustand';
import type {
  CreateGoalInput,
  Goal,
  GoalStatus,
  UpdateGoalInput,
} from '@/core/db';

interface GoalState {
  // Data
  goals: Goal[];
  selectedGoalId: string | null;
  isLoading: boolean;
  error: string | null;

  // Filters
  statusFilter: GoalStatus | 'all';

  // Actions
  fetchGoals: () => Promise<void>;
  createGoal: (input: CreateGoalInput) => Promise<Goal | null>;
  updateGoal: (input: UpdateGoalInput) => Promise<Goal | null>;
  deleteGoal: (id: string) => Promise<boolean>;
  selectGoal: (id: string | null) => void;
  setStatusFilter: (status: GoalStatus | 'all') => void;
  contributeToGoal: (
    goalId: string,
    amount: number,
    note?: string
  ) => Promise<boolean>;
  reset: () => void;
}

const initialState = {
  goals: [],
  selectedGoalId: null,
  isLoading: false,
  error: null,
  statusFilter: 'active' as GoalStatus,
};

export const useGoalStore = create<GoalState>((set, get) => ({
  ...initialState,

  fetchGoals: async () => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement goal repository
      // const filter = get().statusFilter === 'all' ? undefined : { status: get().statusFilter }
      // const goals = await goalRepository.findAll(filter)

      set({
        goals: [],
        isLoading: false,
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to fetch goals';
      set({ error: errorMessage, isLoading: false });
    }
  },

  createGoal: async (_input) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement goal repository
      // const goal = await goalRepository.create(_input)
      // await get().fetchGoals()

      set({ isLoading: false });
      return null;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to create goal';
      set({ error: errorMessage, isLoading: false });
      return null;
    }
  },

  updateGoal: async (_input) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement goal repository
      // const goal = await goalRepository.update(_input)
      // await get().fetchGoals()

      set({ isLoading: false });
      return null;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update goal';
      set({ error: errorMessage, isLoading: false });
      return null;
    }
  },

  deleteGoal: async (_id) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement goal repository
      // const success = await goalRepository.delete(_id)
      // await get().fetchGoals()

      set({ isLoading: false });
      return false;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to delete goal';
      set({ error: errorMessage, isLoading: false });
      return false;
    }
  },

  selectGoal: (id) => {
    set({ selectedGoalId: id });
  },

  setStatusFilter: (status) => {
    set({ statusFilter: status });
    get().fetchGoals();
  },

  contributeToGoal: async (_goalId, _amount, _note) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement goal contribution
      // await goalContributionRepository.create({ goal_id: _goalId, amount: _amount, note: _note })
      // await get().fetchGoals()

      set({ isLoading: false });
      return false;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to contribute to goal';
      set({ error: errorMessage, isLoading: false });
      return false;
    }
  },

  reset: () => set(initialState),
}));

/**
 * Selectors
 */
export const selectSelectedGoal = (state: GoalState) =>
  state.goals.find((goal) => goal.id === state.selectedGoalId) || null;

export const selectGoalById = (id: string) => (state: GoalState) =>
  state.goals.find((goal) => goal.id === id) || null;

export const selectActiveGoals = (state: GoalState) =>
  state.goals.filter((goal) => goal.status === 'active');

export const selectCompletedGoals = (state: GoalState) =>
  state.goals.filter((goal) => goal.status === 'completed');

export const selectGoalProgress = (id: string) => (state: GoalState) => {
  const goal = state.goals.find((g) => g.id === id);
  if (!goal) return 0;
  return Math.min((goal.current_amount / goal.target_amount) * 100, 100);
};

export const selectIsLoading = (state: GoalState) => state.isLoading;
