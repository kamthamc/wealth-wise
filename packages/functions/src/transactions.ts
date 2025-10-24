import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();

interface CreateTransactionData {
  account_id: string;
  type: 'income' | 'expense' | 'transfer';
  category: string;
  amount: number;
  description?: string;
  date: string; // ISO date string
  tags?: string[];
  location?: string;
  receipt_url?: string;
  is_recurring?: boolean;
  recurring_frequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  // For transfers
  to_account_id?: string;
}

/**
 * Create a new transaction
 */
export const createTransaction = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const data = request.data as CreateTransactionData;

  // Validate input
  if (!data.account_id) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Account ID is required',
    );
  }

  if (!data.type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Transaction type is required',
    );
  }

  if (!data.category) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Category is required',
    );
  }

  if (data.amount === undefined || data.amount <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Amount must be positive',
    );
  }

  if (!data.date) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Date is required',
    );
  }

  try {
    // Verify account ownership
    const accountRef = db.collection('accounts').doc(data.account_id);
    const account = await accountRef.get();

    if (!account.exists) {
      throw new functions.https.HttpsError('not-found', 'Account not found');
    }

    if (account.data()?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to access this account',
      );
    }

    // Handle transfer transactions
    if (data.type === 'transfer') {
      if (!data.to_account_id) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'To account ID is required for transfers',
        );
      }

      // Verify to_account ownership
      const toAccountRef = db.collection('accounts').doc(data.to_account_id);
      const toAccount = await toAccountRef.get();

      if (!toAccount.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Destination account not found',
        );
      }

      if (toAccount.data()?.user_id !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Not authorized to access destination account',
        );
      }

      // Create expense transaction in source account
      const expenseRef = await db.collection('transactions').add({
        user_id: userId,
        account_id: data.account_id,
        type: 'expense',
        category: data.category,
        amount: data.amount,
        description:
          data.description || `Transfer to ${toAccount.data()?.name}`,
        date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
        tags: data.tags || [],
        is_transfer: true,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create income transaction in destination account
      const incomeRef = await db.collection('transactions').add({
        user_id: userId,
        account_id: data.to_account_id,
        type: 'income',
        category: data.category,
        amount: data.amount,
        description:
          data.description || `Transfer from ${account.data()?.name}`,
        date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
        tags: data.tags || [],
        is_transfer: true,
        linked_transaction_id: expenseRef.id,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Link transactions
      await expenseRef.update({ linked_transaction_id: incomeRef.id });

      // Update account balances
      const currentBalance = account.data()?.balance || 0;
      const toBalance = toAccount.data()?.balance || 0;

      await accountRef.update({
        balance: currentBalance - data.amount,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      await toAccountRef.update({
        balance: toBalance + data.amount,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        transactionId: expenseRef.id,
        linkedTransactionId: incomeRef.id,
        message: 'Transfer completed successfully',
      };
    }

    // Create regular transaction (income/expense)
    const transactionRef = await db.collection('transactions').add({
      user_id: userId,
      account_id: data.account_id,
      type: data.type,
      category: data.category,
      amount: data.amount,
      description: data.description || '',
      date: admin.firestore.Timestamp.fromDate(new Date(data.date)),
      tags: data.tags || [],
      location: data.location || '',
      receipt_url: data.receipt_url || '',
      is_recurring: data.is_recurring || false,
      recurring_frequency: data.recurring_frequency || null,
      is_transfer: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update account balance
    const currentBalance = account.data()?.balance || 0;
    let newBalance = currentBalance;

    if (data.type === 'income') {
      newBalance += data.amount;
    } else if (data.type === 'expense') {
      newBalance -= data.amount;
    }

    await accountRef.update({
      balance: newBalance,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      transactionId: transactionRef.id,
      message: 'Transaction created successfully',
    };
  } catch (error) {
    console.error('Error creating transaction:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create transaction',
    );
  }
});

/**
 * Update an existing transaction
 */
export const updateTransaction = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { transactionId, updates } = request.data as {
    transactionId: string;
    updates: Partial<CreateTransactionData>;
  };

  if (!transactionId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Transaction ID is required',
    );
  }

  try {
    const transactionRef = db.collection('transactions').doc(transactionId);
    const transaction = await transactionRef.get();

    if (!transaction.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Transaction not found',
      );
    }

    const transactionData = transaction.data();

    // Verify ownership
    if (transactionData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to update this transaction',
      );
    }

    // Prepare update data
    const updateData: any = {
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Handle amount or type changes - need to update account balance
    const amountChanged =
      updates.amount !== undefined &&
      updates.amount !== transactionData?.amount;
    const typeChanged =
      updates.type !== undefined && updates.type !== transactionData?.type;

    if (amountChanged || typeChanged) {
      const accountRef = db
        .collection('accounts')
        .doc(transactionData?.account_id);
      const account = await accountRef.get();

      if (account.exists) {
        let balanceAdjustment = 0;

        // Reverse old transaction effect
        const oldAmount = transactionData?.amount || 0;
        const oldType = transactionData?.type;

        if (oldType === 'income') {
          balanceAdjustment -= oldAmount;
        } else if (oldType === 'expense') {
          balanceAdjustment += oldAmount;
        }

        // Apply new transaction effect
        const newAmount = updates.amount ?? oldAmount;
        const newType = updates.type ?? oldType;

        if (newType === 'income') {
          balanceAdjustment += newAmount;
        } else if (newType === 'expense') {
          balanceAdjustment -= newAmount;
        }

        // Update account balance
        const currentBalance = account.data()?.balance || 0;
        await accountRef.update({
          balance: currentBalance + balanceAdjustment,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    // Update transaction fields
    if (updates.type !== undefined) updateData.type = updates.type;
    if (updates.category !== undefined) updateData.category = updates.category;
    if (updates.amount !== undefined) updateData.amount = updates.amount;
    if (updates.description !== undefined)
      updateData.description = updates.description;
    if (updates.date !== undefined) {
      updateData.date = admin.firestore.Timestamp.fromDate(
        new Date(updates.date),
      );
    }
    if (updates.tags !== undefined) updateData.tags = updates.tags;
    if (updates.location !== undefined) updateData.location = updates.location;
    if (updates.receipt_url !== undefined)
      updateData.receipt_url = updates.receipt_url;
    if (updates.is_recurring !== undefined)
      updateData.is_recurring = updates.is_recurring;
    if (updates.recurring_frequency !== undefined)
      updateData.recurring_frequency = updates.recurring_frequency;

    await transactionRef.update(updateData);

    return {
      success: true,
      message: 'Transaction updated successfully',
    };
  } catch (error) {
    console.error('Error updating transaction:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update transaction',
    );
  }
});

/**
 * Delete a transaction
 */
export const deleteTransaction = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { transactionId } = request.data as { transactionId: string };

  if (!transactionId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Transaction ID is required',
    );
  }

  try {
    const transactionRef = db.collection('transactions').doc(transactionId);
    const transaction = await transactionRef.get();

    if (!transaction.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Transaction not found',
      );
    }

    const transactionData = transaction.data();

    // Verify ownership
    if (transactionData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to delete this transaction',
      );
    }

    // Handle linked transactions (transfers)
    if (
      transactionData?.is_transfer &&
      transactionData?.linked_transaction_id
    ) {
      const linkedRef = db
        .collection('transactions')
        .doc(transactionData.linked_transaction_id);
      const linkedTransaction = await linkedRef.get();

      if (linkedTransaction.exists) {
        // Update balance for linked account
        const linkedAccountId = linkedTransaction.data()?.account_id;
        if (linkedAccountId) {
          const linkedAccountRef = db
            .collection('accounts')
            .doc(linkedAccountId);
          const linkedAccount = await linkedAccountRef.get();

          if (linkedAccount.exists) {
            const linkedType = linkedTransaction.data()?.type;
            const linkedAmount = linkedTransaction.data()?.amount || 0;
            const linkedBalance = linkedAccount.data()?.balance || 0;

            let balanceAdjustment = 0;
            if (linkedType === 'income') {
              balanceAdjustment = -linkedAmount;
            } else if (linkedType === 'expense') {
              balanceAdjustment = linkedAmount;
            }

            await linkedAccountRef.update({
              balance: linkedBalance + balanceAdjustment,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }

        // Delete linked transaction
        await linkedRef.delete();
      }
    }

    // Update account balance
    const accountRef = db
      .collection('accounts')
      .doc(transactionData?.account_id);
    const account = await accountRef.get();

    if (account.exists) {
      const currentBalance = account.data()?.balance || 0;
      const transactionAmount = transactionData?.amount || 0;
      const transactionType = transactionData?.type;

      let balanceAdjustment = 0;
      if (transactionType === 'income') {
        balanceAdjustment = -transactionAmount;
      } else if (transactionType === 'expense') {
        balanceAdjustment = transactionAmount;
      }

      await accountRef.update({
        balance: currentBalance + balanceAdjustment,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Delete transaction
    await transactionRef.delete();

    return {
      success: true,
      message: 'Transaction deleted successfully',
    };
  } catch (error) {
    console.error('Error deleting transaction:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to delete transaction',
    );
  }
});

/**
 * Get transaction statistics for a date range
 */
export const getTransactionStats = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { startDate, endDate } = request.data as {
    startDate: string;
    endDate: string;
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

    const transactionsSnapshot = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .where('date', '>=', start)
      .where('date', '<=', end)
      .get();

    let totalIncome = 0;
    let totalExpense = 0;
    const categoryBreakdown: Record<string, number> = {};

    transactionsSnapshot.forEach((doc) => {
      const transaction = doc.data();
      const amount = transaction.amount || 0;
      const category = transaction.category;

      if (transaction.type === 'income') {
        totalIncome += amount;
      } else if (transaction.type === 'expense') {
        totalExpense += amount;
        categoryBreakdown[category] =
          (categoryBreakdown[category] || 0) + amount;
      }
    });

    return {
      success: true,
      stats: {
        total_income: totalIncome,
        total_expense: totalExpense,
        net: totalIncome - totalExpense,
        transaction_count: transactionsSnapshot.size,
        category_breakdown: categoryBreakdown,
      },
    };
  } catch (error) {
    console.error('Error getting transaction stats:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get transaction statistics',
    );
  }
});
