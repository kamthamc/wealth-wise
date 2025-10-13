/**
 * Store initialization and management utilities
 * Provides hooks and utilities for store lifecycle management
 */

import { useEffect } from 'react'
import { db } from '@/core/db'
import { useAccountStore } from './accountStore'
import { useAppStore } from './appStore'

/**
 * Initialize all stores and database
 * Call this in the root component
 */
export function useInitializeStores() {
  const setInitializing = useAppStore((state) => state.setInitializing)
  const setDatabaseReady = useAppStore((state) => state.setDatabaseReady)
  const fetchAccounts = useAccountStore((state) => state.fetchAccounts)

  useEffect(() => {
    const initialize = async () => {
      try {
        setInitializing(true)

        // Initialize database
        await db.initialize()
        setDatabaseReady(true)

        // Fetch initial data
        await fetchAccounts()

        setInitializing(false)
      } catch (error) {
        console.error('Failed to initialize stores:', error)
        setInitializing(false)
        setDatabaseReady(false)
      }
    }

    initialize()
  }, [setInitializing, setDatabaseReady, fetchAccounts])
}

/**
 * Reset all stores to initial state
 * Useful for logout or data clearing
 */
export function useResetStores() {
  const resetApp = useAppStore((state) => state.reset)
  const resetAccounts = useAccountStore((state) => state.reset)

  return () => {
    resetApp()
    resetAccounts()
    // Add other store resets as they are created
  }
}

/**
 * Check if the app is ready to use
 */
export function useIsAppReady() {
  return useAppStore((state) => !state.isInitializing && state.isDatabaseReady)
}
