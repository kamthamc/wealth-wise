// Core Data Models for Unified Banking App
// These models define the structure for financial data across all platforms

// MARK: - Account Models

/**
 * Account Type enumeration covering all supported financial institutions
 */
export enum AccountType {
    // Banking
    SAVINGS = "savings",
    CURRENT = "current",
    SALARY = "salary",
    OVERDRAFT = "overdraft",
    
    // Credit
    CREDIT_CARD = "credit_card",
    CHARGE_CARD = "charge_card",
    
    // Digital Payments
    UPI = "upi",
    WALLET = "wallet",
    PREPAID_CARD = "prepaid_card",
    
    // Investments
    DEMAT = "demat",
    TRADING = "trading",
    MUTUAL_FUND = "mutual_fund",
    PF = "provident_fund",
    PPF = "ppf",
    NSC = "nsc",
    
    // Loans
    HOME_LOAN = "home_loan",
    PERSONAL_LOAN = "personal_loan",
    CAR_LOAN = "car_loan",
    EDUCATION_LOAN = "education_loan",
    GOLD_LOAN = "gold_loan",
    
    // Other
    CASH = "cash",
    OFFLINE_ASSET = "offline_asset"
}

export interface Account {
    id: string;
    name: string;
    accountType: AccountType;
    institutionName: string;
    accountNumber?: string;
    currentBalance: number;
    currency: string;
    isActive: boolean;
    lastSynced?: Date;
    createdAt: Date;
    updatedAt: Date;
}

// MARK: - Transaction Models

export enum TransactionType {
    INCOME = "income",
    EXPENSE = "expense",
    TRANSFER = "transfer",
    INVESTMENT = "investment",
    WITHDRAWAL = "withdrawal",
    DEPOSIT = "deposit",
    REFUND = "refund",
    FEE = "fee",
    INTEREST = "interest",
    DIVIDEND = "dividend",
    BONUS = "bonus",
    PENALTY = "penalty"
}

export enum TransactionCategory {
    // Income Categories
    SALARY = "salary",
    FREELANCE = "freelance",
    BUSINESS = "business",
    INVESTMENT_RETURN = "investment_return",
    RENTAL_INCOME = "rental_income",
    OTHER_INCOME = "other_income",
    
    // Expense Categories
    FOOD_DINING = "food_dining",
    GROCERIES = "groceries",
    TRANSPORTATION = "transportation",
    FUEL = "fuel",
    UTILITIES = "utilities",
    RENT = "rent",
    MEDICAL = "medical",
    INSURANCE = "insurance",
    EDUCATION = "education",
    ENTERTAINMENT = "entertainment",
    SHOPPING = "shopping",
    TRAVEL = "travel",
    PERSONAL_CARE = "personal_care",
    GIFTS_DONATIONS = "gifts_donations",
    TAXES = "taxes",
    BANK_FEES = "bank_fees",
    LOAN_PAYMENT = "loan_payment",
    INVESTMENT_PURCHASE = "investment_purchase",
    OTHER_EXPENSE = "other_expense",
    
    // Transfer Categories
    INTERNAL_TRANSFER = "internal_transfer",
    EXTERNAL_TRANSFER = "external_transfer",
    UPI_TRANSFER = "upi_transfer",
    WALLET_TRANSFER = "wallet_transfer"
}

export interface Transaction {
    id: string;
    accountId: string;
    amount: number;
    currency: string;
    transactionType: TransactionType;
    category: TransactionCategory;
    subcategory?: string;
    description: string;
    merchantName?: string;
    location?: string;
    transactionDate: Date;
    processedDate?: Date;
    
    // Reference and linking
    referenceNumber?: string;
    linkedTransactionId?: string; // For transfers between accounts
    linkedTransactionIds?: string[]; // For split transactions
    
    // Additional metadata
    tags?: string[];
    notes?: string;
    receipt?: string; // File path or URL
    isRecurring: boolean;
    recurringGroupId?: string;
    
    // Classification confidence (for ML categorization)
    categoryConfidence?: number;
    isManuallyVerified: boolean;
    
    // Sync and audit
    syncStatus: 'synced' | 'pending' | 'conflict';
    createdAt: Date;
    updatedAt: Date;
    importSource?: 'manual' | 'csv' | 'bank_api' | 'sms' | 'email';
}

// MARK: - Budget Models

export enum BudgetType {
    MONTHLY = "monthly",
    WEEKLY = "weekly",
    YEARLY = "yearly",
    EVENT_BASED = "event_based",
    PROJECT_BASED = "project_based"
}

export enum BudgetPeriod {
    WEEKLY = "weekly",
    MONTHLY = "monthly",
    QUARTERLY = "quarterly",
    YEARLY = "yearly",
    CUSTOM = "custom"
}

export interface Budget {
    id: string;
    name: string;
    budgetType: BudgetType;
    period: BudgetPeriod;
    startDate: Date;
    endDate?: Date;
    
    // Budget amounts
    totalBudget: number;
    spentAmount: number;
    remainingAmount: number;
    currency: string;
    
    // Categories included in this budget
    includedCategories: TransactionCategory[];
    excludedCategories?: TransactionCategory[];
    includedAccounts?: string[]; // Account IDs
    
    // Alerts and notifications
    alertThresholds: number[]; // Percentage thresholds (e.g., [50, 75, 90])
    isAlertEnabled: boolean;
    
    // Rollover settings
    allowRollover: boolean;
    rolloverAmount?: number;
    
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}

// MARK: - Asset Models

export enum AssetType {
    REAL_ESTATE = "real_estate",
    GOLD = "gold",
    SILVER = "silver",
    JEWELRY = "jewelry",
    VEHICLE = "vehicle",
    ELECTRONICS = "electronics",
    ARTWORK = "artwork",
    COLLECTIBLES = "collectibles",
    BONDS = "bonds",
    FIXED_DEPOSIT = "fixed_deposit",
    INSURANCE_POLICY = "insurance_policy",
    OTHER = "other"
}

export interface Asset {
    id: string;
    name: string;
    assetType: AssetType;
    description?: string;
    
    // Valuation
    purchaseValue: number;
    currentValue: number;
    valuationDate: Date;
    currency: string;
    
    // Purchase details
    purchaseDate: Date;
    purchaseLocation?: string;
    vendor?: string;
    
    // Physical details
    quantity: number;
    unit: string; // e.g., "grams", "pieces", "sq ft"
    
    // Documentation
    documents: AssetDocument[];
    photos: string[]; // File paths or URLs
    
    // Insurance and warranty
    isInsured: boolean;
    insuranceProvider?: string;
    insuranceValue?: number;
    insuranceExpiryDate?: Date;
    warrantyExpiryDate?: Date;
    
    // Depreciation (for items like vehicles, electronics)
    depreciationRate?: number; // Annual percentage
    estimatedLifespan?: number; // Years
    
    tags?: string[];
    notes?: string;
    
    createdAt: Date;
    updatedAt: Date;
}

export interface AssetDocument {
    id: string;
    type: 'receipt' | 'certificate' | 'warranty' | 'insurance' | 'valuation' | 'other';
    fileName: string;
    filePath: string;
    uploadDate: Date;
    description?: string;
}

// MARK: - Loan Models

export enum LoanType {
    HOME_LOAN = "home_loan",
    PERSONAL_LOAN = "personal_loan",
    CAR_LOAN = "car_loan",
    EDUCATION_LOAN = "education_loan",
    GOLD_LOAN = "gold_loan",
    BUSINESS_LOAN = "business_loan",
    CREDIT_CARD_DEBT = "credit_card_debt",
    LENDING_TO_OTHERS = "lending_to_others",
    OTHER = "other"
}

export enum LoanStatus {
    ACTIVE = "active",
    PAID_OFF = "paid_off",
    DEFAULTED = "defaulted",
    PREPAID = "prepaid",
    RESTRUCTURED = "restructured"
}

export interface Loan {
    id: string;
    name: string;
    loanType: LoanType;
    lenderName: string;
    
    // Loan details
    principalAmount: number;
    currentOutstanding: number;
    interestRate: number; // Annual percentage
    tenure: number; // Months
    
    // EMI details
    emiAmount: number;
    startDate: Date;
    endDate: Date;
    nextEmiDate?: Date;
    
    // Payment tracking
    totalPaidAmount: number;
    principalPaid: number;
    interestPaid: number;
    penaltyPaid: number;
    
    // Status and metadata
    status: LoanStatus;
    accountId?: string; // Associated account for payments
    loanAccountNumber?: string;
    
    // Documents and notes
    documents: AssetDocument[];
    notes?: string;
    
    // Prepayment options
    allowPrepayment: boolean;
    prepaymentPenalty?: number; // Percentage
    
    createdAt: Date;
    updatedAt: Date;
}

// MARK: - Investment Models

export enum InvestmentType {
    MUTUAL_FUND = "mutual_fund",
    STOCK = "stock",
    BOND = "bond",
    ETF = "etf",
    FD = "fixed_deposit",
    RD = "recurring_deposit",
    PPF = "ppf",
    NSC = "nsc",
    ELSS = "elss",
    NPS = "nps",
    CRYPTOCURRENCY = "cryptocurrency",
    COMMODITY = "commodity",
    OTHER = "other"
}

export interface Investment {
    id: string;
    name: string;
    investmentType: InvestmentType;
    symbol?: string; // Stock symbol, mutual fund code, etc.
    
    // Investment details
    totalInvested: number;
    currentValue: number;
    quantity: number;
    averagePrice: number;
    currentPrice: number;
    
    // Performance
    totalReturn: number;
    totalReturnPercentage: number;
    dayReturn?: number;
    dayReturnPercentage?: number;
    
    // Dates
    firstInvestmentDate: Date;
    lastInvestmentDate?: Date;
    maturityDate?: Date;
    
    // Account association
    accountId?: string;
    brokerName?: string;
    
    // Additional metadata
    isinCode?: string;
    riskLevel?: 'low' | 'medium' | 'high';
    category?: string;
    subcategory?: string;
    
    // Tax implications
    taxCategory?: 'equity' | 'debt' | 'hybrid';
    lockInPeriod?: number; // Months
    
    createdAt: Date;
    updatedAt: Date;
}

// MARK: - Report Models

export interface ReportTemplate {
    id: string;
    name: string;
    description?: string;
    category: 'income' | 'expense' | 'budget' | 'investment' | 'net_worth' | 'tax' | 'custom';
    
    // Report configuration
    dateRange: {
        type: 'last_7_days' | 'last_30_days' | 'last_3_months' | 'last_6_months' | 'last_year' | 'current_month' | 'current_year' | 'financial_year' | 'custom';
        startDate?: Date;
        endDate?: Date;
    };
    
    // Filters
    includedAccounts?: string[];
    includedCategories?: TransactionCategory[];
    groupBy: 'day' | 'week' | 'month' | 'quarter' | 'year' | 'category' | 'account';
    
    // Visualization preferences
    chartType: 'line' | 'bar' | 'pie' | 'area' | 'table';
    showComparison: boolean;
    comparisonPeriod?: 'previous_period' | 'previous_year';
    
    isCustom: boolean;
    isDefault: boolean;
    
    createdAt: Date;
    updatedAt: Date;
}

// MARK: - User and Settings Models

export interface UserProfile {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    currency: string;
    timezone: string;
    locale: string;
    
    // Financial year settings (important for Indian users)
    financialYearStart: Date; // April 1st for India
    
    // Subscription
    subscriptionTier: 'free' | 'premium' | 'family';
    subscriptionExpiryDate?: Date;
    
    // Privacy settings
    biometricEnabled: boolean;
    cloudSyncEnabled: boolean;
    analyticsEnabled: boolean;
    
    createdAt: Date;
    updatedAt: Date;
}

export interface AppSettings {
    // Display preferences
    theme: 'light' | 'dark' | 'system';
    language: string;
    
    // Notification preferences
    budgetAlerts: boolean;
    transactionAlerts: boolean;
    billReminders: boolean;
    
    // Security settings
    autoLockTimeout: number; // Minutes
    requireBiometricForTransactions: boolean;
    
    // Data preferences
    autoCategorizationEnabled: boolean;
    duplicateTransactionThreshold: number; // Hours
    defaultTransactionDescription: string;
    
    // Sync settings
    autoSyncInterval: number; // Minutes
    syncOnWifiOnly: boolean;
    
    // Export settings
    defaultExportFormat: 'csv' | 'excel' | 'pdf';
    includeCurrencyInExport: boolean;
}

// MARK: - Sync and Conflict Resolution Models

export interface SyncMetadata {
    entityId: string;
    entityType: string;
    lastModified: Date;
    version: number;
    checksum: string;
    deviceId: string;
}

export interface DataConflictResolution {
    conflictId: string;
    userId: string;
    conflictType: 'account_balance' | 'transaction_duplicate' | 'data_mismatch';
    localValue: any;
    remoteValue: any;
    resolution: 'use_local' | 'use_remote' | 'merge' | 'manual';
    resolvedAt: Date;
}