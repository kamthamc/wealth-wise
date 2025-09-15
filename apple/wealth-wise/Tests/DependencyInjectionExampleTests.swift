import XCTest
import SwiftUI
@testable import wealth_wise

/// Example test demonstrating dependency injection with mock services
@available(macOS 15.0, iOS 18.0, *)
final class DependencyInjectionExampleTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        
        // Create a fresh service container for each test
        serviceContainer = ServiceContainer()
        
        // Register mock services
        setupMockServices()
    }
    
    override func tearDown() {
        serviceContainer = nil
        super.tearDown()
    }
    
    // MARK: - Service Registration Tests
    
    func testServiceRegistration() {
        // Test that services are properly registered
        XCTAssertTrue(serviceContainer.isRegistered(DataServiceProtocol.self))
        XCTAssertTrue(serviceContainer.isRegistered(SecurityServiceProtocol.self))
        XCTAssertTrue(serviceContainer.isRegistered(CalculationServiceProtocol.self))
        XCTAssertTrue(serviceContainer.isRegistered(MarketDataServiceProtocol.self))
    }
    
    func testServiceResolution() {
        // Test that services can be resolved
        let dataService = serviceContainer.resolve(DataServiceProtocol.self)
        let securityService = serviceContainer.resolve(SecurityServiceProtocol.self)
        
        XCTAssertNotNil(dataService)
        XCTAssertNotNil(securityService)
        XCTAssertTrue(dataService is MockDataService)
        XCTAssertTrue(securityService is MockSecurityService)
    }
    
    func testSingletonBehavior() {
        // Test that singleton services return the same instance
        let dataService1 = serviceContainer.resolve(DataServiceProtocol.self)
        let dataService2 = serviceContainer.resolve(DataServiceProtocol.self)
        
        // Since we registered as singleton, should be the same instance
        XCTAssertTrue(dataService1 === dataService2)
    }
    
    // MARK: - DashboardViewModel Tests
    
    func testDashboardViewModelInitialization() async {
        // Set the global service container for testing
        ServiceContainer.shared = serviceContainer
        
        let viewModel = DashboardViewModel()
        
        // Test initial state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.totalNetWorth, 0)
        XCTAssertEqual(viewModel.portfolios.count, 0)
        XCTAssertEqual(viewModel.recentTransactions.count, 0)
    }
    
    func testAuthenticationFlow() async {
        // Set the global service container for testing
        ServiceContainer.shared = serviceContainer
        
        let viewModel = DashboardViewModel()
        
        // Configure mock to return successful authentication
        let mockSecurityService = serviceContainer.resolve(SecurityServiceProtocol.self) as! MockSecurityService
        mockSecurityService.shouldAuthenticateSuccessfully = true
        
        await viewModel.authenticateAndLoad()
        
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testAuthenticationFailure() async {
        // Set the global service container for testing
        ServiceContainer.shared = serviceContainer
        
        let viewModel = DashboardViewModel()
        
        // Configure mock to return failed authentication
        let mockSecurityService = serviceContainer.resolve(SecurityServiceProtocol.self) as! MockSecurityService
        mockSecurityService.shouldAuthenticateSuccessfully = false
        mockSecurityService.authenticationError = SecurityError.authenticationFailed
        
        await viewModel.authenticateAndLoad()
        
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testDataLoading() async {
        // Set the global service container for testing
        ServiceContainer.shared = serviceContainer
        
        let viewModel = DashboardViewModel()
        
        // Configure mocks with test data
        let mockDataService = serviceContainer.resolve(DataServiceProtocol.self) as! MockDataService
        let mockSecurityService = serviceContainer.resolve(SecurityServiceProtocol.self) as! MockSecurityService
        
        mockSecurityService.shouldAuthenticateSuccessfully = true
        mockDataService.setupTestData()
        
        await viewModel.authenticateAndLoad()
        
        // Verify data was loaded
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertGreaterThan(viewModel.portfolios.count, 0)
        XCTAssertGreaterThan(viewModel.recentTransactions.count, 0)
    }
    
    // MARK: - Integration Tests with SwiftUI
    
    func testSwiftUIViewWithDependencyInjection() {
        // Test that SwiftUI views can access injected services
        let testView = TestViewWithInjection()
            .withServiceContainer(serviceContainer)
        
        // This would typically be tested with ViewInspector or similar
        // For now, we just verify the view can be created
        XCTAssertNotNil(testView)
    }
    
    // MARK: - Mock Service Configurations
    
    private func setupMockServices() {
        // Register mock implementations
        serviceContainer.register(DataServiceProtocol.self) { _ in
            MockDataService()
        }
        
        serviceContainer.register(SecurityServiceProtocol.self) { _ in
            MockSecurityService()
        }
        
        serviceContainer.register(CalculationServiceProtocol.self) { _ in
            MockCalculationService()
        }
        
        serviceContainer.register(MarketDataServiceProtocol.self) { _ in
            MockMarketDataService()
        }
        
        serviceContainer.register(NotificationServiceProtocol.self) { _ in
            MockNotificationService()
        }
    }
}

// MARK: - Enhanced Mock Services for Testing

@available(macOS 15.0, iOS 18.0, *)
class MockDataService: DataServiceProtocol {
    var dataChangedPublisher = PassthroughSubject<DataChangeNotification, Never>()
    
    private var portfolios: [Portfolio] = []
    private var transactions: [Transaction] = []
    private var assets: [Asset] = []
    
    func setupTestData() {
        // Create test portfolios
        portfolios = [
            Portfolio(name: "Test Portfolio 1", description: "Test portfolio for unit testing"),
            Portfolio(name: "Test Portfolio 2", description: "Another test portfolio")
        ]
        
        // Create test transactions
        transactions = [
            Transaction(
                amount: 1000.0,
                date: Date(),
                description: "Test transaction 1",
                category: .income
            ),
            Transaction(
                amount: -500.0,
                date: Date().addingTimeInterval(-86400),
                description: "Test transaction 2",
                category: .expense
            )
        ]
        
        // Create test assets
        assets = [
            Asset(
                name: "Test Stock",
                type: .equity,
                currentValue: 5000.0,
                purchasePrice: 4000.0,
                quantity: 10
            ),
            Asset(
                name: "Test Bond",
                type: .bond,
                currentValue: 10000.0,
                purchasePrice: 9500.0,
                quantity: 1
            )
        ]
    }
    
    func fetch<T>(_ type: T.Type, predicate: NSPredicate?, sortBy: [SortDescriptor<T>]) async throws -> [T] {
        switch type {
        case is Portfolio.Type:
            return portfolios as! [T]
        case is Transaction.Type:
            return transactions as! [T]
        case is Asset.Type:
            return assets as! [T]
        default:
            return []
        }
    }
    
    func save<T>(_ object: T) async throws {
        // Simulate saving object
        switch object {
        case let portfolio as Portfolio:
            portfolios.append(portfolio)
        case let transaction as Transaction:
            transactions.append(transaction)
        case let asset as Asset:
            assets.append(asset)
        default:
            break
        }
        
        // Emit change notification
        let notification = DataChangeNotification(
            entityType: String(describing: type(of: object)),
            changeType: .insert,
            objectID: UUID().uuidString
        )
        dataChangedPublisher.send(notification)
    }
    
    func delete<T>(_ object: T) async throws {
        // Simulate deletion
        let notification = DataChangeNotification(
            entityType: String(describing: type(of: object)),
            changeType: .delete,
            objectID: UUID().uuidString
        )
        dataChangedPublisher.send(notification)
    }
    
    func count<T>(_ type: T.Type, predicate: NSPredicate?) async throws -> Int {
        switch type {
        case is Portfolio.Type:
            return portfolios.count
        case is Transaction.Type:
            return transactions.count
        case is Asset.Type:
            return assets.count
        default:
            return 0
        }
    }
}

@available(macOS 15.0, iOS 18.0, *)
class MockSecurityService: SecurityServiceProtocol {
    var shouldAuthenticateSuccessfully = true
    var authenticationError: Error?
    
    func authenticate() async throws -> AuthenticationResult {
        if shouldAuthenticateSuccessfully {
            return AuthenticationResult(
                isSuccessful: true,
                userID: "test-user-123",
                sessionToken: "test-session-token"
            )
        } else {
            throw authenticationError ?? SecurityError.authenticationFailed
        }
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        // Simple mock encryption (just return original data)
        return data
    }
    
    func decryptData(_ encryptedData: Data) async throws -> Data {
        // Simple mock decryption (just return original data)
        return encryptedData
    }
    
    func validateBiometrics() async throws -> Bool {
        return shouldAuthenticateSuccessfully
    }
    
    func generateSecureToken() -> String {
        return "mock-secure-token-\(UUID().uuidString)"
    }
}

@available(macOS 15.0, iOS 18.0, *)
class MockCalculationService: CalculationServiceProtocol {
    func calculatePortfolioValue(_ portfolioID: UUID) async throws -> PortfolioValuation {
        return PortfolioValuation(
            portfolioID: portfolioID,
            totalValue: 50000.0,
            dayChange: 1250.0,
            dayChangePercent: 2.5,
            totalGainLoss: 5000.0,
            totalGainLossPercent: 11.1
        )
    }
    
    func calculateAssetPerformance(_ assetID: UUID, period: PerformancePeriod) async throws -> AssetPerformance {
        return AssetPerformance(
            assetID: assetID,
            period: period,
            return: 0.15,
            volatility: 0.18,
            sharpeRatio: 0.83,
            maxDrawdown: -0.12
        )
    }
    
    func calculateEMI(principal: Decimal, rate: Decimal, tenure: Int) async throws -> EMICalculation {
        // Simple EMI calculation
        let monthlyRate = rate / (12 * 100)
        let denominator = pow(1 + monthlyRate, Double(tenure)) - 1
        let emi = (Double(truncating: NSDecimalNumber(decimal: principal)) * monthlyRate * pow(1 + monthlyRate, Double(tenure))) / denominator
        
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
        // Simplified tax calculation
        let taxableIncome = max(income - 250000, 0) // Basic exemption
        let tax = taxableIncome * 0.10 // Simplified 10% tax
        
        return TaxCalculation(
            income: income,
            regime: regime,
            taxableIncome: taxableIncome,
            totalTax: tax,
            effectiveRate: income > 0 ? tax / income : 0
        )
    }
}

@available(macOS 15.0, iOS 18.0, *)
class MockMarketDataService: MarketDataServiceProtocol {
    func getCurrentPrice(for symbol: String) async throws -> MarketPrice? {
        // Return mock price data
        return MarketPrice(
            symbol: symbol,
            value: Decimal(Double.random(in: 100...1000)),
            currency: "INR",
            lastUpdated: Date()
        )
    }
    
    func getHistoricalPrices(for symbol: String, from startDate: Date, to endDate: Date) async throws -> [MarketPrice] {
        // Return mock historical data
        var prices: [MarketPrice] = []
        var currentDate = startDate
        var basePrice = 500.0
        
        while currentDate <= endDate {
            basePrice += Double.random(in: -20...20) // Random price movement
            prices.append(MarketPrice(
                symbol: symbol,
                value: Decimal(basePrice),
                currency: "INR",
                lastUpdated: currentDate
            ))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return prices
    }
    
    func subscribeToUpdates(for symbols: [String]) async -> AsyncStream<MarketPrice> {
        return AsyncStream { continuation in
            // Mock real-time updates
            Task {
                for symbol in symbols {
                    let price = MarketPrice(
                        symbol: symbol,
                        value: Decimal(Double.random(in: 100...1000)),
                        currency: "INR",
                        lastUpdated: Date()
                    )
                    continuation.yield(price)
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                }
                continuation.finish()
            }
        }
    }
}

@available(macOS 15.0, iOS 18.0, *)
class MockNotificationService: NotificationServiceProtocol {
    func scheduleNotification(_ notification: LocalNotification) async throws {
        // Mock implementation - just print for testing
        print("Scheduled notification: \(notification.title)")
    }
    
    func cancelNotification(withID id: String) async throws {
        print("Cancelled notification with ID: \(id)")
    }
    
    func getPendingNotifications() async throws -> [LocalNotification] {
        return []
    }
    
    func requestPermission() async throws -> Bool {
        return true
    }
}

// MARK: - Test SwiftUI View

@available(macOS 15.0, iOS 18.0, *)
struct TestViewWithInjection: View {
    @Injected private var dataService: DataServiceProtocol
    @Injected private var securityService: SecurityServiceProtocol
    
    var body: some View {
        VStack {
            Text("Test View with Dependency Injection")
            
            Button("Test Services") {
                Task {
                    // Test that services are available
                    let _ = try? await securityService.authenticate()
                    let portfolios = try? await dataService.fetch(Portfolio.self, predicate: nil, sortBy: [])
                    print("Services working: portfolios count = \(portfolios?.count ?? 0)")
                }
            }
        }
    }
}

// MARK: - Additional Test Extensions

@available(macOS 15.0, iOS 18.0, *)
extension ServiceContainer {
    /// Create a test container with mock services
    static func createTestContainer() -> ServiceContainer {
        let container = ServiceContainer()
        
        container.register(DataServiceProtocol.self) { _ in MockDataService() }
        container.register(SecurityServiceProtocol.self) { _ in MockSecurityService() }
        container.register(CalculationServiceProtocol.self) { _ in MockCalculationService() }
        container.register(MarketDataServiceProtocol.self) { _ in MockMarketDataService() }
        container.register(NotificationServiceProtocol.self) { _ in MockNotificationService() }
        
        return container
    }
}

#if DEBUG
/// Preview provider demonstrating DI testing setup
@available(macOS 15.0, iOS 18.0, *)
struct DITestingPreview: PreviewProvider {
    static var previews: some View {
        TestViewWithInjection()
            .withServiceContainer(ServiceContainer.createTestContainer())
            .previewDisplayName("View with Test Services")
    }
}
#endif