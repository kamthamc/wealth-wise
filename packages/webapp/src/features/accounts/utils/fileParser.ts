/**
 * Multi-format file parser for importing transactions
 * Supports: CSV, Excel (.xlsx, .xls), PDF (bank statements)
 */

export interface ParsedTransaction {
  date: string;
  description: string;
  amount: number;
  type: 'income' | 'expense' | 'transfer';
  category?: string;
}

export interface ParsedData {
  headers: string[];
  rows: Record<string, string>[];
  format: 'csv' | 'excel' | 'pdf';
}

/**
 * Parse CSV file
 */
export async function parseCSV(file: File): Promise<ParsedData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      try {
        const text = e.target?.result as string;
        const allLines = text.split(/\r?\n/).filter((line) => line.trim());

        if (allLines.length < 2) {
          reject(
            new Error(
              'CSV file must have at least a header row and one data row'
            )
          );
          return;
        }

        // Find the header row (may not be the first line if there's summary info)
        let headerIndex = 0;
        // Including HDFC-specific terms: "Narration", "Chq./Ref.No.", "Value Dt", "Withdrawal Amt.", "Deposit Amt."
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
          'chq',
          'ref.no',
          'ref no',
          'withdrawal amt',
          'deposit amt',
          'closing balance',
        ];

        for (let i = 0; i < Math.min(allLines.length, 10); i++) {
          const line = allLines[i];
          if (!line) continue;

          const lowerLine = line.toLowerCase();
          const matchCount = headerKeywords.filter((keyword) =>
            lowerLine.includes(keyword)
          ).length;

          // If line contains at least 2 header keywords, it's likely the header
          if (matchCount >= 2) {
            headerIndex = i;
            break;
          }
        }

        const lines = allLines.slice(headerIndex);

        // Parse headers
        const headers = parseCSVLine(lines[0]!);

        // Parse data rows
        const rows = lines.slice(1).map((line) => {
          const values = parseCSVLine(line);
          const row: Record<string, string> = {};
          headers.forEach((header, index) => {
            row[header] = values[index] || '';
          });
          return row;
        });

        resolve({
          headers,
          rows,
          format: 'csv',
        });
      } catch (error) {
        reject(error);
      }
    };

    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsText(file);
  });
}

/**
 * Parse a single CSV line handling quotes and commas
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
 * Find the row index where the transaction table starts
 * Bank statements often have summary info at the top before the actual data table
 */
function findTableStartRow(data: string[][]): number {
  // Look for common transaction table headers
  // Including bank-specific terms (HDFC: "Narration", "Chq./Ref.No.", "Value Dt", "Withdrawal Amt.", "Deposit Amt.")
  const headerKeywords = [
    'date',
    'txn',
    'transaction',
    'posting',
    'value date',
    'value dt',
    'description',
    'narration',
    'particulars',
    'details',
    'amount',
    'debit',
    'credit',
    'withdrawal',
    'deposit',
    'withdrawal amt',
    'deposit amt',
    'closing balance',
    'balance',
    'type',
    'category',
    'chq',
    'ref.no',
    'ref no',
  ];

  for (let i = 0; i < Math.min(data.length, 30); i++) {
    const row = data[i];
    if (!row) continue;

    // Check if this row looks like a header row
    const rowText = row
      .map((cell) =>
        String(cell || '')
          .toLowerCase()
          .trim()
      )
      .join(' ');

    // Count how many header keywords are present
    const matchCount = headerKeywords.filter((keyword) =>
      rowText.includes(keyword)
    ).length;

    // If at least 3 header keywords found, this is likely the header row
    if (matchCount >= 3) {
      return i;
    }

    // Also check if row has multiple non-empty cells that look like headers
    const nonEmptyCells = row.filter(
      (cell) => cell != null && String(cell).trim() !== ''
    );
    if (nonEmptyCells.length >= 3) {
      const hasDateColumn = nonEmptyCells.some((cell) =>
        /date|dt|txn/i.test(String(cell))
      );
      const hasAmountColumn = nonEmptyCells.some((cell) =>
        /amount|debit|credit|withdrawal|deposit|balance/i.test(String(cell))
      );
      const hasDescColumn = nonEmptyCells.some((cell) =>
        /description|narration|particulars|details|remark/i.test(String(cell))
      );

      if (hasDateColumn && hasAmountColumn && hasDescColumn) {
        return i;
      }
    }
  }

  // If no clear header found, assume first row with enough data
  for (let i = 0; i < Math.min(data.length, 10); i++) {
    const row = data[i];
    if (!row) continue;

    const nonEmptyCells = row.filter(
      (cell) => cell != null && String(cell).trim() !== ''
    );
    if (nonEmptyCells.length >= 3) {
      return i;
    }
  }

  return -1;
}

/**
 * Find the row index where the transaction table starts in PDF text
 * Bank statements often have account summary, terms, etc. before transactions
 */
function findPDFTableStart(lines: string[]): number {
  // Including HDFC-specific terms
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
    'withdrawal amt',
    'deposit amt',
    'closing balance',
    'chq',
    'ref no',
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
 * Check if a line is likely a header, footer, or non-transaction line
 */
function isHeaderOrFooterLine(line: string): boolean {
  const lower = line.toLowerCase();

  // Common header/footer patterns to skip
  const skipPatterns = [
    /^page \d+/i,
    /statement period/i,
    /account number/i,
    /customer id/i,
    /opening balance/i,
    /closing balance/i,
    /total credits/i,
    /total debits/i,
    /continued on next page/i,
    /terms and conditions/i,
    /^date.*description.*amount$/i, // Header row itself
    /^s\.?\s*no\.?/i, // Serial number headers
    /^\d+\s+of\s+\d+$/i, // Page numbers
  ];

  return skipPatterns.some((pattern) => pattern.test(lower));
}

/**
 * Parse Excel file (.xlsx, .xls)
 * Note: Requires xlsx library to be installed
 */
export async function parseExcel(file: File): Promise<ParsedData> {
  try {
    // Dynamic import to avoid bundling if not used
    const XLSX = await import('xlsx');

    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = (e) => {
        try {
          const data = e.target?.result;
          const workbook = XLSX.read(data, { type: 'binary' });

          // Get first sheet
          const sheetName = workbook.SheetNames[0];
          if (!sheetName) {
            reject(new Error('Excel file has no sheets'));
            return;
          }
          const worksheet = workbook.Sheets[sheetName];
          if (!worksheet) {
            reject(new Error('Failed to read worksheet'));
            return;
          }

          // Convert to JSON
          const jsonData = XLSX.utils.sheet_to_json(worksheet, {
            header: 1,
          }) as string[][];

          if (jsonData.length < 2) {
            reject(
              new Error(
                'Excel file must have at least a header row and one data row'
              )
            );
            return;
          }

          // Find the row where data table starts (skip summary/header rows)
          const tableStartIndex = findTableStartRow(jsonData);

          if (
            tableStartIndex === -1 ||
            tableStartIndex >= jsonData.length - 1
          ) {
            reject(new Error('Could not find transaction table in Excel file'));
            return;
          }

          const headers =
            jsonData[tableStartIndex]
              ?.map((h) => String(h || '').trim())
              .filter((h) => h) || [];

          if (headers.length === 0) {
            reject(new Error('No valid headers found in Excel file'));
            return;
          }

          const rows = jsonData
            .slice(tableStartIndex + 1)
            .filter(
              (row) =>
                row &&
                row.some((cell) => cell != null && String(cell).trim() !== '')
            )
            .map((row) => {
              const rowData: Record<string, string> = {};
              headers.forEach((header, index) => {
                rowData[header] = String(row[index] || '').trim();
              });
              return rowData;
            });

          resolve({
            headers,
            rows,
            format: 'excel',
          });
        } catch (error) {
          reject(error);
        }
      };

      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsBinaryString(file);
    });
  } catch (error) {
    throw new Error(
      'Excel parsing library not available. Please install xlsx package.'
    );
  }
}

/**
 * Parse PDF bank statement
 * Note: This is a basic implementation. Real-world bank PDFs vary significantly.
 * Consider using bank-specific parsers or OCR services for production.
 */
export async function parsePDF(file: File): Promise<ParsedData> {
  try {
    // Dynamic import to avoid bundling if not used
    const pdfjsLib = await import('pdfjs-dist');

    // Set worker path
    pdfjsLib.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.js`;

    const arrayBuffer = await file.arrayBuffer();
    const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;

    let fullText = '';

    // Extract text from all pages
    for (let i = 1; i <= pdf.numPages; i++) {
      const page = await pdf.getPage(i);
      const textContent = await page.getTextContent();
      const pageText = textContent.items.map((item: any) => item.str).join(' ');
      fullText += pageText + '\n';
    }

    // Parse transactions from text
    const transactions = parseTransactionsFromText(fullText);

    if (transactions.length === 0) {
      throw new Error(
        'No transactions found in PDF. This format may not be supported.'
      );
    }

    // Convert to standard format
    const headers = ['Date', 'Description', 'Amount', 'Type'];
    const rows = transactions.map((txn) => ({
      Date: txn.date,
      Description: txn.description,
      Amount: String(txn.amount),
      Type: txn.type,
    }));

    return {
      headers,
      rows,
      format: 'pdf',
    };
  } catch (error) {
    throw new Error(
      `Failed to parse PDF: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Extract transactions from PDF text
 * This is a simplified parser. Real implementation should handle:
 * - Different bank formats (HDFC, ICICI, SBI, etc.)
 * - Multiple table formats
 * - OCR errors
 * - Regional date formats
 */
function parseTransactionsFromText(text: string): ParsedTransaction[] {
  const transactions: ParsedTransaction[] = [];
  const lines = text.split('\n');

  // Find where the transaction table starts (skip summary/header sections)
  const tableStartIndex = findPDFTableStart(lines);

  // Common patterns for Indian bank statements
  const datePattern = /(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})/;
  const amountPattern = /(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)/;

  // Start parsing from where the table begins
  for (let i = tableStartIndex; i < lines.length; i++) {
    const line = lines[i]?.trim();
    if (!line) continue;

    // Skip empty lines and very short lines (likely not transactions)
    if (line.length < 10) continue;

    // Skip lines that look like headers or footers
    if (isHeaderOrFooterLine(line)) continue;

    // Try to extract date
    const dateMatch = line.match(datePattern);
    if (!dateMatch || !dateMatch[1]) continue;

    const date = normalizeDateFormat(dateMatch[1]);

    // Extract description (text between date and amount)
    const afterDate = line.substring(
      line.indexOf(dateMatch[1]) + dateMatch[1].length
    );
    const amountMatch = afterDate.match(amountPattern);

    if (!amountMatch || !amountMatch[1]) continue;

    const description = afterDate
      .substring(0, afterDate.indexOf(amountMatch[1]))
      .trim();
    const amount = parseFloat(amountMatch[1].replace(/,/g, ''));

    // Determine type based on keywords
    const lowerDesc = description.toLowerCase();
    const type = determineTransactionType(lowerDesc, line);

    if (description && amount > 0) {
      transactions.push({
        date,
        description,
        amount,
        type,
      });
    }
  }

  return transactions;
}

/**
 * Normalize date format to YYYY-MM-DD
 */
function normalizeDateFormat(dateStr: string): string {
  // Handle DD/MM/YYYY, DD-MM-YYYY, DD/MM/YY
  const parts = dateStr.split(/[/-]/);

  if (parts.length === 3) {
    const day = parts[0];
    const month = parts[1];
    let year = parts[2];

    if (!day || !month || !year) return dateStr;

    // Handle 2-digit year
    if (year.length === 2) {
      year = (parseInt(year) > 50 ? '19' : '20') + year;
    }

    return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
  }

  return dateStr;
}

/**
 * Determine transaction type from description and context
 */
function determineTransactionType(
  description: string,
  fullLine: string
): 'income' | 'expense' | 'transfer' {
  const incomeKeywords = [
    'credit',
    'salary',
    'deposit',
    'interest',
    'refund',
    'cr',
    'payment received',
  ];
  const expenseKeywords = [
    'debit',
    'withdrawal',
    'payment',
    'purchase',
    'dr',
    'charge',
    'fee',
  ];
  const transferKeywords = ['transfer', 'neft', 'imps', 'rtgs', 'upi'];

  // Check for transfer keywords first
  if (transferKeywords.some((keyword) => description.includes(keyword))) {
    return 'transfer';
  }

  // Check for income keywords
  if (incomeKeywords.some((keyword) => description.includes(keyword))) {
    return 'income';
  }

  // Check for expense keywords
  if (expenseKeywords.some((keyword) => description.includes(keyword))) {
    return 'expense';
  }

  // Check in full line for column headers like "Withdrawal" or "Deposit"
  const lowerLine = fullLine.toLowerCase();
  if (lowerLine.includes('withdrawal') || lowerLine.includes('debit amt')) {
    return 'expense';
  }
  if (lowerLine.includes('deposit') || lowerLine.includes('credit amt')) {
    return 'income';
  }

  // Default to expense
  return 'expense';
}

/**
 * Detect file format from extension and MIME type
 */
export function detectFileFormat(
  file: File
): 'csv' | 'excel' | 'pdf' | 'unknown' {
  const extension = file.name.toLowerCase().split('.').pop();
  const mimeType = file.type.toLowerCase();

  if (extension === 'csv' || mimeType.includes('csv')) {
    return 'csv';
  }

  if (
    extension === 'xlsx' ||
    extension === 'xls' ||
    mimeType.includes('spreadsheet') ||
    mimeType.includes('excel')
  ) {
    return 'excel';
  }

  if (extension === 'pdf' || mimeType === 'application/pdf') {
    return 'pdf';
  }

  return 'unknown';
}

/**
 * Parse any supported file format
 */
export async function parseFile(file: File): Promise<ParsedData> {
  const format = detectFileFormat(file);

  switch (format) {
    case 'csv':
      return parseCSV(file);
    case 'excel':
      return parseExcel(file);
    case 'pdf':
      return parsePDF(file);
    default:
      throw new Error(`Unsupported file format: ${file.name}`);
  }
}
