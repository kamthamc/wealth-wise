import { QueryClient } from '@tanstack/react-query';

/**
 * Default query function for TanStack Query.
 * Can be customized to use a specific API client.
 */
const defaultQueryFn = async ({ queryKey }: { queryKey: any }) => {
  // This is a placeholder. In a real app, you would use your API client
  // to make a request based on the queryKey.
  // For example: const { data } = await apiClient.get(queryKey.join('/'));
  // return data;
  throw new Error('Default query function not implemented. Please provide a queryFn for your query.');
};

/**
 * Global QueryClient instance.
 *
 * Configuration:
 * - staleTime: 5 minutes. Data is considered fresh for this long and won't be refetched on mount.
 * - cacheTime: 15 minutes. Data is kept in the cache for this long after it becomes inactive.
 */
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: defaultQueryFn,
      staleTime: 1000 * 60 * 5, // 5 minutes
      cacheTime: 1000 * 60 * 15, // 15 minutes
      retry: 1, // Retry failed requests once
    },
  },
});
