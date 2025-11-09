import { useMutation, useQueryClient } from '@tanstack/react-query';
import { transactionsApi } from '@/core/api'; // Assuming you have an API client
import type { Transaction } from '@/core/types';

interface TransactionFormData {
  account_id: string;
  amount: number;
  type: 'debit' | 'credit';
  category: string;
  description?: string;
  date: string;
  is_recurring?: boolean;
  is_initial_balance?: boolean;
}

/**
 * Custom hook for creating a new transaction.
 * 
 * This hook handles the creation of a new transaction and automatically
 * invalidates the transactions and accounts cache to trigger refetches.
 * 
 * @returns The result of the useMutation hook.
 */
export const useCreateTransaction = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: TransactionFormData) => {
      // This is where you would call your actual API
      // For example: return await transactionsApi.create(data);
      console.log('Creating transaction:', data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: Date.now().toString(),
        ...data,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as Transaction);
    },
    onSuccess: () => {
      // Invalidate and refetch transactions and accounts after successful creation
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for updating an existing transaction.
 * 
 * This hook handles transaction updates and automatically invalidates
 * the transactions and accounts cache to trigger refetches.
 * 
 * @returns The result of the useMutation hook.
 */
export const useUpdateTransaction = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<TransactionFormData> }) => {
      // This is where you would call your actual API
      // For example: return await transactionsApi.update(id, data);
      console.log('Updating transaction:', id, data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id,
        ...data,
        updated_at: new Date().toISOString(),
      } as Transaction);
    },
    onSuccess: () => {
      // Invalidate and refetch transactions and accounts after successful update
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for deleting a transaction.
 * 
 * This hook handles transaction deletion and automatically invalidates
 * the transactions and accounts cache to trigger refetches.
 * 
 * @returns The result of the useMutation hook.
 */
export const useDeleteTransaction = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      // This is where you would call your actual API
      // For example: return await transactionsApi.delete(id);
      console.log('Deleting transaction:', id);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({ id });
    },
    onSuccess: () => {
      // Invalidate and refetch transactions and accounts after successful deletion
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for bulk deleting transactions.
 * 
 * This hook handles bulk deletion of transactions and automatically invalidates
 * the transactions and accounts cache to trigger refetches.
 * 
 * @returns The result of the useMutation hook.
 */
export const useBulkDeleteTransactions = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (ids: string[]) => {
      // This is where you would call your actual API
      // For example: return await transactionsApi.bulkDelete(ids);
      console.log('Bulk deleting transactions:', ids);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({ deletedIds: ids });
    },
    onSuccess: () => {
      // Invalidate and refetch transactions and accounts after successful bulk deletion
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};

/**
 * Custom hook for importing transactions from CSV.
 * 
 * This hook handles CSV import of transactions and automatically invalidates
 * the transactions and accounts cache to trigger refetches.
 * 
 * @returns The result of the useMutation hook.
 */
export const useImportTransactions = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: { accountId: string; transactions: TransactionFormData[] }) => {
      // This is where you would call your actual API
      // For example: return await transactionsApi.import(data);
      console.log('Importing transactions:', data);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        importedCount: data.transactions.length,
        skippedCount: 0,
        transactions: data.transactions.map((t, i) => ({
          ...t,
          id: `import-${Date.now()}-${i}`,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })),
      });
    },
    onSuccess: () => {
      // Invalidate and refetch transactions and accounts after successful import
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
};
