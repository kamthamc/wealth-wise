import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();

// Default categories for Indian context
const DEFAULT_CATEGORIES = {
  expense: [
    { name: 'Food & Dining', icon: '🍽️', color: '#FF6B6B' },
    { name: 'Groceries', icon: '🛒', color: '#4ECDC4' },
    { name: 'Transportation', icon: '🚗', color: '#45B7D1' },
    { name: 'Shopping', icon: '🛍️', color: '#96CEB4' },
    { name: 'Entertainment', icon: '🎬', color: '#FFEAA7' },
    { name: 'Healthcare', icon: '⚕️', color: '#DFE6E9' },
    { name: 'Education', icon: '📚', color: '#74B9FF' },
    { name: 'Bills & Utilities', icon: '💡', color: '#A29BFE' },
    { name: 'Rent', icon: '🏠', color: '#FD79A8' },
    { name: 'EMI', icon: '💳', color: '#FDCB6E' },
    { name: 'Insurance', icon: '🛡️', color: '#6C5CE7' },
    { name: 'Mobile & Internet', icon: '📱', color: '#00B894' },
    { name: 'Fuel', icon: '⛽', color: '#00CEC9' },
    { name: 'Maintenance', icon: '🔧', color: '#B2BEC3' },
    { name: 'Personal Care', icon: '💆', color: '#FFA7C4' },
    { name: 'Gifts & Donations', icon: '🎁', color: '#E17055' },
    { name: 'Travel', icon: '✈️', color: '#0984E3' },
    { name: 'Subscriptions', icon: '📺', color: '#D63031' },
    { name: 'Taxes', icon: '🏛️', color: '#2D3436' },
    { name: 'Other', icon: '📝', color: '#636E72' },
  ],
  income: [
    { name: 'Salary', icon: '💰', color: '#00B894' },
    { name: 'Business Income', icon: '💼', color: '#0984E3' },
    { name: 'Freelance', icon: '💻', color: '#6C5CE7' },
    { name: 'Investment Returns', icon: '📈', color: '#FDCB6E' },
    { name: 'Dividend', icon: '💵', color: '#00CEC9' },
    { name: 'Interest', icon: '🏦', color: '#74B9FF' },
    { name: 'Rental Income', icon: '🏘️', color: '#A29BFE' },
    { name: 'Bonus', icon: '🎉', color: '#FD79A8' },
    { name: 'Gift', icon: '🎁', color: '#FFEAA7' },
    { name: 'Refund', icon: '↩️', color: '#DFE6E9' },
    { name: 'Other', icon: '📝', color: '#636E72' },
  ],
};

/**
 * Get all categories (default + custom user categories)
 */
export const getCategories = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { type } = request.data as { type?: 'income' | 'expense' | 'all' };

  try {
    // Get custom user categories
    let query = db
      .collection('categories')
      .where('user_id', '==', userId)
      .where('is_default', '==', false);

    if (type && type !== 'all') {
      query = query.where('type', '==', type);
    }

    const customSnapshot = await query.orderBy('name').get();

    const customCategories = customSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      created_at: doc.data().created_at?.toDate().toISOString(),
      updated_at: doc.data().updated_at?.toDate().toISOString(),
    }));

    // Build default categories
    const defaultCategories = [];

    if (!type || type === 'all' || type === 'expense') {
      defaultCategories.push(
        ...DEFAULT_CATEGORIES.expense.map((cat, index) => ({
          id: `default_expense_${index}`,
          name: cat.name,
          type: 'expense',
          icon: cat.icon,
          color: cat.color,
          is_default: true,
          user_id: userId,
        })),
      );
    }

    if (!type || type === 'all' || type === 'income') {
      defaultCategories.push(
        ...DEFAULT_CATEGORIES.income.map((cat, index) => ({
          id: `default_income_${index}`,
          name: cat.name,
          type: 'income',
          icon: cat.icon,
          color: cat.color,
          is_default: true,
          user_id: userId,
        })),
      );
    }

    // Combine default and custom categories
    const allCategories = [...defaultCategories, ...customCategories];

    return {
      success: true,
      categories: allCategories,
      total: allCategories.length,
      custom_count: customCategories.length,
      default_count: defaultCategories.length,
    };
  } catch (error: any) {
    console.error('Error fetching categories:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch categories',
    );
  }
});

/**
 * Get a specific category by ID
 */
export const getCategoryById = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { categoryId } = request.data as { categoryId: string };

  if (!categoryId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Category ID is required',
    );
  }

  try {
    // Check if it's a default category
    if (categoryId.startsWith('default_')) {
      const [, typeStr, indexStr] = categoryId.split('_');
      const index = parseInt(indexStr, 10);
      const type = typeStr as 'income' | 'expense';

      const defaultCat = DEFAULT_CATEGORIES[type]?.[index];
      if (defaultCat) {
        return {
          success: true,
          category: {
            id: categoryId,
            name: defaultCat.name,
            type,
            icon: defaultCat.icon,
            color: defaultCat.color,
            is_default: true,
            user_id: userId,
          },
        };
      }

      throw new functions.https.HttpsError('not-found', 'Category not found');
    }

    // Fetch custom category
    const categoryDoc = await db.collection('categories').doc(categoryId).get();

    if (!categoryDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Category not found');
    }

    const categoryData = categoryDoc.data();

    // Verify ownership
    if (categoryData?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Access denied',
      );
    }

    return {
      success: true,
      category: {
        id: categoryDoc.id,
        ...categoryData,
        created_at: categoryData?.created_at?.toDate().toISOString(),
        updated_at: categoryData?.updated_at?.toDate().toISOString(),
      },
    };
  } catch (error: any) {
    console.error('Error fetching category:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch category',
    );
  }
});

/**
 * Create a custom category
 */
export const createCategory = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { name, type, icon, color } = request.data as {
    name: string;
    type: 'income' | 'expense';
    icon?: string;
    color?: string;
  };

  if (!name || !type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Name and type are required',
    );
  }

  if (type !== 'income' && type !== 'expense') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Type must be income or expense',
    );
  }

  try {
    // Check if category with same name already exists
    const existingSnapshot = await db
      .collection('categories')
      .where('user_id', '==', userId)
      .where('name', '==', name)
      .where('type', '==', type)
      .limit(1)
      .get();

    if (!existingSnapshot.empty) {
      throw new functions.https.HttpsError(
        'already-exists',
        'Category with this name already exists',
      );
    }

    // Create category
    const categoryRef = await db.collection('categories').add({
      user_id: userId,
      name,
      type,
      icon: icon || '📝',
      color: color || '#636E72',
      is_default: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      categoryId: categoryRef.id,
      message: 'Category created successfully',
    };
  } catch (error: any) {
    console.error('Error creating category:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create category',
    );
  }
});

/**
 * Update a custom category
 */
export const updateCategory = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { categoryId, updates } = request.data as {
    categoryId: string;
    updates: {
      name?: string;
      icon?: string;
      color?: string;
    };
  };

  if (!categoryId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Category ID is required',
    );
  }

  // Cannot update default categories
  if (categoryId.startsWith('default_')) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Cannot update default categories',
    );
  }

  try {
    const categoryRef = db.collection('categories').doc(categoryId);
    const categoryDoc = await categoryRef.get();

    if (!categoryDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Category not found');
    }

    // Verify ownership
    if (categoryDoc.data()?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Access denied',
      );
    }

    // Update category
    await categoryRef.update({
      ...updates,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: 'Category updated successfully',
    };
  } catch (error: any) {
    console.error('Error updating category:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update category',
    );
  }
});

/**
 * Delete a custom category
 */
export const deleteCategory = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { categoryId } = request.data as { categoryId: string };

  if (!categoryId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Category ID is required',
    );
  }

  // Cannot delete default categories
  if (categoryId.startsWith('default_')) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Cannot delete default categories',
    );
  }

  try {
    const categoryRef = db.collection('categories').doc(categoryId);
    const categoryDoc = await categoryRef.get();

    if (!categoryDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Category not found');
    }

    // Verify ownership
    if (categoryDoc.data()?.user_id !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Access denied',
      );
    }

    // Check if category is in use
    const usageCount = await getCategoryUsageCount(userId, categoryId);

    if (usageCount > 0) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Cannot delete category. It is used by ${usageCount} transaction(s)`,
      );
    }

    // Delete category
    await categoryRef.delete();

    return {
      success: true,
      message: 'Category deleted successfully',
    };
  } catch (error: any) {
    console.error('Error deleting category:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Failed to delete category',
    );
  }
});

/**
 * Get category usage count (number of transactions using this category)
 */
export const getCategoryUsage = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const userId = request.auth.uid;
  const { categoryId } = request.data as { categoryId: string };

  if (!categoryId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Category ID is required',
    );
  }

  try {
    const count = await getCategoryUsageCount(userId, categoryId);

    return {
      success: true,
      categoryId,
      usageCount: count,
    };
  } catch (error: any) {
    console.error('Error getting category usage:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get category usage',
    );
  }
});

/**
 * Helper function to count category usage
 */
async function getCategoryUsageCount(
  userId: string,
  categoryId: string,
): Promise<number> {
  // For default categories, we need to check by name since transactions store category as string
  let categoryName = categoryId;

  if (categoryId.startsWith('default_')) {
    const [, typeStr, indexStr] = categoryId.split('_');
    const index = parseInt(indexStr, 10);
    const type = typeStr as 'income' | 'expense';
    const defaultCat = DEFAULT_CATEGORIES[type]?.[index];
    if (defaultCat) {
      categoryName = defaultCat.name;
    }
  } else {
    // Get custom category name
    const categoryDoc = await db.collection('categories').doc(categoryId).get();
    if (categoryDoc.exists) {
      categoryName = categoryDoc.data()?.name || categoryId;
    }
  }

  // Count transactions using this category
  const transactionsSnapshot = await db
    .collection('transactions')
    .where('user_id', '==', userId)
    .where('category', '==', categoryName)
    .limit(1000)
    .get();

  return transactionsSnapshot.size;
}
