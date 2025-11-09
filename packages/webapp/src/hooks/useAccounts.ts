import { useQuery } from '@tanstack/react-query';
import { accountsApi } from '@/core/api'; // Assuming you have an API client
import { Account } from '@/types'; // Assuming you have this type

const fetchAccounts = async (): Promise<Account[]> => {
  // This is where you would call your actual API
  // For example: return await accountsApi.getAll();
  
  // For demonstration, we'll return mock data.
  // In a real scenario, you would remove this mock implementation.
  console.log('Fetching accounts...');
  return Promise.resolve([
    { id: '1', name: 'HDFC Bank', balance: 50000, currency: 'INR', type: 'bank' },
    { id: '2', name: 'ICICI Credit Card', balance: -15000, currency: 'INR', type: 'credit_card' },
    { id: '3', name: 'Zerodha', balance: 120000, currency: 'INR', type: 'brokerage' },
  ]);
};

/**
 * Custom hook to fetch user accounts using TanStack Query.
 *
 * This hook abstracts the data fetching logic for accounts. It handles caching,
 * background refetching, and provides convenient status variables.
 *
 * @returns The result of the useQuery hook.
 */
export const useAccounts = () => {
  return useQuery<Account[], Error>({
    queryKey: ['accounts'],
    queryFn: fetchAccounts,
    // Optional: Configure staleTime, cacheTime, etc. on a per-query basis
    staleTime: 1000 * 60 * 2, // 2 minutes
  });
};
