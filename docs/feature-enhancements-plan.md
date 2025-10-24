# Feature Enhancements Plan

**Date**: October 21, 2025  
**Status**: Planning & Implementation

## Requirements Overview

### 1. ✅ Cache Transaction Computations
**Priority**: HIGH  
**Impact**: Performance optimization for large datasets

**Implementation**:
- Add React Query or SWR for data caching
- Implement memoization for expensive calculations
- Add cache invalidation on transaction create/update/delete
- Consider IndexedDB for persistent cache

### 2. 🔄 Initial Balance as Transaction
**Priority**: HIGH  
**Impact**: Cleaner data model, better audit trail

**Current**: `account.balance` field  
**Proposed**: Create "Initial Balance" transaction on account creation

**Benefits**:
- Complete transaction history
- Easier balance reconciliation
- Better audit trail
- Simplifies balance calculations

**Migration Strategy**:
- Create migration to convert existing `account.balance` to initial transactions
- Update account creation flow
- Set `account.balance = 0` for new accounts
- Add `transaction.is_initial_balance` flag

### 3. 🆕 Deposit Account Type Extensions (FD, RD, etc.)
**Priority**: HIGH  
**Impact**: Core feature for Indian market

**Required Fields**:
```typescript
interface DepositAccount extends Account {
  type: 'fixed_deposit' | 'recurring_deposit' | 'ppf' | 'nsc' | 'kvp' | 'scss';
  
  // Deposit-specific fields
  deposit_details: {
    principal_amount: number;
    interest_rate: number; // Annual percentage
    start_date: Date;
    maturity_date: Date;
    
    // Interest payout
    interest_frequency: 'monthly' | 'quarterly' | 'yearly' | 'at_maturity';
    last_interest_payout?: Date;
    next_interest_payout?: Date;
    
    // Tax
    tds_percentage: number; // Usually 10%
    tds_applicable: boolean;
    
    // Maturity
    maturity_amount: number; // Calculated
    total_interest: number; // Calculated
    
    // Recurring deposit specific
    monthly_installment?: number; // For RD
    
    // Nomination
    nominee_name?: string;
    nominee_relationship?: string;
  };
}
```

**Calculations Required**:
- Monthly interest amount
- Maturity value
- TDS deductions (10% on interest if PAN provided, 20% if not)
- Tax liability (interest income is taxable)

**Auto-transactions**:
- Monthly interest credit (if applicable)
- TDS deduction transactions
- Maturity payout transaction

### 4. 🔍 Multi-Select Filters for Accounts Page
**Priority**: MEDIUM  
**Impact**: Better UX for filtering

**Current**: Single select or no filters  
**Proposed**: Multi-select dropdowns for:
- Account types (can select multiple)
- Status (active/closed)
- Currency
- Balance range

**Implementation**: Use Radix UI `Select` with `multiple` prop or build custom multi-select

### 5. 🐛 FD Not Showing Up
**Priority**: CRITICAL  
**Impact**: Blocking user workflow

**Investigation Needed**:
- Check if FD is being saved to database
- Check if FD is being filtered out in queries
- Check if `is_active` flag is set correctly
- Check account list rendering logic

### 6. 🎨 Account Type-Specific Views
**Priority**: HIGH  
**Impact**: Better UX for different account types

**Requirements**:
- **Bank Account**: Standard view with transactions
- **Credit Card**: Show credit limit, available credit, due date, statement cycle
- **FD/RD**: Show maturity details, interest calculations, auto-interest tracking
- **Brokerage**: Show holdings, portfolio value, P&L
- **UPI/Wallet**: Show linked accounts, QR code (future)

**Implementation**: Polymorphic components based on account type

### 7. 🐛 Net Worth Computation Wrong
**Priority**: CRITICAL  
**Impact**: Core metric incorrect

**Current Issues**:
- May be using initial balance instead of calculated balance
- May not be handling all account types correctly
- May have caching issues

**Debug Steps**:
1. Check NetWorthHero calculation logic
2. Verify `calculateAccountBalances()` is being used
3. Check if all account types are included
4. Verify transaction filtering

### 8. 💾 Transaction Import - Duplicate Prevention
**Priority**: HIGH  
**Impact**: Data integrity

**Implementation**:
```typescript
interface Transaction {
  // ... existing fields
  
  // Import metadata
  import_reference?: string; // Bank's reference number
  import_check_number?: string;
  import_transaction_id?: string; // Unique ID from bank
  import_source?: 'csv' | 'excel' | 'pdf' | 'manual';
  import_date?: Date;
  import_file_hash?: string; // Hash of source file
  
  // Additional metadata
  metadata?: {
    merchant_code?: string;
    merchant_category?: string;
    card_last_4?: string;
    authorization_code?: string;
    settlement_date?: Date;
    foreign_currency?: string;
    foreign_amount?: number;
    exchange_rate?: number;
    [key: string]: any; // Extensible
  };
}
```

**Duplicate Detection Strategy**:
1. Check if `import_transaction_id` exists
2. Check combination of: account_id + date + amount + reference
3. Show duplicate preview before import
4. Allow user to skip or update duplicates

### 9. 🔥 Firebase Integration
**Priority**: HIGH  
**Impact**: Cloud sync, multi-device support

**Requirements**:
- Secure API key storage
- User authentication
- Real-time sync
- Offline support
- Data encryption

## Implementation Priority

### Phase 1: Critical Fixes (Week 1)
1. ✅ Fix FD not showing up
2. ✅ Fix net worth computation
3. ✅ Add transaction caching

### Phase 2: Core Features (Week 2)
4. ✅ Initial balance as transaction (with migration)
5. ✅ Deposit account extensions (FD, RD fields)
6. ✅ Transaction duplicate prevention

### Phase 3: Enhanced Features (Week 3)
7. ✅ Multi-select filters
8. ✅ Account type-specific views
9. ✅ Transaction metadata

### Phase 4: Cloud Integration (Week 4)
10. ✅ Firebase setup
11. ✅ Authentication
12. ✅ Data sync
13. ✅ Secure key storage

---

## Detailed Implementation Plans

### 1. Transaction Caching Implementation

```typescript
// /webapp/src/core/cache/transactionCache.ts

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  expiresAt: number;
}

class TransactionCache {
  private cache = new Map<string, CacheEntry<any>>();
  private readonly TTL = 5 * 60 * 1000; // 5 minutes
  
  set<T>(key: string, data: T, ttl = this.TTL): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      expiresAt: Date.now() + ttl,
    });
  }
  
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    
    return entry.data as T;
  }
  
  invalidate(pattern: string): void {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }
  
  clear(): void {
    this.cache.clear();
  }
}

export const transactionCache = new TransactionCache();

// Usage in financial.ts
export function calculateAccountBalance(
  initialBalance: number | string,
  transactions: Transaction[]
): number {
  const cacheKey = `balance:${transactions.length}:${transactions[0]?.id}:${transactions[transactions.length-1]?.id}`;
  
  const cached = transactionCache.get<number>(cacheKey);
  if (cached !== null) return cached;
  
  // ... actual calculation
  
  transactionCache.set(cacheKey, balance);
  return balance;
}
```

### 2. Initial Balance Migration

```typescript
// /webapp/src/core/db/migrations/005_initial_balance_to_transaction.ts

export async function migrateInitialBalances(db: PGliteDatabase) {
  const accounts = await db.query('SELECT * FROM accounts WHERE balance != 0');
  
  for (const account of accounts.rows) {
    // Create initial balance transaction
    await db.query(`
      INSERT INTO transactions (
        id,
        account_id,
        amount,
        type,
        category,
        date,
        description,
        is_initial_balance
      ) VALUES (
        $1, $2, $3, 'income', 'Initial Balance', $4, 'Opening Balance', true
      )
    `, [
      `init_${account.id}`,
      account.id,
      account.balance,
      account.created_at
    ]);
  }
  
  // Reset account balances (keep for backward compatibility)
  // await db.query('UPDATE accounts SET balance = 0');
}
```

### 3. Deposit Account Schema

```sql
-- /webapp/src/core/db/schema/deposits.sql

CREATE TABLE deposit_details (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  
  -- Principal
  principal_amount REAL NOT NULL,
  
  -- Interest
  interest_rate REAL NOT NULL,
  interest_frequency TEXT NOT NULL CHECK (interest_frequency IN ('monthly', 'quarterly', 'yearly', 'at_maturity')),
  
  -- Dates
  start_date TIMESTAMP NOT NULL,
  maturity_date TIMESTAMP NOT NULL,
  last_interest_payout TIMESTAMP,
  next_interest_payout TIMESTAMP,
  
  -- Tax
  tds_percentage REAL DEFAULT 10.0,
  tds_applicable BOOLEAN DEFAULT true,
  
  -- Calculated fields (stored for performance)
  maturity_amount REAL,
  total_interest REAL,
  
  -- RD specific
  monthly_installment REAL,
  
  -- Nomination
  nominee_name TEXT,
  nominee_relationship TEXT,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deposit_details_account ON deposit_details(account_id);
CREATE INDEX idx_deposit_details_maturity ON deposit_details(maturity_date);
```

### 4. Firebase Schema

```typescript
// Firebase Firestore Structure

/**
 * /users/{userId}
 */
interface UserDocument {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  
  // Preferences
  preferences: {
    currency: string;
    locale: string;
    theme: 'light' | 'dark' | 'auto';
  };
  
  // Subscription
  subscription: {
    plan: 'free' | 'premium';
    status: 'active' | 'cancelled' | 'expired';
    startDate: Timestamp;
    endDate?: Timestamp;
  };
  
  // Metadata
  createdAt: Timestamp;
  lastLoginAt: Timestamp;
  lastSyncAt?: Timestamp;
}

/**
 * /users/{userId}/accounts/{accountId}
 */
interface AccountDocument {
  id: string;
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  isActive: boolean;
  
  // Deposit details (if applicable)
  depositDetails?: DepositDetails;
  
  // Encryption
  encryptedData?: string; // Encrypted sensitive fields
  
  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt?: Timestamp;
}

/**
 * /users/{userId}/transactions/{transactionId}
 */
interface TransactionDocument {
  id: string;
  accountId: string;
  amount: number;
  type: 'income' | 'expense' | 'transfer';
  category: string;
  date: Timestamp;
  description: string;
  
  // Import metadata
  importReference?: string;
  importSource?: string;
  importFileHash?: string;
  
  // Additional metadata
  metadata?: Record<string, any>;
  
  // Flags
  isInitialBalance?: boolean;
  isReconciled?: boolean;
  
  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt?: Timestamp;
}

/**
 * /users/{userId}/syncState
 */
interface SyncStateDocument {
  lastSyncAt: Timestamp;
  pendingChanges: number;
  conflictedItems: string[];
  syncStatus: 'idle' | 'syncing' | 'error';
  lastError?: string;
}

/**
 * Security Rules
 */
const firestoreRules = `
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's accounts
      match /accounts/{accountId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's transactions
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Sync state
      match /syncState {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
`;

/**
 * API Key Storage (Firebase Remote Config + Local Secure Storage)
 */
interface SecureConfig {
  firebaseConfig: {
    apiKey: string; // Encrypted in localStorage
    authDomain: string;
    projectId: string;
    storageBucket: string;
    messagingSenderId: string;
    appId: string;
  };
  
  // Encryption key (stored in secure enclave if available)
  encryptionKey: string; // Never stored in plain text
}
```

### 5. Multi-Select Filter Component

```typescript
// /webapp/src/shared/components/MultiSelect/MultiSelect.tsx

interface MultiSelectProps {
  options: Array<{ value: string; label: string; icon?: React.ReactNode }>;
  value: string[];
  onChange: (values: string[]) => void;
  placeholder?: string;
  label?: string;
}

export function MultiSelect({ options, value, onChange, placeholder, label }: MultiSelectProps) {
  const [open, setOpen] = useState(false);
  
  const handleToggle = (optionValue: string) => {
    if (value.includes(optionValue)) {
      onChange(value.filter(v => v !== optionValue));
    } else {
      onChange([...value, optionValue]);
    }
  };
  
  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger>
        <Button variant="outline">
          {value.length === 0 
            ? placeholder 
            : `${value.length} selected`}
        </Button>
      </PopoverTrigger>
      <PopoverContent>
        {options.map(option => (
          <div key={option.value} onClick={() => handleToggle(option.value)}>
            <Checkbox checked={value.includes(option.value)} />
            {option.icon}
            <span>{option.label}</span>
          </div>
        ))}
      </PopoverContent>
    </Popover>
  );
}
```

---

## Next Steps

1. **Immediate**: Debug FD not showing up
2. **Today**: Fix net worth computation
3. **This Week**: Implement caching
4. **Next Week**: Start Firebase integration planning

## Questions for Clarification

1. **Firebase**: Do you want to use Firebase or should we consider alternatives like Supabase?
2. **Encryption**: Should sensitive data (balances, account numbers) be encrypted at rest?
3. **Sync Strategy**: Real-time sync or periodic sync?
4. **Offline Mode**: Should the app work fully offline with sync when online?
5. **Multi-device**: Should changes from one device immediately reflect on another?

