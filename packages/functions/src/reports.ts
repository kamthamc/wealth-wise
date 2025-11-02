import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { fetchUserPreferences } from './preferences';

const db = admin.firestore();

/**
 * Generate financial reports for a user
 */
export const generateReport = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { startDate, endDate, reportType } = request.data as {
    startDate: string;
    endDate: string;
    reportType:
      | 'income-expense'
      | 'category-breakdown'
      | 'monthly-trend'
      | 'account-summary';
  };

  if (!startDate || !endDate) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Start and end dates are required',
    );
  }

  try {
    const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
    const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

    // Get transactions for the period
    const transactionsSnapshot = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .where('date', '>=', start)
      .where('date', '<=', end)
      .orderBy('date', 'desc')
      .get();

    const transactions = transactionsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    let reportData: any = {};

    switch (reportType) {
      case 'income-expense':
        reportData = generateIncomeExpenseReport(transactions);
        break;
      case 'category-breakdown':
        reportData = generateCategoryBreakdownReport(transactions);
        break;
      case 'monthly-trend':
        reportData = generateMonthlyTrendReport(transactions);
        break;
      case 'account-summary': {
        const accountsSnapshot = await db
          .collection('accounts')
          .where('user_id', '==', userId)
          .where('is_active', '==', true)
          .get();
        reportData = generateAccountSummaryReport(
          accountsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
          transactions,
        );
        break;
      }
      default:
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid report type',
        );
    }

    // Fetch user preferences for formatting
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;
    const dateFormat = userPreferences.dateFormat;
    const locale = userPreferences.locale;

    return {
      success: true,
      report: {
        type: reportType,
        startDate: startDate,
        endDate: endDate,
        generatedAt: admin.firestore.Timestamp.now(),
        data: reportData,
        currency, // For amount formatting
        dateFormat, // For date formatting
        locale, // For number formatting
      },
    };
  } catch (error) {
    console.error('Error generating report:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate report',
    );
  }
});

function generateIncomeExpenseReport(transactions: any[]) {
  let totalIncome = 0;
  let totalExpense = 0;
  const monthlyData: Record<string, { income: number; expense: number }> = {};

  transactions.forEach((txn) => {
    const amount = txn.amount || 0;
    const date = txn.date.toDate();
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

    if (!monthlyData[monthKey]) {
      monthlyData[monthKey] = { income: 0, expense: 0 };
    }

    if (txn.type === 'income') {
      totalIncome += amount;
      monthlyData[monthKey].income += amount;
    } else if (txn.type === 'expense') {
      totalExpense += amount;
      monthlyData[monthKey].expense += amount;
    }
  });

  return {
    summary: {
      totalIncome,
      totalExpense,
      netSavings: totalIncome - totalExpense,
      savingsRate:
        totalIncome > 0
          ? ((totalIncome - totalExpense) / totalIncome) * 100
          : 0,
    },
    monthlyBreakdown: Object.entries(monthlyData).map(([month, data]) => ({
      month,
      income: data.income,
      expense: data.expense,
      net: data.income - data.expense,
    })),
  };
}

function generateCategoryBreakdownReport(transactions: any[]) {
  const categoryData: Record<
    string,
    { count: number; total: number; percentage: number }
  > = {};
  let totalExpense = 0;

  // Calculate totals
  transactions.forEach((txn) => {
    if (txn.type === 'expense') {
      const category = txn.category || 'Uncategorized';
      const amount = txn.amount || 0;

      if (!categoryData[category]) {
        categoryData[category] = { count: 0, total: 0, percentage: 0 };
      }

      categoryData[category].count++;
      categoryData[category].total += amount;
      totalExpense += amount;
    }
  });

  // Calculate percentages
  Object.keys(categoryData).forEach((category) => {
    categoryData[category].percentage =
      totalExpense > 0
        ? (categoryData[category].total / totalExpense) * 100
        : 0;
  });

  // Sort by total descending
  const sortedCategories = Object.entries(categoryData)
    .map(([category, data]) => ({
      category,
      ...data,
    }))
    .sort((a, b) => b.total - a.total);

  return {
    totalExpense,
    categories: sortedCategories,
    topCategories: sortedCategories.slice(0, 5),
  };
}

function generateMonthlyTrendReport(transactions: any[]) {
  const monthlyTrends: Record<
    string,
    {
      month: string;
      income: number;
      expense: number;
      transactionCount: number;
    }
  > = {};

  transactions.forEach((txn) => {
    const date = txn.date.toDate();
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

    if (!monthlyTrends[monthKey]) {
      monthlyTrends[monthKey] = {
        month: monthKey,
        income: 0,
        expense: 0,
        transactionCount: 0,
      };
    }

    monthlyTrends[monthKey].transactionCount++;

    if (txn.type === 'income') {
      monthlyTrends[monthKey].income += txn.amount || 0;
    } else if (txn.type === 'expense') {
      monthlyTrends[monthKey].expense += txn.amount || 0;
    }
  });

  return {
    trends: Object.values(monthlyTrends).sort((a, b) =>
      a.month.localeCompare(b.month),
    ),
  };
}

function generateAccountSummaryReport(accounts: any[], transactions: any[]) {
  const accountSummaries = accounts.map((account) => {
    const accountTransactions = transactions.filter(
      (txn) => txn.account_id === account.id,
    );

    const income = accountTransactions
      .filter((txn) => txn.type === 'income')
      .reduce((sum: number, txn: any) => sum + (txn.amount || 0), 0);

    const expense = accountTransactions
      .filter((txn) => txn.type === 'expense')
      .reduce((sum: number, txn: any) => sum + (txn.amount || 0), 0);

    return {
      accountId: account.id,
      name: account.name,
      type: account.type,
      currentBalance: account.balance || 0,
      totalIncome: income,
      totalExpense: expense,
      transactionCount: accountTransactions.length,
      netChange: income - expense,
    };
  });

  const totalBalance = accountSummaries.reduce(
    (sum, acc) => sum + acc.currentBalance,
    0,
  );
  const totalIncome = accountSummaries.reduce(
    (sum, acc) => sum + acc.totalIncome,
    0,
  );
  const totalExpense = accountSummaries.reduce(
    (sum, acc) => sum + acc.totalExpense,
    0,
  );

  return {
    accounts: accountSummaries,
    totals: {
      balance: totalBalance,
      income: totalIncome,
      expense: totalExpense,
      netChange: totalIncome - totalExpense,
    },
  };
}

/**
 * Get dashboard analytics
 */
export const getDashboardAnalytics = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;

  try {
    // Get accounts
    const accountsSnapshot = await db
      .collection('accounts')
      .where('user_id', '==', userId)
      .where('is_active', '==', true)
      .get();

    const accounts = accountsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Get recent transactions (last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const transactionsSnapshot = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .where('date', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('date', 'desc')
      .limit(100)
      .get();

    const transactions = transactionsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Calculate analytics
    const totalBalance = accounts.reduce(
      (sum: number, acc: any) => sum + (acc.balance || 0),
      0,
    );

    const monthlyIncome = transactions
      .filter((txn: any) => txn.type === 'income')
      .reduce((sum: number, txn: any) => sum + (txn.amount || 0), 0);

    const monthlyExpense = transactions
      .filter((txn: any) => txn.type === 'expense')
      .reduce((sum: number, txn: any) => sum + (txn.amount || 0), 0);

    // Get active budgets
    const budgetsSnapshot = await db
      .collection('budgets')
      .where('user_id', '==', userId)
      .where('end_date', '>=', admin.firestore.Timestamp.now())
      .get();

    // Fetch user preferences for formatting
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;

    return {
      success: true,
      analytics: {
        totalBalance,
        monthlyIncome,
        monthlyExpense,
        netSavings: monthlyIncome - monthlyExpense,
        savingsRate:
          monthlyIncome > 0
            ? ((monthlyIncome - monthlyExpense) / monthlyIncome) * 100
            : 0,
        accountCount: accounts.length,
        activeBudgetCount: budgetsSnapshot.size,
        recentTransactionCount: transactions.length,
        accountsByType: accounts.reduce((acc: any, account: any) => {
          acc[account.type] = (acc[account.type] || 0) + 1;
          return acc;
        }, {}),
        currency, // Return currency for amount formatting
      },
    };
  } catch (error) {
    console.error('Error getting dashboard analytics:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get dashboard analytics',
    );
  }
});
