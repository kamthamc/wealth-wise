/**
 * Credit Card Details Repository
 * Handles all database operations for credit card details
 */

import { db } from '../client';
import type { CreditCardDetails } from '../types';
import { BaseRepository } from './base';

class CreditCardDetailsRepository extends BaseRepository<CreditCardDetails> {
  constructor() {
    super('credit_card_details');
  }

  /**
   * Create credit card details for an account
   */
  async create(
    details: Omit<CreditCardDetails, 'id' | 'created_at' | 'updated_at'>
  ): Promise<CreditCardDetails> {
    const result = await db.query<CreditCardDetails>(
      `INSERT INTO credit_card_details (
        account_id, credit_limit, available_credit, current_balance,
        minimum_due, total_due, payment_due_date,
        billing_cycle_day, statement_date,
        interest_rate, late_payment_fee, annual_fee, rewards_points,
        rewards_value, cashback_earned,
        card_network, card_type, last_four_digits, expiry_date,
        issuer_bank, customer_id,
        autopay_enabled, status, notes
      )
      VALUES (
        $1, $2, $3, $4,
        $5, $6, $7,
        $8, $9,
        $10, $11, $12, $13,
        $14, $15,
        $16, $17, $18, $19,
        $20, $21,
        $22, $23, $24
      )
      RETURNING *`,
      [
        details.account_id,
        details.credit_limit,
        details.available_credit,
        details.current_balance,
        details.minimum_due,
        details.total_due,
        details.payment_due_date || null,
        details.billing_cycle_day,
        details.statement_date || null,
        details.interest_rate || null,
        details.annual_fee,
        details.late_payment_fee,
        details.rewards_points,
        details.rewards_value,
        details.cashback_earned,
        details.card_network || null,
        details.card_type || null,
        details.last_four_digits || null,
        details.expiry_date || null,
        details.issuer_bank || null,
        details.customer_id || null,
        details.autopay_enabled,
        details.status,
        details.notes || null,
      ]
    );

    const creditCardDetails = result.rows[0];
    if (!creditCardDetails) {
      throw new Error('Failed to create credit card details');
    }
    return creditCardDetails;
  }

  /**
   * Update credit card details
   */
  async update(
    id: string,
    updates: Partial<
      Omit<CreditCardDetails, 'id' | 'account_id' | 'created_at' | 'updated_at'>
    >
  ): Promise<CreditCardDetails | null> {
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
    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    // Add id parameter
    values.push(id);

    const result = await db.query<CreditCardDetails>(
      `UPDATE credit_card_details
       SET ${fields.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get credit card details by account ID
   */
  async getByAccountId(accountId: string): Promise<CreditCardDetails | null> {
    const result = await db.query<CreditCardDetails>(
      `SELECT * FROM credit_card_details WHERE account_id = $1`,
      [accountId]
    );

    return result.rows[0] || null;
  }

  /**
   * Delete credit card details
   */
  override async delete(id: string): Promise<boolean> {
    const result = await db.query(
      `DELETE FROM credit_card_details WHERE id = $1 RETURNING id`,
      [id]
    );

    return result.rows.length > 0;
  }

  /**
   * Delete credit card details by account ID
   */
  async deleteByAccountId(accountId: string): Promise<boolean> {
    const result = await db.query(
      `DELETE FROM credit_card_details WHERE account_id = $1 RETURNING id`,
      [accountId]
    );

    return result.rows.length > 0;
  }

  /**
   * Get all credit cards with upcoming payment due dates
   */
  async getUpcomingPayments(
    daysAhead: number = 7
  ): Promise<CreditCardDetails[]> {
    const result = await db.query<CreditCardDetails>(
      `SELECT * FROM credit_card_details
       WHERE payment_due_date IS NOT NULL
       AND payment_due_date >= CURRENT_DATE
       AND payment_due_date <= CURRENT_DATE + $1
       AND status = 'active'
       ORDER BY payment_due_date ASC`,
      [daysAhead]
    );

    return result.rows;
  }

  /**
   * Get credit cards with high utilization (>80%)
   */
  async getHighUtilization(): Promise<CreditCardDetails[]> {
    const result = await db.query<CreditCardDetails>(
      `SELECT * FROM credit_card_details
       WHERE credit_limit > 0
       AND (current_balance / credit_limit) > 0.8
       AND status = 'active'
       ORDER BY (current_balance / credit_limit) DESC`,
      []
    );

    return result.rows;
  }

  /**
   * Update credit card balance after transaction
   */
  async updateBalance(
    id: string,
    transactionAmount: number
  ): Promise<CreditCardDetails | null> {
    const result = await db.query<CreditCardDetails>(
      `UPDATE credit_card_details
       SET 
         current_balance = current_balance + $1,
         available_credit = credit_limit - (current_balance + $1),
         updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
      [transactionAmount, id]
    );

    return result.rows[0] || null;
  }

  /**
   * Get total credit card debt across all cards
   */
  async getTotalDebt(): Promise<number> {
    const result = await db.query<{ total: number }>(
      `SELECT COALESCE(SUM(current_balance), 0) as total
       FROM credit_card_details
       WHERE status = 'active'`,
      []
    );

    return result.rows[0]?.total ?? 0;
  }

  /**
   * Get total available credit across all cards
   */
  async getTotalAvailableCredit(): Promise<number> {
    const result = await db.query<{ total: number }>(
      `SELECT COALESCE(SUM(available_credit), 0) as total
       FROM credit_card_details
       WHERE status = 'active'`,
      []
    );

    return result.rows[0]?.total ?? 0;
  }

  /**
   * Get total rewards points across all cards
   */
  async getTotalRewardsPoints(): Promise<number> {
    const result = await db.query<{ total: number }>(
      `SELECT COALESCE(SUM(rewards_points), 0) as total
       FROM credit_card_details
       WHERE status = 'active'`,
      []
    );

    return result.rows[0]?.total ?? 0;
  }
}

// Export singleton instance
export const creditCardDetailsRepository = new CreditCardDetailsRepository();
