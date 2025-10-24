# Zod Validation and Error Codes Migration Guide

## Overview
This guide documents the implementation of Zod schema validation and structured error codes across all 48 Cloud Functions in the WealthWise application.

## Architecture Components

### 1. Error Codes System (`functions/src/errors.ts`)
- **ErrorCodes object**: 60+ i18n-ready error codes organized by entity
- **AppError class**: Custom error with code, message, statusCode, and details
- **Helper functions**: `validationError()`, `notFoundError()`, `permissionError()`, `authError()`
- **ErrorMessages**: English fallback messages for all error codes

### 2. Zod Schemas (`functions/src/schemas.ts`)
- **Common schemas**: dateSchema, currencySchema, uuidSchema
- **Entity schemas**: Account, Transaction, Budget, Goal, etc.
- **Validation helpers**: `validateSchema<T>()`, `safeValidate<T>()`
- **Type inference**: TypeScript types automatically generated from Zod schemas

## Migration Pattern

### Before (Old Pattern)
```typescript
export const createGoal = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Manual validation
  if (!request.data.name || !request.data.target_amount) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    // Business logic
    const goalRef = db.collection('goals').doc();
    await goalRef.set({ ...request.data });
    return { id: goalRef.id };
  } catch (error: any) {
    throw new functions.https.HttpsError('internal', 'Failed to create goal', error.message);
  }
});
```

### After (New Pattern)
```typescript
import {
  createGoalSchema,
  safeValidate,
} from './schemas';
import {
  AppError,
  ErrorCodes,
  validationError,
  notFoundError,
  authError,
  permissionError,
} from './errors';

export const createGoal = functions.https.onCall(async (request) => {
  // 1. Authentication check with error code
  if (!request.auth) {
    throw authError(ErrorCodes.AUTH_UNAUTHENTICATED);
  }

  const userId = request.auth.uid;
  
  // 2. Zod validation with structured error
  const validation = safeValidate(createGoalSchema, request.data);
  if (!validation.success) {
    throw validationError(ErrorCodes.VALIDATION_INVALID_FORMAT, undefined, {
      errors: validation.errors.issues,
    });
  }

  const goalData = validation.data;

  try {
    // 3. Business logic with validated data
    const goalRef = db.collection('goals').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const goal = {
      user_id: userId,
      name: goalData.name,
      target_amount: goalData.target_amount,
      current_amount: goalData.current_amount || 0,
      target_date: goalData.target_date ? admin.firestore.Timestamp.fromDate(new Date(goalData.target_date)) : null,
      priority: goalData.priority || 'medium',
      status: 'active',
      created_at: now,
      updated_at: now,
    };

    await goalRef.set(goal);

    return {
      id: goalRef.id,
      ...goal,
      created_at: new Date(),
      updated_at: new Date(),
    };
  } catch (error: any) {
    console.error('Error creating goal:', error);
    // 4. Re-throw AppError instances (from helper functions)
    if (error instanceof AppError) {
      throw error;
    }
    // 5. Wrap unexpected errors with entity-specific error code
    throw new AppError(
      ErrorCodes.GOAL_OPERATION_FAILED,
      'Failed to create goal',
      'internal',
      { originalError: error.message }
    );
  }
});
```

## Step-by-Step Migration Process

### Step 1: Add Imports
```typescript
// Add Zod schema imports
import {
  createGoalSchema,
  updateGoalSchema,
  safeValidate,
} from './schemas';

// Add error handling imports
import {
  AppError,
  ErrorCodes,
  validationError,
  notFoundError,
  authError,
  permissionError,
} from './errors';
```

### Step 2: Replace Authentication Errors
```typescript
// Before
if (!request.auth) {
  throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
}

// After
if (!request.auth) {
  throw authError(ErrorCodes.AUTH_UNAUTHENTICATED);
}
```

### Step 3: Replace Validation with Zod
```typescript
// Before (manual validation)
if (!request.data.name || !request.data.target_amount) {
  throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
}

// After (Zod validation)
const validation = safeValidate(createGoalSchema, request.data);
if (!validation.success) {
  throw validationError(ErrorCodes.VALIDATION_INVALID_FORMAT, undefined, {
    errors: validation.errors.issues,
  });
}

const goalData = validation.data; // Type-safe validated data
```

### Step 4: Replace Not Found Errors
```typescript
// Before
if (!doc.exists) {
  throw new functions.https.HttpsError('not-found', 'Goal not found');
}

// After
if (!doc.exists) {
  throw notFoundError(ErrorCodes.GOAL_NOT_FOUND, 'Goal');
}
```

### Step 5: Replace Permission Errors
```typescript
// Before
if (data.user_id !== userId) {
  throw new functions.https.HttpsError('permission-denied', 'Not authorized');
}

// After
if (data.user_id !== userId) {
  throw permissionError(ErrorCodes.AUTH_PERMISSION_DENIED);
}
```

### Step 6: Replace Generic Errors
```typescript
// Before
throw new functions.https.HttpsError('invalid-argument', 'Goal ID is required');

// After
throw validationError(ErrorCodes.VALIDATION_REQUIRED_FIELD, 'goalId');
```

### Step 7: Update Catch Blocks
```typescript
// Before
catch (error: any) {
  console.error('Error:', error);
  throw new functions.https.HttpsError('internal', 'Operation failed', error.message);
}

// After
catch (error: any) {
  console.error('Error:', error);
  // Re-throw AppError instances
  if (error instanceof AppError) {
    throw error;
  }
  // Wrap unexpected errors with entity-specific error code
  throw new AppError(
    ErrorCodes.GOAL_OPERATION_FAILED,
    'Failed to create goal',
    'internal',
    { originalError: error.message }
  );
}
```

## Error Code Mapping Reference

### Authentication Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'unauthenticated'` | `ErrorCodes.AUTH_UNAUTHENTICATED` |
| `'permission-denied'` | `ErrorCodes.AUTH_PERMISSION_DENIED` |
| `'invalid token'` | `ErrorCodes.AUTH_INVALID_TOKEN` |

### Validation Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'invalid-argument'` (generic) | `ErrorCodes.VALIDATION_INVALID_FORMAT` |
| `'missing field'` | `ErrorCodes.VALIDATION_REQUIRED_FIELD` |
| `'invalid type'` | `ErrorCodes.VALIDATION_INVALID_TYPE` |

### Entity-Specific Errors

#### Account Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'not-found'` (account) | `ErrorCodes.ACCOUNT_NOT_FOUND` |
| `'duplicate account'` | `ErrorCodes.ACCOUNT_DUPLICATE` |
| `'insufficient balance'` | `ErrorCodes.ACCOUNT_INSUFFICIENT_BALANCE` |

#### Goal Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'not-found'` (goal) | `ErrorCodes.GOAL_NOT_FOUND` |
| `'target already met'` | `ErrorCodes.GOAL_TARGET_MET` |
| `'invalid contribution'` | `ErrorCodes.GOAL_INVALID_CONTRIBUTION` |
| `'internal'` (goal operations) | `ErrorCodes.GOAL_OPERATION_FAILED` |

#### Transaction Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'not-found'` (transaction) | `ErrorCodes.TRANSACTION_NOT_FOUND` |
| `'invalid type'` | `ErrorCodes.TRANSACTION_INVALID_TYPE` |
| `'invalid amount'` | `ErrorCodes.TRANSACTION_INVALID_AMOUNT` |

#### Budget Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'not-found'` (budget) | `ErrorCodes.BUDGET_NOT_FOUND` |
| `'budget exceeded'` | `ErrorCodes.BUDGET_EXCEEDED` |
| `'invalid period'` | `ErrorCodes.BUDGET_INVALID_PERIOD` |

#### Import/Export Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'invalid format'` | `ErrorCodes.IMPORT_INVALID_FORMAT` |
| `'too many transactions'` | `ErrorCodes.IMPORT_TOO_MANY_TRANSACTIONS` |
| `'export failed'` | `ErrorCodes.EXPORT_FAILED` |

#### Investment Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'invalid symbol'` | `ErrorCodes.INVESTMENT_INVALID_SYMBOL` |
| `'data not available'` | `ErrorCodes.INVESTMENT_DATA_NOT_AVAILABLE` |
| `'API error'` | `ErrorCodes.INVESTMENT_API_ERROR` |

#### Dashboard Errors
| Old Error | New Error Code |
|-----------|---------------|
| `'computation failed'` | `ErrorCodes.DASHBOARD_COMPUTATION_FAILED` |
| `'cache error'` | `ErrorCodes.DASHBOARD_CACHE_ERROR` |

## Complete Error Codes List

### Authentication (AUTH_*)
```typescript
AUTH_UNAUTHENTICATED: 'auth.unauthenticated',
AUTH_PERMISSION_DENIED: 'auth.permission_denied',
AUTH_INVALID_TOKEN: 'auth.invalid_token',
AUTH_TOKEN_EXPIRED: 'auth.token_expired',
```

### Validation (VALIDATION_*)
```typescript
VALIDATION_INVALID_FORMAT: 'validation.invalid_format',
VALIDATION_REQUIRED_FIELD: 'validation.required_field',
VALIDATION_INVALID_TYPE: 'validation.invalid_type',
VALIDATION_OUT_OF_RANGE: 'validation.out_of_range',
```

### Account (ACCOUNT_*)
```typescript
ACCOUNT_NOT_FOUND: 'account.not_found',
ACCOUNT_ALREADY_EXISTS: 'account.already_exists',
ACCOUNT_DUPLICATE: 'account.duplicate',
ACCOUNT_INVALID_TYPE: 'account.invalid_type',
ACCOUNT_INSUFFICIENT_BALANCE: 'account.insufficient_balance',
ACCOUNT_OPERATION_FAILED: 'account.operation_failed',
```

### Transaction (TRANSACTION_*)
```typescript
TRANSACTION_NOT_FOUND: 'transaction.not_found',
TRANSACTION_INVALID_TYPE: 'transaction.invalid_type',
TRANSACTION_INVALID_AMOUNT: 'transaction.invalid_amount',
TRANSACTION_OPERATION_FAILED: 'transaction.operation_failed',
```

### Budget (BUDGET_*)
```typescript
BUDGET_NOT_FOUND: 'budget.not_found',
BUDGET_ALREADY_EXISTS: 'budget.already_exists',
BUDGET_EXCEEDED: 'budget.exceeded',
BUDGET_INVALID_PERIOD: 'budget.invalid_period',
BUDGET_OPERATION_FAILED: 'budget.operation_failed',
```

### Goal (GOAL_*)
```typescript
GOAL_NOT_FOUND: 'goal.not_found',
GOAL_ALREADY_EXISTS: 'goal.already_exists',
GOAL_TARGET_MET: 'goal.target_met',
GOAL_INVALID_CONTRIBUTION: 'goal.invalid_contribution',
GOAL_OPERATION_FAILED: 'goal.operation_failed',
```

### Import/Export (IMPORT_*, EXPORT_*)
```typescript
IMPORT_INVALID_FORMAT: 'import.invalid_format',
IMPORT_TOO_MANY_TRANSACTIONS: 'import.too_many_transactions',
IMPORT_OPERATION_FAILED: 'import.operation_failed',
EXPORT_FAILED: 'export.failed',
EXPORT_NO_DATA: 'export.no_data',
```

### Investment (INVESTMENT_*)
```typescript
INVESTMENT_INVALID_SYMBOL: 'investment.invalid_symbol',
INVESTMENT_DATA_NOT_AVAILABLE: 'investment.data_not_available',
INVESTMENT_API_ERROR: 'investment.api_error',
INVESTMENT_CACHE_ERROR: 'investment.cache_error',
```

### Dashboard (DASHBOARD_*)
```typescript
DASHBOARD_COMPUTATION_FAILED: 'dashboard.computation_failed',
DASHBOARD_CACHE_ERROR: 'dashboard.cache_error',
DASHBOARD_INVALID_REQUEST: 'dashboard.invalid_request',
```

### Report (REPORT_*)
```typescript
REPORT_GENERATION_FAILED: 'report.generation_failed',
REPORT_INVALID_TYPE: 'report.invalid_type',
REPORT_INVALID_DATE_RANGE: 'report.invalid_date_range',
```

### Deposit (DEPOSIT_*)
```typescript
DEPOSIT_INVALID_PRINCIPAL: 'deposit.invalid_principal',
DEPOSIT_INVALID_RATE: 'deposit.invalid_rate',
DEPOSIT_INVALID_TENURE: 'deposit.invalid_tenure',
DEPOSIT_CALCULATION_FAILED: 'deposit.calculation_failed',
```

### Duplicate Detection (DUPLICATE_*)
```typescript
DUPLICATE_FOUND: 'duplicate.found',
DUPLICATE_CHECK_FAILED: 'duplicate.check_failed',
```

### Generic (GENERIC_*)
```typescript
GENERIC_INTERNAL_ERROR: 'generic.internal_error',
GENERIC_NOT_FOUND: 'generic.not_found',
GENERIC_OPERATION_FAILED: 'generic.operation_failed',
```

## Helper Function Reference

### authError()
```typescript
// Usage
throw authError(ErrorCodes.AUTH_UNAUTHENTICATED);

// Definition
function authError(code: ErrorCode): AppError {
  return new AppError(code, 'Authentication failed', 'unauthenticated');
}
```

### validationError()
```typescript
// Usage 1: With field name
throw validationError(ErrorCodes.VALIDATION_REQUIRED_FIELD, 'goalId');

// Usage 2: With Zod errors
throw validationError(ErrorCodes.VALIDATION_INVALID_FORMAT, undefined, {
  errors: validation.errors.issues,
});

// Definition
function validationError(code: ErrorCode, field?: string, details?: any): AppError {
  const message = field ? `Validation failed for field: ${field}` : 'Validation failed';
  return new AppError(code, message, 'invalid-argument', { field, ...details });
}
```

### notFoundError()
```typescript
// Usage
throw notFoundError(ErrorCodes.GOAL_NOT_FOUND, 'Goal');

// Definition
function notFoundError(code: ErrorCode, resource: string): AppError {
  return new AppError(code, `${resource} not found`, 'not-found');
}
```

### permissionError()
```typescript
// Usage
throw permissionError(ErrorCodes.AUTH_PERMISSION_DENIED);

// Definition
function permissionError(code: ErrorCode): AppError {
  return new AppError(code, 'Permission denied', 'permission-denied');
}
```

## Frontend Integration

### Error Handling in UI
```typescript
// Frontend API wrapper
import { ErrorCodes } from '@/core/errors';
import { useTranslation } from 'react-i18next';

async function createGoal(data: GoalData) {
  const { t } = useTranslation();
  
  try {
    const result = await httpsCallable(functions, 'createGoal')(data);
    return result.data;
  } catch (error: any) {
    const errorCode = error.details?.code || ErrorCodes.GENERIC_INTERNAL_ERROR;
    const translatedMessage = t(errorCode); // e.g., t('goal.not_found')
    throw new Error(translatedMessage);
  }
}
```

### Translation Files Structure
```json
// webapp/src/locales/en/errors.json
{
  "auth": {
    "unauthenticated": "You must be signed in to perform this action",
    "permission_denied": "You don't have permission to perform this action",
    "invalid_token": "Your session has expired. Please sign in again",
    "token_expired": "Your session has expired. Please sign in again"
  },
  "validation": {
    "invalid_format": "The provided data is invalid",
    "required_field": "This field is required",
    "invalid_type": "Invalid data type",
    "out_of_range": "Value is out of valid range"
  },
  "account": {
    "not_found": "Account not found",
    "already_exists": "Account already exists",
    "insufficient_balance": "Insufficient balance",
    "operation_failed": "Account operation failed"
  },
  "goal": {
    "not_found": "Goal not found",
    "target_met": "Goal target has already been met",
    "invalid_contribution": "Invalid contribution amount",
    "operation_failed": "Failed to perform goal operation"
  }
  // ... more translations
}
```

## Testing with Error Codes

### Unit Test Example
```typescript
import { createGoal } from '../src/goals';
import { ErrorCodes } from '../src/errors';

describe('createGoal', () => {
  it('should throw AUTH_UNAUTHENTICATED when user is not authenticated', async () => {
    const request = {
      auth: null,
      data: { name: 'Test Goal', target_amount: 10000 },
    };

    try {
      await createGoal(request);
      fail('Should have thrown error');
    } catch (error: any) {
      expect(error.code).toBe(ErrorCodes.AUTH_UNAUTHENTICATED);
      expect(error.httpStatusCode).toBe('unauthenticated');
    }
  });

  it('should throw VALIDATION_INVALID_FORMAT for missing required fields', async () => {
    const request = {
      auth: { uid: 'user123' },
      data: { name: 'Test Goal' }, // Missing target_amount
    };

    try {
      await createGoal(request);
      fail('Should have thrown error');
    } catch (error: any) {
      expect(error.code).toBe(ErrorCodes.VALIDATION_INVALID_FORMAT);
      expect(error.httpStatusCode).toBe('invalid-argument');
      expect(error.details.errors).toBeDefined();
    }
  });
});
```

## Migration Progress Tracker

### Phase 1: Core Functions (In Progress)
- [x] goals.ts - createGoal (completed)
- [ ] goals.ts - updateGoal, deleteGoal, getGoal, addGoalContribution
- [ ] import.ts - All functions (need validation + error codes)
- [ ] dashboard.ts - All functions (need validation + error codes)
- [ ] investments.ts - All functions (need validation + error codes)

### Phase 2: Existing Functions
- [ ] accounts.ts - All CRUD operations
- [ ] transactions.ts - All CRUD operations
- [ ] budgets.ts - All CRUD operations
- [ ] reports.ts - All report generation functions
- [ ] deposits.ts - All calculation functions
- [ ] duplicates.ts - All duplicate detection functions
- [ ] dataExport.ts - All export functions
- [ ] pubsub.ts - All scheduled functions

### Phase 3: Testing & Documentation
- [ ] Update all unit tests to verify error codes
- [ ] Create frontend error translation files
- [ ] Update API documentation with error codes
- [ ] Add error code reference to developer docs

## Benefits of Migration

### 1. Type Safety
- Zod schemas provide compile-time type checking
- Auto-generated TypeScript types from schemas
- Reduces runtime type errors

### 2. I18n-Ready Errors
- Error codes map directly to translation keys
- Consistent error messages across UI
- Support for multiple languages

### 3. Structured Error Handling
- Consistent error format across all functions
- Rich error details for debugging
- Better error tracking and monitoring

### 4. Improved Developer Experience
- Clear validation rules in schemas
- Reusable error helper functions
- Better error messages during development

### 5. Better User Experience
- Specific, actionable error messages
- Localized error text
- Consistent error handling patterns

## Next Steps

1. **Complete goals.ts migration** - Update remaining 4 functions
2. **Migrate import.ts** - Add validation and error codes to 4 functions
3. **Migrate dashboard.ts** - Add validation and error codes to 4 functions
4. **Migrate investments.ts** - Add validation and error codes to 6 functions
5. **Create frontend translation files** - en/errors.json, hi/errors.json
6. **Update existing functions** - Migrate remaining 29 functions
7. **Add comprehensive testing** - Test validation and error codes
8. **Update documentation** - API docs with error codes reference

## References

- **Error Codes**: `functions/src/errors.ts`
- **Zod Schemas**: `functions/src/schemas.ts`
- **Example Migration**: `functions/src/goals.ts` - createGoal function
- **Cloud Functions**: All 48 functions in `functions/src/`
