/**
 * Budget Service - STUB IMPLEMENTATION
 * Original functionality depends on PGlite repositories which have been removed
 * TODO: Implement with Firebase when needed
 */

import type {
  Budget,
  BudgetAlert,
  BudgetCategory,
  BudgetFilters,
  BudgetProgress,
  CategorySpending,
} from '@/core/types';

class BudgetService {
  async createBudget(): Promise<{ budget: Budget; categories: BudgetCategory[] }> {
    throw new Error('Budget service not implemented with Firebase');
  }

  async updateBudget(): Promise<Budget> {
    throw new Error('Budget service not implemented with Firebase');
  }

  async deleteBudget(): Promise<void> {
    throw new Error('Budget service not implemented with Firebase');
  }

  async getBudgets(): Promise<Budget[]> {
    return [];
  }

  async getBudgetById(): Promise<Budget | null> {
    return null;
  }

  async calculateProgress(): Promise<BudgetProgress[]> {
    return [];
  }

  async getCategorySpending(): Promise<CategorySpending[]> {
    return [];
  }

  async getAlerts(): Promise<BudgetAlert[]> {
    return [];
  }

  async filterBudgets(_filters: BudgetFilters): Promise<Budget[]> {
    return [];
  }
}

export const budgetService = new BudgetService();
