/**
 * Category Service
 * Manages transaction categories with Firebase Cloud Functions
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';
import type { Category } from '@/core/types';

class CategoryService {
  /**
   * Get all categories (default + custom)
   */
  async getCategories(type?: 'income' | 'expense' | 'all'): Promise<Category[]> {
    try {
      const getCategoriesFn = httpsCallable<
        { type?: 'income' | 'expense' | 'all' },
        {
          success: boolean;
          categories: Category[];
          total: number;
          custom_count: number;
          default_count: number;
        }
      >(functions, 'getCategories');

      const result = await getCategoriesFn({ type: type || 'all' });
      return result.data.categories;
    } catch (error) {
      console.error('Error fetching categories:', error);
      return [];
    }
  }

  /**
   * Get a specific category by ID
   */
  async getCategoryById(categoryId: string): Promise<Category | null> {
    try {
      const getCategoryFn = httpsCallable<
        { categoryId: string },
        { success: boolean; category: Category }
      >(functions, 'getCategoryById');

      const result = await getCategoryFn({ categoryId });
      return result.data.category;
    } catch (error) {
      console.error('Error fetching category:', error);
      return null;
    }
  }

  /**
   * Create a custom category
   */
  async createCategory(input: CreateCategoryInput): Promise<Category> {
    try {
      const createCategoryFn = httpsCallable<
        CreateCategoryInput,
        { success: boolean; categoryId: string; message: string }
      >(functions, 'createCategory');

      const result = await createCategoryFn(input);

      // Fetch the created category
      const category = await this.getCategoryById(result.data.categoryId);
      if (!category) {
        throw new Error('Failed to fetch created category');
      }

      return category;
    } catch (error) {
      console.error('Error creating category:', error);
      throw error;
    }
  }

  /**
   * Update a custom category
   */
  async updateCategory(
    categoryId: string,
    updates: UpdateCategoryInput,
  ): Promise<Category> {
    try {
      const updateCategoryFn = httpsCallable<
        { categoryId: string; updates: UpdateCategoryInput },
        { success: boolean; message: string }
      >(functions, 'updateCategory');

      await updateCategoryFn({ categoryId, updates });

      // Fetch the updated category
      const category = await this.getCategoryById(categoryId);
      if (!category) {
        throw new Error('Failed to fetch updated category');
      }

      return category;
    } catch (error) {
      console.error('Error updating category:', error);
      throw error;
    }
  }

  /**
   * Delete a custom category
   */
  async deleteCategory(categoryId: string): Promise<void> {
    try {
      const deleteCategoryFn = httpsCallable<
        { categoryId: string },
        { success: boolean; message: string }
      >(functions, 'deleteCategory');

      await deleteCategoryFn({ categoryId });
    } catch (error) {
      console.error('Error deleting category:', error);
      throw error;
    }
  }

  /**
   * Get category usage count
   */
  async getCategoryUsage(categoryId: string): Promise<number> {
    try {
      const getUsageFn = httpsCallable<
        { categoryId: string },
        { success: boolean; categoryId: string; usageCount: number }
      >(functions, 'getCategoryUsage');

      const result = await getUsageFn({ categoryId });
      return result.data.usageCount;
    } catch (error) {
      console.error('Error getting category usage:', error);
      return 0;
    }
  }
}

// Export types and constants for compatibility
export type { Category } from '@/core/types';
export type CategoryType = 'income' | 'expense';
export interface CreateCategoryInput {
  name: string;
  type: CategoryType;
  icon?: string;
  color?: string;
}
export type UpdateCategoryInput = Partial<CreateCategoryInput>;

// Export service instance and convenience functions
export const categoryService = new CategoryService();

export const getAllCategories = () => categoryService.getCategories('all');

export const getCategoriesByType = (type: CategoryType) =>
  categoryService.getCategories(type);

export const getCategoryById = (id: string) =>
  categoryService.getCategoryById(id);

export const createCategory = (input: CreateCategoryInput) =>
  categoryService.createCategory(input);

export const updateCategory = (id: string, input: UpdateCategoryInput) =>
  categoryService.updateCategory(id, input);

export const deleteCategory = (id: string) =>
  categoryService.deleteCategory(id);

export const getCategoryUsage = (id: string) =>
  categoryService.getCategoryUsage(id);

export default categoryService;

