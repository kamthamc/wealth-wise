import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import {
  AppError,
  authError,
  ErrorCodes,
  notFoundError,
  permissionError,
  validationError,
} from './errors';
import { importTransactionsSchema, safeValidate } from './schemas';

const db = admin.firestore();

/**
 * Import transactions from CSV/JSON data
 * Supports batch import with duplicate detection
 */
export const importTransactions = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw authError(ErrorCodes.AUTH_UNAUTHENTICATED);
  }

  const userId = request.auth.uid;

  // Validate input with Zod
  const validation = safeValidate(importTransactionsSchema, request.data);
  if (!validation.success) {
    throw validationError(ErrorCodes.VALIDATION_INVALID_FORMAT, undefined, {
      errors: validation.errors.issues,
    });
  }

  const { transactions, accountId, detectDuplicates = true } = validation.data;

  try {
    // Verify account ownership
    const accountDoc = await db.collection('accounts').doc(accountId).get();
    if (!accountDoc.exists) {
      throw notFoundError(ErrorCodes.ACCOUNT_NOT_FOUND, 'Account');
    }

    if (accountDoc.data()?.user_id !== userId) {
      throw permissionError(ErrorCodes.PERMISSION_DENIED);
    }

    const importReference = `import_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const results = {
      total: transactions.length,
      imported: 0,
      skipped: 0,
      duplicates: [] as string[],
      errors: [] as string[],
    };

    const batch = db.batch();
    let batchCount = 0;
    const MAX_BATCH_SIZE = 500;

    for (let i = 0; i < transactions.length; i++) {
      const txn = transactions[i];

      try {
        // Validate required fields
        if (!txn.date || !txn.description || txn.amount === undefined) {
          results.errors.push(`Transaction ${i + 1}: Missing required fields`);
          results.skipped++;
          continue;
        }

        // Duplicate detection
        if (detectDuplicates) {
          const duplicateQuery = await db
            .collection('transactions')
            .where('user_id', '==', userId)
            .where('account_id', '==', accountId)
            .where(
              'date',
              '==',
              admin.firestore.Timestamp.fromDate(new Date(txn.date)),
            )
            .where('amount', '==', Math.abs(txn.amount))
            .where('description', '==', txn.description)
            .limit(1)
            .get();

          if (!duplicateQuery.empty) {
            results.duplicates.push(txn.description);
            results.skipped++;
            continue;
          }
        }

        // Create transaction
        const txnRef = db.collection('transactions').doc();
        const now = admin.firestore.FieldValue.serverTimestamp();

        const transactionData = {
          user_id: userId,
          account_id: accountId,
          date: admin.firestore.Timestamp.fromDate(new Date(txn.date)),
          description: txn.description,
          amount: txn.amount,
          type: txn.type,
          category: txn.category || null,
          notes: txn.notes || null,
          import_reference: importReference,
          import_transaction_id: txn.import_transaction_id || null,
          created_at: now,
          updated_at: now,
        };

        batch.set(txnRef, transactionData);
        batchCount++;
        results.imported++;

        // Commit batch if it reaches the limit
        if (batchCount >= MAX_BATCH_SIZE) {
          await batch.commit();
          batchCount = 0;
        }
      } catch (error: any) {
        results.errors.push(`Transaction ${i + 1}: ${error.message}`);
        results.skipped++;
      }
    }

    // Commit remaining transactions
    if (batchCount > 0) {
      await batch.commit();
    }

    // Update account balance
    if (results.imported > 0) {
      // Recalculate account balance
      const transactionsSnapshot = await db
        .collection('transactions')
        .where('account_id', '==', accountId)
        .get();

      let balance = accountDoc.data()?.initial_balance || 0;
      transactionsSnapshot.docs.forEach((doc) => {
        balance += doc.data().amount;
      });

      await db.collection('accounts').doc(accountId).update({
        balance,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      ...results,
      importReference,
      accountId,
    };
  } catch (error: any) {
    console.error('Error importing transactions:', error);
    // Re-throw AppError instances
    if (error instanceof AppError) {
      throw error;
    }
    // Wrap unexpected errors with import-specific error code
    throw new AppError(
      ErrorCodes.OPERATION_FAILED,
      'Failed to import transactions',
      'internal',
      { originalError: error.message },
    );
  }
});

/**
 * Clear all user data
 * WARNING: This is a destructive operation
 */
export const clearUserData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { confirmation, collections = ['all'] } = request.data as {
    confirmation: string;
    collections?: string[];
  };

  // Require explicit confirmation
  if (confirmation !== 'DELETE_ALL_MY_DATA') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Must confirm deletion with exact phrase: DELETE_ALL_MY_DATA',
    );
  }

  try {
    const collectionsToDelete = collections.includes('all')
      ? [
          'transactions',
          'accounts',
          'budgets',
          'goals',
          'goal_contributions',
          'categories',
        ]
      : collections;

    const results: Record<string, number> = {};

    // Delete in batches to avoid timeouts
    for (const collectionName of collectionsToDelete) {
      let deletedCount = 0;
      let hasMore = true;

      while (hasMore) {
        const snapshot = await db
          .collection(collectionName)
          .where('user_id', '==', userId)
          .limit(500)
          .get();

        if (snapshot.empty) {
          hasMore = false;
          break;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
          deletedCount++;
        });

        await batch.commit();
      }

      results[collectionName] = deletedCount;
    }

    // Delete goal contributions (no user_id field, need to check via goal)
    if (
      collectionsToDelete.includes('all') ||
      collectionsToDelete.includes('goal_contributions')
    ) {
      const goalsSnapshot = await db
        .collection('goals')
        .where('user_id', '==', userId)
        .get();
      const goalIds = goalsSnapshot.docs.map((doc) => doc.id);

      let contributionsDeleted = 0;
      for (const goalId of goalIds) {
        let hasMore = true;
        while (hasMore) {
          const contributionsSnapshot = await db
            .collection('goal_contributions')
            .where('goal_id', '==', goalId)
            .limit(500)
            .get();

          if (contributionsSnapshot.empty) {
            hasMore = false;
            break;
          }

          const batch = db.batch();
          contributionsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
            contributionsDeleted++;
          });

          await batch.commit();
        }
      }

      results.goal_contributions = contributionsDeleted;
    }

    return {
      success: true,
      deletedCollections: results,
      totalDeleted: Object.values(results).reduce(
        (sum, count) => sum + count,
        0,
      ),
      timestamp: new Date().toISOString(),
    };
  } catch (error: any) {
    console.error('Error clearing user data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to clear user data',
      error.message,
    );
  }
});

/**
 * Batch import with progress tracking
 * For large imports, processes in chunks
 */
export const batchImportTransactions = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const {
      transactions,
      accountId,
      chunkSize = 100,
    } = request.data as {
      transactions: Array<any>;
      accountId: string;
      chunkSize?: number;
    };

    if (!transactions || !Array.isArray(transactions)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Transactions array is required',
      );
    }

    try {
      const totalChunks = Math.ceil(transactions.length / chunkSize);
      const batchId = `batch_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      const results = {
        batchId,
        totalTransactions: transactions.length,
        totalChunks,
        processedChunks: 0,
        imported: 0,
        skipped: 0,
        errors: [] as string[],
      };

      // Process in chunks
      for (let i = 0; i < totalChunks; i++) {
        const start = i * chunkSize;
        const end = Math.min(start + chunkSize, transactions.length);
        const chunk = transactions.slice(start, end);

        try {
          // Import chunk directly with batch operations
          const importRef = `batch_${batchId}_chunk_${i}`;
          const batch = db.batch();
          let imported = 0;

          for (const txn of chunk) {
            if (!txn.date || !txn.description || txn.amount === undefined) {
              results.skipped++;
              continue;
            }

            const txnRef = db.collection('transactions').doc();
            const now = admin.firestore.FieldValue.serverTimestamp();

            batch.set(txnRef, {
              user_id: request.auth!.uid,
              account_id: accountId,
              date: admin.firestore.Timestamp.fromDate(new Date(txn.date)),
              description: txn.description,
              amount: txn.amount,
              type: txn.type,
              category: txn.category || null,
              notes: txn.notes || null,
              import_reference: importRef,
              created_at: now,
              updated_at: now,
            });

            imported++;
          }

          await batch.commit();
          results.imported += imported;
          results.processedChunks++;
        } catch (error: any) {
          results.errors.push(`Chunk ${i + 1}: ${error.message}`);
        }
      }

      return results;
    } catch (error: any) {
      console.error('Error in batch import:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to process batch import',
        error.message,
      );
    }
  },
);

/**
 * Export transactions with filtering
 */
export const exportTransactions = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const {
    accountId,
    startDate,
    endDate,
    format = 'json',
  } = request.data as {
    accountId?: string;
    startDate?: string;
    endDate?: string;
    format?: 'json' | 'csv';
  };

  try {
    let query = db.collection('transactions').where('user_id', '==', userId);

    if (accountId) {
      query = query.where('account_id', '==', accountId);
    }

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
      id: doc.id,
      ...doc.data(),
      date: doc.data().date.toDate().toISOString(),
      created_at: doc.data().created_at?.toDate?.()?.toISOString?.() || null,
      updated_at: doc.data().updated_at?.toDate?.()?.toISOString?.() || null,
    }));

    if (format === 'csv') {
      // Convert to CSV
      if (transactions.length === 0) {
        return { format: 'csv', data: 'No transactions to export', count: 0 };
      }

      const headers = [
        'date',
        'description',
        'amount',
        'type',
        'category',
        'account_id',
        'notes',
      ];
      const csvRows = [headers.join(',')];

      transactions.forEach((txn: any) => {
        const row = headers.map((header) => {
          const value = txn[header] || '';
          // Escape commas and quotes in CSV
          return typeof value === 'string' &&
            (value.includes(',') || value.includes('"'))
            ? `"${value.replace(/"/g, '""')}"`
            : value;
        });
        csvRows.push(row.join(','));
      });

      return {
        format: 'csv',
        data: csvRows.join('\n'),
        count: transactions.length,
      };
    }

    return {
      format: 'json',
      data: transactions,
      count: transactions.length,
    };
  } catch (error: any) {
    console.error('Error exporting transactions:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to export transactions',
      error.message,
    );
  }
});
