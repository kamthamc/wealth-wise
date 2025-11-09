# AddAccountModal Translation Fixes

## Problem
Console showing `i18next::translator: missingKey` errors for AddAccountModal component, looking for keys under `pages.accounts.modal.*`.

## Missing Keys Identified
The following keys were missing from all locale files:
- `pages.accounts.modal.addTitle` - "Add New Account"
- `pages.accounts.modal.editTitle` - "Edit Account"
- `pages.accounts.modal.addSubtitle` - "Add a new financial account to track your money"
- `pages.accounts.modal.editSubtitle` - "Update your account information"
- `pages.accounts.modal.nameLabel` - "Account Name"
- `pages.accounts.modal.namePlaceholder` - "e.g., HDFC Savings"
- `pages.accounts.modal.typeLabel` - "Account Type"
- `pages.accounts.modal.initialBalanceLabel` - "Initial Balance"
- `pages.accounts.modal.currentBalanceLabel` - "Current Balance"
- `pages.accounts.modal.addButton` - "Add Account"
- `pages.accounts.modal.saveButton` - "Save Changes"

## Solution Applied

### Files Updated

#### Public Locale Files (Runtime)
1. **`webapp/public/locales/en-IN.json`** ✅ Added modal section
2. **`webapp/public/locales/hi.json`** ✅ Already had modal keys (from previous session)
3. **`webapp/public/locales/te-IN.json`** ✅ Already had modal keys (from previous session)

#### Source Locale Files (Version Control)
1. **`webapp/src/core/i18n/locales/en-IN.json`** ✅ Added modal section
2. **`webapp/src/core/i18n/locales/hi.json`** ✅ Added modal section
3. **`webapp/src/core/i18n/locales/te-IN.json`** ✅ Added modal section

## Translation Content

### English (en-IN)
```json
"modal": {
  "addTitle": "Add New Account",
  "editTitle": "Edit Account",
  "addSubtitle": "Add a new financial account to track your money",
  "editSubtitle": "Update your account information",
  "nameLabel": "Account Name",
  "namePlaceholder": "e.g., HDFC Savings",
  "typeLabel": "Account Type",
  "initialBalanceLabel": "Initial Balance",
  "currentBalanceLabel": "Current Balance",
  "addButton": "Add Account",
  "saveButton": "Save Changes"
}
```

### Hindi (hi)
```json
"modal": {
  "addTitle": "नया खाता जोड़ें",
  "editTitle": "खाता संपादित करें",
  "addSubtitle": "अपने पैसे को ट्रैक करने के लिए एक नया वित्तीय खाता जोड़ें",
  "editSubtitle": "अपनी खाता जानकारी अपडेट करें",
  "nameLabel": "खाता का नाम",
  "namePlaceholder": "उदाहरण, HDFC बचत",
  "typeLabel": "खाता प्रकार",
  "initialBalanceLabel": "प्रारंभिक शेष",
  "currentBalanceLabel": "वर्तमान शेष",
  "addButton": "खाता जोड़ें",
  "saveButton": "परिवर्तन सहेजें"
}
```

### Telugu (te-IN)
```json
"modal": {
  "addTitle": "కొత్త ఖాతా జోడించండి",
  "editTitle": "ఖాతాను సవరించండి",
  "addSubtitle": "మీ డబ్బును ట్రాక్ చేయడానికి కొత్త ఆర్థిక ఖాతాను జోడించండి",
  "editSubtitle": "మీ ఖాతా సమాచారాన్ని అప్‌డేట్ చేయండి",
  "nameLabel": "ఖాతా పేరు",
  "namePlaceholder": "ఉదాహరణకు, HDFC సేవింగ్స్",
  "typeLabel": "ఖాతా రకం",
  "initialBalanceLabel": "ప్రారంభ బ్యాలెన్స్",
  "currentBalanceLabel": "ప్రస్తుత బ్యాలెన్స్",
  "addButton": "ఖాతా జోడించు",
  "saveButton": "మార్పులను సేవ్ చేయండి"
}
```

## How to Verify Fix

Since we updated the i18n config to use `no-cache` in development mode (previous fix), the new translations should load automatically. However, if you still see errors:

### Option 1: Hard Refresh
1. Open the Accounts page with Add Account modal
2. Press **`Cmd+Shift+R`** (Mac) or **`Ctrl+Shift+R`** (Windows/Linux)
3. Console errors should disappear

### Option 2: Restart Dev Server
```bash
cd webapp
# Stop current server (Ctrl+C)
pnpm run dev
```

## Verification Checklist
- [ ] Console shows no `missingKey` errors for AddAccountModal
- [ ] Modal title shows "Add New Account" (English)
- [ ] Modal subtitle displays correctly
- [ ] All form labels visible (Account Name, Account Type, Initial Balance)
- [ ] Placeholder text shows "e.g., HDFC Savings"
- [ ] Buttons show "Add Account" and "Cancel"
- [ ] Edit mode shows "Edit Account" title
- [ ] Edit mode shows "Current Balance" label
- [ ] Language switching works (English/Hindi/Telugu)

## Component Reference
**File**: `webapp/src/features/accounts/components/AddAccountModal.tsx`

**Translation Keys Used**:
- Lines 106-111: Modal title and subtitle
- Line 120: Name label
- Line 130: Name placeholder
- Lines 139, 144: Type label
- Line 183: Balance label (initial/current)
- Line 213: Submit button text

## Prevention
- Always check if translation keys exist before using `t()` in components
- Keep source files (`src/core/i18n/locales/`) in sync with public files
- Use no-cache mode in development to prevent stale translations
- Test language switching after adding new translation keys
- Document translation keys in component files for reference

## Related Documentation
- `docs/translation-cache-fix.md` - Browser cache troubleshooting
- `docs/i18n-language-detection.md` - i18n configuration guide
- `docs/translation-audit.md` - Comprehensive translation audit
