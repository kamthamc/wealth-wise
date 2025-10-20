/**
 * Deposit Store
 * Manages Fixed Deposits, Recurring Deposits, PPF, NSC, and other deposit schemes
 */

import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import type {
  CreateDepositDetailsInput,
  CreateDepositInterestPaymentInput,
  DepositCalculation,
  DepositCalculationResult,
  DepositDetails,
  DepositInterestPayment,
  DepositStatus,
  UpdateDepositDetailsInput,
} from '@/core/db/types';

interface DepositState {
  // State
  deposits: DepositDetails[];
  interestPayments: DepositInterestPayment[];
  isLoading: boolean;
  error: string | null;

  // Actions
  fetchDeposits: (accountId?: string) => Promise<void>;
  fetchInterestPayments: (depositId: string) => Promise<void>;
  addDeposit: (input: CreateDepositDetailsInput) => Promise<void>;
  updateDeposit: (input: UpdateDepositDetailsInput) => Promise<void>;
  deleteDeposit: (id: string) => Promise<void>;
  recordInterestPayment: (
    input: CreateDepositInterestPaymentInput
  ) => Promise<void>;

  // Calculations
  calculateMaturityAmount: (
    calculation: DepositCalculation
  ) => DepositCalculationResult;
  calculateCurrentValue: (depositId: string) => number;
  updateDepositProgress: (depositId: string) => Promise<void>;

  // Queries
  getDepositsByStatus: (status: DepositStatus) => DepositDetails[];
  getDepositsByAccount: (accountId: string) => DepositDetails[];
  getMaturingDeposits: (daysAhead: number) => DepositDetails[];
  getTotalInterestEarned: (accountIds?: string[]) => number;
  getTotalTDSDeducted: (financialYear: string) => number;

  // Utility
  clearError: () => void;
  reset: () => void;
}

/**
 * Calculate compound interest
 */
function calculateCompoundInterest(
  principal: number,
  rate: number,
  time: number,
  frequency: number = 4 // quarterly by default
): number {
  const r = rate / 100;
  return principal * (1 + r / frequency) ** (frequency * time) - principal;
}

/**
 * Get compound frequency from payout frequency
 */
function getCompoundFrequency(payout: string): number {
  switch (payout) {
    case 'monthly':
      return 12;
    case 'quarterly':
      return 4;
    case 'annually':
      return 1;
    case 'maturity':
      return 4; // Default to quarterly compounding
    default:
      return 4;
  }
}

/**
 * Calculate months between two dates
 */
function monthsDiff(startDate: Date, endDate: Date): number {
  const start = new Date(startDate);
  const end = new Date(endDate);

  let months = (end.getFullYear() - start.getFullYear()) * 12;
  months += end.getMonth() - start.getMonth();

  return months;
}

export const useDepositStore = create<DepositState>()(
  devtools(
    (set, get) => ({
      // Initial State
      deposits: [],
      interestPayments: [],
      isLoading: false,
      error: null,

      // Fetch Deposits
      fetchDeposits: async (accountId?: string) => {
        set({ isLoading: true, error: null });
        try {
          // TODO: Replace with actual API call
          const mockDeposits: DepositDetails[] = [];

          console.log('Fetching deposits for account:', accountId);

          set({ deposits: mockDeposits, isLoading: false });
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to fetch deposits',
            isLoading: false,
          });
        }
      },

      // Fetch Interest Payments
      fetchInterestPayments: async (depositId: string) => {
        set({ isLoading: true, error: null });
        try {
          // TODO: Replace with actual API call
          const mockPayments: DepositInterestPayment[] = [];

          console.log('Fetching interest payments for deposit:', depositId);

          set({ interestPayments: mockPayments, isLoading: false });
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to fetch interest payments',
            isLoading: false,
          });
        }
      },

      // Add Deposit
      addDeposit: async (input: CreateDepositDetailsInput) => {
        set({ isLoading: true, error: null });
        try {
          // Calculate derived values
          const tenureYears = input.tenure_months / 12;
          const compoundFreq = getCompoundFrequency(
            input.interest_payout_frequency
          );

          const totalInterest = calculateCompoundInterest(
            input.principal_amount,
            input.interest_rate,
            tenureYears,
            compoundFreq
          );

          const now = new Date();
          const completedMonths = monthsDiff(new Date(input.start_date), now);
          const remainingMonths = Math.max(
            0,
            input.tenure_months - completedMonths
          );

          // Calculate current value based on elapsed time
          const elapsedYears = completedMonths / 12;
          const currentInterest = calculateCompoundInterest(
            input.principal_amount,
            input.interest_rate,
            elapsedYears,
            compoundFreq
          );

          const newDeposit: DepositDetails = {
            ...input,
            id: crypto.randomUUID(),
            current_value:
              input.current_value || input.principal_amount + currentInterest,
            total_interest_earned: input.total_interest_earned || 0,
            completed_months: completedMonths >= 0 ? completedMonths : 0,
            remaining_months: remainingMonths,
            maturity_amount: input.principal_amount + totalInterest,
            created_at: new Date(),
            updated_at: new Date(),
          };

          set((state) => ({
            deposits: [...state.deposits, newDeposit],
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error ? error.message : 'Failed to add deposit',
            isLoading: false,
          });
        }
      },

      // Update Deposit
      updateDeposit: async (input: UpdateDepositDetailsInput) => {
        set({ isLoading: true, error: null });
        try {
          set((state) => ({
            deposits: state.deposits.map((d) =>
              d.id === input.id ? { ...d, ...input, updated_at: new Date() } : d
            ),
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to update deposit',
            isLoading: false,
          });
        }
      },

      // Delete Deposit
      deleteDeposit: async (id: string) => {
        set({ isLoading: true, error: null });
        try {
          set((state) => ({
            deposits: state.deposits.filter((d) => d.id !== id),
            interestPayments: state.interestPayments.filter(
              (p) => p.deposit_id !== id
            ),
            isLoading: false,
          }));
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to delete deposit',
            isLoading: false,
          });
        }
      },

      // Record Interest Payment
      recordInterestPayment: async (
        input: CreateDepositInterestPaymentInput
      ) => {
        set({ isLoading: true, error: null });
        try {
          const newPayment: DepositInterestPayment = {
            ...input,
            id: crypto.randomUUID(),
            created_at: new Date(),
          };

          set((state) => {
            // Update deposit's total interest earned
            const deposits = state.deposits.map((d) => {
              if (d.id === input.deposit_id) {
                return {
                  ...d,
                  total_interest_earned:
                    d.total_interest_earned + input.net_amount,
                  last_interest_date: input.payment_date,
                  updated_at: new Date(),
                };
              }
              return d;
            });

            return {
              interestPayments: [...state.interestPayments, newPayment],
              deposits,
              isLoading: false,
            };
          });
        } catch (error) {
          set({
            error:
              error instanceof Error
                ? error.message
                : 'Failed to record interest payment',
            isLoading: false,
          });
        }
      },

      // Calculate Maturity Amount
      calculateMaturityAmount: (
        calculation: DepositCalculation
      ): DepositCalculationResult => {
        const {
          principal,
          interest_rate,
          tenure_months,
          payout_frequency,
          compound_frequency,
        } = calculation;

        const tenureYears = tenure_months / 12;
        const compoundFreq =
          compound_frequency || getCompoundFrequency(payout_frequency);

        const totalInterest = calculateCompoundInterest(
          principal,
          interest_rate,
          tenureYears,
          compoundFreq
        );

        const maturityAmount = principal + totalInterest;
        const effectiveRate = ((totalInterest / principal) * 100) / tenureYears;

        // Calculate month-by-month breakdown
        const interestBreakdown = [];
        for (let month = 1; month <= tenure_months; month++) {
          const years = month / 12;
          const interest = calculateCompoundInterest(
            principal,
            interest_rate,
            years,
            compoundFreq
          );

          const prevInterest =
            month > 1
              ? calculateCompoundInterest(
                  principal,
                  interest_rate,
                  (month - 1) / 12,
                  compoundFreq
                )
              : 0;

          interestBreakdown.push({
            month,
            interest: interest - prevInterest,
            cumulative_interest: interest,
          });
        }

        return {
          principal,
          total_interest: totalInterest,
          maturity_amount: maturityAmount,
          effective_rate: effectiveRate,
          interest_breakdown: interestBreakdown,
        };
      },

      // Calculate Current Value
      calculateCurrentValue: (depositId: string): number => {
        const { deposits } = get();
        const deposit = deposits.find((d) => d.id === depositId);

        if (!deposit) return 0;

        const now = new Date();
        const startDate = new Date(deposit.start_date);
        const elapsedMonths = monthsDiff(startDate, now);

        if (elapsedMonths <= 0) return deposit.principal_amount;
        if (elapsedMonths >= deposit.tenure_months)
          return deposit.maturity_amount;

        const elapsedYears = elapsedMonths / 12;
        const compoundFreq = getCompoundFrequency(
          deposit.interest_payout_frequency
        );

        const interest = calculateCompoundInterest(
          deposit.principal_amount,
          deposit.interest_rate,
          elapsedYears,
          compoundFreq
        );

        return deposit.principal_amount + interest;
      },

      // Update Deposit Progress
      updateDepositProgress: async (depositId: string) => {
        const { deposits, calculateCurrentValue } = get();
        const deposit = deposits.find((d) => d.id === depositId);

        if (!deposit) return;

        const now = new Date();
        const completedMonths = monthsDiff(new Date(deposit.start_date), now);
        const remainingMonths = Math.max(
          0,
          deposit.tenure_months - completedMonths
        );
        const currentValue = calculateCurrentValue(depositId);

        // Determine status
        let status: DepositStatus = deposit.status;
        if (now >= new Date(deposit.maturity_date)) {
          status = 'matured';
        } else {
          status = 'active';
        }

        set((state) => ({
          deposits: state.deposits.map((d) =>
            d.id === depositId
              ? {
                  ...d,
                  completed_months: Math.max(0, completedMonths),
                  remaining_months: remainingMonths,
                  current_value: currentValue,
                  status,
                  updated_at: new Date(),
                }
              : d
          ),
        }));
      },

      // Get Deposits by Status
      getDepositsByStatus: (status: DepositStatus): DepositDetails[] => {
        const { deposits } = get();
        return deposits.filter((d) => d.status === status);
      },

      // Get Deposits by Account
      getDepositsByAccount: (accountId: string): DepositDetails[] => {
        const { deposits } = get();
        return deposits.filter((d) => d.account_id === accountId);
      },

      // Get Maturing Deposits
      getMaturingDeposits: (daysAhead: number): DepositDetails[] => {
        const { deposits } = get();
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + daysAhead);

        return deposits.filter((d) => {
          const maturityDate = new Date(d.maturity_date);
          return maturityDate <= futureDate && d.status === 'active';
        });
      },

      // Get Total Interest Earned
      getTotalInterestEarned: (accountIds?: string[]): number => {
        const { deposits } = get();

        const filteredDeposits =
          accountIds && accountIds.length > 0
            ? deposits.filter((d) => accountIds.includes(d.account_id))
            : deposits;

        return filteredDeposits.reduce(
          (sum, d) => sum + d.total_interest_earned,
          0
        );
      },

      // Get Total TDS Deducted
      getTotalTDSDeducted: (financialYear: string): number => {
        const { interestPayments } = get();

        return interestPayments
          .filter((p) => p.financial_year === financialYear)
          .reduce((sum, p) => sum + p.tds_deducted, 0);
      },

      // Clear Error
      clearError: () => set({ error: null }),

      // Reset Store
      reset: () =>
        set({
          deposits: [],
          interestPayments: [],
          isLoading: false,
          error: null,
        }),
    }),
    { name: 'DepositStore' }
  )
);
