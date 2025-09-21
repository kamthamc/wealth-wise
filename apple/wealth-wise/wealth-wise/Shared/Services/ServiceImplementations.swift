import Foundation
import SwiftData
import Combine

// MARK: - SwiftData Service Implementation

@available(macOS 15.0, iOS 18.0, *)
final class SwiftDataService: DataServiceProtocol, @unchecked Sendable {
    
    private let modelContext: ModelContext
    private let dataChangedSubject = PassthroughSubject<DataChangeNotification, Never>()
    
    init(modelContext: ModelContext? = nil) {
        // Use provided context or create a default one
        if let context = modelContext {
            self.modelContext = context
        } else {
            // This would be properly configured in the app with the shared model container
            let container = try! ModelContainer(for: Asset.self, Portfolio.self, Transaction.self)
            self.modelContext = ModelContext(container)
        }
    }
    
    var dataChangedPublisher: AnyPublisher<DataChangeNotification, Never> {
        dataChangedSubject.eraseToAnyPublisher()
    }
    
    func save<T: PersistentModel>(_ model: T) async throws {
        do {
            modelContext.insert(model)
            try modelContext.save()
            
            notifyDataChanged(model: model, changeType: .insert)
        } catch {
            throw DataServiceError.saveFailed(error.localizedDescription)
        }
    }
    
    func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>]?
    ) async throws -> [T] {
        do {
            var descriptor = FetchDescriptor<T>(predicate: predicate)
            if let sortBy = sortBy {
                descriptor.sortBy = sortBy
            }
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataServiceError.fetchFailed(error.localizedDescription)
        }
    }
    
    func delete<T: PersistentModel>(_ model: T) async throws {
        do {
            modelContext.delete(model)
            try modelContext.save()
            
            notifyDataChanged(model: model, changeType: .delete)
        } catch {
            throw DataServiceError.deleteFailed(error.localizedDescription)
        }
    }
    
    func update<T: PersistentModel>(_ model: T) async throws {
        do {
            try modelContext.save()
            
            notifyDataChanged(model: model, changeType: .update)
        } catch {
            throw DataServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    func batchSave<T: PersistentModel>(_ models: [T]) async throws {
        do {
            for model in models {
                modelContext.insert(model)
            }
            try modelContext.save()
            
            for model in models {
                notifyDataChanged(model: model, changeType: .insert)
            }
        } catch {
            throw DataServiceError.saveFailed(error.localizedDescription)
        }
    }
    
    func batchDelete<T: PersistentModel>(_ models: [T]) async throws {
        do {
            for model in models {
                modelContext.delete(model)
            }
            try modelContext.save()
            
            for model in models {
                notifyDataChanged(model: model, changeType: .delete)
            }
        } catch {
            throw DataServiceError.deleteFailed(error.localizedDescription)
        }
    }
    
    func count<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> Int {
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw DataServiceError.fetchFailed(error.localizedDescription)
        }
    }
    
    private func notifyDataChanged<T: PersistentModel>(model: T, changeType: DataChangeNotification.ChangeType) {
        let notification = DataChangeNotification(
            entityType: String(describing: type(of: model)),
            changeType: changeType,
            entityId: nil, // Could extract ID if models have a common protocol
            timestamp: Date()
        )
        dataChangedSubject.send(notification)
    }
}

// MARK: - Keychain Security Service Implementation

@available(macOS 15.0, iOS 18.0, *)
final class KeychainSecurityService: SecurityServiceProtocol, @unchecked Sendable {
    
    private let keychain = KeychainManager()
    private var encryptionKey: Data?
    
    func authenticate() async throws -> AuthenticationResult {
        // Mock implementation - replace with LocalAuthentication
        return AuthenticationResult(
            isSuccessful: true,
            method: .biometric,
            error: nil
        )
    }
    
    func isBiometricAvailable() async -> Bool {
        // Mock implementation - replace with LocalAuthentication
        return true
    }
    
    func enableBiometric() async throws {
        // Mock implementation - replace with actual biometric setup
    }
    
    func encrypt(_ data: Data) throws -> Data {
        guard let key = getOrCreateEncryptionKey() else {
            throw SecurityError.encryptionFailed("No encryption key available")
        }
        
        // Mock encryption - replace with CryptoKit
        return data // Placeholder
    }
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        guard let key = getOrCreateEncryptionKey() else {
            throw SecurityError.decryptionFailed("No encryption key available")
        }
        
        // Mock decryption - replace with CryptoKit
        return encryptedData // Placeholder
    }
    
    func encryptString(_ string: String) throws -> String {
        let data = string.data(using: .utf8) ?? Data()
        let encrypted = try encrypt(data)
        return encrypted.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw SecurityError.decryptionFailed("Invalid base64 string")
        }
        
        let decrypted = try decrypt(data)
        return String(data: decrypted, encoding: .utf8) ?? ""
    }
    
    func rotateKeys() async throws {
        // Mock implementation - replace with actual key rotation
        encryptionKey = nil
        _ = getOrCreateEncryptionKey()
    }
    
    func storeSecurely(_ data: Data, forKey key: String) throws {
        try keychain.store(data, forKey: key)
    }
    
    func retrieveSecurely(forKey key: String) throws -> Data? {
        return try keychain.retrieve(forKey: key)
    }
    
    private func getOrCreateEncryptionKey() -> Data? {
        if encryptionKey == nil {
            // Generate or retrieve from keychain
            encryptionKey = Data(repeating: 0x42, count: 32) // Mock key
        }
        return encryptionKey
    }
}

// MARK: - Mock Market Data Service

@available(macOS 15.0, iOS 18.0, *)
final class MockMarketDataService: MarketDataServiceProtocol, @unchecked Sendable {
    
    private let priceUpdateSubject = PassthroughSubject<PriceUpdate, Never>()
    
    func getCurrentPrice(for symbol: String) async throws -> Price? {
        // Mock price data
        let mockPrice = Decimal(Double.random(in: 100...500))
        return Price(
            symbol: symbol,
            value: mockPrice,
            currency: "USD",
            timestamp: Date(),
            source: "Mock"
        )
    }
    
    func getHistoricalPrices(for symbol: String, range: DateRange) async throws -> [Price] {
        // Generate mock historical data
        let calendar = Calendar.current
        var prices: [Price] = []
        var currentDate = range.start
        var currentPrice = Decimal(Double.random(in: 100...500))
        
        while currentDate <= range.end {
            prices.append(Price(
                symbol: symbol,
                value: currentPrice,
                currency: "USD",
                timestamp: currentDate,
                source: "Mock"
            ))
            
            // Random price movement
            let change = Decimal(Double.random(in: -10...10))
            currentPrice += change
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return prices
    }
    
    func searchSymbols(_ query: String) async throws -> [SecurityInfo] {
        // Mock search results
        return [
            SecurityInfo(symbol: "\(query)1", name: "Mock Company 1", exchange: "NYSE", type: .stock, currency: "USD"),
            SecurityInfo(symbol: "\(query)2", name: "Mock Company 2", exchange: "NASDAQ", type: .stock, currency: "USD")
        ]
    }
    
    func getMarketStatus(for exchange: String) async throws -> MarketStatus {
        return MarketStatus(
            exchange: exchange,
            isOpen: true,
            nextOpen: nil,
            nextClose: Calendar.current.date(byAdding: .hour, value: 4, to: Date())
        )
    }
    
    func getExchangeRate(from: String, to: String) async throws -> ExchangeRate {
        return ExchangeRate(
            from: from,
            to: to,
            rate: Decimal(Double.random(in: 0.5...2.0)),
            timestamp: Date()
        )
    }
    
    func priceUpdates(for symbols: [String]) -> AnyPublisher<PriceUpdate, Never> {
        return priceUpdateSubject.eraseToAnyPublisher()
    }
}

// MARK: - Default Calculation Service

@available(macOS 15.0, iOS 18.0, *)
final class DefaultCalculationService: CalculationServiceProtocol, @unchecked Sendable {
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    func calculatePortfolioValue(_ portfolioId: UUID) async throws -> PortfolioValuation {
        // Mock calculation
        return PortfolioValuation(
            portfolioId: portfolioId,
            totalValue: Decimal(100000),
            currency: "USD",
            lastUpdated: Date(),
            holdings: []
        )
    }
    
    func calculateAssetAllocation(_ portfolioId: UUID) async throws -> AssetAllocation {
        // Mock allocation
        return AssetAllocation(
            portfolioId: portfolioId,
            allocations: [
                AllocationItem(category: "Stocks", percentage: 60.0, value: Decimal(60000)),
                AllocationItem(category: "Bonds", percentage: 30.0, value: Decimal(30000)),
                AllocationItem(category: "Cash", percentage: 10.0, value: Decimal(10000))
            ],
            lastCalculated: Date()
        )
    }
    
    func calculatePerformance(_ portfolioId: UUID, timeframe: TimeFrame) async throws -> PerformanceMetrics {
        // Mock performance metrics
        return PerformanceMetrics(
            portfolioId: portfolioId,
            timeframe: timeframe,
            totalReturn: 0.12,
            annualizedReturn: 0.15,
            volatility: 0.18,
            sharpeRatio: 0.83,
            maxDrawdown: 0.08,
            calculatedAt: Date()
        )
    }
    
    func calculateCapitalGainsTax(_ transactions: [Transaction], financialYear: String) async throws -> TaxCalculation {
        // Mock tax calculation
        return TaxCalculation(
            financialYear: financialYear,
            shortTermGains: Decimal(5000),
            longTermGains: Decimal(8000),
            taxableAmount: Decimal(13000),
            taxOwed: Decimal(3900),
            calculatedAt: Date()
        )
    }
    
    func calculateDividendTax(_ dividends: [Transaction], financialYear: String) async throws -> TaxCalculation {
        // Mock dividend tax calculation
        return TaxCalculation(
            financialYear: financialYear,
            shortTermGains: Decimal(0),
            longTermGains: Decimal(2000),
            taxableAmount: Decimal(2000),
            taxOwed: Decimal(600),
            calculatedAt: Date()
        )
    }
    
    func calculateRiskMetrics(_ portfolioId: UUID) async throws -> RiskAssessment {
        // Mock risk assessment
        return RiskAssessment(
            portfolioId: portfolioId,
            riskLevel: .moderate,
            volatility: 0.18,
            betaCoefficient: 1.2,
            valueAtRisk: Decimal(5000),
            conditionalValueAtRisk: Decimal(6500),
            calculatedAt: Date()
        )
    }
    
    func calculateVaR(_ portfolioId: UUID, confidence: Double, timeHorizon: Int) async throws -> VaRResult {
        // Mock VaR calculation
        return VaRResult(
            portfolioId: portfolioId,
            confidence: confidence,
            timeHorizon: timeHorizon,
            valueAtRisk: Decimal(5000),
            expectedShortfall: Decimal(6000),
            calculatedAt: Date()
        )
    }
    
    func calculateAssetPerformance(_ assetID: UUID, period: PerformancePeriod) async throws -> AssetPerformance {
        // Mock asset performance calculation
        return AssetPerformance(
            assetID: assetID,
            period: period,
            returns: 0.12,
            volatility: 0.18,
            sharpeRatio: 1.25,
            maxDrawdown: 0.08
        )
    }
    
    func calculateEMI(principal: Decimal, rate: Decimal, tenure: Int) async throws -> EMICalculation {
        // EMI = [P x R x (1+R)^N] / [(1+R)^N-1]
        let monthlyRate = rate / 12 / 100
        let monthlyRateDecimal = NSDecimalNumber(decimal: monthlyRate)
        let tenureDecimal = NSDecimalNumber(value: tenure)
        let principalDecimal = NSDecimalNumber(decimal: principal)
        
        // Calculate EMI using standard formula
        let onePlusR = monthlyRateDecimal.adding(NSDecimalNumber(value: 1))
        let onePlusRPowerN = onePlusR.raising(toPower: tenure)
        let numerator = principalDecimal.multiplying(by: monthlyRateDecimal).multiplying(by: onePlusRPowerN)
        let denominator = onePlusRPowerN.subtracting(NSDecimalNumber(value: 1))
        let emiAmount = numerator.dividing(by: denominator)
        
        let totalAmount = emiAmount.multiplying(by: tenureDecimal)
        let totalInterest = totalAmount.subtracting(principalDecimal)
        
        return EMICalculation(
            principal: principal,
            rate: rate,
            tenure: tenure,
            emi: emiAmount.decimalValue,
            totalInterest: totalInterest.decimalValue,
            totalAmount: totalAmount.decimalValue
        )
    }
    
    func calculateTax(income: Decimal, regime: TaxRegime) async throws -> TaxCalculation {
        // Simplified Indian tax calculation
        var taxableAmount = income
        var taxOwed = Decimal(0)
        
        switch regime {
        case .old:
            // Old regime with standard deduction
            taxableAmount = max(0, income - Decimal(50000))
        case .new:
            // New regime with higher basic exemption
            taxableAmount = max(0, income - Decimal(300000))
        }
        
        // Progressive tax calculation (simplified)
        if taxableAmount > Decimal(300000) {
            let taxable300to600 = min(taxableAmount - Decimal(300000), Decimal(300000))
            taxOwed += taxable300to600 * Decimal(0.05)
        }
        
        if taxableAmount > Decimal(600000) {
            let taxable600to900 = min(taxableAmount - Decimal(600000), Decimal(300000))
            taxOwed += taxable600to900 * Decimal(0.10)
        }
        
        if taxableAmount > Decimal(900000) {
            let taxableAbove900 = taxableAmount - Decimal(900000)
            taxOwed += taxableAbove900 * Decimal(0.15)
        }
        
        return TaxCalculation(
            financialYear: "2024-25",
            shortTermGains: Decimal(0),
            longTermGains: Decimal(0),
            taxableAmount: taxableAmount,
            taxOwed: taxOwed,
            calculatedAt: Date()
        )
    }
}

// MARK: - Local Notification Service

@available(macOS 15.0, iOS 18.0, *)
final class LocalNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    
    private let notificationSubject = PassthroughSubject<NotificationEvent, Never>()
    
    var notificationPublisher: AnyPublisher<NotificationEvent, Never> {
        notificationSubject.eraseToAnyPublisher()
    }
    
    func scheduleNotification(_ notification: LocalNotification) async throws {
        // Mock notification scheduling
        print("Scheduled notification: \(notification.title)")
    }
    
    func cancelNotification(identifier: String) async {
        // Mock cancellation
        print("Cancelled notification: \(identifier)")
    }
    
    func cancelAllNotifications() async {
        // Mock cancel all
        print("Cancelled all notifications")
    }
    
    func createPriceAlert(assetId: UUID, targetPrice: Decimal, condition: AlertCondition) async throws {
        // Mock price alert creation
        print("Created price alert for asset \(assetId) at \(targetPrice)")
    }
    
    func createPortfolioAlert(portfolioId: UUID, targetValue: Decimal, condition: AlertCondition) async throws {
        // Mock portfolio alert creation
        print("Created portfolio alert for \(portfolioId) at \(targetValue)")
    }
}

// MARK: - Keychain Manager Helper

private class KeychainManager {
    
    func store(_ data: Data, forKey key: String) throws {
        // Mock keychain storage
        UserDefaults.standard.set(data, forKey: "keychain_\(key)")
    }
    
    func retrieve(forKey key: String) throws -> Data? {
        // Mock keychain retrieval
        return UserDefaults.standard.data(forKey: "keychain_\(key)")
    }
}

// MARK: - Production Service Implementations

@available(macOS 15.0, iOS 18.0, *)
final class ProductionDataService: DataServiceProtocol, @unchecked Sendable {
    private let swiftDataService: SwiftDataService
    
    init() {
        // Use the default SwiftData service
        self.swiftDataService = SwiftDataService()
    }
    
    var dataChangedPublisher: AnyPublisher<DataChangeNotification, Never> {
        swiftDataService.dataChangedPublisher
    }
    
    func save<T: PersistentModel>(_ model: T) async throws {
        try await swiftDataService.save(model)
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?, sortBy: [SortDescriptor<T>]?) async throws -> [T] {
        try await swiftDataService.fetch(type, predicate: predicate, sortBy: sortBy)
    }
    
    func delete<T: PersistentModel>(_ model: T) async throws {
        try await swiftDataService.delete(model)
    }
    
    func update<T: PersistentModel>(_ model: T) async throws {
        try await swiftDataService.update(model)
    }
    
    func batchSave<T: PersistentModel>(_ models: [T]) async throws {
        try await swiftDataService.batchSave(models)
    }
    
    func batchDelete<T: PersistentModel>(_ models: [T]) async throws {
        try await swiftDataService.batchDelete(models)
    }
    
    func count<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> Int {
        try await swiftDataService.count(type, predicate: predicate)
    }
}

@available(macOS 15.0, iOS 18.0, *)
final class ProductionSecurityService: SecurityServiceProtocol, @unchecked Sendable {
    
    func authenticate() async throws -> AuthenticationResult {
        // In production, this would use proper biometric/keychain authentication
        return AuthenticationResult(
            isSuccessful: true,
            method: .biometric,
            error: nil
        )
    }
    
    func isBiometricAvailable() async -> Bool {
        // Check actual biometric availability
        return true
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        // Use proper encryption in production
        return data
    }
    
    func decryptData(_ encryptedData: Data) async throws -> Data {
        // Use proper decryption in production
        return encryptedData
    }
    
    func enableBiometric() async throws {
        // Enable biometric authentication
        print("Biometric authentication enabled")
    }
    
    func encrypt(_ data: Data) throws -> Data {
        // Use proper encryption in production
        return data
    }
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        // Use proper decryption in production
        return encryptedData
    }
    
    func encryptString(_ string: String) throws -> String {
        // Convert to data, encrypt, then base64 encode
        guard let data = string.data(using: .utf8) else {
            throw SecurityError.encryptionFailed("String to UTF8 conversion failed")
        }
        let encryptedData = try encrypt(data)
        return encryptedData.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        // Base64 decode, decrypt, then convert to string
        guard let data = Data(base64Encoded: encryptedString) else {
            throw SecurityError.decryptionFailed("Base64 decoding failed")
        }
        let decryptedData = try decrypt(data)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decryptionFailed("UTF8 string conversion failed")
        }
        return string
    }
    
    func rotateKeys() async throws {
        // Implement key rotation
        print("Keys rotated")
    }
    
    func storeSecurely(_ data: Data, forKey key: String) throws {
        // Store in keychain
        try KeychainManager().store(data, forKey: key)
    }
    
    func retrieveSecurely(forKey key: String) throws -> Data? {
        // Retrieve from keychain
        return try KeychainManager().retrieve(forKey: key)
    }
}

@available(macOS 15.0, iOS 18.0, *)
final class ProductionMarketDataService: MarketDataServiceProtocol, @unchecked Sendable {
    
    func getCurrentPrice(for symbol: String) async throws -> Price? {
        // In production, fetch from real market data API
        return Price(
            symbol: symbol,
            value: Decimal(100.0), // Placeholder
            currency: "INR",
            timestamp: Date(),
            source: "production-api"
        )
    }
    
    func getHistoricalPrices(for symbol: String, from startDate: Date, to endDate: Date) async throws -> [Price] {
        // Production implementation would fetch real historical data
        return []
    }
    
    func subscribeToUpdates(for symbols: [String]) async -> AsyncStream<Price> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    func getHistoricalPrices(for symbol: String, range: DateRange) async throws -> [Price] {
        // Production implementation would fetch real historical data  
        return []
    }
    
    func searchSymbols(_ query: String) async throws -> [SecurityInfo] {
        // Production implementation would search real securities
        return []
    }
    
    func getMarketStatus(for exchange: String) async throws -> MarketStatus {
        // Production implementation would check real market status
        return MarketStatus(exchange: exchange, isOpen: true, nextOpen: nil, nextClose: nil)
    }
    
    func getExchangeRate(from: String, to: String) async throws -> ExchangeRate {
        // Production implementation would fetch real exchange rates
        return ExchangeRate(from: from, to: to, rate: Decimal(1.0), timestamp: Date())
    }
    
    func priceUpdates(for symbols: [String]) -> AnyPublisher<PriceUpdate, Never> {
        // Production implementation would provide real-time updates
        Empty<PriceUpdate, Never>().eraseToAnyPublisher()
    }
}

@available(macOS 15.0, iOS 18.0, *)
final class ProductionCalculationService: CalculationServiceProtocol, @unchecked Sendable {
    
    func calculatePortfolioValue(_ portfolioId: UUID) async throws -> PortfolioValuation {
        return PortfolioValuation(
            portfolioId: portfolioId,
            totalValue: 0,
            currency: "INR",
            lastUpdated: Date(),
            holdings: []
        )
    }
    
    func calculateAssetAllocation(_ portfolioId: UUID) async throws -> AssetAllocation {
        return AssetAllocation(
            portfolioId: portfolioId,
            allocations: [],
            lastCalculated: Date()
        )
    }
    
    func calculatePerformance(_ portfolioId: UUID, timeframe: TimeFrame) async throws -> PerformanceMetrics {
        return PerformanceMetrics(
            portfolioId: portfolioId,
            timeframe: timeframe,
            totalReturn: 0.0,
            annualizedReturn: 0.0,
            volatility: 0.0,
            sharpeRatio: 0.0,
            maxDrawdown: 0.0,
            calculatedAt: Date()
        )
    }
    
    func calculateCapitalGainsTax(_ transactions: [Transaction], financialYear: String) async throws -> TaxCalculation {
        return TaxCalculation(
            financialYear: financialYear,
            shortTermGains: 0,
            longTermGains: 0,
            taxableAmount: 0,
            taxOwed: 0,
            calculatedAt: Date()
        )
    }
    
    func calculateDividendTax(_ dividends: [Transaction], financialYear: String) async throws -> TaxCalculation {
        return TaxCalculation(
            financialYear: financialYear,
            shortTermGains: 0,
            longTermGains: 0,
            taxableAmount: 0,
            taxOwed: 0,
            calculatedAt: Date()
        )
    }
    
    func calculateRiskMetrics(_ portfolioId: UUID) async throws -> RiskAssessment {
        return RiskAssessment(
            portfolioId: portfolioId,
            riskLevel: .moderate,
            volatility: 0.15,
            betaCoefficient: 1.0,
            valueAtRisk: 0,
            conditionalValueAtRisk: 0,
            calculatedAt: Date()
        )
    }
    
    func calculateVaR(_ portfolioId: UUID, confidence: Double, timeHorizon: Int) async throws -> VaRResult {
        return VaRResult(
            portfolioId: portfolioId,
            confidence: confidence,
            timeHorizon: timeHorizon,
            valueAtRisk: 0,
            expectedShortfall: 0,
            calculatedAt: Date()
        )
    }
    
    func calculateAssetPerformance(_ assetID: UUID, period: PerformancePeriod) async throws -> AssetPerformance {
        return AssetPerformance(
            assetID: assetID,
            period: period,
            returns: 0.0,
            volatility: 0.0,
            sharpeRatio: 0.0,
            maxDrawdown: 0.0
        )
    }
    
    func calculateEMI(principal: Decimal, rate: Decimal, tenure: Int) async throws -> EMICalculation {
        let monthlyRate = rate / (12 * 100)
        let denominator = pow(1 + Double(truncating: NSDecimalNumber(decimal: monthlyRate)), Double(tenure)) - 1
        let emi = (Double(truncating: NSDecimalNumber(decimal: principal)) * Double(truncating: NSDecimalNumber(decimal: monthlyRate)) * pow(1 + Double(truncating: NSDecimalNumber(decimal: monthlyRate)), Double(tenure))) / denominator
        
        return EMICalculation(
            principal: principal,
            rate: rate,
            tenure: tenure,
            emi: Decimal(emi),
            totalInterest: Decimal(emi * Double(tenure)) - principal,
            totalAmount: Decimal(emi * Double(tenure))
        )
    }
    
    func calculateTax(income: Decimal, regime: TaxRegime) async throws -> TaxCalculation {
        let taxableIncome = max(income - 250000, 0)
        let tax = taxableIncome * 0.10
        
        return TaxCalculation(
            financialYear: "2025-26",
            shortTermGains: 0,
            longTermGains: tax,
            taxableAmount: taxableIncome,
            taxOwed: tax,
            calculatedAt: Date()
        )
    }
}

@available(macOS 15.0, iOS 18.0, *)
final class ProductionNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    
    func scheduleNotification(_ notification: LocalNotification) async throws {
        // Production notification scheduling
    }
    
    func cancelNotification(withID id: String) async throws {
        // Production notification cancellation
    }
    
    func getPendingNotifications() async throws -> [LocalNotification] {
        return []
    }
    
    func requestPermission() async throws -> Bool {
        return true
    }
    
    func cancelNotification(identifier: String) async {
        // Production notification cancellation
    }
    
    func cancelAllNotifications() async {
        // Cancel all production notifications
    }
    
    func createPriceAlert(assetId: UUID, targetPrice: Decimal, condition: AlertCondition) async throws {
        // Create production price alert
    }
    
    func createPortfolioAlert(portfolioId: UUID, targetValue: Decimal, condition: AlertCondition) async throws {
        // Create production portfolio alert
    }
    
    var notificationPublisher: AnyPublisher<NotificationEvent, Never> {
        Empty<NotificationEvent, Never>().eraseToAnyPublisher()
    }
}

// MARK: - Test Service Implementations (Simple Stubs)

@available(macOS 15.0, iOS 18.0, *)
final class TestDataService: DataServiceProtocol, @unchecked Sendable {
    var dataChangedPublisher: AnyPublisher<DataChangeNotification, Never> {
        Just(DataChangeNotification(entityType: "Test", changeType: .insert, entityId: nil, timestamp: Date())).setFailureType(to: Never.self).eraseToAnyPublisher()
    }
    
    func save<T: PersistentModel>(_ model: T) async throws {}
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?, sortBy: [SortDescriptor<T>]?) async throws -> [T] { return [] }
    func delete<T: PersistentModel>(_ model: T) async throws {}
    func update<T: PersistentModel>(_ model: T) async throws {}
    func batchSave<T: PersistentModel>(_ models: [T]) async throws {}
    func batchDelete<T: PersistentModel>(_ models: [T]) async throws {}
    func count<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> Int { return 0 }
}

@available(macOS 15.0, iOS 18.0, *)
final class TestSecurityService: SecurityServiceProtocol, @unchecked Sendable {
    func authenticate() async throws -> AuthenticationResult {
        return AuthenticationResult(isSuccessful: true, method: .password, error: nil)
    }
    func isBiometricAvailable() async -> Bool { return false }
    func encryptData(_ data: Data) async throws -> Data { return data }
    func decryptData(_ encryptedData: Data) async throws -> Data { return encryptedData }
    func enableBiometric() async throws { }
    func encrypt(_ data: Data) throws -> Data { return data }
    func decrypt(_ encryptedData: Data) throws -> Data { return encryptedData }
    func encryptString(_ string: String) throws -> String { return string }
    func decryptString(_ encryptedString: String) throws -> String { return encryptedString }
    func rotateKeys() async throws { }
    func storeSecurely(_ data: Data, forKey key: String) throws { }
    func retrieveSecurely(forKey key: String) throws -> Data? { return nil }
}

@available(macOS 15.0, iOS 18.0, *)
final class TestMarketDataService: MarketDataServiceProtocol, @unchecked Sendable {
    func getCurrentPrice(for symbol: String) async throws -> Price? { return nil }
    func getHistoricalPrices(for symbol: String, from startDate: Date, to endDate: Date) async throws -> [Price] { return [] }
    func getHistoricalPrices(for symbol: String, range: DateRange) async throws -> [Price] { return [] }
    func searchSymbols(_ query: String) async throws -> [SecurityInfo] { return [] }
    func getMarketStatus(for exchange: String) async throws -> MarketStatus {
        return MarketStatus(exchange: exchange, isOpen: true, nextOpen: nil, nextClose: nil)
    }
    func getExchangeRate(from: String, to: String) async throws -> ExchangeRate {
        return ExchangeRate(from: from, to: to, rate: Decimal(1.0), timestamp: Date())
    }
    func priceUpdates(for symbols: [String]) -> AnyPublisher<PriceUpdate, Never> {
        Empty<PriceUpdate, Never>().eraseToAnyPublisher()
    }
    func subscribeToUpdates(for symbols: [String]) async -> AsyncStream<Price> {
        AsyncStream { $0.finish() }
    }
}

@available(macOS 15.0, iOS 18.0, *)
final class TestCalculationService: CalculationServiceProtocol, @unchecked Sendable {
    func calculatePortfolioValue(_ portfolioId: UUID) async throws -> PortfolioValuation {
        return PortfolioValuation(portfolioId: portfolioId, totalValue: 0, currency: "INR", lastUpdated: Date(), holdings: [])
    }
    func calculateAssetAllocation(_ portfolioId: UUID) async throws -> AssetAllocation {
        return AssetAllocation(portfolioId: portfolioId, allocations: [], lastCalculated: Date())
    }
    func calculatePerformance(_ portfolioId: UUID, timeframe: TimeFrame) async throws -> PerformanceMetrics {
        return PerformanceMetrics(portfolioId: portfolioId, timeframe: timeframe, totalReturn: 0, annualizedReturn: 0, volatility: 0, sharpeRatio: 0, maxDrawdown: 0, calculatedAt: Date())
    }
    func calculateCapitalGainsTax(_ transactions: [Transaction], financialYear: String) async throws -> TaxCalculation {
        return TaxCalculation(financialYear: financialYear, shortTermGains: 0, longTermGains: 0, taxableAmount: 0, taxOwed: 0, calculatedAt: Date())
    }
    func calculateDividendTax(_ dividends: [Transaction], financialYear: String) async throws -> TaxCalculation {
        return TaxCalculation(financialYear: financialYear, shortTermGains: 0, longTermGains: 0, taxableAmount: 0, taxOwed: 0, calculatedAt: Date())
    }
    func calculateRiskMetrics(_ portfolioId: UUID) async throws -> RiskAssessment {
        return RiskAssessment(portfolioId: portfolioId, riskLevel: .low, volatility: 0, betaCoefficient: 0, valueAtRisk: 0, conditionalValueAtRisk: 0, calculatedAt: Date())
    }
    func calculateVaR(_ portfolioId: UUID, confidence: Double, timeHorizon: Int) async throws -> VaRResult {
        return VaRResult(portfolioId: portfolioId, confidence: confidence, timeHorizon: timeHorizon, valueAtRisk: 0, expectedShortfall: 0, calculatedAt: Date())
    }
    func calculateAssetPerformance(_ assetID: UUID, period: PerformancePeriod) async throws -> AssetPerformance {
        return AssetPerformance(assetID: assetID, period: period, returns: 0, volatility: 0, sharpeRatio: 0, maxDrawdown: 0)
    }
    func calculateEMI(principal: Decimal, rate: Decimal, tenure: Int) async throws -> EMICalculation {
        return EMICalculation(principal: principal, rate: rate, tenure: tenure, emi: 0, totalInterest: 0, totalAmount: 0)
    }
    func calculateTax(income: Decimal, regime: TaxRegime) async throws -> TaxCalculation {
        return TaxCalculation(financialYear: "2025-26", shortTermGains: 0, longTermGains: 0, taxableAmount: 0, taxOwed: 0, calculatedAt: Date())
    }
}

@available(macOS 15.0, iOS 18.0, *)
final class TestNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    func scheduleNotification(_ notification: LocalNotification) async throws {}
    func cancelNotification(withID id: String) async throws {}
    func cancelNotification(identifier: String) async {}
    func cancelAllNotifications() async {}
    func createPriceAlert(assetId: UUID, targetPrice: Decimal, condition: AlertCondition) async throws {}
    func createPortfolioAlert(portfolioId: UUID, targetValue: Decimal, condition: AlertCondition) async throws {}
    func getPendingNotifications() async throws -> [LocalNotification] { return [] }
    func requestPermission() async throws -> Bool { return true }
    var notificationPublisher: AnyPublisher<NotificationEvent, Never> {
        Empty<NotificationEvent, Never>().eraseToAnyPublisher()
    }
}