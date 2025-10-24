# Translation Audit - Missing Strings

## Summary

Total hardcoded strings found: **100+ instances**

This document lists all hardcoded English strings that need to be translated.

---

## By Component

### 1. **AccountsList.tsx** (Partially Translated)

Missing translations:
```typescript
// Empty states
"No accounts found"
"No accounts yet"
"Try adjusting your filters or search query to find what you're looking for"
"Start tracking your finances by adding your bank accounts, credit cards, and other financial accounts"

// Delete dialog
"Delete Account?"
description: `Are you sure you want to delete "${account.name}"?...`
"Delete Account" (confirmLabel)
"Cancel"

// Actions
"Add Your First Account"
"Learn about account types →"
```

Translation keys needed:
```
pages.accounts.empty.notFound.title
pages.accounts.empty.notFound.description
pages.accounts.empty.initial.title
pages.accounts.empty.initial.description
pages.accounts.empty.actions.addFirst
pages.accounts.empty.actions.learnMore
pages.accounts.deleteDialog.title
pages.accounts.deleteDialog.description
pages.accounts.deleteDialog.confirm
pages.accounts.deleteDialog.cancel
```

---

### 2. **AddAccountModal.tsx** (Now Translated ✅)

All strings translated in recent commit.

---

### 3. **AccountDetails.tsx** (Not Translated)

Missing translations:
```typescript
"← Back to Accounts"
"✏️ Edit Account"
"🗑️ Delete Account"
"Account Not Found"
"The account you're looking for doesn't exist or has been deleted."
"Back to Accounts"

// Stats
"Current Balance"
"Total Transactions"
"Coming soon"
"This Month"

// Empty state
"No Transactions Yet"
"Transactions for this account will appear here. This feature is coming soon!"

// Delete dialog
"Delete Account?"
description with account name
"Delete Account"
"Cancel"
```

Translation keys needed:
```
pages.accountDetails.backButton
pages.accountDetails.editButton
pages.accountDetails.deleteButton
pages.accountDetails.notFound.title
pages.accountDetails.notFound.description
pages.accountDetails.stats.currentBalance
pages.accountDetails.stats.totalTransactions
pages.accountDetails.stats.thisMonth
pages.accountDetails.stats.comingSoon
pages.accountDetails.empty.title
pages.accountDetails.empty.description
pages.accountDetails.deleteDialog.title
pages.accountDetails.deleteDialog.description
pages.accountDetails.deleteDialog.confirm
pages.accountDetails.deleteDialog.cancel
```

---

### 4. **TransactionsList.tsx** (Partially Translated)

Missing translations:
```typescript
"Transactions"
"Track your income and expenses"
"+ Add Transaction"

// Stats
"Total Income"
"Total Expenses"
"Net Cash Flow"
"Total Transactions"

// Search
"🔍 Search transactions..."

// Filters
"All"
"Income" (type)
"Expense" (type)
"Transfer" (type)

// Empty states
"No transactions found"
"No transactions yet"
"Try adjusting your filters or search query to find the transactions you're looking for"
"Start tracking your income and expenses by recording your first transaction"
"Add Your First Transaction"
"Import from bank statement →"

// Transaction items
"Unknown Account"
```

Translation keys needed:
```
pages.transactions.title
pages.transactions.subtitle
pages.transactions.addButton
pages.transactions.stats.totalIncome
pages.transactions.stats.totalExpenses
pages.transactions.stats.netCashFlow
pages.transactions.stats.totalTransactions
pages.transactions.search
pages.transactions.filters.all
pages.transactions.filters.income
pages.transactions.filters.expense
pages.transactions.filters.transfer
pages.transactions.empty.notFound.title
pages.transactions.empty.notFound.description
pages.transactions.empty.initial.title
pages.transactions.empty.initial.description
pages.transactions.empty.actions.addFirst
pages.transactions.empty.actions.import
pages.transactions.unknownAccount
```

---

### 5. **AddTransactionForm.tsx** (Not Translated)

Missing translations:
```typescript
"Add Transaction"
"Record a new income, expense, or transfer"
"Transaction updated"
"Your transaction has been updated successfully"
"Transaction added"
"Your transaction has been added successfully"
"Failed to save transaction"

// Form labels
"Transaction Type"
"Income"
"Expense"
"Transfer"
"Amount"
"Account"
"Select an account..."
"To Account" (for transfers)
"Select destination account..."
"Description"
"What was this transaction for?"
"Date"
"Category"
"Optional category ID"
"Notes"
"Add notes or tags..."

// Buttons
"Cancel"
"Add Transaction"
"Update Transaction"
```

Translation keys needed:
```
pages.transactions.form.title.add
pages.transactions.form.title.edit
pages.transactions.form.description
pages.transactions.form.success.updated.title
pages.transactions.form.success.updated.description
pages.transactions.form.success.added.title
pages.transactions.form.success.added.description
pages.transactions.form.error.save
pages.transactions.form.fields.type.label
pages.transactions.form.fields.type.income
pages.transactions.form.fields.type.expense
pages.transactions.form.fields.type.transfer
pages.transactions.form.fields.amount.label
pages.transactions.form.fields.account.label
pages.transactions.form.fields.account.placeholder
pages.transactions.form.fields.toAccount.label
pages.transactions.form.fields.toAccount.placeholder
pages.transactions.form.fields.description.label
pages.transactions.form.fields.description.placeholder
pages.transactions.form.fields.date.label
pages.transactions.form.fields.category.label
pages.transactions.form.fields.category.placeholder
pages.transactions.form.fields.notes.label
pages.transactions.form.fields.notes.placeholder
pages.transactions.form.buttons.cancel
pages.transactions.form.buttons.add
pages.transactions.form.buttons.update
```

---

### 6. **BudgetsList.tsx** (Not Translated)

Missing translations:
```typescript
"Budgets"
"+ Add Budget"

// Stats
"Total Budget"
"Total Spent"
"Remaining"
"Over Budget"

// Search
"🔍 Search budgets..."

// Filters
"All" (period)
"📅 Daily"
"📆 Weekly"
"🗓️ Monthly"
"📊 Yearly"
"All Status"
"Active"
"Inactive"

// Empty states
"No budgets found"
"No budgets yet"
"Try adjusting your filters or search query"
"Create your first budget to start tracking spending"
```

Translation keys needed:
```
pages.budgets.title
pages.budgets.addButton
pages.budgets.stats.totalBudget
pages.budgets.stats.totalSpent
pages.budgets.stats.remaining
pages.budgets.stats.overBudget
pages.budgets.search
pages.budgets.filters.period.all
pages.budgets.filters.period.daily
pages.budgets.filters.period.weekly
pages.budgets.filters.period.monthly
pages.budgets.filters.period.yearly
pages.budgets.filters.status.all
pages.budgets.filters.status.active
pages.budgets.filters.status.inactive
pages.budgets.empty.notFound.title
pages.budgets.empty.notFound.description
pages.budgets.empty.initial.title
pages.budgets.empty.initial.description
```

---

### 7. **AddBudgetForm.tsx** (Not Translated)

Missing translations:
```typescript
"Create Budget"
"Edit Budget"
"Set spending limits for better financial control"
"Update budget details and limits"
"Close dialog"

// Validation
"Validation failed"
"Please fix all errors before submitting"

// Success messages
"Budget updated"
"Your budget has been updated successfully"
"Budget created"
"Your budget has been created successfully"

// Error
"Failed to save"
"Failed to save budget"

// Form fields
"Budget Name"
"e.g., Monthly Groceries"
"Category"
"e.g., Food & Dining"
"Budget Amount"
"Budget Period"
"Daily"
"Weekly"
"Monthly"
"Yearly"
"Start Date"
"Select start date..."
"End Date (Optional)"
"No end date (ongoing)"
"Alert Threshold"
"Get notified at..."

// Buttons
"Cancel"
"Create Budget"
"Update Budget"
```

Translation keys needed: (Similar pattern as transactions form)

---

### 8. **GoalsList.tsx** (Not Translated)

Missing translations:
```typescript
"Goals"
"+ Add Goal"

// Stats
"Active Goals"
"Completed"
"Total Target"
"Overall Progress"

// Search
"🔍 Search goals..."

// Filters
"All"
"🎯 Active"
"✅ Completed"
"⏸️ Paused"
"❌ Cancelled"

// Empty states
"No goals found"
"No goals yet"
"Try adjusting your filters or search query"
"Set your first financial goal and start saving"
```

Translation keys needed:
```
pages.goals.title
pages.goals.addButton
pages.goals.stats.activeGoals
pages.goals.stats.completed
pages.goals.stats.totalTarget
pages.goals.stats.overallProgress
pages.goals.search
pages.goals.filters.all
pages.goals.filters.active
pages.goals.filters.completed
pages.goals.filters.paused
pages.goals.filters.cancelled
pages.goals.empty.notFound.title
pages.goals.empty.notFound.description
pages.goals.empty.initial.title
pages.goals.empty.initial.description
```

---

### 9. **Dashboard Components** (Not Translated)

**FinancialOverview.tsx**:
```typescript
"Financial Overview"
"Total Balance"
"Across 0 accounts"
"This Month Income"
"vs last month"
"This Month Expenses"
"Savings Rate"
"Excellent savings!"
"Good savings"
"Try to save more"
```

**BudgetProgress.tsx**:
```typescript
"Budget Progress"
"View All →"
"No budgets yet"
"Create budgets to track your spending"
```

Translation keys needed:
```
pages.dashboard.financialOverview.title
pages.dashboard.financialOverview.totalBalance
pages.dashboard.financialOverview.acrossAccounts
pages.dashboard.financialOverview.thisMonthIncome
pages.dashboard.financialOverview.vsLastMonth
pages.dashboard.financialOverview.thisMonthExpenses
pages.dashboard.financialOverview.savingsRate
pages.dashboard.financialOverview.savingsRate.excellent
pages.dashboard.financialOverview.savingsRate.good
pages.dashboard.financialOverview.savingsRate.improve
pages.dashboard.budgetProgress.title
pages.dashboard.budgetProgress.viewAll
pages.dashboard.budgetProgress.empty.title
pages.dashboard.budgetProgress.empty.description
```

---

### 10. **ReportsPage.tsx** (Not Translated)

Missing translations:
```typescript
"Reports"
"Financial reports and insights"

// Stats
"Total Income"
"Total Expenses"
"Net Cash Flow"
"Savings Rate"
"Good" / "Can improve"

// Sections
"Income by Category"
"Expenses by Category"
"Monthly Trends"
"Account Balances"
"Total Balance"
"No data available"
```

Translation keys needed:
```
pages.reports.title
pages.reports.subtitle
pages.reports.stats.totalIncome
pages.reports.stats.totalExpenses
pages.reports.stats.netCashFlow
pages.reports.stats.savingsRate
pages.reports.stats.savingsRate.good
pages.reports.stats.savingsRate.improve
pages.reports.sections.incomeByCategory
pages.reports.sections.expensesByCategory
pages.reports.sections.monthlyTrends
pages.reports.sections.accountBalances
pages.reports.totalBalance
pages.reports.noData
```

---

### 11. **DashboardHeader.tsx** (Partially Translated)

Navigation items - already using `t('navigation.X')` ✅

---

## Total Translation Keys Needed

Estimate: **~250+ new translation keys**

Breakdown:
- Accounts: ~30 keys
- Transactions: ~40 keys
- Budgets: ~40 keys
- Goals: ~30 keys
- Dashboard: ~20 keys
- Reports: ~20 keys
- Forms (Add/Edit): ~70 keys
- Common UI elements: ~20 keys

---

## Priority Order

### 🔴 High Priority (User-facing frequently)
1. **TransactionsList** - Most used feature
2. **AddTransactionForm** - Most used form
3. **BudgetsList** - Core feature
4. **AddBudgetForm** - Core feature
5. **Dashboard components** - Landing page

### 🟡 Medium Priority
6. **AccountsList** - Already partially done
7. **GoalsList** - Secondary feature
8. **AccountDetails** - Detail view

### 🟢 Low Priority
9. **ReportsPage** - Analytics page
10. **Settings** - Not yet implemented

---

## Next Steps

1. ✅ AddAccountModal - **DONE**
2. ⏳ Update AccountsList (finish remaining strings)
3. ⏳ TransactionsList + AddTransactionForm
4. ⏳ BudgetsList + AddBudgetForm
5. ⏳ GoalsList + AddGoalForm
6. ⏳ Dashboard components
7. ⏳ ReportsPage
8. ⏳ AccountDetails

---

## Translation File Structure Proposal

```json
{
  "pages": {
    "accounts": {
      "title": "Accounts",
      "subtitle": "...",
      "addButton": "...",
      "search": "...",
      "stats": { ... },
      "filters": { ... },
      "empty": { ... },
      "deleteDialog": { ... },
      "modal": { ... }
    },
    "transactions": {
      "title": "...",
      "subtitle": "...",
      // similar structure
    },
    "budgets": { ... },
    "goals": { ... },
    "dashboard": { ... },
    "reports": { ... }
  }
}
```

This keeps translations organized by feature area.
