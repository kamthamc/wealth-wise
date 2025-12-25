import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';
import type { Institution } from '../types';

export interface GetInstitutionsResponse {
    institutions: Institution[];
}

export const institutionApi = {
    getInstitutions: async (): Promise<Institution[]> => {
        const callable = httpsCallable<void, GetInstitutionsResponse>(
            functions,
            'getInstitutions'
        );
        const result = await callable();
        return result.data.institutions;
    },
};
