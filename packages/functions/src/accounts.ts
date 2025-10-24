import {} from 'node:https';
import * as admin from 'firebase-admin';
import { https } from 'firebase-functions';
import { getUserAuthenticated } from './auth';
import { ErrorCodes, HTTP_STATUS_CODES, WWHttpError } from './errors';
import {
  allAccountTypes,
  allBudgetPeriods,
  allGoalPriorities,
  allGoalStatuses,
  allTransactionTypes,
  createAccountSchema,
  safeValidate,
} from './schemas';
import type { GetAccountTypesHttpsCallable  } from '@svc/wealth-wise-shared-types'

const { onRequest, onCall } = https;

const db = admin.firestore();

export const getAccountTypes: GetAccountTypesHttpsCallable = onCall(() => {
    // GetAccountTypesHttpsCallable
  return ({
      success: true,
      accountTypes: allAccountTypes,
    });
  });

export const getBudgetPeriods = onRequest(
  {
    cors: '*',
  },
  (req, res) => {
    res.json({
      success: true,
      budgetPeriods: allBudgetPeriods,
    });
  },
);

export const getGoalPriorities = onRequest({}, (req, res) => {
  if (req.method !== 'GET') {
    res
      .status(HTTP_STATUS_CODES.METHOD_NOT_ALLOWED)
      .json({ success: false, message: 'Method Not Allowed' });
    return;
  }
  res.json({
    success: true,
    goalPriorities: allGoalPriorities,
  });
});

export const getGoalStatuses = onRequest({}, (req, res) => {
  res.json({
    success: true,
    goalStatuses: allGoalStatuses,
  });
});

export const getTransactionTypes = onRequest({}, (req, res) => {
  res.json({
    success: true,
    transactionTypes: allTransactionTypes,
  });
});

/**
 * Create a new account
 */
export const createAccount = onCall(async (request, resp) => {
  const auth = getUserAuthenticated(request.auth);
  const userId = auth.uid;

  // Validate input with Zod
  const validation = safeValidate(createAccountSchema, request.data);
  if (!validation.success) {
    throw new WWHttpError(
      ErrorCodes.ACCOUNT_VALIDATION_FAILED,
      HTTP_STATUS_CODES.BAD_REQUEST,
      undefined,
      validation.errors.issues,
    );
  }

  const data = validation.data;

  try {
    // Create account document
    const accountRef = await db.collection('accounts').add({
      user_id: userId,
      name: data.name,
      type: data.type,
      balance: data.balance || 0,
      initial_balance: data.initial_balance || data.balance || 0,
      currency: data.currency || 'INR',
      institution: data.institution || null,
      account_number: data.account_number || null,
      notes: data.notes || null,
      is_active: data.is_active ?? true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      accountId: accountRef.id,
      message: 'Account created successfully',
    };
  } catch (error) {
    console.error('Error creating account:', error);
    throw new WWHttpError(
      ErrorCodes.ACCOUNT_CREATION_FAILED,
      HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
    );
  }
});

/**
 * Update an existing account
 */
export const updateAccount = onCall(async (request) => {
  const auth = getUserAuthenticated(request.auth);
  const userId = auth.uid;
  const { accountId, updates } = request.data as {
    accountId: string;
    updates: any;
  };

  if (!accountId) {
    throw new WWHttpError(
      ErrorCodes.VALIDATION_INVALID_ACCOUNT_ID,
      HTTP_STATUS_CODES.BAD_REQUEST,
    );
  }

  try {
    const accountRef = db.collection('accounts').doc(accountId);
    const account = await accountRef.get();

    if (!account.exists) {
      throw new WWHttpError(
        ErrorCodes.ACCOUNT_NOT_FOUND,
        HTTP_STATUS_CODES.NOT_FOUND,
        'Account not found',
      );
    }

    // Verify ownership
    if (account.data()?.user_id !== userId) {
      throw new WWHttpError(
        ErrorCodes.PERMISSION_DENIED,
        HTTP_STATUS_CODES.FORBIDDEN,
        'Not authorized to update this account',
      );
    }

    // Prepare update data
    const updateData: any = {
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.type !== undefined) updateData.type = updates.type;
    if (updates.balance !== undefined) updateData.balance = updates.balance;
    if (updates.currency !== undefined) updateData.currency = updates.currency;
    if (updates.icon !== undefined) updateData.icon = updates.icon;
    if (updates.color !== undefined) updateData.color = updates.color;

    await accountRef.update(updateData);

    return {
      success: true,
      message: 'Account updated successfully',
    };
  } catch (error) {
    console.error('Error updating account:', error);
    if (error instanceof WWHttpError) {
      throw error;
    }
    throw new WWHttpError(
      ErrorCodes.INTERNAL_ERROR,
      HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
      'Failed to update account',
    );
  }
});

/**
 * Delete an account
 */
export const deleteAccount = onCall(async (request) => {
  const auth = getUserAuthenticated(request.auth);
  const userId = auth.uid;
  const { accountId } = request.data as { accountId: string };

  if (!accountId) {
    throw new WWHttpError(
      ErrorCodes.VALIDATION_INVALID_ACCOUNT_ID,
      HTTP_STATUS_CODES.BAD_REQUEST,
    );
  }

  try {
    const accountRef = db.collection('accounts').doc(accountId);
    const account = await accountRef.get();

    if (!account.exists) {
      throw new WWHttpError(
        ErrorCodes.ACCOUNT_NOT_FOUND,
        HTTP_STATUS_CODES.NOT_FOUND,
        'Account not found',
      );
    }

    // Verify ownership
    if (account.data()?.user_id !== userId) {
      throw new WWHttpError(
        ErrorCodes.PERMISSION_DENIED,
        HTTP_STATUS_CODES.FORBIDDEN,
        'Not authorized to delete this account',
      );
    }

    // Check if account has transactions
    const transactionsSnapshot = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .where('account_id', '==', accountId)
      .limit(1)
      .get();

    if (!transactionsSnapshot.empty) {
      throw new WWHttpError(
        ErrorCodes.ACCOUNT_DELETE_FAILED,
        HTTP_STATUS_CODES.FAILED_DEPENDENCY,
        'Cannot delete account with existing transactions',
      );
    }

    await accountRef.delete();

    return {
      success: true,
      message: 'Account deleted successfully',
    };
  } catch (error) {
    console.error('Error deleting account:', error);
    if (error instanceof WWHttpError) {
      throw error;
    }
    throw new WWHttpError(
      ErrorCodes.INTERNAL_ERROR,
      HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
      'Failed to delete account',
    );
  }
});

/**
 * Calculate account balance from transactions
 */
export const calculateAccountBalance = onCall(async (request) => {
  const auth = getUserAuthenticated(request.auth);
  const userId = auth.uid;
  const { accountId } = request.data as { accountId: string };

  if (!accountId) {
    throw new WWHttpError(
      ErrorCodes.VALIDATION_INVALID_ACCOUNT_ID,
      HTTP_STATUS_CODES.BAD_REQUEST,
    );
  }

  try {
    const accountRef = db.collection('accounts').doc(accountId);
    const account = await accountRef.get();

    if (!account.exists) {
      throw new WWHttpError(
        ErrorCodes.ACCOUNT_NOT_FOUND,
        HTTP_STATUS_CODES.NOT_FOUND,
        'Account not found',
      );
    }

    // Verify ownership
    if (account.data()?.user_id !== userId) {
      throw new WWHttpError(
        ErrorCodes.PERMISSION_DENIED,
        HTTP_STATUS_CODES.FORBIDDEN,
        'Not authorized to access this account',
      );
    }

    // Get all transactions for this account
    const transactionsSnapshot = await db
      .collection('transactions')
      .where('user_id', '==', userId)
      .where('account_id', '==', accountId)
      .get();

    let balance = Number(0);
    transactionsSnapshot.forEach((doc) => {
      const transaction = doc.data();
      if (transaction.type === 'income') {
        balance += Number(transaction.amount);
      } else if (transaction.type === 'expense') {
        balance -= Number(transaction.amount);
      }
    });

    // Update account balance
    await accountRef.update({
      balance: String(balance),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      balance: String(balance),
      message: 'Account balance calculated successfully',
    };
  } catch (error) {
    console.error('Error calculating account balance:', error);
    if (error instanceof WWHttpError) {
      throw error;
    }
    throw new WWHttpError(
      ErrorCodes.INTERNAL_ERROR,
      HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR,
      'Failed to calculate account balance',
    );
  }
});
