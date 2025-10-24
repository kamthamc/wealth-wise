/**
 * Firebase Remote Config Service
 * Feature flags and A/B testing configuration
 */

import {
  fetchAndActivate,
  getBoolean,
  getNumber,
  getRemoteConfig,
  getString,
} from 'firebase/remote-config';
import { app } from '../firebase/firebase';

// Initialize Remote Config
const remoteConfig = getRemoteConfig(app);

// Set config defaults
remoteConfig.defaultConfig = {
  enable_advanced_analytics: false,
  enable_ai_insights: false,
  enable_export_pdf: true,
  max_accounts_per_user: 50,
  max_transactions_per_import: 100,
  enable_deposit_calculator: true,
  enable_goal_tracking: true,
  enable_budget_alerts: true,
  theme_variant: 'default',
  report_cache_ttl_seconds: 300,
};

// Set minimum fetch interval (1 hour in production, 0 in development)
remoteConfig.settings = {
  minimumFetchIntervalMillis: import.meta.env.DEV ? 0 : 3600000,
  fetchTimeoutMillis: 60000,
};

/**
 * Initialize and fetch remote config
 */
export async function initRemoteConfig(): Promise<void> {
  try {
    await fetchAndActivate(remoteConfig);
    console.log('Remote Config initialized successfully');
  } catch (error) {
    console.error('Failed to initialize Remote Config:', error);
  }
}

/**
 * Feature Flags
 */
export const FeatureFlags = {
  isAdvancedAnalyticsEnabled: (): boolean =>
    getBoolean(remoteConfig, 'enable_advanced_analytics'),
  isAIInsightsEnabled: (): boolean =>
    getBoolean(remoteConfig, 'enable_ai_insights'),
  isExportPDFEnabled: (): boolean =>
    getBoolean(remoteConfig, 'enable_export_pdf'),
  isDepositCalculatorEnabled: (): boolean =>
    getBoolean(remoteConfig, 'enable_deposit_calculator'),
  isGoalTrackingEnabled: (): boolean =>
    getBoolean(remoteConfig, 'enable_goal_tracking'),
  isBudgetAlertsEnabled: (): boolean =>
    getBoolean(remoteConfig, 'enable_budget_alerts'),
};

/**
 * Configuration Values
 */
export const RemoteConfigValues = {
  getMaxAccountsPerUser: (): number =>
    getNumber(remoteConfig, 'max_accounts_per_user'),
  getMaxTransactionsPerImport: (): number =>
    getNumber(remoteConfig, 'max_transactions_per_import'),
  getThemeVariant: (): string => getString(remoteConfig, 'theme_variant'),
  getReportCacheTTL: (): number =>
    getNumber(remoteConfig, 'report_cache_ttl_seconds'),
};

/**
 * Refresh remote config
 */
export async function refreshRemoteConfig(): Promise<void> {
  try {
    await fetchAndActivate(remoteConfig);
    console.log('Remote Config refreshed successfully');
  } catch (error) {
    console.error('Failed to refresh Remote Config:', error);
  }
}

/**
 * Get all active config values
 */
export function getAllConfigValues(): Record<string, any> {
  return {
    features: {
      advancedAnalytics: FeatureFlags.isAdvancedAnalyticsEnabled(),
      aiInsights: FeatureFlags.isAIInsightsEnabled(),
      exportPDF: FeatureFlags.isExportPDFEnabled(),
      depositCalculator: FeatureFlags.isDepositCalculatorEnabled(),
      goalTracking: FeatureFlags.isGoalTrackingEnabled(),
      budgetAlerts: FeatureFlags.isBudgetAlertsEnabled(),
    },
    config: {
      maxAccountsPerUser: RemoteConfigValues.getMaxAccountsPerUser(),
      maxTransactionsPerImport:
        RemoteConfigValues.getMaxTransactionsPerImport(),
      themeVariant: RemoteConfigValues.getThemeVariant(),
      reportCacheTTL: RemoteConfigValues.getReportCacheTTL(),
    },
  };
}

export { remoteConfig };
