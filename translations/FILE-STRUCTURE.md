# Cross-Platform Localization - File Structure

## 📁 Complete Directory Structure

```
wealth-wise/
│
├── translations/                          # 🌍 Master translation directory
│   ├── en.json                           # ✅ SOURCE OF TRUTH - Master English translations
│   ├── README.md                         # ✅ Full documentation (4,500+ words)
│   ├── QUICK-START.md                    # ✅ Quick reference guide
│   ├── IMPLEMENTATION-SUMMARY.md         # ✅ Implementation details and status
│   ├── FILE-STRUCTURE.md                 # ✅ This file
│   │
│   └── generated/                        # 🤖 Auto-generated platform files
│       ├── ios/
│       │   ├── en.lproj/
│       │   │   └── Localizable.strings   # ✅ iOS format (Apple .strings)
│       │   ├── hi.lproj/                 # ⏳ Hindi (future)
│       │   │   └── Localizable.strings
│       │   └── te.lproj/                 # ⏳ Telugu (future)
│       │       └── Localizable.strings
│       │
│       └── android/
│           ├── values/                    # ✅ English (default)
│           │   └── strings.xml
│           ├── values-hi/                 # ⏳ Hindi (future)
│           │   └── strings.xml
│           └── values-te/                 # ⏳ Telugu (future)
│               └── strings.xml
│
├── scripts/
│   ├── transform-i18n.mjs                # ✅ Transformation script (Node.js ES Module)
│   └── transform-i18n.ts                 # ⏳ TypeScript version (backup)
│
├── packages/
│   ├── webapp/                           # 🌐 Web application
│   │   ├── src/
│   │   │   ├── core/
│   │   │   │   └── i18n/
│   │   │   │       └── config.ts         # ✅ i18next configuration
│   │   │   │
│   │   │   └── features/
│   │   │       ├── auth/
│   │   │       │   └── LoginPage.tsx     # ✅ Fully localized
│   │   │       │
│   │   │       ├── accounts/
│   │   │       │   └── components/
│   │   │       │       └── AccountsList.tsx  # ✅ Already localized
│   │   │       │
│   │   │       ├── budgets/              # ⏳ Needs localization
│   │   │       ├── transactions/         # ⏳ Needs localization
│   │   │       └── investments/          # ⏳ Needs localization
│   │   │
│   │   └── public/
│   │       └── locales/                  # 🌐 Web translation files
│   │           ├── en.json               # ✅ English (copy of translations/en.json)
│   │           ├── hi.json               # ⏳ Hindi (future)
│   │           └── te.json               # ⏳ Telugu (future)
│   │
│   └── shared-types/
│       └── src/
│           └── i18n.types.ts             # ✅ TypeScript type definitions
│
├── apple/                                # 🍎 iOS/macOS application
│   └── WealthWise/
│       ├── en.lproj/                     # ⏳ iOS localization (future)
│       │   └── Localizable.strings       # Copy from translations/generated/ios/
│       ├── hi.lproj/                     # ⏳ Hindi (future)
│       └── te.lproj/                     # ⏳ Telugu (future)
│
├── android/                              # 🤖 Android application (future)
│   └── app/
│       └── src/
│           └── main/
│               └── res/
│                   ├── values/           # ⏳ English (future)
│                   │   └── strings.xml   # Copy from translations/generated/android/
│                   ├── values-hi/        # ⏳ Hindi (future)
│                   └── values-te/        # ⏳ Telugu (future)
│
├── package.json                          # ✅ Root package.json with scripts
│   # Scripts:
│   #   "i18n:transform": "node scripts/transform-i18n.mjs"
│
└── .github/
    └── copilot-instructions.md           # ✅ Updated with localization guidelines
```

## 🔄 Data Flow

```
Developer edits:
  translations/en.json
         |
         v
  [pnpm run i18n:transform]
         |
         v
  scripts/transform-i18n.mjs
         |
         +------------------+------------------+------------------+
         |                  |                  |                  |
         v                  v                  v                  v
    iOS .strings      Android .xml       Web .json        TypeScript types
         |                  |                  |                  |
         v                  v                  v                  v
  translations/      translations/      packages/webapp/   packages/shared-types/
   generated/ios/     generated/android/ public/locales/    src/i18n.types.ts
         |                  |                  |                  |
         v                  v                  v                  v
  Copy to Xcode      Copy to Android    Loaded by i18next  Used for validation
```

## 📝 File Descriptions

### Core Translation Files

| File | Purpose | Status | Auto-Generated |
|------|---------|--------|----------------|
| `translations/en.json` | Master English translations | ✅ Active | ❌ Manual |
| `translations/hi.json` | Hindi translations | ⏳ Future | ❌ Manual |
| `translations/te.json` | Telugu translations | ⏳ Future | ❌ Manual |

### Generated Files

| File | Platform | Format | Status |
|------|----------|--------|--------|
| `translations/generated/ios/en.lproj/Localizable.strings` | iOS/macOS | Apple .strings | ✅ Generated |
| `translations/generated/android/values/strings.xml` | Android | XML | ✅ Generated |
| `packages/webapp/public/locales/en.json` | Web | JSON | ✅ Generated |
| `packages/shared-types/src/i18n.types.ts` | TypeScript | .ts | ✅ Generated |

### Documentation Files

| File | Purpose | Word Count | Status |
|------|---------|-----------|--------|
| `translations/README.md` | Full documentation | 4,500+ | ✅ Complete |
| `translations/QUICK-START.md` | Quick reference | 1,200+ | ✅ Complete |
| `translations/IMPLEMENTATION-SUMMARY.md` | Implementation details | 3,500+ | ✅ Complete |
| `translations/FILE-STRUCTURE.md` | This file | 800+ | ✅ Complete |

### Scripts

| File | Language | Purpose | Status |
|------|----------|---------|--------|
| `scripts/transform-i18n.mjs` | JavaScript (ESM) | Generate platform files | ✅ Working |
| `scripts/transform-i18n.ts` | TypeScript | Alternative version | ⏳ Backup |

### Configuration Files

| File | Purpose | Status |
|------|---------|--------|
| `packages/webapp/src/core/i18n/config.ts` | i18next web config | ✅ Active |
| `.github/copilot-instructions.md` | Dev guidelines | ✅ Updated |

## 🎯 Important Paths by Use Case

### Adding New Translations
1. Edit: `translations/en.json`
2. Run: `pnpm run i18n:transform`
3. Commit all files in `translations/generated/` and `packages/webapp/public/locales/`

### Using Translations in Web
1. Import: `import { useTranslation } from 'react-i18next';`
2. Get function: `const { t } = useTranslation();`
3. Use: `{t('auth.signIn', 'Sign In')}`
4. Reference: See `packages/webapp/src/features/auth/LoginPage.tsx`

### Setting up iOS
1. Copy: `translations/generated/ios/en.lproj/Localizable.strings`
2. To: `apple/WealthWise/en.lproj/Localizable.strings`
3. Add to: Xcode project → Build Phases → Copy Bundle Resources
4. Use: `NSLocalizedString("auth.signIn", comment: "")`

### Setting up Android
1. Copy: `translations/generated/android/values/strings.xml`
2. To: `android/app/src/main/res/values/strings.xml`
3. Sync: File → Sync Project with Gradle Files
4. Use: `getString(R.string.auth_signIn)`

## 📊 File Ownership

| Directory | Owner | Review Required |
|-----------|-------|-----------------|
| `translations/*.json` | All developers | No |
| `translations/generated/` | Script only | ❌ Do not edit manually |
| `packages/webapp/public/locales/` | Script only | ❌ Do not edit manually |
| `packages/shared-types/src/i18n.types.ts` | Script only | ❌ Do not edit manually |
| `scripts/transform-i18n.mjs` | Core team | Yes |
| `translations/*.md` | Documentation team | No |

## ⚠️ Important Notes

### DO NOT Edit Manually
These files are auto-generated and will be overwritten:
- ❌ `translations/generated/**/*`
- ❌ `packages/webapp/public/locales/*.json`
- ❌ `packages/shared-types/src/i18n.types.ts`

### Always Edit
- ✅ `translations/en.json` - Master source
- ✅ `translations/hi.json` - Hindi (when created)
- ✅ `translations/te.json` - Telugu (when created)

### Run After Changes
```bash
pnpm run i18n:transform
```

## 🔍 Finding Files

### Quick Commands

```bash
# List all translation files
find translations -name "*.json" -o -name "*.strings" -o -name "*.xml"

# Find components using translations
grep -r "useTranslation" packages/webapp/src --include="*.tsx"

# Check for hardcoded strings (needs localization)
grep -r '"[A-Z]' packages/webapp/src/features --include="*.tsx" | grep -v "className"

# View generated iOS strings
cat translations/generated/ios/en.lproj/Localizable.strings

# View generated Android XML
cat translations/generated/android/values/strings.xml

# Check TypeScript types
cat packages/shared-types/src/i18n.types.ts
```

## 📦 Git Tracking

### Committed Files
- ✅ `translations/en.json`
- ✅ `translations/generated/**/*` (generated but committed for easy access)
- ✅ `packages/webapp/public/locales/*.json`
- ✅ `packages/shared-types/src/i18n.types.ts`
- ✅ All documentation files
- ✅ `scripts/transform-i18n.mjs`

### .gitignore Considerations
Currently all files are committed. Consider adding to `.gitignore` if:
- Build time generation is preferred
- Want to reduce repo size
- Platform-specific repos maintain their own copies

---

**Last Updated**: 2024
**Maintainer**: Development Team
