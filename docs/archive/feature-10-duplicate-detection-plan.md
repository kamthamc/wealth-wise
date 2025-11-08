# Feature #10: Transaction Duplicate Detection

**Status**: 🚧 In Progress  
**Started**: October 21, 2025  
**Estimated Time**: 6-8 hours  
**Priority**: HIGH - Data Integrity & UX Improvement

---

## Overview

Implement intelligent duplicate detection during transaction imports to prevent data duplication and improve user experience when importing bank statements multiple times.

---

## Problem Statement

### Current Behavior
- Users can import the same bank statement multiple times
- No detection of duplicate transactions
- Results in inflated balances and incorrect financial data
- Users must manually identify and delete duplicates
- Time-consuming and error-prone process

### User Pain Points
1. **Overlapping Statements**: Bank exports often have date ranges that overlap
2. **Re-imports**: Users may accidentally import the same file twice
3. **Manual Cleanup**: Finding and removing duplicates is tedious
4. **Data Integrity**: Duplicate data leads to incorrect financial analysis
5. **Loss of Trust**: Users lose confidence in the accuracy of their data

---

## Solution Design

### Smart Duplicate Detection

**Three-Tier Detection System**:

1. **Exact Match** (100% confidence)
   - Same transaction reference ID from bank (Chq./Ref.No., UTR, UPI ID, etc.)
   - **ENHANCED**: Intelligently extracts reference IDs from multiple sources:
     - Explicit reference column (if mapped)
     - Description text parsing (HDFC: "Chq./Ref.No.", ICICI: "Ref #", SBI: "UTR No.")
     - UPI transaction IDs
     - IMPS/NEFT/RTGS references
   - Prevents importing from same bank statement twice

2. **Strong Match** (95% confidence)
   - Same account + date + amount + description (fuzzy)
   - High probability of duplicate

3. **Possible Match** (70% confidence)
   - Same account + date within 24h + similar amount + similar description
   - User decides if duplicate

### User Experience Flow

```
┌────────────────────────────────────────────┐
│ 1. User uploads bank statement CSV         │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ 2. Parse file & extract transactions       │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ 3. Run duplicate detection algorithm       │
│    • Check import reference                │
│    • Check exact matches                   │
│    • Check fuzzy matches                   │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ 4. Show import preview with indicators     │
│    ✅ New (150)                            │
│    ⚠️  Possible duplicate (15)             │
│    ❌ Exact duplicate (5)                  │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ 5. User reviews & chooses action           │
│    • Skip duplicates                       │
│    • Update existing                       │
│    • Force add anyway                      │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ 6. Execute import with user choices        │
└────────────────────────────────────────────┘
```

---

## Technical Implementation

### Phase 1: Database Schema (1 hour)

**Add Import Metadata Columns**:

```sql
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS import_reference TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS import_transaction_id TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS import_file_hash TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS import_source TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS import_date TIMESTAMP;

-- Indices for fast duplicate detection
CREATE INDEX IF NOT EXISTS idx_transactions_import_ref 
  ON transactions(import_reference);
CREATE INDEX IF NOT EXISTS idx_transactions_import_txn_id 
  ON transactions(import_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_date_amount 
  ON transactions(account_id, date, amount);
```

**Column Purposes**:
- `import_reference`: Unique ID for each import session (UUID)
- `import_transaction_id`: Bank's transaction reference/ID
- `import_file_hash`: SHA-256 hash of imported file
- `import_source`: Source system (e.g., "HDFC Bank CSV", "ICICI Excel")
- `import_date`: When the transaction was imported

**Updated TypeScript Interface**:

```typescript
export interface Transaction {
  // ... existing fields ...
  import_reference?: string;
  import_transaction_id?: string;
  import_file_hash?: string;
  import_source?: string;
  import_date?: Date;
}
```

### Phase 2: Duplicate Detection Service (2-3 hours)

**File**: `/webapp/src/core/services/duplicateDetectionService.ts`

**Duplicate Match Types**:

```typescript
export type DuplicateConfidence = 'exact' | 'high' | 'possible';

export interface DuplicateMatch {
  existingTransaction: Transaction;
  confidence: DuplicateConfidence;
  matchReasons: string[];
  score: number; // 0-100
}

export interface DuplicateCheckResult {
  isNewTransaction: boolean;
  duplicateMatches: DuplicateMatch[];
  bestMatch?: DuplicateMatch;
}
```

**Detection Algorithm**:

```typescript
class DuplicateDetectionService {
  /**
   * Check if transaction is duplicate
   * Returns all potential matches with confidence scores
   */
  async checkDuplicate(
    transaction: ParsedTransaction,
    accountId: string
  ): Promise<DuplicateCheckResult> {
    // 1. Check import_transaction_id (exact match)
    if (transaction.reference) {
      const exactMatch = await this.findByImportTransactionId(
        accountId,
        transaction.reference
      );
      if (exactMatch) {
        return {
          isNewTransaction: false,
          duplicateMatches: [{
            existingTransaction: exactMatch,
            confidence: 'exact',
            matchReasons: ['Same transaction reference ID'],
            score: 100
          }],
          bestMatch: { /* ... */ }
        };
      }
    }

    // 2. Check by date + amount + description (strong match)
    const strongMatches = await this.findByDateAmountDescription(
      accountId,
      transaction.date,
      transaction.amount,
      transaction.description
    );

    // 3. Check by fuzzy match (possible match)
    const fuzzyMatches = await this.findByFuzzyMatch(
      accountId,
      transaction.date,
      transaction.amount,
      transaction.description
    );

    // Combine and score matches
    const allMatches = [...strongMatches, ...fuzzyMatches];
    
    return {
      isNewTransaction: allMatches.length === 0,
      duplicateMatches: allMatches,
      bestMatch: allMatches[0] // Highest score
    };
  }

  /**
   * String similarity using Levenshtein distance
   */
  private calculateSimilarity(str1: string, str2: string): number {
    // Normalize strings
    const s1 = str1.toLowerCase().trim();
    const s2 = str2.toLowerCase().trim();
    
    // Calculate Levenshtein distance
    const distance = this.levenshteinDistance(s1, s2);
    const maxLength = Math.max(s1.length, s2.length);
    
    // Convert to similarity percentage
    return ((maxLength - distance) / maxLength) * 100;
  }

  /**
   * Date proximity check (within 24 hours)
   */
  private isDateSimilar(date1: Date, date2: Date): boolean {
    const diff = Math.abs(date1.getTime() - date2.getTime());
    const oneDayMs = 24 * 60 * 60 * 1000;
    return diff <= oneDayMs;
  }

  /**
   * Amount proximity check (within 1%)
   */
  private isAmountSimilar(amount1: number, amount2: number): boolean {
    const diff = Math.abs(amount1 - amount2);
    const tolerance = Math.max(amount1, amount2) * 0.01; // 1%
    return diff <= tolerance;
  }
}
```

**Detection Thresholds**:
- **Exact Match**: `score = 100` - Same import_transaction_id
- **High Confidence**: `score >= 95` - Same date (exact) + amount (exact) + description (>90% similar)
- **Possible Match**: `score >= 70` - Date within 24h + amount within 1% + description >70% similar

### Phase 3: Import Preview UI (2-3 hours)

**Component**: `DuplicateReviewModal.tsx`

**Features**:
- ✅ Show all transactions with duplicate indicators
- ✅ Color coding: Green (new), Yellow (possible), Red (duplicate)
- ✅ Bulk actions: "Skip All Duplicates", "Import All New"
- ✅ Individual actions: Skip / Update / Force Add
- ✅ Show confidence score and match reasons
- ✅ Compare side-by-side (new vs existing)

**UI Layout**:

```
┌──────────────────────────────────────────────────────────────┐
│ Import Preview - 170 transactions found                       │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ Summary:                                                      │
│  ✅ 150 New transactions                                     │
│  ⚠️  15 Possible duplicates                                  │
│  ❌ 5 Exact duplicates                                       │
│                                                               │
│ Quick Actions:                                                │
│  [Skip All Duplicates] [Import All New]                      │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ Transaction List:                                             │
│                                                               │
│ ❌ DUPLICATE (100% match)                                    │
│ 2025-01-15 | Salary Payment | ₹50,000.00 | Income           │
│ ⚙️ Action: [Skip] [Update] [Force Add]                      │
│ 📋 Existing: Same date, amount, and reference ID            │
│                                                               │
│ ⚠️  POSSIBLE DUPLICATE (85% match)                           │
│ 2025-01-16 | Grocery Store | ₹2,543.00 | Expense            │
│ ⚙️ Action: [Skip] [Import as New]                           │
│ 📋 Similar to: 2025-01-16 | Grocery | ₹2,500.00             │
│                                                               │
│ ✅ NEW                                                        │
│ 2025-01-17 | Netflix | ₹499.00 | Expense                    │
│ ⚙️ Action: [Import] (auto-selected)                         │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**User Actions**:

1. **Skip**: Don't import (for duplicates)
2. **Update**: Update existing transaction with new data
3. **Force Add**: Import as new despite duplicate warning
4. **Bulk Skip**: Skip all marked duplicates
5. **Bulk Import**: Import all new transactions

### Phase 4: Integration (1-2 hours)

**Update**: `ImportTransactionsModal.tsx`

**Changes**:
1. Generate unique `import_reference` UUID for each import session
2. Calculate file hash using SHA-256
3. Run duplicate detection on all parsed transactions
4. Show `DuplicateReviewModal` instead of direct preview
5. Apply user actions during import
6. Store import metadata with each transaction

**Updated Import Flow**:

```typescript
const handleMappingComplete = async (mappings: any[]) => {
  // Parse transactions
  const transactions = parseTransactions(mappings);
  
  // Generate import metadata
  const importReference = crypto.randomUUID();
  const fileHash = await calculateFileHash(selectedFile);
  const importSource = detectBankFormat(selectedFile);
  
  // Run duplicate detection
  const results = await Promise.all(
    transactions.map(txn => 
      duplicateDetectionService.checkDuplicate(txn, accountId)
    )
  );
  
  // Show review modal with results
  setDuplicateReview({
    transactions,
    results,
    importReference,
    fileHash,
    importSource
  });
  setShowDuplicateReview(true);
};

const handleImportWithActions = async (actions: UserAction[]) => {
  for (let i = 0; i < actions.length; i++) {
    const action = actions[i];
    const transaction = duplicateReview.transactions[i];
    
    switch (action.type) {
      case 'skip':
        continue; // Don't import
        
      case 'import':
        await createTransaction({
          ...transaction,
          import_reference: duplicateReview.importReference,
          import_file_hash: duplicateReview.fileHash,
          import_source: duplicateReview.importSource,
          import_date: new Date()
        });
        break;
        
      case 'update':
        await updateTransaction(action.existingId, {
          ...transaction,
          import_reference: duplicateReview.importReference
        });
        break;
        
      case 'force':
        await createTransaction({
          ...transaction,
          import_reference: duplicateReview.importReference,
          import_file_hash: duplicateReview.fileHash
        });
        break;
    }
  }
};
```

---

## File Changes Summary

### New Files (4)
1. `/webapp/src/core/services/duplicateDetectionService.ts` (~300 lines)
2. `/webapp/src/features/accounts/components/DuplicateReviewModal.tsx` (~400 lines)
3. `/webapp/src/features/accounts/components/DuplicateReviewModal.css` (~150 lines)
4. `/webapp/src/core/db/migrations/005_add_import_metadata.ts` (~50 lines)

### Modified Files (4)
1. `/webapp/src/core/db/schema.ts` (add import columns)
2. `/webapp/src/core/db/types.ts` (add import fields to Transaction interface)
3. `/webapp/src/features/accounts/components/ImportTransactionsModal.tsx` (integrate duplicate detection)
4. `/webapp/src/core/repositories/transactionRepository.ts` (support import metadata)

**Total Estimated Changes**: ~1,200 lines

---

## Testing Strategy

### Unit Tests
- ✅ String similarity algorithm accuracy
- ✅ Date proximity detection
- ✅ Amount proximity detection
- ✅ Duplicate scoring logic
- ✅ Edge cases (null values, special characters)

### Integration Tests
- ✅ Full import flow with duplicates
- ✅ Bulk actions (skip all, import all)
- ✅ Individual action handling
- ✅ Database persistence of import metadata

### Manual Testing
1. Import same file twice → Should detect all as duplicates
2. Import overlapping date range → Should detect partial duplicates
3. Import with slight variations → Should detect as possible matches
4. Test all user actions (skip, update, force)
5. Verify import metadata saved correctly

---

## Success Criteria

### Functional Requirements
- ✅ Detect 100% of exact duplicates (same reference ID)
- ✅ Detect >95% of duplicate transactions (same date/amount/desc)
- ✅ Allow user to review and choose action for each transaction
- ✅ Support bulk actions for efficiency
- ✅ Persist import metadata for audit trail

### Performance Requirements
- ✅ Duplicate detection completes in <2 seconds for 1,000 transactions
- ✅ UI remains responsive during detection
- ✅ Database queries optimized with proper indices

### User Experience
- ✅ Clear visual indicators for duplicate status
- ✅ Helpful match reasons and confidence scores
- ✅ Easy bulk actions for common scenarios
- ✅ Non-technical language in UI

---

## Future Enhancements

### Phase 2 (Later)
1. **Machine Learning**: Learn from user actions to improve detection
2. **Smart Suggestions**: Auto-select likely action based on confidence
3. **Import History**: Show which files were imported when
4. **Conflict Resolution**: Handle when same transaction updated from different files
5. **Cross-Account Detection**: Detect transfers between accounts

---

## Implementation Checklist

### Phase 1: Database Schema ⏳
- [ ] Create migration file
- [ ] Add import metadata columns
- [ ] Create indices for performance
- [ ] Update TypeScript types
- [ ] Test migration on sample database

### Phase 2: Duplicate Detection Service ⏳
- [ ] Create service class
- [ ] Implement exact match detection
- [ ] Implement fuzzy match detection
- [ ] Implement string similarity (Levenshtein)
- [ ] Add confidence scoring
- [ ] Write unit tests

### Phase 3: Import Preview UI ⏳
- [ ] Create DuplicateReviewModal component
- [ ] Add duplicate indicators (colors, icons)
- [ ] Implement action selection
- [ ] Add bulk actions
- [ ] Create comparison view
- [ ] Style component

### Phase 4: Integration ⏳
- [ ] Update ImportTransactionsModal
- [ ] Add file hash generation
- [ ] Integrate duplicate detection
- [ ] Handle user actions
- [ ] Store import metadata
- [ ] Update transaction repository
- [ ] Test end-to-end flow

---

**Next Step**: Start Phase 1 - Database Schema Updates
