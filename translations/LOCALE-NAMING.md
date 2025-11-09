# Locale Naming Convention Guide

## Overview

WealthWise uses **BCP 47** locale codes with region qualifiers to support India-specific content, currency formatting, and cultural preferences.

## Format: `language-REGION`

- **language**: ISO 639-1 two-letter language code (lowercase)
- **REGION**: ISO 3166-1 alpha-2 country code (UPPERCASE)
- **Separator**: Hyphen `-`

## Supported Locales

| Locale Code | Language | Region | Currency | Date Format | Notes |
|-------------|----------|--------|----------|-------------|-------|
| `en-IN` | English | India | ₹ (INR) | DD/MM/YYYY | Default locale |
| `hi-IN` | Hindi | India | ₹ (INR) | DD/MM/YYYY | Primary Indian language |
| `te-IN` | Telugu | India | ₹ (INR) | DD/MM/YYYY | South India |
| `ta-IN` | Tamil | India | ₹ (INR) | DD/MM/YYYY | South India |

## File Structure

### Source Files (JSON)
```
translations/
├── en-IN.json          # English (India) - Source of truth
├── hi-IN.json          # Hindi (India) - Translation
├── te-IN.json          # Telugu (India) - Translation
└── ta-IN.json          # Tamil (India) - Translation
```

### Generated Platform Files

#### iOS (Apple Platforms)
```
translations/generated/ios/
├── en-IN.lproj/
│   └── Localizable.strings
├── hi-IN.lproj/
│   └── Localizable.strings
├── te-IN.lproj/
│   └── Localizable.strings
└── ta-IN.lproj/
    └── Localizable.strings
```

**iOS Usage:**
```swift
// Automatically selects based on device language
NSLocalizedString("pages.accounts.title", comment: "")

// Force specific locale
let bundle = Bundle(path: "en-IN.lproj")
NSLocalizedString("pages.accounts.title", bundle: bundle, comment: "")
```

#### Android
```
translations/generated/android/
├── values/                    # Default (en-IN)
│   └── strings.xml
├── values-hi-rIN/            # Hindi (India)
│   └── strings.xml
├── values-te-rIN/            # Telugu (India)
│   └── strings.xml
└── values-ta-rIN/            # Tamil (India)
    └── strings.xml
```

**Android Format:** `values-{language}-r{REGION}`
- `values/` = Default locale (en-IN)
- `values-hi-rIN/` = Hindi India
- `values-te-rIN/` = Telugu India

**Android Usage:**
```kotlin
// Automatically selects based on device language
getString(R.string.pages_accounts_title)

// Force specific locale
val resources = context.createConfigurationContext(
    Configuration().apply {
        setLocale(Locale("hi", "IN"))
    }
).resources
```

#### Web (i18next)
```
packages/webapp/public/locales/
├── en-IN.json
├── hi-IN.json
├── te-IN.json
└── ta-IN.json
```

**Web Usage:**
```typescript
import i18n from 'i18next';

// Initialize with locale
i18n.init({
  lng: 'en-IN',
  fallbackLng: 'en-IN',
});

// Use translations
t('pages.accounts.title');

// Change language
i18n.changeLanguage('hi-IN');
```

## Why Use Region Codes?

### 1. **Currency Display**
- `en-IN`: ₹10,000.00 (Indian Rupee)
- `en-US`: $10,000.00 (US Dollar)
- `en-GB`: £10,000.00 (British Pound)

### 2. **Number Formatting**
- `en-IN`: 1,00,000 (Indian numbering system with lakhs)
- `en-US`: 100,000 (Western numbering system)

### 3. **Date Formatting**
- `en-IN`: 15/08/2024 (DD/MM/YYYY)
- `en-US`: 08/15/2024 (MM/DD/YYYY)

### 4. **Cultural Context**
- Financial terms vary by region (e.g., "FD" common in India, "CD" in US)
- Tax terminology (GST, Income Tax India vs IRS US)
- Payment methods (UPI in India, Venmo in US)

## Adding a New Language

### Step 1: Create Translation File
```bash
cp translations/en-IN.json translations/mr-IN.json  # Marathi
```

### Step 2: Translate Content
Edit `mr-IN.json` and translate all values (keep keys unchanged):
```json
{
  "app": {
    "name": "WealthWise",
    "tagline": "आपल्या आर्थिक व्यवस्थापना हुशारपणे करा"
  }
}
```

### Step 3: Register Locale in Script
Edit `scripts/transform-i18n.mjs`:
```javascript
const SUPPORTED_LANGUAGES = [
  // ... existing locales
  { 
    code: 'mr-IN', 
    name: 'Marathi (India)', 
    iosCode: 'mr-IN', 
    androidCode: 'mr-rIN' 
  },
];
```

### Step 4: Generate Platform Files
```bash
node scripts/transform-i18n.mjs
```

### Step 5: Configure App
Update your app's language selection to include the new locale.

## Best Practices

### 1. **Always Include Region Code**
❌ Bad: `en.json`, `hi.json`
✅ Good: `en-IN.json`, `hi-IN.json`

### 2. **Keep Keys Consistent**
Translation keys must be identical across all locale files:
```json
// en-IN.json
{ "pages.accounts.title": "Accounts" }

// hi-IN.json  
{ "pages.accounts.title": "खाते" }
```

### 3. **Use Placeholders for Dynamic Content**
```json
{
  "greeting": "Welcome, {{name}}!",
  "balance": "Your balance is {{amount}}"
}
```

### 4. **Support Pluralization**
```json
{
  "items": "{{count}} item",
  "items_other": "{{count}} items"
}
```

### 5. **Provide Context in Comments**
```json
{
  "save": "Save",
  "_save_comment": "Button label for saving form data"
}
```

## Testing Locales

### iOS Simulator
1. Settings → General → Language & Region
2. Add Hindi (India)
3. Relaunch app

### Android Emulator
1. Settings → System → Languages & Input
2. Add Hindi (India)
3. Relaunch app

### Web Browser
```javascript
// Test in console
i18n.changeLanguage('hi-IN');
```

## Locale Fallback Strategy

```
hi-IN → en-IN → English fallback text
te-IN → en-IN → English fallback text
```

If a key is missing in Hindi, it falls back to English (India), then to the fallback text in code.

## Resources

- [BCP 47 Language Tags](https://www.ietf.org/rfc/bcp/bcp47.txt)
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [ISO 3166-1 Country Codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
- [i18next Documentation](https://www.i18next.com/)
- [iOS Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [Android Localization Guide](https://developer.android.com/guide/topics/resources/localization)

## Summary

✅ **DO:**
- Use `en-IN` for Indian English
- Include region codes for all locales
- Keep translation keys consistent
- Test all supported locales

❌ **DON'T:**
- Use simple `en` without region
- Mix different naming conventions
- Hardcode locale-specific content in code
- Forget to update transformation script
