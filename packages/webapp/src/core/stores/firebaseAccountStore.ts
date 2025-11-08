import type { Unsubscribe } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { collection, getFirestore, onSnapshot, query, where } from 'firebase/firestore';
import { create } from 'zustand';
import { accountFunctions } from '../api';

interface Account {
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
  icon?: string;
  color?: string;
  is_active: boolean;
  created_at: any;
  updated_at: any;
}

interface AccountState {
  accounts: Account[];
  loading: boolean;
  isLoading: boolean; // Alias for compatibility
  error: string | null;
  unsubscribe: Unsubscribe | null;

  // Actions
  initialize: () => void;
  fetchAccounts: () => void; // Alias for initialize
  createAccount: (
    data: Omit<
      Account,
      'id' | 'user_id' | 'created_at' | 'updated_at' | 'is_active'
    >
  ) => Promise<void>;
  updateAccount: (id: string, updates: Partial<Account>) => Promise<void>;
  deleteAccount: (id: string) => Promise<void>;
  calculateBalance: (id: string) => Promise<void>;
  cleanup: () => void;
}

export const useFirebaseAccountStore = create<AccountState>((set, get) => ({
  accounts: [],
  loading: false,
  isLoading: false,
  error: null,
  unsubscribe: null,

    initialize: () => {
    const auth = getAuth();
    const userId = auth.currentUser?.uid;
    if (!userId) return;

    const db = getFirestore();
    const accountsRef = collection(db, 'accounts');
    const q = query(accountsRef, where('user_id', '==', userId));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const accounts = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Account[];
      set({ accounts, loading: false });
    });

    set({ unsubscribe });
  },

  fetchAccounts() {
    get().initialize();
  },

  createAccount: async (data) => {
    set({ loading: true, error: null });
    try {
      await accountFunctions.createAccount(data);
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  updateAccount: async (id, updates) => {
    set({ loading: true, error: null });
    try {
      await accountFunctions.updateAccount({ accountId: id, updates });
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  deleteAccount: async (id) => {
    set({ loading: true, error: null });
    try {
      await accountFunctions.deleteAccount(id);
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  calculateBalance: async (id) => {
    set({ loading: true, error: null });
    try {
      await accountFunctions.calculateAccountBalance(id);
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  cleanup: () => {
    const unsubscribe = get().unsubscribe;
    if (unsubscribe) {
      unsubscribe();
      set({ unsubscribe: null, accounts: [] });
    }
  },
}));
