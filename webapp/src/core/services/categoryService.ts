/**
 * Category Management Service
 * Handles CRUD operations for transaction categories
 */

import { db } from '../db';

export interface Category {
  id: string;
  name: string;
  type: 'income' | 'expense';
  icon?: string;
  color?: string;
  parent_id?: string;
  is_default: boolean;
  created_at: string;
}

export interface CreateCategoryInput {
  name: string;
  type: 'income' | 'expense';
  icon?: string;
  color?: string;
  parent_id?: string;
}

/**
 * Get all categories
 */
export async function getAllCategories(): Promise<Category[]> {
  try {
    const result = await db.query(
      'SELECT * FROM categories ORDER BY type, name'
    );
    return result.rows as Category[];
  } catch (error) {
    console.error('Error fetching categories:', error);
    throw new Error('Failed to fetch categories');
  }
}

/**
 * Get categories by type
 */
export async function getCategoriesByType(
  type: 'income' | 'expense'
): Promise<Category[]> {
  try {
    const result = await db.query(
      'SELECT * FROM categories WHERE type = $1 ORDER BY name',
      [type]
    );
    return result.rows as Category[];
  } catch (error) {
    console.error('Error fetching categories by type:', error);
    throw new Error('Failed to fetch categories');
  }
}

/**
 * Create a new category
 */
export async function createCategory(
  input: CreateCategoryInput
): Promise<Category> {
  try {
    const result = await db.query(
      `INSERT INTO categories (name, type, icon, color, parent_id, is_default)
       VALUES ($1, $2, $3, $4, $5, false)
       RETURNING *`,
      [input.name, input.type, input.icon, input.color, input.parent_id]
    );
    return result.rows[0] as Category;
  } catch (error) {
    console.error('Error creating category:', error);
    throw new Error('Failed to create category');
  }
}

/**
 * Update a category
 */
export async function updateCategory(
  id: string,
  input: Partial<CreateCategoryInput>
): Promise<Category> {
  try {
    const fields: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (input.name !== undefined) {
      fields.push(`name = $${paramCount++}`);
      values.push(input.name);
    }
    if (input.type !== undefined) {
      fields.push(`type = $${paramCount++}`);
      values.push(input.type);
    }
    if (input.icon !== undefined) {
      fields.push(`icon = $${paramCount++}`);
      values.push(input.icon);
    }
    if (input.color !== undefined) {
      fields.push(`color = $${paramCount++}`);
      values.push(input.color);
    }
    if (input.parent_id !== undefined) {
      fields.push(`parent_id = $${paramCount++}`);
      values.push(input.parent_id);
    }

    if (fields.length === 0) {
      throw new Error('No fields to update');
    }

    values.push(id);

    const result = await db.query(
      `UPDATE categories SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new Error('Category not found');
    }

    return result.rows[0] as Category;
  } catch (error) {
    console.error('Error updating category:', error);
    throw new Error('Failed to update category');
  }
}

/**
 * Delete a category
 */
export async function deleteCategory(id: string): Promise<void> {
  try {
    // Check if category is default
    const category = await db.query(
      'SELECT is_default FROM categories WHERE id = $1',
      [id]
    );

    if (category.rows.length === 0) {
      throw new Error('Category not found');
    }

    if ((category.rows[0] as Category).is_default) {
      throw new Error('Cannot delete default category');
    }

    // Delete category
    await db.query('DELETE FROM categories WHERE id = $1', [id]);
  } catch (error) {
    console.error('Error deleting category:', error);
    throw new Error('Failed to delete category');
  }
}

/**
 * Get default categories for initialization
 */
export function getDefaultCategories(): CreateCategoryInput[] {
  return [
    // Income categories
    { name: 'Salary', type: 'income', icon: '💼', color: '#10B981' },
    { name: 'Freelance', type: 'income', icon: '💻', color: '#10B981' },
    { name: 'Investment Returns', type: 'income', icon: '📈', color: '#10B981' },
    { name: 'Business', type: 'income', icon: '🏢', color: '#10B981' },
    { name: 'Rental Income', type: 'income', icon: '🏠', color: '#10B981' },
    { name: 'Other Income', type: 'income', icon: '💰', color: '#10B981' },

    // Expense categories
    { name: 'Food & Dining', type: 'expense', icon: '🍔', color: '#EF4444' },
    { name: 'Groceries', type: 'expense', icon: '🛒', color: '#EF4444' },
    { name: 'Transportation', type: 'expense', icon: '🚗', color: '#EF4444' },
    { name: 'Shopping', type: 'expense', icon: '🛍️', color: '#EF4444' },
    { name: 'Entertainment', type: 'expense', icon: '🎬', color: '#EF4444' },
    { name: 'Bills & Utilities', type: 'expense', icon: '📄', color: '#EF4444' },
    { name: 'Healthcare', type: 'expense', icon: '🏥', color: '#EF4444' },
    { name: 'Education', type: 'expense', icon: '📚', color: '#EF4444' },
    { name: 'Travel', type: 'expense', icon: '✈️', color: '#EF4444' },
    { name: 'Rent', type: 'expense', icon: '🏠', color: '#EF4444' },
    { name: 'Insurance', type: 'expense', icon: '🛡️', color: '#EF4444' },
    { name: 'Subscriptions', type: 'expense', icon: '📱', color: '#EF4444' },
    { name: 'Other Expenses', type: 'expense', icon: '💸', color: '#EF4444' },
  ];
}

/**
 * Initialize default categories
 */
export async function initializeDefaultCategories(): Promise<void> {
  try {
    const defaultCategories = getDefaultCategories();
    
    for (const category of defaultCategories) {
      await db.query(
        `INSERT INTO categories (name, type, icon, color, is_default)
         VALUES ($1, $2, $3, $4, true)
         ON CONFLICT (name) DO NOTHING`,
        [category.name, category.type, category.icon, category.color]
      );
    }
  } catch (error) {
    console.error('Error initializing default categories:', error);
    throw new Error('Failed to initialize default categories');
  }
}
