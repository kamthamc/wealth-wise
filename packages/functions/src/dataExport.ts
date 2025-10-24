import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();

/**
 * Export user data in JSON format
 */
export const exportUserData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { format = 'json', includeDeleted = false } = request.data as {
    format?: 'json' | 'csv';
    includeDeleted?: boolean;
  };

  try {
    // Get all accounts
    let accountsQuery = db
      .collection('accounts')
      .where('user_id', '==', userId);

    if (!includeDeleted) {
      accountsQuery = accountsQuery.where('is_active', '==', true);
    }

    const accountsSnapshot = await accountsQuery.get();
    const accounts = accountsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Get all transactions
    const transactionsSnapshot = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .orderBy('date', 'desc')
      .get();

    const transactions = transactionsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      date: doc.data().date.toDate().toISOString(),
    }));

    // Get all budgets
    const budgetsSnapshot = await db
      .collection('budgets')
      .where('user_id', '==', userId)
      .orderBy('created_at', 'desc')
      .get();

    const budgets = budgetsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      start_date: doc.data().start_date.toDate().toISOString(),
      end_date: doc.data().end_date.toDate().toISOString(),
      created_at: doc.data().created_at.toDate().toISOString(),
      updated_at: doc.data().updated_at?.toDate().toISOString(),
    }));

    // Get all goals
    const goalsSnapshot = await db
      .collection('goals')
      .where('user_id', '==', userId)
      .get();

    const goals = goalsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      target_date: doc.data().target_date?.toDate().toISOString(),
      created_at: doc.data().created_at?.toDate().toISOString(),
    }));

    const exportData = {
      exportedAt: new Date().toISOString(),
      userId: userId,
      summary: {
        accountsCount: accounts.length,
        transactionsCount: transactions.length,
        budgetsCount: budgets.length,
        goalsCount: goals.length,
      },
      accounts,
      transactions,
      budgets,
      goals,
    };

    return {
      success: true,
      format,
      data: exportData,
    };
  } catch (error) {
    console.error('Error exporting user data:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to export user data',
    );
  }
});

/**
 * Import user data from exported JSON
 */
export const importUserData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { data, replaceExisting = false } = request.data as {
    data: any;
    replaceExisting?: boolean;
  };

  if (!data) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Import data is required',
    );
  }

  try {
    const batch = db.batch();
    let accountsImported = 0;
    let transactionsImported = 0;
    let budgetsImported = 0;
    let goalsImported = 0;

    // If replaceExisting, delete all existing data first
    if (replaceExisting) {
      const deletePromises = [
        deleteUserCollection(userId, 'accounts'),
        deleteUserCollection(userId, 'transactions'),
        deleteUserCollection(userId, 'budgets'),
        deleteUserCollection(userId, 'goals'),
      ];
      await Promise.all(deletePromises);
    }

    // Import accounts
    if (data.accounts && Array.isArray(data.accounts)) {
      for (const account of data.accounts) {
        const docRef = db.collection('accounts').doc();
        const accountData = {
          ...account,
          user_id: userId, // Ensure correct user_id
          id: undefined, // Remove old ID
        };
        delete accountData.id;
        batch.set(docRef, accountData);
        accountsImported++;
      }
    }

    // Import transactions
    if (data.transactions && Array.isArray(data.transactions)) {
      for (const transaction of data.transactions) {
        const docRef = db.collection('transactions').doc();
        const txnData = {
          ...transaction,
          user_id: userId,
          date: admin.firestore.Timestamp.fromDate(new Date(transaction.date)),
          id: undefined,
        };
        delete txnData.id;
        batch.set(docRef, txnData);
        transactionsImported++;
      }
    }

    // Import budgets
    if (data.budgets && Array.isArray(data.budgets)) {
      for (const budget of data.budgets) {
        const docRef = db.collection('budgets').doc();
        const budgetData = {
          ...budget,
          user_id: userId,
          start_date: admin.firestore.Timestamp.fromDate(
            new Date(budget.start_date),
          ),
          end_date: admin.firestore.Timestamp.fromDate(
            new Date(budget.end_date),
          ),
          created_at: admin.firestore.Timestamp.fromDate(
            new Date(budget.created_at),
          ),
          updated_at: budget.updated_at
            ? admin.firestore.Timestamp.fromDate(new Date(budget.updated_at))
            : admin.firestore.Timestamp.now(),
          id: undefined,
        };
        delete budgetData.id;
        batch.set(docRef, budgetData);
        budgetsImported++;
      }
    }

    // Import goals
    if (data.goals && Array.isArray(data.goals)) {
      for (const goal of data.goals) {
        const docRef = db.collection('goals').doc();
        const goalData = {
          ...goal,
          user_id: userId,
          target_date: goal.target_date
            ? admin.firestore.Timestamp.fromDate(new Date(goal.target_date))
            : null,
          created_at: goal.created_at
            ? admin.firestore.Timestamp.fromDate(new Date(goal.created_at))
            : admin.firestore.Timestamp.now(),
          id: undefined,
        };
        delete goalData.id;
        batch.set(docRef, goalData);
        goalsImported++;
      }
    }

    await batch.commit();

    return {
      success: true,
      summary: {
        accountsImported,
        transactionsImported,
        budgetsImported,
        goalsImported,
      },
    };
  } catch (error) {
    console.error('Error importing user data:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to import user data',
    );
  }
});

async function deleteUserCollection(userId: string, collectionName: string) {
  const snapshot = await db
    .collection(collectionName)
    .where('user_id', '==', userId)
    .get();

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
}

/**
 * Get user statistics
 */
export const getUserStatistics = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;

  try {
    // Get counts for all collections
    const [accountsSnap, transactionsSnap, budgetsSnap, goalsSnap] =
      await Promise.all([
        db
          .collection('accounts')
          .where('user_id', '==', userId)
          .where('is_active', '==', true)
          .get(),
        db.collection('transactions').where('user_id', '==', userId).get(),
        db.collection('budgets').where('user_id', '==', userId).get(),
        db.collection('goals').where('user_id', '==', userId).get(),
      ]);

    // Get first and last transaction dates
    const firstTxnSnap = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .orderBy('date', 'asc')
      .limit(1)
      .get();

    const lastTxnSnap = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .orderBy('date', 'desc')
      .limit(1)
      .get();

    const firstTransactionDate = !firstTxnSnap.empty
      ? firstTxnSnap.docs[0].data().date.toDate().toISOString()
      : null;

    const lastTransactionDate = !lastTxnSnap.empty
      ? lastTxnSnap.docs[0].data().date.toDate().toISOString()
      : null;

    // Calculate total balance
    const totalBalance = accountsSnap.docs.reduce(
      (sum: number, doc: any) => sum + (doc.data().balance || 0),
      0,
    );

    // Get account types breakdown
    const accountsByType = accountsSnap.docs.reduce((acc: any, doc: any) => {
      const type = doc.data().type;
      acc[type] = (acc[type] || 0) + 1;
      return acc;
    }, {});

    return {
      success: true,
      statistics: {
        totalAccounts: accountsSnap.size,
        totalTransactions: transactionsSnap.size,
        totalBudgets: budgetsSnap.size,
        totalGoals: goalsSnap.size,
        totalBalance: Math.round(totalBalance * 100) / 100,
        accountsByType,
        firstTransactionDate,
        lastTransactionDate,
        dataQuality: {
          accountsWithoutBalance: accountsSnap.docs.filter(
            (doc: any) => !doc.data().balance,
          ).length,
          transactionsWithoutCategory: transactionsSnap.docs.filter(
            (doc: any) => !doc.data().category,
          ).length,
        },
      },
    };
  } catch (error) {
    console.error('Error getting user statistics:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get user statistics',
    );
  }
});
