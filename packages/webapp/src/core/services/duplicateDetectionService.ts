/**
 * Duplicate Detection Service
 * Intelligent duplicate detection for transaction imports
 */

import { transactionRepository } from '@/core/db/repositories';
import type { Transaction } from '@/core/db/types';
import {
  getTransactionReference,
  referencesMatch,
} from '@/features/accounts/utils/referenceExtraction';

/**
 * Confidence level for duplicate matches
 */
export type DuplicateConfidence = 'exact' | 'high' | 'possible';

/**
 * A potential duplicate match
 */
export interface DuplicateMatch {
  existingTransaction: Transaction;
  confidence: DuplicateConfidence;
  matchReasons: string[];
  score: number; // 0-100
}

/**
 * Result of duplicate check
 */
export interface DuplicateCheckResult {
  isNewTransaction: boolean;
  duplicateMatches: DuplicateMatch[];
  bestMatch?: DuplicateMatch;
}

/**
 * Parsed transaction from import (before saving to DB)
 */
export interface ParsedTransaction {
  date: string | Date;
  description: string;
  amount: number;
  type: 'income' | 'expense' | 'transfer';
  category?: string;
  reference?: string; // Bank's transaction ID/reference
}

/**
 * Service for detecting duplicate transactions during import
 */
export class DuplicateDetectionService {
  /**
   * Check if a parsed transaction is a duplicate
   */
  async checkDuplicate(
    transaction: ParsedTransaction,
    accountId: string
  ): Promise<DuplicateCheckResult> {
    const matches: DuplicateMatch[] = [];

    // Normalize transaction date
    const txnDate =
      typeof transaction.date === 'string'
        ? new Date(transaction.date)
        : transaction.date;

    // Extract reference ID from explicit field or description
    const transactionRef = getTransactionReference(
      transaction.reference,
      transaction.description
    );

    // 1. Check by extracted reference ID (exact match - 100% confidence)
    if (transactionRef) {
      const exactMatch = await this.findByReferenceId(
        accountId,
        transactionRef
      );
      if (exactMatch) {
        matches.push({
          existingTransaction: exactMatch,
          confidence: 'exact',
          matchReasons: ['Same transaction reference ID'],
          score: 100,
        });

        // If we found an exact reference match, return immediately
        // No need to check fuzzy matches
        return {
          isNewTransaction: false,
          duplicateMatches: matches,
          bestMatch: matches[0],
        };
      }
    }

    // 2. Check by date + amount + description (strong match - 95-100% confidence)
    const strongMatches = await this.findByDateAmountDescription(
      accountId,
      txnDate,
      transaction.amount
    );

    for (const match of strongMatches) {
      // Calculate description similarity
      const similarity = this.calculateSimilarity(
        transaction.description,
        match.description || ''
      );

      if (similarity >= 90) {
        const reasons = [
          'Same date',
          'Same amount',
          `${similarity.toFixed(0)}% description match`,
        ];
        matches.push({
          existingTransaction: match,
          confidence: 'high',
          matchReasons: reasons,
          score: 95 + similarity / 20, // 95-100
        });
      }
    }

    // 3. Check by fuzzy match (possible duplicate - 70-90% confidence)
    if (matches.length === 0) {
      const fuzzyMatches = await this.findByFuzzyMatch(
        accountId,
        txnDate,
        transaction.amount
      );

      for (const match of fuzzyMatches) {
        const matchDate = new Date(match.date);
        const dateSimilar = this.isDateSimilar(txnDate, matchDate);
        const amountSimilar = this.isAmountSimilar(
          transaction.amount,
          match.amount
        );
        const descSimilarity = this.calculateSimilarity(
          transaction.description,
          match.description || ''
        );

        if (dateSimilar && amountSimilar && descSimilarity >= 70) {
          const reasons = [];
          if (dateSimilar) reasons.push('Date within 24 hours');
          if (amountSimilar) reasons.push('Amount within 1%');
          if (descSimilarity >= 70)
            reasons.push(`${descSimilarity.toFixed(0)}% description match`);

          const score =
            descSimilarity * 0.6 +
            (amountSimilar ? 20 : 0) +
            (dateSimilar ? 10 : 0);

          matches.push({
            existingTransaction: match,
            confidence: 'possible',
            matchReasons: reasons,
            score: Math.min(score, 95), // Cap at 95 for fuzzy matches
          });
        }
      }
    }

    // Sort matches by score (highest first)
    matches.sort((a, b) => b.score - a.score);

    return {
      isNewTransaction: matches.length === 0,
      duplicateMatches: matches,
      bestMatch: matches[0],
    };
  }

  /**
   * Batch check multiple transactions
   */
  async checkDuplicates(
    transactions: ParsedTransaction[],
    accountId: string
  ): Promise<DuplicateCheckResult[]> {
    return Promise.all(
      transactions.map((txn) => this.checkDuplicate(txn, accountId))
    );
  }

  /**
   * Find transaction by reference ID (exact match from import_transaction_id or extracted)
   */
  private async findByReferenceId(
    accountId: string,
    referenceId: string
  ): Promise<Transaction | null> {
    const all = await transactionRepository.findAll();

    return (
      all.find((t: Transaction) => {
        if (t.account_id !== accountId) return false;

        // Check import_transaction_id field
        if (t.import_transaction_id) {
          if (referencesMatch(t.import_transaction_id, referenceId)) {
            return true;
          }
        }

        // Also try extracting from description of existing transaction
        const existingRef = getTransactionReference(
          t.import_transaction_id,
          t.description
        );
        if (existingRef && referencesMatch(existingRef, referenceId)) {
          return true;
        }

        return false;
      }) || null
    );
  }

  /**
   * Find transactions by exact date, amount, and similar description
   */
  private async findByDateAmountDescription(
    accountId: string,
    date: Date,
    amount: number
  ): Promise<Transaction[]> {
    const all = await transactionRepository.findAll();

    // Filter to same account, date, and amount
    return all.filter((t: Transaction) => {
      if (t.account_id !== accountId) return false;

      const txnDate = new Date(t.date);
      const sameDate = txnDate.toDateString() === date.toDateString();

      const sameAmount = Math.abs(t.amount - amount) < 0.01; // Within 1 cent

      return sameDate && sameAmount;
    });
  }

  /**
   * Find transactions by fuzzy match (date proximity + amount similarity)
   */
  private async findByFuzzyMatch(
    accountId: string,
    date: Date,
    amount: number
  ): Promise<Transaction[]> {
    const all = await transactionRepository.findAll();

    // Get date range (24 hours before and after)
    const oneDayMs = 24 * 60 * 60 * 1000;
    const minDate = new Date(date.getTime() - oneDayMs);
    const maxDate = new Date(date.getTime() + oneDayMs);

    // Filter to transactions within range
    return all.filter((t: Transaction) => {
      if (t.account_id !== accountId) return false;

      const txnDate = new Date(t.date);
      const inDateRange = txnDate >= minDate && txnDate <= maxDate;

      const amountTolerance =
        Math.max(Math.abs(amount), Math.abs(t.amount)) * 0.01; // 1%
      const amountDiff = Math.abs(t.amount - amount);
      const similarAmount = amountDiff <= amountTolerance;

      return inDateRange && similarAmount;
    });
  }

  /**
   * Calculate string similarity using Levenshtein distance
   * Returns percentage (0-100)
   */
  private calculateSimilarity(str1: string, str2: string): number {
    // Normalize strings
    const s1 = this.normalizeString(str1);
    const s2 = this.normalizeString(str2);

    if (s1 === s2) return 100;
    if (s1.length === 0 && s2.length === 0) return 100;
    if (s1.length === 0 || s2.length === 0) return 0;

    // Calculate Levenshtein distance
    const distance = this.levenshteinDistance(s1, s2);
    const maxLength = Math.max(s1.length, s2.length);

    // Convert to similarity percentage
    return ((maxLength - distance) / maxLength) * 100;
  }

  /**
   * Normalize string for comparison
   */
  private normalizeString(str: string): string {
    return str
      .toLowerCase()
      .trim()
      .replace(/\s+/g, ' ') // Normalize whitespace
      .replace(/[^\w\s]/g, ''); // Remove special characters
  }

  /**
   * Calculate Levenshtein distance between two strings
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;

    // Create matrix
    const matrix: number[][] = Array(len1 + 1)
      .fill(null)
      .map(() => Array(len2 + 1).fill(0));

    // Initialize first column and row
    for (let i = 0; i <= len1; i++) {
      const row = matrix[i];
      if (row) row[0] = i;
    }
    for (let j = 0; j <= len2; j++) {
      const firstRow = matrix[0];
      if (firstRow) firstRow[j] = j;
    }

    // Fill matrix
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        const currentRow = matrix[i];
        const prevRow = matrix[i - 1];
        const prevCell = currentRow?.[j - 1];
        const aboveCell = prevRow?.[j];
        const diagCell = prevRow?.[j - 1];

        if (
          currentRow &&
          typeof prevCell === 'number' &&
          typeof aboveCell === 'number' &&
          typeof diagCell === 'number'
        ) {
          currentRow[j] = Math.min(
            aboveCell + 1, // Deletion
            prevCell + 1, // Insertion
            diagCell + cost // Substitution
          );
        }
      }
    }

    const lastRow = matrix[len1];
    return lastRow?.[len2] ?? 0;
  }

  /**
   * Check if two dates are within 24 hours of each other
   */
  private isDateSimilar(date1: Date, date2: Date): boolean {
    const diff = Math.abs(date1.getTime() - date2.getTime());
    const oneDayMs = 24 * 60 * 60 * 1000;
    return diff <= oneDayMs;
  }

  /**
   * Check if two amounts are within 1% of each other
   */
  private isAmountSimilar(amount1: number, amount2: number): boolean {
    const tolerance = Math.max(Math.abs(amount1), Math.abs(amount2)) * 0.01; // 1%
    const diff = Math.abs(amount1 - amount2);
    return diff <= tolerance;
  }
}

// Export singleton instance
export const duplicateDetectionService = new DuplicateDetectionService();
