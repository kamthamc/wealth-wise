# Browser Locale Initialization Guide

## Overview
The user preferences system now automatically detects and initializes locale settings from the user's browser when they first use the application. Users can then customize these settings through the PreferencesSettings component.

## How It Works

### 1. Browser Locale Detection

When a user first calls `getUserPreferences()`:
- The webapp sends the browser locale (`navigator.language`) to the Cloud Function
- The Cloud Function detects the best matching locale configuration
- Preferences are initialized with appropriate defaults for that locale

**Supported Locales:**
- `en-IN` - English (India) - INR, DD/MM/YYYY, Indian numbering
- `en-US` - English (United States) - USD, MM/DD/YYYY, Western numbering
- `en-GB` - English (United Kingdom) - GBP, DD/MM/YYYY, Western numbering
- `en-CA` - English (Canada) - CAD, DD/MM/YYYY, Western numbering
- `en-AU` - English (Australia) - AUD, DD/MM/YYYY, Western numbering
- `en-SG` - English (Singapore) - SGD, DD/MM/YYYY, Western numbering
- `de-DE` - German (Germany) - EUR, DD.MM.YYYY, 24h time
- `fr-FR` - French (France) - EUR, DD/MM/YYYY, 24h time
- `ja-JP` - Japanese (Japan) - JPY, YYYY/MM/DD, 24h time
- `zh-CN` - Chinese (China) - CNY, YYYY-MM-DD, 24h time

### 2. Locale Matching Logic

The system uses intelligent fallback matching:

```typescript
// 1. Try exact match (e.g., 'en-IN')
if (LOCALE_CONFIGURATIONS['en-IN']) {
  return LOCALE_CONFIGURATIONS['en-IN'];
}

// 2. Try language-only match (e.g., 'en' from 'en-GB')
const language = 'en-GB'.split('-')[0]; // 'en'
// Finds first locale starting with 'en-'

// 3. Default to en-IN if no match
return LOCALE_CONFIGURATIONS['en-IN'];
```

**Examples:**
- Browser locale `en-IN` → Uses `en-IN` config (India)
- Browser locale `en-NZ` → Matches `en-` prefix → Uses `en-US` config (closest match)
- Browser locale `es-ES` → No match → Uses `en-IN` config (default)
- Browser locale `de-DE` → Uses `de-DE` config (Germany)

### 3. Initialization Flow

```
User First Login
    ↓
Webapp calls getUserPreferences()
    ↓
Sends browserLocale: 'en-US'
    ↓
Cloud Function receives request
    ↓
Check if preferences exist
    ↓
NOT FOUND → Create new preferences
    ↓
detectLocaleFromBrowser('en-US')
    ↓
Returns LocaleConfiguration for en-US:
  - currency: 'USD'
  - locale: 'en-US'
  - dateFormat: 'MM/DD/YYYY'
  - timeFormat: '12h'
  - numberFormat: 'western'
  - weekStartDay: 0 (Sunday)
  - useFinancialYear: false
  - financialYearStartMonth: 1 (January)
    ↓
Create UserPreferences with these defaults
    ↓
Save to Firestore
    ↓
Return preferences to webapp
    ↓
Webapp uses locale for all formatting
```

### 4. User Customization

After initialization, users can customize any preference:

```typescript
// User changes currency from USD to INR
await preferencesApi.update({ currency: 'INR' });

// User changes locale from en-US to en-IN
await preferencesApi.update({ locale: 'en-IN' });

// User changes date format
await preferencesApi.update({ dateFormat: 'DD/MM/YYYY' });

// All subsequent API calls use updated preferences
```

## Implementation Details

### Backend (Cloud Functions)

**File:** `packages/functions/src/preferences.ts`

```typescript
function createDefaultPreferences(userId: string, browserLocale?: string): UserPreferences {
  const now = new Date().toISOString();
  const defaults = createDefaultPreferencesFromLocale(browserLocale);
  
  return {
    ...defaults,
    userId,
    createdAt: now,
    updatedAt: now,
  } as UserPreferences;
}

export const getUserPreferences = onCall<
  GetUserPreferencesRequest,
  Promise<GetUserPreferencesResponse>
>(async (request) => {
  const userId = getUserAuthenticated(request);
  const { browserLocale } = request.data || {};

  const prefDoc = await db.collection('user_preferences').doc(userId).get();

  if (!prefDoc.exists) {
    // Initialize with browser locale
    console.log(`Creating preferences for user ${userId} with browser locale: ${browserLocale || 'not provided'}`);
    const defaultPrefs = createDefaultPreferences(userId, browserLocale);
    await db.collection('user_preferences').doc(userId).set(defaultPrefs);
    
    return { preferences: defaultPrefs };
  }

  return { preferences: prefDoc.data() as UserPreferences };
});
```

### Shared Types

**File:** `packages/shared-types/src/UserPreferences.ts`

```typescript
export function detectLocaleFromBrowser(browserLocale?: string): LocaleConfiguration {
  const locale = browserLocale || 'en-IN';
  
  // Try exact match
  if (LOCALE_CONFIGURATIONS[locale]) {
    return LOCALE_CONFIGURATIONS[locale];
  }
  
  // Try language-only match
  const language = locale.split('-')[0];
  const languageMatch = Object.keys(LOCALE_CONFIGURATIONS).find(
    key => key.startsWith(`${language}-`)
  );
  
  if (languageMatch) {
    return LOCALE_CONFIGURATIONS[languageMatch];
  }
  
  // Default to en-IN
  return LOCALE_CONFIGURATIONS['en-IN'];
}

export function createDefaultPreferencesFromLocale(browserLocale?: string): Omit<UserPreferences, 'userId' | 'createdAt' | 'updatedAt'> {
  const localeConfig = detectLocaleFromBrowser(browserLocale);
  
  return {
    // Localization (from browser)
    currency: localeConfig.currency,
    locale: localeConfig.locale,
    language: localeConfig.locale.split('-')[0],
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Kolkata',
    
    // Regional Settings
    dateFormat: localeConfig.dateFormat,
    timeFormat: localeConfig.timeFormat,
    numberFormat: localeConfig.numberFormat,
    weekStartDay: localeConfig.weekStartDay,
    
    // Financial Settings
    useFinancialYear: localeConfig.useFinancialYear,
    financialYearStartMonth: localeConfig.financialYearStartMonth,
    hideSensitiveData: false,
    
    // ... other defaults
  };
}
```

### Webapp API Client

**File:** `packages/webapp/src/core/api/preferencesApi.ts`

```typescript
export const getUserPreferences = async (): Promise<UserPreferences> => {
  const callable = httpsCallable<GetUserPreferencesRequest, GetUserPreferencesResponse>(
    functions,
    'getUserPreferences'
  );
  
  // Detect browser locale for first-time initialization
  const browserLocale = navigator.language || navigator.languages?.[0] || 'en-IN';
  
  const result = await callable({ browserLocale });
  return result.data.preferences;
};
```

### Webapp Hooks

**File:** `packages/webapp/src/hooks/usePreferences.ts`

```typescript
export function usePreferences(): UsePreferencesResult {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadPreferences = async () => {
    try {
      setLoading(true);
      setError(null);
      const prefs = await preferencesApi.get();
      setPreferences(prefs);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to load preferences'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPreferences();
  }, []);

  return { preferences, loading, error, reload: loadPreferences };
}
```

## Usage Examples

### 1. Using usePreferences Hook

```typescript
import { usePreferences } from '@/hooks/usePreferences';
import { formatCurrency } from '@/utils';

function MyComponent() {
  const { preferences, loading, error } = usePreferences();
  
  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error.message} />;
  if (!preferences) return null;
  
  // Use user's locale for formatting
  const formatted = formatCurrency(1000000, preferences.currency, preferences.locale);
  // Output depends on user's browser/settings:
  // en-IN: "₹10,00,000.00"
  // en-US: "$1,000,000.00"
  // de-DE: "1.000.000,00 €"
  
  return <div>{formatted}</div>;
}
```

### 2. NetWorthCard with Locale

```typescript
import { usePreferences } from '@/hooks/usePreferences';
import { formatCurrency } from '@/utils';

export function NetWorthCard() {
  const { preferences, loading: prefsLoading } = usePreferences();
  const [data, setData] = useState(null);
  
  useEffect(() => {
    if (!prefsLoading && preferences) {
      // Fetch data only after preferences are loaded
      loadNetWorth();
    }
  }, [prefsLoading, preferences]);
  
  if (prefsLoading || !preferences) {
    return <LoadingSpinner />;
  }
  
  // Format using user's locale (from browser on first use)
  const formatted = formatCurrency(
    data.totalNetWorth,
    data.currency,
    preferences.locale  // Browser-detected locale
  );
  
  return <div>{formatted}</div>;
}
```

### 3. Updating Locale

```typescript
import { preferencesApi } from '@/core/api';
import { usePreferences } from '@/hooks/usePreferences';

function LocaleSelector() {
  const { preferences, reload } = usePreferences();
  
  const handleLocaleChange = async (newLocale: string) => {
    // Update locale in preferences
    await preferencesApi.update({ locale: newLocale });
    
    // Reload preferences
    await reload();
    
    // All subsequent formatting will use new locale
  };
  
  return (
    <select 
      value={preferences?.locale} 
      onChange={(e) => handleLocaleChange(e.target.value)}
    >
      <option value="en-IN">English (India)</option>
      <option value="en-US">English (United States)</option>
      <option value="de-DE">Deutsch (Germany)</option>
      <option value="ja-JP">日本語 (Japan)</option>
    </select>
  );
}
```

## Benefits

### 1. **Automatic Localization**
- No manual setup required for users
- Preferences match user's browser/OS settings
- Immediate locale-appropriate experience

### 2. **Consistent Formatting**
- Currency symbols match locale (₹, $, €, ¥)
- Number grouping respects locale (Indian lakh/crore vs Western million/billion)
- Date formats follow regional conventions
- Time formats use 12h/24h based on locale

### 3. **User Control**
- Browser detection is just the starting point
- Users can customize any preference
- Changes persist across sessions
- Easy to switch between locales

### 4. **Intelligent Fallbacks**
- Language-only matching (en-NZ → en-US)
- Graceful degradation to defaults
- No errors for unsupported locales

### 5. **Performance**
- Browser locale detected once on first use
- Preferences cached in Firestore
- Single API call for all preferences
- No repeated locale detection

## Testing

### Test Browser Locale Detection

```typescript
import { detectLocaleFromBrowser } from '@svc/wealth-wise-shared-types';

describe('detectLocaleFromBrowser', () => {
  it('returns exact match for en-IN', () => {
    const config = detectLocaleFromBrowser('en-IN');
    expect(config.currency).toBe('INR');
    expect(config.locale).toBe('en-IN');
    expect(config.numberFormat).toBe('indian');
  });
  
  it('matches language prefix for en-NZ', () => {
    const config = detectLocaleFromBrowser('en-NZ');
    expect(config.locale).toMatch(/^en-/);
  });
  
  it('defaults to en-IN for unsupported locale', () => {
    const config = detectLocaleFromBrowser('es-ES');
    expect(config.locale).toBe('en-IN');
  });
});
```

### Test Component Integration

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import { NetWorthCard } from './NetWorthCard';

// Mock the hooks
jest.mock('@/hooks/usePreferences', () => ({
  usePreferences: () => ({
    preferences: {
      locale: 'en-US',
      currency: 'USD',
    },
    loading: false,
    error: null,
  }),
}));

it('formats currency using user locale', async () => {
  render(<NetWorthCard />);
  await waitFor(() => {
    // Should use en-US formatting
    expect(screen.getByText(/\$1,000,000/)).toBeInTheDocument();
  });
});
```

## Migration Notes

### For Existing Users

Existing users who already have preferences will NOT be affected:
- Their preferences remain unchanged
- Browser locale is only used for NEW users
- Existing locale settings are preserved

### For New Features

When adding new locale-dependent features:
1. Always use `preferences.locale` from the hook
2. Never hardcode locale values
3. Test with multiple locales
4. Provide locale in all formatting utilities

## Future Enhancements

1. **RTL Language Support**: Add support for Arabic, Hebrew
2. **More Currencies**: Expand to 50+ currencies
3. **Custom Locale Profiles**: Let users create custom combinations
4. **Locale Suggestions**: Suggest locale based on IP geolocation
5. **Timezone Auto-Detection**: Automatically set timezone from browser
6. **Regional Holidays**: Support locale-specific holidays in calendar

## Troubleshooting

### Locale Not Detected

**Problem:** User's browser locale not properly detected

**Solution:**
```typescript
// Check what browser is sending
console.log('Browser locale:', navigator.language);
console.log('Browser languages:', navigator.languages);

// Verify in Cloud Function logs
// Should see: "Creating preferences for user ${userId} with browser locale: ${browserLocale}"
```

### Wrong Locale Configuration

**Problem:** User gets wrong currency/date format for their locale

**Solution:**
1. Check if locale is in `LOCALE_CONFIGURATIONS`
2. Add missing locale configuration
3. Update `LOCALE_CONFIGURATIONS` in `UserPreferences.ts`
4. Deploy updated shared-types package

### Preferences Not Updating

**Problem:** Changes in PreferencesSettings not reflected immediately

**Solution:**
```typescript
// Use reload function from hook
const { preferences, reload } = usePreferences();

const handleSave = async () => {
  await preferencesApi.update(updates);
  await reload(); // Force reload
};
```

## References

- User Preferences Schema: `packages/shared-types/src/UserPreferences.ts`
- Cloud Function: `packages/functions/src/preferences.ts`
- Webapp API: `packages/webapp/src/core/api/preferencesApi.ts`
- Formatting Utilities: `packages/webapp/src/utils/formatCurrency.ts`, `formatDate.ts`
- Settings Component: `packages/webapp/src/components/settings/PreferencesSettings.tsx`
