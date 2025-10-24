# Enhanced Import/Export Implementation Plan

## Overview
This document outlines the implementation of advanced import/export features including:
1. Column mapping for different CSV formats
2. PDF and Excel file import support
3. Enhanced export to Excel and PDF
4. Categorized account type dropdown

## Package Requirements

```json
{
  "xlsx": "^0.18.5",
  "pdfjs-dist": "^4.0.0",
  "jspdf": "^2.5.1",
  "jspdf-autotable": "^3.8.0"
}
```

Install command:
```bash
npm install xlsx pdfjs-dist jspdf jspdf-autotable
```

## Files Created

### 1. ColumnMapper Component
**File**: `src/features/accounts/components/ColumnMapper.tsx`
**Purpose**: Allow users to map CSV columns to system fields
**Features**:
- Auto-detection of common column names
- Credit/Debit to Income/Expense mapping
- Visual mapping interface with dropdowns
- Sample data preview
- Required field validation

### 2. ColumnMapper Styles
**File**: `src/features/accounts/components/ColumnMapper.css`
**Purpose**: Styling for column mapping interface
**Features**:
- Responsive grid layout
- Mobile-friendly design
- Visual indicators for required fields
- Hover states and transitions

### 3. File Parser Utility
**File**: `src/features/accounts/utils/fileParser.ts`
**Purpose**: Parse CSV, Excel, and PDF files
**Features**:
- CSV parsing with proper quote handling
- Excel (.xlsx, .xls) parsing using xlsx library
- PDF text extraction and transaction parsing
- Auto-format detection
- Bank-specific patterns (HDFC, ICICI, etc.)

**Key Functions**:
```typescript
parseCSV(file: File): Promise<ParsedData>
parseExcel(file: File): Promise<ParsedData>
parsePDF(file: File): Promise<ParsedData>
parseFile(file: File): Promise<ParsedData> // Auto-detect format
detectFileFormat(file: File): 'csv' | 'excel' | 'pdf' | 'unknown'
```

### 4. Export Utilities
**File**: `src/features/accounts/utils/exportUtils.ts`
**Purpose**: Export transactions to Excel and PDF
**Features**:
- Excel export with multiple sheets
- PDF statement generation with tables
- Professional formatting
- Support for single account or all accounts

**Key Functions**:
```typescript
exportToExcel(transactions, accountName): Promise<void>
exportStatementToPDF(account, transactions): Promise<void>
exportAllAccountsToExcel(accounts, transactionsByAccount): Promise<void>
```

## Files to Update

### 1. ImportTransactionsModal.tsx
**Current State**: Only supports CSV with fixed format
**Updates Needed**:
1. Add support for multiple file formats (CSV, Excel, PDF)
2. Integrate ColumnMapper component
3. Update file handling to use new parser
4. Add format-specific instructions

**Implementation Steps**:

```typescript
// Add state for column mapping
const [showColumnMapper, setShowColumnMapper] = useState(false);
const [parsedData, setParsedData] = useState<ParsedData | null>(null);
const [columnMappings, setColumnMappings] = useState<ColumnMapping[]>([]);

// Update file validation
const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
  const file = event.target.files?.[0];
  if (!file) return;

  const format = detectFileFormat(file);
  if (format === 'unknown') {
    toast.error('Unsupported format', 'Please upload CSV, Excel, or PDF files');
    return;
  }

  setSelectedFile(file);
  parseFileWithFormat(file, format);
};

// Parse file and show column mapper
const parseFileWithFormat = async (file: File, format: string) => {
  setIsProcessing(true);
  try {
    const data = await parseFile(file);
    setParsedData(data);
    setShowColumnMapper(true); // Show mapper before import
  } catch (error) {
    toast.error('Parse Error', error.message);
  } finally {
    setIsProcessing(false);
  }
};

// Handle mapping complete
const handleMappingComplete = (mappings: ColumnMapping[]) => {
  setColumnMappings(mappings);
  setShowColumnMapper(false);
  applyMappingsAndPreview(parsedData, mappings);
};

// Apply mappings to transform data
const applyMappingsAndPreview = (data: ParsedData, mappings: ColumnMapping[]) => {
  const transactions = data.rows.map(row => {
    const txn: any = {};
    
    mappings.forEach(mapping => {
      if (mapping.systemField === 'skip') return;
      
      let value = row[mapping.csvColumn];
      
      // Apply value mappings (e.g., credit -> income)
      if (mapping.valueMapping && value) {
        value = mapping.valueMapping[value.toLowerCase()] || value;
      }
      
      txn[mapping.systemField] = value;
    });
    
    return txn;
  });
  
  setPreviewData(transactions.slice(0, 5));
};
```

**UI Updates**:
```tsx
{/* Add file format indicator */}
{selectedFile && (
  <div className="file-format-badge">
    Format: {detectFileFormat(selectedFile).toUpperCase()}
  </div>
)}

{/* Show column mapper or preview */}
{showColumnMapper && parsedData && (
  <ColumnMapper
    csvHeaders={parsedData.headers}
    sampleData={parsedData.rows.slice(0, 5)}
    onMappingComplete={handleMappingComplete}
    onCancel={() => {
      setShowColumnMapper(false);
      setSelectedFile(null);
    }}
  />
)}

{!showColumnMapper && previewData.length > 0 && (
  <div className="preview-section">
    {/* Existing preview table */}
  </div>
)}
```

### 2. AccountDetails.tsx
**Current State**: Basic CSV export and text statement
**Updates Needed**:
1. Add Excel export option
2. Add PDF statement generation
3. Add "Export All Accounts" feature

**Implementation**:

```typescript
// Import new utilities
import { exportToExcel, exportStatementToPDF } from '../utils/exportUtils';

// Update export handler
const handleExportTransactions = async (format: 'csv' | 'excel') => {
  if (format === 'excel') {
    try {
      await exportToExcel(accountTransactions, account?.name || 'Account');
      toast.success('Export Successful', 'Excel file downloaded');
    } catch (error) {
      toast.error('Export Failed', error.message);
    }
  } else {
    // Existing CSV export
    const csv = generateCSV(accountTransactions);
    downloadFile(csv, `${account?.name}_transactions.csv`);
  }
};

// Add PDF statement handler
const handleDownloadPDFStatement = async () => {
  if (!account) return;
  
  try {
    await exportStatementToPDF(account, accountTransactions);
    toast.success('Statement Generated', 'PDF downloaded successfully');
  } catch (error) {
    toast.error('Generation Failed', error.message);
  }
};
```

**UI Updates**:
```tsx
{/* Add format selector for export */}
<div className="export-options">
  <button onClick={() => handleExportTransactions('csv')}>
    Export as CSV
  </button>
  <button onClick={() => handleExportTransactions('excel')}>
    Export as Excel
  </button>
  <button onClick={handleDownloadPDFStatement}>
    Download PDF Statement
  </button>
</div>
```

### 3. AddAccountModal.tsx
**Current State**: Grid of account types
**Updates Needed**:
1. Replace grid with categorized dropdown
2. Add icons and separators
3. Group by category (Banking, Investments, Deposits)

**Implementation**:

```typescript
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import {
  Building2, CreditCard, Smartphone, TrendingUp, 
  Wallet, Banknote, PiggyBank, Lock, FileText,
  Landmark
} from 'lucide-react';

const ACCOUNT_TYPE_CATEGORIES = {
  banking: {
    label: 'Banking',
    types: [
      { value: 'bank', label: 'Bank Account', icon: Building2 },
      { value: 'credit_card', label: 'Credit Card', icon: CreditCard },
      { value: 'upi', label: 'UPI Account', icon: Smartphone },
    ],
  },
  investments: {
    label: 'Investments',
    types: [
      { value: 'brokerage', label: 'Brokerage Account', icon: TrendingUp },
    ],
  },
  deposits: {
    label: 'Deposits & Savings',
    types: [
      { value: 'fixed_deposit', label: 'Fixed Deposit', icon: Lock },
      { value: 'recurring_deposit', label: 'Recurring Deposit', icon: PiggyBank },
      { value: 'ppf', label: 'PPF', icon: Lock },
      { value: 'nsc', label: 'NSC', icon: FileText },
      { value: 'kvp', label: 'KVP', icon: FileText },
      { value: 'scss', label: 'SCSS', icon: Landmark },
      { value: 'post_office', label: 'Post Office', icon: Landmark },
    ],
  },
  cash: {
    label: 'Cash & Wallets',
    types: [
      { value: 'cash', label: 'Cash', icon: Banknote },
      { value: 'wallet', label: 'Digital Wallet', icon: Wallet },
    ],
  },
};

// Replace grid with dropdown
<DropdownMenu.Root>
  <DropdownMenu.Trigger className="account-type-trigger">
    {selectedType ? (
      <div className="selected-type">
        <Icon />
        <span>{label}</span>
      </div>
    ) : (
      <span>Select Account Type</span>
    )}
    <ChevronDown />
  </DropdownMenu.Trigger>

  <DropdownMenu.Portal>
    <DropdownMenu.Content className="account-type-menu">
      {Object.entries(ACCOUNT_TYPE_CATEGORIES).map(([key, category]) => (
        <div key={key}>
          <DropdownMenu.Label>{category.label}</DropdownMenu.Label>
          {category.types.map(type => (
            <DropdownMenu.Item
              key={type.value}
              onSelect={() => handleSelectType(type.value)}
            >
              <type.icon size={16} />
              <span>{type.label}</span>
            </DropdownMenu.Item>
          ))}
          <DropdownMenu.Separator />
        </div>
      ))}
    </DropdownMenu.Content>
  </DropdownMenu.Portal>
</DropdownMenu.Root>
```

### 4. Update index.ts exports
**File**: `src/features/accounts/components/index.ts`

```typescript
export { ColumnMapper } from './ColumnMapper';
export { ImportTransactionsModal } from './ImportTransactionsModal';
// ... other exports
```

## Testing Checklist

### Column Mapping
- [ ] Auto-detects common column names (date, description, amount, etc.)
- [ ] Allows manual column mapping
- [ ] Maps credit/debit to income/expense correctly
- [ ] Shows preview of sample data
- [ ] Validates required fields before proceeding
- [ ] Mobile responsive

### File Parsing
- [ ] CSV: Parses standard CSV files
- [ ] CSV: Handles quoted fields with commas
- [ ] CSV: Handles different delimiters
- [ ] Excel: Parses .xlsx files
- [ ] Excel: Parses .xls files (if supported)
- [ ] PDF: Extracts text from bank statements
- [ ] PDF: Parses HDFC format
- [ ] PDF: Parses ICICI format
- [ ] PDF: Falls back gracefully for unsupported formats

### Excel Export
- [ ] Exports single account transactions
- [ ] Formats dates correctly (DD/MM/YYYY)
- [ ] Formats amounts with currency
- [ ] Sets appropriate column widths
- [ ] Includes all transaction data
- [ ] Exports all accounts to multiple sheets
- [ ] Includes summary sheet

### PDF Generation
- [ ] Creates formatted statement
- [ ] Includes account details
- [ ] Shows transaction table
- [ ] Handles long descriptions
- [ ] Adds page numbers
- [ ] Professional styling
- [ ] Downloads with correct filename

### Account Type Dropdown
- [ ] Shows all account types
- [ ] Groups by category
- [ ] Shows icons for each type
- [ ] Has visual separators
- [ ] Allows search/filter (future)
- [ ] Mobile friendly

## Sample Bank Statement Patterns

### HDFC Bank
```
Date        Narration                       Chq./Ref.No.    Value Dt    Withdrawal Amt.    Deposit Amt.    Closing Balance
02/10/25    FD THROUGH MOBILE-503012250...  MB02133655...   02/10/25    7,850,000.00                      64,170.76
02/10/25    UPI-CRED                        000056411578... 02/10/25    2,981.93                          61,188.83
```

### ICICI Bank
```
S No.  Value Date  Transaction Date  Cheque Number  Transaction Remarks                               Withdrawal Amount  Deposit Amount  Balance (INR)
1      22/09/2025  22/09/2025        -              WMS/MF/H-HNNIRG-M02337361/002509220                100                0               275296.5
2      22/09/2025  22/09/2025        -              EBA/EQ Trade 22SEP/202509220                       54.8               0               275241.7
```

### Patterns to Support
1. Different date formats (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
2. Amount formats with commas (1,23,456.78)
3. Separate withdrawal/deposit columns
4. Single amount column with +/- signs
5. Credit/Debit indicators
6. Transaction descriptions with special characters

## Error Handling

### File Upload
- Invalid file type
- File too large (> 10MB)
- Empty file
- Corrupted file

### Parsing
- Invalid CSV format
- Missing required columns
- Invalid date formats
- Invalid amount formats
- PDF text extraction failure

### Mapping
- Required fields not mapped
- Duplicate column mappings
- Invalid type mappings

### Export
- No transactions to export
- Library not available
- File write failure
- Permission denied

## Performance Considerations

1. **Large Files**: 
   - Parse in chunks for files > 1MB
   - Show progress indicator
   - Limit preview to first 100 rows

2. **PDF Processing**:
   - Process pages in background
   - Cache extracted text
   - Timeout for large PDFs (> 50 pages)

3. **Excel Generation**:
   - Stream writing for large datasets
   - Limit formatting for > 10,000 rows
   - Compress workbook

4. **Memory Management**:
   - Release file blobs after processing
   - Clear preview data when not needed
   - Dispose PDF.js worker

## Future Enhancements

1. **Bank-Specific Parsers**:
   - Template system for different banks
   - User-contributed templates
   - ML-based format detection

2. **Advanced Mapping**:
   - Save mapping templates
   - Auto-apply saved mappings
   - Smart category detection
   - Duplicate transaction detection

3. **Bulk Operations**:
   - Import multiple files at once
   - Batch export with date ranges
   - Scheduled exports
   - Email delivery

4. **Integration**:
   - Direct bank API integration
   - Automated statement fetching
   - Real-time sync
   - Cloud backup

## Documentation Updates Needed

1. Add screenshots of new features
2. Update user guide with column mapping instructions
3. Create video tutorials
4. Document supported bank formats
5. Add troubleshooting guide
6. Update API documentation

## Migration Notes

### Breaking Changes
None - all features are additive

### Backward Compatibility
- Existing CSV imports still work
- Old export format maintained as default
- No database schema changes

### Upgrade Path
1. Install new dependencies
2. Add new files
3. Update existing components
4. Test all features
5. Update documentation
6. Deploy

## Estimated Implementation Time

- Column Mapper: ✅ Complete
- File Parser: ✅ Complete  
- Export Utilities: ✅ Complete
- ImportTransactionsModal Updates: 4-6 hours
- AccountDetails Updates: 2-3 hours
- AddAccountModal Updates: 2-3 hours
- Testing: 4-6 hours
- Documentation: 2-3 hours

**Total: 14-21 hours**

## Priority Order

1. **High Priority** (Must Have):
   - Column mapping for CSV
   - Excel import
   - Excel export
   - Basic PDF parsing

2. **Medium Priority** (Should Have):
   - PDF statement generation
   - Categorized account dropdown
   - Export all accounts
   - Enhanced error handling

3. **Low Priority** (Nice to Have):
   - Bank-specific parsers
   - Advanced PDF features
   - Saved mapping templates
   - Performance optimizations
