# Cross-Platform Localization - Quick Start

## 🎯 Quick Commands

```bash
# Generate all platform files from translations/en.json
pnpm run i18n:transform

# Or manually
node scripts/transform-i18n.mjs
```

## 📁 File Structure

```
translations/
├── en.json                        # 📝 SOURCE OF TRUTH
├── README.md                      # 📖 Full documentation
├── QUICK-START.md                 # ⚡ This file
└── generated/
    ├── ios/
    │   └── en.lproj/
    │       └── Localizable.strings  # 🍎 iOS format
    └── android/
        └── values/
            └── strings.xml          # 🤖 Android format

packages/
├── webapp/public/locales/
│   └── en.json                    # 🌐 Web (i18next) format
└── shared-types/src/
    └── i18n.types.ts              # 📘 TypeScript types
```

## ✏️ Adding New Translations (3 Steps)

### 1. Edit `translations/en.json`

```json
{
  "pages": {
    "newFeature": {
      "title": "New Feature",
      "description": "This is a new feature"
    }
  }
}
```

### 2. Run Transform Script

```bash
pnpm run i18n:transform
```

### 3. Use in Code

**Web (React)**:
```tsx
import { useTranslation } from 'react-i18next';

const { t } = useTranslation();
<h1>{t('pages.newFeature.title', 'New Feature')}</h1>
```

**iOS (Swift)**:
```swift
Text(NSLocalizedString("pages.newFeature.title", comment: ""))
```

**Android (Kotlin)**:
```kotlin
Text(text = stringResource(R.string.pages_newFeature_title))
```

## 🔑 Key Naming Rules

| Prefix | Usage | Example |
|--------|-------|---------|
| `app.*` | App name, tagline | `app.name` |
| `auth.*` | Login, signup, auth | `auth.signIn` |
| `pages.*` | Page-specific strings | `pages.accounts.title` |
| `common.*` | Reusable UI elements | `common.save` |
| `validation.*` | Form errors | `validation.required` |
| `emptyState.*` | Empty states | `emptyState.accounts.title` |

## 🌍 Currently Localized

✅ **LoginPage** (`packages/webapp/src/features/auth/LoginPage.tsx`)
- All strings converted to use `t()` function
- Example: `t('auth.signIn', 'Sign In')`

✅ **AccountsList** (`packages/webapp/src/features/accounts/components/AccountsList.tsx`)
- Already using i18next
- Example: `t('pages.accounts.title', 'Accounts')`

## 🚀 Next Steps

### Immediate Priorities

1. **Extract more hardcoded strings**:
   - Budget components
   - Transaction components
   - Investment components
   - Dashboard components

2. **Add more languages**:
   ```bash
   # Create new language file
   cp translations/en.json translations/hi.json
   
   # Edit translations
   vi translations/hi.json
   
   # Generate platform files
   pnpm run i18n:transform
   ```

3. **Implement iOS localization**:
   - Copy `translations/generated/ios/en.lproj/Localizable.strings` to Xcode
   - Add to Bundle Resources
   - Use `NSLocalizedString()` in SwiftUI views

4. **Implement Android localization**:
   - Copy `translations/generated/android/values/strings.xml` to Android project
   - Use `getString(R.string.*)` in Kotlin code

## 📝 Common Patterns

### Button Text
```json
{
  "pages": {
    "feature": {
      "saveButton": "Save Changes",
      "cancelButton": "Cancel",
      "deleteButton": "Delete"
    }
  }
}
```

### Form Labels
```json
{
  "forms": {
    "account": {
      "nameLabel": "Account Name",
      "namePlaceholder": "Enter account name",
      "typeLabel": "Account Type"
    }
  }
}
```

### Error Messages
```json
{
  "errors": {
    "network": "Network error. Please try again.",
    "auth": {
      "invalidCredentials": "Invalid email or password",
      "emailInUse": "Email already in use"
    }
  }
}
```

## 🔍 Finding Hardcoded Strings

```bash
# Search for hardcoded strings in components
grep -r "\"[A-Z]" packages/webapp/src/features --include="*.tsx" | grep -v "className" | head -20

# Search specific components
grep "\"[A-Z]" packages/webapp/src/features/budgets/**/*.tsx
```

## 🎨 Best Practices

✅ **DO**:
- Use descriptive keys: `auth.signIn` ✅
- Provide fallbacks: `t('key', 'Fallback')` ✅
- Keep strings in JSON first ✅
- Run transform before commit ✅

❌ **DON'T**:
- Hardcode strings: `"Sign In"` ❌
- Use vague keys: `text1` ❌
- Skip transformation step ❌
- Mix languages: `"Sign करें"` ❌

## 🐛 Troubleshooting

### Script won't run?
```bash
# Make executable
chmod +x scripts/transform-i18n.mjs

# Run directly
node scripts/transform-i18n.mjs
```

### Translations not showing in web app?
```bash
# Check if file exists
ls packages/webapp/public/locales/en.json

# Clear browser cache
# Hard refresh (Cmd+Shift+R)
```

### TypeScript errors?
```bash
# Regenerate types
pnpm run i18n:transform

# Restart TypeScript in VS Code
Cmd+Shift+P → "TypeScript: Restart TS Server"
```

## 📚 Full Documentation

See [`translations/README.md`](./README.md) for:
- Detailed platform integration guides
- Variable interpolation examples
- RTL language support
- Advanced usage patterns
- Contributing guidelines

---

**Quick help**: Open an issue or check the main README
