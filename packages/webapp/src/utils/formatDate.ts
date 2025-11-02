/**
 * Date Formatting Utilities
 * Formats dates based on user preferences (dateFormat and locale)
 */

import type { UserPreferences } from '@svc/wealth-wise-shared-types';

/**
 * Format a date according to user's preferred format
 * 
 * @param date - Date to format (Date object or ISO string)
 * @param dateFormat - Format preference ('DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD', etc.)
 * @param locale - Locale for localized formatting
 * @returns Formatted date string
 * 
 * @example
 * formatDate(new Date('2025-11-02'), 'DD/MM/YYYY') // '02/11/2025'
 * formatDate(new Date('2025-11-02'), 'MM/DD/YYYY') // '11/02/2025'
 * formatDate(new Date('2025-11-02'), 'YYYY-MM-DD') // '2025-11-02'
 */
export function formatDate(
  date: Date | string,
  dateFormat: string = 'DD/MM/YYYY',
  locale: string = 'en-IN'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  
  if (isNaN(d.getTime())) {
    console.warn('Invalid date:', date);
    return 'Invalid Date';
  }

  const day = d.getDate();
  const month = d.getMonth() + 1;
  const year = d.getFullYear();
  
  const dd = String(day).padStart(2, '0');
  const mm = String(month).padStart(2, '0');
  const yyyy = String(year);

  switch (dateFormat) {
    case 'DD/MM/YYYY':
      return `${dd}/${mm}/${yyyy}`;
    case 'MM/DD/YYYY':
      return `${mm}/${dd}/${yyyy}`;
    case 'YYYY-MM-DD':
      return `${yyyy}-${mm}-${dd}`;
    case 'DD.MM.YYYY':
      return `${dd}.${mm}.${yyyy}`;
    case 'YYYY/MM/DD':
      return `${yyyy}/${mm}/${dd}`;
    case 'DD-MM-YYYY':
      return `${dd}-${mm}-${yyyy}`;
    default:
      // Use Intl.DateTimeFormat as fallback
      try {
        return new Intl.DateTimeFormat(locale).format(d);
      } catch (error) {
        console.warn(`Invalid locale: ${locale}`, error);
        return `${dd}/${mm}/${yyyy}`;
      }
  }
}

/**
 * Format date with time
 * 
 * @example
 * formatDateTime(new Date(), 'DD/MM/YYYY', '12h') // '02/11/2025, 1:30 PM'
 * formatDateTime(new Date(), 'YYYY-MM-DD', '24h') // '2025-11-02, 13:30'
 */
export function formatDateTime(
  date: Date | string,
  dateFormat: string = 'DD/MM/YYYY',
  timeFormat: '12h' | '24h' = '12h',
  locale: string = 'en-IN'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  
  if (isNaN(d.getTime())) {
    return 'Invalid Date';
  }

  const datePart = formatDate(d, dateFormat, locale);
  const timePart = formatTime(d, timeFormat, locale);
  
  return `${datePart}, ${timePart}`;
}

/**
 * Format time only
 * 
 * @example
 * formatTime(new Date(), '12h') // '1:30 PM'
 * formatTime(new Date(), '24h') // '13:30'
 */
export function formatTime(
  date: Date | string,
  timeFormat: '12h' | '24h' = '12h',
  locale: string = 'en-IN'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  
  if (isNaN(d.getTime())) {
    return 'Invalid Time';
  }

  try {
    return new Intl.DateTimeFormat(locale, {
      hour: 'numeric',
      minute: '2-digit',
      hour12: timeFormat === '12h',
    }).format(d);
  } catch (error) {
    console.warn(`Invalid time format: ${timeFormat}`, error);
    const hours = d.getHours();
    const minutes = d.getMinutes();
    
    if (timeFormat === '24h') {
      return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
    } else {
      const hour12 = hours % 12 || 12;
      const ampm = hours < 12 ? 'AM' : 'PM';
      return `${hour12}:${String(minutes).padStart(2, '0')} ${ampm}`;
    }
  }
}

/**
 * Format date in relative terms (e.g., "2 days ago", "in 3 hours")
 * 
 * @example
 * formatRelativeDate(new Date(Date.now() - 86400000)) // '1 day ago'
 * formatRelativeDate(new Date(Date.now() + 3600000)) // 'in 1 hour'
 */
export function formatRelativeDate(
  date: Date | string,
  locale: string = 'en-IN'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  
  if (isNaN(d.getTime())) {
    return 'Invalid Date';
  }

  try {
    const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
    const now = new Date();
    const diffMs = d.getTime() - now.getTime();
    const diffSeconds = Math.round(diffMs / 1000);
    const diffMinutes = Math.round(diffSeconds / 60);
    const diffHours = Math.round(diffMinutes / 60);
    const diffDays = Math.round(diffHours / 24);
    const diffMonths = Math.round(diffDays / 30);
    const diffYears = Math.round(diffDays / 365);

    // Choose appropriate unit
    if (Math.abs(diffYears) >= 1) {
      return rtf.format(diffYears, 'year');
    } else if (Math.abs(diffMonths) >= 1) {
      return rtf.format(diffMonths, 'month');
    } else if (Math.abs(diffDays) >= 1) {
      return rtf.format(diffDays, 'day');
    } else if (Math.abs(diffHours) >= 1) {
      return rtf.format(diffHours, 'hour');
    } else if (Math.abs(diffMinutes) >= 1) {
      return rtf.format(diffMinutes, 'minute');
    } else {
      return rtf.format(diffSeconds, 'second');
    }
  } catch (error) {
    console.warn(`Cannot format relative date:`, error);
    return formatDate(d, 'DD/MM/YYYY', locale);
  }
}

/**
 * Format date range
 * 
 * @example
 * formatDateRange(startDate, endDate, 'DD/MM/YYYY') // '01/11/2025 - 30/11/2025'
 */
export function formatDateRange(
  startDate: Date | string,
  endDate: Date | string,
  dateFormat: string = 'DD/MM/YYYY',
  locale: string = 'en-IN'
): string {
  const start = formatDate(startDate, dateFormat, locale);
  const end = formatDate(endDate, dateFormat, locale);
  return `${start} - ${end}`;
}

/**
 * Format month and year
 * 
 * @example
 * formatMonthYear(new Date('2025-11-02'), 'en-IN') // 'November 2025'
 * formatMonthYear(new Date('2025-11-02'), 'en-US') // 'November 2025'
 */
export function formatMonthYear(
  date: Date | string,
  locale: string = 'en-IN'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  
  if (isNaN(d.getTime())) {
    return 'Invalid Date';
  }

  try {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'long',
    }).format(d);
  } catch (error) {
    console.warn(`Invalid locale: ${locale}`, error);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return `${months[d.getMonth()]} ${d.getFullYear()}`;
  }
}

/**
 * Format month only (short form)
 * 
 * @example
 * formatMonthShort(new Date('2025-11-02'), 'en-IN') // 'Nov'
 */
export function formatMonthShort(
  date: Date | string,
  locale: string = 'en-IN'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  
  if (isNaN(d.getTime())) {
    return 'Invalid';
  }

  try {
    return new Intl.DateTimeFormat(locale, {
      month: 'short',
    }).format(d);
  } catch (error) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[d.getMonth()] || 'Invalid';
  }
}

/**
 * Format using user preferences
 * Convenience wrapper that uses UserPreferences object
 * 
 * @example
 * const prefs = await preferencesApi.getUserPreferences();
 * formatDateWithPreferences(new Date(), prefs) // Uses user's date format and locale
 */
export function formatDateWithPreferences(
  date: Date | string,
  preferences: Pick<UserPreferences, 'dateFormat' | 'locale'>
): string {
  return formatDate(date, preferences.dateFormat, preferences.locale);
}

/**
 * Parse date string to Date object
 * Handles various formats based on user preference
 * 
 * @example
 * parseDate('02/11/2025', 'DD/MM/YYYY') // Date object for Nov 2, 2025
 * parseDate('11/02/2025', 'MM/DD/YYYY') // Date object for Nov 2, 2025
 */
export function parseDate(
  dateString: string,
  dateFormat: string = 'DD/MM/YYYY'
): Date | null {
  const parts = dateString.split(/[\/\-\.]/);
  
  if (parts.length !== 3 || !parts[0] || !parts[1] || !parts[2]) {
    console.warn('Invalid date string:', dateString);
    return null;
  }

  let day: number, month: number, year: number;

  switch (dateFormat) {
    case 'DD/MM/YYYY':
    case 'DD-MM-YYYY':
    case 'DD.MM.YYYY':
      day = parseInt(parts[0]!, 10);
      month = parseInt(parts[1]!, 10);
      year = parseInt(parts[2]!, 10);
      break;
    case 'MM/DD/YYYY':
      month = parseInt(parts[0]!, 10);
      day = parseInt(parts[1]!, 10);
      year = parseInt(parts[2]!, 10);
      break;
    case 'YYYY-MM-DD':
    case 'YYYY/MM/DD':
      year = parseInt(parts[0]!, 10);
      month = parseInt(parts[1]!, 10);
      day = parseInt(parts[2]!, 10);
      break;
    default:
      return new Date(dateString);
  }

  const date = new Date(year, month - 1, day);
  
  if (isNaN(date.getTime())) {
    console.warn('Invalid date components:', { day, month, year });
    return null;
  }

  return date;
}

/**
 * Get date format placeholder for input fields
 * 
 * @example
 * getDateFormatPlaceholder('DD/MM/YYYY') // 'dd/mm/yyyy'
 * getDateFormatPlaceholder('MM/DD/YYYY') // 'mm/dd/yyyy'
 */
export function getDateFormatPlaceholder(dateFormat: string): string {
  return dateFormat.toLowerCase();
}
