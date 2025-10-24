import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

/**
 * Account Types
 */
export interface CreateAccountData {
  name: string;
  type:
    | 'bank'
    | 'credit_card'
    | 'upi'
    | 'brokerage'
    | 'cash'
    | 'wallet'
    | 'fixed_deposit'
    | 'recurring_deposit'
    | 'ppf'
    | 'nsc'
    | 'kvp'
    | 'scss'
    | 'post_office';
  balance: number;
  currency?: string;
  icon?: string;
  color?: string;
}

export interface UpdateAccountData {
  accountId: string;
  updates: Partial<CreateAccountData>;
}

/**
 * Cloud Functions API for Accounts
 */
export const accountFunctions = {
  /**
   * Create a new account
   */
  createAccount: async (data: CreateAccountData) => {
    const callable = httpsCallable(functions, 'createAccount');
    const result = await callable(data);
    return result.data;
  },

  /**
   * Update an existing account
   */
  updateAccount: async (data: UpdateAccountData) => {
    const callable = httpsCallable(functions, 'updateAccount');
    const result = await callable(data);
    return result.data;
  },

  /**
   * Delete an account
   */
  deleteAccount: async (accountId: string) => {
    const callable = httpsCallable(functions, 'deleteAccount');
    const result = await callable({ accountId });
    return result.data;
  },

  /**
   * Calculate account balance from transactions
   */
  calculateAccountBalance: async (accountId: string) => {
    const callable = httpsCallable(functions, 'calculateAccountBalance');
    const result = await callable({ accountId });
    return result.data;
  },
};
