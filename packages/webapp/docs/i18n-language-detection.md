# i18n Language Detection System

## Overview

WealthWise now supports automatic language detection from multiple sources with a priority-based fallback system. This ensures the best user experience by automatically selecting the most appropriate language.

## Supported Languages

- **English (India)** - `en-IN` (Default)
- **Hindi** - `hi`
- **Telugu (India)** - `te-IN`

## Language Detection Priority

The system checks for language preference in the following order:

1. **localStorage** (`app-language` key)
   - User's previously saved preference
   - Persists across sessions
   - Highest priority

2. **sessionStorage** (`app-language` key)
   - Temporary session preference
   - Cleared when browser closes

3. **Cookie** (`i18next` cookie)
   - Server-side language preference
   - Expires after 7 days
   - Useful for SSR scenarios

4. **Query String** (`?lng=en-IN`)
   - URL parameter for forcing language
   - Example: `https://app.com?lng=hi`
   - Useful for sharing links

5. **Custom Browser Language Mapping**
   - Intelligent mapping of browser languages to supported languages
   - Maps `hi-*` → `hi` (Hindi)
   - Maps `te-*` → `te-IN` (Telugu)
   - Maps `en-IN` → `en-IN` (English India)
   - Falls back to `en-IN` for other languages

6. **Browser Navigator** (`navigator.language`)
   - System language preference
   - Automatic detection from OS settings

7. **HTML Tag** (`<html lang="...">`)
   - Document language attribute
   - Lowest priority fallback

## Usage Examples

### Set Language via URL

```
https://wealthwise.app?lng=hi           # Switch to Hindi
https://wealthwise.app?lng=te-IN        # Switch to Telugu
https://wealthwise.app?lng=en-IN        # Switch to English
```

### Set Language Programmatically

```typescript
import { useTranslation } from 'react-i18next';

function LanguageSwitcher() {
  const { i18n } = useTranslation();
  
  const changeLanguage = (lng: string) => {
    i18n.changeLanguage(lng); // Automatically saves to localStorage
  };
  
  return (
    <div>
      <button onClick={() => changeLanguage('en-IN')}>English</button>
      <button onClick={() => changeLanguage('hi')}>हिंदी</button>
      <button onClick={() => changeLanguage('te-IN')}>తెలుగు</button>
    </div>
  );
}
```

### Get Current Language

```typescript
import { useTranslation } from 'react-i18next';

function CurrentLanguage() {
  const { i18n } = useTranslation();
  
  console.log('Current language:', i18n.language); // 'en-IN', 'hi', or 'te-IN'
  console.log('Resolved language:', i18n.resolvedLanguage);
  
  return <p>Current: {i18n.language}</p>;
}
```

## Lazy Loading

Translations are loaded on-demand using HTTP requests:

- **Only the detected language is loaded** initially
- **Fallback language (en-IN) is preloaded** for instant display
- **Additional languages load when switched** to
- **Translations are cached** in browser for performance

### Benefits

1. **Faster Initial Load**
   - Don't download unused translations
   - Smaller bundle size
   - Better performance

2. **Reduced Memory Usage**
   - Only active language in memory
   - Previous languages can be garbage collected

3. **Easy Updates**
   - Translation files in `/public/locales/`
   - Can be updated without rebuilding app
   - CDN-friendly

## RTL Support

The system automatically sets the HTML direction attribute:

```typescript
// Automatically sets dir="rtl" for right-to-left languages
const isRTL = ['ar', 'he', 'fa', 'ur'].some(rtlLang => lng.startsWith(rtlLang));
document.documentElement.dir = isRTL ? 'rtl' : 'ltr';
```

Currently supported LTR languages only, but ready for RTL expansion.

## Storage and Caching

### localStorage
- **Key**: `app-language`
- **Value**: Language code (e.g., `'en-IN'`, `'hi'`, `'te-IN'`)
- **Persistence**: Permanent until cleared
- **Usage**: User preference

### HTTP Caching
- **Strategy**: `force-cache`
- **Location**: Browser HTTP cache
- **Files**: `/public/locales/{lng}.json`
- **Benefits**: Instant loading on return visits

## Configuration

The language detector can be configured in `/src/core/i18n/config.ts`:

```typescript
const languageDetectorOptions = {
  order: ['localStorage', 'sessionStorage', 'cookie', 'querystring', 'customDetector', 'navigator', 'htmlTag'],
  lookupQuerystring: 'lng',
  lookupCookie: 'i18next',
  lookupLocalStorage: 'app-language',
  lookupSessionStorage: 'app-language',
  caches: ['localStorage'],
  cookieMinutes: 10080, // 7 days
};
```

## Performance Optimizations

1. **Preload Only Fallback**
   ```typescript
   preload: ['en-IN'] // Only preload English for instant display
   ```

2. **Load Current Language Only**
   ```typescript
   load: 'currentOnly' // Don't load language variants
   ```

3. **HTTP Caching**
   ```typescript
   requestOptions: {
     cache: 'force-cache' // Use browser cache aggressively
   }
   ```

4. **React Suspense**
   ```typescript
   react: {
     useSuspense: true // Show loading state while fetching
   }
   ```

## Browser Language Mapping

The custom detector intelligently maps browser languages:

| Browser Language | Detected Language | Note |
|-----------------|-------------------|------|
| `hi` | `hi` | Hindi |
| `hi-IN` | `hi` | Hindi (India) |
| `te` | `te-IN` | Telugu |
| `te-IN` | `te-IN` | Telugu (India) |
| `en-IN` | `en-IN` | English (India) |
| `en-US` | `en-IN` | Fallback to English (India) |
| Any other | `en-IN` | Default fallback |

## Testing

### Test Language Detection

1. **Via URL**: Add `?lng=hi` to URL
2. **Via Console**: 
   ```javascript
   localStorage.setItem('app-language', 'te-IN');
   location.reload();
   ```
3. **Via Browser**: Change browser language in settings

### Test Lazy Loading

1. Open DevTools → Network tab
2. Filter by `/locales/`
3. Change language
4. Observe only requested language loads

## Migration from Previous System

### Before (Manual Detection)
```typescript
const getBrowserLanguage = (): string => {
  const stored = localStorage.getItem('app-language');
  if (stored) return stored;
  
  const browserLang = navigator.language;
  if (browserLang.startsWith('hi')) return 'hi';
  if (browserLang.startsWith('te')) return 'te-IN';
  return 'en-IN';
};
```

### After (Automatic Detection)
```typescript
// i18next-browser-languagedetector handles all detection automatically
// Just configure the priority order
detection: {
  order: ['localStorage', 'querystring', 'navigator', ...],
  caches: ['localStorage']
}
```

## Troubleshooting

### Language not changing
1. Check browser console for errors
2. Verify translation file exists in `/public/locales/`
3. Clear localStorage and try again
4. Check network tab for failed requests

### Wrong language detected
1. Check localStorage: `localStorage.getItem('app-language')`
2. Check query string: Look for `?lng=` in URL
3. Check browser language: `navigator.language`
4. Clear all caches and reload

### Translations not loading
1. Verify files in `/public/locales/` directory
2. Check network tab for 404 errors
3. Ensure file names match language codes exactly
4. Check browser HTTP cache

## Future Enhancements

- [ ] Add more Indian languages (Tamil, Kannada, Malayalam, Bengali, etc.)
- [ ] Add RTL language support (Arabic, Urdu)
- [ ] Server-side language detection
- [ ] Automatic translation updates via API
- [ ] User language preference in settings UI
- [ ] Language selector in navigation
- [ ] Translation contribution system

## References

- [i18next Documentation](https://www.i18next.com/)
- [i18next-browser-languagedetector](https://github.com/i18next/i18next-browser-languageDetector)
- [react-i18next](https://react.i18next.com/)
- [i18next-http-backend](https://github.com/i18next/i18next-http-backend)
