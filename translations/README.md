# Cross-Platform Localization Guide

## Overview

WealthWise uses a **single source of truth** for translations that automatically generates platform-specific formats:

- **Source**: `translations/en.json` (JSON with nested structure)
- **Web**: `packages/webapp/public/locales/en.json` (i18next JSON)
- **iOS**: `translations/generated/ios/en.lproj/Localizable.strings` (Apple strings format)
- **Android**: `translations/generated/android/values/strings.xml` (Android XML format)
- **TypeScript**: `packages/shared-types/src/i18n.types.ts` (Type-safe keys)

## Translation File Structure

The master translation file uses a **hierarchical structure** organized by feature:

```json
{
  "app": {
    "name": "WealthWise",
    "tagline": "Manage your finances intelligently"
  },
  "auth": {
    "signIn": "Sign In",
    "signUp": "Sign Up",
    "displayName": "Display Name"
  },
  "pages": {
    "accounts": {
      "title": "Accounts",
      "addButton": "Add Account"
    }
  },
  "common": {
    "save": "Save",
    "cancel": "Cancel"
  }
}
```

### Key Naming Convention

Use **dot notation** for hierarchical organization:
- `app.*` - App-level strings (name, tagline)
- `auth.*` - Authentication strings
- `pages.*` - Page-specific strings (organized by feature)
- `common.*` - Reusable UI strings
- `validation.*` - Form validation messages
- `emptyState.*` - Empty state messages
- `quickActions.*` - Quick action descriptions

## Adding New Translations

### 1. Update Source File

Edit `translations/en.json`:

```json
{
  "pages": {
    "settings": {
      "title": "Settings",
      "profile": {
        "title": "Profile Settings",
        "updateButton": "Update Profile"
      }
    }
  }
}
```

### 2. Run Transformation Script

```bash
pnpm run i18n:transform
```

This generates:
- ✅ iOS Localizable.strings
- ✅ Android strings.xml
- ✅ Web JSON
- ✅ TypeScript types

### 3. Use in Code

**Web (React)**:
```tsx
import { useTranslation } from 'react-i18next';

function SettingsPage() {
  const { t } = useTranslation();
  
  return (
    <div>
      <h1>{t('pages.settings.title', 'Settings')}</h1>
      <button>{t('pages.settings.profile.updateButton', 'Update Profile')}</button>
    </div>
  );
}
```

**iOS (Swift)**:
```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text(NSLocalizedString("pages.settings.title", comment: "Settings page title"))
                Button(NSLocalizedString("pages.settings.profile.updateButton", comment: "Update profile button")) {
                    // Action
                }
            }
            .navigationTitle(NSLocalizedString("pages.settings.title", comment: ""))
        }
    }
}
```

**Android (Kotlin)**:
```kotlin
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource

@Composable
fun SettingsScreen() {
    Column {
        Text(text = stringResource(R.string.pages_settings_title))
        Button(onClick = { /* Action */ }) {
            Text(text = stringResource(R.string.pages_settings_profile_updateButton))
        }
    }
}
```

## Variable Interpolation

### Format in JSON

Use double curly braces:
```json
{
  "greeting": "Hello, {{name}}!",
  "itemCount": "You have {{count}} items"
}
```

### Platform-Specific Usage

**Web (i18next)**:
```tsx
t('greeting', { name: 'John' })
// Output: "Hello, John!"
```

**iOS (Swift)**:
```swift
String(format: NSLocalizedString("greeting", comment: ""), name)
```

**Android (Kotlin)**:
```kotlin
getString(R.string.greeting, name)
```

## Supported Languages

Current: `en` (English)

Planned:
- `hi` (Hindi)
- `te` (Telugu)

To add a new language:
1. Create `translations/<lang>.json`
2. Run `pnpm run i18n:transform`
3. Generated files appear in platform folders

## Best Practices

### ✅ DO

- **Always use translation keys** - Never hardcode user-facing strings
- **Provide fallback text** - Use second parameter: `t('key', 'Fallback')`
- **Use descriptive keys** - `auth.signIn` not `btn1`
- **Group by feature** - Keep related strings together
- **Keep strings concise** - UI constraints differ across platforms
- **Test RTL languages** - Ensure layout works for Arabic, Hebrew, etc.

### ❌ DON'T

- Don't hardcode strings: ❌ `<button>Sign In</button>`
- Don't concatenate strings: ❌ `"Hello" + name`
- Don't use vague keys: ❌ `text1`, `label2`
- Don't mix languages: ❌ `signIn: "Click करें"`
- Don't forget accessibility: Add proper ARIA labels

## Type Safety

The transformation script generates TypeScript types for all translation keys:

```typescript
// packages/shared-types/src/i18n.types.ts
export type TranslationKey = 
  | 'app.name'
  | 'auth.signIn'
  | 'pages.accounts.title'
  // ...all keys

// Use in type-safe hooks
const { t } = useTranslation();
const text: string = t('app.name'); // ✅ Valid
const invalid = t('invalid.key');   // ❌ TypeScript error
```

## Platform Integration

### Web (React + i18next)

**Configuration**: `packages/webapp/src/core/i18n/config.ts`

```typescript
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import HttpBackend from 'i18next-http-backend';

i18n
  .use(HttpBackend)
  .use(initReactI18next)
  .init({
    fallbackLng: 'en-IN',
    supportedLngs: ['en-IN', 'hi', 'te-IN'],
    backend: {
      loadPath: '/locales/{{lng}}.json'
    }
  });
```

**Usage in Components**:
```tsx
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t, i18n } = useTranslation();
  
  // Change language
  i18n.changeLanguage('hi');
  
  // Use translations
  return <h1>{t('app.name')}</h1>;
}
```

### iOS (SwiftUI)

**Setup**:
1. Copy `translations/generated/ios/en.lproj/Localizable.strings` to Xcode project
2. Add to app target in "Copy Bundle Resources"

**Usage**:
```swift
// Simple usage
Text(NSLocalizedString("auth.signIn", comment: "Sign in button"))

// With String extension
extension String {
    func localized(comment: String = "") -> String {
        NSLocalizedString(self, comment: comment)
    }
}

Text("auth.signIn".localized())
```

### Android (Kotlin)

**Setup**:
1. Copy `translations/generated/android/values/strings.xml` to `app/src/main/res/values/`

**Usage**:
```kotlin
// In Activity/Fragment
val title = getString(R.string.pages_accounts_title)

// In Composable
@Composable
fun MyScreen() {
    Text(text = stringResource(R.string.pages_accounts_title))
}
```

## Development Workflow

### 1. During Development

```bash
# Terminal 1: Run dev server
pnpm run dev

# Terminal 2: Watch for translation changes
watch -n 5 pnpm run i18n:transform
```

### 2. Before Commit

```bash
# Update translations
vi translations/en.json

# Generate platform files
pnpm run i18n:transform

# Commit all changes
git add translations/ packages/
git commit -m "feat: add settings page translations"
```

### 3. Pre-release Checklist

- [ ] All user-facing strings translated
- [ ] Platform files generated (`pnpm run i18n:transform`)
- [ ] TypeScript types updated
- [ ] Tested on all target platforms
- [ ] Verified RTL language support (if applicable)
- [ ] Accessibility labels added

## Troubleshooting

### Web: Translations not loading

```bash
# Check if files exist
ls packages/webapp/public/locales/

# Verify i18n config
cat packages/webapp/src/core/i18n/config.ts
```

### iOS: Strings not found

1. Verify `Localizable.strings` in Xcode project
2. Check "Copy Bundle Resources" in Build Phases
3. Clean build folder (Cmd+Shift+K)

### Android: Resource not found

1. Verify `strings.xml` in `res/values/`
2. Sync Gradle files
3. Clean and rebuild project

### TypeScript: Type errors

```bash
# Regenerate types
pnpm run i18n:transform

# Restart TypeScript server in VS Code
Cmd+Shift+P → "TypeScript: Restart TS Server"
```

## Examples

See real-world usage in:
- **Web**: `packages/webapp/src/features/auth/LoginPage.tsx`
- **Web**: `packages/webapp/src/features/accounts/components/AccountsList.tsx`
- **iOS**: (pending implementation)
- **Android**: (pending implementation)

## Contributing

When adding new features:

1. **Add translations first** before writing UI code
2. **Use descriptive keys** following the naming convention
3. **Provide fallback text** for graceful degradation
4. **Run transformation script** before committing
5. **Test on target platforms** if possible

## Resources

- [i18next Documentation](https://www.i18next.com/)
- [Apple Localization Guide](https://developer.apple.com/localization/)
- [Android Localization Guide](https://developer.android.com/guide/topics/resources/localization)
- [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages/)

---

**Questions?** Open an issue or check the project README.
