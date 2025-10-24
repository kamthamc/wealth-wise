import { AccountType } from '@svc/wealth-wise-shared-types';
import { z } from 'zod';

/**
 * Common validation schemas
 */

// Date validation
export const dateSchema = z
  .iso
  .datetime()
  .or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/));

// Currency validation (positive numbers with 2 decimal places)
export const currencySchema = z.number().nonnegative();

// UUID validation
export const uuidSchema = z.uuidv4();

export const allAccountTypes: AccountType[] = [
  'savings',
  'checking',
  'credit_card',
  'investment',
  'brokerage',
  'mutual_fund',
  'loan',
  'mortgage',
  'fixed_deposit',
  'recurring_deposit',
  'ppf',
  'nps',
  'epf',
  'cash',
  'other',
];

/**
 * Account schemas
 */
export const accountTypeSchema = z.enum(allAccountTypes);

export const createAccountSchema = z.object({
  name: z.string().min(1).max(100),
  type: accountTypeSchema,
  balance: currencySchema.optional(),
  initial_balance: currencySchema.optional(),
  currency: z.string().length(3).default('INR'),
  institution: z.string().max(100).optional(),
  account_number: z.string().max(50).optional(),
  notes: z.string().max(500).optional(),
  is_active: z.boolean().default(true),
});

export const updateAccountSchema = createAccountSchema.partial();

export const calculateAccountBalanceSchema = z.object({
  accountId: uuidSchema,
  includeTransfers: z.boolean().optional().default(true),
});

export const allTransactionTypes = ['income', 'expense', 'transfer'];

/**
 * Transaction schemas
 */
export const transactionTypeSchema = z.enum(allTransactionTypes);

export const createTransactionSchema = z.object({
  account_id: uuidSchema,
  date: dateSchema,
  description: z.string().min(1).max(200),
  amount: z.number(),
  type: transactionTypeSchema,
  category: z.string().max(50).optional(),
  notes: z.string().max(500).optional(),
  tags: z.array(z.string()).optional(),
  to_account_id: uuidSchema.optional(),
  import_reference: z.string().optional(),
  import_transaction_id: z.string().optional(),
});

export const updateTransactionSchema = createTransactionSchema.partial();

export const getTransactionStatsSchema = z.object({
  accountId: uuidSchema.optional(),
  startDate: dateSchema.optional(),
  endDate: dateSchema.optional(),
  category: z.string().optional(),
  type: transactionTypeSchema.optional(),
});

export const allBudgetPeriods = ['daily', 'weekly', 'monthly', 'yearly'];

/**
 * Budget schemas
 */
export const budgetPeriodSchema = z.enum(allBudgetPeriods);

export const createBudgetSchema = z.object({
  name: z.string().min(1).max(100),
  amount: currencySchema,
  period: budgetPeriodSchema,
  category: z.string().max(50).optional(),
  start_date: dateSchema,
  end_date: dateSchema,
  is_active: z.boolean().default(true),
  alert_threshold: z.number().min(0).max(100).optional(), // percentage
});

export const updateBudgetSchema = createBudgetSchema.partial();

export const allGoalPriorities = ['low', 'medium', 'high'];
export const allGoalStatuses = ['active', 'completed', 'paused', 'cancelled'];

/**
 * Goal schemas
 */
export const goalPrioritySchema = z.enum(allGoalPriorities);
export const goalStatusSchema = z.enum(allGoalStatuses);

export const createGoalSchema = z.object({
  name: z.string().min(1).max(100),
  target_amount: currencySchema,
  current_amount: currencySchema.optional().default(0),
  target_date: dateSchema.optional(),
  priority: goalPrioritySchema.optional().default('medium'),
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
    priority: goalPrioritySchema.optional(),
    category: z.string().max(50).optional(),
    description: z.string().max(500).optional(),
    status: goalStatusSchema.optional(),
  }),
});

export const addGoalContributionSchema = z.object({
  goalId: uuidSchema,
  amount: currencySchema.refine((val) => val > 0, {
    message: 'Contribution amount must be greater than 0',
  }),
  date: dateSchema.optional(),
  notes: z.string().max(200).optional(),
});

/**
 * Import/Export schemas
 */
export const importTransactionSchema = z.object({
  date: dateSchema,
  description: z.string().min(1).max(200),
  amount: z.number(),
  type: transactionTypeSchema,
  category: z.string().max(50).optional(),
  notes: z.string().max(500).optional(),
  import_transaction_id: z.string().optional(),
});

export const importTransactionsSchema = z.object({
  transactions: z.array(importTransactionSchema).min(1).max(5000),
  accountId: uuidSchema,
  detectDuplicates: z.boolean().optional().default(true),
});

export const batchImportTransactionsSchema = z.object({
  transactions: z.array(importTransactionSchema).min(1),
  accountId: uuidSchema,
  chunkSize: z.number().min(10).max(500).optional().default(100),
});

export const exportTransactionsSchema = z.object({
  accountId: uuidSchema.optional(),
  startDate: dateSchema.optional(),
  endDate: dateSchema.optional(),
  format: z.enum(['json', 'csv']).optional().default('json'),
});

export const clearUserDataSchema = z.object({
  confirmation: z.literal('DELETE_ALL_MY_DATA'),
  collections: z.array(z.string()).optional().default(['all']),
});

/**
 * Dashboard schemas
 */
export const computeAndCacheDashboardSchema = z.object({
  forceRefresh: z.boolean().optional().default(false),
  cacheTTL: z.number().min(60).max(3600).optional().default(300), // 1 min to 1 hour
});

export const getAccountSummarySchema = z.object({
  accountId: uuidSchema,
});

export const getTransactionSummarySchema = z.object({
  startDate: dateSchema.optional(),
  endDate: dateSchema.optional(),
  groupBy: z.enum(['day', 'week', 'month', 'year']).optional().default('month'),
});

/**
 * Investment schemas
 */
export const fetchStockDataSchema = z.object({
  symbol: z
    .string()
    .min(1)
    .max(10)
    .regex(/^[A-Z0-9.]+$/),
  forceRefresh: z.boolean().optional().default(false),
});

export const fetchStockHistorySchema = z.object({
  symbol: z
    .string()
    .min(1)
    .max(10)
    .regex(/^[A-Z0-9.]+$/),
  interval: z.enum(['daily', 'weekly', 'monthly']).optional().default('daily'),
  outputSize: z.enum(['compact', 'full']).optional().default('compact'),
});

export const fetchMutualFundDataSchema = z.object({
  isin: z.string().min(1).max(20),
  forceRefresh: z.boolean().optional().default(false),
});

export const clearInvestmentCacheSchema = z.object({
  type: z.enum(['all', 'stocks', 'mutualfunds']).optional().default('all'),
});

/**
 * Deposit calculation schemas
 */
export const calculateFDMaturitySchema = z.object({
  principal: currencySchema,
  rate: z.number().min(0).max(100), // percentage
  tenure: z.number().min(1).max(360), // months
  compoundingFrequency: z
    .enum(['monthly', 'quarterly', 'half-yearly', 'yearly'])
    .optional()
    .default('quarterly'),
});

export const calculateRDMaturitySchema = z.object({
  monthlyDeposit: currencySchema,
  rate: z.number().min(0).max(100),
  tenure: z.number().min(6).max(120), // 6 months to 10 years
});

export const calculatePPFMaturitySchema = z.object({
  yearlyDeposit: currencySchema.max(150000), // PPF limit
  tenure: z.number().min(15).max(50), // 15 years minimum
  currentBalance: currencySchema.optional().default(0),
});

export const calculateSavingsInterestSchema = z.object({
  balance: currencySchema,
  rate: z.number().min(0).max(100),
  days: z.number().min(1).max(365),
});

/**
 * Report schemas
 */
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

/**
 * Duplicate detection schemas
 */
export const checkDuplicateTransactionSchema = z.object({
  accountId: uuidSchema,
  date: dateSchema,
  amount: z.number(),
  description: z.string().min(1),
  threshold: z.number().min(0).max(1).optional().default(0.9), // similarity threshold
});

export const batchCheckDuplicatesSchema = z.object({
  transactions: z
    .array(
      z.object({
        accountId: uuidSchema,
        date: dateSchema,
        amount: z.number(),
        description: z.string().min(1),
      }),
    )
    .min(1)
    .max(1000),
  threshold: z.number().min(0).max(1).optional().default(0.9),
});

/**
 * Helper function to validate data against a schema
 */
export function validateSchema<T>(schema: z.ZodSchema<T>, data: unknown): T {
  try {
    return schema.parse(data);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const formattedErrors = error.issues.map((err) => ({
        path: err.path.join('.'),
        message: err.message,
        code: err.code,
      }));
      throw new Error(
        `Validation failed: ${JSON.stringify(formattedErrors, null, 2)}`,
      );
    }
    throw error;
  }
}

/**
 * Helper function for safe validation that returns success/error
 */
export function safeValidate<T>(
  schema: z.ZodSchema<T>,
  data: unknown,
): { success: true; data: T } | { success: false; errors: z.ZodError } {
  const result = schema.safeParse(data);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, errors: result.error };
}

// Export type inference helpers
export type CreateAccountInput = z.infer<typeof createAccountSchema>;
export type UpdateAccountInput = z.infer<typeof updateAccountSchema>;
export type CreateTransactionInput = z.infer<typeof createTransactionSchema>;
export type UpdateTransactionInput = z.infer<typeof updateTransactionSchema>;
export type CreateBudgetInput = z.infer<typeof createBudgetSchema>;
export type UpdateBudgetInput = z.infer<typeof updateBudgetSchema>;
export type CreateGoalInput = z.infer<typeof createGoalSchema>;
export type UpdateGoalInput = z.infer<typeof updateGoalSchema>;
export type ImportTransactionInput = z.infer<typeof importTransactionSchema>;
export type FetchStockDataInput = z.infer<typeof fetchStockDataSchema>;
export type GenerateReportInput = z.infer<typeof generateReportSchema>;
