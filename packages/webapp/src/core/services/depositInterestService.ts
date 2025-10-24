import {
  calculateCurrentValue,
  calculateInterestEarned,
  calculateMonthlyInterest,
  calculateTDS,
} from '../../shared/utils/depositCalculations';
import { depositDetailsRepository } from '../db/repositories/depositDetails';
import { transactionRepository } from '../db/repositories/transactions';
import type { DepositDetails, InterestPayoutFrequency } from '../db/types';

/**
 * Service for automatically calculating and posting interest transactions
 * for deposit accounts (FD, RD, PPF, etc.)
 */
export class DepositInterestService {
  /**
   * Process all deposits and post due interest payments
   * Should be called:
   * - On app startup
   * - Daily in background
   * - Manually via admin action
   */
  async processAllPendingInterest(): Promise<{
    processed: number;
    totalInterest: number;
    errors: string[];
  }> {
    const results = {
      processed: 0,
      totalInterest: 0,
      errors: [] as string[],
    };

    try {
      // Get all active deposits
      const activeDeposits =
        await depositDetailsRepository.findByStatus('active');

      for (const deposit of activeDeposits) {
        try {
          const result = await this.processDepositInterest(deposit);
          if (result.posted) {
            results.processed++;
            results.totalInterest += result.interestAmount;
          }
        } catch (error) {
          const message =
            error instanceof Error ? error.message : 'Unknown error';
          results.errors.push(`Deposit ${deposit.id}: ${message}`);
          console.error(
            `[Interest Service] Error processing deposit ${deposit.id}:`,
            error
          );
        }
      }

      console.log(
        `[Interest Service] Processed ${results.processed} deposits, total interest: ₹${results.totalInterest.toFixed(2)}`
      );
    } catch (error) {
      console.error(
        '[Interest Service] Fatal error processing interest:',
        error
      );
      results.errors.push(
        'Fatal error: ' + (error instanceof Error ? error.message : 'Unknown')
      );
    }

    return results;
  }

  /**
   * Process interest for a single deposit
   * Posts interest transaction if payment is due
   */
  async processDepositInterest(
    deposit: DepositDetails
  ): Promise<{ posted: boolean; interestAmount: number }> {
    // Check if deposit is active
    if (deposit.status !== 'active') {
      return { posted: false, interestAmount: 0 };
    }

    // For deposits with interest paid at maturity, don't post interim transactions
    if (deposit.interest_payout_frequency === 'maturity') {
      // Just update current value (accrued interest)
      const currentValue = calculateCurrentValue(deposit);
      await depositDetailsRepository.update(deposit.id, {
        current_value: currentValue,
      });
      return { posted: false, interestAmount: 0 };
    }

    // Calculate if interest payment is due
    const { isDue, periods } = this.calculateInterestDue(deposit);

    if (!isDue || periods === 0) {
      return { posted: false, interestAmount: 0 };
    }

    // Calculate interest for the period
    const interestAmount = this.calculatePeriodInterest(deposit, periods);
    const tdsAmount = calculateTDS(interestAmount, deposit.interest_rate);
    const netInterest = interestAmount - tdsAmount;

    // Create interest credit transaction
    await transactionRepository.create({
      account_id: deposit.account_id,
      amount: netInterest,
      type: 'income',
      category: 'Interest Income',
      description: this.generateInterestDescription(deposit, periods),
      date: new Date(),
      is_recurring: false,
      is_initial_balance: false,
    });

    // Update deposit details
    const totalInterestEarned = deposit.total_interest_earned + interestAmount;
    const tdsTotalDeducted = deposit.tds_deducted + tdsAmount;
    const currentValue = calculateCurrentValue({
      ...deposit,
      total_interest_earned: totalInterestEarned,
    });

    await depositDetailsRepository.update(deposit.id, {
      total_interest_earned: totalInterestEarned,
      tds_deducted: tdsTotalDeducted,
      current_value: currentValue,
      last_interest_date: new Date(),
    });

    // Update tenure progress
    const now = new Date();
    const startDate = new Date(deposit.start_date);
    const completedMonths = this.getMonthsDifference(startDate, now);
    await depositDetailsRepository.updateTenureProgress(
      deposit.id,
      completedMonths
    );

    console.log(
      `[Interest Service] Posted ₹${netInterest.toFixed(2)} interest for deposit ${deposit.id}`
    );

    return { posted: true, interestAmount: netInterest };
  }

  /**
   * Calculate if interest payment is due and how many periods
   */
  private calculateInterestDue(deposit: DepositDetails): {
    isDue: boolean;
    periods: number;
  } {
    const now = new Date();
    const startDate = new Date(deposit.start_date);
    const lastPaymentDate = deposit.last_interest_date
      ? new Date(deposit.last_interest_date)
      : new Date(startDate);

    // Calculate next payment date based on frequency
    const nextPaymentDate = this.calculateNextPaymentDate(
      lastPaymentDate,
      deposit.interest_payout_frequency || 'quarterly'
    );

    // Check if we've passed the next payment date
    const isDue = now >= nextPaymentDate;

    // Calculate how many periods have passed
    const periods = isDue
      ? this.calculatePeriodsPassed(
          lastPaymentDate,
          now,
          deposit.interest_payout_frequency || 'quarterly'
        )
      : 0;

    return { isDue, periods };
  }

  /**
   * Calculate next payment date based on frequency
   */
  private calculateNextPaymentDate(
    lastDate: Date,
    frequency: InterestPayoutFrequency
  ): Date {
    const next = new Date(lastDate);

    switch (frequency) {
      case 'monthly':
        next.setMonth(next.getMonth() + 1);
        break;
      case 'quarterly':
        next.setMonth(next.getMonth() + 3);
        break;
      case 'annually':
        next.setFullYear(next.getFullYear() + 1);
        break;
      case 'maturity':
        // For maturity, return far future date
        next.setFullYear(next.getFullYear() + 100);
        break;
    }

    return next;
  }

  /**
   * Calculate how many complete periods have passed
   */
  private calculatePeriodsPassed(
    lastDate: Date,
    currentDate: Date,
    frequency: InterestPayoutFrequency
  ): number {
    const monthsDiff = this.getMonthsDifference(lastDate, currentDate);

    switch (frequency) {
      case 'monthly':
        return Math.floor(monthsDiff);
      case 'quarterly':
        return Math.floor(monthsDiff / 3);
      case 'annually':
        return Math.floor(monthsDiff / 12);
      case 'maturity':
        return 0;
      default:
        return 0;
    }
  }

  /**
   * Calculate months between two dates
   */
  private getMonthsDifference(startDate: Date, endDate: Date): number {
    const start = new Date(startDate);
    const end = new Date(endDate);

    const yearsDiff = end.getFullYear() - start.getFullYear();
    const monthsDiff = end.getMonth() - start.getMonth();
    const daysDiff = end.getDate() - start.getDate();

    let totalMonths = yearsDiff * 12 + monthsDiff;

    // If we haven't completed the month yet, don't count it
    if (daysDiff < 0) {
      totalMonths--;
    }

    return totalMonths;
  }

  /**
   * Calculate interest for a specific number of periods
   */
  private calculatePeriodInterest(
    deposit: DepositDetails,
    periods: number
  ): number {
    const monthlyInterest = calculateMonthlyInterest(
      deposit.principal_amount,
      deposit.interest_rate
    );

    switch (deposit.interest_payout_frequency) {
      case 'monthly':
        return monthlyInterest * periods;
      case 'quarterly':
        return monthlyInterest * 3 * periods;
      case 'annually':
        return monthlyInterest * 12 * periods;
      default:
        return 0;
    }
  }

  /**
   * Generate human-readable description for interest transaction
   */
  private generateInterestDescription(
    deposit: DepositDetails,
    periods: number
  ): string {
    const frequency = deposit.interest_payout_frequency || 'quarterly';
    const rate = deposit.interest_rate;

    let periodText = '';
    switch (frequency) {
      case 'monthly':
        periodText = periods === 1 ? 'monthly' : `${periods} months`;
        break;
      case 'quarterly':
        periodText = periods === 1 ? 'quarterly' : `${periods} quarters`;
        break;
      case 'annually':
        periodText = periods === 1 ? 'annual' : `${periods} years`;
        break;
    }

    return `Interest credit (${rate}% p.a.) - ${periodText}`;
  }

  /**
   * Calculate next interest date for a deposit
   * Useful for display in UI
   */
  async getNextInterestDate(depositId: string): Promise<Date | null> {
    const deposit = await depositDetailsRepository.findById(depositId);
    if (!deposit || deposit.status !== 'active') {
      return null;
    }

    if (deposit.interest_payout_frequency === 'maturity') {
      return new Date(deposit.maturity_date);
    }

    const lastPaymentDate = deposit.last_interest_date
      ? new Date(deposit.last_interest_date)
      : new Date(deposit.start_date);

    return this.calculateNextPaymentDate(
      lastPaymentDate,
      deposit.interest_payout_frequency || 'quarterly'
    );
  }

  /**
   * Process interest for deposits that are maturing
   * Posts final interest payment if needed
   */
  async processMaturityInterest(depositId: string): Promise<void> {
    const deposit = await depositDetailsRepository.findById(depositId);
    if (!deposit || deposit.status !== 'active') {
      return;
    }

    const now = new Date();
    const maturityDate = new Date(deposit.maturity_date);

    // Check if deposit has matured
    if (now < maturityDate) {
      return;
    }

    // For deposits with interest at maturity, post the full maturity amount
    if (deposit.interest_payout_frequency === 'maturity') {
      const totalInterest = calculateInterestEarned(deposit);
      const tdsAmount = calculateTDS(totalInterest, deposit.interest_rate);
      const netInterest = totalInterest - tdsAmount;

      // Create maturity interest transaction
      await transactionRepository.create({
        account_id: deposit.account_id,
        amount: netInterest,
        type: 'income',
        category: 'Interest Income',
        description: `Maturity interest (${deposit.interest_rate}% p.a.)`,
        date: maturityDate,
        is_recurring: false,
        is_initial_balance: false,
      });

      // Update deposit to matured status
      await depositDetailsRepository.markAsMatured(depositId);

      console.log(
        `[Interest Service] Posted maturity interest for deposit ${depositId}`
      );
    } else {
      // For other frequencies, just mark as matured (interest already posted periodically)
      await depositDetailsRepository.markAsMatured(depositId);
    }
  }
}

// Export singleton instance
export const depositInterestService = new DepositInterestService();
