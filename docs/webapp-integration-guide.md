# Webapp Integration Guide - User Preferences

## Overview
This guide explains how to use the user preferences system in the webapp, including formatting utilities and the PreferencesSettings component.

## Quick Start

### 1. Format Currency in Your Components

```typescript
import { formatCurrency, formatCurrencyCompact } from '@/utils';

// Basic usage with explicit values
const formatted = formatCurrency(1000000, 'INR', 'en-IN');
// Output: "₹10,00,000.00" (Indian numbering)

// Compact notation for large numbers
const compact = formatCurrencyCompact(1000000, 'INR', 'en-IN');
// Output: "₹10L" (10 Lakh)

// Western format
const western = formatCurrency(1000000, 'USD', 'en-US');
// Output: "$1,000,000.00"
```

### 2. Format Dates

```typescript
import { formatDate, formatDateTime, formatRelativeDate } from '@/utils';

// Format with user's preferred date format
const date = formatDate(new Date(), 'DD/MM/YYYY', 'en-IN');
// Output: "15/11/2025"

// Format with time
const dateTime = formatDateTime(new Date(), 'DD/MM/YYYY', '12h', 'en-IN');
// Output: "15/11/2025, 2:30 PM"

// Relative dates
const relative = formatRelativeDate(new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), 'en-IN');
// Output: "2 days ago"
```

### 3. Using Cloud Function Responses

All updated Cloud Functions now return `currency` (and some include `dateFormat` and `locale`) in their responses. Use these values directly with the formatting utilities:

```typescript
import { analyticsApi } from '@/core/api';
import { formatCurrency } from '@/utils';

const response = await analyticsApi.calculateNetWorth();

// Response includes: { totalNetWorth: 1000000, currency: 'INR', ... }
// Format using the user's currency preference
const formatted = formatCurrency(
  response.totalNetWorth, 
  response.currency,  // User's preferred currency from their preferences
  'en-IN'  // Locale (will be added to responses in future)
);
```

## Architecture

### Formatting Utilities

#### Currency Formatting (`formatCurrency.ts`)

**Main Functions:**
- `formatCurrency(amount, currency, locale)` - Standard currency formatting
- `formatCurrencyCompact(amount, currency, locale)` - Compact notation (K, M, B, L, Cr)
- `formatCurrencyForTable(amount, currency, locale)` - Smart formatting for tables
- `formatCurrencyWhole(amount, currency, locale)` - No decimal places
- `formatNumber(value, locale, decimals)` - Number formatting without currency
- `formatPercentage(value, locale, decimals)` - Percentage formatting
- `getCurrencySymbol(currency, locale)` - Extract currency symbol
- `parseCurrency(currencyString)` - Parse formatted string back to number

**Features:**
- **Indian Numbering System**: Automatically uses lakh/crore for `en-IN` locale
  - 1,00,000 (1 Lakh) instead of 100,000
  - 1,00,00,000 (1 Crore) instead of 10,000,000
- **Western Numbering**: Standard thousand/million/billion for other locales
- **Compact Notation**: Intelligent abbreviations based on locale
  - Indian: 10L, 1Cr, 100Cr
  - Western: 10K, 1M, 100M, 1B
- **18 Currencies Supported**: INR, USD, EUR, GBP, JPY, AUD, CAD, CHF, CNY, SEK, NZD, ZAR, BRL, MXN, RUB, KRW, TRY, SGD
- **Fallback Handling**: Graceful degradation for invalid locales/currencies

**Implementation:**
```typescript
// Indian formatting example
formatCurrency(1000000, 'INR', 'en-IN')
// "₹10,00,000.00"

formatCurrencyCompact(1000000, 'INR', 'en-IN')
// "₹10L"

formatCurrencyCompact(10000000, 'INR', 'en-IN')
// "₹1Cr"

// Western formatting example
formatCurrency(1000000, 'USD', 'en-US')
// "$1,000,000.00"

formatCurrencyCompact(1000000, 'USD', 'en-US')
// "$1M"

// Table formatting (smart switching)
formatCurrencyForTable(1234567, 'INR', 'en-IN')
// "₹12L" (compact for large numbers)

formatCurrencyForTable(1234, 'INR', 'en-IN')
// "₹1,234" (full format for small numbers)
```

#### Date Formatting (`formatDate.ts`)

**Main Functions:**
- `formatDate(date, dateFormat, locale)` - Main date formatter
- `formatDateTime(date, dateFormat, timeFormat, locale)` - Date with time
- `formatTime(date, timeFormat, locale)` - Time only
- `formatRelativeDate(date, locale)` - Relative format ("2 days ago")
- `formatDateRange(start, end, dateFormat, locale)` - Date range formatting
- `formatMonthYear(date, locale)` - Month and year display
- `formatMonthShort(date)` - Short month names
- `parseDate(dateString, dateFormat)` - Parse date strings
- `getDateFormatPlaceholder(dateFormat)` - Placeholder for inputs

**Features:**
- **5 Date Formats Supported**: DD/MM/YYYY, MM/DD/YYYY, YYYY-MM-DD, DD.MM.YYYY, YYYY/MM/DD
- **Time Format Options**: 12h (AM/PM) or 24h
- **Relative Time**: "2 days ago", "in 3 hours", etc.
- **Date Ranges**: Intelligent formatting for date ranges
- **Parsing**: Convert user input back to Date objects
- **Input Helpers**: Placeholder text for date input fields

**Implementation:**
```typescript
const date = new Date('2025-11-15T14:30:00');

// Different date formats
formatDate(date, 'DD/MM/YYYY', 'en-IN')  // "15/11/2025"
formatDate(date, 'MM/DD/YYYY', 'en-US')  // "11/15/2025"
formatDate(date, 'YYYY-MM-DD', 'en-US')  // "2025-11-15"
formatDate(date, 'DD.MM.YYYY', 'de-DE')  // "15.11.2025"

// Time formatting
formatTime(date, '12h', 'en-IN')  // "2:30 PM"
formatTime(date, '24h', 'en-IN')  // "14:30"

// Date and time combined
formatDateTime(date, 'DD/MM/YYYY', '12h', 'en-IN')
// "15/11/2025, 2:30 PM"

// Relative dates
const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
formatRelativeDate(twoDaysAgo, 'en-IN')  // "2 days ago"

// Date ranges
const start = new Date('2025-01-01');
const end = new Date('2025-12-31');
formatDateRange(start, end, 'DD/MM/YYYY', 'en-IN')
// "01/01/2025 - 31/12/2025"

// Parsing user input
const parsed = parseDate('15/11/2025', 'DD/MM/YYYY');
// Date object: 2025-11-15T00:00:00

// Input placeholder
getDateFormatPlaceholder('DD/MM/YYYY')  // "dd/mm/yyyy"
```

### Preferences Settings Component

Location: `packages/webapp/src/components/settings/PreferencesSettings.tsx`

**Features:**
- Load current user preferences on mount
- Real-time preview of formatting changes
- Auto-save on change (with success/error feedback)
- Reset to defaults with confirmation
- Organized sections:
  - **Localization**: Currency, Locale, Language, Timezone
  - **Regional Formats**: Date format, Time format, Number format, Week start
  - **Financial Settings**: Financial year, Hide sensitive data

**Usage:**
```typescript
import { PreferencesSettings } from '@/components/settings/PreferencesSettings';

function SettingsPage() {
  return (
    <PreferencesSettings
      onSave={(prefs) => console.log('Saved:', prefs)}
      onError={(err) => console.error('Error:', err)}
    />
  );
}
```

**Props:**
- `onSave?: (preferences: UserPreferences) => void` - Callback when preferences are saved
- `onError?: (error: Error) => void` - Callback when an error occurs

### Example Components

#### NetWorthCard Component

Location: `packages/webapp/src/components/dashboard/NetWorthCard.tsx`

Demonstrates best practices for using Cloud Function responses with formatting utilities:

```typescript
import { NetWorthCard } from '@/components/dashboard/NetWorthCard';

// Basic usage
<NetWorthCard />

// Compact display
<NetWorthCard showCompact={true} />

// Hide currency info
<NetWorthCard showCurrency={false} />
```

**Key Implementation Points:**
1. Fetches data from `analyticsApi.calculateNetWorth()`
2. Response includes `currency` from user preferences
3. Uses `formatCurrency()` and `formatCurrencyCompact()` for display
4. Handles loading and error states
5. Shows detailed breakdown (assets/liabilities)

## Cloud Functions Integration

### Functions with Currency Support (37 total)

All these functions return `currency` in their responses:

**Analytics (5)**
- `calculateNetWorth` - Returns `currency`
- `getPortfolioSummary` - Returns `currency`
- `getTransactionAnalytics` - Returns `currency`
- `getCashFlow` - Returns `currency`
- `getSpendingTrends` - Returns `currency`

**Budgets (4)**
- `createBudget` - Returns `currency`
- `updateBudget` - Returns `currency`
- `getBudgetStatus` - Returns `currency`
- `getBudgetSummary` - Returns `currency`

**Goals (5)**
- `createGoal` - Returns `currency`
- `updateGoal` - Returns `currency`
- `getGoalProgress` - Returns `currency`
- `predictGoalCompletion` - Returns `currency`
- `getGoalSummary` - Returns `currency`

**Deposits (5)**
- `calculateFDReturns` - Returns `currency`
- `calculateRDReturns` - Returns `currency`
- `compareFDPlans` - Returns `currency`
- `compareRDPlans` - Returns `currency`
- `getDepositSummary` - Returns `currency`

**Investments (6)**
- `fetchStockData` - Returns `currency`
- `fetchMutualFundData` - Returns `currency`
- `fetchETFData` - Returns `currency`
- `fetchStockHistory` - Returns `currency`
- `getInvestmentsSummary` - Returns `currency`
- `clearInvestmentCache` - No response data

**Dashboard (3)**
- `computeAndCacheDashboard` - Returns `currency`, `dateFormat`
- `getAccountSummary` - Returns `currency`, `dateFormat`
- `getTransactionSummary` - Returns `currency`, `dateFormat`

**Reports (2)**
- `generateReport` - Returns `currency`, `dateFormat`, `locale`
- `getDashboardAnalytics` - Returns `currency`

**Preferences (3)**
- `getUserPreferences` - Returns full preferences object
- `updateUserPreferences` - Returns updated preferences
- `resetUserPreferences` - Returns reset preferences

### Usage Pattern

```typescript
// Standard pattern for using Cloud Functions with formatting
const fetchAndDisplay = async () => {
  // 1. Call Cloud Function
  const response = await analyticsApi.calculateNetWorth();
  
  // 2. Response includes currency from user preferences
  const { totalNetWorth, currency, totalAssets, totalLiabilities } = response;
  
  // 3. Format using the user's currency
  const locale = currency === 'INR' ? 'en-IN' : 'en-US';
  const formattedNetWorth = formatCurrency(totalNetWorth, currency, locale);
  const formattedAssets = formatCurrency(totalAssets, currency, locale);
  const formattedLiabilities = formatCurrency(totalLiabilities, currency, locale);
  
  // 4. Display formatted values
  return {
    netWorth: formattedNetWorth,
    assets: formattedAssets,
    liabilities: formattedLiabilities
  };
};
```

## Best Practices

### 1. Always Use Formatting Utilities

❌ **Don't format manually:**
```typescript
const formatted = `₹${amount.toFixed(2)}`;  // Hardcoded currency, no locale support
```

✅ **Use formatting utilities:**
```typescript
const formatted = formatCurrency(amount, currency, locale);
```

### 2. Use Currency from Cloud Function Responses

❌ **Don't hardcode currency:**
```typescript
const formatted = formatCurrency(amount, 'INR', 'en-IN');  // Hardcoded
```

✅ **Use response currency:**
```typescript
const response = await analyticsApi.calculateNetWorth();
const formatted = formatCurrency(response.totalNetWorth, response.currency, locale);
```

### 3. Handle Loading and Error States

```typescript
function MyComponent() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        const response = await analyticsApi.calculateNetWorth();
        setData(response);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);
  
  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  if (!data) return <EmptyState />;
  
  return <DisplayData data={data} />;
}
```

### 4. Choose the Right Formatting Function

```typescript
// Large numbers in cards/summaries
<h2>{formatCurrencyCompact(netWorth, currency, locale)}</h2>
// Output: "₹12L" or "$1.2M"

// Detailed tables
<td>{formatCurrency(amount, currency, locale)}</td>
// Output: "₹12,34,567.00" or "$1,234,567.00"

// Smart table formatting (auto-switches)
<td>{formatCurrencyForTable(amount, currency, locale)}</td>
// Compact for large, full for small

// Integer values (no decimals)
<span>{formatCurrencyWhole(roundedAmount, currency, locale)}</span>
// Output: "₹1,00,000" or "$100,000"
```

### 5. Provide Locale Fallbacks

Until all Cloud Functions include `locale` in responses, use sensible defaults:

```typescript
const locale = response.locale || (response.currency === 'INR' ? 'en-IN' : 'en-US');
const formatted = formatCurrency(amount, response.currency, locale);
```

### 6. Use Compact Notation Wisely

```typescript
// Dashboard cards (overview)
<NetWorthCard showCompact={true} />  // "₹12L", "$1.2M"

// Detailed views (precision matters)
<NetWorthCard showCompact={false} />  // "₹12,00,000.00", "$1,200,000.00"
```

## Testing

### Unit Tests for Formatting Utilities

```typescript
import { formatCurrency, formatCurrencyCompact } from '@/utils';

describe('formatCurrency', () => {
  it('formats INR with Indian numbering', () => {
    expect(formatCurrency(1000000, 'INR', 'en-IN')).toBe('₹10,00,000.00');
  });
  
  it('formats USD with Western numbering', () => {
    expect(formatCurrency(1000000, 'USD', 'en-US')).toBe('$1,000,000.00');
  });
});

describe('formatCurrencyCompact', () => {
  it('formats lakhs for Indian locale', () => {
    expect(formatCurrencyCompact(1000000, 'INR', 'en-IN')).toBe('₹10L');
  });
  
  it('formats millions for US locale', () => {
    expect(formatCurrencyCompact(1000000, 'USD', 'en-US')).toBe('$1M');
  });
});
```

### Component Testing

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import { NetWorthCard } from './NetWorthCard';

jest.mock('@/core/api', () => ({
  analyticsApi: {
    calculateNetWorth: jest.fn(() => Promise.resolve({
      totalNetWorth: 1000000,
      currency: 'INR',
      totalAssets: 1200000,
      totalLiabilities: 200000,
      accountCount: 5,
      asOfDate: '2025-11-15',
      lastUpdated: '2025-11-15T12:00:00Z'
    }))
  }
}));

it('displays formatted net worth', async () => {
  render(<NetWorthCard />);
  await waitFor(() => {
    expect(screen.getByText(/₹10,00,000/)).toBeInTheDocument();
  });
});
```

## Migration Guide

### Updating Existing Components

1. **Import formatting utilities:**
```typescript
import { formatCurrency, formatDate } from '@/utils';
```

2. **Replace manual formatting:**
```typescript
// Before
const formatted = `₹${amount.toFixed(2)}`;

// After
const formatted = formatCurrency(amount, currency, locale);
```

3. **Use Cloud Function currency:**
```typescript
// Before
const data = await api.getData();
const formatted = formatCurrency(data.amount, 'INR', 'en-IN');

// After
const data = await api.getData();
const formatted = formatCurrency(data.amount, data.currency, locale);
```

4. **Add loading/error states if missing:**
```typescript
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);
```

## Next Steps

1. **Add PreferencesSettings to App Navigation**
   - Add link to settings page in main navigation
   - Create route for `/settings/preferences`

2. **Update More Components**
   - Dashboard components
   - Analytics charts (axis labels, tooltips)
   - Transaction lists
   - Account cards
   - Budget displays
   - Goal progress indicators

3. **Add Locale to More Cloud Functions**
   - Currently: Reports functions return `locale`
   - TODO: Add locale to Analytics, Dashboard, and other functions

4. **Create Context Provider (Optional)**
   - Avoid prop drilling for preferences
   - `usePreferences()` hook for easy access
   - Automatic refetch on preference changes

5. **Implement Caching**
   - Cache user preferences in localStorage
   - Reduce API calls for frequently accessed preferences

6. **Add Visual Regression Tests**
   - Test formatted displays across different currencies/locales
   - Verify Indian vs Western numbering systems
   - Check RTL language support (future)

## Support

For issues or questions:
1. Check Cloud Function response types in `packages/shared-types/src/CloudFunctionTypes.ts`
2. Review formatting utility implementations in `packages/webapp/src/utils/`
3. See example component: `packages/webapp/src/components/dashboard/NetWorthCard.tsx`
4. Refer to main documentation: `docs/user-preferences-final-summary.md`
