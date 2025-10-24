/**
 * Transaction state store
 * Manages transactions data and operations
 */

import { create } from 'zustand';
import { transactionCache } from '@/core/cache';
import { transactionRepository } from '@/core/db';
import type {
  CreateTransactionInput,
  Transaction,
  UpdateTransactionInput,
} from '../db/types';

interface TransactionState {
  // Data
  transactions: Transaction[];
  selectedTransactionId: string | null;
  isLoading: boolean;
  error: string | null;

  // Filters
  filters: {
    accountId?: string;
    type?: 'income' | 'expense' | 'transfer';
    category?: string;
    startDate?: Date;
    endDate?: Date;
    search?: string;
  };

  // Pagination
  currentPage: number;
  pageSize: number;
  totalCount: number;

  // Actions
  fetchTransactions: () => Promise<void>;
  createTransaction: (
    input: CreateTransactionInput
  ) => Promise<Transaction | null>;
  updateTransaction: (
    input: UpdateTransactionInput
  ) => Promise<Transaction | null>;
  deleteTransaction: (id: string) => Promise<boolean>;
  linkTransactions: (
    transactionId1: string,
    transactionId2: string
  ) => Promise<boolean>;
  unlinkTransaction: (transactionId: string) => Promise<boolean>;
  selectTransaction: (id: string | null) => void;
  setFilters: (filters: TransactionState['filters']) => void;
  clearFilters: () => void;
  setPage: (page: number) => void;
  setPageSize: (size: number) => void;
  reset: () => void;
}

const initialState = {
  transactions: [],
  selectedTransactionId: null,
  isLoading: false,
  error: null,
  filters: {},
  currentPage: 1,
  pageSize: 50,
  totalCount: 0,
};

export const useTransactionStore = create<TransactionState>((set, get) => ({
  ...initialState,

  fetchTransactions: async () => {
    set({ isLoading: true, error: null });
    try {
      const filters = get().filters;
      let transactions: Transaction[] = [];

      // Apply filters if specified
      if (filters.accountId) {
        transactions = await transactionRepository.findByAccount(
          filters.accountId
        );
      } else if (filters.type) {
        transactions = await transactionRepository.findByType(filters.type);
      } else if (filters.category) {
        transactions = await transactionRepository.findByCategory(
          filters.category
        );
      } else if (filters.startDate && filters.endDate) {
        transactions = await transactionRepository.findByDateRange(
          filters.startDate.toISOString(),
          filters.endDate.toISOString()
        );
      } else {
        // No filters - get all transactions
        transactions = await transactionRepository.findAll();
      }

      // Apply search filter if present
      if (filters.search && transactions.length > 0) {
        const searchLower = filters.search.toLowerCase();
        transactions = transactions.filter(
          (t) =>
            t.description?.toLowerCase().includes(searchLower) ||
            t.category?.toLowerCase().includes(searchLower)
        );
      }

      set({
        transactions,
        totalCount: transactions.length,
        isLoading: false,
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to fetch transactions';
      set({ error: errorMessage, isLoading: false });
    }
  },

  createTransaction: async (input) => {
    set({ isLoading: true, error: null });
    try {
      const transaction = await transactionRepository.create(input);

      // Invalidate cache for the affected account
      if (transaction.account_id) {
        transactionCache.invalidateAccount(transaction.account_id);
      }

      await get().fetchTransactions();
      set({ isLoading: false });
      return transaction;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to create transaction';
      set({ error: errorMessage, isLoading: false });
      return null;
    }
  },

  updateTransaction: async (input) => {
    set({ isLoading: true, error: null });
    try {
      const transaction = await transactionRepository.update(input);
      if (transaction) {
        // Invalidate cache for the affected account
        if (transaction.account_id) {
          transactionCache.invalidateAccount(transaction.account_id);
        }
        await get().fetchTransactions();
      }
      set({ isLoading: false });
      return transaction;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update transaction';
      set({ error: errorMessage, isLoading: false });
      return null;
    }
  },

  deleteTransaction: async (id) => {
    set({ isLoading: true, error: null });
    try {
      // Get transaction to find account ID before deleting
      const transaction = get().transactions.find((t) => t.id === id);

      const success = await transactionRepository.delete(id);

      if (success && transaction?.account_id) {
        // Invalidate cache for the affected account
        transactionCache.invalidateAccount(transaction.account_id);
        await get().fetchTransactions();
      }

      set({ isLoading: false });
      return success;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to delete transaction';
      set({ error: errorMessage, isLoading: false });
      return false;
    }
  },

  linkTransactions: async (transactionId1, transactionId2) => {
    set({ isLoading: true, error: null });
    try {
      // Update both transactions to link them
      const { transactions } = get();
      const updatedTransactions = transactions.map((txn) => {
        if (txn.id === transactionId1) {
          return { ...txn, linked_transaction_id: transactionId2 };
        }
        if (txn.id === transactionId2) {
          return { ...txn, linked_transaction_id: transactionId1 };
        }
        return txn;
      });

      set({ transactions: updatedTransactions, isLoading: false });
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to link transactions';
      set({ error: errorMessage, isLoading: false });
      return false;
    }
  },

  unlinkTransaction: async (transactionId) => {
    set({ isLoading: true, error: null });
    try {
      const { transactions } = get();
      const transaction = transactions.find((txn) => txn.id === transactionId);

      if (!transaction?.linked_transaction_id) {
        set({ isLoading: false });
        return false;
      }

      // Unlink both transactions
      const linkedId = transaction.linked_transaction_id;
      const updatedTransactions = transactions.map((txn) => {
        if (txn.id === transactionId || txn.id === linkedId) {
          const { linked_transaction_id, ...rest } = txn as any;
          return rest;
        }
        return txn;
      });

      set({ transactions: updatedTransactions, isLoading: false });
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to unlink transaction';
      set({ error: errorMessage, isLoading: false });
      return false;
    }
  },

  selectTransaction: (id) => {
    set({ selectedTransactionId: id });
  },

  setFilters: (filters) => {
    set({ filters, currentPage: 1 });
    get().fetchTransactions();
  },

  clearFilters: () => {
    set({ filters: {}, currentPage: 1 });
    get().fetchTransactions();
  },

  setPage: (page) => {
    set({ currentPage: page });
    get().fetchTransactions();
  },

  setPageSize: (size) => {
    set({ pageSize: size, currentPage: 1 });
    get().fetchTransactions();
  },

  reset: () => set(initialState),
}));

/**
 * Selectors
 */
export const selectSelectedTransaction = (state: TransactionState) =>
  state.transactions.find((tx) => tx.id === state.selectedTransactionId) ||
  null;

export const selectTransactionById =
  (id: string) => (state: TransactionState) =>
    state.transactions.find((tx) => tx.id === id) || null;

export const selectIsLoading = (state: TransactionState) => state.isLoading;

export const selectFilters = (state: TransactionState) => state.filters;

export const selectPagination = (state: TransactionState) => ({
  currentPage: state.currentPage,
  pageSize: state.pageSize,
  totalCount: state.totalCount,
  totalPages: Math.ceil(state.totalCount / state.pageSize),
});
