/**
 * Account state store
 * Manages accounts data and operations
 */

import { create } from 'zustand'
import type { Account, CreateAccountInput, UpdateAccountInput } from '@/core/db'
import { accountRepository } from '@/core/db'
import { announce, announceError } from '@/shared/utils'

interface AccountState {
  // Data
  accounts: Account[]
  selectedAccountId: string | null
  isLoading: boolean
  error: string | null

  // Computed
  totalBalance: number
  activeAccounts: Account[]

  // Actions
  fetchAccounts: () => Promise<void>
  createAccount: (input: CreateAccountInput) => Promise<Account | null>
  updateAccount: (input: UpdateAccountInput) => Promise<Account | null>
  deleteAccount: (id: string) => Promise<boolean>
  selectAccount: (id: string | null) => void
  updateBalance: (id: string, amount: number) => Promise<void>
  refreshTotalBalance: () => Promise<void>
  reset: () => void
}

const initialState = {
  accounts: [],
  selectedAccountId: null,
  isLoading: false,
  error: null,
  totalBalance: 0,
  activeAccounts: [],
}

export const useAccountStore = create<AccountState>((set, get) => ({
  ...initialState,

  fetchAccounts: async () => {
    set({ isLoading: true, error: null })
    try {
      const accounts = await accountRepository.findAll()
      const activeAccounts = accounts.filter((acc) => acc.is_active)
      const totalBalance = await accountRepository.getTotalBalance()

      set({
        accounts,
        activeAccounts,
        totalBalance,
        isLoading: false,
      })
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to fetch accounts'
      set({ error: errorMessage, isLoading: false })
      announceError(errorMessage)
    }
  },

  createAccount: async (input) => {
    set({ isLoading: true, error: null })
    try {
      const account = await accountRepository.create(input)
      await get().fetchAccounts()
      announce(`Account "${account.name}" created successfully`)
      set({ isLoading: false })
      return account
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to create account'
      set({ error: errorMessage, isLoading: false })
      announceError(errorMessage)
      return null
    }
  },

  updateAccount: async (input) => {
    set({ isLoading: true, error: null })
    try {
      const account = await accountRepository.update(input)
      if (account) {
        await get().fetchAccounts()
        announce(`Account "${account.name}" updated successfully`)
      }
      set({ isLoading: false })
      return account
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update account'
      set({ error: errorMessage, isLoading: false })
      announceError(errorMessage)
      return null
    }
  },

  deleteAccount: async (id) => {
    set({ isLoading: true, error: null })
    try {
      const success = await accountRepository.delete(id)
      if (success) {
        await get().fetchAccounts()
        announce('Account deleted successfully')

        // Clear selection if deleted account was selected
        if (get().selectedAccountId === id) {
          set({ selectedAccountId: null })
        }
      }
      set({ isLoading: false })
      return success
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to delete account'
      set({ error: errorMessage, isLoading: false })
      announceError(errorMessage)
      return false
    }
  },

  selectAccount: (id) => {
    set({ selectedAccountId: id })
  },

  updateBalance: async (id, amount) => {
    set({ isLoading: true, error: null })
    try {
      await accountRepository.updateBalance(id, amount)
      await get().fetchAccounts()
      set({ isLoading: false })
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update balance'
      set({ error: errorMessage, isLoading: false })
      announceError(errorMessage)
    }
  },

  refreshTotalBalance: async () => {
    try {
      const totalBalance = await accountRepository.getTotalBalance()
      set({ totalBalance })
    } catch (error) {
      console.error('Failed to refresh total balance:', error)
    }
  },

  reset: () => set(initialState),
}))

/**
 * Selectors for computed values
 */
export const selectActiveAccounts = (state: AccountState) => state.activeAccounts

export const selectSelectedAccount = (state: AccountState) =>
  state.accounts.find((acc) => acc.id === state.selectedAccountId) || null

export const selectAccountById = (id: string) => (state: AccountState) =>
  state.accounts.find((acc) => acc.id === id) || null

export const selectAccountsByType = (type: string) => (state: AccountState) =>
  state.accounts.filter((acc) => acc.type === type)

export const selectTotalBalance = (state: AccountState) => state.totalBalance

export const selectIsLoading = (state: AccountState) => state.isLoading
