/**
 * Deposit Interest Service - STUB IMPLEMENTATION
 * Original functionality depends on PGlite repositories which have been removed
 * TODO: Implement with Firebase when needed
 */

class DepositInterestService {
  async calculateInterest(): Promise<number> {
    return 0;
  }

  async getPaymentSchedule(): Promise<any[]> {
    return [];
  }

  async recordInterestPayment(): Promise<void> {
    throw new Error('Deposit interest service not implemented with Firebase');
  }

  async getInterestHistory(): Promise<any[]> {
    return [];
  }
}

export const depositInterestService = new DepositInterestService();
