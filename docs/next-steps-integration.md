# Next Steps - Quick Reference

**Current Status**: ✅ Core infrastructure complete, zero compilation errors

## Immediate Actions (Priority Order)

### 1. Fix Balance Display in AccountDetails (30 min) ⭐ CRITICAL

**File**: `/webapp/src/features/accounts/components/AccountDetails.tsx`

**Add Import**:
```typescript
import { calculateAccountBalance } from '@/shared/utils/financial';
```

**Replace balance calculation** (around line 80-85):
```typescript
// Find this useMemo or the section where balance is used
const currentBalance = useMemo(() => {
  if (!account) return '0';
  return calculateAccountBalance(account, transactions);
}, [account, transactions]);
```

**Update display** (find where balance is shown):
```typescript
// Replace static account.balance with:
<span className="account-details__balance">
  {formatCurrency(Number(currentBalance))}
</span>
```

### 2. Fix Net Worth in Dashboard (20 min) ⭐ CRITICAL

**File**: `/webapp/src/features/dashboard/components/NetWorthHero.tsx` (or similar)

**Add Import**:
```typescript
import { calculateNetWorth } from '@/shared/utils/financial';
```

**Calculate net worth**:
```typescript
const netWorth = useMemo(() => {
  return calculateNetWorth(accounts, transactions);
}, [accounts, transactions]);
```

**Display**:
```typescript
<span>{formatCurrency(Number(netWorth))}</span>
```

### 3. Update Performance Insights (30 min)

**File**: `/webapp/src/features/dashboard/components/PerformanceInsights.tsx` (or similar)

**Add Import**:
```typescript
import { getMonthlyStats } from '@/shared/utils/financial';
import { LineChart } from '@/shared/components/Charts';
```

**Calculate monthly data**:
```typescript
const monthlyData = useMemo(() => {
  return getMonthlyStats(transactions, 12);
}, [transactions]);
```

**Add line chart**:
```typescript
<LineChart
  data={monthlyData.map(m => ({ month: m.month, balance: m.balance }))}
  xKey="month"
  yKey="balance"
  height={300}
  showGrid
  showDots
  color="var(--color-primary)"
/>
```

### 4. Update Account Breakdown (30 min)

**File**: `/webapp/src/features/dashboard/components/AccountBreakdown.tsx` (or similar)

**Add Import**:
```typescript
import { calculateAccountBalance } from '@/shared/utils/financial';
import { PieChart } from '@/shared/components/Charts';
```

**Calculate balances**:
```typescript
const accountsWithBalances = useMemo(() => {
  return accounts.map(account => ({
    ...account,
    currentBalance: calculateAccountBalance(account, transactions)
  }));
}, [accounts, transactions]);
```

**Add pie chart for allocation**:
```typescript
const allocationData = accountsWithBalances.map((acc, idx) => ({
  label: acc.name,
  value: Number(acc.currentBalance),
  color: ACCOUNT_COLORS[idx % ACCOUNT_COLORS.length]
}));

<PieChart
  data={allocationData}
  height={300}
  showLegend
  showPercentages
/>
```

## Testing Checklist

### Balance Calculation Test
1. Open AccountDetails for any account
2. Note the displayed balance
3. Add a new income transaction (e.g., ₹1000)
4. Verify balance increases by ₹1000
5. Add a new expense transaction (e.g., ₹500)
6. Verify balance decreases by ₹500

### Net Worth Test
1. Go to Dashboard
2. Note the net worth displayed
3. Add transaction to any account
4. Return to Dashboard
5. Verify net worth updated correctly

### Theme Test
1. View AccountCharts in current theme
2. Toggle theme (Settings → Appearance)
3. Verify all charts update colors automatically
4. Check: grid lines, axis labels, bars, lines all match theme

### Large Number Test
1. Create test account with balance: "999999999999.99"
2. Add income: "50000000000.50"
3. Expected balance: "1049999999999.49"
4. Verify displayed correctly (no scientific notation, no rounding errors)

## File Locations Reference

### New Files Created
```
/webapp/src/shared/utils/financial.ts          (304 lines)
/webapp/src/shared/components/Charts/Charts.tsx (400+ lines)
/webapp/src/shared/components/Charts/Charts.css (150 lines)
/webapp/src/shared/components/Charts/index.ts
/docs/centralized-financial-calculations.md
```

### Files to Update
```
/webapp/src/features/accounts/components/AccountDetails.tsx
/webapp/src/features/dashboard/components/NetWorthHero.tsx
/webapp/src/features/dashboard/components/PerformanceInsights.tsx
/webapp/src/features/dashboard/components/AccountBreakdown.tsx
```

### Files Already Updated
```
✅ /webapp/src/features/accounts/components/AccountCharts.tsx
✅ /webapp/src/shared/utils/index.ts (added financial export)
✅ /webapp/src/shared/components/index.ts (added Charts export)
```

## Code Snippets for Quick Copy-Paste

### Import Financial Utils
```typescript
import {
  calculateAccountBalance,
  calculateNetWorth,
  getMonthlyStats,
  getCategoryBreakdown,
} from '@/shared/utils/financial';
```

### Import Charts
```typescript
import {
  LineChart,
  BarChart,
  GroupedBarChart,
  PieChart,
  type GroupedBarDataPoint,
} from '@/shared/components/Charts';
```

### Calculate Account Balance
```typescript
const currentBalance = useMemo(() => {
  if (!account) return '0';
  return calculateAccountBalance(account, transactions);
}, [account, transactions]);
```

### Calculate Net Worth
```typescript
const netWorth = useMemo(() => {
  return calculateNetWorth(accounts, transactions);
}, [accounts, transactions]);
```

### Monthly Stats for Charts
```typescript
const monthlyData = useMemo(() => {
  return getMonthlyStats(transactions, 6); // Last 6 months
}, [transactions]);

// For line chart
const balanceHistory = monthlyData.map(m => ({
  month: m.month,
  balance: m.balance
}));

// For grouped bar chart
const incomeExpenseData: GroupedBarDataPoint[] = monthlyData.map(m => ({
  label: m.month,
  values: [
    { key: 'Income', value: m.income, color: 'var(--color-success)' },
    { key: 'Expenses', value: m.expenses, color: 'var(--color-danger)' }
  ]
}));
```

### Category Breakdown for Pie Chart
```typescript
const categoryData = useMemo(() => {
  const breakdown = getCategoryBreakdown(transactions, 'expense');
  return breakdown.map((item, index) => ({
    label: item.category,
    value: item.amount,
    color: CATEGORY_COLORS[index % CATEGORY_COLORS.length]
  }));
}, [transactions]);
```

## Common Patterns

### Pattern: Safe Number Conversion
```typescript
// BigInt/string → Number for display
const displayValue = Number(calculateAccountBalance(account, transactions));

// Format for UI
<span>{formatCurrency(displayValue)}</span>
```

### Pattern: Empty State Handling
```typescript
const hasData = transactions.length > 0;

{!hasData ? (
  <div className="empty-state">
    <p>No data available</p>
  </div>
) : (
  <LineChart data={chartData} ... />
)}
```

### Pattern: Chart Data Transformation
```typescript
// From transaction list → Chart data
const monthlyData = useMemo(() => {
  return getMonthlyStats(transactions, 6);
}, [transactions]);

// Transform for specific chart type
const chartData = monthlyData.map(m => ({
  label: m.month,
  value: m.balance
}));
```

## Known Issues & Solutions

### Issue: "formatCurrency is not defined"
**Solution**: Import from correct module
```typescript
import { formatCurrency } from '@/shared/utils/formatting';
// NOT from '@/shared/utils/financial'
```

### Issue: Chart not updating on theme change
**Solution**: Ensure chart uses CSS variables
```typescript
color="var(--color-primary)"  // ✅ Theme-aware
color="#3b82f6"                // ❌ Hardcoded
```

### Issue: Balance not updating after transaction
**Solution**: Ensure dependencies in useMemo
```typescript
const balance = useMemo(() => {
  return calculateAccountBalance(account, transactions);
}, [account, transactions]); // ← Include transactions!
```

## Performance Tips

1. **Use useMemo for expensive calculations**
   ```typescript
   const balance = useMemo(() => calculateAccountBalance(...), [deps]);
   ```

2. **Limit chart data points**
   ```typescript
   getMonthlyStats(transactions, 6) // Not 120 months
   ```

3. **Slice category data**
   ```typescript
   const topCategories = getCategoryBreakdown(transactions)
     .slice(0, 8); // Top 8 only
   ```

## Commit Message Template

```bash
git add .
git commit -S -m "feat: integrate centralized financial calculations

- Update AccountDetails to use calculateAccountBalance()
- Update NetWorthHero to use calculateNetWorth()
- Update PerformanceInsights with LineChart
- Update AccountBreakdown with PieChart
- All balance calculations now accurate with BigInt precision
- Charts support dark/light theme automatically

Addresses balance calculation and chart theming issues"

git push origin feature/centralized-calculations
```

## Success Criteria

✅ Account balance reflects all transactions  
✅ Dashboard net worth is accurate  
✅ Monthly charts display in Performance Insights  
✅ Account breakdown shows allocation pie chart  
✅ All charts support theme switching  
✅ No floating point precision errors  
✅ Zero compilation errors  

## Questions to Verify

1. Does the account balance change when you add a transaction? → Should be YES
2. Does net worth equal sum of all account balances? → Should be YES
3. Do charts change color when you switch themes? → Should be YES
4. Can you handle amounts over ₹1 billion? → Should be YES
5. Are there any console errors? → Should be NO

---

**Ready to proceed**: Start with Priority 1 (AccountDetails balance), then test before moving to next item.
