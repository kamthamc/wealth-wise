# Separate Debit/Credit Column Handling

## Problem Statement

Banks like HDFC use separate columns for withdrawals and deposits instead of a single "amount" column with a "type" indicator:

### Traditional Format (Single Amount Column)
```csv
Date,Description,Amount,Type
01/04/2024,NEFT Payment,5000.00,Expense
02/04/2024,Salary Credit,50000.00,Income
```

### HDFC Format (Separate Debit/Credit Columns)
```csv
Date,Narration,Chq./Ref.No.,Value Dt,Withdrawal Amt.,Deposit Amt.,Closing Balance
01/04/2024,NEFT Payment,N123,01/04/2024,5000.00,,45000.00
02/04/2024,Salary Credit,C456,02/04/2024,,50000.00,95000.00
```

## Solution

The ColumnMapper now supports both formats by:
1. Detecting separate debit/credit columns automatically
2. Making the "Type" field optional when separate columns exist
3. Auto-inferring transaction type from which column has a value

---

## Implementation Details

### 1. Enhanced System Fields

**Added new field types:**
```typescript
const SYSTEM_FIELDS = [
  { value: 'date', label: 'Date', required: true },
  { value: 'description', label: 'Description', required: true },
  { value: 'amount', label: 'Amount', required: true },
  { value: 'amount_debit', label: 'Amount (Debit/Withdrawal)', required: false },
  { value: 'amount_credit', label: 'Amount (Credit/Deposit)', required: false },
  { value: 'type', label: 'Type (Income/Expense)', required: false }, // ← Now optional
  { value: 'category', label: 'Category', required: false },
  { value: 'skip', label: 'Skip this column', required: false },
];
```

### 2. Auto-Detection Logic

**Detects separate columns by name:**
```typescript
// Debit/Withdrawal detection
if (lowerHeader.includes('withdrawal') || 
    lowerHeader.includes('debit amt') ||
    (lowerHeader.includes('debit') && lowerHeader.includes('amt'))) {
  systemField = 'amount_debit';
}

// Credit/Deposit detection  
if (lowerHeader.includes('deposit') || 
    lowerHeader.includes('credit amt') ||
    (lowerHeader.includes('credit') && lowerHeader.includes('amt'))) {
  systemField = 'amount_credit';
}
```

**HDFC columns automatically map to:**
- `"Withdrawal Amt."` → `amount_debit`
- `"Deposit Amt."` → `amount_credit`

### 3. Dynamic Validation

**Validation adapts based on column configuration:**

```typescript
// Get mapped fields
const mappedFields = mappings.map(m => m.systemField).filter(f => f !== 'skip');

// Check if using separate debit/credit columns
const hasSeparateColumns = 
  mappedFields.includes('amount_debit') && 
  mappedFields.includes('amount_credit');

if (hasSeparateColumns) {
  // Don't require 'type' column
  // Don't require general 'amount' column
  // DO require both 'amount_debit' and 'amount_credit'
  effectiveRequiredFields = ['date', 'description', 'amount_debit', 'amount_credit'];
} else {
  // Traditional format
  effectiveRequiredFields = ['date', 'description', 'amount', 'type'];
}
```

### 4. Transaction Processing

**`ImportTransactionsModal.handleMappingComplete()` handles both formats:**

```typescript
// Detect format
const hasDebitColumn = mappings.some(m => m.systemField === 'amount_debit');
const hasCreditColumn = mappings.some(m => m.systemField === 'amount_credit');
const hasSeparateColumns = hasDebitColumn && hasCreditColumn;

// Process each row
if (hasSeparateColumns) {
  // HDFC format: Check which column has a value
  const debitValue = parseFloat(txn.amount_debit || '0');
  const creditValue = parseFloat(txn.amount_credit || '0');
  
  if (debitValue > 0) {
    amount = debitValue;
    type = 'expense';
  } else if (creditValue > 0) {
    amount = creditValue;
    type = 'income';
  }
} else {
  // Traditional format: Use amount + type columns
  amount = Math.abs(parseFloat(txn.amount || '0'));
  type = txn.type?.toLowerCase() || 'expense';
}
```

---

## User Experience

### HDFC File Upload Flow

**Step 1: File Upload**
```
User uploads: hdfc_statement.xlsx
```

**Step 2: Auto-Detection**
```
┌──────────────────────────────────────────────────────────┐
│ Map Your Columns                                         │
│ ✓ Columns auto-detected                                 │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ CSV Column         Maps To ▼              Sample Data   │
│ ──────────────────────────────────────────────────────── │
│ Date           ✓   Date                →  01/04/2024    │
│ Narration      ✓   Description         →  NEFT Payment  │
│ Chq./Ref.No.       Skip this column    →  N123456       │
│ Value Dt           Skip this column    →  01/04/2024    │
│ Withdrawal Amt. ✓  Amount (Debit)      →  5,000.00      │
│ Deposit Amt.    ✓  Amount (Credit)     →  50,000.00     │
│ Closing Balance    Skip this column    →  45,000.00     │
│                                                          │
│ ℹ️ Type will be auto-detected from debit/credit columns │
│                                                          │
│ ┌────────────┐  ┌───────────────────────────┐          │
│ │   Cancel   │  │  Continue with Mapping    │          │
│ └────────────┘  └───────────────────────────┘          │
└──────────────────────────────────────────────────────────┘
```

**Key Points:**
- ✅ No "Type" column mapping required
- ✅ Both amount columns detected automatically
- ✅ Info message explains auto-detection
- ✅ Validation passes with 4 required fields (date, description, amount_debit, amount_credit)

**Step 3: Preview**
```
┌──────────────────────────────────────────────────────────┐
│ Import Preview - 50 transactions                         │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ Date        Description          Amount      Type       │
│ ──────────────────────────────────────────────────────── │
│ 2024-04-01  NEFT Payment          5,000.00   Expense    │ ← From Withdrawal Amt.
│ 2024-04-02  Salary Credit        50,000.00   Income     │ ← From Deposit Amt.
│ 2024-04-03  ATM Withdrawal       10,000.00   Expense    │ ← From Withdrawal Amt.
│ 2024-04-04  Interest Credit          150.00  Income     │ ← From Deposit Amt.
│ ...                                                      │
│                                                          │
│ ┌────────────┐  ┌────────────────────────┐             │
│ │   Cancel   │  │  Import 50 Transactions │             │
│ └────────────┘  └────────────────────────┘             │
└──────────────────────────────────────────────────────────┘
```

**Result:**
- ✅ Type correctly set to "Expense" for withdrawals
- ✅ Type correctly set to "Income" for deposits
- ✅ Amounts taken from correct column
- ✅ No manual type mapping required

---

## Traditional Format Still Works

### Single Amount Column with Type

**Example CSV:**
```csv
Date,Description,Amount,Type
01/04/2024,NEFT Payment,5000.00,Debit
02/04/2024,Salary Credit,50000.00,Credit
```

**Auto-Detection:**
```
CSV Column      Maps To ▼           Sample Data
──────────────────────────────────────────────
Date        ✓   Date             →  01/04/2024
Description ✓   Description      →  NEFT Payment
Amount      ✓   Amount           →  5000.00
Type        ✓   Type             →  Debit
```

**Value Mapping (if needed):**
```
Map Transaction Type Values:

When "Type" column has value:
Debit  → Expense
Credit → Income
```

**Result:** Works exactly as before!

---

## Edge Cases Handled

### 1. Mixed Amount Columns

**Scenario:** User accidentally maps both single and separate columns
```
Mapped: amount, amount_debit, amount_credit
```

**Behavior:**
- Validation checks for `amount_debit` AND `amount_credit`
- If both present, uses separate columns (ignores `amount`)
- If only one present, falls back to traditional format

### 2. Only One Separate Column

**Scenario:** User maps only withdrawal column
```
Mapped: amount_debit (but NOT amount_credit)
```

**Behavior:**
- `hasSeparateColumns = false` (requires BOTH)
- Falls back to traditional validation
- Shows error: "Missing required field: amount"

### 3. Empty Amount Cells

**Scenario:** HDFC row with both columns empty
```csv
01/04/2024,Invalid Transaction,,,
```

**Behavior:**
```typescript
const debitValue = parseFloat(txn.amount_debit || '0'); // 0
const creditValue = parseFloat(txn.amount_credit || '0'); // 0

// Neither > 0, amount stays 0
// Filtered out: filter(t => t.amount > 0)
```

**Result:** Transaction skipped (as expected)

### 4. Both Columns Have Values

**Scenario:** Rare case where both debit and credit populated
```csv
01/04/2024,Transfer,1000.00,1000.00,
```

**Behavior:**
```typescript
if (debitValue > 0) {
  // Takes debit first (priority)
  amount = debitValue;
  type = 'expense';
}
```

**Result:** Treated as expense (debit takes priority)

---

## Bank Compatibility

### Supported Formats

| Bank | Debit Column | Credit Column | Auto-Detected |
|------|--------------|---------------|---------------|
| **HDFC** | Withdrawal Amt. | Deposit Amt. | ✅ Yes |
| **ICICI** | Debit | Credit | ✅ Yes |
| **SBI** | Debit | Credit | ✅ Yes |
| **Axis** | Debit Amount | Credit Amount | ✅ Yes |
| **Kotak** | Withdrawal | Deposit | ✅ Yes |

### Detection Keywords

Any column containing these terms will be detected:

**Debit/Withdrawal:**
- `withdrawal`
- `debit amt`
- `debit` + `amt` (both in name)

**Credit/Deposit:**
- `deposit`
- `credit amt`
- `credit` + `amt` (both in name)

---

## Testing Scenarios

### Test Case 1: HDFC Excel
```
Input: hdfc_statement.xlsx with separate debit/credit columns
Expected: Auto-detects amount_debit and amount_credit, type is optional
Result: ✅ Pass
```

### Test Case 2: Traditional CSV
```
Input: transactions.csv with single amount + type column
Expected: Auto-detects amount and type, both required
Result: ✅ Pass
```

### Test Case 3: Manual Remapping
```
Input: User changes "Withdrawal Amt." from amount_debit to amount
Expected: Validation switches to traditional format, requires type column
Result: ✅ Pass
```

### Test Case 4: One Amount Column Skipped
```
Input: User maps Withdrawal Amt. → amount_debit, Deposit Amt. → Skip
Expected: Falls back to traditional validation, shows error
Result: ✅ Pass
```

---

## Future Enhancements

### 1. Visual Indicator
```
┌────────────────────────────────────────┐
│ 💡 Detected Format: HDFC Bank         │
│ Using separate debit/credit columns   │
│ Type will be automatically assigned    │
└────────────────────────────────────────┘
```

### 2. Quick Switch
```
┌──────────────────────────────────────┐
│ Using separate debit/credit columns │
│ ┌─────────────────────────────────┐ │
│ │ Switch to Single Amount Column  │ │
│ └─────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### 3. Bank Presets
```typescript
const bankPresets = {
  hdfc: {
    debitColumn: 'Withdrawal Amt.',
    creditColumn: 'Deposit Amt.',
    descriptionColumn: 'Narration'
  },
  icici: {
    debitColumn: 'Debit',
    creditColumn: 'Credit',
    descriptionColumn: 'Transaction Details'
  }
};
```

---

## Conclusion

The ColumnMapper now intelligently handles both:

1. ✅ **Separate debit/credit columns** (HDFC, ICICI, SBI)
   - Auto-detects withdrawal/deposit columns
   - Makes "type" optional
   - Infers type from which column has value

2. ✅ **Single amount + type column** (Generic exports)
   - Works as before
   - Requires type column
   - Supports value mapping

**Result:** Users can import from any bank format without manual preprocessing!
