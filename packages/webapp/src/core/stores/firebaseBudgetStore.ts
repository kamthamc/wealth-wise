import type { Unsubscribe } from 'firebase/firestore';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { create } from 'zustand';
import { budgetFunctions } from '../api';
import { db } from '../firebase/firebase';
import { useAuthStore } from './authStore';

interface BudgetCategory {
  category: string;
  allocated_amount: number;
  alert_threshold?: number;
  notes?: string;
}

interface Budget {
  id: string;
  user_id: string;
  name: string;
  description?: string;
  period_type: 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event';
  start_date: any;
  end_date?: any;
  is_recurring: boolean;
  rollover_enabled: boolean;
  categories: BudgetCategory[];
  created_at: any;
  updated_at: any;
}

interface BudgetState {
  budgets: Budget[];
  loading: boolean;
  error: string | null;
  unsubscribe: Unsubscribe | null;

  // Actions
  initialize: () => void;
  createBudget: (data: any) => Promise<void>;
  updateBudget: (id: string, updates: any) => Promise<void>;
  deleteBudget: (id: string) => Promise<void>;
  calculateProgress: (id: string) => Promise<any>;
  cleanup: () => void;
}

export const useFirebaseBudgetStore = create<BudgetState>((set, get) => ({
  budgets: [],
  loading: false,
  error: null,
  unsubscribe: null,

  initialize: () => {
    const user = useAuthStore.getState().user;
    if (!user) {
      set({ budgets: [], loading: false });
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
      collection(db, 'budgets'),
      where('user_id', '==', user.uid)
    );

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const budgets = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Budget[];

        set({ budgets, loading: false });
      },
      (error) => {
        console.error('Error fetching budgets:', error);
        set({ error: error.message, loading: false });
      }
    );

    set({ unsubscribe });
  },

  createBudget: async (data) => {
    set({ loading: true, error: null });
    try {
      await budgetFunctions.createBudget(data);
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  updateBudget: async (id, updates) => {
    set({ loading: true, error: null });
    try {
      await budgetFunctions.updateBudget({ budgetId: id, updates });
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  deleteBudget: async (id) => {
    set({ loading: true, error: null });
    try {
      await budgetFunctions.deleteBudget(id);
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  calculateProgress: async (id) => {
    set({ loading: true, error: null });
    try {
      const result = await budgetFunctions.calculateBudgetProgress(id);
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
      set({ unsubscribe: null, budgets: [] });
    }
  },
}));
