# Implementation Tracking - Current Feature Requests

**Date**: October 21, 2025  
**Context**: User's comprehensive feature request list

## Quick Status Summary

### ✅ COMPLETED TODAY
1. Fixed charts showing NaN - Balance calculations
2. Implemented dashboard net worth chart
3. Fixed account balance computation
4. Optimized for millions of transactions
5. Fixed Radix UI Select.Label error
6. **Fixed FD not showing up** - Added deposit types to filter

### 📋 PENDING - User's 10 Feature Requests

## Feature Request Details

### 1. Cache Transaction Computations
**Request**: "Cache the computations from transactions"  
**Status**: ✅ Planned  
**Priority**: HIGH  
**Document**: `/docs/feature-enhancements-plan.md`

**Implementation**:
```typescript
// Create: /webapp/src/core/cache/transactionCache.ts
class TransactionCache {
  private cache = new Map<string, CacheEntry>();
  private TTL = 5 * 60 * 1000; // 5 minutes
  
  get(key: string): any | null
  set(key: string, value: any): void
  invalidate(pattern: string): void
}
```

**Files to Create**:
- `/webapp/src/core/cache/transactionCache.ts`
- `/webapp/src/core/cache/types.ts`
- `/webapp/src/core/hooks/useCachedTransactions.ts`

**Estimated Time**: 2-3 hours

---

### 2. Initial Balance as Transaction
**Request**: "For initial amounts during account creations create it as a transaction rather than tied to account"  
**Status**: 📋 Planned  
**Priority**: MEDIUM  
**Impact**: Data model change, requires migration

**Changes Needed**:
1. Add `is_initial_balance` flag to transactions table
2. Migration script to convert existing `account.balance` to transactions
3. Update account creation flow to create initial transaction
4. Remove `balance` field from accounts table (or deprecate)

**SQL Migration**:
```sql
-- Add flag
ALTER TABLE transactions ADD COLUMN is_initial_balance BOOLEAN DEFAULT false;

-- Migrate existing balances
INSERT INTO transactions (id, account_id, amount, type, category, date, description, is_initial_balance)
SELECT 
  uuid_generate_v4(),
  id,
  balance,
  'income',
  'Initial Balance',
  created_at,
  'Opening Balance',
  true
FROM accounts WHERE balance > 0;
```

**Files to Update**:
- `/webapp/src/core/db/schema.sql`
- `/webapp/src/core/db/migrations/005_initial_balance.ts`
- `/webapp/src/features/accounts/components/AddAccountModal.tsx`
- `/webapp/src/shared/utils/financial.ts`

**Estimated Time**: 1 day

---

### 3. Deposit Account Extensions (FD, RD)
**Request**: "FDs, RDs etc will have start date, end date, interest rate. It might have monthly interest or interest at the end of the end date"  
**Status**: 📋 Planned  
**Priority**: HIGH  
**Document**: Complete schema in `/docs/feature-enhancements-plan.md`

**New Table Schema**:
```sql
CREATE TABLE deposit_details (
  id TEXT PRIMARY KEY,
  account_id TEXT REFERENCES accounts(id),
  principal_amount REAL NOT NULL,
  interest_rate REAL NOT NULL,
  interest_frequency TEXT NOT NULL, -- monthly/quarterly/yearly/at_maturity
  start_date TIMESTAMP NOT NULL,
  maturity_date TIMESTAMP NOT NULL,
  tds_percentage REAL DEFAULT 10.0,
  tds_applicable BOOLEAN DEFAULT true,
  maturity_amount REAL,
  monthly_installment REAL -- for RD
);
```

**Features**:
- Interest calculation (simple/compound)
- TDS deduction (10% if PAN, 20% if not)
- Auto-generate interest transactions (monthly/quarterly)
- Maturity alerts

**Files to Create**:
- `/webapp/src/core/db/schema/deposit_details.sql`
- `/webapp/src/core/db/types/deposits.ts`
- `/webapp/src/core/db/repositories/deposits.ts`
- `/webapp/src/features/deposits/utils/depositCalculations.ts`
- `/webapp/src/features/deposits/components/DepositForm.tsx`
- `/webapp/src/features/deposits/components/DepositDetails.tsx`

**Estimated Time**: 2-3 days

---

### 4. FD Projections & Tax Calculations
**Request**: "FDs might not have multiple transactions but I am interested in the total amount or the monthly interest I will get & the tax / TDS cuts"  
**Status**: 📋 Planned (Part of #3)  
**Priority**: HIGH

**Features**:
- Maturity value calculator
- Monthly interest projections
- TDS calculation and tracking
- Tax reporting view
- Interest income summary

**Calculation Formulas**:
```typescript
// Simple Interest (FD)
maturityAmount = principal + (principal × rate × time)
monthlyInterest = (principal × rate) / 12
tdsDeduction = interest × (tds_percentage / 100)

// Compound Interest (some FDs)
maturityAmount = principal × (1 + rate/n)^(n×time)
```

**Files to Create**:
- `/webapp/src/features/deposits/components/InterestCalculator.tsx`
- `/webapp/src/features/deposits/components/TaxProjections.tsx`
- `/webapp/src/features/deposits/utils/tdsCalculations.ts`

**Estimated Time**: 1-2 days (integrated with #3)

---

### 5. Multi-Select Filters for Accounts
**Request**: "Accounts page doesn't have all the filters, make it multi select dropdown"  
**Status**: 📋 Planned  
**Priority**: MEDIUM  
**Current**: Single-select filter

**Design**:
- Multi-select dropdown with checkboxes
- Show "X types selected" in button
- Clear all button
- Persist filter state
- Filter by: account type, status (active/closed), currency

**Component Structure**:
```typescript
<MultiSelect
  options={ACCOUNT_TYPES}
  selected={selectedTypes}
  onChange={setSelectedTypes}
  placeholder="All Account Types"
  renderLabel={(count) => `${count} type${count !== 1 ? 's' : ''} selected`}
/>
```

**Files to Create**:
- `/webapp/src/shared/components/MultiSelect/MultiSelect.tsx`
- `/webapp/src/shared/components/MultiSelect/MultiSelect.css`

**Files to Update**:
- `/webapp/src/features/accounts/components/AccountsList.tsx`

**Estimated Time**: 4-5 hours

---

### 6. FD Not Showing Up
**Request**: "I tried to add FD and it didn't show up"  
**Status**: ✅ FIXED  
**Priority**: CRITICAL (COMPLETED)

**Root Cause**: FILTER_OPTIONS array missing deposit account types

**Fix Applied**:
```typescript
// Before: 7 types
const FILTER_OPTIONS = ['all', 'bank', 'credit_card', 'upi', 'brokerage', 'cash', 'wallet'];

// After: 15 types (added 8 deposit types)
const FILTER_OPTIONS = [
  'all',
  'bank', 'credit_card', 'upi',
  'brokerage',
  'fixed_deposit', 'recurring_deposit', 'ppf', 'nsc', 'kvp', 'scss', 'post_office',
  'cash', 'wallet',
];
```

**File Modified**: `/webapp/src/features/accounts/components/AccountsList.tsx`  
**Lines**: 33-51

**Verification Steps**:
1. Create a Fixed Deposit account
2. Check if it appears in accounts list
3. Test filter dropdown shows "Fixed Deposit"
4. Test filtering by Fixed Deposit works

---

### 7. Account Type-Specific Views
**Request**: "Each account type might have different input fields and different views, investigate"  
**Status**: 📋 Planned  
**Priority**: HIGH

**Approach**: Polymorphic components based on account type

**Account Type Requirements**:

**Credit Card**:
- Credit limit, available credit
- Billing cycle, statement date, due date
- Minimum due, total due
- Rewards points tracking
- Payment reminders

**Fixed Deposit/RD**:
- Principal, interest rate, maturity date
- Interest payout schedule
- TDS tracking
- Maturity value projection
- Nominee details

**Brokerage**:
- Holdings view (stocks, mutual funds)
- P&L tracking
- Portfolio allocation chart
- Market value vs invested value

**Bank Account**:
- Standard transaction list
- Balance history
- Overdraft limit (if applicable)

**Files to Create**:
- `/webapp/src/features/accounts/components/views/BankAccountView.tsx`
- `/webapp/src/features/accounts/components/views/CreditCardView.tsx`
- `/webapp/src/features/accounts/components/views/DepositView.tsx`
- `/webapp/src/features/accounts/components/views/BrokerageView.tsx`
- `/webapp/src/features/accounts/components/AccountViewFactory.tsx`

**Files to Update**:
- `/webapp/src/features/accounts/components/AddAccountModal.tsx` - Conditional fields
- `/webapp/src/features/accounts/components/AccountDetails.tsx` - Use view factory

**Estimated Time**: 2-3 days

---

### 8. Fix Net Worth Computation
**Request**: "My net worth computation seems wrong in dashboard"  
**Status**: 📋 NEEDS INVESTIGATION  
**Priority**: CRITICAL

**Current Implementation**:
```typescript
// In NetWorthHero.tsx
const accountBalances = calculateAccountBalances(accounts, transactions);
const totalNetWorth = accountBalances.reduce((sum, acc) => sum + acc.balance, 0);
```

**Debug Steps**:
1. Add console logging to see what's being calculated
2. Verify all accounts are included
3. Check transaction filtering
4. Verify calculateAccountBalances is working correctly
5. Test with specific account set

**Possible Issues**:
- Not including certain account types?
- Filtering active/closed accounts incorrectly?
- Transaction date filtering issue?
- BigInt conversion problem?

**Next Action**: Add detailed logging and test with user's data

**Estimated Time**: 1-2 hours

---

### 9. Transaction Import - Duplicate Prevention
**Request**: "when importing transaction save ref/check no/id for avoiding duplicates"  
**Status**: 📋 Planned  
**Priority**: HIGH

**Schema Changes**:
```sql
ALTER TABLE transactions ADD COLUMN import_reference TEXT;
ALTER TABLE transactions ADD COLUMN import_check_number TEXT;
ALTER TABLE transactions ADD COLUMN import_transaction_id TEXT;
ALTER TABLE transactions ADD COLUMN import_source TEXT; -- csv/excel/pdf/manual
ALTER TABLE transactions ADD COLUMN import_date TIMESTAMP;
ALTER TABLE transactions ADD COLUMN import_file_hash TEXT;

CREATE INDEX idx_import_transaction_id ON transactions(import_transaction_id);
CREATE INDEX idx_import_reference ON transactions(import_reference);
CREATE INDEX idx_import_file_hash ON transactions(import_file_hash);
```

**Duplicate Detection Strategy**:
```typescript
// Primary: Exact match on import_transaction_id
const hasDuplicate = await db.query(
  'SELECT id FROM transactions WHERE import_transaction_id = $1',
  [txn.import_transaction_id]
);

// Secondary: Fuzzy match on account + date + amount + reference
if (!hasDuplicate) {
  const fuzzyMatch = await db.query(`
    SELECT id FROM transactions 
    WHERE account_id = $1 
    AND DATE(date) = DATE($2)
    AND ABS(amount - $3) < 0.01
    AND (import_reference = $4 OR description LIKE $5)
  `, [account, date, amount, reference, `%${reference}%`]);
}
```

**UI Flow**:
1. Parse imported file
2. Check each transaction for duplicates
3. Show preview with duplicate indicators
4. Allow user to: Skip, Update, or Force Add
5. Import non-duplicates

**Files to Update**:
- `/webapp/src/core/db/schema.sql`
- `/webapp/src/core/db/types.ts`
- `/webapp/src/features/transactions/utils/importParser.ts`
- `/webapp/src/features/transactions/components/ImportTransactionsModal.tsx`
- `/webapp/src/features/transactions/components/ImportPreview.tsx` (new)

**Estimated Time**: 1-2 days

---

### 10. Firebase Integration & Secure Key Storage
**Request**: "I don't see firebase integration, asking for api keys and saving it securely. Create firebase schema or metadata I need to use or create in firebase studio"  
**Status**: 📋 Planned  
**Priority**: HIGH  
**Document**: Complete Firestore schema in `/docs/feature-enhancements-plan.md`

**Firebase Setup Required**:

**1. Authentication**:
- Email/Password
- Google Sign-In
- Apple Sign-In
- Biometric re-authentication

**2. Firestore Schema**:
```
/users/{userId}/
  - profile: { email, displayName, createdAt }
  - settings: { currency, theme, sync_enabled }
  
  - accounts/{accountId}
    { name, type, institution, balance, currency, created_at }
  
  - transactions/{transactionId}
    { account_id, amount, type, category, date, description }
  
  - deposit_details/{depositId}
    { account_id, interest_rate, maturity_date, tds_percentage }
  
  - syncState
    { last_sync, version, device_id, status }
```

**3. Security Rules**:
```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

**4. Encryption Strategy**:
- User's master key derived from password (PBKDF2)
- Sensitive fields encrypted client-side before upload
- API keys stored in encrypted localStorage
- Biometric protection for master key

**5. Sync Strategy**:
- Real-time listeners for multi-device sync
- Conflict resolution: Last-write-wins with version tracking
- Offline support with local queue
- Batch sync on reconnection

**Files to Create**:
- `/webapp/src/core/firebase/config.ts`
- `/webapp/src/core/firebase/auth.ts`
- `/webapp/src/core/firebase/firestore.ts`
- `/webapp/src/core/firebase/sync.ts`
- `/webapp/src/core/firebase/encryption.ts`
- `/webapp/src/core/hooks/useAuth.ts`
- `/webapp/src/core/hooks/useFirebaseSync.ts`
- `/webapp/src/features/settings/components/FirebaseSetup.tsx`

**Environment Variables Needed**:
```env
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
VITE_FIREBASE_STORAGE_BUCKET=...
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=...
```

**UI Flow**:
1. Settings → Cloud Sync
2. "Enable Firebase Sync" button
3. Sign up / Sign in
4. Enable biometric protection
5. Initial sync (upload local data)
6. Real-time sync active

**Estimated Time**: 1 week

---

## Implementation Priority & Timeline

### Week 1 (Current) - Critical Fixes
- [x] Fix charts and balances
- [x] Fix FD filter issue
- [ ] **Debug net worth computation** ← NEXT
- [ ] Implement transaction caching
- [ ] Create initial balance migration plan

### Week 2 - Deposit Accounts
- [ ] Create deposit_details schema
- [ ] Implement deposit forms
- [ ] Add interest calculations
- [ ] Add TDS tracking
- [ ] Implement maturity alerts

### Week 3 - UX Improvements
- [ ] Multi-select filters
- [ ] Account type-specific views
- [ ] Transaction duplicate detection
- [ ] Import preview improvements

### Week 4 - Cloud Integration
- [ ] Firebase project setup
- [ ] Authentication flow
- [ ] Firestore schema implementation
- [ ] Sync service
- [ ] Encryption layer
- [ ] Offline support

---

## Testing Requirements

### Unit Tests
- [ ] Transaction cache (get, set, invalidate)
- [ ] Duplicate detection algorithm
- [ ] Interest calculations (simple, compound)
- [ ] TDS calculations
- [ ] Encryption/decryption functions

### Integration Tests
- [ ] Account creation with initial transaction
- [ ] Deposit interest auto-generation
- [ ] Transaction import with duplicates
- [ ] Firebase sync workflow
- [ ] Conflict resolution

### E2E Tests
- [ ] Complete FD lifecycle (create → interest → mature)
- [ ] Import transactions from CSV/Excel
- [ ] Multi-device sync
- [ ] Offline → Online sync recovery

---

## Questions for User

1. **Net Worth Issue**: Can you provide specific example? (e.g., "I have 3 accounts with X, Y, Z balances but showing W")
2. **Firebase Preference**: Do you already have a Firebase project, or should we create one?
3. **Encryption Level**: Encrypt all data or just sensitive fields (account numbers, etc.)?
4. **Sync Frequency**: Real-time or periodic (e.g., every 5 minutes)?
5. **Initial Balance Migration**: Auto-migrate existing accounts or ask user confirmation?
6. **Interest Transactions**: Auto-generate monthly or manual entry?

---

## Next Immediate Action

**Priority 1**: Debug net worth computation issue
- Add detailed console logging
- Test with actual data
- Identify discrepancy source

**Priority 2**: Test FD fix
- Create a Fixed Deposit account
- Verify it appears in list
- Test filtering

**Priority 3**: Start transaction caching implementation
- Create TransactionCache class
- Integrate with calculateAccountBalances
- Test performance improvement

