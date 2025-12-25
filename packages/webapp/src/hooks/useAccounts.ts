import { useQuery } from '@tanstack/react-query';
import { accountsApi } from '@/core/api';
import type { Account } from '@/core/types'; // Assuming you have this type

const fetchAccounts = async (): Promise<Account[]> => {
  const result = await accountsApi.getAccounts();
  // Ensure we return an array, even if the API structure is different
  return Array.isArray(result) ? result : (result as any).data || [];
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
