/**
 * CSV Parsing Cloud Function
 * Handles parsing of CSV files for transaction and account imports
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import * as logger from 'firebase-functions/logger';

// Request schema
const csvParseRequestSchema = z.object({
  csvContent: z.string().min(1, 'CSV content cannot be empty'),
  fileType: z.enum(['transactions', 'accounts']).default('transactions'),
  skipRows: z.number().int().min(0).max(100).optional().default(0),
});

// Response interface
interface ParsedCSVData {
  headers: string[];
  rows: Record<string, string>[];
  rowCount: number;
  format: 'csv';
  detectedHeaders: {
    hasDate: boolean;
    hasAmount: boolean;
    hasDescription: boolean;
  };
}

/**
 * Parse a single CSV line handling quotes and commas properly
 */
function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    const nextChar = line[i + 1];

    if (char === '"') {
      if (inQuotes && nextChar === '"') {
        // Escaped quote
        current += '"';
        i++;
      } else {
        // Toggle quote state
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      // End of field
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }

  result.push(current.trim());
  return result;
}

/**
 * Find the header row in CSV content
 * Bank statements often have summary info at the top
 */
function findHeaderRow(lines: string[]): number {
  // Including HDFC-specific and common banking terms
  const headerKeywords = [
    'date',
    'description',
    'amount',
    'type',
    'category',
    'debit',
    'credit',
    'balance',
    'narration',
    'particulars',
    'withdrawal',
    'deposit',
    'value dt',
    'value date',
    'txn date',
    'posting date',
    'chq',
    'ref.no',
    'ref no',
    'withdrawal amt',
    'deposit amt',
    'closing balance',
  ];

  // Check first 10 lines for header row
  for (let i = 0; i < Math.min(lines.length, 10); i++) {
    const line = lines[i];
    if (!line) continue;

    const lowerLine = line.toLowerCase();
    const matchCount = headerKeywords.filter((keyword) =>
      lowerLine.includes(keyword)
    ).length;

    // If line contains at least 2 header keywords, it's likely the header
    if (matchCount >= 2) {
      return i;
    }
  }

  return 0; // Default to first line if no clear header found
}

/**
 * Detect header types to help with column mapping
 */
function detectHeaderTypes(headers: string[]): {
  hasDate: boolean;
  hasAmount: boolean;
  hasDescription: boolean;
} {
  const headerText = headers.join(' ').toLowerCase();

  return {
    hasDate: /date|dt|txn|posting|value/.test(headerText),
    hasAmount: /amount|debit|credit|withdrawal|deposit|balance/.test(
      headerText
    ),
    hasDescription: /description|narration|particulars|details|remark/.test(
      headerText
    ),
  };
}

/**
 * Parse CSV content into structured data
 */
function parseCSVContent(
  csvContent: string,
  skipRows: number = 0
): ParsedCSVData {
  // Split into lines and filter empty lines
  const allLines = csvContent
    .split(/\r?\n/)
    .filter((line) => line.trim())
    .slice(skipRows);

  if (allLines.length < 2) {
    throw new HttpsError(
      'invalid-argument',
      'CSV must have at least a header row and one data row'
    );
  }

  // Find header row (may not be first line if there's summary info)
  const headerIndex = findHeaderRow(allLines);
  const lines = allLines.slice(headerIndex);

  // Parse headers
  const headers = parseCSVLine(lines[0]!);

  if (headers.length === 0) {
    throw new HttpsError('invalid-argument', 'No headers found in CSV');
  }

  // Parse data rows
  const rows: Record<string, string>[] = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;

    const values = parseCSVLine(line);
    const row: Record<string, string> = {};

    headers.forEach((header, index) => {
      row[header] = values[index] || '';
    });

    // Only include rows with at least some data
    if (Object.values(row).some((v) => v.trim() !== '')) {
      rows.push(row);
    }
  }

  // Detect header types for better UI guidance
  const detectedHeaders = detectHeaderTypes(headers);

  return {
    headers,
    rows,
    rowCount: rows.length,
    format: 'csv',
    detectedHeaders,
  };
}

/**
 * Cloud Function to parse CSV files
 * Handles transaction and account CSV imports with intelligent header detection
 */
export const parseCSV = onCall<unknown, Promise<ParsedCSVData>>(
  { cors: true },
  async (request) => {
    try {
      // Validate request
      const validatedData = csvParseRequestSchema.parse(request.data);
      const { csvContent, fileType, skipRows } = validatedData;

      logger.info('Parsing CSV file', {
        fileType,
        skipRows,
        contentLength: csvContent.length,
      });

      // Parse CSV content
      const result = parseCSVContent(csvContent, skipRows);

      logger.info('CSV parsed successfully', {
        headers: result.headers.length,
        rows: result.rowCount,
        detectedHeaders: result.detectedHeaders,
      });

      return result;
    } catch (error) {
      logger.error('CSV parsing failed', error);

      if (error instanceof z.ZodError) {
        throw new HttpsError(
          'invalid-argument',
          `Invalid request: ${error.issues.map((e: z.ZodIssue) => e.message).join(', ')}`
        );
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        'internal',
        `Failed to parse CSV: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }
);
