/**
 * Deposit Details Repository
 * Handles all database operations for deposit details
 */

import { db } from '../client';
import type { DepositDetails } from '../types';
import { BaseRepository } from './base';

class DepositDetailsRepository extends BaseRepository<DepositDetails> {
  constructor() {
    super('deposit_details');
  }

  /**
   * Create deposit details for an account
   */
  async create(
    details: Omit<DepositDetails, 'id' | 'created_at' | 'updated_at'>
  ): Promise<DepositDetails> {
    const result = await db.query<DepositDetails>(
      `INSERT INTO deposit_details (
        account_id, principal_amount, maturity_amount, current_value,
        start_date, maturity_date, last_interest_date,
        interest_rate, interest_payout_frequency, total_interest_earned,
        tenure_months, completed_months, remaining_months,
        tds_deducted, tax_deduction_section, is_tax_saving,
        status, auto_renewal, premature_withdrawal_allowed, loan_against_deposit_allowed,
        bank_name, branch, account_number, certificate_number,
        nominee_name, nominee_relationship, notes
      )
      VALUES (
        $1, $2, $3, $4,
        $5, $6, $7,
        $8, $9, $10,
        $11, $12, $13,
        $14, $15, $16,
        $17, $18, $19, $20,
        $21, $22, $23, $24,
        $25, $26, $27
      )
      RETURNING *`,
      [
        details.account_id,
        details.principal_amount,
        details.maturity_amount,
        details.current_value,
        details.start_date,
        details.maturity_date,
        details.last_interest_date || null,
        details.interest_rate,
        details.interest_payout_frequency || null,
        details.total_interest_earned,
        details.tenure_months,
        details.completed_months,
        details.remaining_months,
        details.tds_deducted,
        details.tax_deduction_section || null,
        details.is_tax_saving,
        details.status,
        details.auto_renewal,
        details.premature_withdrawal_allowed,
        details.loan_against_deposit_allowed,
        details.bank_name || null,
        details.branch || null,
        details.account_number || null,
        details.certificate_number || null,
        details.nominee_name || null,
        details.nominee_relationship || null,
        details.notes || null,
      ]
    );

    const depositDetails = result.rows[0];
    if (!depositDetails) {
      throw new Error('Failed to create deposit details');
    }
    return depositDetails;
  }

  /**
   * Update deposit details
   */
  async update(
    id: string,
    updates: Partial<
      Omit<DepositDetails, 'id' | 'account_id' | 'created_at' | 'updated_at'>
    >
  ): Promise<DepositDetails | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    // Build dynamic UPDATE query
    for (const [key, value] of Object.entries(updates)) {
      fields.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    // Add updated_at timestamp
    fields.push(`updated_at = NOW()`);
    values.push(id);

    const result = await db.query<DepositDetails>(
      `UPDATE deposit_details SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get deposit details by account ID
   */
  async findByAccountId(accountId: string): Promise<DepositDetails | null> {
    const result = await db.query<DepositDetails>(
      'SELECT * FROM deposit_details WHERE account_id = $1',
      [accountId]
    );
    return result.rows[0] || null;
  }

  /**
   * Get all deposits maturing within a date range
   */
  async findMaturingBetween(
    startDate: Date,
    endDate: Date
  ): Promise<DepositDetails[]> {
    const result = await db.query<DepositDetails>(
      'SELECT * FROM deposit_details WHERE maturity_date BETWEEN $1 AND $2 ORDER BY maturity_date ASC',
      [startDate, endDate]
    );
    return result.rows;
  }

  /**
   * Get deposits by status
   */
  async findByStatus(status: string): Promise<DepositDetails[]> {
    const result = await db.query<DepositDetails>(
      'SELECT * FROM deposit_details WHERE status = $1 ORDER BY maturity_date ASC',
      [status]
    );
    return result.rows;
  }

  /**
   * Get tax-saving deposits
   */
  async findTaxSaving(): Promise<DepositDetails[]> {
    const result = await db.query<DepositDetails>(
      'SELECT * FROM deposit_details WHERE is_tax_saving = true ORDER BY maturity_date ASC'
    );
    return result.rows;
  }

  /**
   * Update completed and remaining months for a deposit
   */
  async updateTenureProgress(
    id: string,
    completedMonths: number
  ): Promise<DepositDetails | null> {
    const deposit = await this.findById(id);
    if (!deposit) return null;

    const remainingMonths = Math.max(
      0,
      deposit.tenure_months - completedMonths
    );

    return this.update(id, {
      completed_months: completedMonths,
      remaining_months: remainingMonths,
    });
  }

  /**
   * Update current value and total interest earned
   */
  async updateCurrentValue(
    id: string,
    currentValue: number,
    interestEarned: number
  ): Promise<DepositDetails | null> {
    return this.update(id, {
      current_value: currentValue,
      total_interest_earned: interestEarned,
    });
  }

  /**
   * Mark deposit as matured
   */
  async markAsMatured(id: string): Promise<DepositDetails | null> {
    const deposit = await this.findById(id);
    if (!deposit) return null;

    return this.update(id, {
      status: 'matured',
      current_value: deposit.maturity_amount,
      completed_months: deposit.tenure_months,
      remaining_months: 0,
    });
  }

  /**
   * Delete deposit details
   */
  override async delete(id: string): Promise<boolean> {
    const result = await db.query('DELETE FROM deposit_details WHERE id = $1', [
      id,
    ]);
    return result.rows.length === 0; // If no rows returned, deletion was successful
  }

  /**
   * Delete deposit details by account ID
   */
  async deleteByAccountId(accountId: string): Promise<boolean> {
    const result = await db.query(
      'DELETE FROM deposit_details WHERE account_id = $1',
      [accountId]
    );
    return result.rows.length === 0; // If no rows returned, deletion was successful
  }
}

export const depositDetailsRepository = new DepositDetailsRepository();
