/**
 * Export all stores from a central location
 * Now using Firebase Firestore as the default backend
 */

// Re-export Firebase stores as default stores
export { useFirebaseAccountStore as useAccountStore } from './firebaseAccountStore';
export { useFirebaseBudgetStore as useBudgetStore } from './firebaseBudgetStore';
export { useFirebaseTransactionStore as useTransactionStore } from './firebaseTransactionStore';

// Auth store (Firebase-based)
export { useAuthStore } from './authStore';

// App store (local state)
export {
  selectCurrency,
  selectIsReady,
  selectTheme,
  useAppStore,
} from './appStore';

// Specialized stores
export { useDepositStore } from './depositStore';
export { useGoalStore } from './goalStore';
export { useInvestmentStore } from './investmentStore';

// Utilities
export { useInitializeStores, useIsAppReady, useResetStores } from './utils';
