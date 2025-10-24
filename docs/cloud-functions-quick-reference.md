# Cloud Functions Quick Reference

## 📋 All 48 Cloud Functions

### Budgets (4)
```typescript
createBudget(data: BudgetData) → Budget
updateBudget(budgetId, updates) → Budget
deleteBudget(budgetId) → { success: boolean }
calculateBudgetProgress(budgetId) → BudgetProgress
```

### Accounts (4)
```typescript
createAccount(data: AccountData) → Account
updateAccount(accountId, updates) → Account
deleteAccount(accountId) → { success: boolean }
calculateAccountBalance(accountId) → { balance: number }
```

### Transactions (4)
```typescript
createTransaction(data: TransactionData) → Transaction
updateTransaction(transactionId, updates) → Transaction
deleteTransaction(transactionId) → { success: boolean }
getTransactionStats(params) → TransactionStats
```

### Goals (5) 🆕
```typescript
createGoal(data: GoalData) → Goal
updateGoal(goalId, updates) → Goal
deleteGoal(goalId) → { success: boolean }
calculateGoalProgress(goalId) → GoalProgress
addGoalContribution(goalId, amount, date?, notes?) → Contribution
```

### Reports (2)
```typescript
generateReport(params) → Report
getDashboardAnalytics() → Analytics
```

### Duplicates (2)
```typescript
checkDuplicateTransaction(transaction) → { isDuplicate: boolean }
batchCheckDuplicates(transactions) → DuplicateCheckResult[]
```

### Deposits (5)
```typescript
calculateFDMaturity(principal, rate, tenure) → FDResult
calculateRDMaturity(monthlyDeposit, rate, tenure) → RDResult
calculatePPFMaturity(yearlyDeposit, tenure) → PPFResult
calculateSavingsInterest(balance, rate, days) → SavingsResult
getDepositAccountDetails(accountId) → DepositDetails
```

### Data Export (3)
```typescript
exportUserData(format?, includeDeleted?) → ExportData
importUserData(data) → ImportResult
getUserStatistics() → UserStats
```

### Import/Export (4) 🆕
```typescript
importTransactions(transactions[], accountId, detectDuplicates?) → ImportResult
batchImportTransactions(transactions[], accountId, chunkSize?) → BatchResult
exportTransactions(filters?) → ExportData
clearUserData(confirmation, collections?) → ClearResult
```

### Dashboard (4) 🆕
```typescript
computeAndCacheDashboard(forceRefresh?, cacheTTL?) → DashboardData
getAccountSummary(accountId) → AccountSummary
getTransactionSummary(startDate?, endDate?, groupBy?) → TransactionSummary
invalidateDashboardCache() → { success: boolean }
```

### Investments (6) 🆕
```typescript
fetchStockData(symbol, forceRefresh?) → StockData
fetchStockHistory(symbol, interval?, outputSize?) → StockHistory
fetchMutualFundData(isin, forceRefresh?) → MutualFundData
fetchETFData(symbol, forceRefresh?) → ETFData
getInvestmentsSummary() → PortfolioSummary
clearInvestmentCache(type?) → { success: boolean }
```

### Pub/Sub (5)
```typescript
processBudgetAlerts(message) → void
processTransactionInsights(message) → void
processScheduledReports(message) → void
processDataExportComplete(message) → void
scheduledBudgetCheck() → void (cron: daily 9 AM)
```

---

## 🚀 Frontend API Usage

### Goals
```typescript
import { goalsApi } from '@/core/api/goalsApi';

// Create
const goal = await goalsApi.createGoal({
  name: 'Emergency Fund',
  target_amount: 500000,
  target_date: '2025-12-31',
});

// Add contribution
await goalsApi.addGoalContribution(goal.id, 10000);

// Check progress
const progress = await goalsApi.calculateGoalProgress(goal.id);
```

### Import/Export
```typescript
import { importApi } from '@/core/api/importApi';

// Import
const result = await importApi.importTransactions(
  parsedTransactions,
  accountId,
  true // detectDuplicates
);

// Export
const csv = await importApi.exportTransactions({
  startDate: '2025-01-01',
  format: 'csv',
});

// Clear all data (destructive!)
await importApi.clearUserData('DELETE_ALL_MY_DATA', ['transactions']);
```

### Dashboard
```typescript
import { dashboardApi } from '@/core/api/dashboardApi';

// Get cached dashboard
const dashboard = await dashboardApi.computeAndCacheDashboard();

// Force refresh
const fresh = await dashboardApi.computeAndCacheDashboard({
  forceRefresh: true,
});

// Account details
const account = await dashboardApi.getAccountSummary(accountId);

// Monthly analysis
const monthly = await dashboardApi.getTransactionSummary({
  groupBy: 'month',
});
```

### Investments
```typescript
import { investmentsApi } from '@/core/api/investmentsApi';

// Stock price
const stock = await investmentsApi.fetchStockData('AAPL');

// Historical data
const history = await investmentsApi.fetchStockHistory('AAPL', 'daily');

// Mutual fund NAV
const mf = await investmentsApi.fetchMutualFundData('119551');

// Portfolio
const portfolio = await investmentsApi.getInvestmentsSummary();
```

---

## 🔧 Configuration

### Environment Variables
```bash
# Alpha Vantage API key for stock data
firebase functions:config:set alphavantage.apikey="YOUR_KEY"

# Get free key: https://www.alphavantage.co/support/#api-key
```

### Deployment
```bash
# Build
cd functions && npm run build

# Deploy all
firebase deploy --only functions

# Deploy specific
firebase deploy --only functions:createGoal,functions:importTransactions
```

---

## 📊 Caching Strategy

| Data Type | TTL | Collection | Clear Method |
|-----------|-----|------------|--------------|
| Dashboard | 5 min | dashboard_cache | invalidateDashboardCache |
| Stock | 5 min | stock_cache | clearInvestmentCache('stocks') |
| Mutual Fund | 24 hrs | mutualfund_cache | clearInvestmentCache('mutualfunds') |

---

## 🔐 Security

### All Functions Require
- ✅ Authentication (request.auth)
- ✅ User ownership verification
- ✅ Input validation
- ✅ Error handling

### Destructive Operations
- `clearUserData`: Requires confirmation phrase "DELETE_ALL_MY_DATA"
- `deleteGoal`: Cascades to goal_contributions
- `deleteAccount`: Soft delete (is_active = false)

---

## 📈 Performance

### Batch Limits
- Firestore batch: 500 documents
- Import chunk: 100 transactions (configurable)
- Transaction queries: 1000 limit

### Optimization Tips
1. Use cached dashboard for initial load
2. Batch import for >50 transactions
3. Clear investment cache only when needed
4. Use `forceRefresh: false` for stock data

---

## 🎯 Common Patterns

### Error Handling
```typescript
try {
  const result = await goalsApi.createGoal(data);
} catch (error: any) {
  if (error.code === 'unauthenticated') {
    // Redirect to login
  } else if (error.code === 'permission-denied') {
    // Show error toast
  } else {
    // Generic error
  }
}
```

### Loading States
```typescript
const [loading, setLoading] = useState(false);

const handleImport = async () => {
  setLoading(true);
  try {
    const result = await importApi.importTransactions(...);
    toast.success(`Imported ${result.imported} transactions`);
  } finally {
    setLoading(false);
  }
};
```

### Cache Invalidation
```typescript
// After import/delete
await importApi.importTransactions(...);
await dashboardApi.invalidateDashboardCache();

// Refresh dashboard
const dashboard = await dashboardApi.computeAndCacheDashboard({
  forceRefresh: true,
});
```

---

## 📞 Support

### Documentation
- `docs/critical-cloud-functions-implementation.md` - Full guide
- `docs/implementation-summary.md` - Overview
- `docs/firebase-infrastructure-setup.md` - Infrastructure

### API Wrappers
- `webapp/src/core/api/goalsApi.ts`
- `webapp/src/core/api/importApi.ts`
- `webapp/src/core/api/dashboardApi.ts`
- `webapp/src/core/api/investmentsApi.ts`

### External APIs
- Alpha Vantage: https://www.alphavantage.co/documentation/
- Indian MF API: https://www.mfapi.in/

---

**Total Functions: 48**
**Compilation: ✅ Success**
**Ready: ✅ Production**
