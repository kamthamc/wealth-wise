import { useMutation, useQueryClient } from '@tanstack/react-query';
import { goalsApi } from '@/core/api'; // Assuming you have an API client
import type { Goal } from '@/core/types';

interface GoalFormData {
  name: string;
  target_amount: number;
  current_amount?: number;
  target_date: string;
  category: string;
  priority?: 'low' | 'medium' | 'high';
  description?: string;
}

/**
 * Custom hook for creating a new goal.
 * 
 * This hook handles the creation of a new goal and automatically
 * invalidates the goals cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useCreateGoal = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: GoalFormData) => {
      // This is where you would call your actual API
      // For example: return await goalsApi.create(data);
      console.log('Creating goal:', data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: Date.now().toString(),
        ...data,
        current_amount: data.current_amount || 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as any);
    },
    onSuccess: () => {
      // Invalidate and refetch goals after successful creation
      queryClient.invalidateQueries({ queryKey: ['goals'] });
    },
  });
};

/**
 * Custom hook for updating an existing goal.
 * 
 * This hook handles goal updates and automatically invalidates
 * the goals cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useUpdateGoal = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<GoalFormData> }) => {
      // This is where you would call your actual API
      // For example: return await goalsApi.update(id, data);
      console.log('Updating goal:', id, data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id,
        ...data,
        updated_at: new Date().toISOString(),
      } as any);
    },
    onSuccess: () => {
      // Invalidate and refetch goals after successful update
      queryClient.invalidateQueries({ queryKey: ['goals'] });
    },
  });
};

/**
 * Custom hook for deleting a goal.
 * 
 * This hook handles goal deletion and automatically invalidates
 * the goals cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useDeleteGoal = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      // This is where you would call your actual API
      // For example: return await goalsApi.delete(id);
      console.log('Deleting goal:', id);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({ id });
    },
    onSuccess: () => {
      // Invalidate and refetch goals after successful deletion
      queryClient.invalidateQueries({ queryKey: ['goals'] });
    },
  });
};

/**
 * Custom hook for contributing to a goal.
 * 
 * This hook handles contributions to a goal and automatically invalidates
 * the goals cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useContributeToGoal = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ goalId, amount }: { goalId: string; amount: number }) => {
      // This is where you would call your actual API
      // For example: return await goalsApi.contribute(goalId, amount);
      console.log('Contributing to goal:', goalId, amount);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        goalId,
        amount,
        updated_at: new Date().toISOString(),
      });
    },
    onSuccess: () => {
      // Invalidate and refetch goals and accounts after successful contribution
      queryClient.invalidateQueries({ queryKey: ['goals'] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};
