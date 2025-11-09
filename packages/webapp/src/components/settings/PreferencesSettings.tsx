/**
 * Preferences Settings Component
 * Allows users to manage their preferences (currency, locale, date format, etc.)
 */

import { useState, useEffect } from 'react';
import type { UserPreferences } from '@svc/wealth-wise-shared-types';
import { preferencesApi } from '@/core/api';
import { formatCurrency, formatDate } from '@/utils';

interface PreferencesSettingsProps {
  onSave?: (preferences: UserPreferences) => void;
  onError?: (error: Error) => void;
}

export function PreferencesSettings({ onSave, onError }: PreferencesSettingsProps) {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Load preferences on mount
  useEffect(() => {
    loadPreferences();
  }, []);

  const loadPreferences = async () => {
    try {
      setLoading(true);
      setError(null);
      const prefs = await preferencesApi.get();
      setPreferences(prefs);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load preferences';
      setError(message);
      onError?.(err instanceof Error ? err : new Error(message));
    } finally {
      setLoading(false);
    }
  };

  const handleUpdate = async (updates: Partial<UserPreferences>) => {
    if (!preferences) return;

    try {
      setSaving(true);
      setError(null);
      setSuccess(null);
      
      const updated = await preferencesApi.update(updates);
      setPreferences(updated);
      setSuccess('Preferences saved successfully!');
      onSave?.(updated);
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to save preferences';
      setError(message);
      onError?.(err instanceof Error ? err : new Error(message));
    } finally {
      setSaving(false);
    }
  };

  const handleReset = async () => {
    if (!confirm('Are you sure you want to reset all preferences to defaults?')) {
      return;
    }

    try {
      setSaving(true);
      setError(null);
      setSuccess(null);
      
      const reset = await preferencesApi.reset(true);
      setPreferences(reset);
      setSuccess('Preferences reset to defaults!');
      onSave?.(reset);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to reset preferences';
      setError(message);
      onError?.(err instanceof Error ? err : new Error(message));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full" />
        <span className="ml-3 text-gray-600">Loading preferences...</span>
      </div>
    );
  }

  if (!preferences) {
    return (
      <div className="p-8 text-center">
        <p className="text-red-600 mb-4">{error || 'Failed to load preferences'}</p>
        <button
          onClick={loadPreferences}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Preferences</h1>
        <button
          onClick={handleReset}
          disabled={saving}
          className="px-4 py-2 text-sm text-red-600 border border-red-600 rounded hover:bg-red-50 disabled:opacity-50"
        >
          Reset to Defaults
        </button>
      </div>

      {/* Status Messages */}
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-red-800">{error}</p>
        </div>
      )}
      {success && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
          <p className="text-green-800">{success}</p>
        </div>
      )}

      {/* Localization Settings */}
      <section className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Localization</h2>
        
        {/* Currency */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Currency
          </label>
          <select
            value={preferences.currency}
            onChange={(e) => handleUpdate({ currency: e.target.value })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="INR">₹ Indian Rupee (INR)</option>
            <option value="USD">$ US Dollar (USD)</option>
            <option value="EUR">€ Euro (EUR)</option>
            <option value="GBP">£ British Pound (GBP)</option>
            <option value="JPY">¥ Japanese Yen (JPY)</option>
            <option value="AUD">A$ Australian Dollar (AUD)</option>
            <option value="CAD">C$ Canadian Dollar (CAD)</option>
            <option value="CHF">CHF Swiss Franc (CHF)</option>
            <option value="CNY">¥ Chinese Yuan (CNY)</option>
            <option value="SEK">kr Swedish Krona (SEK)</option>
            <option value="NZD">NZ$ New Zealand Dollar (NZD)</option>
            <option value="ZAR">R South African Rand (ZAR)</option>
            <option value="BRL">R$ Brazilian Real (BRL)</option>
            <option value="MXN">Mex$ Mexican Peso (MXN)</option>
            <option value="RUB">₽ Russian Ruble (RUB)</option>
            <option value="KRW">₩ South Korean Won (KRW)</option>
            <option value="TRY">₺ Turkish Lira (TRY)</option>
            <option value="SGD">S$ Singapore Dollar (SGD)</option>
          </select>
          <p className="mt-1 text-sm text-gray-500">
            Example: {formatCurrency(1000000, preferences.currency, preferences.locale)}
          </p>
        </div>

        {/* Locale */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Locale (Region & Language)
          </label>
          <select
            value={preferences.locale}
            onChange={(e) => handleUpdate({ locale: e.target.value })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="en-IN">English (India)</option>
            <option value="en-US">English (United States)</option>
            <option value="en-GB">English (United Kingdom)</option>
            <option value="en-CA">English (Canada)</option>
            <option value="en-AU">English (Australia)</option>
            <option value="en-SG">English (Singapore)</option>
            <option value="de-DE">Deutsch (Germany)</option>
            <option value="fr-FR">Français (France)</option>
            <option value="ja-JP">日本語 (Japan)</option>
            <option value="zh-CN">中文 (China)</option>
          </select>
        </div>

        {/* Language */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Language
          </label>
          <select
            value={preferences.language}
            onChange={(e) => handleUpdate({ language: e.target.value })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="en">English</option>
            <option value="hi">हिन्दी (Hindi)</option>
            <option value="te">తెలుగు (Telugu)</option>
          </select>
          <p className="mt-1 text-sm text-gray-500">UI language (when available)</p>
        </div>

        {/* Timezone */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Timezone
          </label>
          <select
            value={preferences.timezone}
            onChange={(e) => handleUpdate({ timezone: e.target.value })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="Asia/Kolkata">Asia/Kolkata (IST)</option>
            <option value="America/New_York">America/New_York (EST/EDT)</option>
            <option value="America/Los_Angeles">America/Los_Angeles (PST/PDT)</option>
            <option value="Europe/London">Europe/London (GMT/BST)</option>
            <option value="Europe/Paris">Europe/Paris (CET/CEST)</option>
            <option value="Asia/Tokyo">Asia/Tokyo (JST)</option>
            <option value="Asia/Shanghai">Asia/Shanghai (CST)</option>
            <option value="Australia/Sydney">Australia/Sydney (AEST/AEDT)</option>
          </select>
        </div>
      </section>

      {/* Regional Format Settings */}
      <section className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Regional Formats</h2>
        
        {/* Date Format */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Date Format
          </label>
          <select
            value={preferences.dateFormat}
            onChange={(e) => handleUpdate({ dateFormat: e.target.value as UserPreferences['dateFormat'] })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="DD/MM/YYYY">DD/MM/YYYY (Day first)</option>
            <option value="MM/DD/YYYY">MM/DD/YYYY (Month first)</option>
            <option value="YYYY-MM-DD">YYYY-MM-DD (ISO 8601)</option>
            <option value="DD.MM.YYYY">DD.MM.YYYY (European)</option>
            <option value="YYYY/MM/DD">YYYY/MM/DD (Japanese)</option>
          </select>
          <p className="mt-1 text-sm text-gray-500">
            Example: {formatDate(new Date(), preferences.dateFormat, preferences.locale)}
          </p>
        </div>

        {/* Time Format */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Time Format
          </label>
          <select
            value={preferences.timeFormat}
            onChange={(e) => handleUpdate({ timeFormat: e.target.value as '12h' | '24h' })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="12h">12-hour (1:30 PM)</option>
            <option value="24h">24-hour (13:30)</option>
          </select>
        </div>

        {/* Number Format */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Number Format
          </label>
          <select
            value={preferences.numberFormat}
            onChange={(e) => handleUpdate({ numberFormat: e.target.value as 'indian' | 'western' })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="indian">Indian (Lakh/Crore)</option>
            <option value="western">Western (Million/Billion)</option>
          </select>
          <p className="mt-1 text-sm text-gray-500">
            {preferences.numberFormat === 'indian' 
              ? 'Example: 10 Lakh, 1 Crore'
              : 'Example: 1 Million, 1 Billion'}
          </p>
        </div>

        {/* Week Start Day */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Week Starts On
          </label>
          <select
            value={preferences.weekStartDay}
            onChange={(e) => handleUpdate({ weekStartDay: parseInt(e.target.value, 10) as UserPreferences['weekStartDay'] })}
            disabled={saving}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
          >
            <option value={0}>Sunday</option>
            <option value={1}>Monday</option>
            <option value={6}>Saturday</option>
          </select>
        </div>
      </section>

      {/* Financial Settings */}
      <section className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Financial Settings</h2>
        
        {/* Financial Year */}
        <div className="mb-6">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={preferences.useFinancialYear}
              onChange={(e) => handleUpdate({ useFinancialYear: e.target.checked })}
              disabled={saving}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <span className="ml-2 text-sm text-gray-700">Use Financial Year</span>
          </label>
          <p className="mt-1 ml-6 text-sm text-gray-500">
            Enable for April-March financial year (India), disable for calendar year
          </p>
        </div>

        {preferences.useFinancialYear && (
          <div className="mb-6 ml-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Financial Year Start Month
            </label>
            <select
              value={preferences.financialYearStartMonth}
              onChange={(e) => handleUpdate({ financialYearStartMonth: parseInt(e.target.value, 10) })}
              disabled={saving}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            >
              <option value={1}>January</option>
              <option value={2}>February</option>
              <option value={3}>March</option>
              <option value={4}>April (India)</option>
              <option value={5}>May</option>
              <option value={6}>June</option>
              <option value={7}>July</option>
              <option value={8}>August</option>
              <option value={9}>September</option>
              <option value={10}>October</option>
              <option value={11}>November</option>
              <option value={12}>December</option>
            </select>
          </div>
        )}

        {/* Hide Sensitive Data */}
        <div className="mb-6">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={preferences.hideSensitiveData}
              onChange={(e) => handleUpdate({ hideSensitiveData: e.target.checked })}
              disabled={saving}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <span className="ml-2 text-sm text-gray-700">Hide sensitive data by default</span>
          </label>
          <p className="mt-1 ml-6 text-sm text-gray-500">
            Mask account balances and amounts in the UI
          </p>
        </div>
      </section>

      {/* Save Button */}
      <div className="flex justify-end">
        <p className="text-sm text-gray-500">
          Changes are saved automatically
        </p>
      </div>
    </div>
  );
}

export default PreferencesSettings;
