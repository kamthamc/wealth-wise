# Quick Reference: Language System

## Switching Languages

### Via URL (Easiest for Testing)
```
http://localhost:5173?lng=hi        # Hindi
http://localhost:5173?lng=te-IN     # Telugu
http://localhost:5173?lng=en-IN     # English
```

### Via Browser Console
```javascript
// Change language immediately
localStorage.setItem('app-language', 'hi');
location.reload();

// Or use i18n API (if app is already loaded)
window.i18n.changeLanguage('te-IN');
```

### Via Component Code
```typescript
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { i18n } = useTranslation();
  
  return (
    <button onClick={() => i18n.changeLanguage('hi')}>
      Switch to Hindi
    </button>
  );
}
```

## Using Translations in Components

### Basic Translation
```typescript
import { useTranslation } from 'react-i18next';

function Welcome() {
  const { t } = useTranslation();
  
  return <h1>{t('common.welcome')}</h1>;
  // Output (en-IN): "Welcome to WealthWise"
  // Output (hi): "वेल्थवाइज में आपका स्वागत है"
  // Output (te-IN): "వెల్త్‌వైజ్‌కి స్వాగతం"
}
```

### With Variables
```typescript
const { t } = useTranslation();

// Translation key: "pages.accounts.stats.balance": "Total Balance: {{amount}}"
t('pages.accounts.stats.balance', { amount: '₹10,000' });
// Output: "Total Balance: ₹10,000"
```

### Pluralization (Not yet implemented)
```typescript
// Future feature
t('items', { count: 1 });  // "1 item"
t('items', { count: 5 });  // "5 items"
```

## Available Translation Keys

### Common
```typescript
t('common.welcome')           // "Welcome to WealthWise"
t('common.loading')           // "Loading..."
t('common.error')            // "Error"
t('common.success')          // "Success"
t('common.cancel')           // "Cancel"
t('common.save')             // "Save"
t('common.delete')           // "Delete"
t('common.edit')             // "Edit"
t('common.add')              // "Add"
t('common.search')           // "Search"
t('common.filter')           // "Filter"
```

### Navigation
```typescript
t('navigation.dashboard')     // "Dashboard"
t('navigation.accounts')      // "Accounts"
t('navigation.transactions')  // "Transactions"
t('navigation.budgets')       // "Budgets"
t('navigation.goals')         // "Goals"
t('navigation.reports')       // "Reports"
t('navigation.settings')      // "Settings"
```

### Pages - Accounts
```typescript
t('pages.accounts.title')              // "Accounts"
t('pages.accounts.subtitle')           // "Manage your financial accounts and track balances"
t('pages.accounts.addButton')          // "Add Account"
t('pages.accounts.search')             // "Search accounts..."
t('pages.accounts.empty.title')        // "No accounts yet"
t('pages.accounts.empty.description')  // "Start tracking your finances..."
```

### Forms
```typescript
t('forms.required')           // "This field is required"
t('forms.invalid')           // "Invalid value"
t('forms.email')             // "Please enter a valid email"
t('forms.minLength')         // "Minimum {{min}} characters"
```

### Errors
```typescript
t('errors.generic')          // "Something went wrong"
t('errors.network')          // "Network error. Please try again."
t('errors.notFound')         // "Not found"
t('errors.unauthorized')     // "Unauthorized access"
```

## Current Language Info

### Get Current Language
```typescript
const { i18n } = useTranslation();

console.log(i18n.language);           // 'en-IN', 'hi', or 'te-IN'
console.log(i18n.resolvedLanguage);   // Resolved language after fallbacks
```

### Check if Language is Loaded
```typescript
const { i18n } = useTranslation();

console.log(i18n.hasResourceBundle('hi', 'translation'));  // true/false
```

## Testing Different Languages

### Method 1: URL Parameter (Recommended)
1. Open app with `?lng=hi`
2. Language is automatically detected and applied
3. Preference saved to localStorage

### Method 2: Browser DevTools
```javascript
// In console
localStorage.setItem('app-language', 'te-IN');
location.reload();
```

### Method 3: Change Browser Language
1. Chrome: Settings → Languages → Add Telugu
2. Set Telugu as preferred language
3. Reload app

## Language Files Location

```
public/
  locales/
    en-IN.json    # English (India)
    hi.json       # Hindi
    te-IN.json    # Telugu (India)
```

## Detection Priority (Top to Bottom)

1. ✅ **localStorage.getItem('app-language')** ← User preference
2. ✅ **sessionStorage.getItem('app-language')** ← Temporary
3. ✅ **Cookie 'i18next'** ← Server preference
4. ✅ **URL ?lng=hi** ← Forced via URL
5. ✅ **Custom browser mapping** ← Intelligent detection
6. ✅ **navigator.language** ← Browser/OS setting
7. ✅ **HTML lang attribute** ← Document fallback

## Supported Languages

| Code | Language | Native Name | Status |
|------|----------|-------------|---------|
| `en-IN` | English (India) | English | ✅ Complete |
| `hi` | Hindi | हिंदी | ✅ Complete |
| `te-IN` | Telugu (India) | తెలుగు | ✅ Complete |

## Common Issues

### Language not changing?
```javascript
// Clear localStorage and reload
localStorage.removeItem('app-language');
location.reload();
```

### Seeing translation keys instead of text?
```
Check: public/locales/{language}.json file exists
Check: Translation key exists in file
Check: No typos in translation key
```

### Wrong language showing?
```javascript
// Check what's stored
console.log(localStorage.getItem('app-language'));

// Force change
localStorage.setItem('app-language', 'en-IN');
location.reload();
```

## Next Steps

To use translations in your component:

1. Import the hook:
   ```typescript
   import { useTranslation } from 'react-i18next';
   ```

2. Use in component:
   ```typescript
   const { t } = useTranslation();
   ```

3. Replace hardcoded strings:
   ```typescript
   // Before
   <h1>Accounts</h1>
   
   // After
   <h1>{t('pages.accounts.title')}</h1>
   ```

4. Test with different languages via URL:
   ```
   ?lng=hi
   ?lng=te-IN
   ```

## Performance Tips

- ✅ Translations are lazy-loaded (only when language changes)
- ✅ HTTP cache is aggressive (translations cached in browser)
- ✅ Only current language in memory
- ✅ Suspense for loading states
- ✅ Preload fallback language (en-IN) for instant display

## Future Enhancements

- [ ] Language selector UI component
- [ ] More Indian languages (Tamil, Kannada, Malayalam)
- [ ] RTL support (Arabic, Urdu)
- [ ] Pluralization rules
- [ ] Date/time formatting per locale
- [ ] Number formatting per locale
- [ ] Currency formatting per locale
