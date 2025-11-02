/**
 * Analytics Cloud Functions
 * Provides comprehensive financial analytics and reporting
 */

import * as admin from 'firebase-admin';
import { https } from 'firebase-functions';
import type {
  NetWorthRequest,
  NetWorthResponse,
  AccountBalance,
  NetWorthByType,
  PortfolioSummaryRequest,
  PortfolioSummaryResponse,
  InvestmentHolding,
  PortfolioPerformance,
  TransactionAnalyticsRequest,
  TransactionAnalyticsResponse,
  CategoryBreakdown,
  TimeSeries,
  CashFlowRequest,
  CashFlowResponse,
  CashFlowPeriod,
  DashboardRequest,
  DashboardResponse,
  AccountType,
  Transaction,
} from '@svc/wealth-wise-shared-types';
import { getUserAuthenticated } from './auth';
import { ErrorCodes, HTTP_STATUS_CODES, WWHttpError } from './errors';
import { fetchUserPreferences } from './preferences';

const { onCall } = https;
const db = admin.firestore();

/**
 * Calculate Net Worth
 * Returns comprehensive net worth analysis including breakdown by account type
 */
export const calculateNetWorth = onCall<NetWorthRequest, Promise<NetWorthResponse>>(
  async (request) => {
    const auth = getUserAuthenticated(request.auth);
    const userId = auth.uid;
    const { asOfDate, includeInactive = false } = request.data || {};

    try {
      // Get user preferences for currency
      const userPreferences = await fetchUserPreferences(userId);
      const userCurrency = userPreferences.currency;

      // Build query for accounts
      let accountsQuery = db
        .collection('accounts')
        .where('user_id', '==', userId);

      if (!includeInactive) {
        accountsQuery = accountsQuery.where('is_active', '==', true);
      }

      const accountsSnapshot = await accountsQuery.get();

      if (accountsSnapshot.empty) {
        return {
          totalNetWorth: 0,
          currency: userCurrency,
          asOfDate: asOfDate || new Date().toISOString(),
          totalAssets: 0,
          totalLiabilities: 0,
          accountCount: 0,
          byType: [],
          topAccounts: [],
          lastUpdated: new Date().toISOString(),
        };
      }

      // Process accounts
      const accounts: AccountBalance[] = [];
      const byTypeMap = new Map<AccountType, NetWorthByType>();
      let totalAssets = 0;
      let totalLiabilities = 0;

      for (const doc of accountsSnapshot.docs) {
        const data = doc.data();
        const balance = Number(data.balance) || 0;
        const accountType = data.type as AccountType;

        const accountBalance: AccountBalance = {
          accountId: doc.id,
          accountName: data.name,
          accountType,
          balance,
          currency: data.currency || 'INR',
        };

        accounts.push(accountBalance);

        // Categorize as asset or liability
        const isLiability = accountType === 'credit_card' || 
                           accountType === 'upi' && balance < 0;
        
        if (isLiability) {
          totalLiabilities += Math.abs(balance);
        } else {
          totalAssets += balance;
        }

        // Group by type
        if (!byTypeMap.has(accountType)) {
          byTypeMap.set(accountType, {
            type: accountType,
            totalBalance: 0,
            accountCount: 0,
            accounts: [],
          });
        }

        const typeGroup = byTypeMap.get(accountType)!;
        typeGroup.totalBalance += balance;
        typeGroup.accountCount += 1;
        typeGroup.accounts.push(accountBalance);
      }

      // Calculate net worth
      const totalNetWorth = totalAssets - totalLiabilities;

      // Convert map to array and sort by total balance
      const byType = Array.from(byTypeMap.values())
        .sort((a, b) => Math.abs(b.totalBalance) - Math.abs(a.totalBalance));

      // Get top 5 accounts by absolute balance
      const topAccounts = accounts
        .sort((a, b) => Math.abs(b.balance) - Math.abs(a.balance))
        .slice(0, 5);

      return {
        totalNetWorth,
        currency: userCurrency,
        asOfDate: asOfDate || new Date().toISOString(),
        totalAssets,
        totalLiabilities,
        accountCount: accounts.length,
        byType,
        topAccounts,
        lastUpdated: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error calculating net worth:', error);
      throw new WWHttpError(
        ErrorCodes.INTERNAL_ERROR,
        HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
        'Failed to calculate net worth',
      );
    }
  }
);

/**
 * Get Portfolio Summary
 * Returns investment portfolio performance and holdings
 */
export const getPortfolioSummary = onCall<PortfolioSummaryRequest, Promise<PortfolioSummaryResponse>>(
  async (request) => {
    const auth = getUserAuthenticated(request.auth);
    const userId = auth.uid;
    const { includePerformance = true } = request.data || {};

    try {
      // Get user preferences for currency
      const userPreferences = await fetchUserPreferences(userId);
      const userCurrency = userPreferences.currency;

      // Investment account types
      const investmentTypes: AccountType[] = [
        'brokerage',
        'mutual_fund',
        'stocks',
        'bonds',
        'etf',
        'fixed_deposit',
        'recurring_deposit',
        'ppf',
        'nsc',
        'kvp',
        'scss',
        'nps',
        'apy',
        'epf',
        'vpf',
        'property',
        'reit',
        'invit',
        'gold',
        'silver',
      ];

      const accountsSnapshot = await db
        .collection('accounts')
        .where('user_id', '==', userId)
        .where('is_active', '==', true)
        .get();

      const investmentAccounts = accountsSnapshot.docs
        .filter((doc) => investmentTypes.includes(doc.data().type as AccountType))
        .map((doc) => {
          const data = doc.data();
          return { id: doc.id, ...data };
        });

      const summary = {
        totalInvestments: investmentAccounts.length,
        accountCount: investmentAccounts.length,
        investmentTypes: new Set(investmentAccounts.map((a: any) => a.type)).size,
      };

      let performance: PortfolioPerformance | undefined;

      if (includePerformance && investmentAccounts.length > 0) {
        const holdings: InvestmentHolding[] = [];

        for (const account of investmentAccounts) {
          const accountData = account as any; // Type assertion for Firestore data
          const balance = Number(accountData.balance) || 0;
          
          // Get deposit details if available
          let invested = balance;
          if (accountData.type === 'fixed_deposit' || accountData.type === 'recurring_deposit' || 
              accountData.type === 'ppf' || accountData.type === 'nsc') {
            const depositSnapshot = await db
              .collection('deposit_details')
              .where('account_id', '==', account.id)
              .limit(1)
              .get();
            
            if (!depositSnapshot.empty) {
              const depositData = depositSnapshot.docs[0].data();
              invested = Number(depositData.principal_amount) || balance;
            }
          }

          const returns = balance - invested;
          const returnsPercentage = invested > 0 ? (returns / invested) * 100 : 0;

          holdings.push({
            accountId: account.id,
            accountName: accountData.name,
            accountType: accountData.type as AccountType,
            invested,
            currentValue: balance,
            returns,
            returnsPercentage,
          });
        }

        const totalInvested = holdings.reduce((sum, h) => sum + h.invested, 0);
        const currentValue = holdings.reduce((sum, h) => sum + h.currentValue, 0);
        const totalReturns = currentValue - totalInvested;
        const returnsPercentage = totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0;

        const topPerformers = holdings
          .filter((h) => h.returns > 0)
          .sort((a, b) => b.returnsPercentage - a.returnsPercentage)
          .slice(0, 5);

        const bottomPerformers = holdings
          .filter((h) => h.returns < 0)
          .sort((a, b) => a.returnsPercentage - b.returnsPercentage)
          .slice(0, 5);

        performance = {
          totalInvested,
          currentValue,
          totalReturns,
          returnsPercentage,
          holdings,
          topPerformers,
          bottomPerformers,
        };
      }

      return {
        summary,
        performance,
        currency: userCurrency,
        asOfDate: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error getting portfolio summary:', error);
      throw new WWHttpError(
        ErrorCodes.INTERNAL_ERROR,
        HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
        'Failed to get portfolio summary',
      );
    }
  }
);

/**
 * Get Transaction Analytics
 * Provides detailed transaction analysis with category breakdowns and trends
 */
export const getTransactionAnalytics = onCall<TransactionAnalyticsRequest, Promise<TransactionAnalyticsResponse>>(
  async (request) => {
    const auth = getUserAuthenticated(request.auth);
    const userId = auth.uid;
    const { startDate, endDate, accountIds, categories } = request.data;

    if (!startDate || !endDate) {
      throw new WWHttpError(
        ErrorCodes.VALIDATION_INVALID_FORMAT,
        HTTP_STATUS_CODES.BAD_REQUEST,
        'Start and end dates are required',
      );
    }

    try {
      // Get user preferences for currency and date format
      const userPreferences = await fetchUserPreferences(userId);
      const userCurrency = userPreferences.currency;
      const userDateFormat = userPreferences.dateFormat;
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      let query = db
        .collection('transactions')
        .where('user_id', '==', userId)
        .where('date', '>=', start)
        .where('date', '<=', end);

      if (accountIds && accountIds.length > 0) {
        query = query.where('account_id', 'in', accountIds.slice(0, 10)); // Firestore limit
      }

      const transactionsSnapshot = await query.get();
      const transactions = transactionsSnapshot.docs.map((doc) => doc.data());

      // Calculate summary
      let totalIncome = 0;
      let totalExpense = 0;
      const categoryMap = new Map<string, { income: number; expense: number; count: number }>();

      for (const txn of transactions) {
        const amount = Number(txn.amount) || 0;
        const category = txn.category || 'Uncategorized';
        const type = txn.type as 'income' | 'expense' | 'transfer';

        if (categories && categories.length > 0 && !categories.includes(category)) {
          continue;
        }

        if (type === 'income') {
          totalIncome += amount;
        } else if (type === 'expense') {
          totalExpense += amount;
        }

        if (!categoryMap.has(category)) {
          categoryMap.set(category, { income: 0, expense: 0, count: 0 });
        }

        const catData = categoryMap.get(category)!;
        catData.count += 1;
        if (type === 'income') {
          catData.income += amount;
        } else if (type === 'expense') {
          catData.expense += amount;
        }
      }

      const netIncome = totalIncome - totalExpense;
      const transactionCount = transactions.length;
      const averageTransaction = transactionCount > 0 ? (totalIncome + totalExpense) / transactionCount : 0;

      // Create category breakdowns
      const incomeByCategory: CategoryBreakdown[] = [];
      const expenseByCategory: CategoryBreakdown[] = [];

      for (const [category, data] of categoryMap.entries()) {
        if (data.income > 0) {
          incomeByCategory.push({
            category,
            total: data.income,
            count: data.count,
            percentage: totalIncome > 0 ? (data.income / totalIncome) * 100 : 0,
          });
        }
        if (data.expense > 0) {
          expenseByCategory.push({
            category,
            total: data.expense,
            count: data.count,
            percentage: totalExpense > 0 ? (data.expense / totalExpense) * 100 : 0,
          });
        }
      }

      incomeByCategory.sort((a, b) => b.total - a.total);
      expenseByCategory.sort((a, b) => b.total - a.total);

      // Time series (simplified - monthly)
      const timeSeriesMap = new Map<string, TimeSeries>();
      for (const txn of transactions) {
        const date = new Date((txn.date as admin.firestore.Timestamp).toDate());
        const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        
        if (!timeSeriesMap.has(monthKey)) {
          timeSeriesMap.set(monthKey, {
            date: monthKey,
            income: 0,
            expense: 0,
            net: 0,
            balance: 0,
          });
        }

        const entry = timeSeriesMap.get(monthKey)!;
        const amount = Number(txn.amount) || 0;
        if (txn.type === 'income') {
          entry.income += amount;
        } else if (txn.type === 'expense') {
          entry.expense += amount;
        }
        entry.net = entry.income - entry.expense;
      }

      const timeSeries = Array.from(timeSeriesMap.values()).sort((a, b) => a.date.localeCompare(b.date));

      return {
        summary: {
          totalIncome,
          totalExpense,
          netIncome,
          transactionCount,
          averageTransaction,
        },
        incomeByCategory,
        expenseByCategory,
        timeSeries,
        topExpenseCategories: expenseByCategory.slice(0, 5),
        topIncomeCategories: incomeByCategory.slice(0, 5),
        currency: userCurrency,
        dateFormat: userDateFormat,
      };
    } catch (error) {
      console.error('Error getting transaction analytics:', error);
      throw new WWHttpError(
        ErrorCodes.INTERNAL_ERROR,
        HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
        'Failed to get transaction analytics',
      );
    }
  }
);

/**
 * Get Cash Flow Analysis
 * Analyzes cash flow over time periods
 */
export const getCashFlow = onCall<CashFlowRequest, Promise<CashFlowResponse>>(
  async (request) => {
    const auth = getUserAuthenticated(request.auth);
    const userId = auth.uid;
    const { startDate, endDate, granularity = 'month' } = request.data;

    if (!startDate || !endDate) {
      throw new WWHttpError(
        ErrorCodes.VALIDATION_INVALID_FORMAT,
        HTTP_STATUS_CODES.BAD_REQUEST,
        'Start and end dates are required',
      );
    }

    try {
      // Get user preferences for currency
      const userPreferences = await fetchUserPreferences(userId);
      const userCurrency = userPreferences.currency;
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const transactionsSnapshot = await db
        .collection('transactions')
        .where('user_id', '==', userId)
        .where('date', '>=', start)
        .where('date', '<=', end)
        .orderBy('date', 'asc')
        .get();

      const transactions = transactionsSnapshot.docs.map((doc) => doc.data());

      // Group by period
      const periodMap = new Map<string, CashFlowPeriod>();
      let runningBalance = 0;

      for (const txn of transactions) {
        const date = new Date((txn.date as admin.firestore.Timestamp).toDate());
        let periodKey: string;

        if (granularity === 'month') {
          periodKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        } else if (granularity === 'week') {
          const weekNum = Math.ceil(date.getDate() / 7);
          periodKey = `${date.getFullYear()}-W${weekNum}`;
        } else {
          periodKey = date.toISOString().split('T')[0];
        }

        if (!periodMap.has(periodKey)) {
          periodMap.set(periodKey, {
            period: periodKey,
            income: 0,
            expense: 0,
            netFlow: 0,
            openingBalance: runningBalance,
            closingBalance: runningBalance,
          });
        }

        const period = periodMap.get(periodKey)!;
        const amount = Number(txn.amount) || 0;

        if (txn.type === 'income') {
          period.income += amount;
          runningBalance += amount;
        } else if (txn.type === 'expense') {
          period.expense += amount;
          runningBalance -= amount;
        }

        period.netFlow = period.income - period.expense;
        period.closingBalance = runningBalance;
      }

      const periods = Array.from(periodMap.values());
      const totalIncome = periods.reduce((sum, p) => sum + p.income, 0);
      const totalExpense = periods.reduce((sum, p) => sum + p.expense, 0);
      const positiveMonths = periods.filter((p) => p.netFlow > 0).length;
      const negativeMonths = periods.filter((p) => p.netFlow < 0).length;

      return {
        periods,
        summary: {
          totalIncome,
          totalExpense,
          netCashFlow: totalIncome - totalExpense,
          averageIncome: periods.length > 0 ? totalIncome / periods.length : 0,
          averageExpense: periods.length > 0 ? totalExpense / periods.length : 0,
          positiveMonths,
          negativeMonths,
        },
        currency: userCurrency,
      };
    } catch (error) {
      console.error('Error getting cash flow:', error);
      throw new WWHttpError(
        ErrorCodes.INTERNAL_ERROR,
        HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
        'Failed to get cash flow analysis',
      );
    }
  }
);

/**
 * Get Dashboard Data
 * Returns comprehensive dashboard with net worth, transactions, budgets, goals
 */
export const getDashboard = onCall<DashboardRequest, Promise<DashboardResponse>>(
  async (request) => {
    const auth = getUserAuthenticated(request.auth);
    const userId = auth.uid;
    const { refresh = false } = request.data || {};

    try {
      // Get user preferences for comprehensive dashboard formatting
      const userPreferences = await fetchUserPreferences(userId);
      const userCurrency = userPreferences.currency;

      // Check cache if not forcing refresh
      if (!refresh) {
        const cacheDoc = await db
          .collection('dashboard_cache')
          .doc(userId)
          .get();

        if (cacheDoc.exists) {
          const cached = cacheDoc.data();
          const cacheAge = Date.now() - cached!.timestamp;
          
          // Cache valid for 5 minutes
          if (cacheAge < 5 * 60 * 1000) {
            return {
              ...cached!.data,
              cached: true,
              generatedAt: new Date(cached!.timestamp).toISOString(),
            } as DashboardResponse;
          }
        }
      }

      // Get net worth by calling the calculation directly
      const netWorthResult: NetWorthResponse = await (async () => {
        // Inline net worth calculation for dashboard
        const accountsSnapshot = await db
          .collection('accounts')
          .where('user_id', '==', userId)
          .where('is_active', '==', true)
          .get();

        const accounts: AccountBalance[] = [];
        let totalAssets = 0;
        let totalLiabilities = 0;

        for (const doc of accountsSnapshot.docs) {
          const data = doc.data();
          const balance = Number(data.balance) || 0;
          const accountType = data.type as AccountType;

          accounts.push({
            accountId: doc.id,
            accountName: data.name,
            accountType,
            balance,
            currency: data.currency || 'INR',
          });

          const isLiability = accountType === 'credit_card';
          if (isLiability) {
            totalLiabilities += Math.abs(balance);
          } else {
            totalAssets += balance;
          }
        }

        return {
          totalNetWorth: totalAssets - totalLiabilities,
          currency: userCurrency,
          asOfDate: new Date().toISOString(),
          totalAssets,
          totalLiabilities,
          accountCount: accounts.length,
          byType: [],
          topAccounts: accounts.slice(0, 5),
          lastUpdated: new Date().toISOString(),
        };
      })();

      // Get recent transactions
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const transactionsSnapshot = await db
        .collection('transactions')
        .where('user_id', '==', userId)
        .where('date', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('date', 'desc')
        .limit(10)
        .get();

      const recentTransactions = transactionsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Get budget summary
      const budgetsSnapshot = await db
        .collection('budgets')
        .where('user_id', '==', userId)
        .where('is_active', '==', true)
        .get();

      const budgetSummary = {
        activeBudgets: budgetsSnapshot.size,
        totalSpent: 0,
        budgetsOverLimit: 0,
      };

      // Get goal summary
      const goalsSnapshot = await db
        .collection('goals')
        .where('user_id', '==', userId)
        .where('status', '==', 'active')
        .get();

      const goals = goalsSnapshot.docs.map((doc) => doc.data());
      const completedGoals = goals.filter((g) => g.status === 'completed').length;
      const totalProgress = goals.length > 0
        ? goals.reduce((sum, g) => sum + (Number(g.current_amount) / Number(g.target_amount)), 0) / goals.length * 100
        : 0;

      const goalSummary = {
        activeGoals: goals.length,
        totalProgress,
        goalsCompleted: completedGoals,
      };

      const insights = [];
      
      if (netWorthResult.totalNetWorth < 0) {
        insights.push({
          type: 'warning' as const,
          message: 'Your net worth is negative. Consider reducing expenses or increasing income.',
        });
      }

      if (budgetSummary.budgetsOverLimit > 0) {
        insights.push({
          type: 'warning' as const,
          message: `${budgetSummary.budgetsOverLimit} budget(s) are over limit.`,
          action: 'View Budgets',
        });
      }

      const dashboardData: DashboardResponse = {
        netWorth: netWorthResult,
        recentTransactions: recentTransactions as Transaction[],
        budgetSummary,
        goalSummary,
        insights,
        widgets: [],
        cached: false,
        generatedAt: new Date().toISOString(),
      };

      // Cache the result
      await db.collection('dashboard_cache').doc(userId).set({
        data: dashboardData,
        timestamp: Date.now(),
      });

      return dashboardData;
    } catch (error) {
      console.error('Error getting dashboard:', error);
      throw new WWHttpError(
        ErrorCodes.INTERNAL_ERROR,
        HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
        'Failed to get dashboard data',
      );
    }
  }
);
