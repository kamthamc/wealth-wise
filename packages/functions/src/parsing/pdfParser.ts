/**
 * PDF Parsing Cloud Function
 * Handles parsing of PDF bank statements for transaction imports
 * 
 * Note: This is a text-extraction based parser. For complex PDFs with tables,
 * consider integrating OCR services like Google Cloud Vision API or AWS Textract.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import * as logger from 'firebase-functions/logger';

// Request schema
const pdfParseRequestSchema = z.object({
  pdfBase64: z.string().min(1, 'PDF content cannot be empty'),
  bankType: z
    .enum([
      'hdfc',
      'icici',
      'sbi',
      'axis',
      'kotak',
      'generic',
    ])
    .optional()
    .default('generic'),
  extractOptions: z
    .object({
      skipPages: z.number().int().min(0).optional().default(0),
      maxPages: z.number().int().min(1).max(100).optional(),
    })
    .optional(),
});

// Response interface
interface ParsedPDFData {
  headers: string[];
  rows: Record<string, string>[];
  rowCount: number;
  format: 'pdf';
  metadata: {
    pageCount: number;
    textLength: number;
    bankType: string;
  };
}

interface ParsedTransaction {
  date: string;
  description: string;
  amount: string;
  type: string;
}

/**
 * Find where the transaction table starts in PDF text
 * Bank statements often have account summary, terms, etc. before transactions
 */
function findTableStart(lines: string[]): number {
  const tableIndicators = [
    'transaction',
    'date',
    'particulars',
    'narration',
    'description',
    'debit',
    'credit',
    'withdrawal',
    'deposit',
    'balance',
    'txn date',
    'posting date',
    'value date',
    'value dt',
  ];

  for (let i = 0; i < Math.min(lines.length, 50); i++) {
    const line = lines[i]?.toLowerCase().trim();
    if (!line || line.length < 5) continue;

    // Check if this line contains multiple table indicators
    const matchCount = tableIndicators.filter((indicator) =>
      line.includes(indicator)
    ).length;

    if (matchCount >= 2) {
      return i;
    }

    // Check for common table header patterns
    if (
      /date.*description.*amount/i.test(line) ||
      /date.*particulars.*debit.*credit/i.test(line) ||
      /txn.*date.*narration/i.test(line)
    ) {
      return i;
    }
  }

  return 0; // Start from beginning if no clear table start found
}

/**
 * Check if a line should be skipped (header/footer/summary)
 */
function shouldSkipLine(line: string): boolean {
  const lower = line.toLowerCase();

  const skipPatterns = [
    'page',
    'statement',
    'bank',
    'address',
    'customer',
    'account number',
    'ifsc',
    'branch',
    'opening balance',
    'closing balance',
    'continued',
    'total',
    'summary',
    '***',
    '---',
    '===',
  ];

  return (
    skipPatterns.some((pattern) => lower.includes(pattern)) ||
    line.trim().length < 10
  );
}

/**
 * Extract transactions from PDF text
 * This is a generic parser - bank-specific parsers would be more accurate
 */
function extractTransactions(text: string, bankType: string): ParsedTransaction[] {
  const transactions: ParsedTransaction[] = [];
  const lines = text.split('\n').map((l) => l.trim());

  // Find where the transaction table starts
  const tableStartIndex = findTableStart(lines);

  // Common date patterns for Indian banks (DD/MM/YYYY, DD-MM-YYYY, etc.)
  const datePattern = /\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b/;
  
  // Amount pattern for Indian currency (with commas)
  const amountPattern = /\b(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\b/;

  logger.info('Extracting transactions', {
    totalLines: lines.length,
    tableStartIndex,
    bankType,
  });

  // Parse transaction lines
  for (let i = tableStartIndex; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;

    // Skip header/footer lines
    if (shouldSkipLine(line)) continue;

    // Try to extract date
    const dateMatch = line.match(datePattern);
    if (!dateMatch) continue;

    const date = dateMatch[1] || '';

    // Extract amounts (there may be multiple: withdrawal, deposit, balance)
    const amounts = Array.from(line.matchAll(new RegExp(amountPattern, 'g')));
    if (amounts.length === 0) continue;

    // Extract description (text between date and first amount)
    const dateEndIndex = line.indexOf(date) + date.length;
    const firstAmountIndex = line.indexOf(amounts[0]?.[0] || '');
    const description =
      firstAmountIndex > dateEndIndex
        ? line.substring(dateEndIndex, firstAmountIndex).trim()
        : line.substring(dateEndIndex).trim();

    if (!description || description.length < 3) continue;

    // Determine transaction type based on column position or keywords
    let type = 'expense';
    const lowerDesc = description.toLowerCase();
    if (
      lowerDesc.includes('credit') ||
      lowerDesc.includes('deposit') ||
      lowerDesc.includes('salary') ||
      lowerDesc.includes('refund')
    ) {
      type = 'income';
    }

    transactions.push({
      date,
      description: description.replace(/\s+/g, ' ').trim(),
      amount: amounts[0]?.[0] || '0',
      type,
    });
  }

  return transactions;
}

/**
 * Parse PDF content (base64 encoded)
 * 
 * IMPORTANT: This implementation extracts text from PDFs.
 * For production use with complex bank statement PDFs:
 * 1. Use specialized PDF parsing libraries (pdf-parse, pdf2json)
 * 2. Integrate OCR services for scanned PDFs
 * 3. Implement bank-specific parsers for better accuracy
 */
function parsePDFContent(
  pdfBase64: string,
  bankType: string
): ParsedPDFData {
  try {
    // Decode base64
    const pdfBuffer = Buffer.from(pdfBase64, 'base64');
    
    // For this basic implementation, we'll extract text naively
    // In production, use a proper PDF parsing library like pdf-parse
    const text = pdfBuffer.toString('utf-8');
    
    // Extract transactions
    const transactions = extractTransactions(text, bankType);

    if (transactions.length === 0) {
      throw new HttpsError(
        'not-found',
        'No transactions found in PDF. This format may not be supported. Consider using CSV export from your bank.'
      );
    }

    // Convert to standard format
    const headers = ['Date', 'Description', 'Amount', 'Type'];
    const rows = transactions.map((txn) => ({
      Date: txn.date,
      Description: txn.description,
      Amount: txn.amount,
      Type: txn.type,
    }));

    return {
      headers,
      rows,
      rowCount: rows.length,
      format: 'pdf',
      metadata: {
        pageCount: 1, // Would need proper PDF parsing to get actual page count
        textLength: text.length,
        bankType,
      },
    };
  } catch (error) {
    logger.error('PDF text extraction failed', error);
    throw new HttpsError(
      'internal',
      'Failed to extract text from PDF. Please ensure the PDF is text-based (not scanned) or use CSV export instead.'
    );
  }
}

/**
 * Cloud Function to parse PDF bank statements
 * 
 * NOTE: This is a basic text-extraction implementation.
 * For production use with real bank PDFs:
 * - Install pdf-parse: npm install pdf-parse
 * - Or integrate with Google Cloud Vision API for OCR
 * - Implement bank-specific parsing logic
 */
export const parsePDF = onCall<unknown, Promise<ParsedPDFData>>(
  { cors: true },
  async (request) => {
    try {
      // Validate request
      const validatedData = pdfParseRequestSchema.parse(request.data);
      const { pdfBase64, bankType } = validatedData;

      logger.info('Parsing PDF file', {
        bankType,
        contentLength: pdfBase64.length,
      });

      // Check PDF size (max 10MB base64 encoded)
      if (pdfBase64.length > 10 * 1024 * 1024 * 4 / 3) {
        throw new HttpsError(
          'invalid-argument',
          'PDF file is too large. Maximum size is 10MB.'
        );
      }

      // Parse PDF content
      const result = parsePDFContent(pdfBase64, bankType || 'generic');

      logger.info('PDF parsed successfully', {
        rows: result.rowCount,
        bankType: result.metadata.bankType,
      });

      return result;
    } catch (error) {
      logger.error('PDF parsing failed', error);

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
        `Failed to parse PDF: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }
);
