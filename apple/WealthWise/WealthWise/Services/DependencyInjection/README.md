# Dependency Injection / Service Container

## Overview

The WealthWise Dependency Injection system provides a robust, thread-safe service container for managing application dependencies. It follows protocol-oriented design principles and supports multiple service lifecycle scopes.

## Architecture

### Core Components

1. **ServiceContainer** - Thread-safe singleton container managing service registration and resolution
2. **Service Protocols** - Clean interfaces for core services (persistence, security, market data)
3. **Service Adapters** - Bridge existing implementations to protocol interfaces
4. **Configuration** - Centralized service setup and registration

## Service Protocols

### PersistenceServiceProtocol

Abstracts data persistence operations using Core Data.

```swift
@Injected var persistenceService: PersistenceServiceProtocol

// Access view context
let context = persistenceService.viewContext

// Perform background operations
try await persistenceService.performBackgroundTask { context in
    // Heavy database operations
}

// Get statistics
let stats = await persistenceService.getDatabaseStatistics()
```

### SecurityServiceProtocol

Provides unified interface for encryption, authentication, and security validation.

```swift
@Injected var securityService: SecurityServiceProtocol

// Encrypt sensitive data
let encrypted = try await securityService.encryptData(sensitiveData)

// Authenticate user
let result = try await securityService.authenticateUser(reason: "Access financial data")

// Validate device security
let isSecure = await securityService.validateDeviceSecurity()
```

### MarketDataServiceProtocol

Manages currency exchange rates and market data.

```swift
@Injected var marketData: MarketDataServiceProtocol

// Get exchange rate
if let rate = marketData.getExchangeRate(from: .USD, to: .INR) {
    print("Exchange rate: \(rate.rate)")
}

// Convert currency
if let converted = marketData.convert(100, from: .USD, to: .INR) {
    print("Converted amount: \(converted)")
}

// Format with localization
let formatted = marketData.formatAmount(1234.56, currency: .USD, locale: .current)
```

## Service Registration

### Manual Registration

```swift
// Register singleton service
ServiceContainer.shared.register(MyServiceProtocol.self) {
    MyServiceImplementation()
}

// Register transient service
ServiceContainer.shared.register(MyServiceProtocol.self, scope: .transient) {
    MyServiceImplementation()
}

// Register existing instance
let instance = MyServiceImplementation()
ServiceContainer.shared.registerInstance(MyServiceProtocol.self, instance: instance)
```

### Automatic Configuration

```swift
// Configure all default services
ServiceContainerConfiguration.configureDefaultServices()

// Configure test services
ServiceContainerConfiguration.configureTestServices()
```

## Service Resolution

### Property Wrapper Injection

```swift
class MyViewModel {
    @Injected var persistenceService: PersistenceServiceProtocol
    @Injected var securityService: SecurityServiceProtocol
    @OptionalInjected var optionalService: OptionalServiceProtocol?
    
    func doWork() {
        // Use injected services
        persistenceService.save()
    }
}
```

### Manual Resolution

```swift
// Resolve required service
let service = try ServiceContainer.shared.resolve(MyServiceProtocol.self)

// Resolve optional service
let optionalService = ServiceContainer.shared.resolveOptional(MyServiceProtocol.self)

// Check if registered
if ServiceContainer.shared.isRegistered(MyServiceProtocol.self) {
    // Service is available
}
```

### SwiftUI Environment

```swift
struct MyView: View {
    @Environment(\.serviceContainer) private var container
    
    var body: some View {
        Button("Action") {
            if let service = try? container.resolve(MyServiceProtocol.self) {
                service.performAction()
            }
        }
    }
}
```

## Service Scopes

### Singleton (Default)
Single instance shared across the entire application.

```swift
container.register(MyServiceProtocol.self, scope: .singleton) {
    MyServiceImplementation()
}
```

### Transient
New instance created for each resolution.

```swift
container.register(MyServiceProtocol.self, scope: .transient) {
    MyServiceImplementation()
}
```

### Scoped
Instance per scope (e.g., per view hierarchy).

```swift
container.register(MyServiceProtocol.self, scope: .scoped) {
    MyServiceImplementation()
}
```

## Thread Safety

The ServiceContainer is fully thread-safe and supports concurrent registration and resolution:

```swift
// Safe to call from multiple threads
DispatchQueue.global().async {
    let service = try? ServiceContainer.shared.resolve(MyServiceProtocol.self)
}
```

## Testing

### Unit Testing

```swift
func testMyFeature() {
    // Create isolated container
    let container = ServiceContainer.shared
    container.reset()
    
    // Register mock services
    container.register(MyServiceProtocol.self) {
        MockMyService()
    }
    
    // Test with mock
    let service = try! container.resolve(MyServiceProtocol.self)
    // Assertions...
}
```

### Integration Testing

```swift
func testServiceIntegration() async {
    // Configure test services
    ServiceContainerConfiguration.configureTestServices()
    
    let securityService = try! ServiceContainer.shared.resolve(SecurityServiceProtocol.self)
    let testData = "Test".data(using: .utf8)!
    
    // Test encryption/decryption
    let encrypted = try await securityService.encryptData(testData)
    let decrypted = try await securityService.decryptData(encrypted)
    
    XCTAssertEqual(testData, decrypted)
}
```

## Best Practices

### 1. Protocol-First Design
Always define protocols before implementations:

```swift
protocol MyServiceProtocol {
    func doWork() async throws
}

class MyServiceImplementation: MyServiceProtocol {
    func doWork() async throws {
        // Implementation
    }
}
```

### 2. Use Property Wrappers
Prefer `@Injected` over manual resolution:

```swift
// Good
@Injected var service: MyServiceProtocol

// Avoid
let service = try! ServiceContainer.shared.resolve(MyServiceProtocol.self)
```

### 3. Register Early
Configure services during app initialization:

```swift
@main
struct MyApp: App {
    init() {
        ServiceContainerConfiguration.configureDefaultServices()
    }
}
```

### 4. Avoid Circular Dependencies
Services should not depend on each other circularly. Use protocols to break cycles.

### 5. Localize Error Messages
All user-facing strings use NSLocalizedString:

```swift
throw ServiceContainerError.serviceNotRegistered(
    NSLocalizedString("service_not_found", comment: "Service not found")
)
```

## Error Handling

### ServiceContainerError

```swift
do {
    let service = try container.resolve(MyServiceProtocol.self)
} catch ServiceContainerError.serviceNotRegistered(let type) {
    print("Service not registered: \(type)")
} catch ServiceContainerError.typeMismatch(let expected, let actual) {
    print("Type mismatch: expected \(expected), got \(actual)")
} catch {
    print("Unknown error: \(error)")
}
```

## Performance

The service container is optimized for:
- Fast singleton resolution (cached instances)
- Thread-safe concurrent access
- Minimal memory overhead
- Lazy initialization

## Migration Guide

### From Singletons

Before:
```swift
let service = MyService.shared
```

After:
```swift
@Injected var service: MyServiceProtocol
```

### From Manual Initialization

Before:
```swift
class MyClass {
    let service = MyService()
}
```

After:
```swift
class MyClass {
    @Injected var service: MyServiceProtocol
}
```

## Examples

See `ServiceContainerExampleView` in `WealthWiseApp.swift` for complete usage examples.

## License

Copyright © 2025 WealthWise. All rights reserved.
