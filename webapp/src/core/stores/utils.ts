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
  useEffect(() => {
    let timeoutId: ReturnType<typeof setTimeout>
    let retryCount = 0
    const MAX_RETRIES = 2

    const initialize = async () => {
      try {
        console.log('[App] Starting initialization...')
        useAppStore.getState().setInitializing(true)

        // Set a timeout to prevent infinite loading
        timeoutId = setTimeout(() => {
          console.error('[App] Initialization timeout - forcing completion')
          useAppStore.getState().setInitializing(false)
          useAppStore.getState().setDatabaseReady(false)
        }, 15000) // 15 second timeout

        // Initialize database with retry logic
        console.log('[App] Initializing database...')
        let dbInitialized = false
        
        while (!dbInitialized && retryCount <= MAX_RETRIES) {
          try {
            await db.initialize()
            dbInitialized = true
            console.log('[App] Database initialized successfully')
            useAppStore.getState().setDatabaseReady(true)
          } catch (error) {
            retryCount++
            console.error(`[App] Database initialization attempt ${retryCount} failed:`, error)
            
            if (retryCount <= MAX_RETRIES) {
              console.log(`[App] Retrying initialization (attempt ${retryCount + 1}/${MAX_RETRIES + 1})...`)
              // On retry, try to clear and reinitialize
              try {
                await db.clearAndReinitialize()
                dbInitialized = true
                console.log('[App] Database recovered after clearing')
                useAppStore.getState().setDatabaseReady(true)
              } catch (retryError) {
                console.error('[App] Retry failed:', retryError)
              }
            } else {
              throw error
            }
          }
        }

        // Fetch initial data (non-blocking)
        if (dbInitialized) {
          console.log('[App] Fetching initial data...')
          try {
            await useAccountStore.getState().fetchAccounts()
            console.log('[App] Initial data loaded successfully')
          } catch (error) {
            console.warn('[App] Failed to fetch initial data:', error)
            // Continue anyway - data can be loaded later
          }
        }

        clearTimeout(timeoutId)
        useAppStore.getState().setInitializing(false)
        console.log('[App] Initialization complete')
      } catch (error) {
        console.error('[App] Failed to initialize after all retries:', error)
        clearTimeout(timeoutId)
        useAppStore.getState().setInitializing(false)
        useAppStore.getState().setDatabaseReady(false)
      }
    }

    initialize()

    return () => {
      if (timeoutId) clearTimeout(timeoutId)
    }
  }, []) // Empty deps - run once on mount
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
