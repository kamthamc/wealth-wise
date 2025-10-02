# WealthWise Dashboard & Analytics UI

Modern SwiftUI dashboard providing comprehensive portfolio visualization and analytics.

## Overview

The Dashboard provides a consolidated view of all financial data with interactive widgets, responsive layouts, and full dark mode support.

## Features

### ✅ Consolidated Net Worth View
- Real-time net worth calculation
- 30-day trend chart with gradient styling
- Monthly change percentage and amount
- Asset breakdown by category
- Color-coded visualizations

### ✅ Asset Allocation Widget
- Interactive pie chart with donut design
- Asset type distribution
- Tap-to-select functionality
- Detailed breakdown with percentages
- Asset count per category

### ✅ Recent Transactions Panel
- Last 5 transactions display
- Color-coded transaction types (Income/Expense/Investment)
- Category icons and labels
- Relative date formatting
- Empty state handling

### ✅ Performance Metrics
- Returns: 1M, 3M, 6M, 1Y
- Risk metrics: Volatility, Sharpe Ratio
- Color-coded performance indicators
- Grid layout for easy comparison

### ✅ Alerts & Notifications
- Severity-based color coding (Info/Warning/Critical)
- Action required badges
- Relative timestamps
- Empty state with success message
- Up to 3 most recent alerts

### ✅ Responsive Layout
- Single column on iPhone
- Two-column on iPad and Mac
- Adaptive widget sizing
- Portrait/landscape support
- Platform-specific optimizations

### ✅ Dark Mode Support
- Automatic color scheme adaptation
- High contrast ratios
- Chart theme switching
- Proper opacity handling

### ✅ Localization
- English (en)
- Hindi (hi)
- Tamil (ta)
- All user-facing strings localized
- Currency formatting per locale
- RTL support ready

## Architecture

### DashboardCoordinator
Central state manager using `@Observable` macro:
- Manages dashboard state and view selection
- Handles data loading and refreshing
- Coordinates timeframe and currency switching
- Singleton pattern for shared state

### Data Models
Type-safe models conforming to `Sendable`:
- `DashboardData` - Main container
- `NetWorthData` - Net worth metrics
- `AssetAllocationSummary` - Asset distribution
- `TransactionSummary` - Transaction data
- `PerformanceMetricsSummary` - Returns and risk
- `DashboardAlert` - Notifications

### Widgets
Modular, reusable components:
- `NetWorthWidget` - Net worth with chart
- `AssetAllocationWidget` - Pie chart
- `RecentTransactionsWidget` - Transaction list
- `PerformanceMetricsWidget` - Metrics grid
- `AlertsWidget` - Notifications panel

## Usage

### Basic Integration

```swift
import SwiftUI

@available(iOS 18.6, macOS 15.6, *)
struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}
```

### Accessing Dashboard Data

```swift
let coordinator = DashboardCoordinator.shared

// Switch timeframe
coordinator.switchTimeframe(.year)

// Switch currency
coordinator.switchCurrency("USD")

// Refresh data
await coordinator.refreshDashboardData()
```

### Custom Widget Styling

Widgets support customization through SwiftUI modifiers:

```swift
NetWorthWidget(netWorthData: data)
    .frame(maxWidth: 400)
    .padding()
```

## Timeframe Options

- **1W** - Last 7 days
- **1M** - Last 30 days
- **3M** - Last quarter
- **1Y** - Last year
- **All** - All available data

## View Types

- **Overview** - Main dashboard with all widgets
- **Portfolio** - Asset-focused view
- **Goals** - Financial goals tracking
- **Taxes** - Tax information
- **Analytics** - Detailed analytics

## Testing

Comprehensive test coverage:
- `DashboardCoordinatorTests` - State management
- `DashboardModelsTests` - Data model validation
- Unit tests for all data structures
- Async/await testing patterns

Run tests:
```bash
xcodebuild -project WealthWise.xcodeproj -scheme WealthWise test
```

## Platform Support

- **iOS**: 18.6+
- **macOS**: 15.6+
- **iPad**: Optimized two-column layout
- **Mac**: Native window sizing

## Dependencies

- SwiftUI (iOS 18.6+/macOS 15.6+)
- Charts framework
- Foundation
- LocalizationManager (internal)

## Performance

- Lazy loading for large datasets
- Efficient chart rendering
- Minimal state updates
- Background data refresh

## Accessibility

- VoiceOver support
- Dynamic Type scaling
- High contrast colors
- Semantic labels on all elements

## Future Enhancements

- [ ] Widget customization (add/remove/reorder)
- [ ] Export dashboard as PDF
- [ ] Scheduled data refresh
- [ ] Real-time data updates
- [ ] Additional chart types
- [ ] Benchmark comparisons
- [ ] Goal integration
- [ ] Tax optimization suggestions

## Contributing

When adding new widgets:
1. Create widget in `Widgets/` directory
2. Add to `DashboardView` layout
3. Update `DashboardCoordinator` if needed
4. Add localization strings
5. Write unit tests
6. Update this README

## License

Part of WealthWise project - Modern financial management for cross-border portfolios.
