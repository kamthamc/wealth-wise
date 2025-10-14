/**
 * Application state store
 * Manages global app state like theme, loading states, and user preferences
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AppState {
  // Theme
  theme: 'light' | 'dark' | 'system';

  // Loading states
  isInitializing: boolean;
  isDatabaseReady: boolean;

  // UI state
  sidebarOpen: boolean;

  // User preferences
  currency: string;
  locale: string;
  dateFormat: string;

  // Actions
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  setInitializing: (isInitializing: boolean) => void;
  setDatabaseReady: (isDatabaseReady: boolean) => void;
  toggleSidebar: () => void;
  setSidebarOpen: (open: boolean) => void;
  setCurrency: (currency: string) => void;
  setLocale: (locale: string) => void;
  setDateFormat: (format: string) => void;
  reset: () => void;
}

const initialState = {
  theme: 'system' as const,
  isInitializing: true,
  isDatabaseReady: false,
  sidebarOpen: true,
  currency: 'INR',
  locale: 'en-IN',
  dateFormat: 'dd/MM/yyyy',
};

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      ...initialState,

      setTheme: (theme) => set({ theme }),

      setInitializing: (isInitializing) => set({ isInitializing }),

      setDatabaseReady: (isDatabaseReady) => set({ isDatabaseReady }),

      toggleSidebar: () =>
        set((state) => ({ sidebarOpen: !state.sidebarOpen })),

      setSidebarOpen: (open) => set({ sidebarOpen: open }),

      setCurrency: (currency) => set({ currency }),

      setLocale: (locale) => set({ locale }),

      setDateFormat: (format) => set({ dateFormat: format }),

      reset: () => set(initialState),
    }),
    {
      name: 'wealthwise-app-store',
      // Only persist user preferences, not loading states
      partialize: (state) => ({
        theme: state.theme,
        sidebarOpen: state.sidebarOpen,
        currency: state.currency,
        locale: state.locale,
        dateFormat: state.dateFormat,
      }),
    }
  )
);

/**
 * Selectors for computed values
 */
export const selectIsReady = (state: AppState) =>
  !state.isInitializing && state.isDatabaseReady;

export const selectTheme = (state: AppState) => state.theme;

export const selectCurrency = (state: AppState) => state.currency;
