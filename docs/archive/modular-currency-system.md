# WealthWise Modular Currency System

## Overview
A comprehensive currency management system that enables seamless switching between currencies, real-time conversion, and localized formatting across all supported markets.

## Currency Module Architecture

### 1. Core Currency Types
```swift
enum SupportedCurrency: String, CaseIterable, Codable {
    // Major Currencies
    case inr = "INR"  // Indian Rupee
    case usd = "USD"  // US Dollar
    case eur = "EUR"  // Euro
    case gbp = "GBP"  // British Pound
    case cad = "CAD"  // Canadian Dollar
    case aud = "AUD"  // Australian Dollar
    case sgd = "SGD"  // Singapore Dollar
    case hkd = "HKD"  // Hong Kong Dollar
    case jpy = "JPY"  // Japanese Yen
    case chf = "CHF"  // Swiss Franc
    
    // Regional Currencies
    case aed = "AED"  // UAE Dirham
    case sar = "SAR"  // Saudi Riyal
    case qar = "QAR"  // Qatari Riyal
    case nzd = "NZD"  // New Zealand Dollar
    case zar = "ZAR"  // South African Rand
    
    var displayName: String {
        switch self {
        case .inr: return "Indian Rupee"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .sgd: return "Singapore Dollar"
        case .hkd: return "Hong Kong Dollar"
        case .jpy: return "Japanese Yen"
        case .chf: return "Swiss Franc"
        case .aed: return "UAE Dirham"
        case .sar: return "Saudi Riyal"
        case .qar: return "Qatari Riyal"
        case .nzd: return "New Zealand Dollar"
        case .zar: return "South African Rand"
        }
    }
    
    var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "C$"
        case .aud: return "A$"
        case .sgd: return "S$"
        case .hkd: return "HK$"
        case .jpy: return "¥"
        case .chf: return "CHF"
        case .aed: return "د.إ"
        case .sar: return "ر.س"
        case .qar: return "ر.ق"
        case .nzd: return "NZ$"
        case .zar: return "R"
        }
    }
    
    var locale: Locale {
        switch self {
        case .inr: return Locale(identifier: "en_IN")
        case .usd: return Locale(identifier: "en_US")
        case .eur: return Locale(identifier: "en_EU")
        case .gbp: return Locale(identifier: "en_GB")
        case .cad: return Locale(identifier: "en_CA")
        case .aud: return Locale(identifier: "en_AU")
        case .sgd: return Locale(identifier: "en_SG")
        case .hkd: return Locale(identifier: "en_HK")
        case .jpy: return Locale(identifier: "ja_JP")
        case .chf: return Locale(identifier: "de_CH")
        case .aed: return Locale(identifier: "ar_AE")
        case .sar: return Locale(identifier: "ar_SA")
        case .qar: return Locale(identifier: "ar_QA")
        case .nzd: return Locale(identifier: "en_NZ")
        case .zar: return Locale(identifier: "en_ZA")
        }
    }
    
    var decimalPlaces: Int {
        switch self {
        case .jpy: return 0  // Japanese Yen has no decimal places
        default: return 2
        }
    }
    
    var numberingSystem: NumberingSystem {
        switch self {
        case .inr: return .indian  // Lakhs, Crores
        case .jpy: return .japanese
        default: return .western  // Thousands, Millions
        }
    }
}

enum NumberingSystem {
    case western    // 1,000,000 (Million)
    case indian     // 10,00,000 (10 Lakh)
    case japanese   // 1,000,000 (100万)
    case arabic     // ١٬٠٠٠٬٠٠٠
}

struct CurrencyAmount: Codable {
    let value: Decimal
    let currency: SupportedCurrency
    var displayValue: String {
        CurrencyFormatter.shared.format(amount: value, currency: currency)
    }
}
```

### 2. Currency Manager
```swift
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var baseCurrency: SupportedCurrency = .inr
    @Published var displayCurrency: SupportedCurrency = .inr
    @Published var exchangeRates: [String: Decimal] = [:]
    @Published var lastUpdated: Date = Date()
    
    private let exchangeRateService: ExchangeRateService
    private let userDefaults = UserDefaults.standard
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    
    private init() {
        self.exchangeRateService = ExchangeRateService()
        loadSavedSettings()
        setupAutoRefresh()
    }
    
    // MARK: - Currency Switching
    func setBaseCurrency(_ currency: SupportedCurrency) {
        baseCurrency = currency
        userDefaults.set(currency.rawValue, forKey: "baseCurrency")
        objectWillChange.send()
    }
    
    func setDisplayCurrency(_ currency: SupportedCurrency) {
        displayCurrency = currency
        userDefaults.set(currency.rawValue, forKey: "displayCurrency")
        objectWillChange.send()
    }
    
    func switchToUnifiedCurrency(_ currency: SupportedCurrency) {
        setBaseCurrency(currency)
        setDisplayCurrency(currency)
        NotificationCenter.default.post(name: .currencyChanged, object: currency)
    }
    
    // MARK: - Currency Conversion
    func convert(
        amount: Decimal, 
        from sourceCurrency: SupportedCurrency, 
        to targetCurrency: SupportedCurrency
    ) -> Decimal {
        guard sourceCurrency != targetCurrency else { return amount }
        
        // Convert to USD first (base rate), then to target currency
        let usdAmount = convertToUSD(amount: amount, from: sourceCurrency)
        return convertFromUSD(amount: usdAmount, to: targetCurrency)
    }
    
    func convertToDisplayCurrency(amount: CurrencyAmount) -> CurrencyAmount {
        let convertedValue = convert(
            amount: amount.value,
            from: amount.currency,
            to: displayCurrency
        )
        return CurrencyAmount(value: convertedValue, currency: displayCurrency)
    }
    
    func convertToBaseCurrency(amount: CurrencyAmount) -> CurrencyAmount {
        let convertedValue = convert(
            amount: amount.value,
            from: amount.currency,
            to: baseCurrency
        )
        return CurrencyAmount(value: convertedValue, currency: baseCurrency)
    }
    
    private func convertToUSD(amount: Decimal, from currency: SupportedCurrency) -> Decimal {
        guard currency != .usd else { return amount }
        guard let rate = exchangeRates[currency.rawValue] else { return amount }
        return amount / rate
    }
    
    private func convertFromUSD(amount: Decimal, to currency: SupportedCurrency) -> Decimal {
        guard currency != .usd else { return amount }
        guard let rate = exchangeRates[currency.rawValue] else { return amount }
        return amount * rate
    }
    
    // MARK: - Exchange Rate Management
    func refreshExchangeRates() async {
        do {
            let rates = try await exchangeRateService.fetchLatestRates()
            await MainActor.run {
                self.exchangeRates = rates
                self.lastUpdated = Date()
                self.saveExchangeRates()
            }
        } catch {
            print("Failed to refresh exchange rates: \(error)")
        }
    }
    
    private func setupAutoRefresh() {
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task {
                await self.refreshExchangeRates()
            }
        }
    }
    
    private func loadSavedSettings() {
        if let savedBaseCurrency = userDefaults.string(forKey: "baseCurrency"),
           let currency = SupportedCurrency(rawValue: savedBaseCurrency) {
            baseCurrency = currency
        }
        
        if let savedDisplayCurrency = userDefaults.string(forKey: "displayCurrency"),
           let currency = SupportedCurrency(rawValue: savedDisplayCurrency) {
            displayCurrency = currency
        }
        
        loadExchangeRates()
    }
    
    private func saveExchangeRates() {
        if let data = try? JSONEncoder().encode(exchangeRates) {
            userDefaults.set(data, forKey: "exchangeRates")
        }
        userDefaults.set(lastUpdated, forKey: "ratesLastUpdated")
    }
    
    private func loadExchangeRates() {
        if let data = userDefaults.data(forKey: "exchangeRates"),
           let rates = try? JSONDecoder().decode([String: Decimal].self, from: data) {
            exchangeRates = rates
        }
        
        if let lastUpdate = userDefaults.object(forKey: "ratesLastUpdated") as? Date {
            lastUpdated = lastUpdate
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let currencyChanged = Notification.Name("currencyChanged")
    static let exchangeRatesUpdated = Notification.Name("exchangeRatesUpdated")
}
```

### 3. Currency Formatter
```swift
class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    private var formatters: [String: NumberFormatter] = [:]
    
    private init() {
        setupFormatters()
    }
    
    func format(amount: Decimal, currency: SupportedCurrency, style: FormattingStyle = .full) -> String {
        let key = "\(currency.rawValue)_\(style.rawValue)"
        
        if let formatter = formatters[key] {
            return formatter.string(from: amount as NSDecimalNumber) ?? "0"
        }
        
        // Create new formatter if not cached
        let formatter = createFormatter(for: currency, style: style)
        formatters[key] = formatter
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
    
    func formatWithConversion(
        amount: CurrencyAmount, 
        targetCurrency: SupportedCurrency,
        style: FormattingStyle = .full
    ) -> String {
        let convertedAmount = CurrencyManager.shared.convert(
            amount: amount.value,
            from: amount.currency,
            to: targetCurrency
        )
        return format(amount: convertedAmount, currency: targetCurrency, style: style)
    }
    
    private func createFormatter(for currency: SupportedCurrency, style: FormattingStyle) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.locale = currency.locale
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.minimumFractionDigits = currency.decimalPlaces
        
        // Handle Indian numbering system
        if currency.numberingSystem == .indian {
            formatter.groupingSize = 3
            formatter.secondaryGroupingSize = 2
            formatter.usesGroupingSeparator = true
        }
        
        switch style {
        case .compact:
            formatter.numberStyle = .decimal
            formatter.currencySymbol = ""
        case .symbol:
            formatter.currencySymbol = currency.symbol
        case .full:
            break // Use default currency formatting
        }
        
        return formatter
    }
    
    private func setupFormatters() {
        // Pre-create formatters for most common currencies
        let commonCurrencies: [SupportedCurrency] = [.inr, .usd, .eur, .gbp, .cad]
        let styles: [FormattingStyle] = [.full, .symbol, .compact]
        
        for currency in commonCurrencies {
            for style in styles {
                let key = "\(currency.rawValue)_\(style.rawValue)"
                formatters[key] = createFormatter(for: currency, style: style)
            }
        }
    }
}

enum FormattingStyle: String {
    case full = "full"      // $1,234.56
    case symbol = "symbol"  // $1,234.56
    case compact = "compact" // 1,234.56
}
```

### 4. Exchange Rate Service
```swift
protocol ExchangeRateServiceProtocol {
    func fetchLatestRates() async throws -> [String: Decimal]
    func fetchRatesForCurrencies(_ currencies: [SupportedCurrency]) async throws -> [String: Decimal]
}

class ExchangeRateService: ExchangeRateServiceProtocol {
    private let baseURL = "https://api.exchangerate-api.com/v4/latest/"
    private let session = URLSession.shared
    
    func fetchLatestRates() async throws -> [String: Decimal] {
        let url = URL(string: "\(baseURL)USD")!
        let (data, _) = try await session.data(from: url)
        
        struct ExchangeRateResponse: Codable {
            let rates: [String: Double]
        }
        
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        // Convert Double to Decimal for precision
        var decimalRates: [String: Decimal] = [:]
        for (currency, rate) in response.rates {
            decimalRates[currency] = Decimal(rate)
        }
        
        return decimalRates
    }
    
    func fetchRatesForCurrencies(_ currencies: [SupportedCurrency]) async throws -> [String: Decimal] {
        let allRates = try await fetchLatestRates()
        
        var filteredRates: [String: Decimal] = [:]
        for currency in currencies {
            filteredRates[currency.rawValue] = allRates[currency.rawValue]
        }
        
        return filteredRates
    }
}

// Mock service for testing
class MockExchangeRateService: ExchangeRateServiceProtocol {
    func fetchLatestRates() async throws -> [String: Decimal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            "INR": 83.12,
            "EUR": 0.85,
            "GBP": 0.73,
            "CAD": 1.35,
            "AUD": 1.52,
            "SGD": 1.34,
            "HKD": 7.83,
            "JPY": 149.50,
            "CHF": 0.88
        ]
    }
    
    func fetchRatesForCurrencies(_ currencies: [SupportedCurrency]) async throws -> [String: Decimal] {
        let allRates = try await fetchLatestRates()
        return currencies.reduce(into: [String: Decimal]()) { result, currency in
            result[currency.rawValue] = allRates[currency.rawValue]
        }
    }
}
```

### 5. Currency Selection UI Components
```swift
struct CurrencySelectionView: View {
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingCurrencyPicker = false
    @State private var selectedCurrency: SupportedCurrency = .inr
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Currency Display
            HStack {
                Text("Display Currency")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingCurrencyPicker = true
                }) {
                    HStack {
                        Text(currencyManager.displayCurrency.symbol)
                            .font(.title2)
                        Text(currencyManager.displayCurrency.rawValue)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Quick Currency Switching
            QuickCurrencySwitcher()
            
            // Unified Currency Mode
            UnifiedCurrencyToggle()
            
            // Exchange Rate Status
            ExchangeRateStatusView()
        }
        .padding()
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerSheet(selectedCurrency: $selectedCurrency) { currency in
                currencyManager.setDisplayCurrency(currency)
            }
        }
    }
}

struct QuickCurrencySwitcher: View {
    @StateObject private var currencyManager = CurrencyManager.shared
    private let quickCurrencies: [SupportedCurrency] = [.inr, .usd, .eur, .gbp, .cad]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Switch")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickCurrencies, id: \.self) { currency in
                        CurrencyQuickButton(currency: currency)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CurrencyQuickButton: View {
    let currency: SupportedCurrency
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        Button(action: {
            currencyManager.switchToUnifiedCurrency(currency)
        }) {
            VStack(spacing: 4) {
                Text(currency.symbol)
                    .font(.title2)
                Text(currency.rawValue)
                    .font(.caption)
            }
            .frame(width: 60, height: 50)
            .background(
                currencyManager.displayCurrency == currency ? 
                Color.blue : Color.gray.opacity(0.2)
            )
            .foregroundColor(
                currencyManager.displayCurrency == currency ? 
                .white : .primary
            )
            .cornerRadius(8)
        }
    }
}

struct UnifiedCurrencyToggle: View {
    @StateObject private var currencyManager = CurrencyManager.shared
    @AppStorage("unifiedCurrencyMode") private var unifiedMode = false
    
    var body: some View {
        Toggle("Unified Currency Mode", isOn: $unifiedMode)
            .toggleStyle(SwitchToggleStyle())
            .onChange(of: unifiedMode) { isEnabled in
                if isEnabled {
                    currencyManager.setBaseCurrency(currencyManager.displayCurrency)
                }
            }
        
        if unifiedMode {
            Text("All amounts will be displayed in \(currencyManager.displayCurrency.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ExchangeRateStatusView: View {
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Exchange Rates")
                    .font(.subheadline)
                Text("Last updated: \(currencyManager.lastUpdated, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Refresh") {
                Task {
                    await currencyManager.refreshExchangeRates()
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 8)
    }
}
```

### 6. Currency-Aware Data Models
```swift
protocol CurrencyConvertible {
    var amount: CurrencyAmount { get set }
    func convertTo(_ currency: SupportedCurrency) -> Self
    func displayAmount() -> String
}

struct Asset: Identifiable, Codable, CurrencyConvertible {
    let id = UUID()
    let name: String
    let type: AssetType
    var amount: CurrencyAmount
    let country: SupportedCountry
    
    func convertTo(_ currency: SupportedCurrency) -> Asset {
        var converted = self
        converted.amount = CurrencyAmount(
            value: CurrencyManager.shared.convert(
                amount: amount.value,
                from: amount.currency, 
                to: currency
            ),
            currency: currency
        )
        return converted
    }
    
    func displayAmount() -> String {
        return CurrencyManager.shared.convertToDisplayCurrency(amount: amount).displayValue
    }
}

struct Transaction: Identifiable, Codable, CurrencyConvertible {
    let id = UUID()
    let date: Date
    let description: String
    var amount: CurrencyAmount
    let category: TransactionCategory
    let account: UUID
    
    func convertTo(_ currency: SupportedCurrency) -> Transaction {
        var converted = self
        converted.amount = CurrencyAmount(
            value: CurrencyManager.shared.convert(
                amount: amount.value,
                from: amount.currency,
                to: currency
            ),
            currency: currency
        )
        return converted
    }
    
    func displayAmount() -> String {
        return CurrencyManager.shared.convertToDisplayCurrency(amount: amount).displayValue
    }
}

// Extension for arrays of currency convertible items
extension Array where Element: CurrencyConvertible {
    func convertAll(to currency: SupportedCurrency) -> [Element] {
        return self.map { $0.convertTo(currency) }
    }
    
    func totalAmount() -> CurrencyAmount {
        let displayCurrency = CurrencyManager.shared.displayCurrency
        let total = self.reduce(Decimal(0)) { sum, item in
            let converted = CurrencyManager.shared.convert(
                amount: item.amount.value,
                from: item.amount.currency,
                to: displayCurrency
            )
            return sum + converted
        }
        return CurrencyAmount(value: total, currency: displayCurrency)
    }
}
```

### 7. Currency Persistence
```swift
extension CurrencyAmount {
    // Core Data compatibility
    var persistableValue: String {
        return "\(value)|\(currency.rawValue)"
    }
    
    init?(persistableValue: String) {
        let components = persistableValue.split(separator: "|")
        guard components.count == 2,
              let value = Decimal(string: String(components[0])),
              let currency = SupportedCurrency(rawValue: String(components[1])) else {
            return nil
        }
        self.value = value
        self.currency = currency
    }
}

// Core Data Transformer
@objc(CurrencyAmountTransformer)
class CurrencyAmountTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSString.self, NSNumber.self]
    }
    
    override class func transformedValueClass() -> AnyClass {
        return CurrencyAmount.self as AnyClass
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let currencyAmount = value as? CurrencyAmount else { return nil }
        return try? JSONEncoder().encode(currencyAmount)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode(CurrencyAmount.self, from: data)
    }
}
```

## Implementation Guidelines

### 1. **Easy Currency Switching**
- Single tap currency switching via QuickCurrencySwitcher
- Unified currency mode for viewing entire app in one currency
- Persistent currency preferences across app launches

### 2. **Real-time Conversion**
- Automatic conversion using latest exchange rates
- Cached rates with hourly refresh
- Offline support with last known rates

### 3. **Localized Formatting**
- Currency-specific number formatting (Indian lakhs/crores)
- Locale-appropriate decimal separators
- Cultural numbering preferences

### 4. **Performance Optimization**
- Cached formatters for common currencies
- Efficient conversion algorithms
- Background rate updates

This modular currency system provides the foundation for multi-country support while maintaining simplicity and performance.
