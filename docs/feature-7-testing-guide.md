# Feature #7 - Manual Testing Guide

**Date**: October 21, 2025  
**Status**: Ready for Testing  
**Completion**: 95% (Code Complete, Testing Pending)

---

## Prerequisites

### 1. Start Development Server
```bash
cd /Users/chaitanyakkamatham/Projects/wealth-wise/webapp
npm run dev
```

### 2. Open Browser
- Navigate to: `http://localhost:5173`
- Open DevTools Console (F12)
- Check for any compilation errors

---

## Test Suite #1: Credit Card Account

### 1.1 Create Credit Card Account

**Steps**:
1. Click "Add Account" button
2. Fill in the form:
   - **Name**: "HDFC Regalia Credit Card"
   - **Type**: Select "Credit Card" from dropdown
   - **Currency**: INR (default)
   - **Initial Balance**: -5000 (negative for outstanding balance)
   - **Institution**: HDFC Bank

3. **Credit Card Specific Fields** (should appear automatically):
   - **Credit Limit**: 100000 (₹1,00,000)
   - **Billing Cycle Day**: 1
   - **Payment Due Day**: 20
   - **Card Network**: Select "Visa"
   - **Interest Rate**: 42 (annual percentage)

4. Click "Add Account"

**Expected Results**:
- ✅ Account created successfully
- ✅ Success notification appears
- ✅ Account appears in accounts list
- ✅ Balance shows as -₹5,000 (or ₹5,000 outstanding)

### 1.2 View Credit Card Details

**Steps**:
1. Click on the newly created "HDFC Regalia Credit Card"
2. Account Details page should open

**Expected Results**:

**Credit Limit Card** (top section with gradient):
- ✅ Shows "Credit Limit: ₹1,00,000"
- ✅ Shows credit utilization percentage: 5.0%
- ✅ Utilization bar is GREEN (since <30%)
- ✅ Shows "Used: ₹5,000"
- ✅ Shows "Available: ₹95,000"

**Stats Grid** (4 cards):
- ✅ Current Balance: ₹5,000
- ✅ Minimum Due: ₹0 (no payment due initially)
- ✅ Total Due: ₹5,000
- ✅ Rewards Points: 0 points

**Billing Cycle Section**:
- ✅ Billing Cycle Day: 1 of every month
- ✅ Payment Due Date: (should show next due date)
- ✅ Days until due shown in parentheses

**Card Details Section**:
- ✅ Network: VISA
- ✅ Interest Rate: 42% p.a.
- ✅ Annual Fee: Free (₹0)
- ✅ Autopay: Disabled

### 1.3 Test Credit Utilization Colors

**Test Case 1: Low Utilization (Green)**
- Current: -₹5,000 balance, ₹100,000 limit
- Expected: 5% utilization, GREEN indicator
- Status: Should already be showing

**Test Case 2: Medium Utilization (Yellow)**
- Add a transaction: Expense of ₹45,000
- New balance: -₹50,000
- Expected: 50% utilization, YELLOW indicator

**Steps**:
1. Go to Transactions
2. Add transaction:
   - Type: Expense
   - Amount: 45000
   - Account: HDFC Regalia Credit Card
   - Category: Shopping
   - Description: "Test transaction"
3. Go back to account details

**Expected**: Utilization bar turns YELLOW, shows 50%

**Test Case 3: High Utilization (Red)**
- Add another transaction: Expense of ₹35,000
- New balance: -₹85,000
- Expected: 85% utilization, RED indicator

**Steps**:
1. Add transaction: ₹35,000 expense
2. Check account details

**Expected**: Utilization bar turns RED, shows 85%

---

## Test Suite #2: Brokerage Account

### 2.1 Create Brokerage Account

**Steps**:
1. Click "Add Account"
2. Fill in the form:
   - **Name**: "Zerodha Trading Account"
   - **Type**: Select "Brokerage"
   - **Currency**: INR
   - **Initial Balance**: 250000 (₹2,50,000 portfolio value)
   - **Institution**: Zerodha

3. **Brokerage Specific Fields** (should appear automatically):
   - **Broker Name**: Zerodha
   - **Demat Account Number**: 1204470012345678
   - **Trading Account Number**: ZD1234
   - **DP ID**: IN300***
   - **Client ID**: ABC123

4. Click "Add Account"

**Expected Results**:
- ✅ Account created successfully
- ✅ Account appears in list with "Brokerage" badge

### 2.2 View Brokerage Details

**Steps**:
1. Click on "Zerodha Trading Account"

**Expected Results**:

**Portfolio Value Card** (gradient card):
- ✅ Shows "Current Portfolio Value: ₹2,50,000"
- ✅ Shows Total Returns: ₹0 (initially, since invested value = current value)
- ✅ Shows Returns %: 0.00%
- ✅ Card color: GREY/DEFAULT (since returns = 0)

**Stats Grid**:
- ✅ Invested Value: ₹0 (initially)
- ✅ Realized Gains: ₹0
- ✅ Unrealized Gains: ₹0
- ✅ Total Holdings: 0

**Holdings Breakdown Section**:
- ✅ Equity: 0 holdings
- ✅ Mutual Funds: 0 funds
- ✅ Bonds: 0 bonds
- ✅ ETFs: 0 ETFs

**Account Information Section**:
- ✅ Broker: Zerodha
- ✅ Account Type: (shows if provided)
- ✅ Demat Account: 1204470012345678
- ✅ Trading Account: ZD1234
- ✅ Status: Active (green badge)

**Trading Preferences Section**:
- ✅ Auto Square Off: ❌ (disabled)
- ✅ Margin Trading: ❌ (disabled)

### 2.3 Test Portfolio Returns Colors

**Note**: To fully test returns colors, you would need to:
1. Update the brokerage_details table with invested_value
2. Update current_value to be different
3. Then the card color changes based on P&L:
   - GREEN: Positive returns
   - RED: Negative returns
   - GREY: Zero returns

---

## Test Suite #3: Deposit Account Integration

### 3.1 Verify Existing Deposit Functionality

**Steps**:
1. Create or view an existing Fixed Deposit account
2. Check that DepositView still works correctly

**Expected Results**:
- ✅ Maturity card displays correctly
- ✅ Interest calculations work
- ✅ Progress bars show tenure completion
- ✅ All deposit-specific fields visible

---

## Test Suite #4: AccountViewFactory Routing

### 4.1 Test View Routing Logic

**Test Different Account Types**:
1. View a Bank Account → Should show standard view (not specialized)
2. View a Credit Card → Should show CreditCardView
3. View a Fixed Deposit → Should show DepositView
4. View a Brokerage Account → Should show BrokerageView
5. View a UPI/Cash/Wallet → Should show standard view

**Expected**:
- ✅ Each account type routes to correct view component
- ✅ No errors in console
- ✅ All views render properly

---

## Test Suite #5: Form Validation

### 5.1 Credit Card Form Validation

**Test Required Fields**:
1. Try creating credit card without Credit Limit
   - Expected: Validation error

**Test Number Ranges**:
1. Try billing cycle day = 35 (invalid, should be 1-31)
   - Expected: Validation error or clamped to 31
2. Try payment due day = 0 (invalid)
   - Expected: Validation error or clamped to 1

### 5.2 Brokerage Form Validation

**Test Optional Fields**:
1. Create brokerage with only Broker Name
   - Expected: Should work, other fields optional
2. Create brokerage with all fields empty
   - Expected: Should use default "Unknown" for broker_name

---

## Test Suite #6: Responsive Design

### 6.1 Mobile View Testing

**Steps**:
1. Open DevTools (F12)
2. Toggle Device Toolbar (Cmd+Shift+M)
3. Select iPhone 12 Pro or similar
4. Navigate through all specialized views

**Expected**:
- ✅ CreditCardView: Cards stack vertically, text readable
- ✅ DepositView: Progress bars adapt to width
- ✅ BrokerageView: Holdings breakdown stacks properly
- ✅ Forms: Fields stack vertically, dropdowns work on touch

### 6.2 Tablet View Testing

**Test on iPad (768px width)**:
- ✅ Grid layouts adapt (2 columns instead of 4)
- ✅ Cards resize appropriately
- ✅ Touch targets are large enough

---

## Test Suite #7: Database Persistence

### 7.1 Verify Data Persistence

**Steps**:
1. Create a credit card account with all fields filled
2. Refresh the page (Cmd+R)
3. View the account again

**Expected**:
- ✅ All credit card details persisted
- ✅ Credit limit shows correctly
- ✅ Billing cycle preserved
- ✅ Card network retained
- ✅ Calculations still accurate

### 7.2 Check Database Schema

**Browser Console**:
```javascript
const { db } = await import('/src/core/db/client.js');

// Check credit_card_details
const ccResult = await db.query('SELECT * FROM credit_card_details');
console.table(ccResult.rows);

// Check brokerage_details
const brokResult = await db.query('SELECT * FROM brokerage_details');
console.table(brokResult.rows);

// Verify all required fields are present
```

---

## Test Suite #8: Edge Cases

### 8.1 Zero Balance Scenarios

**Test Case**: Credit card with ₹0 balance
- Expected: 0% utilization, 100% available credit, GREEN indicator

### 8.2 Negative Balance (Credit Cards)

**Test Case**: Credit card with positive balance (overpayment)
- Create card with +₹5,000 balance
- Expected: Should handle gracefully (might show as -5% utilization or special case)

### 8.3 At-Limit Credit Card

**Test Case**: Balance = Credit Limit
- Balance: -₹100,000
- Limit: ₹100,000
- Expected: 100% utilization, ₹0 available, RED indicator

### 8.4 Over-Limit Credit Card

**Test Case**: Balance > Credit Limit (over-limit fees)
- Balance: -₹110,000
- Limit: ₹100,000
- Expected: >100% utilization, negative available credit

---

## Test Suite #9: Integration Tests

### 9.1 AccountDetails Integration

**Verify**:
- ✅ AccountDetails correctly fetches type-specific details
- ✅ Loading states work properly
- ✅ Error states handled gracefully
- ✅ Empty states (no details) show appropriate message

### 9.2 AccountsList Integration

**Verify**:
- ✅ All account types appear in list
- ✅ Filtering by type works (Credit Card filter shows only credit cards)
- ✅ Multi-select filter works (if implemented)
- ✅ Search works across all account types

---

## Test Suite #10: Performance

### 10.1 Rendering Performance

**Test with Multiple Accounts**:
1. Create 5 credit cards
2. Create 5 brokerage accounts
3. Create 5 deposits
4. Navigate between them rapidly

**Expected**:
- ✅ No lag or freezing
- ✅ Smooth transitions
- ✅ No memory leaks (check DevTools Memory tab)

---

## Regression Testing

### Verify Nothing Broke

**Test Previous Features**:
1. ✅ Feature #3 (Deposit Extensions) - Still works
2. ✅ Feature #4 (Monthly Interest) - Still calculates
3. ✅ Feature #5 (Multi-Select Filters) - Still functional
4. ✅ Dashboard charts - Still render
5. ✅ Net worth calculation - Still accurate
6. ✅ Transaction creation - Still works
7. ✅ Import/Export - Still functional

---

## Bug Reporting Template

If you find any issues, report them using this format:

```markdown
## Bug Report: [Short Description]

**Severity**: Critical / High / Medium / Low

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happened]

**Screenshots**:
[Attach if relevant]

**Console Errors**:
```
[Paste any errors from console]
```

**Environment**:
- Browser: Chrome/Safari/Firefox
- OS: macOS/Windows/Linux
- Screen Size: Desktop/Tablet/Mobile

**Additional Context**:
[Any other relevant information]
```

---

## Checklist Summary

### Must Test (Critical)
- [ ] Create credit card account with all fields
- [ ] View credit card details page
- [ ] Verify credit utilization calculation
- [ ] Create brokerage account with all fields
- [ ] View brokerage details page
- [ ] Verify portfolio sections render
- [ ] Test form field visibility (conditional rendering)
- [ ] Verify data persists after page refresh
- [ ] Check console for errors (0 errors expected)

### Should Test (Important)
- [ ] Test all 3 utilization color states (green/yellow/red)
- [ ] Test responsive design (mobile/tablet)
- [ ] Test edge cases (zero balance, at-limit, over-limit)
- [ ] Verify AccountViewFactory routing
- [ ] Test form validation
- [ ] Check database schema correctness

### Nice to Test (Optional)
- [ ] Performance with many accounts
- [ ] Regression testing of previous features
- [ ] Test with real bank data
- [ ] Accessibility testing (keyboard navigation, screen readers)

---

## Success Criteria

Feature #7 is considered **100% COMPLETE** when:

1. ✅ All critical tests pass
2. ✅ Zero console errors during normal usage
3. ✅ Data persists correctly to database
4. ✅ All views render without visual glitches
5. ✅ Calculations are accurate
6. ✅ Responsive design works on mobile/tablet
7. ✅ No regressions in previous features

---

## Next Steps After Testing

Once all tests pass:

1. **Mark Feature #7 as 100% Complete**
2. **Update documentation** with test results
3. **Create GitHub issue for any bugs found**
4. **Move to next feature** or **implement enhancements**

Possible enhancements:
- Add edit functionality for credit card details
- Add edit functionality for brokerage details
- Implement payment reminders for credit cards
- Add holdings management for brokerage
- Implement interest projections for deposits

---

## Contact / Questions

If you encounter any issues during testing:
1. Check console for error messages
2. Verify database schema (run SQL queries in console)
3. Check that all files are committed and pushed
4. Review the implementation docs in `/docs/feature-7-implementation-summary.md`

**Testing Started**: _____________  
**Testing Completed**: _____________  
**Result**: PASS / FAIL (with notes)  
**Bugs Found**: _____________
