import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();

interface DuplicateCheckResult {
  isDuplicate: boolean;
  confidence: number;
  matchType: 'exact' | 'fuzzy' | 'none';
  matchedTransactionId?: string;
  reason?: string;
}

/**
 * Check if a transaction is a duplicate
 */
export const checkDuplicateTransaction = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const userId = request.auth.uid;
    const { transaction, accountId } = request.data as {
      transaction: {
        date: string;
        amount: number;
        description: string;
        reference?: string;
        type: 'income' | 'expense' | 'transfer';
      };
      accountId: string;
    };

    if (!transaction || !accountId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Transaction and accountId are required',
      );
    }

    try {
      // Check for exact reference match first
      if (transaction.reference) {
        const referenceMatch = await checkReferenceMatch(
          userId,
          transaction.reference,
        );
        if (referenceMatch.isDuplicate) {
          return referenceMatch;
        }
      }

      // Check for fuzzy match (date + amount + description similarity)
      const fuzzyMatch = await checkFuzzyMatch(userId, accountId, transaction);
      return fuzzyMatch;
    } catch (error) {
      console.error('Error checking duplicate transaction:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        'Failed to check duplicate transaction',
      );
    }
  },
);

async function checkReferenceMatch(
  userId: string,
  reference: string,
): Promise<DuplicateCheckResult> {
  const snapshot = await db
    .collection('transactions')
    .where('user_id', '==', userId)
    .where('reference', '==', reference)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return {
      isDuplicate: true,
      confidence: 100,
      matchType: 'exact',
      matchedTransactionId: snapshot.docs[0].id,
      reason: 'Exact reference number match',
    };
  }

  return {
    isDuplicate: false,
    confidence: 0,
    matchType: 'none',
  };
}

async function checkFuzzyMatch(
  userId: string,
  accountId: string,
  transaction: any,
): Promise<DuplicateCheckResult> {
  const txnDate = new Date(transaction.date);

  // Check ±3 days window
  const startDate = new Date(txnDate);
  startDate.setDate(startDate.getDate() - 3);
  const endDate = new Date(txnDate);
  endDate.setDate(endDate.getDate() + 3);

  const snapshot = await db
    .collection('transactions')
    .where('user_id', '==', userId)
    .where('account_id', '==', accountId)
    .where('date', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .where('date', '<=', admin.firestore.Timestamp.fromDate(endDate))
    .get();

  let bestMatch: DuplicateCheckResult = {
    isDuplicate: false,
    confidence: 0,
    matchType: 'none',
  };

  snapshot.docs.forEach((doc) => {
    const existingTxn = doc.data();

    // Check if type matches
    if (existingTxn.type !== transaction.type) {
      return;
    }

    // Check if amount matches (within 1% tolerance)
    const amountDiff = Math.abs(existingTxn.amount - transaction.amount);
    const amountTolerance = transaction.amount * 0.01;

    if (amountDiff > amountTolerance) {
      return;
    }

    // Calculate description similarity
    const similarity = calculateStringSimilarity(
      normalizeString(transaction.description),
      normalizeString(existingTxn.description),
    );

    // Calculate confidence score
    let confidence = 0;

    // Same date: +40 points
    const existingDate = existingTxn.date.toDate();
    if (isSameDay(txnDate, existingDate)) {
      confidence += 40;
    } else {
      // Within 1 day: +20, 2 days: +10, 3 days: +5
      const dayDiff = Math.abs(
        Math.floor(
          (txnDate.getTime() - existingDate.getTime()) / (1000 * 60 * 60 * 24),
        ),
      );
      confidence += Math.max(0, 40 - dayDiff * 10);
    }

    // Exact amount: +30 points
    if (existingTxn.amount === transaction.amount) {
      confidence += 30;
    } else {
      // Within tolerance: +20 points
      confidence += 20;
    }

    // Description similarity: up to +30 points
    confidence += similarity * 30;

    // If confidence is higher than current best match, update it
    if (confidence > bestMatch.confidence) {
      bestMatch = {
        isDuplicate: confidence >= 70, // 70% threshold for duplicate
        confidence: Math.round(confidence),
        matchType: confidence >= 90 ? 'exact' : 'fuzzy',
        matchedTransactionId: doc.id,
        reason: `${Math.round(similarity * 100)}% description match, ${
          amountDiff === 0 ? 'exact' : 'similar'
        } amount, ${Math.abs(
          Math.floor(
            (txnDate.getTime() - existingDate.getTime()) /
              (1000 * 60 * 60 * 24),
          ),
        )} day(s) apart`,
      };
    }
  });

  return bestMatch;
}

function normalizeString(str: string): string {
  return str.toLowerCase().replace(/[^a-z0-9]/g, '');
}

function calculateStringSimilarity(str1: string, str2: string): number {
  if (str1 === str2) return 1;
  if (str1.length === 0 || str2.length === 0) return 0;

  // Use Levenshtein distance
  const matrix: number[][] = [];

  for (let i = 0; i <= str2.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= str1.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= str2.length; i++) {
    for (let j = 1; j <= str1.length; j++) {
      if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j] + 1, // deletion
        );
      }
    }
  }

  const distance = matrix[str2.length][str1.length];
  const maxLength = Math.max(str1.length, str2.length);
  return 1 - distance / maxLength;
}

function isSameDay(date1: Date, date2: Date): boolean {
  return (
    date1.getFullYear() === date2.getFullYear() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getDate() === date2.getDate()
  );
}

/**
 * Batch check for duplicates (for import operations)
 */
export const batchCheckDuplicates = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { transactions, accountId } = request.data as {
    transactions: Array<{
      date: string;
      amount: number;
      description: string;
      reference?: string;
      type: 'income' | 'expense' | 'transfer';
    }>;
    accountId: string;
  };

  if (!transactions || !Array.isArray(transactions) || !accountId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Transactions array and accountId are required',
    );
  }

  if (transactions.length > 100) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Maximum 100 transactions per batch',
    );
  }

  try {
    const results = await Promise.all(
      transactions.map(async (txn) => {
        // Check for exact reference match first
        if (txn.reference) {
          const referenceMatch = await checkReferenceMatch(
            userId,
            txn.reference,
          );
          if (referenceMatch.isDuplicate) {
            return { transaction: txn, result: referenceMatch };
          }
        }

        // Check for fuzzy match
        const fuzzyMatch = await checkFuzzyMatch(userId, accountId, txn);
        return { transaction: txn, result: fuzzyMatch };
      }),
    );

    const duplicates = results.filter((r) => r.result.isDuplicate);
    const unique = results.filter((r) => !r.result.isDuplicate);

    return {
      success: true,
      summary: {
        total: transactions.length,
        duplicates: duplicates.length,
        unique: unique.length,
      },
      results: results,
    };
  } catch (error) {
    console.error('Error batch checking duplicates:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to batch check duplicates',
    );
  }
});
