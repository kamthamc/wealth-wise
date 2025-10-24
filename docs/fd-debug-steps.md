# FD Not Showing Up - Debug Steps

## What I've Done

1. ✅ Added all deposit types to FILTER_OPTIONS in AccountsList.tsx
2. ✅ Added extensive debug logging to track account creation and filtering
3. ✅ Verified AccountType includes 'fixed_deposit' in types
4. ✅ Verified AddAccountModal has fixed_deposit in categories
5. ✅ Verified repository creates accounts with is_active: true by default

## Debug Instructions

### Step 1: Clear Browser Cache & Reload
```bash
# Hard refresh the browser
Cmd + Shift + R (Mac)
Ctrl + Shift + R (Windows/Linux)
```

### Step 2: Open Browser Console
1. Press F12 or Right-click → Inspect
2. Go to "Console" tab
3. Clear any existing logs (🚫 icon)

### Step 3: Create a Fixed Deposit Account
1. Click "Add Account" button
2. **Important**: Select Type dropdown and verify "Fixed Deposit" appears in the "Deposits & Savings" section
3. Fill in the form:
   - Name: "Test FD"
   - Type: "Fixed Deposit"
   - Balance: ₹10,000
   - Institution: Any
4. Click "Add Account"

### Step 4: Check Console Output

You should see TWO debug groups:

#### A. Account Creation Log
```
🔍 DEBUG: Creating Account
  Form data: { name: "Test FD", type: "fixed_deposit", ... }
  Account type: "fixed_deposit"
  Is Fixed Deposit? true
  ✅ Account created successfully
  📊 Total accounts after creation: X
  🔎 All account types: [...]
```

#### B. Filter Log (appears automatically after creation)
```
🔍 DEBUG: Filtering Accounts
  Total accounts: X
  All accounts: [{ id: "...", name: "Test FD", type: "fixed_deposit", is_active: true }, ...]
  Current filter: {}
  Search query: ""
  Final filtered accounts: [...]
```

### Step 5: Analyze the Output

**Check A: Was the account created?**
- Look for "✅ Account created successfully"
- Check "All account types" array - is there an entry with `type: "fixed_deposit"`?
- If YES → Account was created successfully
- If NO → Account creation failed (check for error messages)

**Check B: Is the account being filtered out?**
- Look at "All accounts" - is "Test FD" in the list?
- Look at "Final filtered accounts" - is "Test FD" in the list?
- If in "All accounts" but NOT in "Final filtered accounts" → Filter issue
- If NOT in "All accounts" → Database issue

**Check C: Is the account active?**
- In "All accounts" array, find your FD
- Check: `is_active: true` or `is_active: false`?
- If false → That's the problem!

### Step 6: Test the Filter

1. Click on the account type filter dropdown
2. **Verify**: Do you see "Fixed Deposit" option?
3. Select "Fixed Deposit"
4. Check console - should show:
   ```
   🔍 DEBUG: Filtering Accounts
     Current filter: { type: "fixed_deposit" }
     After type filter (fixed_deposit): X accounts
     Final filtered accounts: [{ name: "Test FD", type: "fixed_deposit" }]
   ```

### Step 7: Check Database Directly

If the account is created but not showing:

```javascript
// Run this in the browser console
const { db } = await import('/src/core/db/client.js');
const result = await db.query('SELECT * FROM accounts WHERE type = $1', ['fixed_deposit']);
console.table(result.rows);
```

This will show you exactly what's in the database.

## Common Issues & Solutions

### Issue 1: Account Type Not in Dropdown
**Symptom**: Can't find "Fixed Deposit" when creating account  
**Solution**: Hard refresh browser (Cmd+Shift+R)

### Issue 2: Account Created but Not Visible
**Symptom**: Console shows "✅ Account created successfully" but FD not in list  
**Possible Causes**:
1. **is_active is false** → Check console log for `is_active` value
2. **Filter is applied** → Check if a filter is active (not showing "all")
3. **Search query active** → Check if there's text in search box
4. **Component not re-rendering** → Refresh page

### Issue 3: Account Creation Fails
**Symptom**: Console shows error, no "✅ Account created successfully"  
**Solution**: 
1. Check console for specific error message
2. Look for database errors
3. Check if database is initialized

### Issue 4: Type Mismatch
**Symptom**: Console shows `type: "Fixed Deposit"` instead of `type: "fixed_deposit"`  
**Cause**: Type value not matching (spaces vs underscores)  
**Solution**: Already fixed in AddAccountModal - should be "fixed_deposit"

## Report Back

Please provide:

1. **Screenshot of Console Output** (both debug groups)
2. **Current Behavior**: What do you see?
3. **Database Check Result**: Result of the SQL query above
4. **Filter Dropdown**: Can you see "Fixed Deposit" in the dropdown?

## Next Steps Based on Results

### If account is created but not showing:
→ I'll check the rendering logic in AccountCard component

### If account creation fails:
→ I'll check database schema and migrations

### If account shows in database but not in UI:
→ I'll check the store synchronization

### If filter dropdown doesn't show "Fixed Deposit":
→ I'll check if the build is stale (need to rebuild)

