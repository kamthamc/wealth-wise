/**
 * Excel Parsing Cloud Function
 * Handles parsing of Excel files (.xlsx, .xls) for transaction and account imports
 * 
 * Note: Requires xlsx library to be installed in Cloud Functions
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import * as logger from 'firebase-functions/logger';

// Request schema
const excelParseRequestSchema = z.object({
  excelBase64: z.string().min(1, 'Excel content cannot be empty'),
  sheetName: z.string().optional(),
  sheetIndex: z.number().int().min(0).optional().default(0),
  skipRows: z.number().int().min(0).max(100).optional().default(0),
});

// Response interface
interface ParsedExcelData {
  headers: string[];
  rows: Record<string, string>[];
  rowCount: number;
  format: 'excel';
  metadata: {
    sheetName: string;
    totalSheets: number;
    availableSheets: string[];
  };
}

/**
 * Parse Excel content (base64 encoded)
 * 
 * NOTE: This is a placeholder implementation that shows the structure.
 * To actually parse Excel files, you need to:
 * 1. Install xlsx library: npm install xlsx @types/node
 * 2. Uncomment the actual parsing code below
 * 3. Handle different Excel formats (.xlsx, .xls, .xlsb)
 */
function parseExcelContent(
  excelBase64: string,
  _sheetName?: string,
  _sheetIndex: number = 0,
  _skipRows: number = 0
): ParsedExcelData {
  try {
    // TODO: Install and use xlsx library for actual parsing
    // When xlsx is installed, uncomment this code:
    /*
    import * as XLSX from 'xlsx';
    
    const buffer = Buffer.from(excelBase64, 'base64');
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const availableSheets = workbook.SheetNames;
    
    // Get the sheet to parse
    const targetSheetName = sheetName || availableSheets[sheetIndex];
    if (!targetSheetName) {
      throw new HttpsError('not-found', 'No sheets found in Excel file');
    }
    
    const worksheet = workbook.Sheets[targetSheetName];
    if (!worksheet) {
      throw new HttpsError('not-found', `Sheet '${targetSheetName}' not found`);
    }
    
    // Convert to array of arrays
    const data: unknown[][] = XLSX.utils.sheet_to_json(worksheet, {
      header: 1,
      defval: '',
      blankrows: false,
    });
    */

    // TEMPORARY: Return error message until xlsx is installed
    throw new HttpsError(
      'unimplemented',
      'Excel parsing is not yet implemented. Please install the xlsx library in Cloud Functions and uncomment the parsing code in excelParser.ts. For now, please export your data as CSV.'
    );

    // Uncomment below when xlsx is installed:
    /*
    if (data.length < 2) {
      throw new HttpsError(
        'invalid-argument',
        'Excel file must have at least a header row and one data row'
      );
    }

    // Skip rows if requested
    const processedData = skipRows > 0 ? data.slice(skipRows) : data;

    // Find header row
    const headerRowIndex = findHeaderRow(processedData);
    const dataWithHeader = processedData.slice(headerRowIndex);

    // Parse headers
    const headers = dataWithHeader[0]?.map((cell) =>
      String(cell || '').trim()
    ) || [];

    if (headers.length === 0) {
      throw new HttpsError('invalid-argument', 'No headers found in Excel file');
    }

    // Parse data rows
    const rows: Record<string, string>[] = [];
    for (let i = 1; i < dataWithHeader.length; i++) {
      const rowData = dataWithHeader[i];
      if (!rowData) continue;

      const row: Record<string, string> = {};
      headers.forEach((header, index) => {
        const cellValue = rowData[index];
        row[header] = cellValue != null ? String(cellValue).trim() : '';
      });

      // Only include rows with at least some data
      if (Object.values(row).some((v) => v !== '')) {
        rows.push(row);
      }
    }

    return {
      headers,
      rows,
      rowCount: rows.length,
      format: 'excel',
      metadata: {
        sheetName: targetSheetName,
        totalSheets: availableSheets.length,
        availableSheets,
      },
    };
    */
  } catch (error) {
    logger.error('Excel parsing failed', error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      'internal',
      `Failed to parse Excel: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Cloud Function to parse Excel files
 * 
 * IMPORTANT: Requires xlsx library installation
 * Run: cd packages/functions && npm install xlsx @types/node
 */
export const parseExcel = onCall<unknown, Promise<ParsedExcelData>>(
  { cors: true },
  async (request) => {
    try {
      // Validate request
      const validatedData = excelParseRequestSchema.parse(request.data);
      const { excelBase64, sheetName, sheetIndex, skipRows } = validatedData;

      logger.info('Parsing Excel file', {
        sheetName,
        sheetIndex,
        skipRows,
        contentLength: excelBase64.length,
      });

      // Check file size (max 10MB base64 encoded)
      if (excelBase64.length > 10 * 1024 * 1024 * 4 / 3) {
        throw new HttpsError(
          'invalid-argument',
          'Excel file is too large. Maximum size is 10MB.'
        );
      }

      // Parse Excel content
      const result = parseExcelContent(
        excelBase64,
        sheetName,
        sheetIndex,
        skipRows
      );

      logger.info('Excel parsed successfully', {
        headers: result.headers.length,
        rows: result.rowCount,
        sheet: result.metadata.sheetName,
      });

      return result;
    } catch (error) {
      logger.error('Excel parsing failed', error);

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
        `Failed to parse Excel: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }
);
