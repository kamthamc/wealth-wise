/**
 * Budget state store
 * Manages budgets data and operations with multi-category support
 */

import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import { budgetService } from '@/core/services/budgetService';
import type {
  BudgetFilters,
  BudgetFormData,
  BudgetWithProgress,
} from '@/features/budgets/types';
import type { Budget } from '../db/types';

interface BudgetState {
  // Data
  budgets: BudgetWithProgress[];
  selectedBudgetId: string | null;
  isLoading: boolean;
  error: string | null;

  // Filters
  showInactive: boolean;

  // Actions
  fetchBudgets: (filters?: BudgetFilters) => Promise<void>;
  getBudgetById: (id: string) => Promise<BudgetWithProgress | null>;
  createBudget: (input: BudgetFormData) => Promise<Budget | null>;
  updateBudget: (
    id: string,
    input: Partial<BudgetFormData>
  ) => Promise<Budget | null>;
  deleteBudget: (id: string) => Promise<boolean>;
  refreshBudgetProgress: (id: string) => Promise<void>;
  selectBudget: (id: string | null) => void;
  toggleShowInactive: () => void;

  // Computed Getters
  getActiveBudgets: () => BudgetWithProgress[];
  getBudgetsWithAlerts: () => BudgetWithProgress[];
  getBudgetsByPeriod: (period: Budget['period_type']) => BudgetWithProgress[];

  reset: () => void;
}

const initialState = {
  budgets: [] as BudgetWithProgress[],
  selectedBudgetId: null,
  isLoading: false,
  error: null,
  showInactive: false,
};

export const useBudgetStore = create<BudgetState>()(
  devtools(
    (set, get) => ({
      ...initialState,

      fetchBudgets: async (filters?: BudgetFilters) => {
        set({ isLoading: true, error: null });
        try {
          const budgets = await budgetService.listBudgets(filters);

          // Enrich budgets with progress and alerts
          const budgetsWithProgress = await Promise.all(
            budgets.map(async (budget) => {
              const progress = await budgetService.calculateBudgetProgress(
                budget.id
              );
              const alerts = await budgetService.checkBudgetAlerts(budget.id);

              const totalAllocated = progress.reduce(
                (sum, p) => sum + p.allocated,
                0
              );
              const totalSpent = progress.reduce((sum, p) => sum + p.spent, 0);
              const totalRemaining = totalAllocated - totalSpent;
              const overallPercentUsed =
                totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

              return {
                ...budget,
                progress,
                total_allocated: totalAllocated,
                total_spent: totalSpent,
                total_remaining: totalRemaining,
                overall_percent_used: overallPercentUsed,
                alerts,
              } as BudgetWithProgress;
            })
          );

          set({
            budgets: budgetsWithProgress,
            isLoading: false,
          });
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : 'Failed to fetch budgets';
          set({ error: errorMessage, isLoading: false });
        }
      },

      getBudgetById: async (id: string) => {
        set({ isLoading: true, error: null });
        try {
          const budget = await budgetService.getBudget(id);
          if (!budget) {
            set({ isLoading: false });
            return null;
          }

          const progress = await budgetService.calculateBudgetProgress(id);
          const alerts = await budgetService.checkBudgetAlerts(id);

          const totalAllocated = progress.reduce(
            (sum, p) => sum + p.allocated,
            0
          );
          const totalSpent = progress.reduce((sum, p) => sum + p.spent, 0);
          const totalRemaining = totalAllocated - totalSpent;
          const overallPercentUsed =
            totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

          const budgetWithProgress = {
            ...budget.budget,
            progress,
            total_allocated: totalAllocated,
            total_spent: totalSpent,
            total_remaining: totalRemaining,
            overall_percent_used: overallPercentUsed,
            alerts,
          } as BudgetWithProgress;

          // Update in store
          set((state) => ({
            budgets: state.budgets.map((b) =>
              b.id === id ? budgetWithProgress : b
            ),
            isLoading: false,
          }));

          return budgetWithProgress;
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : 'Failed to fetch budget';
          set({ error: errorMessage, isLoading: false });
          return null;
        }
      },

      createBudget: async (input: BudgetFormData) => {
        set({ isLoading: true, error: null });
        try {
          const budget = await budgetService.createBudget(
            {
              name: input.name,
              description: input.description,
              period_type: input.period_type,
              start_date: new Date(input.start_date),
              end_date: input.end_date ? new Date(input.end_date) : undefined,
              is_recurring: input.is_recurring,
              rollover_enabled: input.rollover_enabled,
              rollover_amount: 0,
              is_active: true,
            },
            input.categories
          );
          await get().fetchBudgets();
          set({ isLoading: false });
          return budget;
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : 'Failed to create budget';
          set({ error: errorMessage, isLoading: false });
          return null;
        }
      },

      updateBudget: async (id: string, input: Partial<BudgetFormData>) => {
        set({ isLoading: true, error: null });
        try {
          const updateInput: any = { ...input };
          if (input.start_date) {
            updateInput.start_date = new Date(input.start_date);
          }
          if (input.end_date) {
            updateInput.end_date = new Date(input.end_date);
          }

          const budget = await budgetService.updateBudget(id, updateInput);
          if (budget) {
            await get().refreshBudgetProgress(id);
          }
          set({ isLoading: false });
          return budget;
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : 'Failed to update budget';
          set({ error: errorMessage, isLoading: false });
          return null;
        }
      },

      deleteBudget: async (id: string) => {
        set({ isLoading: true, error: null });
        try {
          await budgetService.deleteBudget(id);
          set((state) => ({
            budgets: state.budgets.filter((b) => b.id !== id),
            selectedBudgetId:
              state.selectedBudgetId === id ? null : state.selectedBudgetId,
            isLoading: false,
          }));
          return true;
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : 'Failed to delete budget';
          set({ error: errorMessage, isLoading: false });
          return false;
        }
      },

      refreshBudgetProgress: async (id: string) => {
        try {
          const progress = await budgetService.calculateBudgetProgress(id);
          const alerts = await budgetService.checkBudgetAlerts(id);

          set((state) => ({
            budgets: state.budgets.map((b) => {
              if (b.id === id) {
                const totalAllocated = progress.reduce(
                  (sum, p) => sum + p.allocated,
                  0
                );
                const totalSpent = progress.reduce(
                  (sum, p) => sum + p.spent,
                  0
                );
                const totalRemaining = totalAllocated - totalSpent;
                const overallPercentUsed =
                  totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

                return {
                  ...b,
                  progress,
                  total_allocated: totalAllocated,
                  total_spent: totalSpent,
                  total_remaining: totalRemaining,
                  overall_percent_used: overallPercentUsed,
                  alerts,
                };
              }
              return b;
            }),
          }));
        } catch (error) {
          console.error(`Failed to refresh budget progress for ${id}:`, error);
        }
      },

      selectBudget: (id) => {
        set({ selectedBudgetId: id });
      },

      toggleShowInactive: () => {
        set((state) => ({ showInactive: !state.showInactive }));
        get().fetchBudgets();
      },

      getActiveBudgets: () => {
        return get().budgets.filter((b) => b.is_active);
      },

      getBudgetsWithAlerts: () => {
        return get().budgets.filter((b) => b.alerts.length > 0);
      },

      getBudgetsByPeriod: (period) => {
        return get().budgets.filter((b) => b.period_type === period);
      },

      reset: () => set(initialState),
    }),
    { name: 'BudgetStore' }
  )
);

/**
 * Selectors
 */
export const selectSelectedBudget = (state: BudgetState) =>
  state.budgets.find((budget) => budget.id === state.selectedBudgetId) || null;

export const selectBudgetById = (id: string) => (state: BudgetState) =>
  state.budgets.find((budget) => budget.id === id) || null;

export const selectActiveBudgets = (state: BudgetState) =>
  state.budgets.filter((budget) => budget.is_active);

export const selectIsLoading = (state: BudgetState) => state.isLoading;
