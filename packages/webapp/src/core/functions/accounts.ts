import { functions } from "../firebase/firebase";
// import { CallableFunction } from "firebase-functions/v2/https";
import type { GetAccountTypesResponse  } from '@svc/wealth-wise-shared-types'
import { httpsCallable } from "firebase/functions";

export const getAccountTypes = async (): Promise<string[]> => {
  const getAccountTypesCallable = httpsCallable<null, GetAccountTypesResponse>(functions, 'getAccountTypes');
  const response = await getAccountTypesCallable();
  return response.data.accountTypes || [];
}