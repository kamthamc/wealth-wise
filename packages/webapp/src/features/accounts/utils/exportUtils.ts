/**
 * Export utilities - STUB IMPLEMENTATION
 * Export functionality (PDF, Excel) is handled by Cloud Functions
 * TODO: Implement client-side calls to Cloud Functions for export
 */

import type { Account, Transaction } from '@/core/types';

/**
 * Export transactions to Excel format
 * Should call Cloud Function instead of client-side generation
 */
export async function exportToExcel(
  _transactions: Transaction[],
  _accountName: string
): Promise<void> {
  throw new Error('Excel export should be handled by Cloud Functions - not yet implemented');
}

/**
 * Export statement to PDF format
 * Should call Cloud Function instead of client-side generation
 */
export async function exportStatementToPDF(
  _account: Account,
  _transactions: Transaction[]
): Promise<void> {
  throw new Error('PDF export should be handled by Cloud Functions - not yet implemented');
}

/**
 * Export all accounts to Excel
 * Should call Cloud Function instead of client-side generation
 */
export async function exportAllAccountsToExcel(
  _accounts: Account[],
  _transactions: Transaction[]
): Promise<void> {
  throw new Error('Excel export should be handled by Cloud Functions - not yet implemented');
}
