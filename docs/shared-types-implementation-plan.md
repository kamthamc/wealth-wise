# Shared Types Implementation Plan for Cloud Functions & UI

## 🎯 Goal
Ensure **100% type safety** between Cloud Functions and UI by sharing exact types and payloads, eliminating runtime errors from type mismatches.

## 📊 Current State Analysis

### ✅ What's Working
1. **Monorepo Structure**: Using pnpm workspaces with `packages/functions` and `packages/webapp`
2. **Zod Schemas**: Comprehensive validation schemas in `packages/functions/src/schemas.ts`
3. **Type Inference**: Already exporting some types via `z.infer<typeof schema>`
4. **Firebase Functions**: 48+ Cloud Functions with Zod validation

### ❌ Current Problems
1. **Duplicate Type Definitions**: Types defined separately in functions and webapp
2. **Manual Type Sync**: No automatic synchronization between function signatures and UI calls
3. **Runtime Type Mismatches**: UI can call functions with wrong payload shapes
4. **No Type Safety for Responses**: Response types are manually typed in webapp
5. **Maintenance Overhead**: Changes to functions require manual updates in multiple places

### 📋 Example of Current Duplication

**Functions Side** (`packages/functions/src/schemas.ts`):
```typescript
export const createGoalSchema = z.object({
  name: z.string().min(1).max(100),
  target_amount: currencySchema,
  current_amount: currencySchema.optional().default(0),
  target_date: dateSchema.optional(),
  priority: goalPrioritySchema.optional().default('medium'),
  category: z.string().max(50).optional(),
  description: z.string().max(500).optional(),
});
```

**Webapp Side** (`packages/webapp/src/core/api/goalsApi.ts`):
```typescript
// DUPLICATE TYPE DEFINITION - manually maintained!
export async function createGoal(goalData: {
  name: string;
  target_amount: number;
  current_amount?: number;
  target_date?: string;
  priority?: 'low' | 'medium' | 'high';
  category?: string;
  description?: string;
}): Promise<Goal> {
  // ...
}
```

## 🏗️ Proposed Solution Architecture

### Option A: Shared Types Package (Recommended)
Create a new package `@wealthwise/shared-types` that both functions and webapp depend on.

```
packages/
  ├── shared-types/        # NEW - Shared types package
  │   ├── package.json
  │   ├── tsconfig.json
  │   ├── src/
  │   │   ├── index.ts              # Main export
  │   │   ├── schemas.ts            # Zod schemas (moved from functions)
  │   │   ├── types.ts              # Generated TypeScript types
  │   │   ├── functions.ts          # Function signatures
  │   │   └── constants.ts          # Shared constants
  ├── functions/
  │   └── src/
  │       ├── goals.ts              # Import from @wealthwise/shared-types
  │       └── ...
  └── webapp/
      └── src/
          └── core/api/
              └── goalsApi.ts       # Import from @wealthwise/shared-types
```

### Option B: Export Types from Functions (Simpler)
Export types directly from functions package and import in webapp.

```typescript
// packages/functions/src/types/index.ts
export * from './schemas';
export * from './function-types';

// packages/webapp/src/core/api/goalsApi.ts
import type { CreateGoalInput, CreateGoalOutput } from '@wealthwise/functions/types';
```

## 📝 Detailed Implementation Plan

### Phase 1: Create Shared Types Package (Week 1)

#### Step 1.1: Create Package Structure
```bash
mkdir -p packages/shared-types/src
cd packages/shared-types
pnpm init
```

#### Step 1.2: Configure Package
**`packages/shared-types/package.json`**:
```json
{
  "name": "@wealthwise/shared-types",
  "version": "1.0.0",
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    },
    "./schemas": {
      "types": "./dist/schemas.d.ts",
      "import": "./dist/schemas.js"
    },
    "./types": {
      "types": "./dist/types.d.ts",
      "import": "./dist/types.js"
    },
    "./functions": {
      "types": "./dist/functions.d.ts",
      "import": "./dist/functions.js"
    }
  },
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "lint": "biome check .",
    "format": "biome format --write ."
  },
  "dependencies": {
    "zod": "^3.24.1"
  },
  "devDependencies": {
    "typescript": "catalog:"
  }
}
```

#### Step 1.3: Move Schemas to Shared Package
**`packages/shared-types/src/schemas.ts`**:
```typescript
import { z } from 'zod';

// Move all schemas from packages/functions/src/schemas.ts
export const dateSchema = z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/));
export const currencySchema = z.number().nonnegative();
export const uuidSchema = z.uuidv4();

// Account schemas
export const createAccountSchema = z.object({
  name: z.string().min(1).max(100),
  type: z.enum([
    'savings', 'checking', 'credit_card', 'investment',
    'brokerage', 'mutual_fund', 'loan', 'mortgage',
    'fixed_deposit', 'recurring_deposit', 'ppf', 'nps', 'epf',
    'cash', 'other'
  ]),
  balance: currencySchema.optional(),
  initial_balance: currencySchema.optional(),
  currency: z.string().length(3).default('INR'),
  institution: z.string().max(100).optional(),
  account_number: z.string().max(50).optional(),
  notes: z.string().max(500).optional(),
});

export const updateAccountSchema = createAccountSchema.partial();

// Goal schemas
export const createGoalSchema = z.object({
  name: z.string().min(1).max(100),
  target_amount: currencySchema,
  current_amount: currencySchema.optional().default(0),
  target_date: dateSchema.optional(),
  priority: z.enum(['low', 'medium', 'high']).optional().default('medium'),
  category: z.string().max(50).optional(),
  description: z.string().max(500).optional(),
});

export const updateGoalSchema = z.object({
  goalId: uuidSchema,
  updates: z.object({
    name: z.string().min(1).max(100).optional(),
    target_amount: currencySchema.optional(),
    current_amount: currencySchema.optional(),
    target_date: dateSchema.optional(),
    priority: z.enum(['low', 'medium', 'high']).optional(),
    category: z.string().max(50).optional(),
    description: z.string().max(500).optional(),
    status: z.enum(['active', 'completed', 'paused', 'cancelled']).optional(),
  }),
});

// Transaction schemas
export const createTransactionSchema = z.object({
  accountId: uuidSchema,
  date: dateSchema,
  description: z.string().min(1).max(200),
  amount: currencySchema,
  type: z.enum(['income', 'expense', 'transfer']),
  category: z.string().max(50).optional(),
  notes: z.string().max(500).optional(),
  tags: z.array(z.string().max(30)).optional(),
});

// Budget schemas
export const createBudgetSchema = z.object({
  name: z.string().min(1).max(100),
  amount: currencySchema,
  period: z.enum(['daily', 'weekly', 'monthly', 'yearly']),
  category: z.string().max(50).optional(),
  start_date: dateSchema,
  end_date: dateSchema,
  is_active: z.boolean().default(true),
  alert_threshold: z.number().min(0).max(100).optional(),
});

// Import/Export schemas
export const importTransactionsSchema = z.object({
  transactions: z.array(z.object({
    date: dateSchema,
    description: z.string().min(1).max(200),
    amount: z.number(),
    type: z.enum(['income', 'expense', 'transfer']),
    category: z.string().max(50).optional(),
    notes: z.string().max(500).optional(),
    import_transaction_id: z.string().optional(),
  })).min(1).max(5000),
  accountId: uuidSchema,
  detectDuplicates: z.boolean().optional().default(true),
});

// Dashboard schemas
export const computeAndCacheDashboardSchema = z.object({
  forceRefresh: z.boolean().optional().default(false),
  cacheTTL: z.number().min(60).max(3600).optional().default(300),
});

// Investment schemas
export const fetchStockDataSchema = z.object({
  symbol: z.string().min(1).max(10).regex(/^[A-Z0-9.]+$/),
  forceRefresh: z.boolean().optional().default(false),
});

// Report schemas
export const generateReportSchema = z.object({
  reportType: z.enum([
    'income_expense',
    'category_breakdown',
    'account_summary',
    'budget_performance',
    'goal_progress',
    'net_worth',
  ]),
  startDate: dateSchema.optional(),
  endDate: dateSchema.optional(),
  accountIds: z.array(uuidSchema).optional(),
  includeCharts: z.boolean().optional().default(true),
});

// Add all other schemas...
```

#### Step 1.4: Generate TypeScript Types
**`packages/shared-types/src/types.ts`**:
```typescript
import { z } from 'zod';
import * as schemas from './schemas';

// Input types (inferred from Zod schemas)
export type CreateAccountInput = z.infer<typeof schemas.createAccountSchema>;
export type UpdateAccountInput = z.infer<typeof schemas.updateAccountSchema>;
export type CreateGoalInput = z.infer<typeof schemas.createGoalSchema>;
export type UpdateGoalInput = z.infer<typeof schemas.updateGoalSchema>;
export type CreateTransactionInput = z.infer<typeof schemas.createTransactionSchema>;
export type UpdateTransactionInput = z.infer<typeof schemas.updateTransactionSchema>;
export type CreateBudgetInput = z.infer<typeof schemas.createBudgetSchema>;
export type UpdateBudgetInput = z.infer<typeof schemas.updateBudgetSchema>;
export type ImportTransactionsInput = z.infer<typeof schemas.importTransactionsSchema>;
export type ComputeDashboardInput = z.infer<typeof schemas.computeAndCacheDashboardSchema>;
export type FetchStockDataInput = z.infer<typeof schemas.fetchStockDataSchema>;
export type GenerateReportInput = z.infer<typeof schemas.generateReportSchema>;

// Output types (Cloud Function responses)
export interface Account {
  id: string;
  user_id: string;
  name: string;
  type: string;
  balance: number;
  initial_balance: number;
  currency: string;
  institution?: string;
  account_number?: string;
  notes?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Goal {
  id: string;
  user_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: string;
  priority: 'low' | 'medium' | 'high';
  category?: string;
  description?: string;
  status: 'active' | 'completed' | 'paused' | 'cancelled';
  created_at: string;
  updated_at: string;
}

export interface Transaction {
  id: string;
  user_id: string;
  account_id: string;
  date: string;
  description: string;
  amount: number;
  type: 'income' | 'expense' | 'transfer';
  category?: string;
  notes?: string;
  tags?: string[];
  created_at: string;
  updated_at: string;
}

export interface Budget {
  id: string;
  user_id: string;
  name: string;
  amount: number;
  period: 'daily' | 'weekly' | 'monthly' | 'yearly';
  category?: string;
  start_date: string;
  end_date: string;
  is_active: boolean;
  alert_threshold?: number;
  created_at: string;
  updated_at: string;
}

// Operation result types
export interface CreateAccountOutput {
  success: boolean;
  accountId: string;
  message: string;
}

export interface CreateGoalOutput extends Goal {}

export interface ImportTransactionsOutput {
  total: number;
  imported: number;
  skipped: number;
  duplicates: string[];
  errors: string[];
  importReference: string;
  accountId: string;
}

export interface DashboardData {
  totalBalance: number;
  monthlyIncome: number;
  monthlyExpenses: number;
  budgetUtilization: number;
  activeGoals: number;
  recentTransactions: Transaction[];
  accountSummaries: Array<{
    accountId: string;
    name: string;
    balance: number;
    type: string;
  }>;
  categoryBreakdown: Array<{
    category: string;
    amount: number;
    percentage: number;
  }>;
  cachedAt: string;
}

export interface StockData {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  marketCap: number;
  lastUpdated: string;
}

export interface ReportData {
  reportType: string;
  generatedAt: string;
  startDate?: string;
  endDate?: string;
  data: any; // Specific to report type
  charts?: any[]; // Chart data if requested
}
```

#### Step 1.5: Define Function Signatures
**`packages/shared-types/src/functions.ts`**:
```typescript
import type * as schemas from './schemas';
import type * as types from './types';

/**
 * Type-safe Cloud Function signatures
 * Maps function names to their input/output types
 */
export interface CloudFunctions {
  // Account functions
  createAccount: {
    input: types.CreateAccountInput;
    output: types.CreateAccountOutput;
  };
  updateAccount: {
    input: { accountId: string; updates: types.UpdateAccountInput };
    output: { success: boolean; message: string };
  };
  deleteAccount: {
    input: { accountId: string };
    output: { success: boolean; message: string };
  };
  calculateAccountBalance: {
    input: { accountId: string; asOfDate?: string };
    output: { accountId: string; balance: number; calculatedAt: string };
  };

  // Goal functions
  createGoal: {
    input: types.CreateGoalInput;
    output: types.CreateGoalOutput;
  };
  updateGoal: {
    input: types.UpdateGoalInput;
    output: types.Goal;
  };
  deleteGoal: {
    input: { goalId: string };
    output: { success: boolean; message: string };
  };
  getGoal: {
    input: { goalId: string };
    output: types.Goal;
  };
  addGoalContribution: {
    input: { goalId: string; amount: number; date?: string; notes?: string };
    output: types.Goal;
  };

  // Transaction functions
  createTransaction: {
    input: types.CreateTransactionInput;
    output: { success: boolean; transactionId: string };
  };
  updateTransaction: {
    input: { transactionId: string; updates: types.UpdateTransactionInput };
    output: { success: boolean; message: string };
  };
  deleteTransaction: {
    input: { transactionId: string };
    output: { success: boolean; message: string };
  };
  getTransactionStats: {
    input: { accountId: string; startDate?: string; endDate?: string };
    output: {
      totalIncome: number;
      totalExpenses: number;
      netAmount: number;
      transactionCount: number;
      categoryBreakdown: Array<{ category: string; amount: number }>;
    };
  };

  // Budget functions
  createBudget: {
    input: types.CreateBudgetInput;
    output: { success: boolean; budgetId: string };
  };
  updateBudget: {
    input: { budgetId: string; updates: types.UpdateBudgetInput };
    output: { success: boolean; message: string };
  };
  deleteBudget: {
    input: { budgetId: string };
    output: { success: boolean; message: string };
  };
  calculateBudgetProgress: {
    input: { budgetId: string };
    output: {
      budgetId: string;
      spent: number;
      remaining: number;
      percentage: number;
      isOverBudget: boolean;
    };
  };

  // Import/Export functions
  importTransactions: {
    input: types.ImportTransactionsInput;
    output: types.ImportTransactionsOutput;
  };
  batchImportTransactions: {
    input: types.ImportTransactionsInput & { chunkSize?: number };
    output: types.ImportTransactionsOutput;
  };
  exportTransactions: {
    input: { accountId?: string; startDate?: string; endDate?: string; format?: 'json' | 'csv' };
    output: { url: string; expiresAt: string; format: string };
  };

  // Dashboard functions
  computeAndCacheDashboard: {
    input: types.ComputeDashboardInput;
    output: types.DashboardData;
  };
  getAccountSummary: {
    input: { accountId: string };
    output: {
      account: types.Account;
      balance: number;
      recentTransactions: types.Transaction[];
      monthlyTrend: Array<{ month: string; balance: number }>;
    };
  };

  // Investment functions
  fetchStockData: {
    input: types.FetchStockDataInput;
    output: types.StockData;
  };
  fetchStockHistory: {
    input: { symbol: string; interval?: 'daily' | 'weekly' | 'monthly'; outputSize?: 'compact' | 'full' };
    output: {
      symbol: string;
      history: Array<{ date: string; open: number; high: number; low: number; close: number; volume: number }>;
    };
  };

  // Report functions
  generateReport: {
    input: types.GenerateReportInput;
    output: types.ReportData;
  };

  // Duplicate detection
  checkDuplicateTransaction: {
    input: { accountId: string; date: string; amount: number; description: string; threshold?: number };
    output: { isDuplicate: boolean; matches: types.Transaction[] };
  };
}

/**
 * Helper type to extract input type for a function
 */
export type FunctionInput<T extends keyof CloudFunctions> = CloudFunctions[T]['input'];

/**
 * Helper type to extract output type for a function
 */
export type FunctionOutput<T extends keyof CloudFunctions> = CloudFunctions[T]['output'];
```

#### Step 1.6: Export Everything
**`packages/shared-types/src/index.ts`**:
```typescript
// Export all schemas
export * from './schemas';

// Export all types
export * from './types';

// Export function signatures
export * from './functions';

// Export constants
export const ACCOUNT_TYPES = [
  'savings', 'checking', 'credit_card', 'investment',
  'brokerage', 'mutual_fund', 'loan', 'mortgage',
  'fixed_deposit', 'recurring_deposit', 'ppf', 'nps', 'epf',
  'cash', 'other'
] as const;

export const TRANSACTION_TYPES = ['income', 'expense', 'transfer'] as const;
export const BUDGET_PERIODS = ['daily', 'weekly', 'monthly', 'yearly'] as const;
export const GOAL_PRIORITIES = ['low', 'medium', 'high'] as const;
export const GOAL_STATUSES = ['active', 'completed', 'paused', 'cancelled'] as const;
export const REPORT_TYPES = [
  'income_expense',
  'category_breakdown',
  'account_summary',
  'budget_performance',
  'goal_progress',
  'net_worth',
] as const;
```

### Phase 2: Update Functions Package (Week 1)

#### Step 2.1: Add Dependency
**`packages/functions/package.json`**:
```json
{
  "dependencies": {
    "@wealthwise/shared-types": "workspace:*",
    "firebase-admin": "catalog:",
    "firebase-functions": "catalog:"
  }
}
```

#### Step 2.2: Update Function Implementations
**`packages/functions/src/goals.ts`**:
```typescript
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { 
  createGoalSchema, 
  safeValidate,
  type CreateGoalInput,
  type CreateGoalOutput,
  type FunctionInput,
  type FunctionOutput
} from '@wealthwise/shared-types';
import { AppError, authError, ErrorCodes, validationError } from './errors';

const db = admin.firestore();

/**
 * Create a new goal
 * Type-safe with shared types from @wealthwise/shared-types
 */
export const createGoal = functions.https.onCall<
  FunctionInput<'createGoal'>,
  Promise<FunctionOutput<'createGoal'>>
>(async (request) => {
  if (!request.auth) {
    throw authError(ErrorCodes.AUTH_UNAUTHENTICATED);
  }

  const userId = request.auth.uid;

  // Validate input with Zod schema from shared package
  const validation = safeValidate(createGoalSchema, request.data);
  if (!validation.success) {
    throw validationError(ErrorCodes.VALIDATION_INVALID_FORMAT, undefined, {
      errors: validation.errors.issues,
    });
  }

  const goalData = validation.data;

  try {
    const goalRef = db.collection('goals').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const goal = {
      user_id: userId,
      name: goalData.name,
      target_amount: goalData.target_amount,
      current_amount: goalData.current_amount || 0,
      target_date: goalData.target_date
        ? admin.firestore.Timestamp.fromDate(new Date(goalData.target_date))
        : null,
      priority: goalData.priority || 'medium',
      category: goalData.category || null,
      description: goalData.description || null,
      status: 'active' as const,
      created_at: now,
      updated_at: now,
    };

    await goalRef.set(goal);

    // Return type matches CreateGoalOutput
    return {
      id: goalRef.id,
      ...goal,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    } as CreateGoalOutput;
  } catch (error: any) {
    console.error('Error creating goal:', error);
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      ErrorCodes.OPERATION_FAILED,
      'Failed to create goal',
      'internal',
      { originalError: error.message },
    );
  }
});
```

### Phase 3: Update Webapp Package (Week 2)

#### Step 3.1: Add Dependency
**`packages/webapp/package.json`**:
```json
{
  "dependencies": {
    "@wealthwise/shared-types": "workspace:*",
    "firebase": "catalog:",
    "react": "catalog:"
  }
}
```

#### Step 3.2: Create Type-Safe API Wrapper
**`packages/webapp/src/core/api/typedFunctions.ts`**:
```typescript
import { httpsCallable, type HttpsCallableResult } from 'firebase/functions';
import { functions } from '../firebase/firebase';
import type { CloudFunctions, FunctionInput, FunctionOutput } from '@wealthwise/shared-types';

/**
 * Type-safe wrapper for calling Cloud Functions
 * Ensures input and output types match the function signatures
 */
export function callFunction<T extends keyof CloudFunctions>(
  functionName: T,
  data: FunctionInput<T>
): Promise<FunctionOutput<T>> {
  const callable = httpsCallable<FunctionInput<T>, FunctionOutput<T>>(
    functions,
    functionName as string
  );
  
  return callable(data).then(result => result.data);
}

/**
 * Alternative wrapper that returns the full HttpsCallableResult
 */
export function callFunctionRaw<T extends keyof CloudFunctions>(
  functionName: T,
  data: FunctionInput<T>
): Promise<HttpsCallableResult<FunctionOutput<T>>> {
  const callable = httpsCallable<FunctionInput<T>, FunctionOutput<T>>(
    functions,
    functionName as string
  );
  
  return callable(data);
}
```

#### Step 3.3: Update API Functions
**`packages/webapp/src/core/api/goalsApi.ts`**:
```typescript
import type { 
  Goal, 
  CreateGoalInput,
  UpdateGoalInput,
  FunctionInput,
  FunctionOutput
} from '@wealthwise/shared-types';
import { callFunction } from './typedFunctions';

/**
 * Create a new goal
 * Types are automatically inferred from shared-types package
 */
export async function createGoal(
  data: CreateGoalInput
): Promise<Goal> {
  // TypeScript ensures `data` matches CreateGoalInput exactly
  // Return type is guaranteed to match Goal
  return callFunction('createGoal', data);
}

/**
 * Update an existing goal
 */
export async function updateGoal(
  goalId: string,
  updates: UpdateGoalInput['updates']
): Promise<Goal> {
  return callFunction('updateGoal', { goalId, updates });
}

/**
 * Delete a goal
 */
export async function deleteGoal(
  goalId: string
): Promise<{ success: boolean; message: string }> {
  return callFunction('deleteGoal', { goalId });
}

/**
 * Get a specific goal
 */
export async function getGoal(
  goalId: string
): Promise<Goal> {
  return callFunction('getGoal', { goalId });
}

/**
 * Add contribution to a goal
 */
export async function addGoalContribution(
  data: FunctionInput<'addGoalContribution'>
): Promise<Goal> {
  return callFunction('addGoalContribution', data);
}
```

**`packages/webapp/src/core/api/accountApi.ts`**:
```typescript
import type { 
  Account,
  CreateAccountInput,
  UpdateAccountInput,
  FunctionInput,
  FunctionOutput
} from '@wealthwise/shared-types';
import { callFunction } from './typedFunctions';

export async function createAccount(
  data: CreateAccountInput
): Promise<FunctionOutput<'createAccount'>> {
  return callFunction('createAccount', data);
}

export async function updateAccount(
  accountId: string,
  updates: UpdateAccountInput
): Promise<{ success: boolean; message: string }> {
  return callFunction('updateAccount', { accountId, updates });
}

export async function deleteAccount(
  accountId: string
): Promise<{ success: boolean; message: string }> {
  return callFunction('deleteAccount', { accountId });
}

export async function calculateAccountBalance(
  accountId: string,
  asOfDate?: string
): Promise<{ accountId: string; balance: number; calculatedAt: string }> {
  return callFunction('calculateAccountBalance', { accountId, asOfDate });
}
```

### Phase 4: Code Generation (Week 2)

#### Step 4.1: Create Type Generator Script
**`packages/shared-types/scripts/generate-types.ts`**:
```typescript
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as schemas from '../src/schemas';

/**
 * Auto-generate TypeScript types from Zod schemas
 * Run: pnpm run generate:types
 */

const TEMPLATE = `
// AUTO-GENERATED - DO NOT EDIT
// Generated from Zod schemas on {date}

import { z } from 'zod';
import * as schemas from './schemas';

{types}
`;

function generateTypes() {
  const types: string[] = [];
  
  // Extract all schema exports
  for (const [name, schema] of Object.entries(schemas)) {
    if (name.endsWith('Schema')) {
      const typeName = name
        .replace('Schema', '')
        .replace(/^./, (c) => c.toUpperCase()) + 'Input';
      
      types.push(`export type ${typeName} = z.infer<typeof schemas.${name}>;`);
    }
  }
  
  const output = TEMPLATE
    .replace('{date}', new Date().toISOString())
    .replace('{types}', types.join('\n'));
  
  const outputPath = path.join(__dirname, '../src/generated-types.ts');
  fs.writeFileSync(outputPath, output, 'utf-8');
  
  console.log(`✅ Generated ${types.length} types to ${outputPath}`);
}

generateTypes();
```

Add to `packages/shared-types/package.json`:
```json
{
  "scripts": {
    "generate:types": "tsx scripts/generate-types.ts",
    "build": "npm run generate:types && tsc"
  }
}
```

### Phase 5: Validation & Testing (Week 3)

#### Step 5.1: Create Type Tests
**`packages/shared-types/src/__tests__/type-safety.test.ts`**:
```typescript
import { describe, it, expect } from 'vitest';
import type { CloudFunctions, FunctionInput, FunctionOutput } from '../functions';

describe('Type Safety Tests', () => {
  it('should enforce correct input types', () => {
    type CreateGoalInput = FunctionInput<'createGoal'>;
    
    // Valid input
    const validInput: CreateGoalInput = {
      name: 'Buy a house',
      target_amount: 5000000,
      priority: 'high',
    };
    
    // TypeScript should catch these errors at compile time:
    // @ts-expect-error - missing required field 'name'
    const invalidInput1: CreateGoalInput = {
      target_amount: 5000000,
    };
    
    // @ts-expect-error - wrong type for priority
    const invalidInput2: CreateGoalInput = {
      name: 'Test',
      target_amount: 5000000,
      priority: 'urgent', // Not a valid priority
    };
  });

  it('should enforce correct output types', () => {
    type CreateGoalOutput = FunctionOutput<'createGoal'>;
    
    // Output must include all required Goal fields
    const output: CreateGoalOutput = {
      id: '123',
      user_id: 'user456',
      name: 'Buy a house',
      target_amount: 5000000,
      current_amount: 0,
      priority: 'high',
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    expect(output.id).toBeDefined();
  });
});
```

#### Step 5.2: Runtime Validation Tests
**`packages/webapp/src/core/api/__tests__/goalsApi.test.ts`**:
```typescript
import { describe, it, expect, vi } from 'vitest';
import { createGoal } from '../goalsApi';
import type { CreateGoalInput } from '@wealthwise/shared-types';

vi.mock('../typedFunctions', () => ({
  callFunction: vi.fn(),
}));

describe('Goals API', () => {
  it('should enforce CreateGoalInput type', async () => {
    const validInput: CreateGoalInput = {
      name: 'Save for vacation',
      target_amount: 100000,
      priority: 'medium',
    };
    
    // TypeScript ensures this matches CreateGoalInput
    await createGoal(validInput);
    
    // @ts-expect-error - TypeScript catches missing required fields
    await createGoal({ name: 'Test' });
    
    // @ts-expect-error - TypeScript catches invalid field types
    await createGoal({ name: 123, target_amount: 'invalid' });
  });
});
```

### Phase 6: Migration Strategy (Week 3-4)

#### Migration Checklist

**Step 1: Update Dependencies**
```bash
# Add shared-types to both packages
cd packages/functions && pnpm add @wealthwise/shared-types@workspace:*
cd packages/webapp && pnpm add @wealthwise/shared-types@workspace:*
```

**Step 2: Migrate Functions (One at a time)**
- [ ] goals.ts
- [ ] accounts.ts
- [ ] transactions.ts
- [ ] budgets.ts
- [ ] import.ts
- [ ] dashboard.ts
- [ ] investments.ts
- [ ] reports.ts
- [ ] deposits.ts
- [ ] duplicates.ts
- [ ] dataExport.ts
- [ ] pubsub.ts

**Step 3: Migrate Webapp APIs (One at a time)**
- [ ] goalsApi.ts
- [ ] accountApi.ts
- [ ] transactionApi.ts
- [ ] budgetApi.ts
- [ ] importApi.ts
- [ ] dashboardApi.ts
- [ ] investmentsApi.ts (NEW)
- [ ] reportApi.ts
- [ ] depositApi.ts
- [ ] duplicateApi.ts
- [ ] dataExportApi.ts

**Step 4: Remove Duplicate Types**
- [ ] Delete duplicate type definitions from webapp
- [ ] Remove manual type casts
- [ ] Update imports to use shared-types

**Step 5: Add Validation**
- [ ] Run type tests
- [ ] Verify API calls at compile time
- [ ] Test in Firebase emulators

### Phase 7: Developer Experience Improvements (Week 4)

#### DX Enhancement 1: VSCode Autocomplete
**`.vscode/settings.json`**:
```json
{
  "typescript.suggest.autoImports": true,
  "typescript.preferences.includePackageJsonAutoImports": "on",
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

#### DX Enhancement 2: Pre-commit Hook
**`.husky/pre-commit`**:
```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Generate types before committing
cd packages/shared-types && pnpm run generate:types

# Type check everything
pnpm run -r type-check
```

#### DX Enhancement 3: API Documentation Generator
**`packages/shared-types/scripts/generate-docs.ts`**:
```typescript
/**
 * Auto-generate API documentation from function signatures
 */
import * as fs from 'node:fs';
import type { CloudFunctions } from '../src/functions';

const docs: string[] = ['# Cloud Functions API Reference\n\n'];

type FunctionName = keyof CloudFunctions;

const functionNames = [
  'createGoal',
  'updateGoal',
  'deleteGoal',
  // ... all function names
] as const;

for (const name of functionNames) {
  docs.push(`## ${name}\n\n`);
  docs.push('**Input:**\n```typescript\n');
  // Type information is preserved in TypeScript
  docs.push('```\n\n');
  docs.push('**Output:**\n```typescript\n');
  docs.push('```\n\n');
}

fs.writeFileSync('API.md', docs.join(''), 'utf-8');
console.log('✅ Generated API documentation');
```

## 📊 Benefits Summary

### Before (Current State)
❌ Duplicate type definitions in functions and webapp  
❌ Manual type synchronization required  
❌ Runtime type mismatches possible  
❌ No compile-time safety for API calls  
❌ Maintenance overhead on every change  

### After (With Shared Types)
✅ Single source of truth for all types  
✅ Automatic type synchronization  
✅ Compile-time type safety guaranteed  
✅ TypeScript autocomplete for all API calls  
✅ Zero runtime type errors  
✅ Auto-generated documentation  
✅ Easier onboarding for new developers  

## 🎯 Success Metrics

1. **Type Coverage**: 100% of Cloud Functions have explicit types
2. **Compile-Time Safety**: 0 `any` types in API layer
3. **Documentation**: Auto-generated API docs always up-to-date
4. **Developer Speed**: 50% faster API integration (autocomplete)
5. **Bug Reduction**: 90% fewer type-related runtime errors

## 📅 Timeline Summary

- **Week 1**: Create shared-types package, migrate schemas, update functions
- **Week 2**: Update webapp, create type-safe wrappers, migrate 50% of APIs
- **Week 3**: Complete migration, add tests, validate all endpoints
- **Week 4**: DX improvements, documentation, monitoring

## 🔧 Maintenance

### Adding New Functions
1. Define schema in `shared-types/src/schemas.ts`
2. Add function signature to `shared-types/src/functions.ts`
3. Implement function in `packages/functions/src/`
4. Create API wrapper in `packages/webapp/src/core/api/`
5. TypeScript ensures everything is type-safe!

### Updating Existing Functions
1. Update schema in `shared-types/src/schemas.ts`
2. Update signature in `shared-types/src/functions.ts`
3. TypeScript will show compile errors everywhere types don't match
4. Fix all compile errors
5. All calls are now updated!

## 🚀 Next Steps

1. **Create `packages/shared-types` package** (Priority: HIGH)
2. **Move schemas.ts to shared-types** (Priority: HIGH)
3. **Update functions to use shared types** (Priority: MEDIUM)
4. **Create type-safe API wrappers** (Priority: MEDIUM)
5. **Migrate all API calls** (Priority: LOW - can be done incrementally)

Would you like me to start implementing Phase 1 by creating the shared-types package?
