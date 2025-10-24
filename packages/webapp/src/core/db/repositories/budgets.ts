/**
 * Budget repository
 * Handles all database operations for budgets
 */

import { db } from '../client';
import type { Budget, CreateBudgetInput, UpdateBudgetInput } from '../types';
import { BaseRepository } from './base';

class BudgetRepository extends BaseRepository<Budget> {
  constructor() {
    super('budgets');
  }

  /**
   * Create a new budget
   */
  async create(input: CreateBudgetInput): Promise<Budget> {
    const result = await db.query<Budget>(
      `INSERT INTO budgets (name, category, amount, period, start_date, end_date, alert_threshold, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        input.name,
        // input.category,
        // input.amount,
        // input.period,
        input.start_date,
        input.end_date || null,
        // input.alert_threshold || 80,
        input.is_active ?? true,
      ]
    );

    const budget = result.rows[0];
    if (!budget) {
      throw new Error('Failed to create budget');
    }
    return budget;
  }

  /**
   * Update a budget
   */
  async update(input: UpdateBudgetInput): Promise<Budget | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    // Build dynamic UPDATE query based on provided fields
    const updateFields = Object.entries(input).filter(
      ([key]) => key !== 'id' && key !== 'created_at' && key !== 'updated_at'
    );

    for (const [key, value] of updateFields) {
      fields.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }

    if (fields.length === 0) {
      return this.findById(input.id);
    }

    // Add updated_at timestamp
    fields.push(`updated_at = NOW()`);
    values.push(input.id);

    const result = await db.query<Budget>(
      `UPDATE budgets SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get all active budgets
   */
  async findActive(): Promise<Budget[]> {
    const result = await db.query<Budget>(
      'SELECT * FROM budgets WHERE is_active = true ORDER BY created_at DESC'
    );
    return result.rows;
  }

  /**
   * Get budgets by category
   */
  async findByCategory(category: string): Promise<Budget[]> {
    const result = await db.query<Budget>(
      'SELECT * FROM budgets WHERE category = $1 ORDER BY created_at DESC',
      [category]
    );
    return result.rows;
  }

  /**
   * Get budgets by period
   */
  async findByPeriod(period: string): Promise<Budget[]> {
    const result = await db.query<Budget>(
      'SELECT * FROM budgets WHERE period = $1 AND is_active = true ORDER BY created_at DESC',
      [period]
    );
    return result.rows;
  }

  /**
   * Get current active budgets (within date range)
   */
  async findCurrent(): Promise<Budget[]> {
    const result = await db.query<Budget>(
      `SELECT * FROM budgets 
       WHERE is_active = true 
       AND start_date <= CURRENT_DATE 
       AND (end_date IS NULL OR end_date >= CURRENT_DATE)
       ORDER BY created_at DESC`
    );
    return result.rows;
  }

  /**
   * Update spent amount for a budget
   */
  async updateSpent(id: string, amount: number): Promise<Budget | null> {
    const result = await db.query<Budget>(
      'UPDATE budgets SET spent = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [amount, id]
    );
    return result.rows[0] || null;
  }

  /**
   * Calculate spent amount from transactions for a budget
   */
  async calculateSpent(budgetId: string): Promise<number> {
    // Get budget details
    const budget = await this.findById(budgetId);
    if (!budget) {
      return 0;
    }

    // Calculate spent from transactions
    const result = await db.query<{ total: string }>(
      `SELECT COALESCE(SUM(amount), 0) as total 
       FROM transactions 
       AND type = 'expense'
       AND date >= $2 
       AND (CAST($3 AS DATE) IS NULL OR date <= $3)`,
      [budget.start_date, budget.end_date]
    );

    const spent = Number.parseFloat(result.rows[0]?.total || '0');

    // Update the budget's spent field
    await this.updateSpent(budgetId, spent);

    return spent;
  }

  /**
   * Get budgets nearing or exceeding threshold
   */
  async findNearingThreshold(): Promise<Budget[]> {
    const result = await db.query<Budget>(
      `SELECT * FROM budgets 
       WHERE is_active = true 
       AND (spent / amount * 100) >= alert_threshold
       ORDER BY (spent / amount * 100) DESC`
    );
    return result.rows;
  }
}

export const budgetRepository = new BudgetRepository();
