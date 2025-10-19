# Translation Cache Issue - Troubleshooting Guide

## Problem
Console showing `i18next::translator: missingKey` errors for Settings page, even though translation keys exist in `public/locales/en-IN.json`.

## Root Cause
i18next HTTP backend was configured with `cache: 'force-cache'`, causing the browser to cache old translation files that didn't have the settings keys.

## Solution Applied
Updated `webapp/src/core/i18n/config.ts` to use dynamic caching:
```typescript
requestOptions: {
  // Use no-cache in development, force-cache in production
  cache: import.meta.env.DEV ? 'no-cache' : 'force-cache',
}
```

## How to Verify Fix

### Option 1: Hard Refresh (Quick)
1. Open the app in your browser
2. Navigate to Settings page
3. Press `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows/Linux)
4. Check console - missingKey errors should be gone

### Option 2: Clear Browser Cache (Thorough)
**Chrome/Edge:**
1. Open DevTools (F12)
2. Right-click refresh button
3. Select "Empty Cache and Hard Reload"

**Firefox:**
1. Open DevTools (F12)
2. Go to Storage tab
3. Right-click "Cache Storage" → Clear
4. Refresh page

**Safari:**
1. Develop menu → Empty Caches
2. Refresh page

### Option 3: Dev Server Restart (Nuclear)
```bash
cd webapp
pnpm run dev
```
Then hard refresh the browser.

## Prevention
- **Development**: No-cache mode prevents stale translations
- **Production**: Force-cache improves performance (translations don't change often)
- **Testing**: Always hard refresh after updating translation files

## Verification Checklist
- [ ] Console shows no `missingKey` errors
- [ ] Settings page displays proper English text
- [ ] Theme toggle shows "Light", "Dark", "System"
- [ ] Language selector shows "Language"
- [ ] All section titles and descriptions visible
- [ ] "Coming Soon" messages display properly

## Translation Files Updated
- ✅ `webapp/public/locales/en-IN.json` - Complete settings section
- ✅ `webapp/public/locales/hi.json` - Hindi translations
- ✅ `webapp/public/locales/te-IN.json` - Telugu translations
- ✅ `webapp/src/core/i18n/locales/*.json` - Source files (for reference)

## Related Files
- `webapp/src/core/i18n/config.ts` - i18n configuration (cache fix)
- `webapp/src/features/settings/components/SettingsPage.tsx` - Component using translations
- `webapp/public/locales/*.json` - Runtime translation files

## Notes
- i18next loads translations from `public/locales/` at runtime (HTTP backend)
- Source files in `src/core/i18n/locales/` are for version control only
- Always update both source and public files when adding translations
- Browser caching is the #1 cause of "missing key" errors during development
