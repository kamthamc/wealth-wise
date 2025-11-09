/**
 * User Preferences Types
 * Defines user settings and preferences stored in Firestore
 */

export interface UserPreferences {
  userId: string;
  
  // Localization
  currency: string; // Primary currency (e.g., 'INR', 'USD', 'EUR')
  locale: string; // Locale for formatting (e.g., 'en-IN', 'en-US')
  language: string; // UI language (e.g., 'en', 'hi', 'te')
  timezone: string; // User's timezone (e.g., 'Asia/Kolkata')
  
  // Regional Settings
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD' | 'system';
  timeFormat: '12h' | '24h' | 'system';
  numberFormat: 'indian' | 'western' | 'system'; // Number grouping style
  weekStartDay: 0 | 1 | 6; // 0=Sunday, 1=Monday, 6=Saturday
  
  // Financial Settings
  useFinancialYear: boolean; // April-March for India, Jan-Dec for others
  financialYearStartMonth: number; // 1-12, typically 4 for India, 1 for others
  defaultAccountId?: string;
  hideSensitiveData: boolean; // Blur amounts in UI
  
  // Display Settings
  theme: 'light' | 'dark' | 'system';
  colorScheme?: string; // Custom color scheme
  dashboardLayout?: 'compact' | 'standard' | 'detailed';
  chartType?: 'bar' | 'line' | 'pie' | 'mixed';
  
  // Notification Preferences
  budgetAlerts: boolean;
  goalMilestones: boolean;
  unusualSpending: boolean;
  recurringTransactions: boolean;
  emailNotifications: boolean;
  pushNotifications: boolean;
  
  // Privacy & Security
  biometricEnabled: boolean;
  autoLockTimeout: number; // seconds
  requireAuthForExport: boolean;
  
  // App Behavior
  autoCategorizze: boolean;
  duplicateDetection: boolean;
  smartSuggestions: boolean;
  
  // Metadata
  createdAt: string;
  updatedAt: string;
  version: number; // For migration tracking
}

// Request/Response types for user preferences
export interface GetUserPreferencesRequest {
  // Optional browser locale for initializing preferences on first call
  browserLocale?: string;
}

export interface GetUserPreferencesResponse {
  preferences: UserPreferences;
}

export interface UpdateUserPreferencesRequest {
  preferences: Partial<Omit<UserPreferences, 'userId' | 'createdAt' | 'version'>>;
}

export interface UpdateUserPreferencesResponse {
  success: boolean;
  preferences: UserPreferences;
}

export interface ResetUserPreferencesRequest {
  confirmReset: boolean;
}

export interface ResetUserPreferencesResponse {
  success: boolean;
  preferences: UserPreferences;
}

// Locale configuration for different regions
export interface LocaleConfiguration {
  currency: string;
  locale: string;
  dateFormat: string;
  timeFormat: string;
  numberFormat: string;
  weekStartDay: number;
  useFinancialYear: boolean;
  financialYearStartMonth: number;
}

// Predefined locale configurations
export const LOCALE_CONFIGURATIONS: Record<string, LocaleConfiguration> = {
  'en-IN': {
    currency: 'INR',
    locale: 'en-IN',
    dateFormat: 'DD/MM/YYYY',
    timeFormat: '12h',
    numberFormat: 'indian',
    weekStartDay: 1, // Monday
    useFinancialYear: true,
    financialYearStartMonth: 4, // April
  },
  'en-US': {
    currency: 'USD',
    locale: 'en-US',
    dateFormat: 'MM/DD/YYYY',
    timeFormat: '12h',
    numberFormat: 'western',
    weekStartDay: 0, // Sunday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'en-GB': {
    currency: 'GBP',
    locale: 'en-GB',
    dateFormat: 'DD/MM/YYYY',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 1, // Monday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'en-CA': {
    currency: 'CAD',
    locale: 'en-CA',
    dateFormat: 'DD/MM/YYYY',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 0, // Sunday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'en-AU': {
    currency: 'AUD',
    locale: 'en-AU',
    dateFormat: 'DD/MM/YYYY',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 1, // Monday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'en-SG': {
    currency: 'SGD',
    locale: 'en-SG',
    dateFormat: 'DD/MM/YYYY',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 1, // Monday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'de-DE': {
    currency: 'EUR',
    locale: 'de-DE',
    dateFormat: 'DD.MM.YYYY',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 1, // Monday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'fr-FR': {
    currency: 'EUR',
    locale: 'fr-FR',
    dateFormat: 'DD/MM/YYYY',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 1, // Monday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'ja-JP': {
    currency: 'JPY',
    locale: 'ja-JP',
    dateFormat: 'YYYY/MM/DD',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 0, // Sunday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
  'zh-CN': {
    currency: 'CNY',
    locale: 'zh-CN',
    dateFormat: 'YYYY-MM-DD',
    timeFormat: '24h',
    numberFormat: 'western',
    weekStartDay: 1, // Monday
    useFinancialYear: false,
    financialYearStartMonth: 1, // January
  },
};

/**
 * Detect best locale configuration from browser locale
 * Falls back to en-IN if browser locale is not directly supported
 */
export function detectLocaleFromBrowser(browserLocale?: string): LocaleConfiguration {
  // Use provided browser locale or fallback to en-IN
  const locale = browserLocale || 'en-IN';
  
  // Try exact match first
  if (LOCALE_CONFIGURATIONS[locale]) {
    return LOCALE_CONFIGURATIONS[locale];
  }
  
  // Try language-only match (e.g., 'en' from 'en-GB')
  const language = locale.split('-')[0];
  const languageMatch = Object.keys(LOCALE_CONFIGURATIONS).find(
    key => key.startsWith(`${language}-`)
  );
  
  if (languageMatch) {
    return LOCALE_CONFIGURATIONS[languageMatch];
  }
  
  // Default to en-IN (India)
  return LOCALE_CONFIGURATIONS['en-IN'];
}

/**
 * Create default preferences based on browser locale
 * This is called when a user first signs up
 */
export function createDefaultPreferencesFromLocale(browserLocale?: string): Omit<UserPreferences, 'userId' | 'createdAt' | 'updatedAt'> {
  const localeConfig = detectLocaleFromBrowser(browserLocale);
  
  return {
    // Localization (from browser locale)
    currency: localeConfig.currency,
    locale: localeConfig.locale,
    language: localeConfig.locale.split('-')[0], // Extract language code
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Kolkata',
    
    // Regional Settings (from locale config)
    dateFormat: localeConfig.dateFormat as UserPreferences['dateFormat'],
    timeFormat: localeConfig.timeFormat as UserPreferences['timeFormat'],
    numberFormat: localeConfig.numberFormat as UserPreferences['numberFormat'],
    weekStartDay: localeConfig.weekStartDay as UserPreferences['weekStartDay'],
    
    // Financial Settings (from locale config)
    useFinancialYear: localeConfig.useFinancialYear,
    financialYearStartMonth: localeConfig.financialYearStartMonth,
    hideSensitiveData: false,
    
    // Display Settings
    theme: 'system',
    dashboardLayout: 'standard',
    chartType: 'mixed',
    
    // Notification Preferences
    budgetAlerts: true,
    goalMilestones: true,
    unusualSpending: true,
    recurringTransactions: true,
    emailNotifications: false,
    pushNotifications: false,
    
    // Privacy & Security
    biometricEnabled: true,
    autoLockTimeout: 900, // 15 minutes
    requireAuthForExport: true,
    
    // App Behavior
    autoCategorizze: true,
    duplicateDetection: true,
    smartSuggestions: true,
    
    // Metadata
    version: 1,
  };
}

// Default preferences for new users (using en-IN as base)
// Note: This is kept for backward compatibility but createDefaultPreferencesFromLocale should be used
export const DEFAULT_USER_PREFERENCES: Omit<UserPreferences, 'userId' | 'createdAt' | 'updatedAt'> = 
  createDefaultPreferencesFromLocale('en-IN');
