import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

// Types
export interface StockData {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
  marketCap?: number;
  volume?: number;
  high: number;
  low: number;
  open: number;
  previousClose: number;
  timestamp: string;
  cached: boolean;
  cacheAge: number;
}

export interface StockHistoryPoint {
  date: string;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export interface StockHistory {
  symbol: string;
  interval: 'daily' | 'weekly' | 'monthly';
  history: StockHistoryPoint[];
  count: number;
}

export interface MutualFundData {
  isin: string;
  name: string;
  nav: number;
  change: number;
  changePercent: number;
  aum?: number;
  expenseRatio?: number;
  category?: string;
  riskLevel?: string;
  returns?: {
    oneYear?: number;
    threeYear?: number;
    fiveYear?: number;
  };
  timestamp: string;
  cached: boolean;
  cacheAge: number;
}

export interface Holding {
  accountId: string;
  accountName: string;
  symbol: string;
  name: string;
  type: 'stock' | 'mutual_fund' | 'etf' | 'bond' | 'other';
  quantity: number;
  purchasePrice: number;
  currentPrice: number;
  currentValue: number;
  costBasis: number;
  gainLoss: number;
  gainLossPercent: number;
}

export interface InvestmentsSummary {
  summary: {
    totalAccounts: number;
    totalHoldings: number;
    totalValue: number;
    totalCostBasis: number;
    totalGainLoss: number;
    totalGainLossPercent: number;
  };
  byAssetType: Record<
    string,
    {
      count: number;
      value: number;
      gainLoss: number;
    }
  >;
  holdings: Holding[];
  accounts: Array<{
    id: string;
    name: string;
    type: string;
    balance: number;
  }>;
}

// API Functions

/**
 * Fetch real-time stock data
 */
export async function fetchStockData(
  symbol: string,
  forceRefresh = false
): Promise<StockData> {
  const fetchStockDataFn = httpsCallable<
    { symbol: string; forceRefresh?: boolean },
    StockData
  >(functions, 'fetchStockData');

  const result = await fetchStockDataFn({ symbol, forceRefresh });
  return result.data;
}

/**
 * Fetch historical stock data
 */
export async function fetchStockHistory(
  symbol: string,
  interval: 'daily' | 'weekly' | 'monthly' = 'daily',
  outputSize: 'compact' | 'full' = 'compact'
): Promise<StockHistory> {
  const fetchStockHistoryFn = httpsCallable<
    {
      symbol: string;
      interval?: 'daily' | 'weekly' | 'monthly';
      outputSize?: 'compact' | 'full';
    },
    StockHistory
  >(functions, 'fetchStockHistory');

  const result = await fetchStockHistoryFn({ symbol, interval, outputSize });
  return result.data;
}

/**
 * Fetch mutual fund NAV data
 */
export async function fetchMutualFundData(
  isin: string,
  forceRefresh = false
): Promise<MutualFundData> {
  const fetchMutualFundDataFn = httpsCallable<
    { isin: string; forceRefresh?: boolean },
    MutualFundData
  >(functions, 'fetchMutualFundData');

  const result = await fetchMutualFundDataFn({ isin, forceRefresh });
  return result.data;
}

/**
 * Fetch ETF data (similar to stocks)
 */
export async function fetchETFData(
  symbol: string,
  forceRefresh = false
): Promise<StockData> {
  const fetchETFDataFn = httpsCallable<
    { symbol: string; forceRefresh?: boolean },
    StockData
  >(functions, 'fetchETFData');

  const result = await fetchETFDataFn({ symbol, forceRefresh });
  return result.data;
}

/**
 * Get investments portfolio summary
 */
export async function getInvestmentsSummary(): Promise<InvestmentsSummary> {
  const getInvestmentsSummaryFn = httpsCallable<{}, InvestmentsSummary>(
    functions,
    'getInvestmentsSummary'
  );

  const result = await getInvestmentsSummaryFn({});
  return result.data;
}

/**
 * Clear investment data cache
 */
export async function clearInvestmentCache(
  type: 'all' | 'stocks' | 'mutualfunds' = 'all'
): Promise<{ success: boolean; deletedCount: number; type: string }> {
  const clearInvestmentCacheFn = httpsCallable<
    { type?: 'all' | 'stocks' | 'mutualfunds' },
    { success: boolean; deletedCount: number; type: string }
  >(functions, 'clearInvestmentCache');

  const result = await clearInvestmentCacheFn({ type });
  return result.data;
}

export const investmentsApi = {
  fetchStockData,
  fetchStockHistory,
  fetchMutualFundData,
  fetchETFData,
  getInvestmentsSummary,
  clearInvestmentCache,
};
