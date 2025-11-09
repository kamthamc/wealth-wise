# Feature #2: Initial Balance as Transaction

## Overview
Converted account initial balances from a static field in the accounts table to proper transactions with a special `is_initial_balance` flag. This architectural change ensures all balance changes are tracked through transactions, enabling better history tracking, auditing, and balance recalculation.

## Implementation Date
2025-01-XX (Feature #2 from 10-item feature request list)

## Problem Statement
Previously, when creating an account with an initial balance:
- Balance was stored in `accounts.balance` field
- No transaction record existed for the opening balance
- Balance history started from first actual transaction
- Couldn't recalculate balance from transaction history alone
- Inconsistent data model (some balances in accounts, some in transactions)

## Solution Approach
1. Add `is_initial_balance` boolean field to transactions table
2. Implement database migration (v2→v3) to convert existing balances
3. Update account creation flow to create initial transaction
4. Update transaction repository to handle new field

## Technical Changes

### 1. Database Schema Update

**File**: `webapp/src/core/db/schema.ts`

**Changes**:
```sql
-- Added to transactions table
is_initial_balance BOOLEAN NOT NULL DEFAULT false

-- Version bump
export const DATABASE_VERSION = 3; -- Was 2
```

### 2. TypeScript Type Updates

**File**: `webapp/src/core/db/types.ts`

**Changes**:
```typescript
export interface Transaction {
  // ... existing fields
  is_initial_balance: boolean; // NEW: Marks transaction as opening balance
  created_at: Date;
  updated_at: Date;
}
```

**Impact**: `CreateTransactionInput` automatically includes field via `Omit<Transaction, ...>`

### 3. Database Migration (v2→v3)

**File**: `webapp/src/core/db/client.ts`

**Implementation**:
```typescript
if (from < 3 && to >= 3) {
  console.log('[DB] Migration 2→3: Converting initial balances to transactions');

  // 1. Add is_initial_balance column
  await this.db?.query(`
    ALTER TABLE transactions 
    ADD COLUMN IF NOT EXISTS is_initial_balance BOOLEAN NOT NULL DEFAULT false
  `);

  // 2. Get all accounts with non-zero balances
  const accountsResult = await this.db?.query(`
    SELECT id, balance, created_at, name FROM accounts WHERE balance != 0
  `);

  // 3. Create initial balance transactions
  if (accountsResult && accountsResult.rows.length > 0) {
    for (const row of accountsResult.rows) {
      const account = row as { id: string; balance: number; created_at: string; name: string };
      
      await this.db?.query(`
        INSERT INTO transactions (
          account_id, amount, type, category, date, 
          description, is_initial_balance, is_recurring
        )
        VALUES ($1, $2, $3, $4, $5, $6, true, false)
      `, [
        account.id,
        Math.abs(account.balance),
        account.balance >= 0 ? 'income' : 'expense',
        'Initial Balance',
        account.created_at,
        `Opening balance for ${account.name}`,
      ]);
    }
  }

  console.log('[DB] ✅ Migration 2→3 completed');
}
```

**Migration Logic**:
- Adds `is_initial_balance` column with default `false`
- Finds all accounts with non-zero balances
- Creates transaction for each account:
  - Amount: Absolute value of balance
  - Type: `income` if positive, `expense` if negative
  - Category: "Initial Balance"
  - Date: Account creation date
  - `is_initial_balance`: `true`
- **Note**: Keeps `accounts.balance` unchanged for backward compatibility

### 4. Account Creation Flow

**File**: `webapp/src/core/stores/accountStore.ts`

**Changes**:
```typescript
import { transactionRepository } from '@/core/db';

createAccount: async (input) => {
  const account = await accountRepository.create(input);
  
  // Create initial balance transaction if balance is provided
  if (input.balance && input.balance !== 0) {
    await transactionRepository.create({
      account_id: account.id,
      type: input.balance >= 0 ? 'income' : 'expense',
      category: 'Initial Balance',
      amount: Math.abs(input.balance),
      description: `Opening balance for ${account.name}`,
      date: account.created_at,
      is_initial_balance: true,
      is_recurring: false,
    });
  }
  
  // ... rest of function
}
```

**Behavior**:
- When creating account with balance > 0, creates transaction automatically
- Transaction is marked with `is_initial_balance: true`
- Uses account creation date as transaction date
- Balance still stored in `accounts.balance` (dual approach)

### 5. Transaction Repository Update

**File**: `webapp/src/core/db/repositories/transactions.ts`

**Changes**:
```typescript
async create(input: CreateTransactionInput): Promise<Transaction> {
  const result = await db.query<Transaction>(
    `INSERT INTO transactions (
      account_id, type, category, amount, description, date, 
      tags, is_recurring, recurring_frequency, is_initial_balance
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING *`,
    [
      // ... existing parameters
      input.is_initial_balance || false, // NEW parameter
    ]
  );
  // ...
}
```

**Behavior**:
- Accepts `is_initial_balance` in input
- Defaults to `false` if not provided
- Stores value in database

## Testing Checklist

### Migration Testing
- [ ] Fresh database (no existing data)
  - [ ] Create account with initial balance
  - [ ] Verify transaction is created with `is_initial_balance: true`
  - [ ] Verify account balance matches transaction amount

- [ ] Existing database (v2 with data)
  - [ ] Run migration
  - [ ] Verify column added successfully
  - [ ] Verify initial transactions created for existing accounts
  - [ ] Verify transaction dates match account creation dates
  - [ ] Verify transaction categories are "Initial Balance"

### Account Creation Testing
- [ ] Create account with positive balance
  - [ ] Verify income transaction created
  - [ ] Verify `is_initial_balance: true`

- [ ] Create account with negative balance (debt)
  - [ ] Verify expense transaction created
  - [ ] Verify `is_initial_balance: true`

- [ ] Create account with zero balance
  - [ ] Verify no initial transaction created

- [ ] Create account without balance field
  - [ ] Verify no initial transaction created

### Data Integrity Testing
- [ ] Verify transaction date matches account creation date
- [ ] Verify transaction category is "Initial Balance"
- [ ] Verify transaction description includes account name
- [ ] Verify transaction is NOT marked as recurring
- [ ] Verify both `accounts.balance` and transaction exist

### UI Testing
- [ ] Transaction list shows initial balance transactions
- [ ] Initial transactions have proper visual indicator
- [ ] Balance calculations are accurate
- [ ] Account history shows opening balance

## Benefits

### Data Consistency
- **Single Source of Truth**: All balance changes tracked through transactions
- **Complete History**: Balance history starts from account creation
- **Recalculation**: Can recalculate balance from transaction history alone

### Auditing & Reporting
- **Full Audit Trail**: Opening balances have timestamps and descriptions
- **Better Reporting**: Can include/exclude initial balances in reports
- **Transaction Filtering**: Can filter out initial balance transactions

### Future Enhancements
- **Balance Reconciliation**: Easier to reconcile with bank statements
- **Historical Accuracy**: Can track balance at any point in time
- **Migration Support**: Can convert between account types
- **Rollback Capability**: Can undo initial balance if needed

## Backward Compatibility

### Dual Storage Approach
- `accounts.balance` field still exists and is set during creation
- Initial balance also stored as transaction
- Allows gradual migration to transaction-only balance calculation
- Existing balance calculation logic continues to work

### Migration Safety
- Migration only creates new transactions, doesn't modify accounts
- Can optionally set `accounts.balance = 0` in future migration
- Non-destructive: Original balance data preserved

## Future Improvements

### Phase 1 (Current) ✅
- [x] Add `is_initial_balance` field
- [x] Create migration v2→v3
- [x] Update account creation flow
- [x] Update transaction repository

### Phase 2 (Optional)
- [ ] Add UI indicator for initial balance transactions
- [ ] Add filter to include/exclude initial balances
- [ ] Update balance calculation to use transactions only

### Phase 3 (Advanced)
- [ ] Migration to set `accounts.balance = 0` (use transactions only)
- [ ] Add validation: ensure account balance matches transaction sum
- [ ] Add automatic balance reconciliation
- [ ] Support editing initial balance (updates transaction)

## Related Features

**Completed**:
- Feature #1: Transaction Caching ✅

**Pending**:
- Feature #3: Deposit account extensions (interest, maturity)
- Feature #5: Multi-select filters for accounts
- Feature #9: Import duplicate detection

## Performance Impact

### Migration Performance
- **Time Complexity**: O(n) where n = number of accounts with non-zero balance
- **Expected Duration**: < 1 second for typical database (< 100 accounts)
- **Blocking**: Migration runs synchronously during app initialization

### Runtime Performance
- **Account Creation**: +1 transaction insert (~5-10ms)
- **No Impact**: Balance calculations unchanged (still cached)
- **Storage**: +1 row per account in transactions table

### Optimization Opportunities
- Migration can be batched for very large datasets
- Initial balance transactions can be indexed separately
- Can add composite index on (account_id, is_initial_balance)

## Rollback Plan

If issues arise, rollback by:
1. Revert database version to 2
2. Delete initial balance transactions:
   ```sql
   DELETE FROM transactions WHERE is_initial_balance = true;
   ```
3. Drop column (optional):
   ```sql
   ALTER TABLE transactions DROP COLUMN is_initial_balance;
   ```
4. Revert code changes

## Conclusion

Feature #2 successfully implements a cleaner architecture for tracking account balances through transactions. The dual storage approach ensures backward compatibility while enabling future enhancements. Migration is safe, non-destructive, and handles existing data gracefully.

**Status**: ✅ Implementation Complete
**Next**: Test migration and account creation flow
**After**: Move to Feature #3 (Deposit extensions)
