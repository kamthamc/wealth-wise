// Local Storage Interfaces for WealthWise App
// These interfaces define the contracts for local data operations across all platforms
// No backend services - everything is stored locally with optional cloud backup

import { 
    Transaction, TransactionType, TransactionCategory,
    Account, AccountType,
    Budget, BudgetType, BudgetPeriod,
    Asset, AssetType, AssetDocument,
    Loan, LoanType, LoanStatus,
    Investment, InvestmentType,
    ReportTemplate,
    UserProfile,
    AppSettings
} from '../models/core-models';

// MARK: - Local Storage Interfaces

export interface ILocalStorageManager {
    // Generic storage operations
    save<T>(key: string, data: T): Promise<boolean>;
    load<T>(key: string): Promise<T | null>;
    delete(key: string): Promise<boolean>;
    exists(key: string): Promise<boolean>;
    clear(): Promise<boolean>;
    
    // Encrypted storage for sensitive data
    saveSecure<T>(key: string, data: T): Promise<boolean>;
    loadSecure<T>(key: string): Promise<T | null>;
    deleteSecure(key: string): Promise<boolean>;
}

export interface ITransactionRepository {
    // CRUD operations
    create(transaction: Omit<Transaction, 'id' | 'createdAt' | 'updatedAt'>): Promise<Transaction>;
    findAll(accountId?: string, limit?: number, offset?: number): Promise<Transaction[]>;
    findById(id: string): Promise<Transaction | null>;
    update(id: string, updates: Partial<Transaction>): Promise<Transaction>;
    delete(id: string): Promise<boolean>;
    
    // Import operations
    importFromCSV(csvContent: string, accountId: string, mapping: CSVColumnMapping): Promise<ImportResult>;
    parseFromText(text: string, accountId: string): Promise<Transaction | null>;
    
    // Local ML categorization (when available)
    categorizeTransaction(transaction: Transaction): Promise<{ category: TransactionCategory; confidence: number }>;
    updateCategoryConfidence(transactionId: string, isCorrect: boolean): Promise<void>;
    
    // Linking and relationships
    linkTransactions(transactionIds: string[]): Promise<boolean>;
    unlinkTransaction(transactionId: string): Promise<boolean>;
    getLinkedTransactions(transactionId: string): Promise<Transaction[]>;
    
    // Duplicate detection
    findDuplicates(transaction: Transaction): Promise<Transaction[]>;
    mergeDuplicates(primaryId: string, duplicateIds: string[]): Promise<Transaction>;
    
    // Search and filtering
    search(query: SearchQuery): Promise<Transaction[]>;
    findByDateRange(startDate: Date, endDate: Date, accountId?: string): Promise<Transaction[]>;
    findByCategory(category: TransactionCategory, accountId?: string): Promise<Transaction[]>;
    
    // Bulk operations
    bulkUpdateCategory(transactionIds: string[], category: TransactionCategory): Promise<boolean>;
    bulkDelete(transactionIds: string[]): Promise<boolean>;
}

export interface CSVColumnMapping {
    dateColumn: string;
    amountColumn: string;
    descriptionColumn: string;
    categoryColumn?: string;
    merchantColumn?: string;
    referenceColumn?: string;
    dateFormat: string;
    hasHeader: boolean;
}

export interface ImportResult {
    totalRecords: number;
    successfulImports: number;
    failedImports: number;
    duplicatesSkipped: number;
    errors: ImportError[];
    importedTransactions: Transaction[];
}

export interface ImportError {
    row: number;
    column?: string;
    error: string;
    data: any;
}

export interface SearchQuery {
    text?: string;
    categories?: TransactionCategory[];
    accounts?: string[];
    startDate?: Date;
    endDate?: Date;
    minAmount?: number;
    maxAmount?: number;
    transactionTypes?: TransactionType[];
    tags?: string[];
    sortBy?: 'date' | 'amount' | 'description';
    sortOrder?: 'asc' | 'desc';
    limit?: number;
    offset?: number;
}

// MARK: - Account Repository Interface

export interface IAccountRepository {
    // CRUD operations
    create(account: Omit<Account, 'id' | 'createdAt' | 'updatedAt'>): Promise<Account>;
    findAll(type?: AccountType): Promise<Account[]>;
    findById(id: string): Promise<Account | null>;
    update(id: string, updates: Partial<Account>): Promise<Account>;
    delete(id: string): Promise<boolean>;
    
    // Balance operations
    updateBalance(accountId: string, newBalance: number): Promise<Account>;
    calculateBalance(accountId: string): Promise<number>;
    getBalanceHistory(accountId: string, period: '1M' | '3M' | '6M' | '1Y'): Promise<BalanceHistoryPoint[]>;
    
    // Account management
    activate(accountId: string): Promise<Account>;
    deactivate(accountId: string): Promise<Account>;
    
    // Aggregation
    getTotalBalance(accountTypes?: AccountType[]): Promise<number>;
    getNetWorth(): Promise<NetWorthSummary>;
    getSummary(): Promise<AccountSummary[]>;
}

export interface BalanceHistoryPoint {
    date: Date;
    balance: number;
}

export interface BackupResult {
    success: boolean;
    lastBackupTime: Date;
    recordsBackedUp: number;
    errors: string[];
}

export interface NetWorthSummary {
    totalAssets: number;
    totalLiabilities: number;
    netWorth: number;
    lastCalculated: Date;
    breakdown: {
        liquid: number;
        investments: number;
        fixedAssets: number;
        loans: number;
        creditCards: number;
    };
}

export interface AccountSummary {
    accountId: string;
    accountName: string;
    accountType: AccountType;
    balance: number;
    currency: string;
    lastTransaction?: Date;
    monthlyChange: number;
    monthlyChangePercentage: number;
}

// MARK: - Budget Repository Interface

export interface IBudgetRepository {
    // CRUD operations
    create(budget: Omit<Budget, 'id' | 'createdAt' | 'updatedAt'>): Promise<Budget>;
    findAll(isActive?: boolean): Promise<Budget[]>;
    findById(id: string): Promise<Budget | null>;
    update(id: string, updates: Partial<Budget>): Promise<Budget>;
    delete(id: string): Promise<boolean>;
    
    // Budget tracking
    calculateProgress(budgetId: string): Promise<BudgetProgress>;
    getAlerts(): Promise<BudgetAlert[]>;
    checkThresholds(budgetId: string): Promise<BudgetAlert[]>;
    
    // Budget analysis
    getPerformance(budgetId: string, comparisonPeriod?: 'previous_month' | 'previous_year'): Promise<BudgetPerformance>;
    suggestAdjustments(budgetId: string): Promise<BudgetSuggestion[]>;
    
    // Template and automation
    createFromTemplate(templateName: string, customizations?: Partial<Budget>): Promise<Budget>;
    getTemplates(): Promise<BudgetTemplate[]>;
    generateAutoBudget(accountIds: string[], period: BudgetPeriod): Promise<Budget>;
}

export interface BudgetProgress {
    budgetId: string;
    totalBudget: number;
    spentAmount: number;
    remainingAmount: number;
    percentageUsed: number;
    daysRemaining: number;
    averageDailySpend: number;
    projectedSpend: number;
    isOnTrack: boolean;
    categoryBreakdown: CategorySpending[];
}

export interface CategorySpending {
    category: TransactionCategory;
    budgeted: number;
    spent: number;
    remaining: number;
    percentageUsed: number;
}

export interface BudgetAlert {
    budgetId: string;
    budgetName: string;
    alertType: 'threshold_reached' | 'budget_exceeded' | 'projected_overspend';
    message: string;
    severity: 'info' | 'warning' | 'critical';
    threshold?: number;
    currentSpend: number;
    createdAt: Date;
}

export interface BudgetPerformance {
    currentPeriod: BudgetProgress;
    comparisonPeriod?: BudgetProgress;
    improvement: number; // Percentage change
    insights: string[];
}

export interface BudgetSuggestion {
    type: 'increase' | 'decrease' | 'reallocate';
    category?: TransactionCategory;
    currentAmount: number;
    suggestedAmount: number;
    reason: string;
    confidence: number;
}

export interface BudgetTemplate {
    name: string;
    description: string;
    categories: { category: TransactionCategory; percentage: number }[];
    period: BudgetPeriod;
    isDefault: boolean;
}

// MARK: - Asset Repository Interface

export interface IAssetRepository {
    // CRUD operations
    create(asset: Omit<Asset, 'id' | 'createdAt' | 'updatedAt'>): Promise<Asset>;
    findAll(type?: AssetType): Promise<Asset[]>;
    findById(id: string): Promise<Asset | null>;
    update(id: string, updates: Partial<Asset>): Promise<Asset>;
    delete(id: string): Promise<boolean>;
    
    // Valuation
    updateValuation(assetId: string, newValue: number, valuationDate?: Date): Promise<Asset>;
    getValuationHistory(assetId: string): Promise<ValuationPoint[]>;
    calculateDepreciatedValue(assetId: string, asOfDate?: Date): Promise<number>;
    
    // Portfolio management
    getPortfolio(): Promise<AssetPortfolio>;
    getAllocation(): Promise<AssetAllocation[]>;
    getTotalValue(assetTypes?: AssetType[]): Promise<number>;
    
    // Documentation
    addDocument(assetId: string, document: Omit<AssetDocument, 'id' | 'uploadDate'>): Promise<Asset>;
    removeDocument(assetId: string, documentId: string): Promise<Asset>;
    
    // Analytics
    getAppreciation(assetId: string, period: '1M' | '6M' | '1Y' | 'ALL'): Promise<AppreciationAnalysis>;
    comparePerformance(assetIds: string[]): Promise<AssetComparison[]>;
}

export interface ValuationPoint {
    date: Date;
    value: number;
    source: 'manual' | 'automatic' | 'market';
}

export interface AssetPortfolio {
    totalValue: number;
    totalAppreciation: number;
    totalAppreciationPercentage: number;
    assetsByType: { type: AssetType; value: number; count: number }[];
    topPerformers: Asset[];
    underPerformers: Asset[];
}

export interface AssetAllocation {
    type: AssetType;
    value: number;
    percentage: number;
    count: number;
}

export interface AppreciationAnalysis {
    assetId: string;
    purchaseValue: number;
    currentValue: number;
    totalAppreciation: number;
    totalAppreciationPercentage: number;
    annualizedReturn: number;
    volatility: number;
    bestMonth: { date: string; return: number };
    worstMonth: { date: string; return: number };
}

export interface AssetComparison {
    assetId: string;
    assetName: string;
    totalReturn: number;
    totalReturnPercentage: number;
    annualizedReturn: number;
    riskRating: 'low' | 'medium' | 'high';
}

// MARK: - Loan Repository Interface

export interface ILoanRepository {
    // CRUD operations
    create(loan: Omit<Loan, 'id' | 'createdAt' | 'updatedAt'>): Promise<Loan>;
    findAll(status?: LoanStatus): Promise<Loan[]>;
    findById(id: string): Promise<Loan | null>;
    update(id: string, updates: Partial<Loan>): Promise<Loan>;
    delete(id: string): Promise<boolean>;
    
    // Payment tracking
    recordPayment(loanId: string, amount: number, paymentDate: Date, transactionId?: string): Promise<LoanPayment>;
    getPaymentHistory(loanId: string): Promise<LoanPayment[]>;
    getUpcomingPayments(daysAhead?: number): Promise<UpcomingPayment[]>;
    
    // Calculations
    calculateEMI(principal: number, interestRate: number, tenure: number): Promise<number>;
    calculateSummary(loanId: string): Promise<LoanSummary>;
    calculatePrepaymentSavings(loanId: string, prepaymentAmount: number): Promise<PrepaymentAnalysis>;
    
    // Analytics
    getTotalLiability(): Promise<number>;
    getPortfolio(): Promise<LoanPortfolio>;
    getAmortizationSchedule(loanId: string): Promise<AmortizationEntry[]>;
}

export interface LoanPayment {
    id: string;
    loanId: string;
    amount: number;
    principalAmount: number;
    interestAmount: number;
    penaltyAmount: number;
    paymentDate: Date;
    transactionId?: string;
    remainingBalance: number;
}

export interface UpcomingPayment {
    loanId: string;
    loanName: string;
    amount: number;
    dueDate: Date;
    daysUntilDue: number;
    isOverdue: boolean;
}

export interface LoanSummary {
    loanId: string;
    totalPaidAmount: number;
    principalPaid: number;
    interestPaid: number;
    remainingPrincipal: number;
    remainingInterest: number;
    paymentsRemaining: number;
    paymentsMade: number;
    nextPaymentDate: Date;
    payoffDate: Date;
}

export interface PrepaymentAnalysis {
    currentEMI: number;
    newEMI: number;
    currentTenure: number;
    newTenure: number;
    interestSavings: number;
    timeReduction: number; // Months
    prepaymentPenalty: number;
    netSavings: number;
}

export interface LoanPortfolio {
    totalOutstanding: number;
    totalMonthlyEMI: number;
    loansByType: { type: LoanType; amount: number; count: number }[];
    averageInterestRate: number;
    totalInterestPaid: number;
    totalPrincipalPaid: number;
}

export interface AmortizationEntry {
    paymentNumber: number;
    paymentDate: Date;
    beginningBalance: number;
    paymentAmount: number;
    principalAmount: number;
    interestAmount: number;
    endingBalance: number;
    cumulativeInterest: number;
}

// MARK: - Investment Repository Interface

export interface IInvestmentRepository {
    // CRUD operations
    create(investment: Omit<Investment, 'id' | 'createdAt' | 'updatedAt'>): Promise<Investment>;
    findAll(type?: InvestmentType): Promise<Investment[]>;
    findById(id: string): Promise<Investment | null>;
    update(id: string, updates: Partial<Investment>): Promise<Investment>;
    delete(id: string): Promise<boolean>;
    
    // Price updates (manual only - no external sync)
    updatePrice(investmentId: string, newPrice: number): Promise<Investment>;
    
    // Portfolio management
    getPortfolio(): Promise<InvestmentPortfolio>;
    getAllocation(): Promise<InvestmentAllocation[]>;
    calculatePerformance(period: '1D' | '1M' | '3M' | '6M' | '1Y' | 'ALL'): Promise<PortfolioPerformance>;
    
    // Analytics
    getTopPerformers(limit?: number): Promise<Investment[]>;
    getWorstPerformers(limit?: number): Promise<Investment[]>;
    getDiversificationAnalysis(): Promise<DiversificationAnalysis>;
    
    // Goal tracking
    trackGoal(goalId: string): Promise<InvestmentGoalProgress>;
}



export interface InvestmentPortfolio {
    totalValue: number;
    totalInvested: number;
    totalReturn: number;
    totalReturnPercentage: number;
    dayReturn: number;
    dayReturnPercentage: number;
    investmentsByType: { type: InvestmentType; value: number; count: number }[];
}

export interface InvestmentAllocation {
    type: InvestmentType;
    value: number;
    percentage: number;
    return: number;
    returnPercentage: number;
}

export interface PortfolioPerformance {
    startValue: number;
    endValue: number;
    totalReturn: number;
    totalReturnPercentage: number;
    annualizedReturn: number;
    volatility: number;
    sharpeRatio: number;
    benchmarkComparison?: {
        benchmarkName: string;
        benchmarkReturn: number;
        outperformance: number;
    };
}

export interface DiversificationAnalysis {
    concentrationRisk: 'low' | 'medium' | 'high';
    largestHolding: { name: string; percentage: number };
    top5Holdings: { name: string; percentage: number }[];
    sectorAllocation: { sector: string; percentage: number }[];
    geographicAllocation: { region: string; percentage: number }[];
    suggestions: string[];
}

export interface InvestmentGoalProgress {
    goalId: string;
    targetAmount: number;
    currentValue: number;
    progress: number;
    monthsRemaining: number;
    requiredMonthlyInvestment: number;
    isOnTrack: boolean;
}

// MARK: - Report Generator Interface

export interface IReportGenerator {
    // Template management
    getTemplates(category?: string): Promise<ReportTemplate[]>;
    createCustomTemplate(template: Omit<ReportTemplate, 'id' | 'createdAt' | 'updatedAt'>): Promise<ReportTemplate>;
    updateTemplate(id: string, updates: Partial<ReportTemplate>): Promise<ReportTemplate>;
    deleteTemplate(id: string): Promise<boolean>;
    
    // Report generation
    generate(templateId: string, parameters?: ReportParameters): Promise<ReportData>;
    generateIncomeStatement(startDate: Date, endDate: Date): Promise<IncomeStatement>;
    generateBalanceSheet(asOfDate: Date): Promise<BalanceSheet>;
    generateCashFlow(startDate: Date, endDate: Date): Promise<CashFlowStatement>;
    generateNetWorthReport(period: '1M' | '3M' | '6M' | '1Y'): Promise<NetWorthReport>;
    generateTaxReport(financialYear: string): Promise<TaxReport>;
    
    // Export functionality
    exportReport(reportData: ReportData, format: 'pdf' | 'excel' | 'csv'): Promise<ExportResult>;
    
    // Scheduled reports
    scheduleReport(templateId: string, schedule: ReportSchedule): Promise<ScheduledReport>;
    getScheduledReports(): Promise<ScheduledReport[]>;
}

export interface ReportParameters {
    startDate?: Date;
    endDate?: Date;
    accountIds?: string[];
    categories?: TransactionCategory[];
    comparisonPeriod?: boolean;
    includeProjections?: boolean;
}

export interface ReportData {
    templateId: string;
    templateName: string;
    generatedAt: Date;
    parameters: ReportParameters;
    data: any;
    charts: ChartData[];
    summary: ReportSummary;
}

export interface ChartData {
    type: 'line' | 'bar' | 'pie' | 'area';
    title: string;
    data: any[];
    xAxis?: string;
    yAxis?: string;
}

export interface ReportSummary {
    keyMetrics: { name: string; value: number; change?: number }[];
    insights: string[];
    recommendations: string[];
}

export interface IncomeStatement {
    period: { startDate: Date; endDate: Date };
    revenue: { category: string; amount: number }[];
    expenses: { category: string; amount: number }[];
    totalRevenue: number;
    totalExpenses: number;
    netIncome: number;
    previousPeriodComparison?: {
        revenueChange: number;
        expenseChange: number;
        netIncomeChange: number;
    };
}

export interface BalanceSheet {
    asOfDate: Date;
    assets: {
        liquid: { name: string; amount: number }[];
        investments: { name: string; amount: number }[];
        fixedAssets: { name: string; amount: number }[];
        totalAssets: number;
    };
    liabilities: {
        loans: { name: string; amount: number }[];
        creditCards: { name: string; amount: number }[];
        otherLiabilities: { name: string; amount: number }[];
        totalLiabilities: number;
    };
    netWorth: number;
}

export interface CashFlowStatement {
    period: { startDate: Date; endDate: Date };
    operatingCashFlow: { category: string; amount: number }[];
    investingCashFlow: { category: string; amount: number }[];
    financingCashFlow: { category: string; amount: number }[];
    netCashFlow: number;
    beginningCash: number;
    endingCash: number;
}

export interface NetWorthReport {
    period: string;
    startNetWorth: number;
    endNetWorth: number;
    change: number;
    changePercentage: number;
    assetBreakdown: { category: string; value: number; percentage: number }[];
    liabilityBreakdown: { category: string; value: number; percentage: number }[];
    monthlyTrend: { month: string; netWorth: number }[];
}

export interface TaxReport {
    financialYear: string;
    taxableIncome: number;
    deductions: { section: string; amount: number; description: string }[];
    capitalGains: {
        shortTerm: { investment: string; gain: number }[];
        longTerm: { investment: string; gain: number }[];
    };
    taxLiability: number;
    taxPaid: number;
    refundDue: number;
}

export interface ExportResult {
    success: boolean;
    filePath?: string;
    downloadUrl?: string;
    error?: string;
}

export interface ReportSchedule {
    frequency: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly';
    dayOfWeek?: number; // 0-6 for weekly
    dayOfMonth?: number; // 1-31 for monthly
    recipients: string[];
    format: 'pdf' | 'excel';
    isActive: boolean;
}

export interface ScheduledReport {
    id: string;
    templateId: string;
    schedule: ReportSchedule;
    lastRun?: Date;
    nextRun: Date;
    runCount: number;
    createdAt: Date;
}

// MARK: - Backup Service Interface

export interface IBackupService {
    // Local backup and restore
    createBackup(): Promise<BackupResult>;
    restoreFromBackup(backupId: string): Promise<RestoreResult>;
    getBackupHistory(): Promise<BackupInfo[]>;
    deleteBackup(backupId: string): Promise<boolean>;
    
    // Optional cloud backup (iCloud/Google Drive)
    backupToCloud(): Promise<BackupResult>;
    restoreFromCloud(): Promise<RestoreResult>;
    getCloudBackups(): Promise<BackupInfo[]>;
    
    // Export/Import
    exportData(format: 'json' | 'csv'): Promise<ExportResult>;
    importData(data: string, format: 'json' | 'csv'): Promise<ImportResult>;
    
    // Conflict resolution for cloud imports
    getConflicts(): Promise<DataConflict[]>;
    resolveConflict(conflictId: string, resolution: DataConflictResolution): Promise<boolean>;
}

export interface BackupStatus {
    lastBackup: Date | null;
    nextScheduledBackup: Date | null;
    backupInProgress: boolean;
    cloudBackupEnabled: boolean;
    autoBackupEnabled: boolean;
}

export interface DataConflict {
    id: string;
    entityType: string;
    entityId: string;
    localVersion: any;
    remoteVersion: any;
    conflictDate: Date;
}

export interface DataConflictResolution {
    strategy: 'use_local' | 'use_cloud' | 'merge' | 'custom';
    customData?: any;
}

export interface BackupResult {
    backupId: string;
    size: number;
    createdAt: Date;
    recordCount: number;
    success: boolean;
}

export interface RestoreResult {
    success: boolean;
    recordsRestored: number;
    errors: string[];
}

export interface BackupInfo {
    id: string;
    size: number;
    createdAt: Date;
    recordCount: number;
    deviceName: string;
}

