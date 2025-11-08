import { create } from 'zustand';
import type { DepositDetails } from '@/core/types';

interface DepositState {
  deposits: DepositDetails[];
  interestPayments: any[];
  loading: boolean;
  isLoading: boolean;
  error: string | null;
  initialize: () => void;
  fetchDeposits: () => Promise<void>;
  fetchInterestPayments: (depositId: string) => Promise<void>;
  updateDepositProgress: (depositId: string) => Promise<void>;
  addDeposit: (input: any) => Promise<void>;
  updateDeposit: (input: any) => Promise<void>;
  deleteDeposit: (id: string) => Promise<void>;
  recordInterestPayment: (input: any) => Promise<void>;
  calculateInterest: (calculation: any) => any;
  clearError: () => void;
  reset: () => void;
}

export const useDepositStore = create<DepositState>(() => ({
  deposits: [],
  interestPayments: [],
  loading: false,
  isLoading: false,
  error: null,
  initialize: () => console.warn('DepositStore not implemented'),
  fetchDeposits: async () => { console.warn('fetchDeposits not implemented'); },
  fetchInterestPayments: async () => { console.warn('fetchInterestPayments not implemented'); },
  updateDepositProgress: async () => { console.warn('updateDepositProgress not implemented'); },
  addDeposit: async () => { throw new Error('Not implemented'); },
  updateDeposit: async () => { throw new Error('Not implemented'); },
  deleteDeposit: async () => { throw new Error('Not implemented'); },
  recordInterestPayment: async () => { throw new Error('Not implemented'); },
  calculateInterest: () => ({ principal: 0, maturity_amount: 0, total_interest: 0, effective_rate: 0, interest_breakdown: [] }),
  clearError: () => {},
  reset: () => {},
}));
