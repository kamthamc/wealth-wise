# Cloud Functions Integration Status

## Overview
The Swift app has been refactored to use Firebase Cloud Functions exclusively for all database operations. This document tracks which Cloud Functions exist and which need to be created.

## Architecture

```
Swift App → FirebaseService → Cloud Functions → Firestore
          ↓
    SwiftData (Local Cache)
```

All database operations flow through Cloud Functions in the `asia-south1` region.

## Cloud Functions Status

### ✅ Existing Functions (From webapp)

These functions already exist in `packages/functions/src/index.ts`:

1. **createOrUpdateBudget** - Create/update budget
2. **createOrUpdateGoal** - Create/update goal  
3. **generateBudgetReport** - Get budget analysis with spending breakdown
4. **calculateBalances** - Calculate account balances
5. **bulkDeleteTransactions** - Batch delete transactions
6. **exportTransactions** - Export transactions to CSV

### ❌ Missing Functions (Need to be created)

These functions are called by the Swift app but don't exist yet:

#### Account Operations
- **getAccounts** - Fetch all accounts for user
  ```typescript
  // Request: {}
  // Response: { accounts: AccountData[] }
  ```
- **createAccount** - Create new account
  ```typescript
  // Request: { name, type, currentBalance, currency }
  // Response: { account: AccountData }
  ```
- **updateAccount** - Update existing account
  ```typescript
  // Request: { accountId, name?, type?, currentBalance?, currency?, isArchived? }
  // Response: { account: AccountData }
  ```
- **deleteAccount** - Delete account
  ```typescript
  // Request: { accountId }
  // Response: { success: true }
  ```

#### Transaction Operations
- **getTransactions** - Fetch transactions with filters
  ```typescript
  // Request: { accountId?, startDate?, endDate?, category? }
  // Response: { transactions: TransactionData[] }
  ```
- **createTransaction** - Create new transaction
  ```typescript
  // Request: { accountId, date, amount, type, category, description, notes? }
  // Response: { transaction: TransactionData }
  ```
- **updateTransaction** - Update existing transaction
  ```typescript
  // Request: { transactionId, updates: {} }
  // Response: { transaction: TransactionData }
  ```
- **deleteTransaction** - Delete single transaction
  ```typescript
  // Request: { transactionId }
  // Response: { success: true }
  ```

#### Budget Operations
- **getBudgets** - Fetch all budgets for user
  ```typescript
  // Request: {}
  // Response: { budgets: BudgetData[] }
  ```
- **deleteBudget** - Delete budget
  ```typescript
  // Request: { budgetId }
  // Response: { success: true }
  ```

#### Goal Operations
- **getGoals** - Fetch all goals for user
  ```typescript
  // Request: {}
  // Response: { goals: GoalData[] }
  ```
- **addGoalContribution** - Add contribution to goal
  ```typescript
  // Request: { goalId, amount, date, note? }
  // Response: { goal: GoalData }
  ```
- **deleteGoal** - Delete goal
  ```typescript
  // Request: { goalId }
  // Response: { success: true }
  ```

## Implementation Priority

### Phase 1: Core CRUD (Highest Priority)
1. **getAccounts**, **createAccount**, **updateAccount**, **deleteAccount**
2. **getTransactions**, **createTransaction**, **updateTransaction**, **deleteTransaction**

These are essential for basic app functionality.

### Phase 2: Budget & Goal Management
1. **getBudgets**, **deleteBudget**
2. **getGoals**, **addGoalContribution**, **deleteGoal**

Leverage existing createOrUpdateBudget and createOrUpdateGoal functions.

## Swift Implementation Status

### ✅ Completed
- [x] FirebaseService refactored to use Cloud Functions
- [x] All CRUD operations converted (accounts, transactions, budgets, goals)
- [x] Generic `callFunction<Request, Response>` helper method
- [x] DTO models created (AccountDTO, TransactionDTO, BudgetDTO, GoalDTO)
- [x] AccountRepository using Cloud Functions architecture

### ⏳ Pending
- [ ] Install Firebase SDK via Xcode SPM
- [ ] Add GoogleService-Info.plist
- [ ] Create missing Cloud Functions (backend work)
- [ ] Create TransactionRepository
- [ ] Create BudgetRepository  
- [ ] Create GoalRepository
- [ ] Build authentication UI
- [ ] Test end-to-end flow

## Cloud Function Creation Guide

### Location
Add new functions to `packages/functions/src/index.ts`

### Template
```typescript
export const getFunctionName = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    
    const userId = context.auth.uid;
    
    // Validate input
    const { param1, param2 } = data;
    
    // Perform Firestore operations
    const result = await admin.firestore()
      .collection('collection')
      .where('userId', '==', userId)
      .get();
    
    // Return response matching Swift DTO
    return {
      data: result.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }))
    };
  });
```

### Security Considerations
- Always verify `context.auth` exists
- Always filter by `userId` from `context.auth.uid`
- Validate all input parameters
- Use Firestore security rules as second layer of defense
- Return consistent error codes for Swift error handling

## Testing Checklist

Once Cloud Functions are deployed:

1. Test authentication flow
2. Test account CRUD operations
3. Test transaction CRUD operations  
4. Test budget operations (create, update, delete, report)
5. Test goal operations (create, update, contribution, delete)
6. Test offline sync behavior
7. Test error handling and retry logic
8. Verify data consistency between Swift and webapp

## Next Steps

1. **Backend Team**: Create missing Cloud Functions
2. **iOS Team**: 
   - Install Firebase SDK
   - Test with existing Cloud Functions (budgets, goals)
   - Build remaining repositories once Cloud Functions are deployed
3. **Testing**: End-to-end integration testing

## Notes

- All Cloud Functions must use `asia-south1` region
- Date formats: ISO8601 strings for API, Date objects in Swift
- Currency: Double for API, Decimal for Swift calculations
- All responses should include success/error indicators
- Consider rate limiting and quota management for Cloud Functions
