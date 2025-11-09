# TanStack Query Integration Guide

## Overview

This guide explains how to use TanStack Query (React Query) for data fetching and state management in the WealthWise web application.

## Table of Contents

1. [Why TanStack Query?](#why-tanstack-query)
2. [Basic Concepts](#basic-concepts)
3. [Using Query Hooks](#using-query-hooks)
4. [Using Mutation Hooks](#using-mutation-hooks)
5. [Best Practices](#best-practices)
6. [Available Hooks](#available-hooks)
7. [Debugging](#debugging)

---

## Why TanStack Query?

TanStack Query replaces manual data fetching and caching logic with a declarative, powerful API. Benefits include:

- **Automatic Caching**: Data is cached and reused across components
- **Background Refetching**: Data stays fresh without manual intervention
- **Optimistic Updates**: Update UI immediately, rollback on failure
- **Loading & Error States**: Built-in state management for async operations
- **Request Deduplication**: Multiple components requesting same data = single network request
- **Stale-While-Revalidate**: Show cached data immediately, fetch fresh data in background

---

## Basic Concepts

### Queries

Queries are for **fetching data** (GET operations). Use `useQuery` hooks.

```typescript
const { data, isLoading, error, refetch } = useAccounts();
```

### Mutations

Mutations are for **modifying data** (POST, PUT, DELETE operations). Use `useMutation` hooks.

```typescript
const createAccount = useCreateAccount();
await createAccount.mutateAsync(accountData);
```

### Query Keys

Query keys identify queries for caching. They're arrays that can include parameters:

```typescript
['accounts']                    // All accounts
['accounts', accountId]         // Specific account
['transactions', { filters }]   // Transactions with filters
```

---

## Using Query Hooks

### Example: Fetching Accounts

**Before (Manual State Management):**

```typescript
const { accounts, isLoading, fetchAccounts } = useAccountStore();

useEffect(() => {
  fetchAccounts();
}, []);

// accounts may be stale
// need to manually call fetchAccounts() after mutations
```

**After (TanStack Query):**

```typescript
const { data: accounts = [], isLoading, error } = useAccounts();

// That's it! Data is fetched, cached, and automatically refetched
// No useEffect needed
// No manual refetch calls needed after mutations
```

### Handling States

```typescript
const { data, isLoading, error, isFetching, isRefetching } = useAccounts();

if (isLoading) {
  return <LoadingSpinner />;
}

if (error) {
  return <ErrorMessage error={error} />;
}

return (
  <div>
    {isFetching && <RefreshIndicator />}
    <AccountsList accounts={data} />
  </div>
);
```

### Filtering Data

```typescript
const filters = { accountId: '123', type: 'debit' };
const { data: transactions } = useTransactions(filters);

// Changing filters automatically triggers a new query
```

---

## Using Mutation Hooks

### Example: Creating an Account

**Before:**

```typescript
const handleCreate = async (data) => {
  await createAccount(data);
  await fetchAccounts(); // Manual refetch
};
```

**After:**

```typescript
const createAccountMutation = useCreateAccount();

const handleCreate = async (data) => {
  await createAccountMutation.mutateAsync(data);
  // Accounts are automatically refetched!
};
```

### Handling Mutation States

```typescript
const createAccount = useCreateAccount();

const handleSubmit = async (data) => {
  try {
    await createAccount.mutateAsync(data);
    toast.success('Account created!');
    closeModal();
  } catch (error) {
    toast.error('Failed to create account');
  }
};

return (
  <form onSubmit={handleSubmit}>
    <input {...fields} />
    <button disabled={createAccount.isPending}>
      {createAccount.isPending ? 'Creating...' : 'Create Account'}
    </button>
  </form>
);
```

### Optimistic Updates (Advanced)

```typescript
const updateAccount = useUpdateAccount();

const handleUpdate = () => {
  updateAccount.mutate(
    { id, data },
    {
      // Optimistically update the UI
      onMutate: async (newAccount) => {
        // Cancel outgoing refetches
        await queryClient.cancelQueries({ queryKey: ['accounts'] });
        
        // Snapshot the previous value
        const previousAccounts = queryClient.getQueryData(['accounts']);
        
        // Optimistically update
        queryClient.setQueryData(['accounts'], (old) => {
          return old.map(acc => acc.id === id ? { ...acc, ...data } : acc);
        });
        
        // Return context with snapshot
        return { previousAccounts };
      },
      // Rollback on error
      onError: (err, newAccount, context) => {
        queryClient.setQueryData(['accounts'], context.previousAccounts);
      },
    }
  );
};
```

---

## Best Practices

### 1. Use Default Values

Always provide a default value to prevent undefined errors:

```typescript
const { data: accounts = [] } = useAccounts();
```

### 2. Handle Loading and Error States

```typescript
if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorMessage error={error} />;
```

### 3. Use Mutation Callbacks

```typescript
const mutation = useCreateAccount();

mutation.mutate(data, {
  onSuccess: () => {
    toast.success('Success!');
    navigate('/accounts');
  },
  onError: (error) => {
    toast.error(error.message);
  },
});
```

### 4. Avoid Overusing `refetch()`

TanStack Query handles refetching automatically. Manual `refetch()` is rarely needed.

### 5. Use Proper Query Keys

Make query keys descriptive and consistent:

```typescript
// Good
['transactions', { accountId, startDate, endDate }]

// Bad
['data']
```

---

## Available Hooks

### Accounts

**Queries:**
- `useAccounts()` - Fetch all accounts

**Mutations:**
- `useCreateAccount()` - Create a new account
- `useUpdateAccount()` - Update an existing account
- `useDeleteAccount()` - Delete an account
- `useTransferBetweenAccounts()` - Transfer money between accounts

### Transactions

**Queries:**
- `useTransactions(filters?)` - Fetch transactions with optional filters
- `useTransaction(id)` - Fetch a single transaction

**Mutations:**
- `useCreateTransaction()` - Create a new transaction
- `useUpdateTransaction()` - Update a transaction
- `useDeleteTransaction()` - Delete a transaction
- `useBulkDeleteTransactions()` - Delete multiple transactions
- `useImportTransactions()` - Import transactions from CSV

### Budgets

**Queries:**
- `useBudgets()` - Fetch all budgets
- `useBudget(id)` - Fetch a single budget

**Mutations:**
- `useCreateBudget()` - Create a new budget
- `useUpdateBudget()` - Update a budget
- `useDeleteBudget()` - Delete a budget

### Goals

**Queries:**
- `useGoals()` - Fetch all goals
- `useGoal(id)` - Fetch a single goal

**Mutations:**
- `useCreateGoal()` - Create a new goal
- `useUpdateGoal()` - Update a goal
- `useDeleteGoal()` - Delete a goal
- `useContributeToGoal()` - Make a contribution to a goal

---

## Debugging

### React Query DevTools

The DevTools are automatically enabled in development mode. Look for the TanStack Query icon in the bottom-left corner of your screen.

Features:
- **Query Inspector**: See all active queries, their states, and cached data
- **Mutation Inspector**: Track mutation history and states
- **Cache Explorer**: Inspect and manually modify the query cache
- **Query Invalidation**: Manually invalidate queries to trigger refetches
- **Network Simulation**: Simulate slow networks or errors

### Logging

All hooks include console.log statements (in mock implementations) to help you understand when queries and mutations are triggered.

### Common Issues

**Issue: Data is undefined**
- Solution: Use default values: `const { data = [] } = useQuery(...)`

**Issue: Query not refetching after mutation**
- Solution: Ensure mutation's `onSuccess` calls `queryClient.invalidateQueries()`

**Issue: Multiple refetches happening**
- Solution: Check if multiple components are using the same hook. This is normal! TanStack Query deduplicates requests.

---

## Migration Checklist

When refactoring a component to use TanStack Query:

- [ ] Replace `useXXXStore()` data fetching with `useXXX()` query hook
- [ ] Replace create/update/delete store methods with mutation hooks
- [ ] Remove `useEffect` hooks that call `fetchXXX()`
- [ ] Remove manual `refetch()` calls after mutations
- [ ] Add loading and error state handling
- [ ] Test that automatic refetching works after mutations

---

## Additional Resources

- [TanStack Query Docs](https://tanstack.com/query/latest/docs/react/overview)
- [TanStack Query Examples](https://tanstack.com/query/latest/docs/react/examples/react/simple)
- [Query Keys Best Practices](https://tanstack.com/query/latest/docs/react/guides/query-keys)

---

**Last Updated:** November 9, 2025
