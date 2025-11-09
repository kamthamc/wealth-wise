/**
 * Store initialization and management utilities
 * Provides hooks and utilities for store lifecycle management
 * Now using Firebase as the default backend
 */

import { useEffect } from 'react';
import { useFirebaseAccountStore } from './firebaseAccountStore';
import { useFirebaseBudgetStore } from './firebaseBudgetStore';
import { useFirebaseTransactionStore } from './firebaseTransactionStore';
import { useAppStore } from './appStore';
import { useAuthStore } from './authStore';

/**
 * Initialize all stores with Firebase
 * Call this in the root component after user authentication
 */
export function useInitializeStores() {
  useEffect(() => {
    const user = useAuthStore.getState().user;
    
    if (!user) {
      console.log('[App] No user authenticated, skipping store initialization');
      useAppStore.getState().setInitializing(false);
      useAppStore.getState().setDatabaseReady(false);
      return;
    }

    console.log('[App] Initializing Firebase stores for user:', user.uid);
    useAppStore.getState().setInitializing(true);

    try {
      // Initialize Firebase real-time listeners
      useFirebaseAccountStore.getState().initialize();
      useFirebaseBudgetStore.getState().initialize();
      useFirebaseTransactionStore.getState().initialize();

      // Firebase is ready immediately (no database initialization needed)
      useAppStore.getState().setDatabaseReady(true);
      useAppStore.getState().setInitializing(false);
      
      console.log('[App] Firebase stores initialized successfully');
    } catch (error) {
      console.error('[App] Failed to initialize stores:', error);
      useAppStore.getState().setInitializing(false);
      useAppStore.getState().setDatabaseReady(false);
    }

    // Cleanup listeners on unmount
    return () => {
      useFirebaseAccountStore.getState().cleanup();
      useFirebaseBudgetStore.getState().cleanup();
      useFirebaseTransactionStore.getState().cleanup();
    };
  }, [useAuthStore((state) => state.user?.uid)]); // Re-initialize when user changes
}

/**
 * Reset all stores to initial state
 * Useful for logout or data clearing
 */
export function useResetStores() {
  const resetApp = useAppStore((state) => state.reset);

  return () => {
    // Cleanup Firebase listeners
    useFirebaseAccountStore.getState().cleanup();
    useFirebaseBudgetStore.getState().cleanup();
    useFirebaseTransactionStore.getState().cleanup();
    
    // Reset app state
    resetApp();
    
    console.log('[App] All stores reset');
  };
}

/**
 * Check if the app is ready to use
 */
export function useIsAppReady() {
  return useAppStore((state) => !state.isInitializing && state.isDatabaseReady);
}
