/**
 * Analytics API Client
 * Firebase Cloud Functions for financial analytics
 */

import { httpsCallable } from 'firebase/functions';
import type {
  NetWorthRequest,
  NetWorthResponse,
  PortfolioSummaryRequest,
  PortfolioSummaryResponse,
  TransactionAnalyticsRequest,
  TransactionAnalyticsResponse,
  CashFlowRequest,
  CashFlowResponse,
  DashboardRequest,
  DashboardResponse,
} from '@svc/wealth-wise-shared-types';
import { functions } from '../firebase/firebase';

/**
 * Analytics Cloud Functions API
 */
export const analyticsApi = {
  /**
   * Calculate Net Worth
   * Returns comprehensive net worth analysis including breakdown by account type
   */
  calculateNetWorth: async (request?: NetWorthRequest): Promise<NetWorthResponse> => {
    const callable = httpsCallable<NetWorthRequest, NetWorthResponse>(
      functions,
      'calculateNetWorth'
    );
    const result = await callable(request || {});
    return result.data;
  },

  /**
   * Get Portfolio Summary
   * Returns investment portfolio performance and holdings
   */
  getPortfolioSummary: async (
    request?: PortfolioSummaryRequest
  ): Promise<PortfolioSummaryResponse> => {
    const callable = httpsCallable<PortfolioSummaryRequest, PortfolioSummaryResponse>(
      functions,
      'getPortfolioSummary'
    );
    const result = await callable(request || {});
    return result.data;
  },

  /**
   * Get Transaction Analytics
   * Provides detailed transaction analysis with category breakdowns and trends
   */
  getTransactionAnalytics: async (
    request: TransactionAnalyticsRequest
  ): Promise<TransactionAnalyticsResponse> => {
    const callable = httpsCallable<
      TransactionAnalyticsRequest,
      TransactionAnalyticsResponse
    >(functions, 'getTransactionAnalytics');
    const result = await callable(request);
    return result.data;
  },

  /**
   * Get Cash Flow Analysis
   * Analyzes cash flow over time periods
   */
  getCashFlow: async (request: CashFlowRequest): Promise<CashFlowResponse> => {
    const callable = httpsCallable<CashFlowRequest, CashFlowResponse>(
      functions,
      'getCashFlow'
    );
    const result = await callable(request);
    return result.data;
  },

  /**
   * Get Dashboard Data
   * Returns comprehensive dashboard with net worth, transactions, budgets, goals
   */
  getDashboard: async (request?: DashboardRequest): Promise<DashboardResponse> => {
    const callable = httpsCallable<DashboardRequest, DashboardResponse>(
      functions,
      'getDashboard'
    );
    const result = await callable(request || {});
    return result.data;
  },
};

/**
 * Convenience hooks for React components
 */
export const useNetWorth = () => {
  return analyticsApi.calculateNetWorth;
};

export const usePortfolioSummary = () => {
  return analyticsApi.getPortfolioSummary;
};

export const useTransactionAnalytics = () => {
  return analyticsApi.getTransactionAnalytics;
};

export const useCashFlow = () => {
  return analyticsApi.getCashFlow;
};

export const useDashboard = () => {
  return analyticsApi.getDashboard;
};
