/**
 * Transaction state store
 * Manages transactions data and operations
 */

import { create } from 'zustand'
import type { CreateTransactionInput, Transaction, UpdateTransactionInput } from '@/core/db'

interface TransactionState {
  // Data
  transactions: Transaction[]
  selectedTransactionId: string | null
  isLoading: boolean
  error: string | null

  // Filters
  filters: {
    accountId?: string
    type?: 'income' | 'expense' | 'transfer'
    category?: string
    startDate?: Date
    endDate?: Date
    search?: string
  }

  // Pagination
  currentPage: number
  pageSize: number
  totalCount: number

  // Actions
  fetchTransactions: () => Promise<void>
  createTransaction: (input: CreateTransactionInput) => Promise<Transaction | null>
  updateTransaction: (input: UpdateTransactionInput) => Promise<Transaction | null>
  deleteTransaction: (id: string) => Promise<boolean>
  selectTransaction: (id: string | null) => void
  setFilters: (filters: TransactionState['filters']) => void
  clearFilters: () => void
  setPage: (page: number) => void
  setPageSize: (size: number) => void
  reset: () => void
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
}

export const useTransactionStore = create<TransactionState>((set, get) => ({
  ...initialState,

  fetchTransactions: async () => {
    set({ isLoading: true, error: null })
    try {
      // TODO: Implement transaction repository and fetching with filters
      // const transactions = await transactionRepository.findAll(get().filters)

      set({
        transactions: [],
        totalCount: 0,
        isLoading: false,
      })
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to fetch transactions'
      set({ error: errorMessage, isLoading: false })
    }
  },

  createTransaction: async (_input) => {
    set({ isLoading: true, error: null })
    try {
      // TODO: Implement transaction repository
      // const transaction = await transactionRepository.create(_input)
      // await get().fetchTransactions()

      set({ isLoading: false })
      return null
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to create transaction'
      set({ error: errorMessage, isLoading: false })
      return null
    }
  },

  updateTransaction: async (_input) => {
    set({ isLoading: true, error: null })
    try {
      // TODO: Implement transaction repository
      // const transaction = await transactionRepository.update(_input)
      // await get().fetchTransactions()

      set({ isLoading: false })
      return null
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update transaction'
      set({ error: errorMessage, isLoading: false })
      return null
    }
  },

  deleteTransaction: async (_id) => {
    set({ isLoading: true, error: null })
    try {
      // TODO: Implement transaction repository
      // const success = await transactionRepository.delete(_id)
      // await get().fetchTransactions()

      set({ isLoading: false })
      return false
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to delete transaction'
      set({ error: errorMessage, isLoading: false })
      return false
    }
  },

  selectTransaction: (id) => {
    set({ selectedTransactionId: id })
  },

  setFilters: (filters) => {
    set({ filters, currentPage: 1 })
    get().fetchTransactions()
  },

  clearFilters: () => {
    set({ filters: {}, currentPage: 1 })
    get().fetchTransactions()
  },

  setPage: (page) => {
    set({ currentPage: page })
    get().fetchTransactions()
  },

  setPageSize: (size) => {
    set({ pageSize: size, currentPage: 1 })
    get().fetchTransactions()
  },

  reset: () => set(initialState),
}))

/**
 * Selectors
 */
export const selectSelectedTransaction = (state: TransactionState) =>
  state.transactions.find((tx) => tx.id === state.selectedTransactionId) || null

export const selectTransactionById = (id: string) => (state: TransactionState) =>
  state.transactions.find((tx) => tx.id === id) || null

export const selectIsLoading = (state: TransactionState) => state.isLoading

export const selectFilters = (state: TransactionState) => state.filters

export const selectPagination = (state: TransactionState) => ({
  currentPage: state.currentPage,
  pageSize: state.pageSize,
  totalCount: state.totalCount,
  totalPages: Math.ceil(state.totalCount / state.pageSize),
})
