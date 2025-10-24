/**
 * Budget Service
 * Handles all budget-related operations including CRUD, calculations, and alerts
 */

// import { transactionRepository } from '../db/repositories';
import type {
  Budget,
  BudgetAlert,
  BudgetCategory,
  BudgetFilters,
  //   BudgetHistory,
  BudgetProgress,
  BudgetStatus,
  CategorySpending,
  CreateBudgetCategoryInput,
  CreateBudgetInput,
  UpdateBudgetCategoryInput,
  UpdateBudgetInput,
} from '../db/types';

class BudgetService {
  /**
   * Create a new budget with categories
   */
  async createBudget(
    budgetData: CreateBudgetInput,
    categories: Omit<CreateBudgetCategoryInput, 'budget_id'>[]
  ): Promise<{ budget: Budget; categories: BudgetCategory[] }> {
    // Create the budget
    const budget = await this.createBudgetOnly(budgetData);

    // Create budget categories
    const createdCategories: BudgetCategory[] = [];
    for (const category of categories) {
      const budgetCategory = await this.createBudgetCategory({
        ...category,
        budget_id: budget.id,
      });
      createdCategories.push(budgetCategory);
    }

    return { budget, categories: createdCategories };
  }

  /**
   * Create budget without categories (internal use)
   */
  private async createBudgetOnly(
    budgetData: CreateBudgetInput
  ): Promise<Budget> {
    // TODO: Implement database insert
    // For now, return mock data
    const budget: Budget = {
      id: crypto.randomUUID(),
      ...budgetData,
      created_at: new Date(),
      updated_at: new Date(),
    };
    return budget;
  }

  /**
   * Create a budget category
   */
  async createBudgetCategory(
    categoryData: CreateBudgetCategoryInput
  ): Promise<BudgetCategory> {
    // TODO: Implement database insert
    const category: BudgetCategory = {
      id: crypto.randomUUID(),
      ...categoryData,
      created_at: new Date(),
      updated_at: new Date(),
    };
    return category;
  }

  /**
   * Get budget by ID with its categories
   */
  async getBudget(
    budgetId: string
  ): Promise<{ budget: Budget; categories: BudgetCategory[] } | null> {
    // TODO: Implement database query
    console.log(budgetId);
    return null;
  }

  /**
   * List all budgets with optional filters
   */
  async listBudgets(filters?: BudgetFilters): Promise<Budget[]> {
    // TODO: Implement database query with filters
    console.log(filters);
    return [];
  }

  /**
   * Update budget
   */
  async updateBudget(
    id: string,
    updates: Omit<UpdateBudgetInput, 'id'>
  ): Promise<Budget> {
    // TODO: Implement database update
    const budget: Budget = {
      id,
      ...updates,
      created_at: new Date(),
      updated_at: new Date(),
    } as Budget;
    return budget;
  }

  /**
   * Update budget category
   */
  async updateBudgetCategory(
    id: string,
    updates: Omit<UpdateBudgetCategoryInput, 'id'>
  ): Promise<BudgetCategory> {
    // TODO: Implement database update
    const category: BudgetCategory = {
      id,
      ...updates,
      created_at: new Date(),
      updated_at: new Date(),
    } as BudgetCategory;
    return category;
  }

  /**
   * Delete budget (cascades to categories)
   */
  async deleteBudget(id: string): Promise<void> {
    // TODO: Implement database delete
    console.log(`Deleting budget: ${id}`);
  }

  /**
   * Delete budget category
   */
  async deleteBudgetCategory(id: string): Promise<void> {
    // TODO: Implement database delete
    console.log(`Deleting budget category: ${id}`);
  }

  /**
   * Calculate budget progress for a specific budget
   */
  async calculateBudgetProgress(budgetId: string): Promise<BudgetProgress[]> {
    const result = await this.getBudget(budgetId);
    if (!result) {
      throw new Error(`Budget not found: ${budgetId}`);
    }

    const { budget, categories } = result;
    const progress: BudgetProgress[] = [];

    for (const category of categories) {
      // Get spending for this category in budget period
      const spending = await this.getCategorySpending(
        category.category,
        budget.start_date,
        budget.end_date || new Date()
      );

      const spent = spending.spent;
      const allocated = category.allocated_amount;
      const remaining = allocated - spent;
      const percentUsed = allocated > 0 ? (spent / allocated) * 100 : 0;

      // Determine status
      let status: 'on-track' | 'warning' | 'over-budget';
      if (spent > allocated) {
        status = 'over-budget';
      } else if (percentUsed >= category.alert_threshold * 100) {
        status = 'warning';
      } else {
        status = 'on-track';
      }

      progress.push({
        budget_id: budgetId,
        category: category.category,
        allocated,
        spent,
        remaining,
        percent_used: percentUsed,
        status,
        is_over_budget: spent > allocated,
        variance: spent - allocated,
      });
    }

    return progress;
  }

  /**
   * Get comprehensive budget status
   */
  async getBudgetStatus(budgetId: string): Promise<BudgetStatus> {
    const result = await this.getBudget(budgetId);
    if (!result) {
      throw new Error(`Budget not found: ${budgetId}`);
    }

    const { budget, categories: budgetCategories } = result;
    const progress = await this.calculateBudgetProgress(budgetId);

    // Calculate totals
    const totalAllocated = budgetCategories.reduce(
      (sum, cat) => sum + cat.allocated_amount,
      0
    );
    const totalSpent = progress.reduce((sum, p) => sum + p.spent, 0);
    const totalRemaining = totalAllocated - totalSpent;
    const overallPercentUsed =
      totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

    // Generate alerts
    const alerts = await this.checkBudgetAlerts(budgetId);

    // Count categories by status
    const categoriesOverBudget = progress.filter(
      (p) => p.status === 'over-budget'
    ).length;
    const categoriesAtWarning = progress.filter(
      (p) => p.status === 'warning'
    ).length;

    return {
      budget,
      categories: progress,
      total_allocated: totalAllocated,
      total_spent: totalSpent,
      total_remaining: totalRemaining,
      overall_percent_used: overallPercentUsed,
      alerts,
      categories_over_budget: categoriesOverBudget,
      categories_at_warning: categoriesAtWarning,
    };
  }

  /**
   * Get spending by category for a date range
   */
  async getCategorySpending(
    category: string,
    startDate: Date,
    endDate: Date
  ): Promise<CategorySpending> {
    // Query transactions for this category in date range
    // const transactions = await transactionRepository.find({
    //   category,
    //   dateRange: { start: startDate, end: endDate },
    //   type: 'expense',
    // });
    console.log(category, startDate, endDate);

    // const spent = transactions.reduce((sum, txn) => sum + txn.amount, 0);

    return {
      category,
      spent: 0,
      transaction_count: 0, //transactions.length,
    };
  }

  /**
   * Get spending by multiple categories
   */
  async getSpendingByCategory(budgetId: string): Promise<CategorySpending[]> {
    const result = await this.getBudget(budgetId);
    if (!result) {
      throw new Error(`Budget not found: ${budgetId}`);
    }

    const { budget, categories } = result;
    const spending: CategorySpending[] = [];

    for (const category of categories) {
      const categorySpending = await this.getCategorySpending(
        category.category,
        budget.start_date,
        budget.end_date || new Date()
      );
      spending.push(categorySpending);
    }

    return spending;
  }

  /**
   * Check for budget alerts
   */
  async checkBudgetAlerts(budgetId: string): Promise<BudgetAlert[]> {
    const progress = await this.calculateBudgetProgress(budgetId);
    const alerts: BudgetAlert[] = [];

    for (const item of progress) {
      if (item.is_over_budget) {
        alerts.push({
          budget_id: budgetId,
          category: item.category,
          alert_type: 'exceeded',
          message: `Budget exceeded by ₹${Math.abs(item.variance).toFixed(2)}`,
          percent_used: item.percent_used,
          severity: 'error',
        });
      } else if (item.status === 'warning') {
        alerts.push({
          budget_id: budgetId,
          category: item.category,
          alert_type: 'threshold',
          message: `${item.percent_used.toFixed(0)}% of budget used`,
          percent_used: item.percent_used,
          severity: 'warning',
        });
      } else if (item.percent_used >= 70) {
        alerts.push({
          budget_id: budgetId,
          category: item.category,
          alert_type: 'approaching',
          message: `Approaching budget limit (${item.percent_used.toFixed(0)}%)`,
          percent_used: item.percent_used,
          severity: 'info',
        });
      }
    }

    return alerts;
  }

  /**
   * Get all budgets that need attention (alerts)
   */
  async getBudgetsNeedingAttention(): Promise<Budget[]> {
    const allBudgets = await this.listBudgets({ is_active: true });
    const budgetsNeedingAttention: Budget[] = [];

    for (const budget of allBudgets) {
      const alerts = await this.checkBudgetAlerts(budget.id);
      if (alerts.length > 0) {
        budgetsNeedingAttention.push(budget);
      }
    }

    return budgetsNeedingAttention;
  }

  /**
   * Create budget history record
   */
  async createBudgetHistory(
    budgetId: string,
    periodStart: Date,
    periodEnd: Date
  ): Promise<void> {
    const result = await this.getBudget(budgetId);
    if (!result) {
      throw new Error(`Budget not found: ${budgetId}`);
    }
    console.log(periodStart, periodEnd);

    // const { categories } = result;

    // for (const category of categories) {
    //   const spending = await this.getCategorySpending(
    //     category.category,
    //     periodStart,
    //     periodEnd
    //   );

    //   const history: Omit<BudgetHistory, 'id' | 'created_at'> = {
    //     budget_id: budgetId,
    //     category: category.category,
    //     period_start: periodStart,
    //     period_end: periodEnd,
    //     allocated: category.allocated_amount,
    //     spent: spending.spent,
    //     variance: spending.spent - category.allocated_amount,
    //     rollover_from_previous: 0, // TODO: Calculate from previous period
    //     notes: undefined,
    //   };

    // TODO: Insert into database
    // }
  }

  /**
   * Get budget templates
   */
  getBudgetTemplates(): Array<{
    name: string;
    description: string;
    period_type: 'monthly' | 'annual';
    categories: Array<{ category: string; percent: number }>;
  }> {
    return [
      {
        name: '50/30/20 Rule',
        description: 'Balanced budget: 50% needs, 30% wants, 20% savings',
        period_type: 'monthly',
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
        period_type: 'monthly',
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
        period_type: 'monthly',
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
        period_type: 'monthly',
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
  }

  /**
   * Create budget from template
   */
  async createFromTemplate(
    templateName: string,
    budgetName: string,
    totalAmount: number,
    startDate: Date,
    endDate?: Date
  ): Promise<{ budget: Budget; categories: BudgetCategory[] }> {
    const templates = this.getBudgetTemplates();
    const template = templates.find((t) => t.name === templateName);

    if (!template) {
      throw new Error(`Template not found: ${templateName}`);
    }

    // Create budget
    const budgetData: CreateBudgetInput = {
      name: budgetName,
      description: `Created from template: ${template.description}`,
      period_type: template.period_type,
      start_date: startDate,
      end_date: endDate,
      is_recurring: template.period_type === 'monthly',
      rollover_enabled: false,
      rollover_amount: 0,
      is_active: true,
    };

    // Create categories with calculated amounts
    const categories = template.categories.map((cat) => ({
      category: cat.category,
      allocated_amount: (totalAmount * cat.percent) / 100,
      alert_threshold: 0.8,
      notes: undefined,
    }));

    return this.createBudget(budgetData, categories);
  }
}

export const budgetService = new BudgetService();
