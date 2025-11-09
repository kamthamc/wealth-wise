import { useQuery } from '@tanstack/react-query';
import { budgetsApi } from '@/core/api'; // Assuming you have an API client
import type { Budget } from '@/core/types';

/**
 * Custom hook to fetch user budgets using TanStack Query.
 *
 * This hook abstracts the data fetching logic for budgets. It handles caching,
 * background refetching, and provides convenient status variables.
 *
 * @returns The result of the useQuery hook.
 */
export const useBudgets = () => {
  return useQuery<Budget[], Error>({
    queryKey: ['budgets'],
    queryFn: async () => {
      // This is where you would call your actual API
      // For example: return await budgetsApi.getAll();
      
      console.log('Fetching budgets...');
      
      // Mock implementation - replace with actual API call
      return Promise.resolve([
        {
          id: '1',
          category: 'Groceries',
          amount: 10000,
          period: 'monthly',
          spent: 7500,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        {
          id: '2',
          category: 'Entertainment',
          amount: 5000,
          period: 'monthly',
          spent: 3200,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
      ] as any[]);
    },
    staleTime: 1000 * 60 * 2, // 2 minutes
  });
};

/**
 * Custom hook to fetch a single budget by ID.
 *
 * @param budgetId - The ID of the budget to fetch
 * @returns The result of the useQuery hook.
 */
export const useBudget = (budgetId: string) => {
  return useQuery<Budget, Error>({
    queryKey: ['budgets', budgetId],
    queryFn: async () => {
      // This is where you would call your actual API
      // For example: return await budgetsApi.getById(budgetId);
      
      console.log('Fetching budget:', budgetId);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: budgetId,
        category: 'Groceries',
        amount: 10000,
        period: 'monthly',
        spent: 7500,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as any);
    },
    enabled: !!budgetId, // Only run the query if we have a budget ID
  });
};
