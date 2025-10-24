/**
 * Firebase Account Store
 * Manages accounts using Firebase Firestore and Cloud Functions
 */

import {
  collection,
  onSnapshot,
  query,
  type Timestamp,
  type Unsubscribe,
  where,
} from 'firebase/firestore';
import { create } from 'zustand';
import { accountFunctions } from '@/core/api';
import { db } from '@/core/firebase/firebase';
import { announce, announceError } from '@/shared/utils';
import { useAuthStore } from './authStore';

export interface Account {
  id: string;
  user_id: string;
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
  currency: string;
  icon: string;
  color: string;
  is_active: boolean;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface CreateAccountInput {
  name: string;
  type: Account['type'];
  balance?: number;
  currency?: string;
  icon?: string;
  color?: string;
}

export interface UpdateAccountInput {
  name?: string;
  type?: Account['type'];
  balance?: number;
  currency?: string;
  icon?: string;
  color?: string;
}

interface AccountState {
  // Data
  accounts: Account[];
  selectedAccountId: string | null;
  isLoading: boolean;
  error: string | null;

  // Real-time subscription
  unsubscribe: Unsubscribe | null;

  // Computed
  totalBalance: number;
  activeAccounts: Account[];

  // Actions
  subscribeToAccounts: () => void;
  createAccount: (input: CreateAccountInput) => Promise<void>;
  updateAccount: (id: string, updates: UpdateAccountInput) => Promise<void>;
  deleteAccount: (id: string) => Promise<void>;
  recalculateBalance: (id: string) => Promise<void>;
  selectAccount: (id: string | null) => void;
  reset: () => void;
}

const initialState = {
  accounts: [],
  selectedAccountId: null,
  isLoading: false,
  error: null,
  unsubscribe: null,
  totalBalance: 0,
  activeAccounts: [],
};

export const useAccountStore = create<AccountState>((set, get) => ({
  ...initialState,

  subscribeToAccounts: () => {
    const authStore = useAuthStore.getState();
    const userId = authStore.user?.uid;

    if (!userId) {
      console.warn('Cannot subscribe to accounts: No user logged in');
      return;
    }

    // Unsubscribe from previous subscription if exists
    const currentUnsub = get().unsubscribe;
    if (currentUnsub) {
      currentUnsub();
    }

    set({ isLoading: true });

    const accountsRef = collection(db, 'accounts');
    const q = query(accountsRef, where('user_id', '==', userId));

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const accounts: Account[] = snapshot.docs.map(
          (doc) =>
            ({
              id: doc.id,
              ...doc.data(),
            }) as Account
        );

        const activeAccounts = accounts.filter((acc) => acc.is_active);
        const totalBalance = accounts.reduce(
          (sum, acc) => sum + (acc.balance || 0),
          0
        );

        set({
          accounts,
          activeAccounts,
          totalBalance,
          isLoading: false,
          error: null,
        });
      },
      (error) => {
        console.error('Error subscribing to accounts:', error);
        const errorMessage =
          error instanceof Error ? error.message : 'Failed to load accounts';
        set({ error: errorMessage, isLoading: false });
        announceError(errorMessage);
      }
    );

    set({ unsubscribe });
  },

  createAccount: async (input) => {
    set({ isLoading: true, error: null });
    try {
      await accountFunctions.createAccount({
        name: input.name,
        type: input.type,
        balance: input.balance || 0,
        currency: input.currency || 'INR',
        icon: input.icon || 'wallet',
        color: input.color || '#3b82f6',
      });

      announce(`Account "${input.name}" created successfully`);
      set({ isLoading: false });
    } catch (error) {
      console.error('Error creating account:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to create account';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  updateAccount: async (id, updates) => {
    set({ isLoading: true, error: null });
    try {
      await accountFunctions.updateAccount({
        accountId: id,
        updates,
      });

      announce('Account updated successfully');
      set({ isLoading: false });
    } catch (error) {
      console.error('Error updating account:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update account';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  deleteAccount: async (id) => {
    set({ isLoading: true, error: null });
    try {
      await accountFunctions.deleteAccount(id);

      // Clear selection if deleted account was selected
      if (get().selectedAccountId === id) {
        set({ selectedAccountId: null });
      }

      announce('Account deleted successfully');
      set({ isLoading: false });
    } catch (error) {
      console.error('Error deleting account:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to delete account';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  recalculateBalance: async (id) => {
    try {
      await accountFunctions.calculateAccountBalance(id);
      announce('Account balance recalculated');
    } catch (error) {
      console.error('Error recalculating balance:', error);
      const errorMessage =
        error instanceof Error
          ? error.message
          : 'Failed to recalculate balance';
      announceError(errorMessage);
      throw error;
    }
  },

  selectAccount: (id) => {
    set({ selectedAccountId: id });
  },

  reset: () => {
    const { unsubscribe } = get();
    if (unsubscribe) {
      unsubscribe();
    }
    set(initialState);
  },
}));
