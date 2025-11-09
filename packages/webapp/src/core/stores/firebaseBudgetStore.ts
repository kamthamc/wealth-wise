import type { Unsubscribe } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { collection, getFirestore, onSnapshot, query, where } from 'firebase/firestore';
import { create } from 'zustand';
import { budgetFunctions } from '../api';

interface BudgetCategory {
  category: string;
  allocated_amount: number;
  alert_threshold?: number;
  notes?: string;
  // Calculated fields (need to be computed from transactions)
  spent?: number;
  percent_used?: number;
  status?: 'under' | 'near' | 'over';
  variance?: number;
  allocated?: number; // Alias for allocated_amount
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
  is_active: boolean;
  rollover_enabled: boolean;
  categories: BudgetCategory[];
  created_at: any;
  updated_at: any;
  // Calculated fields (need to be computed from transactions)
  total_allocated?: number;
  total_spent?: number;
  overall_percent_used?: number;
  status?: 'under' | 'near' | 'over';
}

interface BudgetState {
  budgets: Budget[];
  loading: boolean;
  isLoading: boolean; // Alias for compatibility
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
  isLoading: false,
  error: null,
  unsubscribe: null,

  initialize: () => {
    const auth = getAuth();
    const userId = auth.currentUser?.uid;
    if (!userId) {
      set({ budgets: [], loading: false });
      return;
    }

    set({ loading: true, error: null });

    // Cleanup previous subscription
    const prevUnsubscribe = get().unsubscribe;
    if (prevUnsubscribe) {
      prevUnsubscribe();
    }

    const db = getFirestore();
    // Subscribe to real-time updates
    const q = query(
      collection(db, 'budgets'),
      where('user_id', '==', userId)
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
