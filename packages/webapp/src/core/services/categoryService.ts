/**
 * Category Service - STUB IMPLEMENTATION
 * Original functionality depends on PGlite repositories which have been removed
 * TODO: Implement with Firebase when needed
 */

import type { Category } from '@/core/types';

class CategoryService {
  async getCategories(): Promise<Category[]> {
    return [];
  }

  async getCategoryById(): Promise<Category | null> {
    return null;
  }

  async createCategory(): Promise<Category> {
    throw new Error('Category service not implemented with Firebase');
  }

  async updateCategory(): Promise<Category> {
    throw new Error('Category service not implemented with Firebase');
  }

  async deleteCategory(): Promise<void> {
    throw new Error('Category service not implemented with Firebase');
  }

  async getCategoryUsage(): Promise<number> {
    return 0;
  }
}

// Export types and constants for compatibility
export type { Category } from '@/core/types';
export type CategoryType = 'income' | 'expense';
export interface CreateCategoryInput {
  user_id?: string; // Optional - will be filled by service
  name: string;
  type: CategoryType;
  icon?: string;
  color?: string;
  is_default?: boolean;
}
export type UpdateCategoryInput = Partial<Omit<CreateCategoryInput, 'user_id'>>;

// Export service instance and convenience functions
export const categoryService = new CategoryService();
export const getAllCategories = () => categoryService.getCategories();
export const getCategoriesByType = (_type: CategoryType) => categoryService.getCategories();
export const getCategoryById = (_id: string) => categoryService.getCategoryById();
export const createCategory = (_input: CreateCategoryInput) => categoryService.createCategory();
export const updateCategory = (_id: string, _input: UpdateCategoryInput) => categoryService.updateCategory();
export const deleteCategory = (_id: string) => categoryService.deleteCategory();
export const getCategoryUsage = (_id: string) => categoryService.getCategoryUsage();

export default categoryService;
