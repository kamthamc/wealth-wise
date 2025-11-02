/**
 * Cloud Function Request/Response Types
 * Used for Firebase Cloud Functions callable functions
 */

import type {
  Account,
  Transaction,
  DepositDetails,
  BrokerageDetails,
  InsuranceDetails,
  PensionAccount,
  RealEstateInvestment,
  PreciousMetal,
  AlternativeInvestment,
  InvestmentTransaction,
  AccountType,
  TransactionType,
  BudgetPeriodType,
  GoalStatus,
  GoalPriority,
  CategoryType,
} from './Investments.js';

// ==================== Common Response Types ====================

export interface SuccessResponse {
  success: true;
  message: string;
}

export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export type FunctionResponse<T = unknown> = 
  | (SuccessResponse & { data: T })
  | ErrorResponse;

// ==================== Net Worth & Portfolio ====================

export interface NetWorthRequest {
  asOfDate?: string; // ISO date string, defaults to now
  includeInactive?: boolean;
}

export interface AccountBalance {
  accountId: string;
  accountName: string;
  accountType: AccountType;
  balance: number;
  currency: string;
}

export interface NetWorthByType {
  type: AccountType;
  totalBalance: number;
  accountCount: number;
  accounts: AccountBalance[];
}

export interface NetWorthResponse {
  totalNetWorth: number;
  currency: string;
  asOfDate: string;
  totalAssets: number;
  totalLiabilities: number;
  accountCount: number;
  byType: NetWorthByType[];
  topAccounts: AccountBalance[];
  lastUpdated: string;
}

// ==================== Portfolio Summary ====================

export interface PortfolioSummaryRequest {
  includePerformance?: boolean;
  timeframe?: 'day' | 'week' | 'month' | 'year' | 'all';
}

export interface InvestmentHolding {
  accountId: string;
  accountName: string;
  accountType: AccountType;
  invested: number;
  currentValue: number;
  returns: number;
  returnsPercentage: number;
}

export interface PortfolioPerformance {
  totalInvested: number;
  currentValue: number;
  totalReturns: number;
  returnsPercentage: number;
  dayChange?: number;
  dayChangePercentage?: number;
  holdings: InvestmentHolding[];
  topPerformers: InvestmentHolding[];
  bottomPerformers: InvestmentHolding[];
}

export interface PortfolioSummaryResponse {
  summary: {
    totalInvestments: number;
    accountCount: number;
    investmentTypes: number;
  };
  performance?: PortfolioPerformance;
  currency: string;
  asOfDate: string;
}

// ==================== Transaction Analytics ====================

export interface TransactionAnalyticsRequest {
  startDate: string; // ISO date
  endDate: string; // ISO date
  accountIds?: string[];
  categories?: string[];
  groupBy?: 'day' | 'week' | 'month' | 'year' | 'category' | 'account';
}

export interface CategoryBreakdown {
  category: string;
  total: number;
  count: number;
  percentage: number;
  trend?: 'up' | 'down' | 'stable';
}

export interface TimeSeries {
  date: string;
  income: number;
  expense: number;
  net: number;
  balance: number;
}

export interface TransactionAnalyticsResponse {
  summary: {
    totalIncome: number;
    totalExpense: number;
    netIncome: number;
    transactionCount: number;
    averageTransaction: number;
  };
  incomeByCategory: CategoryBreakdown[];
  expenseByCategory: CategoryBreakdown[];
  timeSeries: TimeSeries[];
  topExpenseCategories: CategoryBreakdown[];
  topIncomeCategories: CategoryBreakdown[];
  currency: string;
  dateFormat: string;
}

// ==================== Budget Analytics ====================

export interface BudgetAnalyticsRequest {
  budgetId?: string; // If not provided, returns all active budgets
  period?: string; // ISO date for specific period
}

export interface BudgetCategoryProgress {
  category: string;
  allocated: number;
  spent: number;
  remaining: number;
  percentage: number;
  status: 'under' | 'near' | 'over';
  transactionCount: number;
}

export interface BudgetAnalytics {
  budgetId: string;
  budgetName: string;
  periodType: BudgetPeriodType;
  startDate: string;
  endDate: string;
  totalAllocated: number;
  totalSpent: number;
  totalRemaining: number;
  overallPercentage: number;
  categories: BudgetCategoryProgress[];
  alerts: {
    type: 'warning' | 'danger';
    category: string;
    message: string;
  }[];
}

export interface BudgetAnalyticsResponse {
  budgets: BudgetAnalytics[];
  summary: {
    activeBudgets: number;
    totalAllocated: number;
    totalSpent: number;
    categoriesOverBudget: number;
    categoriesNearLimit: number;
  };
}

// ==================== Goal Analytics ====================

export interface GoalAnalyticsRequest {
  goalId?: string; // If not provided, returns all goals
  status?: GoalStatus;
  priority?: GoalPriority;
}

export interface GoalProgress {
  goalId: string;
  goalName: string;
  targetAmount: number;
  currentAmount: number;
  remainingAmount: number;
  percentage: number;
  targetDate?: string;
  daysRemaining?: number;
  monthlyRequiredContribution?: number;
  status: GoalStatus;
  priority?: GoalPriority;
  onTrack: boolean;
  projectedCompletionDate?: string;
}

export interface GoalAnalyticsResponse {
  goals: GoalProgress[];
  summary: {
    totalGoals: number;
    activeGoals: number;
    completedGoals: number;
    totalTargetAmount: number;
    totalCurrentAmount: number;
    totalRemainingAmount: number;
    overallProgress: number;
  };
}

// ==================== Cash Flow Analysis ====================

export interface CashFlowRequest {
  startDate: string;
  endDate: string;
  granularity?: 'day' | 'week' | 'month';
}

export interface CashFlowPeriod {
  period: string; // Date or period label
  income: number;
  expense: number;
  netFlow: number;
  openingBalance: number;
  closingBalance: number;
}

export interface CashFlowResponse {
  periods: CashFlowPeriod[];
  summary: {
    totalIncome: number;
    totalExpense: number;
    netCashFlow: number;
    averageIncome: number;
    averageExpense: number;
    positiveMonths: number;
    negativeMonths: number;
  };
  projection?: {
    nextPeriodIncome: number;
    nextPeriodExpense: number;
    nextPeriodNet: number;
  };
  currency: string;
}

// ==================== Account Summary ====================

export interface AccountSummaryRequest {
  accountId: string;
  startDate?: string;
  endDate?: string;
}

export interface AccountTransaction {
  id: string;
  date: string;
  type: TransactionType;
  category: string;
  amount: number;
  balance: number;
  description?: string;
}

export interface AccountSummaryResponse {
  account: Account;
  balance: number;
  transactionSummary: {
    totalTransactions: number;
    totalIncome: number;
    totalExpense: number;
    netFlow: number;
    startDate: string;
    endDate: string;
  };
  recentTransactions: AccountTransaction[];
  topCategories: CategoryBreakdown[];
  monthlyAverage: {
    income: number;
    expense: number;
    net: number;
  };
}

// ==================== Investment Details ====================

export interface InvestmentDetailsRequest {
  accountId: string;
  includeTransactions?: boolean;
}

export interface InvestmentDetailsResponse {
  account: Account;
  details:
    | DepositDetails
    | BrokerageDetails
    | InsuranceDetails
    | PensionAccount
    | RealEstateInvestment
    | PreciousMetal
    | AlternativeInvestment;
  transactions?: InvestmentTransaction[];
  performance?: {
    invested: number;
    current: number;
    returns: number;
    returnsPercentage: number;
    xirr?: number;
  };
}

// ==================== Dashboard ====================

export interface DashboardRequest {
  refresh?: boolean; // Force refresh cached data
}

export interface DashboardWidget {
  type: string;
  title: string;
  data: unknown;
  lastUpdated: string;
}

export interface DashboardResponse {
  netWorth: NetWorthResponse;
  recentTransactions: Transaction[];
  budgetSummary: {
    activeBudgets: number;
    totalSpent: number;
    budgetsOverLimit: number;
  };
  goalSummary: {
    activeGoals: number;
    totalProgress: number;
    goalsCompleted: number;
  };
  insights: {
    type: 'info' | 'warning' | 'success';
    message: string;
    action?: string;
  }[];
  widgets: DashboardWidget[];
  cached: boolean;
  generatedAt: string;
}

// ==================== Category Management ====================

export interface CategoryStatsRequest {
  type?: CategoryType;
  startDate?: string;
  endDate?: string;
}

export interface CategoryStats {
  category: string;
  type: CategoryType;
  totalAmount: number;
  transactionCount: number;
  averageAmount: number;
  percentage: number;
  trend: 'up' | 'down' | 'stable';
  monthlyAverage: number;
}

export interface CategoryStatsResponse {
  categories: CategoryStats[];
  summary: {
    totalCategories: number;
    totalAmount: number;
    totalTransactions: number;
  };
}

// ==================== Duplicate Detection ====================

export interface DuplicateCheckRequest {
  transaction: {
    account_id: string;
    amount: number;
    date: string;
    description?: string;
    category?: string;
  };
  lookbackDays?: number; // Default 7
  similarityThreshold?: number; // 0-1, default 0.8
}

export interface DuplicateMatch {
  transactionId: string;
  similarity: number;
  matchReason: string[];
  transaction: Transaction;
}

export interface DuplicateCheckResponse {
  isDuplicate: boolean;
  confidence: number; // 0-1
  matches: DuplicateMatch[];
  recommendation: 'skip' | 'review' | 'proceed';
}

// ==================== Batch Operations ====================

export interface BatchImportRequest {
  transactions: Array<{
    account_id: string;
    type: TransactionType;
    category: string;
    amount: number;
    date: string;
    description?: string;
  }>;
  skipDuplicates?: boolean;
  importSource?: string;
}

export interface BatchImportResponse {
  success: boolean;
  imported: number;
  skipped: number;
  failed: number;
  errors: Array<{
    index: number;
    error: string;
  }>;
  duplicates: Array<{
    index: number;
    matches: DuplicateMatch[];
  }>;
}

// ==================== Recurring Transactions ====================

export interface RecurringTransactionRequest {
  accountId?: string;
  active?: boolean;
}

export interface RecurringPattern {
  transactionId: string;
  pattern: {
    frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
    amount: number;
    category: string;
    description: string;
  };
  nextOccurrence: string;
  occurrences: number;
  totalAmount: number;
}

export interface RecurringTransactionResponse {
  patterns: RecurringPattern[];
  summary: {
    totalRecurring: number;
    monthlyTotal: number;
    yearlyTotal: number;
  };
}

// ==================== Tax Report ====================

export interface TaxReportRequest {
  financialYear: string; // e.g., "2024-25"
}

export interface TaxDeduction {
  section: string;
  category: string;
  amount: number;
  description: string;
  verified: boolean;
}

export interface TaxableIncome {
  category: string;
  amount: number;
  taxable: number;
}

export interface TaxReportResponse {
  financialYear: string;
  deductions: TaxDeduction[];
  income: TaxableIncome[];
  summary: {
    totalDeductions: number;
    section80C: number;
    section80D: number;
    totalIncome: number;
    taxableIncome: number;
    estimatedTax: number;
  };
  recommendations: string[];
}

// ==================== Alerts & Notifications ====================

export interface AlertsRequest {
  types?: ('budget' | 'goal' | 'recurring' | 'unusual')[];
  unreadOnly?: boolean;
}

export interface Alert {
  id: string;
  type: 'budget' | 'goal' | 'recurring' | 'unusual';
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message: string;
  actionUrl?: string;
  actionLabel?: string;
  read: boolean;
  createdAt: string;
}

export interface AlertsResponse {
  alerts: Alert[];
  unreadCount: number;
  summary: {
    budget: number;
    goal: number;
    recurring: number;
    unusual: number;
  };
}

// ==================== Export Types ====================

export interface ExportDataRequest {
  format: 'json' | 'csv';
  entities: ('accounts' | 'transactions' | 'budgets' | 'goals')[];
  startDate?: string;
  endDate?: string;
  includeDeleted?: boolean;
}

export interface ExportDataResponse {
  format: string;
  data: string; // JSON string or CSV string
  filename: string;
  recordCount: number;
  generatedAt: string;
}
