/**
 * Brokerage Details Repository
 * Handles all database operations for brokerage details
 */

import { db } from '../client';
import type { BrokerageDetails } from '../types';
import { BaseRepository } from './base';

class BrokerageDetailsRepository extends BaseRepository<BrokerageDetails> {
  constructor() {
    super('brokerage_details');
  }

  /**
   * Create brokerage details for an account
   */
  async create(
    details: Omit<BrokerageDetails, 'id' | 'created_at' | 'updated_at'>
  ): Promise<BrokerageDetails> {
    const result = await db.query<BrokerageDetails>(
      `INSERT INTO brokerage_details (
        account_id, broker_name, account_number, demat_account_number, trading_account_number,
        invested_value, current_value, total_returns, total_returns_percentage,
        realized_gains, unrealized_gains,
        equity_holdings, mutual_fund_holdings, bond_holdings, etf_holdings,
        account_type, status,
        auto_square_off, margin_enabled,
        notes
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9,
        $10, $11,
        $12, $13, $14, $15,
        $16, $17,
        $18, $19,
        $20
      )
      RETURNING *`,
      [
        details.account_id,
        details.broker_name,
        details.account_number || null,
        details.demat_account_number || null,
        details.trading_account_number || null,
        details.invested_value,
        details.current_value,
        details.total_returns,
        details.total_returns_percentage,
        details.realized_gains,
        details.unrealized_gains,
        details.equity_holdings,
        details.mutual_fund_holdings,
        details.bond_holdings,
        details.etf_holdings,
        details.account_type || null,
        details.status,
        details.auto_square_off,
        details.margin_enabled,
        details.notes || null,
      ]
    );

    const brokerageDetails = result.rows[0];
    if (!brokerageDetails) {
      throw new Error('Failed to create brokerage details');
    }
    return brokerageDetails;
  }

  /**
   * Update brokerage details
   */
  async update(
    id: string,
    updates: Partial<
      Omit<BrokerageDetails, 'id' | 'account_id' | 'created_at' | 'updated_at'>
    >
  ): Promise<BrokerageDetails | null> {
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

    const result = await db.query<BrokerageDetails>(
      `UPDATE brokerage_details
       SET ${fields.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get brokerage details by account ID
   */
  async getByAccountId(accountId: string): Promise<BrokerageDetails | null> {
    const result = await db.query<BrokerageDetails>(
      `SELECT * FROM brokerage_details WHERE account_id = $1`,
      [accountId]
    );

    return result.rows[0] || null;
  }

  /**
   * Delete brokerage details
   */
  override async delete(id: string): Promise<boolean> {
    const result = await db.query(
      `DELETE FROM brokerage_details WHERE id = $1 RETURNING id`,
      [id]
    );

    return result.rows.length > 0;
  }

  /**
   * Delete brokerage details by account ID
   */
  async deleteByAccountId(accountId: string): Promise<boolean> {
    const result = await db.query(
      `DELETE FROM brokerage_details WHERE account_id = $1 RETURNING id`,
      [accountId]
    );

    return result.rows.length > 0;
  }

  /**
   * Update portfolio value after market change
   */
  async updatePortfolioValue(
    id: string,
    newCurrentValue: number
  ): Promise<BrokerageDetails | null> {
    const result = await db.query<BrokerageDetails>(
      `UPDATE brokerage_details
       SET 
         current_value = $1,
         total_returns = $1 - invested_value,
         total_returns_percentage = (($1 - invested_value) / NULLIF(invested_value, 0)) * 100,
         unrealized_gains = $1 - invested_value - realized_gains,
         updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
      [newCurrentValue, id]
    );

    return result.rows[0] || null;
  }

  /**
   * Record realized gain/loss from selling holdings
   */
  async recordRealizedGain(
    id: string,
    realizedAmount: number
  ): Promise<BrokerageDetails | null> {
    const result = await db.query<BrokerageDetails>(
      `UPDATE brokerage_details
       SET 
         realized_gains = realized_gains + $1,
         unrealized_gains = current_value - invested_value - (realized_gains + $1),
         updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
      [realizedAmount, id]
    );

    return result.rows[0] || null;
  }

  /**
   * Update holdings breakdown
   */
  async updateHoldings(
    id: string,
    holdings: {
      equity?: number;
      mutualFund?: number;
      bond?: number;
      etf?: number;
    }
  ): Promise<BrokerageDetails | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (holdings.equity !== undefined) {
      fields.push(`equity_holdings = $${paramIndex}`);
      values.push(holdings.equity);
      paramIndex++;
    }
    if (holdings.mutualFund !== undefined) {
      fields.push(`mutual_fund_holdings = $${paramIndex}`);
      values.push(holdings.mutualFund);
      paramIndex++;
    }
    if (holdings.bond !== undefined) {
      fields.push(`bond_holdings = $${paramIndex}`);
      values.push(holdings.bond);
      paramIndex++;
    }
    if (holdings.etf !== undefined) {
      fields.push(`etf_holdings = $${paramIndex}`);
      values.push(holdings.etf);
      paramIndex++;
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await db.query<BrokerageDetails>(
      `UPDATE brokerage_details
       SET ${fields.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    return result.rows[0] || null;
  }

  /**
   * Get total portfolio value across all brokerage accounts
   */
  async getTotalPortfolioValue(): Promise<number> {
    const result = await db.query<{ total: number }>(
      `SELECT COALESCE(SUM(current_value), 0) as total
       FROM brokerage_details
       WHERE status = 'active'`,
      []
    );

    return result.rows[0]?.total ?? 0;
  }

  /**
   * Get total invested amount across all brokerage accounts
   */
  async getTotalInvestedValue(): Promise<number> {
    const result = await db.query<{ total: number }>(
      `SELECT COALESCE(SUM(invested_value), 0) as total
       FROM brokerage_details
       WHERE status = 'active'`,
      []
    );

    return result.rows[0]?.total ?? 0;
  }

  /**
   * Get total returns (realized + unrealized) across all accounts
   */
  async getTotalReturns(): Promise<{
    total: number;
    realized: number;
    unrealized: number;
    percentage: number;
  }> {
    const result = await db.query<{
      total: number;
      realized: number;
      unrealized: number;
      invested: number;
    }>(
      `SELECT 
        COALESCE(SUM(total_returns), 0) as total,
        COALESCE(SUM(realized_gains), 0) as realized,
        COALESCE(SUM(unrealized_gains), 0) as unrealized,
        COALESCE(SUM(invested_value), 0) as invested
       FROM brokerage_details
       WHERE status = 'active'`,
      []
    );

    const data = result.rows[0];
    const invested = data?.invested ?? 0;
    const total = data?.total ?? 0;
    const percentage = invested > 0 ? (total / invested) * 100 : 0;

    return {
      total,
      realized: data?.realized ?? 0,
      unrealized: data?.unrealized ?? 0,
      percentage,
    };
  }

  /**
   * Get accounts with positive returns
   */
  async getPositiveReturns(): Promise<BrokerageDetails[]> {
    const result = await db.query<BrokerageDetails>(
      `SELECT * FROM brokerage_details
       WHERE total_returns > 0
       AND status = 'active'
       ORDER BY total_returns_percentage DESC`,
      []
    );

    return result.rows;
  }

  /**
   * Get accounts with negative returns
   */
  async getNegativeReturns(): Promise<BrokerageDetails[]> {
    const result = await db.query<BrokerageDetails>(
      `SELECT * FROM brokerage_details
       WHERE total_returns < 0
       AND status = 'active'
       ORDER BY total_returns_percentage ASC`,
      []
    );

    return result.rows;
  }

  /**
   * Get holdings breakdown across all accounts
   */
  async getHoldingsBreakdown(): Promise<{
    equity: number;
    mutualFund: number;
    bond: number;
    etf: number;
    total: number;
  }> {
    const result = await db.query<{
      equity: number;
      mutual_fund: number;
      bond: number;
      etf: number;
    }>(
      `SELECT 
        COALESCE(SUM(equity_holdings), 0) as equity,
        COALESCE(SUM(mutual_fund_holdings), 0) as mutual_fund,
        COALESCE(SUM(bond_holdings), 0) as bond,
        COALESCE(SUM(etf_holdings), 0) as etf
       FROM brokerage_details
       WHERE status = 'active'`,
      []
    );

    const data = result.rows[0];
    return {
      equity: data?.equity ?? 0,
      mutualFund: data?.mutual_fund ?? 0,
      bond: data?.bond ?? 0,
      etf: data?.etf ?? 0,
      total:
        (data?.equity ?? 0) +
        (data?.mutual_fund ?? 0) +
        (data?.bond ?? 0) +
        (data?.etf ?? 0),
    };
  }
}

// Export singleton instance
export const brokerageDetailsRepository = new BrokerageDetailsRepository();
