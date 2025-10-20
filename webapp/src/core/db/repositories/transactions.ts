/**
 * Transaction repository
 * Handles all database operations for transactions
 */

import { db } from '../client';
import type {
  CreateTransactionInput,
  Transaction,
  TransactionType,
  UpdateTransactionInput,
} from '../types';
import { BaseRepository } from './base';

class TransactionRepository extends BaseRepository<Transaction> {
  constructor() {
    super('transactions');
  }

  /**
   * Create a new transaction
   */
  async create(input: CreateTransactionInput): Promise<Transaction> {
    const result = await db.query<Transaction>(
      `INSERT INTO transactions (account_id, type, category, amount, description, date, tags, is_recurring, recurring_frequency)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        input.account_id,
        input.type,
        input.category || '',
        input.amount,
        input.description || '',
        input.date || new Date().toISOString(),
        input.tags || [],
        input.is_recurring || false,
        input.recurring_frequency || null,
      ]
    );

    const transaction = result.rows[0];
    if (!transaction) {
      throw new Error('Failed to create transaction');
    }
    return transaction;
  }

  /**
   * Update a transaction
   */
  async update(input: UpdateTransactionInput): Promise<Transaction | null> {
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

    const result = await db.query<Transaction>(
      `UPDATE transactions SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get transactions by account
   */
  async findByAccount(accountId: string): Promise<Transaction[]> {
    const result = await db.query<Transaction>(
      'SELECT * FROM transactions WHERE account_id = $1 ORDER BY date DESC, created_at DESC',
      [accountId]
    );
    return result.rows;
  }

  /**
   * Get transactions by type
   */
  async findByType(type: TransactionType): Promise<Transaction[]> {
    const result = await db.query<Transaction>(
      'SELECT * FROM transactions WHERE type = $1 ORDER BY date DESC, created_at DESC',
      [type]
    );
    return result.rows;
  }

  /**
   * Get transactions by date range
   */
  async findByDateRange(
    startDate: string,
    endDate: string
  ): Promise<Transaction[]> {
    const result = await db.query<Transaction>(
      'SELECT * FROM transactions WHERE date >= $1 AND date <= $2 ORDER BY date DESC, created_at DESC',
      [startDate, endDate]
    );
    return result.rows;
  }

  /**
   * Get transactions by category
   */
  async findByCategory(category: string): Promise<Transaction[]> {
    const result = await db.query<Transaction>(
      'SELECT * FROM transactions WHERE category = $1 ORDER BY date DESC, created_at DESC',
      [category]
    );
    return result.rows;
  }

  /**
   * Get total by type (income/expense)
   */
  async getTotalByType(type: TransactionType): Promise<number> {
    const result = await db.query<{ total: string }>(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = $1',
      [type]
    );
    return Number.parseFloat(result.rows[0]?.total || '0');
  }

  /**
   * Get total by category
   */
  async getTotalByCategory(category: string): Promise<number> {
    const result = await db.query<{ total: string }>(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE category = $1',
      [category]
    );
    return Number.parseFloat(result.rows[0]?.total || '0');
  }

  /**
   * Get transactions summary by month
   */
  async getSummaryByMonth(year: number): Promise<
    Array<{
      month: number;
      income: number;
      expense: number;
      balance: number;
    }>
  > {
    const result = await db.query<{
      month: number;
      income: string;
      expense: string;
    }>(
      `SELECT 
        EXTRACT(MONTH FROM date)::int as month,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as expense
       FROM transactions
       WHERE EXTRACT(YEAR FROM date) = $1
       GROUP BY EXTRACT(MONTH FROM date)
       ORDER BY month`,
      [year]
    );

    return result.rows.map((row) => ({
      month: row.month,
      income: Number.parseFloat(row.income),
      expense: Number.parseFloat(row.expense),
      balance: Number.parseFloat(row.income) - Number.parseFloat(row.expense),
    }));
  }

  /**
   * Search transactions by description
   */
  async search(query: string): Promise<Transaction[]> {
    const result = await db.query<Transaction>(
      'SELECT * FROM transactions WHERE description ILIKE $1 ORDER BY date DESC, created_at DESC LIMIT 50',
      [`%${query}%`]
    );
    return result.rows;
  }
}

export const transactionRepository = new TransactionRepository();
