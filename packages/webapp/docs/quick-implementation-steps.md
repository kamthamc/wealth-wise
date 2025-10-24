# Quick Implementation Guide - Enhanced Import/Export

## Step 1: Install Dependencies

```bash
cd /Users/chaitanyakkamatham/Projects/wealth-wise/webapp
npm install xlsx pdfjs-dist jspdf jspdf-autotable
```

## Step 2: Files Already Created ✅

1. ✅ `ColumnMapper.tsx` - Column mapping component
2. ✅ `ColumnMapper.css` - Styling
3. ✅ `fileParser.ts` - Multi-format file parser
4. ✅ `exportUtils.ts` - Excel and PDF export utilities

## Step 3: Update ImportTransactionsModal.tsx

### Add Imports
```typescript
import { detectFileFormat, parseFile, type ParsedData } from '../utils/fileParser';
import { ColumnMapper, type ColumnMapping } from './ColumnMapper';
```

### Add State
```typescript
const [showColumnMapper, setShowColumnMapper] = useState(false);
const [parsedData, setParsedData] = useState<ParsedData | null>(null);
const [columnMappings, setColumnMappings] = useState<ColumnMapping[]>([]);
```

### Update handleFileSelect
```typescript
const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
  const file = event.target.files?.[0];
  if (!file) return;

  const format = detectFileFormat(file);
  if (format === 'unknown') {
    toast.error('Unsupported format', 'Please upload CSV, Excel (.xlsx, .xls), or PDF files');
    return;
  }

  setSelectedFile(file);
  parseFileWithFormat(file);
};
```

### Add parseFileWithFormat
```typescript
const parseFileWithFormat = async (file: File) => {
  setIsProcessing(true);
  try {
    const data = await parseFile(file);
    setParsedData(data);
    setShowColumnMapper(true);
  } catch (error) {
    toast.error('Parse Error', error instanceof Error ? error.message : 'Failed to parse file');
    setSelectedFile(null);
  } finally {
    setIsProcessing(false);
  }
};
```

### Add handleMappingComplete
```typescript
const handleMappingComplete = (mappings: ColumnMapping[]) => {
  setColumnMappings(mappings);
  setShowColumnMapper(false);
  
  if (!parsedData) return;
  
  // Apply mappings to transform data
  const transactions = parsedData.rows.map(row => {
    const txn: any = {};
    
    mappings.forEach(mapping => {
      if (mapping.systemField === 'skip') return;
      
      let value = row[mapping.csvColumn];
      
      // Apply value mappings (e.g., credit -> income)
      if (mapping.valueMapping && value) {
        const lowerValue = value.toLowerCase().trim();
        value = mapping.valueMapping[lowerValue] || value;
      }
      
      txn[mapping.systemField] = value;
    });
    
    return txn as ParsedTransaction;
  });
  
  setPreviewData(transactions.slice(0, 5));
};
```

### Update JSX
Replace the current file upload and preview section with:

```tsx
{/* File format indicator */}
{selectedFile && !showColumnMapper && (
  <div className="file-info">
    <p>File: {selectedFile.name}</p>
    <p>Format: {detectFileFormat(selectedFile).toUpperCase()}</p>
    <p>Size: {(selectedFile.size / 1024).toFixed(2)} KB</p>
  </div>
)}

{/* Column Mapper */}
{showColumnMapper && parsedData && (
  <ColumnMapper
    csvHeaders={parsedData.headers}
    sampleData={parsedData.rows.slice(0, 5)}
    onMappingComplete={handleMappingComplete}
    onCancel={() => {
      setShowColumnMapper(false);
      setSelectedFile(null);
      setParsedData(null);
    }}
  />
)}

{/* Preview (only show after mapping is complete) */}
{!showColumnMapper && previewData.length > 0 && (
  <div className="preview-section">
    {/* Existing preview table code */}
  </div>
)}
```

### Update Import Button Logic
```typescript
const handleImport = async () => {
  if (previewData.length === 0) return;

  setIsProcessing(true);
  let successCount = 0;
  let failCount = 0;

  for (const txn of previewData) {
    try {
      await createTransaction(accountId, {
        date: txn.date,
        description: txn.description,
        amount: txn.amount,
        type: txn.type,
        category: txn.category,
      });
      successCount++;
    } catch (error) {
      console.error('Failed to import transaction:', error);
      failCount++;
    }
  }

  setIsProcessing(false);

  if (successCount > 0) {
    toast.success(
      'Import Complete',
      `${successCount} transactions imported${failCount > 0 ? `, ${failCount} failed` : ''}`
    );
    handleClose();
  } else {
    toast.error('Import Failed', 'No transactions could be imported');
  }
};
```

## Step 4: Update AccountDetails.tsx

### Add Imports
```typescript
import { exportToExcel, exportStatementToPDF } from '../utils/exportUtils';
import { ChevronDown } from 'lucide-react';
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
```

### Replace Export Handler
```typescript
const handleExportTransactions = async (format: 'csv' | 'excel') => {
  if (!account) return;
  
  if (format === 'excel') {
    try {
      await exportToExcel(accountTransactions, account.name);
      toast.success('Export Successful', 'Excel file downloaded');
    } catch (error) {
      toast.error('Export Failed', error instanceof Error ? error.message : 'Unknown error');
    }
  } else {
    // Existing CSV export code
    const csv = generateCSV(accountTransactions);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${account.name}_transactions_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('Export Successful', 'CSV file downloaded');
  }
};
```

### Add PDF Statement Handler
```typescript
const handleDownloadPDFStatement = async () => {
  if (!account) return;
  
  try {
    await exportStatementToPDF(account, accountTransactions);
    toast.success('Statement Generated', 'PDF downloaded successfully');
  } catch (error) {
    toast.error('Generation Failed', error instanceof Error ? error.message : 'Unknown error');
  }
};
```

### Update AccountActions Props
```typescript
<AccountActions
  accountId={accountId}
  isActive={account?.status === 'active'}
  onAddTransaction={handleAddTransaction}
  onTransferMoney={() => console.log('Transfer money')}
  onImportTransactions={handleImportTransactions}
  onExportTransactions={() => {}} // Will be replaced with dropdown
  onDownloadStatement={() => {}} // Will be replaced with dropdown
  onToggleAccountStatus={handleToggleAccountStatus}
/>
```

### Add Export Dropdown Menu (replace single button)
```tsx
{/* Replace Export button in AccountActions with this dropdown */}
<DropdownMenu.Root>
  <DropdownMenu.Trigger className="action-button">
    <Download size={20} />
    <span>Export</span>
    <ChevronDown size={16} />
  </DropdownMenu.Trigger>

  <DropdownMenu.Portal>
    <DropdownMenu.Content className="dropdown-content" align="start">
      <DropdownMenu.Item 
        className="dropdown-item"
        onSelect={() => handleExportTransactions('csv')}
      >
        Export as CSV
      </DropdownMenu.Item>
      <DropdownMenu.Item 
        className="dropdown-item"
        onSelect={() => handleExportTransactions('excel')}
      >
        Export as Excel
      </DropdownMenu.Item>
      <DropdownMenu.Separator className="dropdown-separator" />
      <DropdownMenu.Item 
        className="dropdown-item"
        onSelect={handleDownloadPDFStatement}
      >
        Download PDF Statement
      </DropdownMenu.Item>
    </DropdownMenu.Content>
  </DropdownMenu.Portal>
</DropdownMenu.Root>
```

## Step 5: Update AddAccountModal.tsx (Optional Enhancement)

### Import Icons
```typescript
import {
  Building2, CreditCard, Smartphone, TrendingUp, 
  Wallet, Banknote, PiggyBank, Lock, FileText,
  Landmark, ChevronDown, Check
} from 'lucide-react';
import * as Select from '@radix-ui/react-select';
```

### Define Account Type Categories
```typescript
const ACCOUNT_TYPE_OPTIONS = [
  { value: 'bank', label: 'Bank Account', icon: Building2, category: 'Banking' },
  { value: 'credit_card', label: 'Credit Card', icon: CreditCard, category: 'Banking' },
  { value: 'upi', label: 'UPI Account', icon: Smartphone, category: 'Banking' },
  { value: 'brokerage', label: 'Brokerage Account', icon: TrendingUp, category: 'Investments' },
  { value: 'fixed_deposit', label: 'Fixed Deposit', icon: Lock, category: 'Deposits' },
  { value: 'recurring_deposit', label: 'Recurring Deposit', icon: PiggyBank, category: 'Deposits' },
  { value: 'ppf', label: 'Public Provident Fund (PPF)', icon: Lock, category: 'Deposits' },
  { value: 'nsc', label: 'National Savings Certificate', icon: FileText, category: 'Deposits' },
  { value: 'kvp', label: 'Kisan Vikas Patra', icon: FileText, category: 'Deposits' },
  { value: 'scss', label: 'Senior Citizen Savings', icon: Landmark, category: 'Deposits' },
  { value: 'post_office', label: 'Post Office Savings', icon: Landmark, category: 'Deposits' },
  { value: 'cash', label: 'Cash', icon: Banknote, category: 'Cash' },
  { value: 'wallet', label: 'Digital Wallet', icon: Wallet, category: 'Cash' },
];
```

### Replace Grid with Select
```tsx
<Select.Root value={selectedType} onValueChange={setSelectedType}>
  <Select.Trigger className="account-type-select">
    <Select.Value placeholder="Select account type..." />
    <Select.Icon>
      <ChevronDown size={16} />
    </Select.Icon>
  </Select.Trigger>

  <Select.Portal>
    <Select.Content className="account-type-content">
      <Select.Viewport>
        {/* Group by category */}
        {['Banking', 'Investments', 'Deposits', 'Cash'].map(category => {
          const options = ACCOUNT_TYPE_OPTIONS.filter(opt => opt.category === category);
          return (
            <Select.Group key={category}>
              <Select.Label className="account-type-label">{category}</Select.Label>
              {options.map(option => {
                const Icon = option.icon;
                return (
                  <Select.Item 
                    key={option.value} 
                    value={option.value}
                    className="account-type-item"
                  >
                    <Icon size={16} />
                    <Select.ItemText>{option.label}</Select.ItemText>
                    <Select.ItemIndicator>
                      <Check size={16} />
                    </Select.ItemIndicator>
                  </Select.Item>
                );
              })}
              <Select.Separator className="account-type-separator" />
            </Select.Group>
          );
        })}
      </Select.Viewport>
    </Select.Content>
  </Select.Portal>
</Select.Root>
```

## Step 6: Update Component Exports

### File: `src/features/accounts/components/index.ts`
```typescript
export { ColumnMapper } from './ColumnMapper';
export type { ColumnMapping } from './ColumnMapper';
// ... existing exports
```

## Step 7: Add CSS for New Features

### Add to ImportTransactionsModal.css
```css
.file-info {
  padding: 1rem;
  background: var(--color-background-secondary);
  border: 1px solid var(--color-border);
  border-radius: 0.5rem;
  margin-bottom: 1rem;
}

.file-info p {
  margin: 0.25rem 0;
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.file-info p:first-child {
  font-weight: 600;
  color: var(--color-text);
}
```

### Add Dropdown Styles (if not already present)
```css
.dropdown-content {
  min-width: 200px;
  background: var(--color-background);
  border: 1px solid var(--color-border);
  border-radius: 0.5rem;
  padding: 0.5rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
}

.dropdown-item {
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  color: var(--color-text);
  border-radius: 0.25rem;
  cursor: pointer;
  outline: none;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.dropdown-item:hover {
  background: var(--color-primary-alpha);
  color: var(--color-primary);
}

.dropdown-separator {
  height: 1px;
  background: var(--color-border);
  margin: 0.5rem 0;
}
```

## Step 8: Test Each Feature

### Column Mapping
1. Upload a CSV with different column names
2. Verify auto-detection works
3. Manually remap columns
4. Test credit/debit mapping
5. Verify preview shows correct data

### File Formats
1. Upload standard CSV - should work
2. Upload Excel file (.xlsx) - should parse
3. Upload PDF statement - should extract transactions
4. Upload unsupported file - should show error

### Export
1. Export to CSV - verify format
2. Export to Excel - verify formatting
3. Download PDF statement - verify layout
4. Test with empty transactions
5. Test with large dataset (> 1000 transactions)

### Account Types
1. Open Add Account modal
2. Verify all 13 types visible
3. Check grouping by category
4. Verify icons display correctly
5. Test on mobile/tablet

## Common Issues & Solutions

### Issue: "xlsx is not defined"
**Solution**: Make sure library is installed and imported correctly
```bash
npm install xlsx
```

### Issue: PDF parsing returns no transactions
**Solution**: PDF format may not be supported. Add bank-specific parser or use CSV/Excel

### Issue: Column mapper not showing
**Solution**: Check that `parsedData` state is set correctly after file parse

### Issue: Export buttons not working
**Solution**: Verify dynamic imports are working:
```typescript
const XLSX = await import('xlsx');
```

### Issue: TypeScript errors
**Solution**: Make sure types are imported:
```typescript
import type { ParsedData, ColumnMapping } from './types';
```

## Next Steps

1. ✅ Install dependencies
2. ✅ Verify all files created
3. ⏳ Update ImportTransactionsModal
4. ⏳ Update AccountDetails  
5. ⏳ Update AddAccountModal (optional)
6. ⏳ Test all features
7. ⏳ Update documentation
8. ⏳ Create user guide with screenshots

## Rollback Plan

If issues arise:
1. Keep old CSV import as fallback
2. Add feature flags to enable/disable new features
3. Graceful degradation if libraries not available
4. Clear error messages for unsupported formats
