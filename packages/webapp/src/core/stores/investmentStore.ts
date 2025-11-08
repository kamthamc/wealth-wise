import { create } from 'zustand';
import type { InvestmentHolding, InvestmentTransaction } from '@/core/types';

interface InvestmentPerformance {
  total_invested: number;
  current_value: number;
  total_return: number;
  roi_percentage: number;
  xirr: number;
  dividends_received: number;
  capital_gains: number;
  unrealized_gains: number;
}

interface PortfolioSummary {
  total_invested: number;
  total_return: number;
  roi_percentage: number;
  by_asset_type: Record<string, { value: number; percentage: number; count: number }>;
}

interface InvestmentState {
  holdings: InvestmentHolding[];
  transactions: InvestmentTransaction[];
  loading: boolean;
  error: string | null;
  initialize: () => void;
  addHolding: (input: any) => Promise<void>;
  updateHolding: (input: any) => Promise<void>;
  deleteHolding: (id: string) => Promise<void>;
  addTransaction: (input: any) => Promise<void>;
  updateTransaction: (id: string, updates: any) => Promise<void>;
  deleteTransaction: (id: string) => Promise<void>;
  calculatePerformance: (holdingId: string) => InvestmentPerformance;
  getPortfolioSummary: (accountIds?: string[]) => PortfolioSummary;
  cleanup: () => void;
}

export const useInvestmentStore = create<InvestmentState>(() => ({
  holdings: [],
  transactions: [],
  loading: false,
  error: null,
  initialize: () => console.warn('Not implemented'),
  addHolding: async () => { throw new Error('Not implemented'); },
  updateHolding: async () => { throw new Error('Not implemented'); },
  deleteHolding: async () => { throw new Error('Not implemented'); },
  addTransaction: async () => { throw new Error('Not implemented'); },
  updateTransaction: async () => { throw new Error('Not implemented'); },
  deleteTransaction: async () => { throw new Error('Not implemented'); },
  calculatePerformance: (): InvestmentPerformance => ({
    total_invested: 0,
    current_value: 0,
    total_return: 0,
    roi_percentage: 0,
    xirr: 0,
    dividends_received: 0,
    capital_gains: 0,
    unrealized_gains: 0,
  }),
  getPortfolioSummary: (): PortfolioSummary => ({
    total_invested: 0,
    total_return: 0,
    roi_percentage: 0,
    by_asset_type: {},
  }),
  cleanup: () => console.warn('Not implemented'),
}));
