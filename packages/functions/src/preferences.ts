/**
 * User Preferences Cloud Functions
 * Manages user settings and preferences
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import type {
  GetUserPreferencesRequest,
  GetUserPreferencesResponse,
  UpdateUserPreferencesRequest,
  UpdateUserPreferencesResponse,
  ResetUserPreferencesRequest,
  ResetUserPreferencesResponse,
  UserPreferences,
} from '@svc/wealth-wise-shared-types';
import { createDefaultPreferencesFromLocale } from '@svc/wealth-wise-shared-types';

// Initialize Firebase Admin
try {
  initializeApp();
} catch (error) {
  // App already initialized
}

const db = getFirestore();

/**
 * Helper function to get authenticated user ID
 */
function getUserAuthenticated(context: any): string {
  if (!context.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }
  return context.auth.uid;
}

/**
 * Helper function to create default user preferences based on browser locale
 */
function createDefaultPreferences(userId: string, browserLocale?: string): UserPreferences {
  const now = new Date().toISOString();
  const defaults = createDefaultPreferencesFromLocale(browserLocale);
  
  return {
    ...defaults,
    userId,
    createdAt: now,
    updatedAt: now,
  } as UserPreferences;
}

/**
 * Get user preferences
 * Returns user's saved preferences or creates defaults if not found
 * On first call, initializes preferences based on browser locale
 */
export const getUserPreferences = onCall<
  GetUserPreferencesRequest,
  Promise<GetUserPreferencesResponse>
>(async (request) => {
  const userId = getUserAuthenticated(request);
  const { browserLocale } = request.data || {};

  try {
    const prefDoc = await db.collection('user_preferences').doc(userId).get();

    if (!prefDoc.exists) {
      // Create default preferences for new user based on browser locale
      console.log(`Creating preferences for user ${userId} with browser locale: ${browserLocale || 'not provided'}`);
      const defaultPrefs = createDefaultPreferences(userId, browserLocale);
      await db.collection('user_preferences').doc(userId).set(defaultPrefs);
      
      return {
        preferences: defaultPrefs,
      };
    }

    const preferences = prefDoc.data() as UserPreferences;
    return {
      preferences,
    };
  } catch (error) {
    console.error('Error fetching user preferences:', error);
    throw new HttpsError(
      'internal',
      'Failed to fetch user preferences',
      error instanceof Error ? error.message : String(error)
    );
  }
});

/**
 * Update user preferences
 * Allows partial updates to user preferences
 */
export const updateUserPreferences = onCall<
  UpdateUserPreferencesRequest,
  Promise<UpdateUserPreferencesResponse>
>(async (request) => {
  const userId = getUserAuthenticated(request);
  const { preferences: updates } = request.data;

  if (!updates || Object.keys(updates).length === 0) {
    throw new HttpsError('invalid-argument', 'No preferences provided to update');
  }

  try {
    const prefRef = db.collection('user_preferences').doc(userId);
    const prefDoc = await prefRef.get();

    const now = new Date().toISOString();
    
    if (!prefDoc.exists) {
      // Create new preferences with updates
      const newPrefs = {
        ...createDefaultPreferences(userId),
        ...updates,
        updatedAt: now,
      };
      await prefRef.set(newPrefs);
      
      return {
        success: true,
        preferences: newPrefs,
      };
    }

    // Update existing preferences
    const updateData = {
      ...updates,
      updatedAt: now,
    };
    
    await prefRef.update(updateData);
    
    const updatedDoc = await prefRef.get();
    const preferences = updatedDoc.data() as UserPreferences;

    return {
      success: true,
      preferences,
    };
  } catch (error) {
    console.error('Error updating user preferences:', error);
    throw new HttpsError(
      'internal',
      'Failed to update user preferences',
      error instanceof Error ? error.message : String(error)
    );
  }
});

/**
 * Reset user preferences to defaults
 * Requires explicit confirmation to prevent accidental resets
 */
export const resetUserPreferences = onCall<
  ResetUserPreferencesRequest,
  Promise<ResetUserPreferencesResponse>
>(async (request) => {
  const userId = getUserAuthenticated(request);
  const { confirmReset } = request.data;

  if (!confirmReset) {
    throw new HttpsError(
      'failed-precondition',
      'Reset confirmation required'
    );
  }

  try {
    const defaultPrefs = createDefaultPreferences(userId);
    await db.collection('user_preferences').doc(userId).set(defaultPrefs);

    return {
      success: true,
      preferences: defaultPrefs,
    };
  } catch (error) {
    console.error('Error resetting user preferences:', error);
    throw new HttpsError(
      'internal',
      'Failed to reset user preferences',
      error instanceof Error ? error.message : String(error)
    );
  }
});

/**
 * Helper function to fetch user preferences (for use in other Cloud Functions)
 * Returns user preferences or defaults if not found
 */
export async function fetchUserPreferences(userId: string): Promise<UserPreferences> {
  try {
    const prefDoc = await db.collection('user_preferences').doc(userId).get();
    
    if (!prefDoc.exists) {
      // Return defaults but don't create in Firestore yet
      return createDefaultPreferences(userId);
    }

    return prefDoc.data() as UserPreferences;
  } catch (error) {
    console.error('Error fetching user preferences:', error);
    // Return defaults on error
    return createDefaultPreferences(userId);
  }
}

/**
 * Helper function to get user's currency preference
 */
export async function getUserCurrency(userId: string): Promise<string> {
  const prefs = await fetchUserPreferences(userId);
  return prefs.currency;
}

/**
 * Helper function to get user's locale preference
 */
export async function getUserLocale(userId: string): Promise<string> {
  const prefs = await fetchUserPreferences(userId);
  return prefs.locale;
}

/**
 * Helper function to get user's timezone
 */
export async function getUserTimezone(userId: string): Promise<string> {
  const prefs = await fetchUserPreferences(userId);
  return prefs.timezone;
}
