import { useMutation, useQueryClient } from '@tanstack/react-query';
import { accountsApi } from '@/core/api'; // Assuming you have an API client
import type { Account } from '@/core/types';
import type { AccountFormData } from '@/features/accounts/types';

/**
 * Custom hook for creating a new account.
 * 
 * This hook handles the creation of a new account and automatically
 * invalidates the accounts cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useCreateAccount = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: AccountFormData) => {
      // This is where you would call your actual API
      // For example: return await accountsApi.create(data);
      console.log('Creating account:', data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: Date.now().toString(),
        ...data,
        balance: 0,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as Account);
    },
    onSuccess: () => {
      // Invalidate and refetch accounts after successful creation
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for updating an existing account.
 * 
 * This hook handles account updates and automatically invalidates
 * the accounts cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useUpdateAccount = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: AccountFormData }) => {
      // This is where you would call your actual API
      // For example: return await accountsApi.update(id, data);
      console.log('Updating account:', id, data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id,
        ...data,
        updated_at: new Date().toISOString(),
      } as Account);
    },
    onSuccess: () => {
      // Invalidate and refetch accounts after successful update
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for deleting an account.
 * 
 * This hook handles account deletion and automatically invalidates
 * the accounts cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useDeleteAccount = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      // This is where you would call your actual API
      // For example: return await accountsApi.delete(id);
      console.log('Deleting account:', id);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({ id });
    },
    onSuccess: () => {
      // Invalidate and refetch accounts after successful deletion
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for transferring money between accounts.
 * 
 * This hook handles account transfers and automatically invalidates
 * the accounts cache to trigger a refetch.
 * 
 * @returns The result of the useMutation hook.
 */
export const useTransferBetweenAccounts = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (transferData: {
      fromAccountId: string;
      toAccountId: string;
      amount: number;
      description?: string;
    }) => {
      // This is where you would call your actual API
      // For example: return await accountsApi.transfer(transferData);
      console.log('Transferring between accounts:', transferData);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve(transferData);
    },
    onSuccess: () => {
      // Invalidate and refetch accounts after successful transfer
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
    },
  });
};
