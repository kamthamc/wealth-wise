import { create } from 'zustand';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';
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
  
  // Fetch operations
  fetchHoldings: () => Promise<void>;
  fetchTransactions: (accountId?: string, holdingId?: string) => Promise<void>;
  
  // Holding CRUD
  addHolding: (accountId: string, holding: any) => Promise<void>;
  updateHolding: (accountId: string, holdingId: string, updates: any) => Promise<void>;
  deleteHolding: (accountId: string, holdingId: string) => Promise<void>;
  
  // Transaction CRUD
  addTransaction: (transaction: any) => Promise<void>;
  updateTransaction: (transactionId: string, updates: any) => Promise<void>;
  deleteTransaction: (transactionId: string) => Promise<void>;
  
  // Calculations (placeholder for now)
  calculatePerformance: (holdingId: string) => InvestmentPerformance;
  getPortfolioSummary: (accountIds?: string[]) => PortfolioSummary;
  
  // Utility
  initialize: () => void;
  cleanup: () => void;
}

export const useInvestmentStore = create<InvestmentState>((set, get) => ({
  holdings: [],
  transactions: [],
  loading: false,
  error: null,

  /**
   * Fetch all holdings from investment accounts
   */
  fetchHoldings: async () => {
    set({ loading: true, error: null });
    try {
      const getHoldingsFn = httpsCallable<
        void,
        { success: boolean; holdings: InvestmentHolding[] }
      >(functions, 'getHoldings');

      const result = await getHoldingsFn();
      set({ holdings: result.data.holdings, loading: false });
    } catch (error: any) {
      console.error('Error fetching holdings:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Fetch investment transactions
   */
  fetchTransactions: async (accountId?: string, holdingId?: string) => {
    set({ loading: true, error: null });
    try {
      const getTransactionsFn = httpsCallable<
        { accountId?: string; holdingId?: string },
        { success: boolean; transactions: InvestmentTransaction[] }
      >(functions, 'getInvestmentTransactions');

      const result = await getTransactionsFn({ accountId, holdingId });
      set({ transactions: result.data.transactions, loading: false });
    } catch (error: any) {
      console.error('Error fetching investment transactions:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Add a new holding to an investment account
   */
  addHolding: async (accountId: string, holding: any) => {
    set({ loading: true, error: null });
    try {
      const addHoldingFn = httpsCallable<
        { accountId: string; holding: any },
        { success: boolean; holdingId: string; message: string }
      >(functions, 'addHolding');

      await addHoldingFn({ accountId, holding });
      
      // Refresh holdings
      await get().fetchHoldings();
      set({ loading: false });
    } catch (error: any) {
      console.error('Error adding holding:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Update an existing holding
   */
  updateHolding: async (accountId: string, holdingId: string, updates: any) => {
    set({ loading: true, error: null });
    try {
      const updateHoldingFn = httpsCallable<
        { accountId: string; holdingId: string; updates: any },
        { success: boolean; message: string }
      >(functions, 'updateHolding');

      await updateHoldingFn({ accountId, holdingId, updates });
      
      // Refresh holdings
      await get().fetchHoldings();
      set({ loading: false });
    } catch (error: any) {
      console.error('Error updating holding:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Delete a holding from an investment account
   */
  deleteHolding: async (accountId: string, holdingId: string) => {
    set({ loading: true, error: null });
    try {
      const deleteHoldingFn = httpsCallable<
        { accountId: string; holdingId: string },
        { success: boolean; message: string }
      >(functions, 'deleteHolding');

      await deleteHoldingFn({ accountId, holdingId });
      
      // Refresh holdings
      await get().fetchHoldings();
      set({ loading: false });
    } catch (error: any) {
      console.error('Error deleting holding:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Add investment transaction (buy, sell, dividend, etc.)
   */
  addTransaction: async (transaction: any) => {
    set({ loading: true, error: null });
    try {
      const addTransactionFn = httpsCallable<
        { transaction: any },
        { success: boolean; transactionId: string; message: string }
      >(functions, 'addInvestmentTransaction');

      await addTransactionFn({ transaction });
      
      // Refresh transactions
      await get().fetchTransactions();
      set({ loading: false });
    } catch (error: any) {
      console.error('Error adding investment transaction:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Update investment transaction
   */
  updateTransaction: async (transactionId: string, updates: any) => {
    set({ loading: true, error: null });
    try {
      const updateTransactionFn = httpsCallable<
        { transactionId: string; updates: any },
        { success: boolean; message: string }
      >(functions, 'updateInvestmentTransaction');

      await updateTransactionFn({ transactionId, updates });
      
      // Refresh transactions
      await get().fetchTransactions();
      set({ loading: false });
    } catch (error: any) {
      console.error('Error updating investment transaction:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Delete investment transaction
   */
  deleteTransaction: async (transactionId: string) => {
    set({ loading: true, error: null });
    try {
      const deleteTransactionFn = httpsCallable<
        { transactionId: string },
        { success: boolean; message: string }
      >(functions, 'deleteInvestmentTransaction');

      await deleteTransactionFn({ transactionId });
      
      // Refresh transactions
      await get().fetchTransactions();
      set({ loading: false });
    } catch (error: any) {
      console.error('Error deleting investment transaction:', error);
      set({ error: error.message, loading: false });
      throw error;
    }
  },

  /**
   * Calculate performance for a specific holding
   * TODO: Implement proper XIRR and performance calculations
   */
  calculatePerformance: (holdingId: string): InvestmentPerformance => {
    const { holdings } = get();
    const holding = holdings.find((h) => h.id === holdingId);

    if (!holding) {
      return {
        total_invested: 0,
        current_value: 0,
        total_return: 0,
        roi_percentage: 0,
        xirr: 0,
        dividends_received: 0,
        capital_gains: 0,
        unrealized_gains: 0,
      };
    }

    // Basic calculation placeholder
    const invested = (holding as any).invested || 0;
    const currentValue = (holding as any).currentValue || 0;
    const totalReturn = currentValue - invested;
    const roiPercentage = invested > 0 ? (totalReturn / invested) * 100 : 0;

    return {
      total_invested: invested,
      current_value: currentValue,
      total_return: totalReturn,
      roi_percentage: roiPercentage,
      xirr: 0, // TODO: Implement XIRR calculation
      dividends_received: 0,
      capital_gains: 0,
      unrealized_gains: totalReturn,
    };
  },

  /**
   * Get portfolio summary across selected accounts
   * TODO: Enhance with proper aggregation
   */
  getPortfolioSummary: (accountIds?: string[]): PortfolioSummary => {
    const { holdings } = get();
    let filteredHoldings = holdings;

    if (accountIds && accountIds.length > 0) {
      filteredHoldings = holdings.filter((h) =>
        accountIds.includes((h as any).accountId),
      );
    }

    const totalInvested = filteredHoldings.reduce(
      (sum, h) => sum + ((h as any).invested || 0),
      0,
    );
    const currentValue = filteredHoldings.reduce(
      (sum, h) => sum + ((h as any).currentValue || 0),
      0,
    );
    const totalReturn = currentValue - totalInvested;
    const roiPercentage = totalInvested > 0 ? (totalReturn / totalInvested) * 100 : 0;

    // Group by asset type
    const byAssetType: Record<string, { value: number; percentage: number; count: number }> = {};
    filteredHoldings.forEach((h: any) => {
      const type = h.accountType || 'other';
      if (!byAssetType[type]) {
        byAssetType[type] = { value: 0, percentage: 0, count: 0 };
      }
      byAssetType[type].value += h.currentValue || 0;
      byAssetType[type].count++;
    });

    // Calculate percentages
    Object.keys(byAssetType).forEach((type) => {
      const assetTypeData = byAssetType[type];
      if (assetTypeData) {
        assetTypeData.percentage =
          currentValue > 0 ? (assetTypeData.value / currentValue) * 100 : 0;
      }
    });

    return {
      total_invested: totalInvested,
      total_return: totalReturn,
      roi_percentage: roiPercentage,
      by_asset_type: byAssetType,
    };
  },

  /**
   * Initialize store (fetch initial data)
   */
  initialize: () => {
    get().fetchHoldings();
  },

  /**
   * Cleanup store
   */
  cleanup: () => {
    set({ holdings: [], transactions: [], loading: false, error: null });
  },
}));
