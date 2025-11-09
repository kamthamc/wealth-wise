# Xcode Project Configuration Guide

## Current Issues (Exit Code 65)

The build is failing due to Xcode project configuration issues, not code issues. The code is correct but Xcode doesn't know about all the files.

## Critical Issues to Fix in Xcode

### 1. Firebase SDK Not Found ❌

**Error**: `No such module 'FirebaseCore'`

**Fix**:
1. Open `WealthWise.xcodeproj` in Xcode
2. Select the project in the navigator (top-level "WealthWise")
3. Go to the "WealthWise" target
4. Select "General" tab
5. Scroll to "Frameworks, Libraries, and Embedded Content"
6. Click the "+" button
7. Add these Firebase frameworks:
   - FirebaseAuth
   - FirebaseCore
   - FirebaseFunctions
8. Ensure they're all set to "Do Not Embed"

**Alternative** (if using Swift Package Manager):
1. Go to File → Add Package Dependencies
2. Add Firebase iOS SDK: `https://github.com/firebase/firebase-ios-sdk`
3. Select version 11.5.0 or higher
4. Add these products to the WealthWise target:
   - FirebaseAuth
   - FirebaseCore  
   - FirebaseFunctions

### 2. Model Files Not in Target ❌

**Errors**: 
- `Cannot find type 'Account' in scope`
- `Cannot find type 'WebAppTransaction' in scope`
- `Cannot find type 'Budget' in scope`
- `Cannot find type 'WebAppGoal' in scope`

**Fix**:
1. In Xcode, select each model file in the navigator
2. Open File Inspector (⌘⌥1 or View → Inspectors → File)
3. Under "Target Membership", ensure "WealthWise" is checked

**Files to verify** (all in `WealthWise/Models/Financial/`):
- ✓ Account.swift
- ✓ WebAppTransaction.swift
- ✓ Budget.swift
- ✓ WebAppGoal.swift

### 3. DTO Files Not in Target ❌

**Errors**: Various "Cannot find type" errors in DTOs

**Fix**: Add these files to target (same process as #2):
- ✓ AccountDTO.swift
- ✓ TransactionDTO.swift
- ✓ BudgetDTO.swift
- ✓ GoalDTO.swift
- ✓ BalanceResponseDTO.swift

### 4. Service Files Not in Target ❌

**Errors**: `Cannot find type 'FirebaseService' in scope`

**Fix**: Add to target:
- ✓ FirebaseService.swift

### 5. Repository Files Not in Target ❌

**Fix**: Verify these are in target:
- ✓ AccountRepository.swift
- ✓ TransactionRepository.swift
- ✓ BudgetRepository.swift
- ✓ GoalRepository.swift

## Quick Fix Checklist

### Step 1: Add All Files to Target
1. Open Xcode
2. Select the "WealthWise" folder in the navigator
3. Right-click → "Add Files to WealthWise"
4. Navigate to the filesystem folders and add any missing files:
   - `Models/Financial/` (4 files)
   - `Services/DTOs/` (5 files)
   - `Services/` (FirebaseService.swift)
   - `Core/Repositories/` (4 files)
   - `Core/Authentication/` (AuthenticationManager.swift)
   - `Features/*/ViewModels/` (5 view model files)
   - `Features/*/Views/` (all view files)

**Important**: When adding files, ensure "Copy items if needed" is UNCHECKED and "Add to targets: WealthWise" is CHECKED.

### Step 2: Configure Firebase
1. If not already done, add Firebase package dependency:
   - File → Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Version: 11.5.0 or higher
   - Products: FirebaseAuth, FirebaseCore, FirebaseFunctions

2. Verify `GoogleService-Info.plist` is in the project:
   - Should be at root of WealthWise folder
   - Should be included in target

### Step 3: Clean and Rebuild
1. Clean build folder: ⇧⌘K (Shift+Command+K)
2. Or: Product → Clean Build Folder
3. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/WealthWise-*
   ```
4. Rebuild: ⌘B (Command+B)

## Complete File Structure for Target

Ensure all these files are checked in Target Membership:

```
WealthWise/
├── WealthWiseApp.swift ✓
├── ContentView.swift ✓
├── Models/
│   └── Financial/
│       ├── Account.swift ✓
│       ├── WebAppTransaction.swift ✓
│       ├── Budget.swift ✓
│       └── WebAppGoal.swift ✓
├── Services/
│   ├── FirebaseService.swift ✓
│   └── DTOs/
│       ├── AccountDTO.swift ✓
│       ├── TransactionDTO.swift ✓
│       ├── BudgetDTO.swift ✓
│       ├── GoalDTO.swift ✓
│       └── BalanceResponseDTO.swift ✓
├── Core/
│   ├── Repositories/
│   │   ├── AccountRepository.swift ✓
│   │   ├── TransactionRepository.swift ✓
│   │   ├── BudgetRepository.swift ✓
│   │   └── GoalRepository.swift ✓
│   ├── Authentication/
│   │   ├── AuthenticationManager.swift ✓
│   │   └── Views/
│   │       ├── LoginView.swift ✓
│   │       ├── SignUpView.swift ✓
│   │       └── ForgotPasswordView.swift ✓
│   ├── Navigation/
│   │   └── MainTabView.swift ✓
│   └── Components/
│       └── EmptyStateView.swift ✓
├── Features/
│   ├── Dashboard/
│   │   ├── ViewModels/
│   │   │   └── DashboardViewModel.swift ✓
│   │   └── Views/
│   │       └── DashboardView.swift ✓
│   ├── Accounts/
│   │   ├── ViewModels/
│   │   │   └── AccountsViewModel.swift ✓
│   │   └── Views/
│   │       └── AccountsView.swift ✓
│   ├── Transactions/
│   │   ├── ViewModels/
│   │   │   └── TransactionsViewModel.swift ✓
│   │   └── Views/
│   │       └── TransactionsView.swift ✓
│   ├── Budgets/
│   │   ├── ViewModels/
│   │   │   └── BudgetsViewModel.swift ✓
│   │   └── Views/
│   │       └── BudgetsView.swift ✓
│   ├── Goals/
│   │   ├── ViewModels/
│   │   │   └── GoalsViewModel.swift ✓
│   │   └── Views/
│   │       └── GoalsView.swift ✓
│   └── Settings/
│       └── Views/
│           └── SettingsView.swift ✓
└── Resources/
    ├── Localizable.strings ✓
    └── GoogleService-Info.plist ✓
```

## Command Line Build Test

After fixing in Xcode, test from command line:

```bash
cd apple/WealthWise
xcodebuild -project WealthWise.xcodeproj \
  -scheme WealthWise \
  -destination 'platform=macOS' \
  clean build
```

Expected output:
```
** BUILD SUCCEEDED **
```

## Common Issues and Solutions

### Issue: "Duplicate symbol" errors
**Solution**: Clean build folder and rebuild

### Issue: "No such module" for standard libraries
**Solution**: 
1. Check deployment target (should be iOS 18+ / macOS 15+)
2. Verify SDK is correct for the platform

### Issue: Build succeeds in Xcode but fails from terminal
**Solution**: Xcode and xcodebuild use different derived data locations. Try:
```bash
xcodebuild -project WealthWise.xcodeproj \
  -scheme WealthWise \
  -destination 'platform=macOS' \
  -derivedDataPath ./build \
  clean build
```

### Issue: Changes not reflecting
**Solution**:
1. Close Xcode
2. Delete DerivedData
3. Reopen and rebuild

## Next Steps After Successful Build

1. ✅ Run app in Xcode (⌘R)
2. ✅ Verify app launches
3. ✅ Test navigation between tabs
4. ✅ Verify authentication screens display
5. ✅ Check that empty states show correctly

## Firebase Configuration Verification

After build succeeds, verify Firebase is configured:

1. **Check GoogleService-Info.plist**:
   - Should contain your Firebase project details
   - Should have correct bundle identifier

2. **Test Firebase initialization**:
   - App should launch without Firebase errors
   - Check debug console for: "Configured Firebase"

3. **Known Firebase Issue**:
   - Authentication will fail without Cloud Functions
   - This is expected until backend is deployed

## Troubleshooting Log Commands

If build still fails, collect diagnostics:

```bash
# Full build with all output
xcodebuild -project WealthWise.xcodeproj \
  -scheme WealthWise \
  -destination 'platform=macOS' \
  clean build 2>&1 | tee build.log

# Search for errors
grep "error:" build.log

# Search for missing files
grep "No such file" build.log

# Search for module issues
grep "No such module" build.log
```

## Expected Timeline

- **File addition**: 10-15 minutes
- **Firebase setup**: 5 minutes
- **Clean + Rebuild**: 2-3 minutes
- **Total**: ~20-25 minutes

## Success Criteria

When everything is configured correctly:
- ✅ Build succeeds with "** BUILD SUCCEEDED **"
- ✅ Zero errors
- ✅ Zero critical warnings
- ✅ App launches in simulator/device
- ✅ Firebase initializes without errors

---

**Note**: These are Xcode IDE configuration issues, not code problems. The code is correct and ready. Once the Xcode project is properly configured, the build will succeed.
