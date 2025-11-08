import { create } from 'zustand';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';
import type { DepositDetails } from '@/core/types';

interface InterestPayment {
  id: string;
  account_id: string;
  amount: number;
  date: string;
  description: string;
  type: string;
  category: string;
  created_at: string;
}

interface DepositState {
  deposits: DepositDetails[];
  interestPayments: InterestPayment[];
  loading: boolean;
  isLoading: boolean;
  error: string | null;
  
  // Fetch operations
  initialize: () => void;
  fetchDeposits: () => Promise<void>;
  fetchInterestPayments: (depositId: string) => Promise<void>;
  
  // Interest payments
  recordInterestPayment: (input: {
    accountId: string;
    amount: number;
    date: string;
    description?: string;
  }) => Promise<void>;
  
  // Calculations (use Cloud Functions directly)
  calculateInterest: (calculation: any) => any;
  
  // Deposit CRUD - these should use account operations
  // Adding stub methods for compatibility
  addDeposit: (input: any) => Promise<void>;
  updateDeposit: (input: any) => Promise<void>;
  deleteDeposit: (id: string) => Promise<void>;
  updateDepositProgress: (depositId: string) => Promise<void>;
  
  // Utility
  clearError: () => void;
  reset: () => void;
}

export const useDepositStore = create<DepositState>((set, get) => ({
  deposits: [],
  interestPayments: [],
  loading: false,
  isLoading: false,
  error: null,

  /**
   * Initialize store by fetching deposits
   */
  initialize: () => {
    get().fetchDeposits();
  },

  /**
   * Fetch all deposit accounts
   */
  fetchDeposits: async () => {
    set({ loading: true, isLoading: true, error: null });
    try {
      const getDepositsFn = httpsCallable<
        void,
        { success: boolean; deposits: DepositDetails[] }
      >(functions, 'getDeposits');

      const result = await getDepositsFn();
      set({ deposits: result.data.deposits, loading: false, isLoading: false });
    } catch (error: any) {
      console.error('Error fetching deposits:', error);
      set({ error: error.message, loading: false, isLoading: false });
      throw error;
    }
  },

  /**
   * Fetch interest payment transactions for a deposit
   */
  fetchInterestPayments: async (depositId: string) => {
    set({ loading: true, isLoading: true, error: null });
    try {
      const getPaymentsFn = httpsCallable<
        { accountId: string },
        { success: boolean; payments: InterestPayment[]; total: number }
      >(functions, 'getInterestPayments');

      const result = await getPaymentsFn({ accountId: depositId });
      set({
        interestPayments: result.data.payments,
        loading: false,
        isLoading: false,
      });
    } catch (error: any) {
      console.error('Error fetching interest payments:', error);
      set({ error: error.message, loading: false, isLoading: false });
      throw error;
    }
  },

  /**
   * Record an interest payment for a deposit
   */
  recordInterestPayment: async (input: {
    accountId: string;
    amount: number;
    date: string;
    description?: string;
  }) => {
    set({ loading: true, isLoading: true, error: null });
    try {
      const recordPaymentFn = httpsCallable<
        {
          accountId: string;
          amount: number;
          date: string;
          description?: string;
        },
        {
          success: boolean;
          transactionId: string;
          newBalance: number;
          message: string;
        }
      >(functions, 'recordInterestPayment');

      await recordPaymentFn(input);

      // Refresh deposits and interest payments
      await get().fetchDeposits();
      await get().fetchInterestPayments(input.accountId);

      set({ loading: false, isLoading: false });
    } catch (error: any) {
      console.error('Error recording interest payment:', error);
      set({ error: error.message, loading: false, isLoading: false });
      throw error;
    }
  },

  /**
   * Update deposit progress (recalculate based on current date)
   * This is a placeholder - actual calculations happen in Cloud Functions
   */
  updateDepositProgress: async (depositId: string) => {
    // Progress is calculated on-the-fly by getDepositAccountDetails
    // This method exists for compatibility but doesn't need implementation
    console.log('Deposit progress updated for:', depositId);
  },

  /**
   * Calculate interest for a deposit
   * This is a placeholder - use Cloud Functions directly for calculations
   */
  calculateInterest: (calculation: any) => {
    // Calculations should be done via Cloud Functions:
    // - calculateFDMaturity
    // - calculateRDMaturity
    // - calculatePPFMaturity
    // - calculateSavingsInterest
    console.warn(
      'Use Cloud Functions directly for interest calculations:',
      calculation,
    );
    return {
      principal: 0,
      maturity_amount: 0,
      total_interest: 0,
      effective_rate: 0,
      interest_breakdown: [],
    };
  },

  /**
   * Add deposit - Should use createAccount Cloud Function with deposit_info
   */
  addDeposit: async (_input: any) => {
    console.warn(
      'To create a deposit, use createAccount Cloud Function with type fixed_deposit/recurring_deposit/ppf and include deposit_info',
    );
    throw new Error(
      'Use createAccount function with deposit_info for creating deposits',
    );
  },

  /**
   * Update deposit - Should use updateAccount Cloud Function
   */
  updateDeposit: async (_input: any) => {
    console.warn(
      'To update a deposit, use updateAccount Cloud Function to modify deposit_info',
    );
    throw new Error(
      'Use updateAccount function to modify deposit information',
    );
  },

  /**
   * Delete deposit - Should use deleteAccount Cloud Function
   */
  deleteDeposit: async (_id: string) => {
    console.warn('To delete a deposit, use deleteAccount Cloud Function');
    throw new Error('Use deleteAccount function to remove deposits');
  },

  /**
   * Clear error state
   */
  clearError: () => {
    set({ error: null });
  },

  /**
   * Reset store to initial state
   */
  reset: () => {
    set({
      deposits: [],
      interestPayments: [],
      loading: false,
      isLoading: false,
      error: null,
    });
  },
}));
