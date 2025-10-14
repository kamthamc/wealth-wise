/**
 * Budget state store
 * Manages budgets data and operations
 */

import { create } from 'zustand';
import type { Budget, CreateBudgetInput, UpdateBudgetInput } from '@/core/db';

interface BudgetState {
  // Data
  budgets: Budget[];
  selectedBudgetId: string | null;
  isLoading: boolean;
  error: string | null;

  // Filters
  showInactive: boolean;

  // Actions
  fetchBudgets: () => Promise<void>;
  createBudget: (input: CreateBudgetInput) => Promise<Budget | null>;
  updateBudget: (input: UpdateBudgetInput) => Promise<Budget | null>;
  deleteBudget: (id: string) => Promise<boolean>;
  selectBudget: (id: string | null) => void;
  toggleShowInactive: () => void;
  reset: () => void;
}

const initialState = {
  budgets: [],
  selectedBudgetId: null,
  isLoading: false,
  error: null,
  showInactive: false,
};

export const useBudgetStore = create<BudgetState>((set, get) => ({
  ...initialState,

  fetchBudgets: async () => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement budget repository
      // const budgets = await budgetRepository.findAll({ is_active: !get().showInactive })

      set({
        budgets: [],
        isLoading: false,
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to fetch budgets';
      set({ error: errorMessage, isLoading: false });
    }
  },

  createBudget: async (_input) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement budget repository
      // const budget = await budgetRepository.create(_input)
      // await get().fetchBudgets()

      set({ isLoading: false });
      return null;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to create budget';
      set({ error: errorMessage, isLoading: false });
      return null;
    }
  },

  updateBudget: async (_input) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement budget repository
      // const budget = await budgetRepository.update(_input)
      // await get().fetchBudgets()

      set({ isLoading: false });
      return null;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update budget';
      set({ error: errorMessage, isLoading: false });
      return null;
    }
  },

  deleteBudget: async (_id) => {
    set({ isLoading: true, error: null });
    try {
      // TODO: Implement budget repository
      // const success = await budgetRepository.delete(_id)
      // await get().fetchBudgets()

      set({ isLoading: false });
      return false;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to delete budget';
      set({ error: errorMessage, isLoading: false });
      return false;
    }
  },

  selectBudget: (id) => {
    set({ selectedBudgetId: id });
  },

  toggleShowInactive: () => {
    set((state) => ({ showInactive: !state.showInactive }));
    get().fetchBudgets();
  },

  reset: () => set(initialState),
}));

/**
 * Selectors
 */
export const selectSelectedBudget = (state: BudgetState) =>
  state.budgets.find((budget) => budget.id === state.selectedBudgetId) || null;

export const selectBudgetById = (id: string) => (state: BudgetState) =>
  state.budgets.find((budget) => budget.id === id) || null;

export const selectActiveBudgets = (state: BudgetState) =>
  state.budgets.filter((budget) => budget.is_active);

export const selectBudgetsByCategory =
  (category: string) => (state: BudgetState) =>
    state.budgets.filter((budget) => budget.category === category);

export const selectIsLoading = (state: BudgetState) => state.isLoading;
