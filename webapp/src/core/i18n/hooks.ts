/**
 * Custom i18n Hook
 * Provides translation functions with TypeScript support
 */

import { useTranslation as useI18nTranslation } from 'react-i18next';
import { useAppStore } from '@/core/stores';

/**
 * Custom hook for translations
 * Automatically syncs with app store locale
 */
export function useTranslation() {
  const { locale } = useAppStore();
  const { t, i18n } = useI18nTranslation();

  // Sync locale with i18next
  if (i18n.language !== locale) {
    i18n.changeLanguage(locale);
  }

  return { t, i18n, locale };
}

/**
 * Format currency with current locale
 */
export function useLocalizedCurrency() {
  const { locale } = useAppStore();

  return (amount: number, currency = 'INR') => {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
    }).format(amount);
  };
}

/**
 * Format date with current locale
 */
export function useLocalizedDate() {
  const { locale } = useAppStore();

  return (
    date: Date | string,
    options?: Intl.DateTimeFormatOptions
  ) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return new Intl.DateTimeFormat(locale, options).format(dateObj);
  };
}

/**
 * Format number with current locale
 */
export function useLocalizedNumber() {
  const { locale } = useAppStore();

  return (value: number, options?: Intl.NumberFormatOptions) => {
    return new Intl.NumberFormat(locale, options).format(value);
  };
}

/**
 * Get text direction based on current locale
 */
export function useTextDirection(): 'ltr' | 'rtl' {
  const { locale } = useAppStore();
  
  // RTL languages
  const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
  const languageCode = locale.split('-')[0] || 'en';
  
  return rtlLanguages.includes(languageCode) ? 'rtl' : 'ltr';
}
