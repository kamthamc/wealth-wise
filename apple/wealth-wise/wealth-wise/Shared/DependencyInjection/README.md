# Dependency Injection System

## Overview

WealthWise uses a custom dependency injection (DI) container to manage service dependencies across the application. This system provides:

- **Type-safe service registration and resolution**
- **Singleton and transient service lifetimes** 
- **SwiftUI integration with property wrappers**
- **Easy testing with mock services**
- **Clean separation of concerns**

## Architecture

The DI system consists of several key components:

### ServiceContainer
The main container that manages service registration and resolution.

```swift
let container = ServiceContainer()

// Register services
container.register(DataServiceProtocol.self) { _ in
    ProductionDataService()
}

// Resolve services
let dataService = container.resolve(DataServiceProtocol.self)
```

### Service Protocols
All services are defined through protocols to enable easy mocking and testing:

- `DataServiceProtocol` - Core data persistence operations
- `SecurityServiceProtocol` - Authentication and encryption  
- `CalculationServiceProtocol` - Financial calculations and analytics
- `MarketDataServiceProtocol` - Real-time market data and pricing
- `NotificationServiceProtocol` - Local notifications and alerts

### Property Wrapper Integration
The `@Injected` property wrapper provides seamless dependency injection in SwiftUI views and view models:

```swift
class DashboardViewModel: ObservableObject {
    @Injected private var dataService: DataServiceProtocol
    @Injected private var calculationService: CalculationServiceProtocol
    
    // Use services directly without manual resolution
}
```

## Usage Examples

### 1. Basic Service Registration

```swift
import Foundation

// Register production services
func registerProductionServices(in container: ServiceContainer) {
    container.register(DataServiceProtocol.self) { _ in
        SwiftDataService()
    }
    
    container.register(SecurityServiceProtocol.self) { _ in
        KeychainSecurityService()
    }
    
    container.register(CalculationServiceProtocol.self) { _ in
        FinancialCalculationService()
    }
    
    container.register(MarketDataServiceProtocol.self) { container in
        let dataService = container.resolve(DataServiceProtocol.self)!
        return MarketDataService(dataService: dataService)
    }
}
```

### 2. SwiftUI View Integration

```swift
struct PortfolioView: View {
    @Injected private var dataService: DataServiceProtocol
    @Injected private var calculationService: CalculationServiceProtocol
    
    @State private var portfolios: [Portfolio] = []
    
    var body: some View {
        List(portfolios, id: \.id) { portfolio in
            PortfolioRow(portfolio: portfolio)
        }
        .task {
            await loadPortfolios()
        }
    }
    
    private func loadPortfolios() async {
        do {
            portfolios = try await dataService.fetch(
                Portfolio.self,
                predicate: nil,
                sortBy: [SortDescriptor(\Portfolio.name)]
            )
        } catch {
            print("Failed to load portfolios: \(error)")
        }
    }
}

// In your app's root view
struct ContentView: View {
    var body: some View {
        PortfolioView()
            .withServiceContainer() // Provides access to registered services
    }
}
```

### 3. ViewModel Pattern

```swift
@MainActor
class PortfolioViewModel: ObservableObject {
    @Injected private var dataService: DataServiceProtocol
    @Injected private var calculationService: CalculationServiceProtocol
    @Injected private var marketDataService: MarketDataServiceProtocol
    
    @Published var portfolios: [Portfolio] = []
    @Published var totalValue: Decimal = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load portfolios
            portfolios = try await dataService.fetch(
                Portfolio.self,
                predicate: nil,
                sortBy: [SortDescriptor(\Portfolio.name)]
            )
            
            // Calculate total value
            var total: Decimal = 0
            for portfolio in portfolios {
                let valuation = try await calculationService.calculatePortfolioValue(portfolio.id)
                total += valuation.totalValue
            }
            totalValue = total
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addPortfolio(name: String, description: String) async {
        do {
            let portfolio = Portfolio(name: name, description: description)
            try await dataService.save(portfolio)
            await loadData() // Refresh data
        } catch {
            errorMessage = "Failed to add portfolio: \(error.localizedDescription)"
        }
    }
}
```

## Testing

### Setting Up Test Container

```swift
class PortfolioViewModelTests: XCTestCase {
    var testContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        
        testContainer = ServiceContainer()
        
        // Register mock services
        testContainer.register(DataServiceProtocol.self) { _ in
            MockDataService()
        }
        
        testContainer.register(CalculationServiceProtocol.self) { _ in
            MockCalculationService()
        }
        
        // Set as global container for testing
        ServiceContainer.shared = testContainer
    }
    
    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }
}
```

### Mock Service Implementation

```swift
class MockDataService: DataServiceProtocol {
    var portfolios: [Portfolio] = []
    var dataChangedPublisher = PassthroughSubject<DataChangeNotification, Never>()
    
    func fetch<T>(_ type: T.Type, predicate: NSPredicate?, sortBy: [SortDescriptor<T>]) async throws -> [T] {
        if type == Portfolio.self {
            return portfolios as! [T]
        }
        return []
    }
    
    func save<T>(_ object: T) async throws {
        if let portfolio = object as? Portfolio {
            portfolios.append(portfolio)
        }
    }
    
    func delete<T>(_ object: T) async throws {
        // Mock implementation
    }
    
    func count<T>(_ type: T.Type, predicate: NSPredicate?) async throws -> Int {
        if type == Portfolio.self {
            return portfolios.count
        }
        return 0
    }
}
```

### Testing ViewModels

```swift
func testPortfolioLoading() async {
    // Setup test data
    let mockDataService = testContainer.resolve(DataServiceProtocol.self) as! MockDataService
    mockDataService.portfolios = [
        Portfolio(name: "Test Portfolio 1", description: "Test 1"),
        Portfolio(name: "Test Portfolio 2", description: "Test 2")
    ]
    
    let viewModel = PortfolioViewModel()
    
    await viewModel.loadData()
    
    XCTAssertEqual(viewModel.portfolios.count, 2)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
}
```

### SwiftUI Preview Testing

```swift
#if DEBUG
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        let testContainer = ServiceContainer()
        
        // Setup preview data
        testContainer.register(DataServiceProtocol.self) { _ in
            let mockService = MockDataService()
            mockService.portfolios = [
                Portfolio(name: "Tech Stocks", description: "Technology focused portfolio"),
                Portfolio(name: "Balanced Fund", description: "Diversified investment portfolio")
            ]
            return mockService
        }
        
        testContainer.register(CalculationServiceProtocol.self) { _ in
            MockCalculationService()
        }
        
        return PortfolioView()
            .withServiceContainer(testContainer)
            .previewDisplayName("Portfolio View with Mock Data")
    }
}
#endif
```

## Configuration

### App Initialization

```swift
@main
struct WealthWiseApp: App {
    let serviceContainer = ServiceContainer.shared
    
    init() {
        setupServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withServiceContainer(serviceContainer)
        }
    }
    
    private func setupServices() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            registerPreviewServices()
        } else {
            registerProductionServices()
        }
        #else
        registerProductionServices()
        #endif
    }
}
```

### Environment-Specific Configuration

```swift
private func registerProductionServices() {
    serviceContainer.register(DataServiceProtocol.self) { _ in
        SwiftDataService(modelContainer: createModelContainer())
    }
    
    serviceContainer.register(SecurityServiceProtocol.self) { _ in
        KeychainSecurityService()
    }
}

private func registerPreviewServices() {
    serviceContainer.register(DataServiceProtocol.self) { _ in
        MockDataService.withSampleData()
    }
    
    serviceContainer.register(SecurityServiceProtocol.self) { _ in
        MockSecurityService()
    }
}
```

## Best Practices

### 1. Protocol-First Design
Always define service contracts through protocols before implementation:

```swift
protocol UserServiceProtocol {
    func getCurrentUser() async throws -> User?
    func updateUser(_ user: User) async throws
}

class KeychainUserService: UserServiceProtocol {
    // Implementation
}
```

### 2. Dependency Ordering
Register dependencies in the correct order - dependencies should be registered before dependents:

```swift
// ❌ Wrong - MarketDataService depends on DataService, but DataService not registered yet
container.register(MarketDataServiceProtocol.self) { container in
    MarketDataService(dataService: container.resolve(DataServiceProtocol.self)!)
}
container.register(DataServiceProtocol.self) { _ in SwiftDataService() }

// ✅ Correct - Register dependencies first
container.register(DataServiceProtocol.self) { _ in SwiftDataService() }
container.register(MarketDataServiceProtocol.self) { container in
    MarketDataService(dataService: container.resolve(DataServiceProtocol.self)!)
}
```

### 3. Error Handling
Always handle service resolution errors gracefully:

```swift
class ViewModel: ObservableObject {
    @Injected private var dataService: DataServiceProtocol
    
    func loadData() async {
        do {
            let data = try await dataService.fetch(/* ... */)
            // Handle success
        } catch {
            // Handle specific service errors
            switch error {
            case DataServiceError.networkUnavailable:
                showOfflineMessage()
            case DataServiceError.authenticationRequired:
                promptForAuthentication()
            default:
                showGenericError(error)
            }
        }
    }
}
```

### 4. Lifecycle Management
Services registered as singletons will live for the app's lifetime. Be mindful of memory usage:

```swift
// ✅ Good for stateless services
container.register(CalculationServiceProtocol.self) { _ in
    FinancialCalculationService() // Stateless, safe as singleton
}

// ❌ Be careful with stateful services
container.register(DataServiceProtocol.self) { _ in
    SwiftDataService() // May accumulate state over time
}
```

## Troubleshooting

### Common Issues

1. **Service not registered**: Ensure services are registered before views that need them are created
2. **Circular dependencies**: Check for services that depend on each other
3. **Threading issues**: Mark ViewModels with `@MainActor` when using `@Published` properties
4. **Memory leaks**: Use weak references in closures when capturing self

### Debug Mode Features

In debug builds, the container provides additional validation:

```swift
#if DEBUG
// Verify all required services are registered
container.validateRegistrations()

// List all registered services
container.listRegisteredServices().forEach { serviceType in
    print("Registered: \(serviceType)")
}
#endif
```

This dependency injection system provides a clean, testable, and maintainable architecture for the WealthWise application while maintaining strong typing and SwiftUI integration.