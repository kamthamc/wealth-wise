import Foundation
import SwiftData
import Combine

// MARK: - Core Service Protocols

/// Protocol for data persistence operations
@available(macOS 15.0, iOS 18.0, *)
protocol DataServiceProtocol: AnyObject, Sendable {
    
    // MARK: - Generic CRUD Operations
    
    /// Save a model to persistent storage
    /// - Parameter model: The model to save
    /// - Throws: DataServiceError if the operation fails
    func save<T: PersistentModel>(_ model: T) async throws
    
    /// Fetch models from persistent storage
    /// - Parameters:
    ///   - type: The model type to fetch
    ///   - predicate: Optional predicate for filtering
    ///   - sortBy: Optional sort descriptors
    /// - Returns: Array of matching models
    /// - Throws: DataServiceError if the operation fails
    func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>]?
    ) async throws -> [T]
    
    /// Delete a model from persistent storage
    /// - Parameter model: The model to delete
    /// - Throws: DataServiceError if the operation fails
    func delete<T: PersistentModel>(_ model: T) async throws
    
    /// Update a model in persistent storage
    /// - Parameter model: The model to update
    /// - Throws: DataServiceError if the operation fails
    func update<T: PersistentModel>(_ model: T) async throws
    
    // MARK: - Batch Operations
    
    /// Save multiple models in a batch operation
    /// - Parameter models: Array of models to save
    /// - Throws: DataServiceError if the operation fails
    func batchSave<T: PersistentModel>(_ models: [T]) async throws
    
    /// Delete multiple models in a batch operation
    /// - Parameter models: Array of models to delete
    /// - Throws: DataServiceError if the operation fails
    func batchDelete<T: PersistentModel>(_ models: [T]) async throws
    
    // MARK: - Reactive Operations
    
    /// Publisher that emits when data changes occur
    var dataChangedPublisher: AnyPublisher<DataChangeNotification, Never> { get }
    
    /// Count of models matching predicate
    /// - Parameters:
    ///   - type: The model type to count
    ///   - predicate: Optional predicate for filtering
    /// - Returns: Count of matching models
    /// - Throws: DataServiceError if the operation fails
    func count<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> Int
}

/// Protocol for security-related operations
@available(macOS 15.0, iOS 18.0, *)
protocol SecurityServiceProtocol: AnyObject, Sendable {
    
    // MARK: - Authentication
    
    /// Authenticate user using biometric or password
    /// - Returns: Authentication result
    /// - Throws: SecurityError if authentication fails
    func authenticate() async throws -> AuthenticationResult
    
    /// Check if biometric authentication is available
    /// - Returns: True if biometric authentication is available
    func isBiometricAvailable() async -> Bool
    
    /// Enable biometric authentication
    /// - Throws: SecurityError if setup fails
    func enableBiometric() async throws
    
    // MARK: - Encryption
    
    /// Encrypt data using the current encryption key
    /// - Parameter data: Data to encrypt
    /// - Returns: Encrypted data
    /// - Throws: SecurityError if encryption fails
    func encrypt(_ data: Data) throws -> Data
    
    /// Decrypt data using the current encryption key
    /// - Parameter encryptedData: Data to decrypt
    /// - Returns: Decrypted data
    /// - Throws: SecurityError if decryption fails
    func decrypt(_ encryptedData: Data) throws -> Data
    
    /// Encrypt string using the current encryption key
    /// - Parameter string: String to encrypt
    /// - Returns: Encrypted string (base64 encoded)
    /// - Throws: SecurityError if encryption fails
    func encryptString(_ string: String) throws -> String
    
    /// Decrypt string using the current encryption key
    /// - Parameter encryptedString: Encrypted string (base64 encoded)
    /// - Returns: Decrypted string
    /// - Throws: SecurityError if decryption fails
    func decryptString(_ encryptedString: String) throws -> String
    
    // MARK: - Key Management
    
    /// Rotate encryption keys
    /// - Throws: SecurityError if key rotation fails
    func rotateKeys() async throws
    
    /// Store data securely in keychain
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Key identifier
    /// - Throws: SecurityError if storage fails
    func storeSecurely(_ data: Data, forKey key: String) throws
    
    /// Retrieve data securely from keychain
    /// - Parameter key: Key identifier
    /// - Returns: Retrieved data or nil if not found
    /// - Throws: SecurityError if retrieval fails
    func retrieveSecurely(forKey key: String) throws -> Data?
}

/// Protocol for market data operations
@available(macOS 15.0, iOS 18.0, *)
protocol MarketDataServiceProtocol: AnyObject, Sendable {
    
    // MARK: - Price Data
    
    /// Get current price for a symbol
    /// - Parameter symbol: Stock/asset symbol
    /// - Returns: Current price or nil if not available
    func getCurrentPrice(for symbol: String) async throws -> Price?
    
    /// Get historical prices for a symbol
    /// - Parameters:
    ///   - symbol: Stock/asset symbol
    ///   - range: Date range for historical data
    /// - Returns: Array of historical prices
    func getHistoricalPrices(for symbol: String, range: DateRange) async throws -> [Price]
    
    /// Search for symbols/securities
    /// - Parameter query: Search query
    /// - Returns: Array of matching securities
    func searchSymbols(_ query: String) async throws -> [SecurityInfo]
    
    // MARK: - Market Information
    
    /// Get market status (open/closed)
    /// - Parameter exchange: Exchange identifier
    /// - Returns: Market status
    func getMarketStatus(for exchange: String) async throws -> MarketStatus
    
    /// Get exchange rate between currencies
    /// - Parameters:
    ///   - from: Source currency
    ///   - to: Target currency
    /// - Returns: Exchange rate
    func getExchangeRate(from: String, to: String) async throws -> ExchangeRate
    
    // MARK: - Reactive Data
    
    /// Publisher for real-time price updates
    /// - Parameter symbols: Array of symbols to monitor
    /// - Returns: Publisher emitting price updates
    func priceUpdates(for symbols: [String]) -> AnyPublisher<PriceUpdate, Never>
}

/// Protocol for calculation services
@available(macOS 15.0, iOS 18.0, *)
protocol CalculationServiceProtocol: AnyObject, Sendable {
    
    // MARK: - Portfolio Calculations
    
    /// Calculate total portfolio value
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Portfolio valuation
    func calculatePortfolioValue(_ portfolioId: UUID) async throws -> PortfolioValuation
    
    /// Calculate asset allocation
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Asset allocation breakdown
    func calculateAssetAllocation(_ portfolioId: UUID) async throws -> AssetAllocation
    
    /// Calculate performance metrics
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - timeframe: Time period for calculation
    /// - Returns: Performance metrics
    func calculatePerformance(_ portfolioId: UUID, timeframe: TimeFrame) async throws -> PerformanceMetrics
    
    // MARK: - Tax Calculations
    
    /// Calculate capital gains tax
    /// - Parameters:
    ///   - transactions: Array of transactions
    ///   - financialYear: Tax year
    /// - Returns: Tax calculation result
    func calculateCapitalGainsTax(_ transactions: [Transaction], financialYear: String) async throws -> TaxCalculation
    
    /// Calculate dividend tax
    /// - Parameters:
    ///   - dividends: Array of dividend transactions
    ///   - financialYear: Tax year
    /// - Returns: Dividend tax calculation
    func calculateDividendTax(_ dividends: [Transaction], financialYear: String) async throws -> TaxCalculation
    
    // MARK: - Risk Calculations
    
    /// Calculate portfolio risk metrics
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Risk assessment
    func calculateRiskMetrics(_ portfolioId: UUID) async throws -> RiskAssessment
    
    /// Calculate Value at Risk (VaR)
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - confidence: Confidence level (e.g., 0.95)
    ///   - timeHorizon: Time horizon in days
    /// - Returns: VaR calculation
    func calculateVaR(_ portfolioId: UUID, confidence: Double, timeHorizon: Int) async throws -> VaRResult
}

/// Protocol for notification services
@available(macOS 15.0, iOS 18.0, *)
protocol NotificationServiceProtocol: AnyObject, Sendable {
    
    // MARK: - Local Notifications
    
    /// Schedule a local notification
    /// - Parameter notification: Notification to schedule
    /// - Throws: NotificationError if scheduling fails
    func scheduleNotification(_ notification: LocalNotification) async throws
    
    /// Cancel scheduled notification
    /// - Parameter identifier: Notification identifier
    func cancelNotification(identifier: String) async
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() async
    
    // MARK: - Alert Management
    
    /// Create price alert
    /// - Parameters:
    ///   - assetId: Asset identifier
    ///   - targetPrice: Target price for alert
    ///   - condition: Alert condition (above/below)
    /// - Throws: NotificationError if creation fails
    func createPriceAlert(assetId: UUID, targetPrice: Decimal, condition: AlertCondition) async throws
    
    /// Create portfolio alert
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - targetValue: Target value for alert
    ///   - condition: Alert condition
    /// - Throws: NotificationError if creation fails
    func createPortfolioAlert(portfolioId: UUID, targetValue: Decimal, condition: AlertCondition) async throws
    
    // MARK: - Reactive Notifications
    
    /// Publisher for notification events
    var notificationPublisher: AnyPublisher<NotificationEvent, Never> { get }
}

// MARK: - Supporting Types

struct DataChangeNotification {
    let entityType: String
    let changeType: ChangeType
    let entityId: UUID?
    let timestamp: Date
    
    enum ChangeType {
        case insert, update, delete
    }
}

struct AuthenticationResult {
    let isSuccessful: Bool
    let method: AuthenticationMethod
    let error: SecurityError?
    
    enum AuthenticationMethod {
        case biometric, password, none
    }
}

struct Price {
    let symbol: String
    let value: Decimal
    let currency: String
    let timestamp: Date
    let source: String
}

struct SecurityInfo {
    let symbol: String
    let name: String
    let exchange: String
    let type: SecurityType
    let currency: String
    
    enum SecurityType {
        case stock, etf, mutualFund, bond, commodity
    }
}

struct DateRange {
    let start: Date
    let end: Date
}

struct MarketStatus {
    let exchange: String
    let isOpen: Bool
    let nextOpen: Date?
    let nextClose: Date?
}

struct ExchangeRate {
    let from: String
    let to: String
    let rate: Decimal
    let timestamp: Date
}

struct PriceUpdate {
    let symbol: String
    let price: Decimal
    let change: Decimal
    let changePercent: Decimal
    let timestamp: Date
}

struct PortfolioValuation {
    let portfolioId: UUID
    let totalValue: Decimal
    let currency: String
    let lastUpdated: Date
    let holdings: [HoldingValuation]
}

struct HoldingValuation {
    let assetId: UUID
    let symbol: String
    let quantity: Decimal
    let currentPrice: Decimal
    let marketValue: Decimal
    let unrealizedGainLoss: Decimal
}

struct AssetAllocation {
    let portfolioId: UUID
    let allocations: [AllocationItem]
    let lastCalculated: Date
}

struct AllocationItem {
    let category: String
    let percentage: Double
    let value: Decimal
}

struct PerformanceMetrics {
    let portfolioId: UUID
    let timeframe: TimeFrame
    let totalReturn: Double
    let annualizedReturn: Double
    let volatility: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    let calculatedAt: Date
}

struct TimeFrame {
    let period: Period
    let customRange: DateRange?
    
    enum Period {
        case oneWeek, oneMonth, threeMonths, sixMonths, oneYear, threeYears, fiveYears, custom
    }
}

struct TaxCalculation {
    let financialYear: String
    let shortTermGains: Decimal
    let longTermGains: Decimal
    let taxableAmount: Decimal
    let taxOwed: Decimal
    let calculatedAt: Date
}

struct RiskAssessment {
    let portfolioId: UUID
    let riskScore: Double
    let riskLevel: RiskLevel
    let diversificationScore: Double
    let recommendations: [String]
    
    enum RiskLevel {
        case low, moderate, high, extreme
    }
}

struct VaRResult {
    let portfolioId: UUID
    let confidence: Double
    let timeHorizon: Int
    let value: Decimal
    let percentage: Double
    let calculatedAt: Date
}

struct LocalNotification {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date
    let userInfo: [String: Any]?
}

enum AlertCondition {
    case above(Decimal)
    case below(Decimal)
    case percentChange(Double)
}

struct NotificationEvent {
    let type: EventType
    let data: [String: Any]
    let timestamp: Date
    
    enum EventType {
        case priceAlert, portfolioAlert, systemNotification
    }
}

// MARK: - Error Types

enum DataServiceError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case updateFailed(String)
    case invalidModel
    case contextNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message): return "Save failed: \(message)"
        case .fetchFailed(let message): return "Fetch failed: \(message)"
        case .deleteFailed(let message): return "Delete failed: \(message)"
        case .updateFailed(let message): return "Update failed: \(message)"
        case .invalidModel: return "Invalid model provided"
        case .contextNotAvailable: return "Model context not available"
        }
    }
}

enum SecurityError: LocalizedError {
    case authenticationFailed(String)
    case biometricNotAvailable
    case encryptionFailed(String)
    case decryptionFailed(String)
    case keyGenerationFailed
    case keychainError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message): return "Authentication failed: \(message)"
        case .biometricNotAvailable: return "Biometric authentication not available"
        case .encryptionFailed(let message): return "Encryption failed: \(message)"
        case .decryptionFailed(let message): return "Decryption failed: \(message)"
        case .keyGenerationFailed: return "Key generation failed"
        case .keychainError(let message): return "Keychain error: \(message)"
        }
    }
}

enum MarketDataError: LocalizedError {
    case networkError(String)
    case apiError(String)
    case invalidSymbol(String)
    case noDataAvailable
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .apiError(let message): return "API error: \(message)"
        case .invalidSymbol(let symbol): return "Invalid symbol: \(symbol)"
        case .noDataAvailable: return "No data available"
        case .rateLimited: return "Rate limited by data provider"
        }
    }
}

enum NotificationError: LocalizedError {
    case permissionDenied
    case schedulingFailed(String)
    case invalidNotification
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Notification permission denied"
        case .schedulingFailed(let message): return "Notification scheduling failed: \(message)"
        case .invalidNotification: return "Invalid notification configuration"
        }
    }
}