import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { AppError, authError, ErrorCodes, validationError } from './errors';
import {
  addGoalContributionSchema,
  createGoalSchema,
  safeValidate,
  updateGoalSchema,
} from './schemas';

const db = admin.firestore();

/**
 * Create a new goal
 */
export const createGoal = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw authError(ErrorCodes.AUTH_UNAUTHENTICATED);
  }

  const userId = request.auth.uid;

  // Validate input with Zod
  const validation = safeValidate(createGoalSchema, request.data);
  if (!validation.success) {
    throw validationError(ErrorCodes.VALIDATION_INVALID_FORMAT, undefined, {
      errors: validation.errors.issues,
    });
  }

  const goalData = validation.data;

  try {
    const goalRef = db.collection('goals').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const goal = {
      user_id: userId,
      name: goalData.name,
      target_amount: goalData.target_amount,
      current_amount: goalData.current_amount || 0,
      target_date: goalData.target_date
        ? admin.firestore.Timestamp.fromDate(new Date(goalData.target_date))
        : null,
      priority: goalData.priority || 'medium',
      category: goalData.category || null,
      description: goalData.description || null,
      status: 'active',
      created_at: now,
      updated_at: now,
    };

    await goalRef.set(goal);

    return {
      id: goalRef.id,
      ...goal,
      created_at: new Date(),
      updated_at: new Date(),
    };
  } catch (error: any) {
    console.error('Error creating goal:', error);
    // Re-throw AppError instances
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      ErrorCodes.OPERATION_FAILED,
      'Failed to create goal',
      'internal',
      { originalError: error.message },
    );
  }
});

/**
 * Update an existing goal
 */
export const updateGoal = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;

  // Validate input with Zod
  const validation = safeValidate(updateGoalSchema, request.data);
  if (!validation.success) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid update data: ${JSON.stringify(validation.errors.issues)}`,
    );
  }

  const { goalId, updates } = validation.data;

  try {
    const goalRef = db.collection('goals').doc(goalId);
    const goalDoc = await goalRef.get();

    if (!goalDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Goal not found');
    }

    const goalData = goalDoc.data();
    if (goalData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to update this goal',
      );
    }

    const updateData: any = {
      ...updates,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Convert target_date to Timestamp if provided
    if (updates.target_date) {
      updateData.target_date = admin.firestore.Timestamp.fromDate(
        new Date(updates.target_date),
      );
    }

    await goalRef.update(updateData);

    return {
      id: goalId,
      ...goalData,
      ...updates,
      updated_at: new Date(),
    };
  } catch (error: any) {
    console.error('Error updating goal:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update goal',
      error.message,
    );
  }
});

/**
 * Delete a goal
 */
export const deleteGoal = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { goalId } = request.data as { goalId: string };

  if (!goalId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Goal ID is required',
    );
  }

  try {
    const goalRef = db.collection('goals').doc(goalId);
    const goalDoc = await goalRef.get();

    if (!goalDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Goal not found');
    }

    const goalData = goalDoc.data();
    if (goalData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to delete this goal',
      );
    }

    // Delete all goal contributions
    const contributionsSnapshot = await db
      .collection('goal_contributions')
      .where('goal_id', '==', goalId)
      .get();

    const batch = db.batch();
    contributionsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    batch.delete(goalRef);

    await batch.commit();

    return { success: true, goalId };
  } catch (error: any) {
    console.error('Error deleting goal:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to delete goal',
      error.message,
    );
  }
});

/**
 * Calculate goal progress and statistics
 */
export const calculateGoalProgress = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { goalId } = request.data as { goalId: string };

  if (!goalId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Goal ID is required',
    );
  }

  try {
    const goalRef = db.collection('goals').doc(goalId);
    const goalDoc = await goalRef.get();

    if (!goalDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Goal not found');
    }

    const goalData = goalDoc.data();
    if (goalData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to view this goal',
      );
    }

    // Get all contributions
    const contributionsSnapshot = await db
      .collection('goal_contributions')
      .where('goal_id', '==', goalId)
      .orderBy('date', 'desc')
      .get();

    const contributions = contributionsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      date: doc.data().date.toDate().toISOString(),
    }));

    const totalContributions = contributions.reduce(
      (sum, c: any) => sum + c.amount,
      0,
    );
    const currentAmount = goalData?.current_amount || 0;
    const targetAmount = goalData?.target_amount || 0;
    const progress =
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

    // Calculate estimated completion date
    let estimatedCompletionDate = null;
    if (contributions.length >= 2 && progress < 100) {
      // Calculate average monthly contribution from recent contributions
      const recentContributions = contributions.slice(
        0,
        Math.min(6, contributions.length),
      );
      const totalRecent = recentContributions.reduce(
        (sum, c: any) => sum + c.amount,
        0,
      );
      const monthsSpan =
        recentContributions.length > 1
          ? Math.max(
              1,
              (new Date(recentContributions[0].date).getTime() -
                new Date(
                  recentContributions[recentContributions.length - 1].date,
                ).getTime()) /
                (1000 * 60 * 60 * 24 * 30),
            )
          : 1;

      const avgMonthlyContribution = totalRecent / monthsSpan;

      if (avgMonthlyContribution > 0) {
        const remainingAmount = targetAmount - currentAmount;
        const monthsToComplete = remainingAmount / avgMonthlyContribution;
        const completionDate = new Date();
        completionDate.setMonth(
          completionDate.getMonth() + Math.ceil(monthsToComplete),
        );
        estimatedCompletionDate = completionDate.toISOString();
      }
    }

    // Calculate days remaining if target date is set
    let daysRemaining = null;
    let isOnTrack = null;
    if (goalData?.target_date) {
      const targetDate = goalData.target_date.toDate();
      const today = new Date();
      daysRemaining = Math.ceil(
        (targetDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
      );

      // Check if on track (current progress vs time progress)
      const startDate = goalData.created_at.toDate();
      const totalDays =
        (targetDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
      const daysElapsed =
        (today.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
      const expectedProgress =
        totalDays > 0 ? (daysElapsed / totalDays) * 100 : 0;
      isOnTrack = progress >= expectedProgress - 5; // 5% tolerance
    }

    return {
      goalId,
      name: goalData?.name,
      currentAmount,
      targetAmount,
      progress: Math.min(100, Math.round(progress * 100) / 100),
      contributions: contributions.length,
      totalContributions,
      estimatedCompletionDate,
      daysRemaining,
      isOnTrack,
      status: goalData?.status,
      recentContributions: contributions.slice(0, 5), // Last 5 contributions
    };
  } catch (error: any) {
    console.error('Error calculating goal progress:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to calculate goal progress',
      error.message,
    );
  }
});

/**
 * Add contribution to a goal
 */
export const addGoalContribution = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;

  // Validate input with Zod
  const validation = safeValidate(addGoalContributionSchema, request.data);
  if (!validation.success) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid contribution data: ${JSON.stringify(validation.errors.issues)}`,
    );
  }

  const { goalId, amount, date, notes } = validation.data;

  try {
    const goalRef = db.collection('goals').doc(goalId);
    const goalDoc = await goalRef.get();

    if (!goalDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Goal not found');
    }

    const goalData = goalDoc.data();
    if (goalData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Not authorized to contribute to this goal',
      );
    }

    const contributionRef = db.collection('goal_contributions').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const contributionDate = date
      ? admin.firestore.Timestamp.fromDate(new Date(date))
      : now;

    const contribution = {
      goal_id: goalId,
      amount,
      date: contributionDate,
      notes: notes || null,
      created_at: now,
    };

    // Update goal current_amount
    const newCurrentAmount = (goalData?.current_amount || 0) + amount;
    const newStatus =
      newCurrentAmount >= goalData?.target_amount
        ? 'completed'
        : goalData?.status;

    const batch = db.batch();
    batch.set(contributionRef, contribution);
    batch.update(goalRef, {
      current_amount: newCurrentAmount,
      status: newStatus,
      updated_at: now,
    });

    await batch.commit();

    return {
      id: contributionRef.id,
      ...contribution,
      created_at: new Date(),
      date: date || new Date(),
      goalUpdated: {
        current_amount: newCurrentAmount,
        status: newStatus,
      },
    };
  } catch (error: any) {
    console.error('Error adding goal contribution:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to add goal contribution',
      error.message,
    );
  }
});
