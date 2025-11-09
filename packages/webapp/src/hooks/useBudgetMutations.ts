import { useMutation, useQueryClient } from '@tanstack/react-query';
import { budgetsApi } from '@/core/api'; // Assuming you have an API client
import type { Budget } from '@/core/types';

interface BudgetFormData {
  category: string;
  amount: number;
  period: 'monthly' | 'quarterly' | 'yearly';
  start_date?: string;
  end_date?: string;
}

/**
 * Custom hook for creating a new budget.
 * 
 * This hook handles the creation of a new budget and automatically
 * invalidates the budgets cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useCreateBudget = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: BudgetFormData) => {
      // This is where you would call your actual API
      // For example: return await budgetsApi.create(data);
      console.log('Creating budget:', data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: Date.now().toString(),
        ...data,
        spent: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as any);
    },
    onSuccess: () => {
      // Invalidate and refetch budgets after successful creation
      queryClient.invalidateQueries({ queryKey: ['budgets'] });
    },
  });
};

/**
 * Custom hook for updating an existing budget.
 * 
 * This hook handles budget updates and automatically invalidates
 * the budgets cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useUpdateBudget = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<BudgetFormData> }) => {
      // This is where you would call your actual API
      // For example: return await budgetsApi.update(id, data);
      console.log('Updating budget:', id, data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id,
        ...data,
        updated_at: new Date().toISOString(),
      } as any);
    },
    onSuccess: () => {
      // Invalidate and refetch budgets after successful update
      queryClient.invalidateQueries({ queryKey: ['budgets'] });
    },
  });
};

/**
 * Custom hook for deleting a budget.
 * 
 * This hook handles budget deletion and automatically invalidates
 * the budgets cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useDeleteBudget = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      // This is where you would call your actual API
      // For example: return await budgetsApi.delete(id);
      console.log('Deleting budget:', id);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({ id });
    },
    onSuccess: () => {
      // Invalidate and refetch budgets after successful deletion
      queryClient.invalidateQueries({ queryKey: ['budgets'] });
    },
  });
};
