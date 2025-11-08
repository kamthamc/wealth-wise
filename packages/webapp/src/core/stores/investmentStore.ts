/**
 * Investment Store
 * Manages investment holdings, transactions, and portfolio performance
 */

import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import type {
  CreateInvestmentHoldingInput,
  CreateInvestmentTransactionInput,
  InvestmentAssetType,
  InvestmentFilters,
  InvestmentHolding,
  InvestmentPerformance,
  InvestmentTransaction,
  PortfolioSummary,
  UpdateInvestmentHoldingInput,
} from '@/core/types';

interface InvestmentState {
  // State
  holdings: InvestmentHolding[];
  transactions: InvestmentTransaction[];
  performance: Map<string, InvestmentPerformance>;
  isLoading: boolean;
  error: string | null;

  // Actions
  fetchHoldings: (accountId?: string) => Promise<void>;
  fetchTransactions: (holdingId?: string) => Promise<void>;
  addHolding: (input: CreateInvestmentHoldingInput) => Promise<void>;
  updateHolding: (input: UpdateInvestmentHoldingInput) => Promise<void>;
  deleteHolding: (id: string) => Promise<void>;
  addTransaction: (input: CreateInvestmentTransactionInput) => Promise<void>;
  updateTransaction: (
    id: string,
    updates: Partial<InvestmentTransaction>
  ) => Promise<void>;
  deleteTransaction: (id: string) => Promise<void>;

  // Price Updates
  updateHoldingPrices: (prices: Record<string, number>) => Promise<void>;

  // Analytics
  calculatePerformance: (holdingId: string) => InvestmentPerformance | null;
  getPortfolioSummary: (accountIds?: string[]) => PortfolioSummary;
  getHoldingsBySymbol: (
    symbol: string,
    accountIds?: string[]
  ) => InvestmentHolding[];
  filterHoldings: (filters: InvestmentFilters) => InvestmentHolding[];

  // Utility
  clearError: () => void;
  reset: () => void;
}

/**
 * Calculate XIRR (Extended Internal Rate of Return)
 * Uses Newton-Raphson method to find IRR
 */
function calculateXIRR(
  cashFlows: { date: Date; amount: number }[],
  guess = 0.1
): number {
  if (cashFlows.length === 0) return 0;

  const PRECISION = 0.000001;
  const MAX_ITERATIONS = 100;
  const firstDate = cashFlows[0]?.date;

  if (!firstDate) return 0;

  let rate = guess;

  for (let i = 0; i < MAX_ITERATIONS; i++) {
    let sum = 0;
    let derivative = 0;

    for (const cf of cashFlows) {
      const years =
        (cf.date.getTime() - firstDate.getTime()) /
        (365.25 * 24 * 60 * 60 * 1000);
      const factor = (1 + rate) ** years;
      sum += cf.amount / factor;
      derivative -= (cf.amount * years) / (factor * (1 + rate));
    }

    const newRate = rate - sum / derivative;

    if (Math.abs(newRate - rate) < PRECISION) {
      return newRate * 100; // Return as percentage
    }

    rate = newRate;
  }

  return 0; // Failed to converge
}

/**
 * Calculate average cost using FIFO method
 */
function calculateAverageCost(transactions: InvestmentTransaction[]): number {
  let totalCost = 0;
  let totalQuantity = 0;

  const buyTransactions = transactions
    .filter((t) => t.transaction_type === 'buy' || t.transaction_type === 'ipo')
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  for (const txn of buyTransactions) {
    totalCost += txn.total_amount + (txn.fees || 0) + (txn.taxes || 0);
    totalQuantity += txn.quantity;
  }

  return totalQuantity > 0 ? totalCost / totalQuantity : 0;
}

export const useInvestmentStore = create<InvestmentState>()(
  devtools(
    (set, get) => ({
      // Initial State
      holdings: [],
      transactions: [],
      performance: new Map(),
      isLoading: false,
      error: null,

      // Fetch Holdings
      fetchHoldings: async (accountId?: string) => {
        set({ isLoading: true, error: null });
        try {
          // TODO: Replace with actual API call
          // Simulated data for now
          const mockHoldings: InvestmentHolding[] = [];

          // Filter by accountId if provided
          console.log('Fetching holdings for account:', accountId);

          set({ holdings: mockHoldings, isLoading: false });
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to fetch holdings',
            isLoading: false,
          });
        }
      },

      // Fetch Transactions
      fetchTransactions: async (holdingId?: string) => {
        set({ isLoading: true, error: null });
        try {
          // TODO: Replace with actual API call
          const mockTransactions: InvestmentTransaction[] = [];

          // Filter by holdingId if provided
          console.log('Fetching transactions for holding:', holdingId);

          set({ transactions: mockTransactions, isLoading: false });
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to fetch transactions',
            isLoading: false,
          });
        }
      },

      // Add Holding
      addHolding: async (input: CreateInvestmentHoldingInput) => {
        set({ isLoading: true, error: null });
        try {
          const newHolding: InvestmentHolding = {
            ...input,
            id: crypto.randomUUID(),
            current_price: input.current_price || input.average_cost,
            created_at: new Date(),
            updated_at: new Date(),
          };

          set((state) => ({
            holdings: [...state.holdings, newHolding],
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error ? error.message : 'Failed to add holding',
            isLoading: false,
          });
        }
      },

      // Update Holding
      updateHolding: async (input: UpdateInvestmentHoldingInput) => {
        set({ isLoading: true, error: null });
        try {
          set((state) => ({
            holdings: state.holdings.map((h) =>
              h.id === input.id ? { ...h, ...input, updated_at: new Date() } : h
            ),
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to update holding',
            isLoading: false,
          });
        }
      },

      // Delete Holding
      deleteHolding: async (id: string) => {
        set({ isLoading: true, error: null });
        try {
          set((state) => ({
            holdings: state.holdings.filter((h) => h.id !== id),
            transactions: state.transactions.filter((t) => t.holding_id !== id),
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to delete holding',
            isLoading: false,
          });
        }
      },

      // Add Transaction
      addTransaction: async (input: CreateInvestmentTransactionInput) => {
        set({ isLoading: true, error: null });
        try {
          const newTransaction: InvestmentTransaction = {
            ...input,
            id: crypto.randomUUID(),
            date: input.date || new Date(),
            created_at: new Date(),
            updated_at: new Date(),
          };

          set((state) => {
            const transactions = [...state.transactions, newTransaction];

            // Recalculate average cost for the holding
            const holdingTransactions = transactions.filter(
              (t) => t.holding_id === input.holding_id
            );
            const newAvgCost = calculateAverageCost(holdingTransactions);

            // Update holding with new average cost and quantity
            const holdings = state.holdings.map((h) => {
              if (h.id === input.holding_id) {
                const quantityChange =
                  input.transaction_type === 'buy' ||
                  input.transaction_type === 'ipo'
                    ? input.quantity
                    : input.transaction_type === 'sell'
                      ? -input.quantity
                      : 0;

                return {
                  ...h,
                  quantity: h.quantity + quantityChange,
                  average_cost: newAvgCost,
                  updated_at: new Date(),
                };
              }
              return h;
            });

            return { transactions, holdings, isLoading: false };
          });
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to add transaction',
            isLoading: false,
          });
        }
      },

      // Update Transaction
      updateTransaction: async (
        id: string,
        updates: Partial<InvestmentTransaction>
      ) => {
        set({ isLoading: true, error: null });
        try {
          set((state) => ({
            transactions: state.transactions.map((t) =>
              t.id === id ? { ...t, ...updates, updated_at: new Date() } : t
            ),
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to update transaction',
            isLoading: false,
          });
        }
      },

      // Delete Transaction
      deleteTransaction: async (id: string) => {
        set({ isLoading: true, error: null });
        try {
          set((state) => ({
            transactions: state.transactions.filter((t) => t.id !== id),
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to delete transaction',
            isLoading: false,
          });
        }
      },

      // Update Holding Prices (batch update from Firebase)
      updateHoldingPrices: async (prices: Record<string, number>) => {
        set((state) => ({
          holdings: state.holdings.map((h) => ({
            ...h,
            current_price: prices[h.symbol] || h.current_price,
            updated_at: new Date(),
          })),
        }));
      },

      // Calculate Performance for a Holding
      calculatePerformance: (
        holdingId: string
      ): InvestmentPerformance | null => {
        const { holdings, transactions } = get();
        const holding = holdings.find((h) => h.id === holdingId);

        if (!holding) return null;

        const holdingTransactions = transactions
          .filter((t) => t.holding_id === holdingId)
          .sort(
            (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()
          );

        let totalInvested = 0;
        let realizedGains = 0;
        let dividendsReceived = 0;

        for (const txn of holdingTransactions) {
          switch (txn.transaction_type) {
            case 'buy':
            case 'ipo':
              totalInvested +=
                txn.total_amount + (txn.fees || 0) + (txn.taxes || 0);
              break;
            case 'sell': {
              const sellProceeds =
                txn.total_amount - (txn.fees || 0) - (txn.taxes || 0);
              const costBasis = txn.quantity * holding.average_cost;
              realizedGains += sellProceeds - costBasis;
              totalInvested -= costBasis;
              break;
            }
            case 'dividend':
              dividendsReceived += txn.total_amount;
              break;
          }
        }

        const currentValue = holding.quantity * holding.current_price;
        const unrealizedGains = currentValue - totalInvested;
        const absoluteReturn =
          realizedGains + unrealizedGains + dividendsReceived;
        const percentageReturn =
          totalInvested > 0 ? (absoluteReturn / totalInvested) * 100 : 0;

        // Calculate XIRR
        const cashFlows = holdingTransactions.map((txn) => ({
          date: new Date(txn.date),
          amount:
            txn.transaction_type === 'buy' || txn.transaction_type === 'ipo'
              ? -txn.total_amount
              : txn.total_amount,
        }));

        // Add current value as final cash flow
        cashFlows.push({
          date: new Date(),
          amount: currentValue,
        });

        const xirr = calculateXIRR(cashFlows);

        const performance: InvestmentPerformance = {
          holding_id: holdingId,
          symbol: holding.symbol,
          total_invested: totalInvested,
          current_value: currentValue,
          absolute_return: absoluteReturn,
          percentage_return: percentageReturn,
          realized_gains: realizedGains,
          unrealized_gains: unrealizedGains,
          dividends_received: dividendsReceived,
          xirr,
        };

        // Cache the performance
        set((state) => {
          const newPerformance = new Map(state.performance);
          newPerformance.set(holdingId, performance);
          return { performance: newPerformance };
        });

        return performance;
      },

      // Get Portfolio Summary
      getPortfolioSummary: (accountIds?: string[]): PortfolioSummary => {
        const { holdings, calculatePerformance } = get();

        const filteredHoldings =
          accountIds && accountIds.length > 0
            ? holdings.filter((h) => accountIds.includes(h.account_id))
            : holdings;

        let totalInvested = 0;
        let currentValue = 0;
        let totalReturn = 0;

        const byAssetType: Record<
          InvestmentAssetType,
          { value: number; percentage: number; count: number }
        > = {
          stock: { value: 0, percentage: 0, count: 0 },
          mutual_fund: { value: 0, percentage: 0, count: 0 },
          etf: { value: 0, percentage: 0, count: 0 },
          commodity: { value: 0, percentage: 0, count: 0 },
          reit: { value: 0, percentage: 0, count: 0 },
          bond: { value: 0, percentage: 0, count: 0 },
          crypto: { value: 0, percentage: 0, count: 0 },
        };

        for (const holding of filteredHoldings) {
          const performance = calculatePerformance(holding.id);
          if (performance) {
            totalInvested += performance.total_invested;
            currentValue += performance.current_value;
            totalReturn += performance.absolute_return;

            byAssetType[holding.asset_type].value += performance.current_value;
            byAssetType[holding.asset_type].count += 1;
          }
        }

        // Calculate percentages
        for (const assetType in byAssetType) {
          byAssetType[assetType as InvestmentAssetType].percentage =
            currentValue > 0
              ? (byAssetType[assetType as InvestmentAssetType].value /
                  currentValue) *
                100
              : 0;
        }

        return {
          total_invested: totalInvested,
          current_value: currentValue,
          total_return: totalReturn,
          return_percentage:
            totalInvested > 0 ? (totalReturn / totalInvested) * 100 : 0,
          day_change: 0, // TODO: Calculate from price history
          day_change_percentage: 0, // TODO: Calculate from price history
          holdings_count: filteredHoldings.length,
          by_asset_type: byAssetType,
        };
      },

      // Get Holdings by Symbol (across accounts)
      getHoldingsBySymbol: (
        symbol: string,
        accountIds?: string[]
      ): InvestmentHolding[] => {
        const { holdings } = get();

        return holdings.filter((h) => {
          const matchesSymbol = h.symbol === symbol;
          const matchesAccount =
            !accountIds ||
            accountIds.length === 0 ||
            accountIds.includes(h.account_id);
          return matchesSymbol && matchesAccount;
        });
      },

      // Filter Holdings
      filterHoldings: (filters: InvestmentFilters): InvestmentHolding[] => {
        const { holdings } = get();

        return holdings.filter((h) => {
          // Filter by account IDs
          if (filters.account_ids && filters.account_ids.length > 0) {
            if (!filters.account_ids.includes(h.account_id)) return false;
          }

          // Filter by asset types
          if (filters.asset_types && filters.asset_types.length > 0) {
            if (!filters.asset_types.includes(h.asset_type)) return false;
          }

          // Filter by symbols
          if (filters.symbols && filters.symbols.length > 0) {
            if (!filters.symbols.includes(h.symbol)) return false;
          }

          // Filter by value range
          const currentValue = h.quantity * h.current_price;
          if (filters.minValue !== undefined && currentValue < filters.minValue)
            return false;
          if (filters.maxValue !== undefined && currentValue > filters.maxValue)
            return false;

          // Filter by search
          if (filters.search) {
            const searchLower = filters.search.toLowerCase();
            const matchesName = h.name.toLowerCase().includes(searchLower);
            const matchesSymbol = h.symbol.toLowerCase().includes(searchLower);
            if (!matchesName && !matchesSymbol) return false;
          }

          return true;
        });
      },

      // Clear Error
      clearError: () => set({ error: null }),

      // Reset Store
      reset: () =>
        set({
          holdings: [],
          transactions: [],
          performance: new Map(),
          isLoading: false,
          error: null,
        }),
    }),
    { name: 'InvestmentStore' }
  )
);
