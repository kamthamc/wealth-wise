/**
 * User Preferences API Client
 * Manages user settings and preferences through Cloud Functions
 */

import { httpsCallable } from 'firebase/functions';
import type {
  GetUserPreferencesRequest,
  GetUserPreferencesResponse,
  UpdateUserPreferencesRequest,
  UpdateUserPreferencesResponse,
  ResetUserPreferencesRequest,
  ResetUserPreferencesResponse,
  UserPreferences,
} from '@svc/wealth-wise-shared-types';
import { functions } from '../firebase/firebase';

/**
 * Get current user's preferences
 * Returns existing preferences or creates defaults for new users
 * On first call, initializes preferences based on browser locale
 */
export const getUserPreferences = async (): Promise<UserPreferences> => {
  const callable = httpsCallable<GetUserPreferencesRequest, GetUserPreferencesResponse>(
    functions,
    'getUserPreferences'
  );
  
  // Detect browser locale for first-time initialization
  const browserLocale = navigator.language || navigator.languages?.[0] || 'en-IN';
  
  const result = await callable({ browserLocale });
  return result.data.preferences;
};

/**
 * Update user preferences (partial update supported)
 * Only updates the fields provided, leaves others unchanged
 * 
 * @param preferences - Partial preferences to update
 * @returns Updated complete preferences
 */
export const updateUserPreferences = async (
  preferences: Partial<Omit<UserPreferences, 'userId' | 'createdAt' | 'version'>>
): Promise<UserPreferences> => {
  const callable = httpsCallable<UpdateUserPreferencesRequest, UpdateUserPreferencesResponse>(
    functions,
    'updateUserPreferences'
  );
  const result = await callable({ preferences });
  
  if (!result.data.success) {
    throw new Error('Failed to update user preferences');
  }
  
  return result.data.preferences;
};

/**
 * Reset all preferences to defaults
 * Requires explicit confirmation to prevent accidental resets
 * 
 * @param confirmReset - Must be true to confirm reset
 * @returns Reset preferences (defaults)
 */
export const resetUserPreferences = async (confirmReset: boolean = false): Promise<UserPreferences> => {
  if (!confirmReset) {
    throw new Error('Reset confirmation required');
  }
  
  const callable = httpsCallable<ResetUserPreferencesRequest, ResetUserPreferencesResponse>(
    functions,
    'resetUserPreferences'
  );
  const result = await callable({ confirmReset });
  
  if (!result.data.success) {
    throw new Error('Failed to reset user preferences');
  }
  
  return result.data.preferences;
};

/**
 * Update specific preference fields
 * Convenience methods for common preference updates
 */

export const updateCurrency = async (currency: string): Promise<UserPreferences> => {
  return updateUserPreferences({ currency });
};

export const updateLocale = async (locale: string): Promise<UserPreferences> => {
  return updateUserPreferences({ locale });
};

export const updateLanguage = async (language: string): Promise<UserPreferences> => {
  return updateUserPreferences({ language });
};

export const updateTimezone = async (timezone: string): Promise<UserPreferences> => {
  return updateUserPreferences({ timezone });
};

export const updateDateFormat = async (
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD' | 'system'
): Promise<UserPreferences> => {
  return updateUserPreferences({ dateFormat });
};

export const updateTimeFormat = async (
  timeFormat: '12h' | '24h' | 'system'
): Promise<UserPreferences> => {
  return updateUserPreferences({ timeFormat });
};

export const updateTheme = async (
  theme: 'light' | 'dark' | 'system'
): Promise<UserPreferences> => {
  return updateUserPreferences({ theme });
};

export const updateFinancialYearSettings = async (
  useFinancialYear: boolean,
  financialYearStartMonth: number
): Promise<UserPreferences> => {
  return updateUserPreferences({
    useFinancialYear,
    financialYearStartMonth,
  });
};

export const updateNotificationPreferences = async (
  notifications: {
    budgetAlerts?: boolean;
    goalMilestones?: boolean;
    unusualSpending?: boolean;
    recurringTransactions?: boolean;
    emailNotifications?: boolean;
    pushNotifications?: boolean;
  }
): Promise<UserPreferences> => {
  return updateUserPreferences(notifications);
};

export const updateSecuritySettings = async (
  security: {
    biometricEnabled?: boolean;
    autoLockTimeout?: number;
    requireAuthForExport?: boolean;
  }
): Promise<UserPreferences> => {
  return updateUserPreferences(security);
};

export const updateAppBehavior = async (
  behavior: {
    autoCategorizze?: boolean;
    duplicateDetection?: boolean;
    smartSuggestions?: boolean;
  }
): Promise<UserPreferences> => {
  return updateUserPreferences(behavior);
};

/**
 * Preferences API object for organized exports
 */
export const preferencesApi = {
  get: getUserPreferences,
  update: updateUserPreferences,
  reset: resetUserPreferences,
  
  // Specific field updates
  updateCurrency,
  updateLocale,
  updateLanguage,
  updateTimezone,
  updateDateFormat,
  updateTimeFormat,
  updateTheme,
  updateFinancialYearSettings,
  updateNotificationPreferences,
  updateSecuritySettings,
  updateAppBehavior,
};
