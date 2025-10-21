# FD Not Showing Up - Debug & Fix

**Date**: October 21, 2025  
**Issue**: Fixed Deposits and other deposit account types not appearing in accounts list

## Root Cause Analysis

### 1. Filter Options Incomplete
**File**: `/webapp/src/features/accounts/components/AccountsList.tsx`

**Problem**:
```typescript
const FILTER_OPTIONS: (AccountType | 'all')[] = [
  'all',
  'bank',
  'credit_card',
  'upi',
  'brokerage',
  'cash',
  'wallet',
];
```

**Missing Types**:
- `fixed_deposit`
- `recurring_deposit`
- `ppf`
- `nsc`
- `kvp`
- `scss`
- `post_office`

**Impact**: Deposit accounts can be created but cannot be filtered, which might cause display issues in certain views.

### 2. Default Filter Behavior
When no filter is selected, ALL accounts should show. Currently this works, but having incomplete filter options creates confusion.

### 3. Account Display Logic
Need to verify that deposit accounts render properly with their specific icons and details.

## Fixes Required

### Fix 1: Update Filter Options
Add all account types to filter list:

```typescript
const FILTER_OPTIONS: (AccountType | 'all')[] = [
  'all',
  
  // Banking
  'bank',
  'credit_card',
  'upi',
  
  // Investments
  'brokerage',
  
  // Deposits & Savings
  'fixed_deposit',
  'recurring_deposit',
  'ppf',
  'nsc',
  'kvp',
  'scss',
  'post_office',
  
  // Cash & Wallets
  'cash',
  'wallet',
];
```

### Fix 2: Convert to Multi-Select Filter
Replace single-select filter with multi-select to allow viewing multiple types simultaneously.

### Fix 3: Add Deposit-Specific Display
Ensure deposit accounts show relevant information:
- Interest rate
- Maturity date
- Current value (with interest)

## Testing Steps

1. Create a Fixed Deposit account
2. Check if it appears in accounts list
3. Check if it appears in dashboard
4. Check if filter works correctly
5. Check if account details page works

## Verification Queries

```sql
-- Check if FD was created
SELECT * FROM accounts WHERE type = 'fixed_deposit';

-- Check if FD is active
SELECT * FROM accounts WHERE type = 'fixed_deposit' AND is_active = true;

-- Check all deposit types
SELECT type, COUNT(*) FROM accounts 
WHERE type IN ('fixed_deposit', 'recurring_deposit', 'ppf', 'nsc', 'kvp', 'scss', 'post_office')
GROUP BY type;
```

## Implementation Priority

1. ✅ **IMMEDIATE**: Add all account types to filter options
2. ✅ **HIGH**: Convert filter to multi-select
3. ✅ **MEDIUM**: Add deposit-specific display logic
4. ✅ **LOW**: Add deposit calculator and interest tracking

