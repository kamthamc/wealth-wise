/**
 * Firebase Utilities
 * Helpers for working with Firebase-specific types like Timestamp
 */

import { Timestamp } from 'firebase/firestore';

/**
 * Convert Firebase Timestamp to JavaScript Date
 */
export function timestampToDate(timestamp: Timestamp | Date | string): Date {
  if (timestamp instanceof Date) {
    return timestamp;
  }
  
  if (typeof timestamp === 'string') {
    return new Date(timestamp);
  }
  
  if (timestamp && typeof timestamp === 'object' && 'toDate' in timestamp) {
    return timestamp.toDate();
  }
  
  return new Date();
}

/**
 * Convert Date to Firebase Timestamp
 */
export function dateToTimestamp(date: Date | string): Timestamp {
  if (typeof date === 'string') {
    return Timestamp.fromDate(new Date(date));
  }
  return Timestamp.fromDate(date);
}

/**
 * Get current timestamp
 */
export function now(): Timestamp {
  return Timestamp.now();
}

/**
 * Compare two timestamps/dates
 */
export function isAfter(a: Timestamp | Date, b: Timestamp | Date): boolean {
  const dateA = timestampToDate(a);
  const dateB = timestampToDate(b);
  return dateA.getTime() > dateB.getTime();
}

export function isBefore(a: Timestamp | Date, b: Timestamp | Date): boolean {
  const dateA = timestampToDate(a);
  const dateB = timestampToDate(b);
  return dateA.getTime() < dateB.getTime();
}

export function isSameDay(a: Timestamp | Date, b: Timestamp | Date): boolean {
  const dateA = timestampToDate(a);
  const dateB = timestampToDate(b);
  return (
    dateA.getFullYear() === dateB.getFullYear() &&
    dateA.getMonth() === dateB.getMonth() &&
    dateA.getDate() === dateB.getDate()
  );
}

/**
 * Format timestamp to ISO string
 */
export function timestampToISO(timestamp: Timestamp | Date): string {
  return timestampToDate(timestamp).toISOString();
}

/**
 * Check if value is a Firebase Timestamp
 */
export function isTimestamp(value: unknown): value is Timestamp {
  return value instanceof Timestamp || (value !== null && typeof value === 'object' && 'toDate' in value && typeof (value as any).toDate === 'function');
}
