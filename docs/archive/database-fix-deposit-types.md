# Database Schema Fix - Add Deposit Account Types

## The Problem

The database schema has a CHECK constraint that only allows 6 account types:
```sql
type TEXT NOT NULL CHECK (type IN ('bank', 'credit_card', 'upi', 'brokerage', 'cash', 'wallet'))
```

This is why creating Fixed Deposits fails with:
```
❌ Store: createAccount error: new row for relation "accounts" violates check constraint "accounts_type_check"
```

## The Fix

I've updated `/webapp/src/core/db/schema.ts` to include all deposit types, but **existing databases need to be migrated**.

## Solution Options

### Option 1: Clear Database (EASIEST - Loses All Data)

Run this in the browser console:

```javascript
// Import the database client
const { db } = await import('/src/core/db/client.js');

// Clear all data
await db.clearDatabase();

// Reload the page
location.reload();
```

This will recreate the database with the updated schema.

### Option 2: Migrate Existing Database (Preserves Data)

Run this in the browser console:

```javascript
// Import the database client
const { db } = await import('/src/core/db/client.js');

// Drop the old constraint
await db.query('ALTER TABLE accounts DROP CONSTRAINT accounts_type_check;');

// Add the new constraint with all types
await db.query(`
  ALTER TABLE accounts ADD CONSTRAINT accounts_type_check 
  CHECK (type IN (
    'bank', 
    'credit_card', 
    'upi', 
    'brokerage', 
    'cash', 
    'wallet',
    'fixed_deposit',
    'recurring_deposit',
    'ppf',
    'nsc',
    'kvp',
    'scss',
    'post_office'
  ))
`);

console.log('✅ Database migrated successfully!');

// Reload the page
location.reload();
```

This preserves your existing accounts and transactions.

### Option 3: Manual Migration Script

If Option 2 doesn't work (PGlite syntax differences), try:

```javascript
const { db } = await import('/src/core/db/client.js');

// Get current accounts
const result = await db.query('SELECT * FROM accounts');
console.log('Current accounts:', result.rows);

// Drop and recreate the table with new schema
await db.query('DROP TABLE IF EXISTS transactions CASCADE');
await db.query('DROP TABLE IF EXISTS accounts CASCADE');

// Recreate with new schema (will be done automatically on reload)
location.reload();
```

**WARNING**: This loses transactions but can be combined with backup/restore.

## Recommended Approach

**For Testing (No Important Data)**: Use Option 1 (Clear Database)

**For Production (Has Data)**: Use Option 2 (Migrate)

## After Migration

Once the database is fixed:

1. Hard refresh (Cmd+Shift+R)
2. Try creating a Fixed Deposit again
3. It should work now!

## Verification

After migration, verify the constraint was updated:

```javascript
const { db } = await import('/src/core/db/client.js');

const result = await db.query(`
  SELECT conname, pg_get_constraintdef(oid) as definition
  FROM pg_constraint
  WHERE conname = 'accounts_type_check'
`);

console.table(result.rows);
```

You should see all 13 account types in the constraint definition.

## Future Prevention

I've updated the schema file, so new databases will have the correct constraint from the start. For existing users, we'll need to implement proper migrations when we add the migration system.

