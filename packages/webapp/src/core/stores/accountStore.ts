/**
 * Account state store
 * Manages accounts data and operations
 */

import { create } from 'zustand';
import type {
  Account,
  CreateAccountInput,
  InterestPayoutFrequency,
  TaxDeductionSection,
  UpdateAccountInput,
} from '@/core/db';
import {
  accountRepository,
  depositDetailsRepository,
  transactionRepository,
} from '@/core/db';
import { announce, announceError } from '@/shared/utils';
import { calculateMaturityAmount } from '@/shared/utils/depositCalculations';

interface DepositDetailsInput {
  principal_amount: number;
  interest_rate: number;
  start_date: Date;
  tenure_months: number;
  interest_payout_frequency?: InterestPayoutFrequency;
  bank_name?: string;
  auto_renewal?: boolean;
  is_tax_saving?: boolean;
  tax_deduction_section?: TaxDeductionSection;
  nominee_name?: string;
  notes?: string;
}

interface AccountState {
  // Data
  accounts: Account[];
  selectedAccountId: string | null;
  isLoading: boolean;
  error: string | null;

  // Computed
  totalBalance: number;
  activeAccounts: Account[];

  // Actions
  fetchAccounts: () => Promise<void>;
  createAccount: (input: CreateAccountInput) => Promise<Account | null>;
  updateAccount: (input: UpdateAccountInput) => Promise<Account | null>;
  deleteAccount: (id: string) => Promise<boolean>;
  selectAccount: (id: string | null) => void;
  updateBalance: (id: string, amount: number) => Promise<void>;
  refreshTotalBalance: () => Promise<void>;
  reset: () => void;
}

const initialState = {
  accounts: [],
  selectedAccountId: null,
  isLoading: false,
  error: null,
  totalBalance: 0,
  activeAccounts: [],
};

export const useAccountStore = create<AccountState>((set, get) => ({
  ...initialState,

  fetchAccounts: async () => {
    set({ isLoading: true, error: null });
    try {
      const accounts = await accountRepository.findAll();
      const activeAccounts = accounts.filter((acc) => acc.is_active);
      const totalBalance = await accountRepository.getTotalBalance();

      set({
        accounts,
        activeAccounts,
        totalBalance,
        isLoading: false,
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to fetch accounts';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
    }
  },

  createAccount: async (input) => {
    set({ isLoading: true, error: null });
    try {
      const account = await accountRepository.create(input);

      // Create initial balance transaction if balance is provided and non-zero
      if (input.balance && input.balance !== 0) {
        await transactionRepository.create({
          account_id: account.id,
          type: input.balance >= 0 ? 'income' : 'expense',
          category: 'Initial Balance',
          amount: Math.abs(input.balance),
          description: `Opening balance for ${account.name}`,
          date: account.created_at,
          is_initial_balance: true,
          is_recurring: false,
        });
      }

      // Create credit card details if this is a credit card account with credit card details
      const inputWithCreditCard = input as CreateAccountInput & {
        creditCardDetails?: {
          credit_limit: number;
          billing_cycle_day?: number;
          payment_due_day?: number;
          card_network?: string;
          card_type?: string;
          interest_rate?: number;
          annual_fee?: number;
          reward_rate?: number;
        };
      };

      if (
        input.type === 'credit_card' &&
        inputWithCreditCard.creditCardDetails
      ) {
        const ccDetails = inputWithCreditCard.creditCardDetails;
        const { creditCardDetailsRepository } = await import(
          '@/core/db/repositories'
        );

        const currentBalance = Math.abs(input.balance || 0);

        await creditCardDetailsRepository.create({
          account_id: account.id,
          credit_limit: ccDetails.credit_limit,
          available_credit: ccDetails.credit_limit - currentBalance,
          current_balance: currentBalance,
          minimum_due: 0,
          total_due: currentBalance,
          billing_cycle_day: ccDetails.billing_cycle_day || 1,
          annual_fee: ccDetails.annual_fee || 0,
          late_payment_fee: 0,
          rewards_points: 0,
          rewards_value: 0,
          cashback_earned: 0,
          status: 'active' as const,
          autopay_enabled: false,
          card_network: (ccDetails.card_network || undefined) as
            | 'visa'
            | 'mastercard'
            | 'amex'
            | 'rupay'
            | 'diners'
            | undefined,
          card_type: (ccDetails.card_type || undefined) as
            | 'credit'
            | 'charge'
            | undefined,
          interest_rate: ccDetails.interest_rate,
        });
      }

      // Create brokerage details if this is a brokerage account with brokerage details
      const inputWithBrokerage = input as CreateAccountInput & {
        brokerageDetails?: {
          broker_name?: string;
          demat_account_number?: string;
          trading_account_number?: string;
          dp_id?: string;
          client_id?: string;
          account_type?: string;
        };
      };

      if (input.type === 'brokerage' && inputWithBrokerage.brokerageDetails) {
        const brokDetails = inputWithBrokerage.brokerageDetails;
        const { brokerageDetailsRepository } = await import(
          '@/core/db/repositories'
        );

        await brokerageDetailsRepository.create({
          account_id: account.id,
          broker_name: brokDetails.broker_name || 'Unknown',
          demat_account_number: brokDetails.demat_account_number,
          trading_account_number: brokDetails.trading_account_number,
          invested_value: 0,
          current_value: input.balance || 0,
          total_returns: 0,
          total_returns_percentage: 0,
          realized_gains: 0,
          unrealized_gains: 0,
          equity_holdings: 0,
          mutual_fund_holdings: 0,
          bond_holdings: 0,
          etf_holdings: 0,
          account_type: (brokDetails.account_type || undefined) as
            | 'trading'
            | 'demat'
            | 'combined'
            | undefined,
          status: 'active' as const,
          auto_square_off: false,
          margin_enabled: false,
        });
      }

      // Create deposit details if this is a deposit account with deposit details
      const depositTypes = [
        'fixed_deposit',
        'recurring_deposit',
        'ppf',
        'nsc',
        'kvp',
        'scss',
        'post_office',
      ];
      const inputWithDeposit = input as CreateAccountInput & {
        depositDetails?: DepositDetailsInput;
      };

      if (
        depositTypes.includes(input.type) &&
        inputWithDeposit.depositDetails
      ) {
        const depositDetails = inputWithDeposit.depositDetails; // Calculate maturity date and amount
        const startDate = new Date(depositDetails.start_date);
        const maturityDate = new Date(startDate);
        maturityDate.setMonth(
          maturityDate.getMonth() + depositDetails.tenure_months
        );

        const maturityAmount = calculateMaturityAmount(
          depositDetails.principal_amount,
          depositDetails.interest_rate,
          depositDetails.tenure_months,
          depositDetails.interest_payout_frequency || 'quarterly'
        );

        await depositDetailsRepository.create({
          account_id: account.id,
          principal_amount: depositDetails.principal_amount,
          maturity_amount: maturityAmount,
          current_value: depositDetails.principal_amount,
          start_date: startDate,
          maturity_date: maturityDate,
          interest_rate: depositDetails.interest_rate,
          interest_payout_frequency:
            depositDetails.interest_payout_frequency || 'quarterly',
          total_interest_earned: 0,
          tenure_months: depositDetails.tenure_months,
          completed_months: 0,
          remaining_months: depositDetails.tenure_months,
          tds_deducted: 0,
          tax_deduction_section: depositDetails.tax_deduction_section,
          is_tax_saving: depositDetails.is_tax_saving || false,
          status: 'active',
          auto_renewal: depositDetails.auto_renewal || false,
          premature_withdrawal_allowed: true,
          loan_against_deposit_allowed: false,
          bank_name: depositDetails.bank_name,
          nominee_name: depositDetails.nominee_name,
          notes: depositDetails.notes,
        });
      }

      await get().fetchAccounts();
      announce(`Account "${account.name}" created successfully`);
      set({ isLoading: false });
      return account;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to create account';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      return null;
    }
  },

  updateAccount: async (input) => {
    set({ isLoading: true, error: null });
    try {
      const account = await accountRepository.update(input);
      if (account) {
        await get().fetchAccounts();
        announce(`Account "${account.name}" updated successfully`);
      }
      set({ isLoading: false });
      return account;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update account';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      return null;
    }
  },

  deleteAccount: async (id) => {
    set({ isLoading: true, error: null });
    try {
      const success = await accountRepository.delete(id);
      if (success) {
        await get().fetchAccounts();
        announce('Account deleted successfully');

        // Clear selection if deleted account was selected
        if (get().selectedAccountId === id) {
          set({ selectedAccountId: null });
        }
      }
      set({ isLoading: false });
      return success;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to delete account';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      return false;
    }
  },

  selectAccount: (id) => {
    set({ selectedAccountId: id });
  },

  updateBalance: async (id, amount) => {
    set({ isLoading: true, error: null });
    try {
      await accountRepository.updateBalance(id, amount);
      await get().fetchAccounts();
      set({ isLoading: false });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update balance';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
    }
  },

  refreshTotalBalance: async () => {
    try {
      const totalBalance = await accountRepository.getTotalBalance();
      set({ totalBalance });
    } catch (error) {
      console.error('Failed to refresh total balance:', error);
    }
  },

  reset: () => set(initialState),
}));

/**
 * Selectors for computed values
 */
export const selectActiveAccounts = (state: AccountState) =>
  state.activeAccounts;

export const selectSelectedAccount = (state: AccountState) =>
  state.accounts.find((acc) => acc.id === state.selectedAccountId) || null;

export const selectAccountById = (id: string) => (state: AccountState) =>
  state.accounts.find((acc) => acc.id === id) || null;

export const selectAccountsByType = (type: string) => (state: AccountState) =>
  state.accounts.filter((acc) => acc.type === type);

export const selectTotalBalance = (state: AccountState) => state.totalBalance;

export const selectIsLoading = (state: AccountState) => state.isLoading;
