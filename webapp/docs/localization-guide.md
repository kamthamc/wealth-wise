# Localization (i18n) Infrastructure

## Overview

WealthWise has **comprehensive internationalization support** using `i18next` and `react-i18next`. The system supports multiple languages, locales, currencies, and text directions (LTR/RTL).

## Features

### ✅ Implemented

- **Multi-language Support** - English (India), Hindi, easily extensible
- **RTL Language Support** - Automatic text direction detection and application
- **Localized Currency** - Respects locale-specific currency formatting
- **Localized Dates** - Uses `Intl.DateTimeFormat` for proper date formatting
- **Localized Numbers** - Proper number formatting per locale
- **Type-Safe Translations** - TypeScript-friendly translation keys
- **Store Integration** - Syncs with app store locale settings

### 🎯 Architecture

```
src/core/i18n/
├── config.ts           # i18next configuration
├── hooks.ts            # Custom translation hooks
├── index.ts            # Public API exports
└── locales/
    ├── en-IN.json      # English (India) translations
    └── hi.json         # Hindi translations
```

## Usage

### 1. Basic Translation Hook

```tsx
import { useTranslation } from '@/core/i18n';

function MyComponent() {
  const { t } = useTranslation();
  
  return (
    <div>
      <h1>{t('common.loading')}</h1>
      <p>{t('emptyState.accounts.title')}</p>
    </div>
  );
}
```

### 2. Localized Currency

```tsx
import { useLocalizedCurrency } from '@/core/i18n';

function PriceDisplay() {
  const formatCurrency = useLocalizedCurrency();
  
  return <span>{formatCurrency(1000, 'INR')}</span>;
  // en-IN: ₹1,000.00
  // hi: ₹1,000.00
}
```

### 3. Localized Dates

```tsx
import { useLocalizedDate } from '@/core/i18n';

function DateDisplay() {
  const formatDate = useLocalizedDate();
  
  return <span>{formatDate(new Date(), { dateStyle: 'long' })}</span>;
  // en-IN: 19 October 2025
  // hi: 19 अक्तूबर 2025
}
```

### 4. Localized Numbers

```tsx
import { useLocalizedNumber } from '@/core/i18n';

function NumberDisplay() {
  const formatNumber = useLocalizedNumber();
  
  return <span>{formatNumber(1234567)}</span>;
  // en-IN: 12,34,567 (Indian numbering)
  // en-US: 1,234,567 (Western numbering)
}
```

### 5. RTL Support

```tsx
import { useTextDirection } from '@/core/i18n';

function DirectionalComponent() {
  const direction = useTextDirection();
  
  return (
    <div style={{ textAlign: direction === 'rtl' ? 'right' : 'left' }}>
      Content automatically aligns based on locale
    </div>
  );
}
```

## Translation Keys Structure

### Common Keys
- `common.*` - Shared UI text (buttons, actions, states)
- `validation.*` - Form validation messages
- `toast.success.*` - Success notifications
- `toast.error.*` - Error notifications

### Feature-Specific Keys
- `accounts.*` - Account management
- `transactions.*` - Transaction management
- `budgets.*` - Budget management
- `goals.*` - Goal management
- `dashboard.*` - Dashboard components

### Component Keys
- `emptyState.*` - Empty state messages
- `skeleton.*` - Loading state messages
- `accountSelect.*` - Account selector component
- `datePicker.*` - Date picker component

## Adding a New Language

### Step 1: Create Locale File

Create `/src/core/i18n/locales/{locale-code}.json`:

```json
{
  "common": {
    "loading": "Loading...",
    "save": "Save"
  },
  "accounts": {
    "title": "Accounts"
  }
}
```

### Step 2: Register in Config

Update `/src/core/i18n/config.ts`:

```ts
import newLocale from './locales/new-locale.json';

i18n.init({
  resources: {
    'en-IN': { translation: enIN },
    'hi': { translation: hi },
    'new-locale': { translation: newLocale }, // Add new locale
  },
  // ...
});
```

### Step 3: Update Locale Selector

Add the new locale to your locale selector component/settings.

## Supported Locales

| Locale | Language | Status | Currency | Date Format |
|--------|----------|--------|----------|-------------|
| `en-IN` | English (India) | ✅ Complete | INR | DD/MM/YYYY |
| `hi` | Hindi | ✅ Complete | INR | DD/MM/YYYY |
| `en-US` | English (US) | ⏳ Planned | USD | MM/DD/YYYY |
| `ar` | Arabic | ⏳ Planned | Various | RTL |

## RTL Language Support

The system automatically detects RTL languages and applies:

1. **Document Direction**: `<html dir="rtl">`
2. **Text Alignment**: CSS `text-align` adjustments
3. **Icon Positioning**: Automatic flipping of directional icons
4. **Layout Mirroring**: Flexbox/Grid direction changes

### RTL Languages Supported
- Arabic (`ar`)
- Hebrew (`he`)
- Persian/Farsi (`fa`)
- Urdu (`ur`)

## Best Practices

### ✅ Do's

1. **Always use translation keys** - Never hardcode user-facing strings
2. **Use semantic keys** - `emptyState.accounts.title` not `text1`
3. **Keep translations consistent** - Use same terms across the app
4. **Provide context** - Add comments for translators
5. **Test with RTL** - Verify layout works in both directions
6. **Use plural forms** - `{{count}} item` vs `{{count}} items`
7. **Interpolation** - Use `{{variable}}` for dynamic content

### ❌ Don'ts

1. **Don't hardcode text** - Bad: `<button>Save</button>`
2. **Don't concatenate strings** - Bad: `t('hello') + ' ' + name`
3. **Don't assume LTR** - Test with RTL languages
4. **Don't forget plurals** - Handle singular/plural forms
5. **Don't skip validation messages** - Localize all error text
6. **Don't use generic keys** - Bad: `text1`, `label2`

## Examples

### Before (Hardcoded)

```tsx
<EmptyState
  title="No accounts yet"
  description="Get started by adding your first account"
  action={<Button>Add Account</Button>}
/>
```

### After (Localized)

```tsx
import { useTranslation } from '@/core/i18n';

function AccountsEmpty() {
  const { t } = useTranslation();
  
  return (
    <EmptyState
      title={t('emptyState.accounts.title')}
      description={t('emptyState.accounts.description')}
      action={<Button>{t('common.add')}</Button>}
    />
  );
}
```

### With Interpolation

```tsx
// Translation: "Amount must be at least {{min}}"
const { t } = useTranslation();
const errorMessage = t('validation.minAmount', { min: '₹100' });
```

### With Plurals

```json
{
  "transactions": {
    "count": "{{count}} transaction",
    "count_plural": "{{count}} transactions"
  }
}
```

```tsx
const { t } = useTranslation();
<span>{t('transactions.count', { count: 5 })}</span>
// Output: "5 transactions"
```

## Integration with Existing Code

### Formatting Utils Already Support Locales

```ts
// formatCurrency() already accepts locale parameter
formatCurrency(1000, 'en-IN', 'INR')

// formatDate() already accepts locale parameter
formatDate(new Date(), 'en-IN', { dateStyle: 'long' })
```

### App Store Has Locale State

```ts
const { locale, setLocale } = useAppStore();
setLocale('hi'); // Switch to Hindi
```

## Testing Localization

### 1. Visual Testing
- Switch between locales in settings
- Verify all text is translated
- Check layout doesn't break with longer text

### 2. RTL Testing
- Add `dir="rtl"` to `<html>` element
- Verify mirroring works correctly
- Check icons and layouts flip properly

### 3. Pluralization Testing
- Test with count = 0, 1, 2, many
- Verify correct plural forms appear

## Migration Strategy

### Phase 1: Core Components ✅ (Complete)
- Empty states
- Toast notifications
- Validation messages
- Loading states

### Phase 2: Feature Components (In Progress)
- Account forms and lists
- Transaction forms and lists
- Budget management
- Goal tracking

### Phase 3: Settings & Preferences
- Locale selector
- Currency preferences
- Date format preferences

### Phase 4: Documentation & Help
- User guides
- Tooltips
- Error messages

## Performance Considerations

- **Lazy Loading**: Translations loaded on-demand
- **Code Splitting**: Per-locale bundles
- **Caching**: Translations cached in memory
- **Bundle Size**: ~2KB per locale file (gzipped)

## Future Enhancements

- 🔄 Dynamic locale switching without page reload
- 🌍 Auto-detect user locale from browser
- 📱 Mobile-optimized translations (shorter text)
- 🎙️ Screen reader optimized text
- 📊 Translation completion tracking
- 🔧 Translation management UI
- 🌐 Crowdsourced translations

## Resources

- [i18next Documentation](https://www.i18next.com/)
- [react-i18next Guide](https://react.i18next.com/)
- [Intl.NumberFormat MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat)
- [Intl.DateTimeFormat MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat)
