import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();

interface StockData {
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
}

interface MutualFundData {
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
}

/**
 * Fetch stock data from Yahoo Finance or alternative provider
 * Uses caching to reduce API calls
 */
export const fetchStockData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const { symbol, forceRefresh = false } = request.data as {
    symbol: string;
    forceRefresh?: boolean;
  };

  if (!symbol) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Stock symbol is required',
    );
  }

  try {
    // Check cache first (5 minute TTL for stock data)
    if (!forceRefresh) {
      const cacheDoc = await db.collection('stock_cache').doc(symbol).get();
      if (cacheDoc.exists) {
        const cache = cacheDoc.data();
        const cacheAge = cache?.cached_at?.toMillis
          ? Date.now() - cache.cached_at.toMillis()
          : 0;

        if (cacheAge && cacheAge < 5 * 60 * 1000 && cache?.data) {
          // 5 minutes
          return {
            ...cache.data,
            cached: true,
            cacheAge: Math.round(cacheAge / 1000),
          };
        }
      }
    }

    // Fetch from API - Using Alpha Vantage as example
    // Note: In production, use environment variable for API key
    const apiKey = functions.config().alphavantage?.apikey || 'demo';
    const url = `https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=${symbol}&apikey=${apiKey}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data['Error Message'] || data['Note']) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'API rate limit or invalid symbol',
      );
    }

    const quote = data['Global Quote'];
    if (!quote || !quote['05. price']) {
      throw new functions.https.HttpsError('not-found', 'Stock data not found');
    }

    const stockData: StockData = {
      symbol: quote['01. symbol'],
      name: symbol, // API doesn't provide name in this endpoint
      price: parseFloat(quote['05. price']),
      change: parseFloat(quote['09. change']),
      changePercent: parseFloat(quote['10. change percent'].replace('%', '')),
      high: parseFloat(quote['03. high']),
      low: parseFloat(quote['04. low']),
      open: parseFloat(quote['02. open']),
      previousClose: parseFloat(quote['08. previous close']),
      volume: parseInt(quote['06. volume']),
      timestamp: quote['07. latest trading day'],
    };

    // Cache the result
    await db.collection('stock_cache').doc(symbol).set({
      data: stockData,
      cached_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ...stockData,
      cached: false,
      cacheAge: 0,
    };
  } catch (error: any) {
    console.error('Error fetching stock data:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch stock data',
      error.message,
    );
  }
});

/**
 * Fetch historical stock data
 */
export const fetchStockHistory = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const {
    symbol,
    interval = 'daily',
    outputSize = 'compact',
  } = request.data as {
    symbol: string;
    interval?: 'daily' | 'weekly' | 'monthly';
    outputSize?: 'compact' | 'full'; // compact = last 100 data points, full = 20+ years
  };

  if (!symbol) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Stock symbol is required',
    );
  }

  try {
    const apiKey = functions.config().alphavantage?.apikey || 'demo';
    let functionName = 'TIME_SERIES_DAILY';

    switch (interval) {
      case 'weekly':
        functionName = 'TIME_SERIES_WEEKLY';
        break;
      case 'monthly':
        functionName = 'TIME_SERIES_MONTHLY';
        break;
    }

    const url = `https://www.alphavantage.co/query?function=${functionName}&symbol=${symbol}&outputsize=${outputSize}&apikey=${apiKey}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data['Error Message'] || data['Note']) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'API rate limit or invalid symbol',
      );
    }

    const timeSeriesKey = Object.keys(data).find((key) =>
      key.includes('Time Series'),
    );
    if (!timeSeriesKey || !data[timeSeriesKey]) {
      throw new functions.https.HttpsError(
        'not-found',
        'Historical data not found',
      );
    }

    const timeSeries = data[timeSeriesKey];
    const history = Object.entries(timeSeries).map(
      ([date, values]: [string, any]) => ({
        date,
        open: parseFloat(values['1. open']),
        high: parseFloat(values['2. high']),
        low: parseFloat(values['3. low']),
        close: parseFloat(values['4. close']),
        volume: parseInt(values['5. volume']),
      }),
    );

    return {
      symbol,
      interval,
      history,
      count: history.length,
    };
  } catch (error: any) {
    console.error('Error fetching stock history:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch stock history',
      error.message,
    );
  }
});

/**
 * Fetch mutual fund NAV data
 * Uses Indian mutual fund API (mfapi.in) for Indian funds
 */
export const fetchMutualFundData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const { isin, forceRefresh = false } = request.data as {
    isin: string; // scheme code for Indian MFs
    forceRefresh?: boolean;
  };

  if (!isin) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'ISIN or scheme code is required',
    );
  }

  try {
    // Check cache (daily update for mutual funds)
    if (!forceRefresh) {
      const cacheDoc = await db.collection('mutualfund_cache').doc(isin).get();
      if (cacheDoc.exists) {
        const cache = cacheDoc.data();
        const cacheAge = cache?.cached_at?.toMillis
          ? Date.now() - cache.cached_at.toMillis()
          : 0;

        if (cacheAge && cacheAge < 24 * 60 * 60 * 1000 && cache?.data) {
          // 24 hours
          return {
            ...cache.data,
            cached: true,
            cacheAge: Math.round(cacheAge / 1000),
          };
        }
      }
    }

    // Fetch from Indian MF API
    const url = `https://api.mfapi.in/mf/${isin}`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'error' || !data.data || data.data.length === 0) {
      throw new functions.https.HttpsError(
        'not-found',
        'Mutual fund data not found',
      );
    }

    const latestNav = data.data[0];
    const previousNav = data.data[1];

    const nav = parseFloat(latestNav.nav);
    const prevNav = previousNav ? parseFloat(previousNav.nav) : nav;
    const change = nav - prevNav;
    const changePercent = prevNav > 0 ? (change / prevNav) * 100 : 0;

    const mutualFundData: MutualFundData = {
      isin: isin,
      name: data.meta?.scheme_name || 'Unknown Fund',
      nav,
      change,
      changePercent,
      category: data.meta?.scheme_category,
      timestamp: latestNav.date,
    };

    // Cache the result
    await db.collection('mutualfund_cache').doc(isin).set({
      data: mutualFundData,
      cached_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ...mutualFundData,
      cached: false,
      cacheAge: 0,
    };
  } catch (error: any) {
    console.error('Error fetching mutual fund data:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch mutual fund data',
      error.message,
    );
  }
});

/**
 * Fetch ETF data (similar to stocks)
 */
export const fetchETFData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const { symbol, forceRefresh = false } = request.data as {
    symbol: string;
    forceRefresh?: boolean;
  };

  if (!symbol) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'ETF symbol is required',
    );
  }

  // ETFs trade like stocks, so we can reuse stock data logic
  try {
    // Check cache first
    if (!forceRefresh) {
      const cacheDoc = await db.collection('stock_cache').doc(symbol).get();
      if (cacheDoc.exists) {
        const cache = cacheDoc.data();
        const cacheAge = cache?.cached_at?.toMillis
          ? Date.now() - cache.cached_at.toMillis()
          : 0;

        if (cacheAge && cacheAge < 5 * 60 * 1000 && cache?.data) {
          return {
            ...cache.data,
            cached: true,
            cacheAge: Math.round(cacheAge / 1000),
          };
        }
      }
    }

    // Fetch from API
    const apiKey = functions.config().alphavantage?.apikey || 'demo';
    const url = `https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=${symbol}&apikey=${apiKey}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data['Error Message'] || data['Note']) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'API rate limit or invalid symbol',
      );
    }

    const quote = data['Global Quote'];
    if (!quote || !quote['05. price']) {
      throw new functions.https.HttpsError('not-found', 'ETF data not found');
    }

    const etfData: StockData = {
      symbol: quote['01. symbol'],
      name: symbol,
      price: parseFloat(quote['05. price']),
      change: parseFloat(quote['09. change']),
      changePercent: parseFloat(quote['10. change percent'].replace('%', '')),
      high: parseFloat(quote['03. high']),
      low: parseFloat(quote['04. low']),
      open: parseFloat(quote['02. open']),
      previousClose: parseFloat(quote['08. previous close']),
      volume: parseInt(quote['06. volume']),
      timestamp: quote['07. latest trading day'],
    };

    // Cache the result
    await db.collection('stock_cache').doc(symbol).set({
      data: etfData,
      cached_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ...etfData,
      cached: false,
      cacheAge: 0,
    };
  } catch (error: any) {
    console.error('Error fetching ETF data:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch ETF data',
      error.message,
    );
  }
});

/**
 * Get investment summary for user's portfolio
 */
export const getInvestmentsSummary = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;

  try {
    // Get investment accounts
    const accountsSnapshot = await db
      .collection('accounts')
      .where('user_id', '==', userId)
      .where('type', 'in', ['investment', 'brokerage', 'mutual_fund'])
      .where('is_active', '==', true)
      .get();

    const investmentAccounts = accountsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Get holdings from metadata or separate collection
    const holdings = [];
    let totalValue = 0;
    let totalGainLoss = 0;

    for (const account of investmentAccounts) {
      const accountData: any = account;

      // If holdings are stored in account metadata
      if (accountData.holdings && Array.isArray(accountData.holdings)) {
        for (const holding of accountData.holdings) {
          const currentValue = holding.quantity * holding.current_price;
          const costBasis = holding.quantity * holding.purchase_price;
          const gainLoss = currentValue - costBasis;
          const gainLossPercent =
            costBasis > 0 ? (gainLoss / costBasis) * 100 : 0;

          holdings.push({
            accountId: accountData.id,
            accountName: accountData.name,
            symbol: holding.symbol,
            name: holding.name,
            type: holding.type, // stock, mutual_fund, etf, etc.
            quantity: holding.quantity,
            purchasePrice: holding.purchase_price,
            currentPrice: holding.current_price,
            currentValue,
            costBasis,
            gainLoss,
            gainLossPercent: Math.round(gainLossPercent * 100) / 100,
          });

          totalValue += currentValue;
          totalGainLoss += gainLoss;
        }
      }
    }

    const totalCostBasis = totalValue - totalGainLoss;
    const totalGainLossPercent =
      totalCostBasis > 0 ? (totalGainLoss / totalCostBasis) * 100 : 0;

    // Group by asset type
    const byAssetType = holdings.reduce((acc: any, holding: any) => {
      const type = holding.type || 'other';
      if (!acc[type]) {
        acc[type] = {
          count: 0,
          value: 0,
          gainLoss: 0,
        };
      }
      acc[type].count++;
      acc[type].value += holding.currentValue;
      acc[type].gainLoss += holding.gainLoss;
      return acc;
    }, {});

    return {
      summary: {
        totalAccounts: investmentAccounts.length,
        totalHoldings: holdings.length,
        totalValue,
        totalCostBasis,
        totalGainLoss,
        totalGainLossPercent: Math.round(totalGainLossPercent * 100) / 100,
      },
      byAssetType,
      holdings: holdings.sort(
        (a: any, b: any) => b.currentValue - a.currentValue,
      ),
      accounts: investmentAccounts.map((acc: any) => ({
        id: acc.id,
        name: acc.name,
        type: acc.type,
        balance: acc.balance,
      })),
    };
  } catch (error: any) {
    console.error('Error getting investments summary:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get investments summary',
      error.message,
    );
  }
});

/**
 * Clear investment data cache
 */
export const clearInvestmentCache = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const { type = 'all' } = request.data as {
    type?: 'all' | 'stocks' | 'mutualfunds';
  };

  try {
    let deletedCount = 0;

    if (type === 'all' || type === 'stocks') {
      const stocksSnapshot = await db.collection('stock_cache').get();
      const batch = db.batch();
      stocksSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
        deletedCount++;
      });
      await batch.commit();
    }

    if (type === 'all' || type === 'mutualfunds') {
      const mfSnapshot = await db.collection('mutualfund_cache').get();
      const batch = db.batch();
      mfSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
        deletedCount++;
      });
      await batch.commit();
    }

    return {
      success: true,
      deletedCount,
      type,
    };
  } catch (error: any) {
    console.error('Error clearing investment cache:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to clear cache',
      error.message,
    );
  }
});
