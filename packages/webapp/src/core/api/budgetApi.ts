import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

/**
 * Budget Types (matching Cloud Functions interface)
 */
export interface BudgetCategory {
  category: string;
  allocated_amount: number;
  alert_threshold?: number;
  notes?: string;
}

export interface CreateBudgetData {
  name: string;
  description?: string;
  period_type: 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event';
  start_date: string;
  end_date?: string;
  is_recurring: boolean;
  rollover_enabled: boolean;
  categories: BudgetCategory[];
}

export interface UpdateBudgetData {
  budgetId: string;
  updates: Partial<Omit<CreateBudgetData, 'categories'>>;
}

export interface BudgetProgressData {
  budgetId: string;
}

/**
 * Cloud Functions API
 */
export const budgetFunctions = {
  /**
   * Create a new budget with categories
   */
  createBudget: async (data: CreateBudgetData) => {
    const callable = httpsCallable(functions, 'createBudget');
    const result = await callable(data);
    return result.data;
  },

  /**
   * Update an existing budget
   */
  updateBudget: async (data: UpdateBudgetData) => {
    const callable = httpsCallable(functions, 'updateBudget');
    const result = await callable(data);
    return result.data;
  },

  /**
   * Delete a budget
   */
  deleteBudget: async (budgetId: string) => {
    const callable = httpsCallable(functions, 'deleteBudget');
    const result = await callable({ budgetId });
    return result.data;
  },

  /**
   * Calculate budget progress and spending
   */
  calculateBudgetProgress: async (budgetId: string) => {
    const callable = httpsCallable(functions, 'calculateBudgetProgress');
    const result = await callable({ budgetId });
    return result.data;
  },
};

/**
 * Budget templates (client-side only, no Cloud Function needed)
 */
export const getBudgetTemplates = () => {
  return [
    {
      name: '50/30/20 Rule',
      description: 'Balanced budget: 50% needs, 30% wants, 20% savings',
      period_type: 'monthly' as const,
      categories: [
        { category: 'Rent', percent: 25 },
        { category: 'Bills & Utilities', percent: 10 },
        { category: 'Food & Dining', percent: 15 },
        { category: 'Shopping', percent: 15 },
        { category: 'Entertainment', percent: 15 },
        { category: 'Savings', percent: 20 },
      ],
    },
    {
      name: 'Festival Budget',
      description: 'Special budget for festival season',
      period_type: 'monthly' as const,
      categories: [
        { category: 'Shopping', percent: 30 },
        { category: 'Food & Dining', percent: 20 },
        { category: 'Gift', percent: 20 },
        { category: 'Transportation', percent: 15 },
        { category: 'Entertainment', percent: 15 },
      ],
    },
    {
      name: 'Student Budget',
      description: 'Budget optimized for students',
      period_type: 'monthly' as const,
      categories: [
        { category: 'Education', percent: 40 },
        { category: 'Food & Dining', percent: 25 },
        { category: 'Transportation', percent: 15 },
        { category: 'Entertainment', percent: 10 },
        { category: 'Savings', percent: 10 },
      ],
    },
    {
      name: 'Family Budget',
      description: 'Comprehensive family budget',
      period_type: 'monthly' as const,
      categories: [
        { category: 'Rent', percent: 30 },
        { category: 'Food & Dining', percent: 20 },
        { category: 'Bills & Utilities', percent: 10 },
        { category: 'Education', percent: 10 },
        { category: 'Healthcare', percent: 10 },
        { category: 'Savings', percent: 15 },
        { category: 'Other Expense', percent: 5 },
      ],
    },
  ];
};
