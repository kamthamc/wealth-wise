import type { Timestamp, Unsubscribe } from 'firebase/firestore';
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  where,
} from 'firebase/firestore';
import { create } from 'zustand';
import { transactionFunctions } from '../api';
import { db } from '../firebase/firebase';
import { useAuthStore } from './authStore';

interface Transaction {
  id: string;
  user_id: string;
  account_id: string;
  type: 'income' | 'expense' | 'transfer';
  category: string;
  amount: number;
  description?: string;
  date: Timestamp;
  tags?: string[];
  location?: string;
  receipt_url?: string;
  is_recurring?: boolean;
  recurring_frequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  is_transfer?: boolean;
  linked_transaction_id?: string;
  created_at: any;
  updated_at: any;
}

interface TransactionState {
  transactions: Transaction[];
  loading: boolean;
  error: string | null;
  unsubscribe: Unsubscribe | null;

  // Actions
  initialize: () => void;
  createTransaction: (data: any) => Promise<void>;
  updateTransaction: (id: string, updates: any) => Promise<void>;
  deleteTransaction: (id: string) => Promise<void>;
  getStats: (startDate: string, endDate: string) => Promise<any>;
  cleanup: () => void;
}

export const useFirebaseTransactionStore = create<TransactionState>(
  (set, get) => ({
    transactions: [],
    loading: false,
    error: null,
    unsubscribe: null,

    initialize: () => {
      const user = useAuthStore.getState().user;
      if (!user) {
        set({ transactions: [], loading: false });
        return;
      }

      set({ loading: true, error: null });

      // Cleanup previous subscription
      const prevUnsubscribe = get().unsubscribe;
      if (prevUnsubscribe) {
        prevUnsubscribe();
      }

      // Subscribe to real-time updates
      const q = query(
        collection(db, 'transactions'),
        where('user_id', '==', user.uid),
        orderBy('date', 'desc')
      );

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const transactions = snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
          })) as Transaction[];

          set({ transactions, loading: false });
        },
        (error) => {
          console.error('Error fetching transactions:', error);
          set({ error: error.message, loading: false });
        }
      );

      set({ unsubscribe });
    },

    createTransaction: async (data) => {
      set({ loading: true, error: null });
      try {
        await transactionFunctions.createTransaction(data);
        set({ loading: false });
      } catch (error: any) {
        set({ error: error.message, loading: false });
        throw error;
      }
    },

    updateTransaction: async (id, updates) => {
      set({ loading: true, error: null });
      try {
        await transactionFunctions.updateTransaction({
          transactionId: id,
          updates,
        });
        set({ loading: false });
      } catch (error: any) {
        set({ error: error.message, loading: false });
        throw error;
      }
    },

    deleteTransaction: async (id) => {
      set({ loading: true, error: null });
      try {
        await transactionFunctions.deleteTransaction(id);
        set({ loading: false });
      } catch (error: any) {
        set({ error: error.message, loading: false });
        throw error;
      }
    },

    getStats: async (startDate, endDate) => {
      set({ loading: true, error: null });
      try {
        const result = await transactionFunctions.getTransactionStats({
          startDate,
          endDate,
        });
        set({ loading: false });
        return result;
      } catch (error: any) {
        set({ error: error.message, loading: false });
        throw error;
      }
    },

    cleanup: () => {
      const unsubscribe = get().unsubscribe;
      if (unsubscribe) {
        unsubscribe();
        set({ unsubscribe: null, transactions: [] });
      }
    },
  })
);
