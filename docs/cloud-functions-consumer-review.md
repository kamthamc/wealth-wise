# Cloud Functions Consumer Review & User Preferences Integration

## Overview
Comprehensive review of all 53+ Cloud Functions from a consumer perspective, with focus on user preferences integration instead of hardcoded values.

**Created**: January 2025  
**Status**: User preferences system implemented, analytics functions updated  
**Priority**: HIGH - Foundational for consistent user experience

---

## User Preferences System

### Architecture

#### Firestore Collection: `user_preferences`
```typescript
{
  userId: string;                    // Document ID = Firebase Auth UID
  
  // Localization
  currency: string;                  // e.g., 'INR', 'USD', 'EUR'
  locale: string;                    // e.g., 'en-IN', 'en-US'
  language: string;                  // e.g., 'en', 'hi', 'te'
  timezone: string;                  // e.g., 'Asia/Kolkata'
  
  // Regional Settings
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD' | 'system';
  timeFormat: '12h' | '24h' | 'system';
  numberFormat: 'indian' | 'western' | 'system';
  weekStartDay: 0 | 1 | 6;          // Sunday, Monday, Saturday
  
  // Financial Settings
  useFinancialYear: boolean;         // April-March vs Jan-Dec
  financialYearStartMonth: number;   // 1-12 (4 for India, 1 for US)
  defaultAccountId?: string;
  hideSensitiveData: boolean;
  
  // Display Settings
  theme: 'light' | 'dark' | 'system';
  dashboardLayout: 'compact' | 'standard' | 'detailed';
  chartType: 'bar' | 'line' | 'pie' | 'mixed';
  
  // Notification Preferences
  budgetAlerts: boolean;
  goalMilestones: boolean;
  unusualSpending: boolean;
  recurringTransactions: boolean;
  emailNotifications: boolean;
  pushNotifications: boolean;
  
  // Privacy & Security
  biometricEnabled: boolean;
  autoLockTimeout: number;           // seconds
  requireAuthForExport: boolean;
  
  // App Behavior
  autoCategorizze: boolean;
  duplicateDetection: boolean;
  smartSuggestions: boolean;
  
  // Metadata
  createdAt: string;
  updatedAt: string;
  version: number;
}
```

### Cloud Functions

#### 1. `getUserPreferences`
- **Purpose**: Fetch user preferences or create defaults
- **Auth**: Required
- **Request**: `{}` (uses authenticated user)
- **Response**: `{ preferences: UserPreferences }`
- **Behavior**: 
  - Returns existing preferences if found
  - Creates and returns default preferences for new users
  - Defaults to Indian locale (currency='INR', locale='en-IN')

#### 2. `updateUserPreferences`
- **Purpose**: Update user preferences (partial updates supported)
- **Auth**: Required
- **Request**: `{ preferences: Partial<UserPreferences> }`
- **Response**: `{ success: boolean, preferences: UserPreferences }`
- **Validation**: Cannot update `userId`, `createdAt`, `version`

#### 3. `resetUserPreferences`
- **Purpose**: Reset all preferences to defaults
- **Auth**: Required
- **Request**: `{ confirmReset: boolean }`
- **Response**: `{ success: boolean, preferences: UserPreferences }`
- **Safety**: Requires explicit confirmation flag

### Helper Functions (Internal Use)

```typescript
// For use within Cloud Functions
fetchUserPreferences(userId: string): Promise<UserPreferences>
getUserCurrency(userId: string): Promise<string>
getUserLocale(userId: string): Promise<string>
getUserTimezone(userId: string): Promise<string>
```

### Default Preferences (Indian Market)

```typescript
{
  currency: 'INR',
  locale: 'en-IN',
  language: 'en',
  timezone: 'Asia/Kolkata',
  dateFormat: 'DD/MM/YYYY',
  timeFormat: '12h',
  numberFormat: 'indian',           // Lakh/Crore notation
  weekStartDay: 1,                  // Monday
  useFinancialYear: true,           // April-March
  financialYearStartMonth: 4,       // April
  // ... other defaults
}
```

### Locale Configurations

Predefined configurations for 10 major locales:
- **en-IN** (India): INR, Indian number format, Financial year April-March
- **en-US** (USA): USD, Western format, Calendar year
- **en-GB** (UK): GBP, 24h time, Monday start
- **en-CA** (Canada): CAD, DD/MM/YYYY
- **en-AU** (Australia): AUD, Monday start
- **en-SG** (Singapore): SGD, 24h time
- **de-DE** (Germany): EUR, DD.MM.YYYY
- **fr-FR** (France): EUR, 24h time
- **ja-JP** (Japan): JPY, YYYY/MM/DD
- **zh-CN** (China): CNY, YYYY-MM-DD

---

## Cloud Functions Review by Category

### 1. Analytics Functions (5 functions) ✅ UPDATED

#### `calculateNetWorth` ✅
- **User Preferences**: 
  - ✅ Uses `userPreferences.currency` for response
  - ✅ Fetches preferences at start of function
- **Consumer Value**: Core financial metric
- **Improvements Made**:
  - Replaced hardcoded `'INR'` with `userPreferences.currency`
  - Returns currency in user's preferred format

#### `getPortfolioSummary`
- **User Preferences Needed**:
  - Currency for total value display
  - Locale for number formatting
  - Date format for performance periods
- **Consumer Value**: Investment tracking
- **TODO**: Update to use preferences

#### `getTransactionAnalytics`
- **User Preferences Needed**:
  - Currency for amounts
  - Date format for time series
  - Financial year settings for period grouping
  - Locale for category names (if localized)
- **Consumer Value**: Spending insights
- **TODO**: Update to use preferences

#### `getCashFlow`
- **User Preferences Needed**:
  - Currency for cash flow amounts
  - Date format for periods
  - Financial year for period calculation
- **Consumer Value**: Income/expense tracking
- **TODO**: Update to use preferences

#### `getDashboard`
- **User Preferences Needed**:
  - ALL preferences (comprehensive dashboard)
  - Currency, locale, date format, financial year
  - Dashboard layout preference
  - Chart type preference
- **Consumer Value**: Primary app interface
- **TODO**: Update to use preferences

---

### 2. Account Functions (9 functions) ⏳ REVIEW NEEDED

#### `createAccount`
- **User Preferences Needed**:
  - Default currency for new accounts
  - Timezone for created_at timestamps
- **Consumer Value**: Account management
- **Current State**: Likely hardcoded defaults
- **TODO**: Use `userPreferences.currency` as default

#### `updateAccount`
- **User Preferences**: Timezone for timestamps
- **Consumer Value**: Account updates
- **TODO**: Review and update

#### `calculateAccountBalance`
- **User Preferences Needed**:
  - Currency for balance display
  - Number format (indian/western)
- **Consumer Value**: Real-time balance
- **TODO**: Add currency parameter

#### `getAccountTypes`, `getBudgetPeriods`, `getGoalPriorities`, etc.
- **User Preferences**: 
  - Locale for localized type names
  - Language for translations
- **Consumer Value**: Dropdowns, selectors
- **TODO**: Add localization support

---

### 3. Transaction Functions (4 functions) ⏳ REVIEW NEEDED

#### `createTransaction`
- **User Preferences Needed**:
  - Default currency
  - Timezone for transaction timestamps
  - Auto-categorize setting
  - Duplicate detection setting
- **Consumer Value**: Core data entry
- **TODO**: Critical - update with preferences

#### `updateTransaction`
- **User Preferences**: Timezone for updated_at
- **Consumer Value**: Transaction corrections
- **TODO**: Update timestamps

#### `getTransactionStats`
- **User Preferences Needed**:
  - Currency for stats
  - Date format for grouping
  - Financial year settings
- **Consumer Value**: Quick insights
- **TODO**: Add preference support

#### `deleteTransaction`
- **User Preferences**: Minimal (audit logging timezone)
- **Consumer Value**: Data cleanup
- **TODO**: Low priority

---

### 4. Budget Functions (4 functions) ⏳ REVIEW NEEDED

#### `createBudget`
- **User Preferences Needed**:
  - Currency for budget amounts
  - Financial year for period calculation
  - Budget alerts preference
- **Consumer Value**: Budget management
- **TODO**: Use currency preference

#### `updateBudget`
- **User Preferences**: Same as createBudget
- **Consumer Value**: Budget adjustments
- **TODO**: Update with preferences

#### `calculateBudgetProgress`
- **User Preferences Needed**:
  - Currency for amounts
  - Date format for period display
  - Budget alerts for notifications
- **Consumer Value**: Spending tracking
- **TODO**: Add preference support

#### `deleteBudget`
- **User Preferences**: Minimal
- **Consumer Value**: Budget cleanup
- **TODO**: Low priority

---

### 5. Goal Functions (5 functions) ⏳ REVIEW NEEDED

#### `createGoal`
- **User Preferences Needed**:
  - Currency for target amount
  - Date format for target date
  - Goal milestones notification setting
- **Consumer Value**: Financial goals
- **TODO**: Use currency preference

#### `updateGoal`
- **User Preferences**: Same as createGoal
- **Consumer Value**: Goal adjustments
- **TODO**: Update with preferences

#### `calculateGoalProgress`
- **User Preferences Needed**:
  - Currency for amounts
  - Date format for target dates
  - Goal milestones for notifications
- **Consumer Value**: Progress tracking
- **TODO**: Add preference support

#### `addGoalContribution`
- **User Preferences**:
  - Currency for contribution amounts
  - Goal milestones for notifications
- **Consumer Value**: Goal funding
- **TODO**: Use preferences

#### `deleteGoal`
- **User Preferences**: Minimal
- **Consumer Value**: Goal cleanup
- **TODO**: Low priority

---

### 6. Deposit Functions (5 functions) ⏳ REVIEW NEEDED

#### `calculateFDMaturity`, `calculateRDMaturity`, `calculatePPFMaturity`, `calculateSavingsInterest`
- **User Preferences Needed**:
  - Currency for amounts
  - Date format for maturity dates
  - Number format for interest display
  - Locale for calculation rules (Indian vs others)
- **Consumer Value**: Deposit planning
- **TODO**: Critical - add preferences for accurate calculations

#### `getDepositAccountDetails`
- **User Preferences**:
  - Currency for amounts
  - Date format for dates
- **Consumer Value**: Deposit tracking
- **TODO**: Use preferences

---

### 7. Investment Functions (6 functions) ⏳ REVIEW NEEDED

#### `fetchStockData`, `fetchMutualFundData`, `fetchETFData`
- **User Preferences Needed**:
  - Currency for price conversion (if needed)
  - Locale for market data (NSE vs NYSE vs LSE)
- **Consumer Value**: Investment data
- **TODO**: Add market preference

#### `fetchStockHistory`
- **User Preferences**:
  - Date format for historical data
  - Currency for prices
- **Consumer Value**: Historical analysis
- **TODO**: Use preferences

#### `getInvestmentsSummary`
- **User Preferences Needed**:
  - Currency for total value
  - Date format for performance periods
  - Chart type for visualizations
- **Consumer Value**: Investment overview
- **TODO**: Comprehensive preference support

#### `clearInvestmentCache`
- **User Preferences**: None
- **Consumer Value**: Data refresh
- **TODO**: No changes needed

---

### 8. Dashboard Functions (3 functions) ⏳ REVIEW NEEDED

#### `computeAndCacheDashboard`
- **User Preferences Needed**:
  - ALL preferences (comprehensive)
  - Currency, locale, date format
  - Dashboard layout preference
  - Chart type preference
- **Consumer Value**: Primary interface
- **TODO**: Critical - full preference integration

#### `getAccountSummary`, `getTransactionSummary`
- **User Preferences Needed**:
  - Currency for amounts
  - Date format for periods
- **Consumer Value**: Dashboard widgets
- **TODO**: Add preference support

#### `invalidateDashboardCache`
- **User Preferences**: None
- **Consumer Value**: Data refresh
- **TODO**: No changes needed

---

### 9. Report Functions (2 functions) ⏳ REVIEW NEEDED

#### `generateReport`
- **User Preferences Needed**:
  - Currency for amounts
  - Date format for report periods
  - Locale for report formatting
  - Financial year for fiscal reports
  - Require auth setting (if sensitive)
- **Consumer Value**: Financial reporting
- **TODO**: Comprehensive preference support

#### `getDashboardAnalytics`
- **User Preferences Needed**:
  - Currency, date format, locale
  - Chart type for visualizations
- **Consumer Value**: Analytics dashboard
- **TODO**: Add preference support

---

### 10. Import/Export Functions (4 functions) ⏳ REVIEW NEEDED

#### `importTransactions`, `batchImportTransactions`
- **User Preferences Needed**:
  - Default currency for imported data
  - Date format for parsing
  - Timezone for timestamps
  - Auto-categorize setting
  - Duplicate detection setting
- **Consumer Value**: Data import
- **TODO**: Critical - use preferences for parsing

#### `exportUserData`, `exportTransactions`
- **User Preferences Needed**:
  - Currency for exported amounts
  - Date format for export
  - Locale for field names
  - Require auth setting
- **Consumer Value**: Data export
- **TODO**: Format exports with preferences

#### `clearUserData`
- **User Preferences**: Should also clear preferences on request
- **Consumer Value**: Data cleanup
- **TODO**: Add option to reset preferences

#### `getUserStatistics`
- **User Preferences**:
  - Currency for stats
  - Date format
- **Consumer Value**: User insights
- **TODO**: Use preferences

---

### 11. Duplicate Detection (2 functions) ⏳ REVIEW NEEDED

#### `checkDuplicateTransaction`, `batchCheckDuplicates`
- **User Preferences Needed**:
  - Duplicate detection enabled setting
  - Threshold preferences (if configurable)
- **Consumer Value**: Data quality
- **TODO**: Respect duplicate detection setting

---

### 12. Pub/Sub Functions (5 functions) ⏳ REVIEW NEEDED

#### `scheduledBudgetCheck`, `processBudgetAlerts`
- **User Preferences Needed**:
  - Budget alerts enabled
  - Email notifications enabled
  - Push notifications enabled
  - Timezone for alert timing
- **Consumer Value**: Proactive alerts
- **TODO**: Respect notification preferences

#### `processTransactionInsights`
- **User Preferences Needed**:
  - Unusual spending alerts enabled
  - Smart suggestions enabled
  - Notification preferences
- **Consumer Value**: Financial insights
- **TODO**: Use preferences

#### `processScheduledReports`
- **User Preferences Needed**:
  - Email notifications enabled
  - Currency, date format for reports
  - Financial year settings
- **Consumer Value**: Scheduled reports
- **TODO**: Format with preferences

#### `processDataExportComplete`
- **User Preferences**: Email notifications
- **Consumer Value**: Export notifications
- **TODO**: Respect notification setting

---

## Implementation Priority

### Phase 1: Critical (Immediate) ✅
1. ✅ User preferences system (getUserPreferences, updateUserPreferences, resetUserPreferences)
2. ✅ Analytics - calculateNetWorth (COMPLETED)
3. ⏳ Transaction creation (createTransaction) - uses default currency
4. ⏳ Account creation (createAccount) - uses default currency

### Phase 2: High Priority (Week 1)
5. ⏳ All remaining analytics functions
6. ⏳ Dashboard functions (computeAndCacheDashboard)
7. ⏳ Budget functions (createBudget, calculateBudgetProgress)
8. ⏳ Goal functions (createGoal, calculateGoalProgress)

### Phase 3: Medium Priority (Week 2)
9. ⏳ Deposit calculation functions
10. ⏳ Investment functions (getInvestmentsSummary)
11. ⏳ Report generation (generateReport)
12. ⏳ Import/export functions

### Phase 4: Low Priority (Week 3)
13. ⏳ Notification preferences (Pub/Sub functions)
14. ⏳ Duplicate detection settings
15. ⏳ Localization for dropdown values

---

## Missing Consumer Functions

### Financial Planning
- **Monthly savings calculator**: Based on income and expenses
- **Retirement calculator**: Long-term financial planning
- **Tax calculator**: India-specific tax calculations
- **EMI calculator**: Loan and EMI planning

### Insights & Recommendations
- **Spending patterns**: AI-powered insights
- **Budget recommendations**: Smart budget suggestions
- **Investment suggestions**: Based on risk profile
- **Savings opportunities**: Identify potential savings

### Social & Sharing
- **Share net worth**: Generate shareable snapshot
- **Export reports**: PDF/CSV generation
- **Family accounts**: Shared financial tracking (future)

### Account Aggregation
- **Bank account linking**: Plaid/Finicity integration
- **Auto-sync transactions**: Automatic data sync
- **Balance refresh**: Real-time balance updates

### Security & Privacy
- **Two-factor authentication**: Enhanced security
- **Audit logs**: Track all data changes
- **Data encryption**: End-to-end encryption
- **Session management**: Device tracking

---

## Consumer Experience Improvements

### 1. Consistent Currency Display
- **Current**: Hardcoded 'INR' in multiple functions
- **Improved**: Always use `userPreferences.currency`
- **Impact**: Supports international users

### 2. Cultural Financial Practices
- **Current**: Assumes April-March financial year
- **Improved**: Uses `useFinancialYear` and `financialYearStartMonth`
- **Impact**: Accurate for global users

### 3. Number Formatting
- **Current**: Western format (1,000,000)
- **Improved**: Supports Indian format (10,00,000) and Western
- **Impact**: Better readability for Indian users

### 4. Date Handling
- **Current**: Inconsistent date formats
- **Improved**: Uses `dateFormat` and `timezone` preferences
- **Impact**: Consistent user experience

### 5. Notification Control
- **Current**: All notifications enabled
- **Improved**: Respects individual notification preferences
- **Impact**: Reduced notification fatigue

### 6. Smart Defaults
- **Current**: Must configure everything
- **Improved**: Intelligent defaults based on locale
- **Impact**: Faster onboarding

---

## Webapp Integration

### API Client Updates Needed

```typescript
// packages/webapp/src/core/api/preferencesApi.ts
export const preferencesApi = {
  getUserPreferences: () => 
    callFunction<GetUserPreferencesRequest, GetUserPreferencesResponse>(
      'getUserPreferences', 
      {}
    ),
  
  updateUserPreferences: (preferences: Partial<UserPreferences>) =>
    callFunction<UpdateUserPreferencesRequest, UpdateUserPreferencesResponse>(
      'updateUserPreferences',
      { preferences }
    ),
  
  resetUserPreferences: (confirmReset: boolean) =>
    callFunction<ResetUserPreferencesRequest, ResetUserPreferencesResponse>(
      'resetUserPreferences',
      { confirmReset }
    ),
};
```

### AppStore Integration

```typescript
// Sync webapp appStore with Cloud Functions
// On app init:
const prefs = await preferencesApi.getUserPreferences();
appStore.setCurrency(prefs.preferences.currency);
appStore.setLocale(prefs.preferences.locale);
appStore.setDateFormat(prefs.preferences.dateFormat);

// On preference changes:
await preferencesApi.updateUserPreferences({
  currency: 'USD',
  locale: 'en-US',
});
```

---

## macOS App Integration

### UserSettings Synchronization

The macOS app has comprehensive `UserSettings` and `LocalizationConfig`. Integration needed:

```swift
// Sync with Cloud Functions on app launch
let prefs = try await preferencesService.getUserPreferences()
UserSettings.shared.currency = prefs.currency
UserSettings.shared.locale = Locale(identifier: prefs.locale)
LocalizationConfig.shared.update(from: prefs)

// Sync changes to Cloud Functions
func updatePreferences(_ prefs: UserPreferences) async throws {
    try await preferencesService.updateUserPreferences(prefs)
    // Update local UserSettings
    UserSettings.shared.apply(prefs)
}
```

---

## Android App Considerations

### SharedPreferences Sync
- Android apps typically use `SharedPreferences` for local settings
- Need to sync with Cloud Functions on:
  - App launch
  - Settings screen save
  - Preference changes

### DataStore Integration
```kotlin
// Use Jetpack DataStore for preferences
val userPreferencesFlow: Flow<UserPreferences> = preferencesDataStore.data
    .map { preferences ->
        UserPreferences(
            currency = preferences[CURRENCY_KEY] ?: "INR",
            locale = preferences[LOCALE_KEY] ?: "en-IN",
            // ...
        )
    }

// Sync with Cloud Functions
suspend fun syncPreferences() {
    val cloudPrefs = preferencesApi.getUserPreferences()
    preferencesDataStore.updateData { currentPrefs ->
        currentPrefs.toBuilder()
            .putString(CURRENCY_KEY, cloudPrefs.currency)
            .putString(LOCALE_KEY, cloudPrefs.locale)
            .build()
    }
}
```

---

## Testing Strategy

### Unit Tests
- Test default preference creation
- Test preference updates (partial)
- Test preference reset
- Test helper functions (fetchUserPreferences)

### Integration Tests
- Test Cloud Function calls with authentication
- Test Firestore reads/writes
- Test default fallbacks when preferences don't exist

### E2E Tests
- Test full user journey (signup → set preferences → use app)
- Test preference sync across devices
- Test locale changes affect all functions

---

## Performance Considerations

### Caching Strategy
- **Current**: Fetches preferences on every function call
- **Improvement**: Cache preferences in Cloud Function memory
- **Implementation**:
```typescript
const preferencesCache = new Map<string, { prefs: UserPreferences, timestamp: number }>();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

async function getCachedPreferences(userId: string): Promise<UserPreferences> {
  const cached = preferencesCache.get(userId);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.prefs;
  }
  
  const prefs = await fetchUserPreferences(userId);
  preferencesCache.set(userId, { prefs, timestamp: Date.now() });
  return prefs;
}
```

### Firestore Optimization
- **Index**: Create index on `user_id` for fast lookups
- **Batch operations**: Update multiple preferences in single write
- **Read efficiency**: Preferences doc is small (~1KB)

---

## Security Considerations

### Access Control
- ✅ All preference functions require authentication
- ✅ Users can only access their own preferences
- ✅ Firestore rules should enforce user isolation:
```javascript
match /user_preferences/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Data Validation
- Validate currency codes (ISO 4217)
- Validate locale codes (BCP 47)
- Validate timezone (IANA timezone database)
- Sanitize string inputs

### Privacy
- Preferences are personal but not sensitive
- No PII in preferences (name, email, etc.)
- Safe to log for debugging

---

## Documentation for Developers

### Using Preferences in Cloud Functions

```typescript
import { fetchUserPreferences } from './preferences';

export const myFunction = onCall(async (request) => {
  const userId = getUserAuthenticated(request.auth).uid;
  
  // Get user preferences
  const prefs = await fetchUserPreferences(userId);
  
  // Use preferences
  const currency = prefs.currency;
  const locale = prefs.locale;
  const useFinancialYear = prefs.useFinancialYear;
  
  // Apply to calculations/formatting
  const result = calculateSomething(data, currency, useFinancialYear);
  
  return { result, currency };
});
```

### Best Practices

1. **Always fetch preferences early**: Get preferences at the start of the function
2. **Use helper functions**: Prefer `fetchUserPreferences()` over direct Firestore access
3. **Provide defaults**: Never assume preferences exist
4. **Cache when appropriate**: Use in-memory cache for repeated calls
5. **Document preference usage**: Comment which preferences are used
6. **Test with different locales**: Test functions with various preference combinations

---

## Migration Plan

### Existing Users
- **Strategy**: Create preferences on first function call after deployment
- **Fallback**: All functions work with hardcoded defaults if preferences don't exist
- **Communication**: Notify users to review and update preferences in settings

### Data Migration
- **Phase 1**: Deploy preference system (passive - doesn't affect existing behavior)
- **Phase 2**: Update functions one category at a time
- **Phase 3**: Monitor for issues, adjust defaults
- **Phase 4**: Deprecate hardcoded values

### Rollback Plan
- All functions have fallback to hardcoded defaults
- Can disable preference fetching with feature flag
- Preferences collection is separate - won't affect core data

---

## Metrics & Monitoring

### Track
- Preference creation rate (new users)
- Preference update frequency
- Most commonly changed preferences
- Locale distribution (for localization priorities)
- Currency distribution (for exchange rate needs)
- Error rates in preference functions

### Alerts
- High error rate in `getUserPreferences`
- Slow Firestore reads (>500ms)
- Invalid preference values being set
- Unusual preference patterns (security)

---

## Next Steps

1. ✅ **User preferences system created**
   - UserPreferences types in shared-types
   - getUserPreferences, updateUserPreferences, resetUserPreferences functions
   - Helper functions for preference fetching

2. ✅ **Analytics functions updated**
   - calculateNetWorth now uses user currency preference

3. **Continue updating remaining functions**:
   - [ ] Update getPortfolioSummary
   - [ ] Update getTransactionAnalytics
   - [ ] Update getCashFlow
   - [ ] Update getDashboard (highest priority - comprehensive)

4. **Create webapp API client for preferences**:
   - [ ] Create preferencesApi.ts
   - [ ] Export from webapp/api/index.ts
   - [ ] Add preference sync to appStore

5. **Update remaining Cloud Function categories**:
   - [ ] Transaction functions (critical)
   - [ ] Account functions (critical)
   - [ ] Budget functions
   - [ ] Goal functions
   - [ ] Deposit calculation functions
   - [ ] Investment functions
   - [ ] Dashboard functions
   - [ ] Report functions
   - [ ] Import/export functions
   - [ ] Notification functions

6. **Testing & validation**:
   - [ ] Unit tests for preference functions
   - [ ] Integration tests with different locales
   - [ ] Performance testing with caching

7. **Documentation**:
   - [ ] API documentation for developers
   - [ ] User guide for preferences
   - [ ] Migration guide for existing users

---

## Summary

### Completed ✅
- User preferences data model and types
- Three preference management Cloud Functions
- Helper functions for internal use
- Updated `calculateNetWorth` to use preferences
- Comprehensive review of all 53+ Cloud Functions

### In Progress ⏳
- Updating remaining analytics functions
- Creating webapp API client for preferences

### Pending ❌
- 48+ Cloud Functions need preference integration
- Webapp appStore synchronization with Cloud Functions
- macOS app UserSettings sync
- Android app SharedPreferences sync
- Comprehensive testing
- Performance optimization with caching
- Missing consumer functions (calculators, insights, etc.)

### Key Insight
**Every Cloud Function that returns formatted data (currency, dates, numbers) should use user preferences for consistent consumer experience across all platforms.**

The foundation is now in place - next priority is systematically updating all functions to use preferences instead of hardcoded values.
