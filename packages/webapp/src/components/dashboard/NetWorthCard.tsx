/**
 * Net Worth Card Component
 * Displays current net worth with user's preferred currency formatting
 * Example of integrating formatting utilities with Cloud Function responses
 */

import { useState, useEffect } from 'react';
import { analyticsApi } from '@/core/api';
import { formatCurrency, formatCurrencyCompact } from '@/utils';
import { usePreferences } from '@/hooks/usePreferences';
import type { NetWorthResponse } from '@svc/wealth-wise-shared-types';

interface NetWorthCardProps {
  showCompact?: boolean;
  showCurrency?: boolean;
  className?: string;
}

export function NetWorthCard({ 
  showCompact = false, 
  showCurrency = true,
  className = '' 
}: NetWorthCardProps) {
  const [data, setData] = useState<NetWorthResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Get user preferences for locale
  const { preferences, loading: prefsLoading } = usePreferences();

  useEffect(() => {
    if (!prefsLoading && preferences) {
      loadNetWorth();
    }
  }, [prefsLoading, preferences]);

  const loadNetWorth = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Cloud Function returns response with currency from user preferences
      const response = await analyticsApi.calculateNetWorth();
      setData(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load net worth');
    } finally {
      setLoading(false);
    }
  };

  if (loading || prefsLoading) {
    return (
      <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/3 mb-4" />
          <div className="h-8 bg-gray-200 rounded w-2/3" />
        </div>
      </div>
    );
  }

  if (error || !data || !preferences) {
    return (
      <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
        <p className="text-red-600">{error || 'No data available'}</p>
      </div>
    );
  }

  // Format net worth using user's locale from preferences
  // Currency is automatically included in the Cloud Function response
  // Locale comes from user preferences (initialized from browser on first use)
  const locale = preferences.locale;
  
  const formattedNetWorth = showCompact
    ? formatCurrencyCompact(data.totalNetWorth, data.currency, locale)
    : formatCurrency(data.totalNetWorth, data.currency, locale);

  return (
    <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
      <h3 className="text-sm font-medium text-gray-600 mb-2">
        Net Worth
      </h3>
      
      <div className="flex items-baseline justify-between">
        <p className="text-3xl font-bold text-gray-900">
          {formattedNetWorth}
        </p>
        
        <span className="text-xs text-gray-500">
          {data.accountCount} {data.accountCount === 1 ? 'account' : 'accounts'}
        </span>
      </div>

      {showCurrency && (
        <p className="mt-2 text-xs text-gray-500">
          Currency: {data.currency} • As of {new Date(data.asOfDate).toLocaleDateString()}
        </p>
      )}

      <div className="mt-4 pt-4 border-t border-gray-200">
        <div className="flex justify-between text-sm">
          <span className="text-gray-600">Assets</span>
          <span className="font-medium text-gray-900">
            {formatCurrency(data.totalAssets, data.currency, locale)}
          </span>
        </div>
        <div className="flex justify-between text-sm mt-2">
          <span className="text-gray-600">Liabilities</span>
          <span className="font-medium text-gray-900">
            {formatCurrency(data.totalLiabilities, data.currency, locale)}
          </span>
        </div>
      </div>

      <div className="mt-4 pt-4 border-t border-gray-200">
        <p className="text-xs text-gray-500">Last updated: {new Date(data.lastUpdated).toLocaleString()}</p>
      </div>
    </div>
  );
}

export default NetWorthCard;
