# WealthWise Market Data Integration

## Market Data Architecture

### 1. Multi-Source Data Integration
```swift
// Market Data Provider Protocol
protocol MarketDataProvider {
    var providerId: String { get }
    var supportedInstruments: [InstrumentType] { get }
    var updateFrequency: TimeInterval { get }
    var requiresAuthentication: Bool { get }
    var rateLimits: RateLimits { get }
    
    func authenticate(apiKey: String) async throws
    func fetchPrice(for instrument: MarketInstrument) async throws -> PriceData
    func fetchBulkPrices(for instruments: [MarketInstrument]) async throws -> [String: PriceData]
    func subscribeLiveUpdates(for instruments: [MarketInstrument]) async throws -> AsyncStream<PriceUpdate>
}

enum InstrumentType {
    case stock(exchange: StockExchange)
    case mutualFund
    case gold
    case silver
    case cryptocurrency
    case currency(pair: CurrencyPair)
    case bond
    case commodity
}

enum StockExchange: String, CaseIterable {
    case nse = "NSE"
    case bse = "BSE"
    case nasdaq = "NASDAQ"
    case nyse = "NYSE"
}

struct RateLimits {
    let requestsPerMinute: Int
    let requestsPerHour: Int
    let requestsPerDay: Int
}
```

### 2. Indian Market Data Providers

#### NSE/BSE Integration
```swift
// Indian Stock Exchange Data Provider
class IndianStockDataProvider: MarketDataProvider {
    let providerId = "indian_stocks"
    let supportedInstruments: [InstrumentType] = [
        .stock(exchange: .nse),
        .stock(exchange: .bse)
    ]
    let updateFrequency: TimeInterval = 300 // 5 minutes during market hours
    let requiresAuthentication = false // Using free APIs initially
    let rateLimits = RateLimits(requestsPerMinute: 100, requestsPerHour: 1000, requestsPerDay: 10000)
    
    private let baseURL = "https://api.nsepython.org"
    private let session = URLSession.shared
    
    func authenticate(apiKey: String) async throws {
        // For free APIs, no authentication required
        // For premium APIs, implement token-based auth
    }
    
    func fetchPrice(for instrument: MarketInstrument) async throws -> PriceData {
        guard case .stock(let exchange) = instrument.type else {
            throw MarketDataError.unsupportedInstrument
        }
        
        let endpoint: String
        switch exchange {
        case .nse:
            endpoint = "/quote/equity?symbol=\(instrument.symbol)"
        case .bse:
            endpoint = "/quote/bse?symbol=\(instrument.symbol)"
        default:
            throw MarketDataError.unsupportedExchange
        }
        
        let url = URL(string: baseURL + endpoint)!
        let (data, _) = try await session.data(from: url)
        
        let response = try JSONDecoder().decode(NSEQuoteResponse.self, from: data)
        
        return PriceData(
            symbol: instrument.symbol,
            price: response.lastPrice,
            change: response.change,
            changePercent: response.changePercent,
            volume: response.totalTradedVolume,
            timestamp: Date(),
            marketStatus: determineMarketStatus(),
            additionalData: [
                "high": response.dayHigh,
                "low": response.dayLow,
                "open": response.open,
                "previousClose": response.previousClose,
                "marketCap": response.marketCap,
                "pe": response.peRatio
            ]
        )
    }
    
    func fetchBulkPrices(for instruments: [MarketInstrument]) async throws -> [String: PriceData] {
        // Implement bulk fetching to optimize API calls
        let chunks = instruments.chunked(into: 10) // API limit
        var allPrices: [String: PriceData] = [:]
        
        for chunk in chunks {
            let symbols = chunk.map(\.symbol).joined(separator: ",")
            let url = URL(string: "\(baseURL)/quote/bulk?symbols=\(symbols)")!
            
            let (data, _) = try await session.initialValue(from: url)
            let responses = try JSONDecoder().decode([NSEQuoteResponse].self, from: data)
            
            for response in responses {
                let priceData = PriceData(/* convert response to PriceData */)
                allPrices[response.symbol] = priceData
            }
            
            // Respect rate limits
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        }
        
        return allPrices
    }
    
    private func determineMarketStatus() -> MarketStatus {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        
        // Market closed on weekends
        guard weekday >= 2 && weekday <= 6 else {
            return .closed
        }
        
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTime = hour * 60 + minute
        
        // NSE/BSE trading hours: 9:15 AM to 3:30 PM
        let marketOpen = 9 * 60 + 15  // 9:15 AM
        let marketClose = 15 * 60 + 30 // 3:30 PM
        
        if currentTime >= marketOpen && currentTime <= marketClose {
            return .open
        } else {
            return .closed
        }
    }
}

struct NSEQuoteResponse: Codable {
    let symbol: String
    let lastPrice: Decimal
    let change: Decimal
    let changePercent: Decimal
    let dayHigh: Decimal
    let dayLow: Decimal
    let open: Decimal
    let previousClose: Decimal
    let totalTradedVolume: Int64
    let marketCap: Decimal?
    let peRatio: Decimal?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case lastPrice = "lastPrice"
        case change = "change" 
        case changePercent = "pChange"
        case dayHigh = "dayHigh"
        case dayLow = "dayLow"
        case open = "open"
        case previousClose = "previousClose"
        case totalTradedVolume = "totalTradedVolume"
        case marketCap
        case peRatio = "pe"
    }
}
```

#### Gold Price Provider
```swift
// Gold Price Data Provider
class GoldPriceProvider: MarketDataProvider {
    let providerId = "gold_prices"
    let supportedInstruments: [InstrumentType] = [.gold, .silver]
    let updateFrequency: TimeInterval = 600 // 10 minutes
    let requiresAuthentication = true
    let rateLimits = RateLimits(requestsPerMinute: 60, requestsPerHour: 1000, requestsPerDay: 5000)
    
    private var apiKey: String?
    private let baseURL = "https://api.goldapi.io/api"
    
    func authenticate(apiKey: String) async throws {
        self.apiKey = apiKey
        // Validate API key
        let testURL = URL(string: "\(baseURL)/XAU/USD")!
        var request = URLRequest(url: testURL)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MarketDataError.invalidAPIKey
        }
    }
    
    func fetchPrice(for instrument: MarketInstrument) async throws -> PriceData {
        guard let apiKey = apiKey else {
            throw MarketDataError.notAuthenticated
        }
        
        let metal: String
        switch instrument.type {
        case .gold:
            metal = "XAU"
        case .silver:
            metal = "XAG"
        default:
            throw MarketDataError.unsupportedInstrument
        }
        
        // Fetch both USD and INR prices
        let usdPrice = try await fetchMetalPrice(metal: metal, currency: "USD", apiKey: apiKey)
        let inrPrice = try await fetchMetalPrice(metal: metal, currency: "INR", apiKey: apiKey)
        
        return PriceData(
            symbol: instrument.symbol,
            price: inrPrice.price,
            change: inrPrice.change,
            changePercent: inrPrice.changePercent,
            volume: 0, // Not applicable for gold
            timestamp: Date(),
            marketStatus: .open, // Gold trades 24/7
            additionalData: [
                "usd_price": usdPrice.price,
                "usd_change": usdPrice.change,
                "high_24h": inrPrice.high24h,
                "low_24h": inrPrice.low24h,
                "price_per_gram": inrPrice.price / 31.1035, // Convert from ounce to gram
                "price_per_10_gram": (inrPrice.price / 31.1035) * 10
            ]
        )
    }
    
    private func fetchMetalPrice(metal: String, currency: String, apiKey: String) async throws -> GoldAPIResponse {
        let url = URL(string: "\(baseURL)/\(metal)/\(currency)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GoldAPIResponse.self, from: data)
    }
}

struct GoldAPIResponse: Codable {
    let price: Decimal
    let change: Decimal
    let changePercent: Decimal
    let high24h: Decimal
    let low24h: Decimal
    
    enum CodingKeys: String, CodingKey {
        case price
        case change = "ch"
        case changePercent = "chp"
        case high24h = "high_24"
        case low24h = "low_24"
    }
}
```

#### Mutual Fund Data Provider
```swift
// Mutual Fund NAV Provider
class MutualFundDataProvider: MarketDataProvider {
    let providerId = "mutual_funds"
    let supportedInstruments: [InstrumentType] = [.mutualFund]
    let updateFrequency: TimeInterval = 86400 // Daily (NAV updated once daily)
    let requiresAuthentication = false
    let rateLimits = RateLimits(requestsPerMinute: 30, requestsPerHour: 500, requestsPerDay: 2000)
    
    private let baseURL = "https://api.mfapi.in/mf"
    
    func authenticate(apiKey: String) async throws {
        // No authentication required for AMFI data
    }
    
    func fetchPrice(for instrument: MarketInstrument) async throws -> PriceData {
        guard case .mutualFund = instrument.type else {
            throw MarketDataError.unsupportedInstrument
        }
        
        let url = URL(string: "\(baseURL)/\(instrument.symbol)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(MFAPIResponse.self, from: data)
        
        guard let latest = response.data.first else {
            throw MarketDataError.noDataAvailable
        }
        
        let previousNAV = response.data.count > 1 ? response.data[1].nav : latest.nav
        let change = latest.nav - previousNAV
        let changePercent = previousNAV > 0 ? (change / previousNAV) * 100 : 0
        
        return PriceData(
            symbol: instrument.symbol,
            price: latest.nav,
            change: change,
            changePercent: changePercent,
            volume: 0, // Not applicable for MF
            timestamp: latest.date,
            marketStatus: .closed, // MF NAV is published after market close
            additionalData: [
                "scheme_name": response.meta.schemeName,
                "scheme_category": response.meta.schemeCategory,
                "scheme_type": response.meta.schemeType,
                "fund_house": response.meta.fundHouse,
                "scheme_code": response.meta.schemeCode
            ]
        )
    }
    
    func searchMutualFunds(query: String) async throws -> [MutualFundScheme] {
        let url = URL(string: "https://api.mfapi.in/mf/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let schemes = try JSONDecoder().decode([MutualFundScheme].self, from: data)
        return schemes
    }
}

struct MFAPIResponse: Codable {
    let meta: MutualFundMeta
    let data: [NAVData]
    let status: String
}

struct MutualFundMeta: Codable {
    let schemeCode: String
    let schemeName: String
    let schemeCategory: String
    let schemeType: String
    let fundHouse: String
    
    enum CodingKeys: String, CodingKey {
        case schemeCode = "scheme_code"
        case schemeName = "scheme_name"
        case schemeCategory = "scheme_category"
        case schemeType = "scheme_type"
        case fundHouse = "fund_house"
    }
}

struct NAVData: Codable {
    let date: Date
    let nav: Decimal
}

struct MutualFundScheme: Codable {
    let schemeCode: String
    let schemeName: String
    
    enum CodingKeys: String, CodingKey {
        case schemeCode = "schemeCode"
        case schemeName = "schemeName"
    }
}
```

### 3. Market Data Manager
```swift
// Centralized Market Data Management
class MarketDataManager: ObservableObject {
    @Published var priceData: [String: PriceData] = [:]
    @Published var isUpdating = false
    @Published var lastUpdate: Date?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var providers: [MarketDataProvider] = []
    private var subscriptions: Set<String> = []
    private var updateTimer: Timer?
    private var rateLimitManager = RateLimitManager()
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case rateLimited
        case error(Error)
    }
    
    init() {
        setupProviders()
        setupPeriodicUpdates()
    }
    
    private func setupProviders() {
        providers = [
            IndianStockDataProvider(),
            GoldPriceProvider(),
            MutualFundDataProvider(),
            CryptocurrencyProvider(),
            ForexProvider()
        ]
    }
    
    func authenticateProvider(_ providerId: String, apiKey: String) async throws {
        guard let provider = providers.first(where: { $0.providerId == providerId }) else {
            throw MarketDataError.providerNotFound
        }
        
        try await provider.authenticate(apiKey: apiKey)
        UserDefaults.standard.set(apiKey, forKey: "api_key_\(providerId)")
    }
    
    func subscribeToInstrument(_ instrument: MarketInstrument) {
        subscriptions.insert(instrument.symbol)
        
        // Immediately fetch current price
        Task {
            await fetchPrice(for: instrument)
        }
    }
    
    func unsubscribeFromInstrument(_ instrument: MarketInstrument) {
        subscriptions.remove(instrument.symbol)
        priceData.removeValue(forKey: instrument.symbol)
    }
    
    func fetchPrice(for instrument: MarketInstrument) async {
        guard let provider = findProvider(for: instrument.type) else {
            return
        }
        
        // Check rate limits
        guard rateLimitManager.canMakeRequest(for: provider.providerId) else {
            connectionStatus = .rateLimited
            return
        }
        
        do {
            let price = try await provider.fetchPrice(for: instrument)
            
            await MainActor.run {
                self.priceData[instrument.symbol] = price
                self.lastUpdate = Date()
                self.connectionStatus = .connected
            }
            
            rateLimitManager.recordRequest(for: provider.providerId)
            
        } catch {
            await MainActor.run {
                self.connectionStatus = .error(error)
            }
        }
    }
    
    func fetchBulkPrices(for instruments: [MarketInstrument]) async {
        isUpdating = true
        
        // Group instruments by provider
        let groupedInstruments = Dictionary(grouping: instruments) { instrument in
            findProvider(for: instrument.type)?.providerId ?? "unknown"
        }
        
        await withTaskGroup(of: Void.self) { group in
            for (providerId, instrumentsGroup) in groupedInstruments {
                guard let provider = providers.first(where: { $0.providerId == providerId }),
                      rateLimitManager.canMakeRequest(for: providerId) else {
                    continue
                }
                
                group.addTask {
                    do {
                        let prices = try await provider.fetchBulkPrices(for: instrumentsGroup)
                        
                        await MainActor.run {
                            self.priceData.merge(prices) { _, new in new }
                        }
                        
                        self.rateLimitManager.recordRequest(for: providerId)
                        
                    } catch {
                        await MainActor.run {
                            self.connectionStatus = .error(error)
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            self.isUpdating = false
            self.lastUpdate = Date()
        }
    }
    
    private func setupPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.updateSubscribedInstruments()
            }
        }
    }
    
    private func updateSubscribedInstruments() async {
        let instruments = subscriptions.compactMap { symbol in
            // Create MarketInstrument from symbol
            // This would typically involve looking up the instrument type from a database
            createInstrument(from: symbol)
        }
        
        await fetchBulkPrices(for: instruments)
    }
    
    private func findProvider(for instrumentType: InstrumentType) -> MarketDataProvider? {
        return providers.first { provider in
            provider.supportedInstruments.contains { type in
                switch (type, instrumentType) {
                case (.stock(let exchange1), .stock(let exchange2)):
                    return exchange1 == exchange2
                case (.mutualFund, .mutualFund),
                     (.gold, .gold),
                     (.silver, .silver),
                     (.cryptocurrency, .cryptocurrency):
                    return true
                default:
                    return false
                }
            }
        }
    }
}
```

### 4. Rate Limiting and Caching
```swift
// Rate Limit Management
class RateLimitManager {
    private var requestCounts: [String: RequestCounter] = [:]
    private let queue = DispatchQueue(label: "rate.limit", attributes: .concurrent)
    
    struct RequestCounter {
        var minute: (count: Int, timestamp: Date)
        var hour: (count: Int, timestamp: Date)
        var day: (count: Int, timestamp: Date)
    }
    
    func canMakeRequest(for providerId: String) -> Bool {
        return queue.sync {
            guard let provider = findProvider(providerId) else { return false }
            
            let counter = requestCounts[providerId] ?? RequestCounter(
                minute: (0, Date()),
                hour: (0, Date()),
                day: (0, Date())
            )
            
            let now = Date()
            
            // Check minute limit
            if now.timeIntervalSince(counter.minute.timestamp) < 60 {
                if counter.minute.count >= provider.rateLimits.requestsPerMinute {
                    return false
                }
            }
            
            // Check hour limit
            if now.timeIntervalSince(counter.hour.timestamp) < 3600 {
                if counter.hour.count >= provider.rateLimits.requestsPerHour {
                    return false
                }
            }
            
            // Check day limit
            if now.timeIntervalSince(counter.day.timestamp) < 86400 {
                if counter.day.count >= provider.rateLimits.requestsPerDay {
                    return false
                }
            }
            
            return true
        }
    }
    
    func recordRequest(for providerId: String) {
        queue.async(flags: .barrier) {
            let now = Date()
            var counter = self.requestCounts[providerId] ?? RequestCounter(
                minute: (0, now),
                hour: (0, now),
                day: (0, now)
            )
            
            // Reset counters if time windows have passed
            if now.timeIntervalSince(counter.minute.timestamp) >= 60 {
                counter.minute = (0, now)
            }
            if now.timeIntervalSince(counter.hour.timestamp) >= 3600 {
                counter.hour = (0, now)
            }
            if now.timeIntervalSince(counter.day.timestamp) >= 86400 {
                counter.day = (0, now)
            }
            
            // Increment counters
            counter.minute.count += 1
            counter.hour.count += 1
            counter.day.count += 1
            
            self.requestCounts[providerId] = counter
        }
    }
}

// Price Data Caching
class PriceDataCache {
    private let cache = NSCache<NSString, CachedPriceData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("MarketData")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 1000
    }
    
    func getPriceData(for symbol: String) -> PriceData? {
        // First check memory cache
        if let cached = cache.object(forKey: symbol as NSString),
           !cached.isExpired {
            return cached.priceData
        }
        
        // Then check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(symbol).json")
        guard let data = try? Data(contentsOf: fileURL),
              let cached = try? JSONDecoder().decode(CachedPriceData.self, from: data),
              !cached.isExpired else {
            return nil
        }
        
        // Store in memory cache for faster access
        cache.setObject(cached, forKey: symbol as NSString)
        return cached.priceData
    }
    
    func setPriceData(_ priceData: PriceData, for symbol: String, ttl: TimeInterval = 300) {
        let cached = CachedPriceData(priceData: priceData, expiryDate: Date().addingTimeInterval(ttl))
        
        // Store in memory cache
        cache.setObject(cached, forKey: symbol as NSString)
        
        // Store in disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(symbol).json")
        if let data = try? JSONEncoder().encode(cached) {
            try? data.write(to: fileURL)
        }
    }
    
    func clearExpiredData() {
        // Clear memory cache (NSCache handles this automatically)
        
        // Clear expired disk cache
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files {
            guard let data = try? Data(contentsOf: file),
                  let cached = try? JSONDecoder().decode(CachedPriceData.self, from: data) else {
                continue
            }
            
            if cached.isExpired {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

class CachedPriceData: NSObject, Codable {
    let priceData: PriceData
    let expiryDate: Date
    
    var isExpired: Bool {
        return Date() > expiryDate
    }
    
    init(priceData: PriceData, expiryDate: Date) {
        self.priceData = priceData
        self.expiryDate = expiryDate
    }
}
```

### 5. Configuration and User Options
```swift
// User Configuration for Market Data
struct MarketDataConfiguration: Codable {
    var enabledProviders: [String] = []
    var apiKeys: [String: String] = [:]
    var updateFrequency: UpdateFrequency = .standard
    var preferredCurrency: String = "INR"
    var enableNotifications: Bool = true
    var priceAlerts: [PriceAlert] = []
    
    enum UpdateFrequency: String, CaseIterable, Codable {
        case realtime = "Real-time"
        case frequent = "Every 5 minutes"
        case standard = "Every 15 minutes"
        case conservative = "Every hour"
        case manual = "Manual only"
        
        var interval: TimeInterval {
            switch self {
            case .realtime: return 60
            case .frequent: return 300
            case .standard: return 900
            case .conservative: return 3600
            case .manual: return .infinity
            }
        }
    }
}

struct PriceAlert: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let targetPrice: Decimal
    let condition: AlertCondition
    let isEnabled: Bool
    
    enum AlertCondition: String, CaseIterable, Codable {
        case above = "Rises above"
        case below = "Falls below"
        case changePercent = "Changes by %"
    }
}

// Configuration View
struct MarketDataSettingsView: View {
    @StateObject private var marketDataManager = MarketDataManager()
    @State private var config = MarketDataConfiguration()
    
    var body: some View {
        Form {
            Section("Data Providers") {
                ForEach(AvailableProviders.allCases, id: \.self) { provider in
                    ProviderConfigurationRow(
                        provider: provider,
                        isEnabled: config.enabledProviders.contains(provider.id),
                        apiKey: config.apiKeys[provider.id] ?? "",
                        onToggle: { enabled in
                            if enabled {
                                config.enabledProviders.append(provider.id)
                            } else {
                                config.enabledProviders.removeAll { $0 == provider.id }
                            }
                        },
                        onAPIKeyChange: { newKey in
                            config.apiKeys[provider.id] = newKey
                        }
                    )
                }
            }
            
            Section("Update Settings") {
                Picker("Update Frequency", selection: $config.updateFrequency) {
                    ForEach(MarketDataConfiguration.UpdateFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                
                Toggle("Enable Notifications", isOn: $config.enableNotifications)
            }
            
            Section("Price Alerts") {
                ForEach(config.priceAlerts) { alert in
                    PriceAlertRow(alert: alert)
                }
                .onDelete(perform: deleteAlert)
                
                Button("Add Price Alert") {
                    // Show add alert sheet
                }
            }
        }
        .navigationTitle("Market Data Settings")
        .onAppear {
            loadConfiguration()
        }
        .onChange(of: config) { newConfig in
            saveConfiguration(newConfig)
        }
    }
    
    private func deleteAlert(at offsets: IndexSet) {
        config.priceAlerts.remove(atOffsets: offsets)
    }
    
    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: "market_data_config"),
           let savedConfig = try? JSONDecoder().decode(MarketDataConfiguration.self, from: data) {
            config = savedConfig
        }
    }
    
    private func saveConfiguration(_ config: MarketDataConfiguration) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "market_data_config")
        }
    }
}

enum AvailableProviders: CaseIterable {
    case indianStocks
    case goldPrices
    case mutualFunds
    case alphavantage
    case finnhub
    case iex
    
    var id: String {
        switch self {
        case .indianStocks: return "indian_stocks"
        case .goldPrices: return "gold_prices"
        case .mutualFunds: return "mutual_funds"
        case .alphavantage: return "alphavantage"
        case .finnhub: return "finnhub"
        case .iex: return "iex"
        }
    }
    
    var name: String {
        switch self {
        case .indianStocks: return "Indian Stocks (NSE/BSE)"
        case .goldPrices: return "Gold & Silver Prices"
        case .mutualFunds: return "Indian Mutual Funds"
        case .alphavantage: return "Alpha Vantage"
        case .finnhub: return "Finnhub"
        case .iex: return "IEX Cloud"
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .indianStocks, .mutualFunds: return false
        case .goldPrices, .alphavantage, .finnhub, .iex: return true
        }
    }
    
    var description: String {
        switch self {
        case .indianStocks:
            return "Free real-time data for NSE and BSE stocks"
        case .goldPrices:
            return "Live gold and silver prices in INR and USD"
        case .mutualFunds:
            return "Daily NAV data for Indian mutual funds"
        case .alphavantage:
            return "Global stocks, forex, and crypto data"
        case .finnhub:
            return "Real-time stock prices and financial news"
        case .iex:
            return "US market data with extensive coverage"
        }
    }
}
```

This comprehensive market data integration system provides:

1. **Multi-Provider Support** - Indian markets (NSE/BSE), gold prices, mutual funds, and global markets
2. **Flexible Authentication** - Free APIs for basic data, premium APIs for advanced features
3. **Intelligent Rate Limiting** - Respects API limits and optimizes requests
4. **Comprehensive Caching** - Memory and disk caching for performance
5. **User Configuration** - Customizable update frequencies and data sources
6. **Price Alerts** - Notifications for price movements and targets
7. **Offline Support** - Cached data available when network is unavailable

The system is designed to be cost-effective for users while providing comprehensive market data coverage for the Indian financial ecosystem.