import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { fetchUserPreferences } from './preferences';

const db = admin.firestore();

interface DashboardCache {
  user_id: string;
  data: any;
  computed_at: admin.firestore.Timestamp;
  expires_at: admin.firestore.Timestamp;
}

/**
 * Compute and cache comprehensive dashboard data
 */
export const computeAndCacheDashboard = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const userId = request.auth.uid;
    const { forceRefresh = false, cacheTTL = 300 } = request.data as {
      forceRefresh?: boolean;
      cacheTTL?: number; // seconds
    };

    try {
      // Check cache first
      if (!forceRefresh) {
        const cacheDoc = await db
          .collection('dashboard_cache')
          .doc(userId)
          .get();
        if (cacheDoc.exists) {
          const cache = cacheDoc.data() as DashboardCache;
          const now = admin.firestore.Timestamp.now();

          if (cache.expires_at.toMillis() > now.toMillis()) {
            return {
              ...cache.data,
              cached: true,
              computedAt: cache.computed_at.toDate().toISOString(),
              expiresAt: cache.expires_at.toDate().toISOString(),
            };
          }
        }
      }

      // Compute dashboard data
      const [
        accountsSnapshot,
        transactionsSnapshot,
        budgetsSnapshot,
        goalsSnapshot,
      ] = await Promise.all([
        db
          .collection('accounts')
          .where('user_id', '==', userId)
          .where('is_active', '==', true)
          .get(),
        db
          .collection('transactions')
          .where('user_id', '==', userId)
          .orderBy('date', 'desc')
          .limit(1000)
          .get(),
        db
          .collection('budgets')
          .where('user_id', '==', userId)
          .where('is_active', '==', true)
          .get(),
        db
          .collection('goals')
          .where('user_id', '==', userId)
          .where('status', '==', 'active')
          .get(),
      ]);

      const accounts = accountsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      const transactions = transactionsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      const budgets = budgetsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      const goals = goalsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Calculate total balance
      const totalBalance = accounts.reduce(
        (sum, acc: any) => sum + (acc.balance || 0),
        0,
      );

      // Calculate account type breakdown
      const accountsByType = accounts.reduce((acc: any, account: any) => {
        const type = account.type || 'other';
        if (!acc[type]) {
          acc[type] = { count: 0, balance: 0 };
        }
        acc[type].count++;
        acc[type].balance += account.balance || 0;
        return acc;
      }, {});

      // Calculate income vs expenses (last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const recentTransactions = transactions.filter((txn: any) => {
        const txnDate = txn.date.toDate
          ? txn.date.toDate()
          : new Date(txn.date);
        return txnDate >= thirtyDaysAgo;
      });

      const incomeExpenses = recentTransactions.reduce(
        (acc, txn: any) => {
          if (txn.type === 'income') {
            acc.income += Math.abs(txn.amount);
          } else if (txn.type === 'expense') {
            acc.expenses += Math.abs(txn.amount);
          }
          return acc;
        },
        { income: 0, expenses: 0 },
      );

      // Calculate spending by category (last 30 days)
      const categorySpending = recentTransactions
        .filter((txn: any) => txn.type === 'expense')
        .reduce((acc: any, txn: any) => {
          const category = txn.category || 'Uncategorized';
          if (!acc[category]) {
            acc[category] = 0;
          }
          acc[category] += Math.abs(txn.amount);
          return acc;
        }, {});

      // Calculate budget progress
      const budgetProgress = await Promise.all(
        budgets.map(async (budget: any) => {
          const budgetTransactions = transactions.filter((txn: any) => {
            const txnDate = txn.date.toDate
              ? txn.date.toDate()
              : new Date(txn.date);
            const startDate = budget.start_date.toDate
              ? budget.start_date.toDate()
              : new Date(budget.start_date);
            const endDate = budget.end_date.toDate
              ? budget.end_date.toDate()
              : new Date(budget.end_date);

            return (
              txn.type === 'expense' &&
              txnDate >= startDate &&
              txnDate <= endDate &&
              (budget.category ? txn.category === budget.category : true)
            );
          });

          const spent = budgetTransactions.reduce(
            (sum, txn: any) => sum + Math.abs(txn.amount),
            0,
          );
          const progress =
            budget.amount > 0 ? (spent / budget.amount) * 100 : 0;

          return {
            id: budget.id,
            name: budget.name,
            amount: budget.amount,
            spent,
            remaining: Math.max(0, budget.amount - spent),
            progress: Math.min(100, Math.round(progress * 100) / 100),
            status:
              progress >= 100
                ? 'exceeded'
                : progress >= 80
                  ? 'warning'
                  : 'on_track',
          };
        }),
      );

      // Calculate goal progress
      const goalProgress = await Promise.all(
        goals.map(async (goal: any) => {
          const progress =
            goal.target_amount > 0
              ? (goal.current_amount / goal.target_amount) * 100
              : 0;

          return {
            id: goal.id,
            name: goal.name,
            targetAmount: goal.target_amount,
            currentAmount: goal.current_amount,
            remaining: Math.max(0, goal.target_amount - goal.current_amount),
            progress: Math.min(100, Math.round(progress * 100) / 100),
            status: progress >= 100 ? 'completed' : goal.status,
          };
        }),
      );

      // Calculate monthly trends (last 6 months)
      const monthlyTrends = [];
      for (let i = 5; i >= 0; i--) {
        const monthDate = new Date();
        monthDate.setMonth(monthDate.getMonth() - i);
        const monthStart = new Date(
          monthDate.getFullYear(),
          monthDate.getMonth(),
          1,
        );
        const monthEnd = new Date(
          monthDate.getFullYear(),
          monthDate.getMonth() + 1,
          0,
        );

        const monthTransactions = transactions.filter((txn: any) => {
          const txnDate = txn.date.toDate
            ? txn.date.toDate()
            : new Date(txn.date);
          return txnDate >= monthStart && txnDate <= monthEnd;
        });

        const monthData = monthTransactions.reduce(
          (acc, txn: any) => {
            if (txn.type === 'income') {
              acc.income += Math.abs(txn.amount);
            } else if (txn.type === 'expense') {
              acc.expenses += Math.abs(txn.amount);
            }
            return acc;
          },
          {
            month: monthDate.toISOString().slice(0, 7),
            income: 0,
            expenses: 0,
            net: 0,
          },
        );

        monthData.net = monthData.income - monthData.expenses;
        monthlyTrends.push(monthData);
      }

      // Recent transactions
      const recentTransactionsData = transactions
        .slice(0, 10)
        .map((txn: any) => ({
          id: txn.id,
          date: txn.date.toDate ? txn.date.toDate().toISOString() : txn.date,
          description: txn.description,
          amount: txn.amount,
          type: txn.type,
          category: txn.category,
          account_id: txn.account_id,
        }));

      // Fetch user preferences for formatting
      const userPreferences = await fetchUserPreferences(userId);
      const currency = userPreferences.currency;
      const dateFormat = userPreferences.dateFormat;

      const dashboardData = {
        summary: {
          totalBalance,
          accountsCount: accounts.length,
          activeGoalsCount: goals.length,
          activeBudgetsCount: budgets.length,
          recentIncome: incomeExpenses.income,
          recentExpenses: incomeExpenses.expenses,
          netCashFlow: incomeExpenses.income - incomeExpenses.expenses,
        },
        accountsByType,
        categorySpending,
        budgetProgress,
        goalProgress,
        monthlyTrends,
        recentTransactions: recentTransactionsData,
        currency, // Return currency for formatting
        dateFormat, // Return date format preference
      };

      // Cache the result
      const now = admin.firestore.Timestamp.now();
      const expiresAt = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + cacheTTL * 1000,
      );

      await db.collection('dashboard_cache').doc(userId).set({
        user_id: userId,
        data: dashboardData,
        computed_at: now,
        expires_at: expiresAt,
      });

      return {
        ...dashboardData,
        cached: false,
        computedAt: now.toDate().toISOString(),
        expiresAt: expiresAt.toDate().toISOString(),
      };
    } catch (error: any) {
      console.error('Error computing dashboard:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to compute dashboard',
        error.message,
      );
    }
  },
);

/**
 * Get account summary with transaction statistics
 */
export const getAccountSummary = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { accountId } = request.data as { accountId: string };

  if (!accountId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Account ID is required',
    );
  }

  try {
    const accountDoc = await db.collection('accounts').doc(accountId).get();

    if (!accountDoc.exists || accountDoc.data()?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Account not found or access denied',
      );
    }

    const account = { id: accountDoc.id, ...accountDoc.data() };

    // Get account transactions
    const transactionsSnapshot = await db
      .collection('transactions')
      .where('account_id', '==', accountId)
      .orderBy('date', 'desc')
      .limit(500)
      .get();

    const transactions = transactionsSnapshot.docs.map((doc) => ({
      ...doc.data(),
      date: doc.data().date.toDate(),
    }));

    // Calculate statistics
    const stats = {
      totalTransactions: transactions.length,
      totalIncome: 0,
      totalExpenses: 0,
      averageTransaction: 0,
      largestIncome: 0,
      largestExpense: 0,
      categoryBreakdown: {} as Record<string, number>,
    };

    transactions.forEach((txn: any) => {
      const absAmount = Math.abs(txn.amount);

      if (txn.type === 'income') {
        stats.totalIncome += absAmount;
        stats.largestIncome = Math.max(stats.largestIncome, absAmount);
      } else if (txn.type === 'expense') {
        stats.totalExpenses += absAmount;
        stats.largestExpense = Math.max(stats.largestExpense, absAmount);

        const category = txn.category || 'Uncategorized';
        stats.categoryBreakdown[category] =
          (stats.categoryBreakdown[category] || 0) + absAmount;
      }
    });

    stats.averageTransaction =
      transactions.length > 0
        ? (stats.totalIncome + stats.totalExpenses) / transactions.length
        : 0;

    // Fetch user preferences for formatting
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;

    return {
      account,
      statistics: stats,
      recentTransactions: transactions.slice(0, 20).map((txn: any) => ({
        ...txn,
        date: txn.date.toISOString(),
      })),
      currency, // Return currency for amount formatting
    };
  } catch (error: any) {
    console.error('Error getting account summary:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get account summary',
      error.message,
    );
  }
});

/**
 * Get transaction summary with advanced analytics
 */
export const getTransactionSummary = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const {
    startDate,
    endDate,
    groupBy = 'month',
  } = request.data as {
    startDate?: string;
    endDate?: string;
    groupBy?: 'day' | 'week' | 'month' | 'year';
  };

  try {
    let query = db.collection('transactions').where('user_id', '==', userId);

    if (startDate) {
      query = query.where(
        'date',
        '>=',
        admin.firestore.Timestamp.fromDate(new Date(startDate)),
      );
    }

    if (endDate) {
      query = query.where(
        'date',
        '<=',
        admin.firestore.Timestamp.fromDate(new Date(endDate)),
      );
    }

    const snapshot = await query.orderBy('date', 'desc').get();
    const transactions = snapshot.docs.map((doc) => ({
      ...doc.data(),
      date: doc.data().date.toDate(),
    }));

    // Group transactions
    const grouped: Record<string, any> = {};

    transactions.forEach((txn: any) => {
      let key: string;
      const date = txn.date;

      switch (groupBy) {
        case 'day':
          key = date.toISOString().slice(0, 10);
          break;
        case 'week': {
          const weekStart = new Date(date);
          weekStart.setDate(date.getDate() - date.getDay());
          key = weekStart.toISOString().slice(0, 10);
          break;
        }
        case 'month':
          key = date.toISOString().slice(0, 7);
          break;
        case 'year':
          key = date.getFullYear().toString();
          break;
        default:
          key = date.toISOString().slice(0, 7);
      }

      if (!grouped[key]) {
        grouped[key] = {
          period: key,
          income: 0,
          expenses: 0,
          net: 0,
          transactions: 0,
          categories: {} as Record<string, number>,
        };
      }

      grouped[key].transactions++;
      const absAmount = Math.abs(txn.amount);

      if (txn.type === 'income') {
        grouped[key].income += absAmount;
      } else if (txn.type === 'expense') {
        grouped[key].expenses += absAmount;
        const category = txn.category || 'Uncategorized';
        grouped[key].categories[category] =
          (grouped[key].categories[category] || 0) + absAmount;
      }

      grouped[key].net = grouped[key].income - grouped[key].expenses;
    });

    const summary = Object.values(grouped).sort((a: any, b: any) =>
      b.period.localeCompare(a.period),
    );

    // Fetch user preferences for formatting
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;
    const dateFormat = userPreferences.dateFormat;

    return {
      summary,
      totalPeriods: summary.length,
      totalTransactions: transactions.length,
      overallIncome: summary.reduce((sum: number, p: any) => sum + p.income, 0),
      overallExpenses: summary.reduce(
        (sum: number, p: any) => sum + p.expenses,
        0,
      ),
      overallNet: summary.reduce((sum: number, p: any) => sum + p.net, 0),
      currency, // Return currency for amount formatting
      dateFormat, // Return date format preference
    };
  } catch (error: any) {
    console.error('Error getting transaction summary:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get transaction summary',
      error.message,
    );
  }
});

/**
 * Invalidate dashboard cache
 */
export const invalidateDashboardCache = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const userId = request.auth.uid;

    try {
      await db.collection('dashboard_cache').doc(userId).delete();
      return { success: true, invalidated: true };
    } catch (error: any) {
      console.error('Error invalidating cache:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to invalidate cache',
        error.message,
      );
    }
  },
);
