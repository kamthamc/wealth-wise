import { useQuery } from '@tanstack/react-query';
import { transactionsApi } from '@/core/api'; // Assuming you have an API client
import type { Transaction } from '@/core/types';

interface TransactionFilters {
  accountId?: string;
  categoryId?: string;
  type?: 'debit' | 'credit';
  startDate?: string;
  endDate?: string;
  searchQuery?: string;
}

const fetchTransactions = async (filters?: TransactionFilters): Promise<Transaction[]> => {
  // This is where you would call your actual API
  // For example: return await transactionsApi.getAll(filters);
  
  console.log('Fetching transactions with filters:', filters);
  
  // Mock implementation - replace with actual API call
  return Promise.resolve([
    {
      id: '1',
      account_id: '1',
      amount: -2500,
      type: 'debit',
      category: 'Groceries',
      description: 'Weekly grocery shopping',
      date: new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      id: '2',
      account_id: '1',
      amount: 50000,
      type: 'credit',
      category: 'Salary',
      description: 'Monthly salary',
      date: new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ] as Transaction[]);
};

/**
 * Custom hook to fetch user transactions using TanStack Query.
 *
 * This hook abstracts the data fetching logic for transactions. It handles caching,
 * background refetching, and provides convenient status variables.
 *
 * @param filters - Optional filters for transactions
 * @returns The result of the useQuery hook.
 */
export const useTransactions = (filters?: TransactionFilters) => {
  return useQuery<Transaction[], Error>({
    queryKey: ['transactions', filters],
    queryFn: () => fetchTransactions(filters),
    staleTime: 1000 * 60 * 1, // 1 minute
  });
};

/**
 * Custom hook to fetch a single transaction by ID.
 *
 * @param transactionId - The ID of the transaction to fetch
 * @returns The result of the useQuery hook.
 */
export const useTransaction = (transactionId: string) => {
  return useQuery<Transaction, Error>({
    queryKey: ['transactions', transactionId],
    queryFn: async () => {
      // This is where you would call your actual API
      // For example: return await transactionsApi.getById(transactionId);
      
      console.log('Fetching transaction:', transactionId);
      
      // Mock implementation - replace with actual API call
      return Promise.resolve({
        id: transactionId,
        account_id: '1',
        amount: -2500,
        type: 'debit',
        category: 'Groceries',
        description: 'Weekly grocery shopping',
        date: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as Transaction);
    },
    enabled: !!transactionId, // Only run the query if we have a transaction ID
  });
};
