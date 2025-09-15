import Foundation
import SwiftData
import Combine

/// Dependency injection container for WealthWise services
@available(macOS 15.0, iOS 18.0, *)
@MainActor
final class ServiceContainer: ObservableObject, Sendable {
    
    // MARK: - Singleton
    
    static let shared = ServiceContainer()
    
    // MARK: - Service Registry
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultServices()
    }
    
    // MARK: - Service Registration
    
    /// Register a singleton service instance
    /// - Parameters:
    ///   - service: Service instance
    ///   - type: Service protocol type
    func register<T>(_ service: T, as type: T.Type) {
        lock.withLock {
            let key = String(describing: type)
            services[key] = service
        }
    }
    
    /// Register a service factory for lazy initialization
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - factory: Factory closure that creates the service
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.withLock {
            let key = String(describing: type)
            factories[key] = factory
        }
    }
    
    /// Register a service factory with dependencies
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - factory: Factory closure that receives the container
    func register<T>(_ type: T.Type, factory: @escaping (ServiceContainer) -> T) {
        lock.withLock {
            let key = String(describing: type)
            factories[key] = { [weak self] in
                guard let self = self else {
                    fatalError("ServiceContainer deallocated during service creation")
                }
                return factory(self)
            }
        }
    }
    
    // MARK: - Service Resolution
    
    /// Resolve a service instance
    /// - Parameter type: Service protocol type
    /// - Returns: Service instance
    /// - Throws: ServiceContainerError if service cannot be resolved
    func resolve<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)
        
        return try lock.withLock {
            // Check for existing instance
            if let service = services[key] as? T {
                return service
            }
            
            // Try to create from factory
            if let factory = factories[key] {
                let service = factory() as! T
                services[key] = service
                return service
            }
            
            throw ServiceContainerError.serviceNotRegistered(String(describing: type))
        }
    }
    
    /// Resolve a service instance safely (returns nil if not found)
    /// - Parameter type: Service protocol type
    /// - Returns: Service instance or nil
    func resolveOptional<T>(_ type: T.Type) -> T? {
        return try? resolve(type)
    }
    
    // MARK: - Service Management
    
    /// Check if a service is registered
    /// - Parameter type: Service protocol type
    /// - Returns: True if service is registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return lock.withLock {
            return services[key] != nil || factories[key] != nil
        }
    }
    
    /// Remove a service registration
    /// - Parameter type: Service protocol type
    func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        lock.withLock {
            services.removeValue(forKey: key)
            factories.removeValue(forKey: key)
        }
    }
    
    /// Clear all service registrations
    func clearAll() {
        lock.withLock {
            services.removeAll()
            factories.removeAll()
        }
    }
    
    // MARK: - Default Service Setup
    
    private func setupDefaultServices() {
        // Register default service implementations
        register(DataServiceProtocol.self) { container in
            SwiftDataService()
        }
        
        register(SecurityServiceProtocol.self) { container in
            KeychainSecurityService()
        }
        
        register(MarketDataServiceProtocol.self) { container in
            MockMarketDataService() // Replace with real implementation
        }
        
        register(CalculationServiceProtocol.self) { container in
            DefaultCalculationService(
                dataService: try! container.resolve(DataServiceProtocol.self)
            )
        }
        
        register(NotificationServiceProtocol.self) { container in
            LocalNotificationService()
        }
    }
}

// MARK: - Service Container Error

enum ServiceContainerError: LocalizedError {
    case serviceNotRegistered(String)
    case cyclicDependency(String)
    case factoryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "Service not registered: \(type)"
        case .cyclicDependency(let type):
            return "Cyclic dependency detected: \(type)"
        case .factoryFailed(let type):
            return "Factory failed to create service: \(type)"
        }
    }
}

// MARK: - Property Wrapper for Dependency Injection

@propertyWrapper
@MainActor
struct Injected<T> {
    private let type: T.Type
    private var _value: T?
    
    init(_ type: T.Type) {
        self.type = type
    }
    
    var wrappedValue: T {
        mutating get {
            if _value == nil {
                _value = try! ServiceContainer.shared.resolve(type)
            }
            return _value!
        }
    }
}

// MARK: - Service Locator Pattern (Alternative to DI)

@available(macOS 15.0, iOS 18.0, *)
struct ServiceLocator {
    
    /// Get data service instance
    static var dataService: DataServiceProtocol {
        try! ServiceContainer.shared.resolve(DataServiceProtocol.self)
    }
    
    /// Get security service instance
    static var securityService: SecurityServiceProtocol {
        try! ServiceContainer.shared.resolve(SecurityServiceProtocol.self)
    }
    
    /// Get market data service instance
    static var marketDataService: MarketDataServiceProtocol {
        try! ServiceContainer.shared.resolve(MarketDataServiceProtocol.self)
    }
    
    /// Get calculation service instance
    static var calculationService: CalculationServiceProtocol {
        try! ServiceContainer.shared.resolve(CalculationServiceProtocol.self)
    }
    
    /// Get notification service instance
    static var notificationService: NotificationServiceProtocol {
        try! ServiceContainer.shared.resolve(NotificationServiceProtocol.self)
    }
}

// MARK: - Service Configuration

@available(macOS 15.0, iOS 18.0, *)
struct ServiceConfiguration {
    
    /// Configure services for production environment
    static func configureForProduction() {
        let container = ServiceContainer.shared
        
        // Register production services
        container.register(MarketDataServiceProtocol.self) { _ in
            YahooFinanceService() // Real market data service
        }
        
        container.register(SecurityServiceProtocol.self) { _ in
            BiometricSecurityService() // Enhanced security service
        }
    }
    
    /// Configure services for testing environment
    static func configureForTesting() {
        let container = ServiceContainer.shared
        
        // Clear existing services
        container.clearAll()
        
        // Register mock services
        container.register(DataServiceProtocol.self) { _ in
            MockDataService()
        }
        
        container.register(SecurityServiceProtocol.self) { _ in
            MockSecurityService()
        }
        
        container.register(MarketDataServiceProtocol.self) { _ in
            MockMarketDataService()
        }
        
        container.register(CalculationServiceProtocol.self) { container in
            MockCalculationService()
        }
        
        container.register(NotificationServiceProtocol.self) { _ in
            MockNotificationService()
        }
    }
}

// MARK: - Environment Values Extension

private struct ServiceContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerEnvironmentKey.self] }
        set { self[ServiceContainerEnvironmentKey.self] = newValue }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

@available(macOS 15.0, iOS 18.0, *)
extension View {
    
    /// Inject the service container into the environment
    func withServiceContainer(_ container: ServiceContainer = .shared) -> some View {
        environment(\.serviceContainer, container)
    }
}

// MARK: - Example Usage

#if DEBUG
@available(macOS 15.0, iOS 18.0, *)
struct ServiceContainerExample: View {
    
    // Using property wrapper
    @Injected var dataService: DataServiceProtocol
    @Injected var securityService: SecurityServiceProtocol
    
    // Using environment
    @Environment(\.serviceContainer) private var container
    
    var body: some View {
        VStack {
            Text("Service Container Example")
                .font(.title)
            
            Button("Test Data Service") {
                Task {
                    // Use injected service
                    let count = try? await dataService.count(Asset.self, predicate: nil)
                    print("Asset count: \(count ?? 0)")
                }
            }
            
            Button("Test Security Service") {
                Task {
                    // Use service from container
                    let security = try! container.resolve(SecurityServiceProtocol.self)
                    let isAvailable = await security.isBiometricAvailable()
                    print("Biometric available: \(isAvailable)")
                }
            }
            
            Button("Test Market Data") {
                Task {
                    // Use service locator
                    let price = try? await ServiceLocator.marketDataService.getCurrentPrice(for: "AAPL")
                    print("AAPL price: \(price?.value ?? 0)")
                }
            }
        }
        .padding()
    }
}

#Preview("Service Container") {
    ServiceContainerExample()
        .withServiceContainer()
}
#endif