/**
 * usePreferences Hook
 * Provides easy access to user preferences throughout the app
 */

import { useState, useEffect } from 'react';
import { preferencesApi } from '@/core/api';
import type { UserPreferences } from '@svc/wealth-wise-shared-types';

interface UsePreferencesResult {
  preferences: UserPreferences | null;
  loading: boolean;
  error: Error | null;
  reload: () => Promise<void>;
}

/**
 * Hook to access user preferences
 * Automatically loads preferences on mount and provides reload function
 */
export function usePreferences(): UsePreferencesResult {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadPreferences = async () => {
    try {
      setLoading(true);
      setError(null);
      const prefs = await preferencesApi.get();
      setPreferences(prefs);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to load preferences'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPreferences();
  }, []);

  return {
    preferences,
    loading,
    error,
    reload: loadPreferences,
  };
}

export default usePreferences;
