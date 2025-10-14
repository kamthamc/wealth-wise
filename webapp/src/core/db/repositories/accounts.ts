/**
 * Account repository
 * Handles all database operations for accounts
 */

import { db } from '../client';
import type {
  Account,
  AccountType,
  CreateAccountInput,
  UpdateAccountInput,
} from '../types';
import { BaseRepository } from './base';

class AccountRepository extends BaseRepository<Account> {
  constructor() {
    super('accounts');
  }

  /**
   * Create a new account
   */
  async create(input: CreateAccountInput): Promise<Account> {
    const result = await db.query<Account>(
      `INSERT INTO accounts (name, type, balance, currency, icon, color, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        input.name,
        input.type,
        input.balance || 0,
        input.currency || 'INR',
        input.icon || null,
        input.color || null,
        input.is_active ?? true,
      ]
    );

    const account = result.rows[0];
    if (!account) {
      throw new Error('Failed to create account');
    }
    return account;
  }

  /**
   * Update an account
   */
  async update(input: UpdateAccountInput): Promise<Account | null> {
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

    values.push(input.id);

    const result = await db.query<Account>(
      `UPDATE accounts SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get all active accounts
   */
  async findActive(): Promise<Account[]> {
    const result = await db.query<Account>(
      'SELECT * FROM accounts WHERE is_active = true ORDER BY created_at DESC'
    );
    return result.rows;
  }

  /**
   * Get accounts by type
   */
  async findByType(type: AccountType): Promise<Account[]> {
    const result = await db.query<Account>(
      'SELECT * FROM accounts WHERE type = $1 ORDER BY created_at DESC',
      [type]
    );
    return result.rows;
  }

  /**
   * Update account balance
   */
  async updateBalance(id: string, amount: number): Promise<Account | null> {
    const result = await db.query<Account>(
      'UPDATE accounts SET balance = balance + $1 WHERE id = $2 RETURNING *',
      [amount, id]
    );
    return result.rows[0] || null;
  }

  /**
   * Get total balance across all accounts
   */
  async getTotalBalance(): Promise<number> {
    const result = await db.query<{ total: string }>(
      'SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE is_active = true'
    );
    return Number.parseFloat(result.rows[0]?.total || '0');
  }

  /**
   * Get balance by account type
   */
  async getBalanceByType(): Promise<
    Array<{ type: AccountType; balance: number }>
  > {
    const result = await db.query<{ type: AccountType; balance: string }>(
      `SELECT type, COALESCE(SUM(balance), 0) as balance 
       FROM accounts 
       WHERE is_active = true 
       GROUP BY type 
       ORDER BY balance DESC`
    );
    return result.rows.map((row) => ({
      type: row.type,
      balance: Number.parseFloat(row.balance),
    }));
  }
}

export const accountRepository = new AccountRepository();
