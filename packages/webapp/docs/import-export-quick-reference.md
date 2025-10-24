# Import/Export Quick Reference

## Quick Access

### Creating Deposit Accounts
```
Accounts Page → Add Account → Select deposit type (FD, RD, PPF, etc.) → Fill details
```

### Importing Transactions
```
Account Details → Import Transactions → Upload CSV → Preview → Import
```

### Exporting Transactions
```
Account Details → Export Transactions → CSV downloads automatically
```

### Downloading Statement
```
Account Details → Download Statement → Text file downloads
```

## CSV Format Template

```csv
date,description,amount,type,category
2025-01-15,Salary,50000,income,
2025-01-16,Grocery,2500,expense,food
2025-01-17,Electric Bill,1200,expense,utilities
```

## Files Overview

| File | Purpose | Lines | Status |
|------|---------|-------|--------|
| `ImportTransactionsModal.tsx` | CSV upload and import | 269 | ✅ Complete |
| `ImportTransactionsModal.css` | Modal styling | 238 | ✅ Complete |
| `AddAccountModal.tsx` | Account creation (updated) | - | ✅ Modified |
| `AccountActions.tsx` | Action buttons (updated) | - | ✅ Modified |
| `AccountDetails.tsx` | Main integration (updated) | - | ✅ Modified |

## Component Props

### ImportTransactionsModal
```tsx
<ImportTransactionsModal
  isOpen={boolean}
  onClose={() => void}
  accountId={string}
  accountName={string}
/>
```

### AccountActions (New Props)
```tsx
<AccountActions
  onImportTransactions={() => void}
  onExportTransactions={() => void}
  // ... other props
/>
```

## Features at a Glance

### ✅ Fixed Deposit Accounts
- Fixed Deposit (FD)
- Recurring Deposit (RD)
- Public Provident Fund (PPF)
- National Savings Certificate (NSC)
- Kisan Vikas Patra (KVP)
- Senior Citizen Savings Scheme (SCSS)
- Post Office Savings

### ✅ Import Transactions
- Drag-and-drop CSV upload
- File browser upload
- Real-time preview (first 5)
- Batch import
- Error tracking
- Sample format guide

### ✅ Export Transactions
- One-click CSV export
- All transactions included
- Proper escaping
- Smart filename
- Toast notification

### ✅ Download Statement
- Text-based format
- Account summary
- Transaction table
- Date stamped
- Currency formatted

## Button States

| Button | When Active |
|--------|-------------|
| Add Transaction | Account is active |
| Transfer Money | Account is active |
| Import Transactions | Account is active |
| Export Transactions | Always |
| Download Statement | Always |
| Close/Reopen Account | Always |

## Error Handling

### Import Errors
- **Invalid date** → Row skipped
- **Missing description** → Row skipped
- **Invalid amount** → Row skipped
- **Invalid type** → Defaults to 'expense'
- **Empty file** → Error message shown

### Export Errors
- **No transactions** → Empty CSV with headers
- **Special characters** → Properly escaped
- **Long descriptions** → Quoted in CSV

## Testing Commands

### Build
```bash
npm run build
```

### Dev Server
```bash
npm run dev
```

### Type Check
```bash
npm run type-check
```

### Format
```bash
npm run format
```

## Sample CSV Files

### Income & Expenses
```csv
date,description,amount,type,category
2025-01-15,Monthly Salary,75000,income,salary
2025-01-16,Grocery Shopping,3500,expense,food
2025-01-17,Restaurant Dinner,2500,expense,dining
2025-01-18,Electric Bill,1200,expense,utilities
2025-01-19,Freelance Work,15000,income,freelance
```

### With Special Characters
```csv
date,description,amount,type,category
2025-01-15,"Dinner at ""The Grand""",2500,expense,dining
2025-01-16,"Shopping: Clothes, Shoes",5000,expense,shopping
2025-01-17,Salary (with bonus),80000,income,salary
```

### Mixed Categories
```csv
date,description,amount,type,category
2025-01-15,Salary,50000,income,
2025-01-16,Grocery,2500,expense,food
2025-01-17,Investment Interest,1500,income,investment
2025-01-18,Rent Payment,15000,expense,housing
2025-01-19,Medical Bills,3000,expense,healthcare
```

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Upload File | Click or Drag & Drop |
| Close Modal | ESC key |
| Submit Import | Enter (when focused) |

## Common Issues & Solutions

### Import Not Working
1. Check CSV format matches template
2. Ensure dates are YYYY-MM-DD format
3. Verify amounts are positive numbers
4. Check file size isn't too large
5. Try closing and reopening modal

### Export Not Downloading
1. Check browser download settings
2. Ensure pop-ups aren't blocked
3. Verify account has transactions
4. Try different browser

### Statement Missing Data
1. Verify transactions exist
2. Check date range includes transactions
3. Refresh page and try again
4. Check console for errors

## API Integration Points

### Import Flow
```typescript
// Parse CSV → Validate → createTransaction() for each
transactions.forEach(async (txn) => {
  await createTransaction(accountId, txn);
});
```

### Export Flow
```typescript
// Fetch transactions → Generate CSV → Download
const transactions = await getTransactionsByAccount(accountId);
const csv = generateCSV(transactions);
downloadFile(csv, filename);
```

## Type Definitions

```typescript
interface ParsedTransaction {
  date: string;           // YYYY-MM-DD
  description: string;    // Any text
  amount: number;         // Positive number
  type: 'income' | 'expense' | 'transfer';
  category?: string;      // Optional
}

interface ExportTransaction {
  date: string;
  description: string;
  amount: number;
  type: string;
  category: string;
}
```

## Browser Dev Tools Tips

### Check CSV Parsing
```javascript
// In console after upload
console.log(parseCSV(file));
```

### Test Export
```javascript
// In console
handleExportTransactions();
```

### Debug Import Errors
```javascript
// Check failed transactions
console.log(failedCount, successCount);
```

## Next Steps

1. **Test Features:** Try creating a Fixed Deposit account and importing transactions
2. **Validate CSV:** Ensure your existing transaction data matches the format
3. **Export Test:** Export transactions and verify the CSV can be re-imported
4. **Statement Review:** Download a statement and check formatting
5. **Edge Cases:** Test with special characters, large files, empty accounts

## Support

For issues or questions:
1. Check the main documentation: `import-export-deposit-accounts-feature.md`
2. Review CSV format examples above
3. Check browser console for errors
4. Verify file permissions for downloads

## Version Info

- **Feature Version:** 1.0.0
- **Date Added:** January 2025
- **Status:** Production Ready ✅
- **Breaking Changes:** None
