import { useQuery } from '@tanstack/react-query';
import { institutionApi } from '@/core/api/institutionApi';
import type { Institution } from '@/core/types';

export const useInstitutions = () => {
    return useQuery({
        queryKey: ['institutions'],
        queryFn: institutionApi.getInstitutions,
        staleTime: 1000 * 60 * 60 * 24, // 24 hours
    });
};
