import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp({});

// Export account functions
export {
  calculateAccountBalance,
  createAccount,
  deleteAccount,
  getAccountTypes,
  getBudgetPeriods,
  getGoalPriorities,
  getGoalStatuses,
  getTransactionTypes,
  updateAccount,
} from './accounts';
// Export budget functions
export {
  calculateBudgetProgress,
  createBudget,
  deleteBudget,
  updateBudget,
} from './budgets';
// Export dashboard and caching functions
export {
  computeAndCacheDashboard,
  getAccountSummary,
  getTransactionSummary,
  invalidateDashboardCache,
} from './dashboard';
// Export data import/export functions
export {
  exportUserData,
  getUserStatistics,
  importUserData,
} from './dataExport';
// Export deposit calculation functions
export {
  calculateFDMaturity,
  calculatePPFMaturity,
  calculateRDMaturity,
  calculateSavingsInterest,
  getDepositAccountDetails,
} from './deposits';

// Export duplicate detection functions
export { batchCheckDuplicates, checkDuplicateTransaction } from './duplicates';
// Export goal functions
export {
  addGoalContribution,
  calculateGoalProgress,
  createGoal,
  deleteGoal,
  updateGoal,
} from './goals';
// Export import/export and bulk operations
export {
  batchImportTransactions,
  clearUserData,
  exportTransactions,
  importTransactions,
} from './import';
// Export investment data functions
export {
  clearInvestmentCache,
  fetchETFData,
  fetchMutualFundData,
  fetchStockData,
  fetchStockHistory,
  getInvestmentsSummary,
} from './investments';
// Export Pub/Sub and scheduled functions
export {
  processBudgetAlerts,
  processDataExportComplete,
  processScheduledReports,
  processTransactionInsights,
  scheduledBudgetCheck,
} from './pubsub';
// Export report functions
export { generateReport, getDashboardAnalytics } from './reports';
// Export transaction functions
export {
  createTransaction,
  deleteTransaction,
  getTransactionStats,
  updateTransaction,
} from './transactions';
