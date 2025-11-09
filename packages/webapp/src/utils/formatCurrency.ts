/**
 * Currency Formatting Utilities
 * Formats monetary values based on user preferences (currency and locale)
 */

import type { UserPreferences } from '@svc/wealth-wise-shared-types';

/**
 * Format a number as currency with proper locale formatting
 * 
 * @param amount - The amount to format
 * @param currency - Currency code (ISO 4217) e.g., 'INR', 'USD', 'EUR'
 * @param locale - Locale code (BCP 47) e.g., 'en-IN', 'en-US'
 * @returns Formatted currency string
 * 
 * @example
 * formatCurrency(1000000, 'INR', 'en-IN') // '₹10,00,000.00'
 * formatCurrency(1000000, 'USD', 'en-US') // '$1,000,000.00'
 * formatCurrency(1000000, 'EUR', 'de-DE') // '1.000.000,00 €'
 */
export function formatCurrency(
  amount: number,
  currency: string = 'INR',
  locale: string = 'en-IN'
): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);
  } catch (error) {
    // Fallback if locale/currency is invalid
    console.warn(`Invalid currency format: ${currency} / ${locale}`, error);
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(amount);
  }
}

/**
 * Format currency without decimal places
 * Useful for large amounts where cents don't matter
 * 
 * @example
 * formatCurrencyWhole(1000000, 'INR', 'en-IN') // '₹10,00,000'
 */
export function formatCurrencyWhole(
  amount: number,
  currency: string = 'INR',
  locale: string = 'en-IN'
): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch (error) {
    console.warn(`Invalid currency format: ${currency} / ${locale}`, error);
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  }
}

/**
 * Format currency in compact form (with K, M, B suffixes)
 * Useful for displaying large numbers in limited space
 * 
 * @example
 * formatCurrencyCompact(1000000, 'INR', 'en-IN') // '₹10L' or '₹1M'
 * formatCurrencyCompact(1000000, 'USD', 'en-US') // '$1M'
 */
export function formatCurrencyCompact(
  amount: number,
  currency: string = 'INR',
  locale: string = 'en-IN'
): string {
  try {
    const formatter = new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currency,
      notation: 'compact',
      maximumFractionDigits: 1,
    });
    return formatter.format(amount);
  } catch (error) {
    console.warn(`Invalid currency format: ${currency} / ${locale}`, error);
    // Fallback with manual compact notation
    return formatCurrencyManualCompact(amount, currency, locale);
  }
}

/**
 * Manual compact formatting for browsers that don't support Intl.NumberFormat compact notation
 * @private
 */
function formatCurrencyManualCompact(
  amount: number,
  currency: string,
  locale: string
): string {
  const absAmount = Math.abs(amount);
  let suffix = '';
  let divisor = 1;

  // Indian numbering system (Lakh, Crore)
  if (locale.startsWith('en-IN') || locale === 'hi-IN') {
    if (absAmount >= 10000000) {
      // 1 Crore
      suffix = 'Cr';
      divisor = 10000000;
    } else if (absAmount >= 100000) {
      // 1 Lakh
      suffix = 'L';
      divisor = 100000;
    } else if (absAmount >= 1000) {
      suffix = 'K';
      divisor = 1000;
    }
  } else {
    // Western numbering system (Thousand, Million, Billion)
    if (absAmount >= 1000000000) {
      suffix = 'B';
      divisor = 1000000000;
    } else if (absAmount >= 1000000) {
      suffix = 'M';
      divisor = 1000000;
    } else if (absAmount >= 1000) {
      suffix = 'K';
      divisor = 1000;
    }
  }

  const scaledAmount = amount / divisor;
  const formatted = formatCurrency(scaledAmount, currency, locale);
  
  // Add suffix before currency symbol if present, otherwise append
  return suffix ? formatted.replace(/(\d+(?:\.\d+)?)/, `$1${suffix}`) : formatted;
}

/**
 * Format number with locale-specific formatting (without currency symbol)
 * Useful for displaying percentages, rates, or quantities
 * 
 * @example
 * formatNumber(1000000, 'en-IN') // '10,00,000'
 * formatNumber(1000000, 'en-US') // '1,000,000'
 */
export function formatNumber(
  value: number,
  locale: string = 'en-IN',
  decimals: number = 2
): string {
  try {
    return new Intl.NumberFormat(locale, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(value);
  } catch (error) {
    console.warn(`Invalid number format: ${locale}`, error);
    return value.toFixed(decimals);
  }
}

/**
 * Format percentage with locale-specific formatting
 * 
 * @example
 * formatPercentage(0.1523, 'en-IN') // '15.23%'
 * formatPercentage(0.1523, 'en-US', 1) // '15.2%'
 */
export function formatPercentage(
  value: number,
  locale: string = 'en-IN',
  decimals: number = 2
): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: 'percent',
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(value);
  } catch (error) {
    console.warn(`Invalid percentage format: ${locale}`, error);
    return `${(value * 100).toFixed(decimals)}%`;
  }
}

/**
 * Get currency symbol for a given currency code
 * 
 * @example
 * getCurrencySymbol('INR', 'en-IN') // '₹'
 * getCurrencySymbol('USD', 'en-US') // '$'
 */
export function getCurrencySymbol(
  currency: string = 'INR',
  locale: string = 'en-IN'
): string {
  try {
    const parts = new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currency,
    }).formatToParts(0);
    
    const symbolPart = parts.find(part => part.type === 'currency');
    return symbolPart?.value || currency;
  } catch (error) {
    console.warn(`Cannot get currency symbol: ${currency}`, error);
    return currency;
  }
}

/**
 * Format using user preferences
 * Convenience wrapper that uses UserPreferences object
 * 
 * @example
 * const prefs = await preferencesApi.getUserPreferences();
 * formatCurrencyWithPreferences(1000000, prefs) // Uses user's currency and locale
 */
export function formatCurrencyWithPreferences(
  amount: number,
  preferences: Pick<UserPreferences, 'currency' | 'locale'>
): string {
  return formatCurrency(amount, preferences.currency, preferences.locale);
}

/**
 * Format currency for display in tables/lists (compact form)
 */
export function formatCurrencyForTable(
  amount: number,
  currency: string = 'INR',
  locale: string = 'en-IN'
): string {
  const absAmount = Math.abs(amount);
  
  // Use compact format for large numbers
  if (absAmount >= 100000) {
    return formatCurrencyCompact(amount, currency, locale);
  }
  
  // Use whole numbers for medium amounts
  if (absAmount >= 1000) {
    return formatCurrencyWhole(amount, currency, locale);
  }
  
  // Use full format for small amounts
  return formatCurrency(amount, currency, locale);
}

/**
 * Parse currency string back to number
 * Removes currency symbols and formatting
 * 
 * @example
 * parseCurrency('₹10,00,000.00') // 1000000
 * parseCurrency('$1,000,000.00') // 1000000
 */
export function parseCurrency(currencyString: string): number {
  // Remove all non-digit characters except decimal point and minus
  const cleaned = currencyString.replace(/[^\d.-]/g, '');
  return parseFloat(cleaned) || 0;
}
