/**
 * File Parsing API Client
 * Calls Cloud Functions for CSV, Excel, and PDF parsing
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/firebase';

// Type definitions matching Cloud Functions responses
export interface ParsedFileData {
  headers: string[];
  rows: Record<string, string>[];
  rowCount: number;
  format: 'csv' | 'excel' | 'pdf';
  detectedHeaders?: {
    hasDate: boolean;
    hasAmount: boolean;
    hasDescription: boolean;
  };
  metadata?: {
    pageCount?: number;
    textLength?: number;
    bankType?: string;
    sheetName?: string;
    totalSheets?: number;
    availableSheets?: string[];
  };
}

/**
 * Parse CSV file using Cloud Function
 */
export async function parseCSVFile(
  file: File,
  options?: {
    skipRows?: number;
    fileType?: 'transactions' | 'accounts';
  }
): Promise<ParsedFileData> {
  try {
    // Read file content as text
    const csvContent = await file.text();

    // Call Cloud Function
    const parseCSV = httpsCallable<
      {
        csvContent: string;
        fileType?: 'transactions' | 'accounts';
        skipRows?: number;
      },
      ParsedFileData
    >(functions, 'parseCSV');

    const result = await parseCSV({
      csvContent,
      fileType: options?.fileType,
      skipRows: options?.skipRows,
    });

    return result.data;
  } catch (error) {
    console.error('CSV parsing failed:', error);
    throw new Error(
      `Failed to parse CSV file: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Parse PDF file using Cloud Function
 */
export async function parsePDFFile(
  file: File,
  options?: {
    bankType?: 'hdfc' | 'icici' | 'sbi' | 'axis' | 'kotak' | 'generic';
    skipPages?: number;
    maxPages?: number;
  }
): Promise<ParsedFileData> {
  try {
    // Read file content as ArrayBuffer and convert to base64
    const arrayBuffer = await file.arrayBuffer();
    const base64 = btoa(
      new Uint8Array(arrayBuffer).reduce(
        (data, byte) => data + String.fromCharCode(byte),
        ''
      )
    );

    // Call Cloud Function
    const parsePDF = httpsCallable<
      {
        pdfBase64: string;
        bankType?: string;
        extractOptions?: {
          skipPages?: number;
          maxPages?: number;
        };
      },
      ParsedFileData
    >(functions, 'parsePDF');

    const result = await parsePDF({
      pdfBase64: base64,
      bankType: options?.bankType,
      extractOptions: {
        skipPages: options?.skipPages,
        maxPages: options?.maxPages,
      },
    });

    return result.data;
  } catch (error) {
    console.error('PDF parsing failed:', error);
    throw new Error(
      `Failed to parse PDF file: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Parse Excel file using Cloud Function
 */
export async function parseExcelFile(
  file: File,
  options?: {
    sheetName?: string;
    sheetIndex?: number;
    skipRows?: number;
  }
): Promise<ParsedFileData> {
  try {
    // Read file content as ArrayBuffer and convert to base64
    const arrayBuffer = await file.arrayBuffer();
    const base64 = btoa(
      new Uint8Array(arrayBuffer).reduce(
        (data, byte) => data + String.fromCharCode(byte),
        ''
      )
    );

    // Call Cloud Function
    const parseExcel = httpsCallable<
      {
        excelBase64: string;
        sheetName?: string;
        sheetIndex?: number;
        skipRows?: number;
      },
      ParsedFileData
    >(functions, 'parseExcel');

    const result = await parseExcel({
      excelBase64: base64,
      sheetName: options?.sheetName,
      sheetIndex: options?.sheetIndex,
      skipRows: options?.skipRows,
    });

    return result.data;
  } catch (error) {
    console.error('Excel parsing failed:', error);
    throw new Error(
      `Failed to parse Excel file: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Detect file format and parse using appropriate Cloud Function
 */
export async function parseFile(file: File): Promise<ParsedFileData> {
  const extension = file.name.split('.').pop()?.toLowerCase();

  switch (extension) {
    case 'csv':
      return parseCSVFile(file);

    case 'xlsx':
    case 'xls':
      return parseExcelFile(file);

    case 'pdf':
      return parsePDFFile(file);

    default:
      throw new Error(
        `Unsupported file format: ${extension}. Please upload CSV, Excel (.xlsx, .xls), or PDF files.`
      );
  }
}

/**
 * Detect file format from extension
 */
export function detectFileFormat(
  file: File
): 'csv' | 'excel' | 'pdf' | 'unknown' {
  const extension = file.name.split('.').pop()?.toLowerCase();

  switch (extension) {
    case 'csv':
      return 'csv';
    case 'xlsx':
    case 'xls':
      return 'excel';
    case 'pdf':
      return 'pdf';
    default:
      return 'unknown';
  }
}
