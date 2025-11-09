import { useQuery } from '@tanstack/react-query';
import { goalsApi } from '@/core/api'; // Assuming you have an API client
import type { Goal } from '@/core/types';

/**
 * Custom hook to fetch user goals using TanStack Query.
 *
 * This hook abstracts the data fetching logic for goals. It handles caching,
 * background refetching, and provides convenient status variables.
 *
 * @returns The result of the useQuery hook.
 */
export const useGoals = () => {
  return useQuery<Goal[], Error>({
    queryKey: ['goals'],
    queryFn: async () => {
      // This is where you would call your actual API
      // For example: return await goalsApi.getAll();
      
      console.log('Fetching goals...');
      
      // Mock implementation - replace with actual API call
      return Promise.resolve([
        {
          id: '1',
          name: 'Emergency Fund',
          target_amount: 500000,
          current_amount: 250000,
          target_date: '2025-12-31',
          category: 'Savings',
          priority: 'high',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        {
          id: '2',
          name: 'Vacation to Europe',
          target_amount: 200000,
          current_amount: 50000,
          target_date: '2026-06-30',
          category: 'Travel',
          priority: 'medium',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
      ] as any[]);
    },
    staleTime: 1000 * 60 * 2, // 2 minutes
  });
};

/**
 * Custom hook to fetch a single goal by ID.
 *
 * @param goalId - The ID of the goal to fetch
 * @returns The result of the useQuery hook.
 */
export const useGoal = (goalId: string) => {
  return useQuery<Goal, Error>({
    queryKey: ['goals', goalId],
    queryFn: async () => {
      // This is where you would call your actual API
      // For example: return await goalsApi.getById(goalId);
      
      console.log('Fetching goal:', goalId);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: goalId,
        name: 'Emergency Fund',
        target_amount: 500000,
        current_amount: 250000,
        target_date: '2025-12-31',
        category: 'Savings',
        priority: 'high',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as any);
    },
    enabled: !!goalId, // Only run the query if we have a goal ID
  });
};
