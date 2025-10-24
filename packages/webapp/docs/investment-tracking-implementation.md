# Investment Tracking Implementation Plan

## Overview
Comprehensive account detail page with investment tracking, graphs, and real-time price syncing capabilities.

---

## Features Implemented

### 1. **Investment Types & Schema** ✅
**File**: `/webapp/src/core/db/types.ts`

**Asset Types Supported**:
- Stocks
- Mutual Funds
- ETFs
- Commodities
- REITs
- Bonds
- Crypto

**Transaction Types**:
- Buy
- Sell
- Dividend
- Bonus
- Split
- Rights
- IPO

**Data Models**:
- `InvestmentHolding`: Tracks quantity, cost basis, current value
- `InvestmentTransaction`: Records all buy/sell/dividend transactions
- `InvestmentPrice`: Cache for real-time prices
- `InvestmentPerformance`: Calculated metrics (P&L, XIRR, returns)
- `PortfolioSummary`: Aggregated portfolio statistics

### 2. **Investment Store** ✅
**File**: `/webapp/src/core/stores/investmentStore.ts`

**Capabilities**:
- Holdings CRUD operations
- Transaction management with automatic cost basis calculation
- Performance calculation using FIFO method
- XIRR (Extended Internal Rate of Return) calculation
- Portfolio summary aggregation
- Multi-account filtering
- Symbol-based grouping

**Key Functions**:
- `calculatePerformance()`: Computes realized/unrealized gains, dividends, XIRR
- `getPortfolioSummary()`: Aggregates across accounts with asset allocation
- `getHoldingsBySymbol()`: Groups holdings by symbol across accounts
- `filterHoldings()`: Advanced filtering by account, asset type, value range

### 3. **Firebase Service** ✅
**File**: `/webapp/src/core/services/firebaseService.ts`

**Features**:
- Price caching with 5-minute TTL
- Batch price updates
- Real-time subscription support
- Automatic cache invalidation
- Firebase Realtime Database integration (scaffolded)

**Methods**:
- `getCachedPrice()`: Fetch single price with cache fallback
- `getCachedPrices()`: Batch fetch multiple prices
- `updateCachedPrice()`: Update only if newer
- `subscribeToPriceUpdates()`: Real-time price streaming
- `fetchAndCachePrice()`: Fetch from API → Update cache

### 4. **Investment Charts** ✅
**File**: `/webapp/src/features/investments/components/InvestmentCharts.tsx`

**Chart Types**:

1. **Portfolio Performance Chart** (Area Chart)
   - Shows invested vs current value over time
   - Gradient fill for visual appeal
   - Responsive tooltip with currency formatting

2. **Asset Allocation Chart** (Pie Chart)
   - Visual breakdown by asset type
   - Color-coded segments
   - Percentage labels

3. **Holdings Performance Chart** (Bar Chart)
   - Sorted by return percentage
   - Green for gains, red for losses
   - Symbol-wise comparison

4. **Investment Price Chart** (Line Chart)
   - Historical price trend
   - Optional high/low bands
   - Zoom capability

5. **Monthly Returns Chart** (Bar Chart)
   - Month-by-month performance
   - Color-coded gains/losses

**Styling**: Custom CSS with theme support and responsive design

---

## Remaining Implementation

### 5. **Enhanced AccountDetails for Brokerage** 🔄

**Requirements**:
- Detect if account type is 'brokerage'
- Show different UI for brokerage vs bank accounts

**Brokerage Account View Should Include**:
- Portfolio summary card
  * Total invested
  * Current value  
  * Total returns (₹ and %)
  * Today's change
- Holdings table
  * Symbol, Name, Quantity
  * Avg Cost, Current Price, Current Value
  * P&L (₹ and %)
  * Action buttons (Buy, Sell, View Details)
- Performance chart (PortfolioPerformanceChart)
- Asset allocation pie chart
- Recent investment transactions (with type labels)

**Bank Account View Should Include**:
- Current balance graph over time
- Monthly income vs expense chart
- Recent transactions list

### 6. **Investment Detail View** 🔜

**File**: `/webapp/src/features/investments/components/InvestmentDetail.tsx`

**Features**:
- View holdings for specific symbol across accounts
- Account filter (multi-select)
- Aggregated metrics:
  * Total quantity across accounts
  * Weighted average cost
  * Total current value
  * Total P&L
  * XIRR
- Performance chart for the symbol
- Transaction history (all accounts or filtered)
- Add/Edit transaction modal

**Route**: `/investments/:symbol`

### 7. **Investment Filters** 🔜

**File**: `/webapp/src/features/investments/components/InvestmentFilters.tsx`

**Filter Options**:
- Account selection (multi-select dropdown)
- Asset type (stock, mutual fund, ETF, etc.)
- Date range picker
- Value range slider
- Search by symbol/name

**Interaction**:
- Apply filters to holdings list
- Persist filter state in URL search params
- Clear all button
- Filter count badge

### 8. **Firebase Config in Settings** 🔜

**Update**: `/webapp/src/routes/settings.tsx`

**New Section**: "Investment Sync Settings"
- Firebase configuration form
  * API Key (password field)
  * Project ID
  * Auto-sync toggle
  * Sync interval (5min, 15min, 30min, 1hr)
- Test connection button
- Last sync timestamp display
- Manual sync trigger button

**Storage**: Encrypted in IndexedDB or LocalStorage

### 9. **Investment Routes** 🔜

**New Routes**:
```typescript
// Individual investment detail
/investments/:symbol

// Portfolio overview (all holdings)
/portfolio

// Investment analytics
/portfolio/analytics
```

**Route Files**:
- `/webapp/src/routes/investments.$symbol.tsx`
- `/webapp/src/routes/portfolio.tsx`
- `/webapp/src/routes/portfolio.analytics.tsx`

---

## User Workflows

### Workflow 1: View Brokerage Account (Zerodha)
1. Navigate to `/accounts`
2. Click on Zerodha brokerage account
3. See portfolio summary, holdings, charts
4. Click on specific stock (e.g., RELIANCE)
5. View details across all accounts
6. Filter to show only Zerodha
7. Add buy/sell transaction

### Workflow 2: Cross-Account Investment View
1. Navigate to `/investments/RELIANCE`
2. See holdings from Zerodha, Groww, Upstox
3. View combined metrics
4. Filter to specific accounts
5. Analyze performance
6. Export report

### Workflow 3: Enable Real-Time Pricing
1. Go to Settings → Investment Sync
2. Enter Firebase API key
3. Enable auto-sync
4. Prices update automatically every 5 minutes
5. See live price updates in holdings table

---

## Data Flow

### Price Update Flow
```
1. User opens brokerage account page
2. Component fetches holdings from store
3. Extract symbols from holdings
4. Check Firebase cache for prices
   ├─ If cached & fresh → Use cached price
   └─ If missing/stale → Fetch from API
5. Update holding prices in store
6. Subscribe to real-time updates
7. Unsubscribe on component unmount
```

### Transaction Recording Flow
```
1. User clicks "Add Transaction" on holding
2. Modal opens with pre-filled symbol
3. User enters: type, quantity, price, date
4. Calculate total amount (qty × price + fees)
5. Save transaction to store
6. Recalculate average cost (FIFO)
7. Update holding quantity
8. Refresh performance metrics
```

---

## Technical Considerations

### Performance Optimization
- Virtualize large holdings tables (react-window)
- Lazy load charts (code splitting)
- Debounce price updates
- Memoize expensive calculations

### Security
- Encrypt Firebase API keys
- Never expose keys in client code
- Use environment variables for API endpoints
- Implement rate limiting for API calls

### Error Handling
- Graceful degradation when Firebase unavailable
- Retry logic for failed price fetches
- User-friendly error messages
- Fallback to last known prices

### Testing Strategy
- Unit tests for XIRR calculation
- Unit tests for FIFO cost basis
- Integration tests for transaction flows
- E2E tests for account detail page
- Mock Firebase service in tests

---

## API Integration (Future)

### Market Data APIs
**Options**:
1. **Alpha Vantage** (Free tier available)
   - Global stock prices
   - Cryptocurrency prices
   - Technical indicators

2. **Yahoo Finance API** (Unofficial)
   - Real-time quotes
   - Historical data
   - Good for Indian markets

3. **NSE/BSE Official APIs**
   - Authoritative for Indian stocks
   - May require registration

4. **Mutual Fund API**
   - AMFI NAV data
   - Daily updates
   - Free public API

### Implementation Plan
```typescript
// core/services/marketDataService.ts
class MarketDataService {
  async fetchPrice(symbol: string, exchange: string): Promise<number>
  async fetchHistoricalPrices(symbol: string, days: number): Promise<PriceData[]>
  async fetchMutualFundNAV(schemeCode: string): Promise<number>
}
```

---

## Next Steps

1. ✅ Complete chart components
2. 🔄 Enhance AccountDetails for brokerage accounts
3. Create InvestmentDetail component
4. Create InvestmentFilters component  
5. Add Firebase config to Settings
6. Create investment routes
7. Integrate market data API
8. Write comprehensive tests
9. Create user documentation
10. Performance testing and optimization

---

## Notes

- All monetary calculations use precise decimal arithmetic
- XIRR uses Newton-Raphson method for accuracy
- Cost basis calculation uses FIFO (First In, First Out)
- Supports multiple currencies (INR, USD, etc.)
- Firebase integration is optional (graceful degradation)
- Charts are fully responsive and accessible
- Color scheme follows app's design system
