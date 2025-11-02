import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { fetchUserPreferences } from './preferences';

const db = admin.firestore();

interface BudgetCategory {
  category: string;
  allocated_amount: number;
  alert_threshold?: number;
  notes?: string;
}

interface CreateBudgetData {
  name: string;
  description?: string;
  period_type: 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event';
  start_date: string; // TS
  end_date?: string;
  is_recurring: boolean;
  rollover_enabled: boolean;
  categories: BudgetCategory[];
}

/**
 * Create a new budget
 */
export const createBudget = functions.https.onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const data = request.data as CreateBudgetData;

  // Validate input
  if (!data.name || data.name.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Budget name is required',
    );
  }

  if (!data.period_type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Period type is required',
    );
  }

  if (!data.start_date) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Start date is required',
    );
  }

  if (!Array.isArray(data.categories) || data.categories.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'At least one category is required',
    );
  }

  try {
    // Fetch user preferences for currency
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;

    // Create budget document
    const budgetRef = await db.collection('budgets').add({
      user_id: userId,
      name: data.name,
      description: data.description || '',
      period_type: data.period_type,
      start_date: admin.firestore.Timestamp.fromDate(new Date(data.start_date)),
      end_date: data.end_date
        ? admin.firestore.Timestamp.fromDate(new Date(data.end_date))
        : null,
      is_recurring: data.is_recurring,
      rollover_enabled: data.rollover_enabled,
      categories: data.categories,
      currency, // Store currency with budget
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      budgetId: budgetRef.id,
      currency, // Return currency in response
      message: 'Budget created successfully',
    };
  } catch (error) {
    console.error('Error creating budget:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create budget');
  }
});

/**
 * Update an existing budget
 */
export const updateBudget = functions.https.onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { budgetId, updates } = request.data as {
    budgetId: string;
    updates: Partial<CreateBudgetData>;
  };

  if (!budgetId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Budget ID is required',
    );
  }

  try {
    const budgetRef = db.collection('budgets').doc(budgetId);
    const budget = await budgetRef.get();

    if (!budget.exists) {
      throw new functions.https.HttpsError('not-found', 'Budget not found');
    }

    // Verify ownership
    if (budget.data()?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to update this budget',
      );
    }

    // Prepare update data
    const updateData: any = {
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.description !== undefined)
      updateData.description = updates.description;
    if (updates.period_type !== undefined)
      updateData.period_type = updates.period_type;
    if (updates.start_date !== undefined) {
      updateData.start_date = admin.firestore.Timestamp.fromDate(
        new Date(updates.start_date),
      );
    }
    if (updates.end_date !== undefined) {
      updateData.end_date = updates.end_date
        ? admin.firestore.Timestamp.fromDate(new Date(updates.end_date))
        : null;
    }
    if (updates.is_recurring !== undefined)
      updateData.is_recurring = updates.is_recurring;
    if (updates.rollover_enabled !== undefined)
      updateData.rollover_enabled = updates.rollover_enabled;
    if (updates.categories !== undefined)
      updateData.categories = updates.categories;

    await budgetRef.update(updateData);

    // Get updated budget data including currency
    const updatedBudget = await budgetRef.get();
    const budgetData = updatedBudget.data();
    const currency = budgetData?.currency || 'INR';

    return {
      success: true,
      currency, // Return currency in response
      message: 'Budget updated successfully',
    };
  } catch (error) {
    console.error('Error updating budget:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to update budget');
  }
});

/**
 * Delete a budget
 */
export const deleteBudget = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { budgetId } = request.data as { budgetId: string };

  if (!budgetId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Budget ID is required',
    );
  }

  try {
    const budgetRef = db.collection('budgets').doc(budgetId);
    const budget = await budgetRef.get();

    if (!budget.exists) {
      throw new functions.https.HttpsError('not-found', 'Budget not found');
    }

    // Verify ownership
    if (budget.data()?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to delete this budget',
      );
    }

    await budgetRef.delete();

    return {
      success: true,
      message: 'Budget deleted successfully',
    };
  } catch (error) {
    console.error('Error deleting budget:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to delete budget');
  }
});

/**
 * Calculate budget progress and spending
 */
export const calculateBudgetProgress = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const userId = request.auth.uid;
    const { budgetId } = request.data as { budgetId: string };

    if (!budgetId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Budget ID is required',
      );
    }

    try {
      const budgetRef = db.collection('budgets').doc(budgetId);
      const budget = await budgetRef.get();

      if (!budget.exists) {
        throw new functions.https.HttpsError('not-found', 'Budget not found');
      }

      const budgetData = budget.data();

      // Verify ownership
      if (budgetData?.user_id !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Not authorized to access this budget',
        );
      }

      // Get transactions within budget period
      const startDate = budgetData?.start_date?.toDate();
      const endDate = budgetData?.end_date?.toDate() || new Date();

      const transactionsSnapshot = await db
        .collection('transactions')
        .where('user_id', '==', userId)
        .where('type', '==', 'expense')
        .where('date', '>=', startDate)
        .where('date', '<=', endDate)
        .get();

      // Calculate spending by category
      const categorySpending: Record<string, number> = {};
      transactionsSnapshot.forEach((doc) => {
        const transaction = doc.data();
        const category = transaction.category;
        const amount = transaction.amount;
        categorySpending[category] = (categorySpending[category] || 0) + amount;
      });

      // Calculate progress for each budget category
      const categories = (budgetData?.categories || []).map(
        (cat: BudgetCategory) => {
          const spent = categorySpending[cat.category] || 0;
          const allocated = cat.allocated_amount;
          const remaining = allocated - spent;
          const percentUsed = allocated > 0 ? (spent / allocated) * 100 : 0;

          return {
            category: cat.category,
            allocated: cat.allocated_amount,
            spent,
            remaining,
            percent_used: percentUsed,
            is_over_budget: spent > allocated,
            is_near_threshold: cat.alert_threshold
              ? percentUsed >= cat.alert_threshold * 100
              : false,
            variance: remaining,
          };
        },
      );

      // Calculate totals
      const totalAllocated = categories.reduce(
        (sum: number, cat: any) => sum + cat.allocated,
        0,
      );
      const totalSpent = categories.reduce(
        (sum: number, cat: any) => sum + cat.spent,
        0,
      );
      const totalRemaining = totalAllocated - totalSpent;
      const overallPercentUsed =
        totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

      // Get currency from budget or fetch user preferences
      const currency = budgetData?.currency || (await fetchUserPreferences(userId)).currency;

      return {
        success: true,
        budget: {
          id: budget.id,
          ...budgetData,
        },
        categories,
        total_allocated: totalAllocated,
        total_spent: totalSpent,
        total_remaining: totalRemaining,
        overall_percent_used: overallPercentUsed,
        currency, // Return currency for proper formatting
      };
    } catch (error) {
      console.error('Error calculating budget progress:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        'Failed to calculate budget progress',
      );
    }
  },
);
