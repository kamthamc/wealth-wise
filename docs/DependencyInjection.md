# Dependency Injection / Service Container Documentation

## Overview

The WealthWise Dependency Injection system provides a comprehensive, protocol-oriented approach to managing application dependencies. This document describes the architecture, design decisions, and usage patterns.

## Design Goals

1. **Protocol-First Design**: All services are defined as protocols to enable testability and flexibility
2. **Thread Safety**: The service container is fully thread-safe for concurrent access
3. **Type Safety**: Compile-time type checking with Swift's strong type system
4. **Flexibility**: Support for multiple lifecycle scopes (singleton, transient, scoped)
5. **Testability**: Easy mock injection for unit and integration tests
6. **Backward Compatibility**: Works alongside existing singleton patterns

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      WealthWiseApp                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          ServiceContainer (Singleton)               │   │
│  │                                                     │   │
│  │  ┌───────────────────┐  ┌──────────────────────┐  │   │
│  │  │   Registrations   │  │   Cached Instances  │  │   │
│  │  │                   │  │                      │  │   │
│  │  │ Protocol -> Scope │  │ Protocol -> Service │  │   │
│  │  │ Protocol -> Factory│ │                      │  │   │
│  │  └───────────────────┘  └──────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Persistence  │  │   Security   │  │ Market Data  │
│   Service    │  │   Service    │  │   Service    │
│              │  │              │  │              │
│  Protocol    │  │  Protocol    │  │  Protocol    │
│     +        │  │     +        │  │     +        │
│  Adapter     │  │  Adapter     │  │  Adapter     │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Core Components

### 1. Service Protocols

**Location**: `Services/DependencyInjection/ServiceProtocols.swift`

Defines clean interfaces for core services:

- `PersistenceServiceProtocol` - Database operations (Core Data)
- `SecurityServiceProtocol` - Encryption, authentication, validation
- `MarketDataServiceProtocol` - Currency conversion, market data
- `GoalTrackingServiceProtocol` - Financial goal tracking
- `ServiceLifecycle` - Service initialization/cleanup
- `ObservableServiceProtocol` - Service health monitoring

**Key Design Decision**: All protocols use `@available(iOS 18.6, macOS 15.6, *)` to ensure compatibility with latest platform features.

### 2. ServiceContainer

**Location**: `Services/DependencyInjection/ServiceContainer.swift`

Thread-safe dependency injection container with:

- **Registration**: Register services with factory closures
- **Resolution**: Resolve services by protocol type
- **Scopes**: Support singleton, transient, and scoped lifecycles
- **Thread Safety**: NSLock-based synchronization
- **Type Safety**: Compile-time type checking

**Key Design Decision**: Uses `@unchecked Sendable` for the container itself while ensuring internal thread-safety with locks.

### 3. Service Adapters

**Location**: `Services/DependencyInjection/*ServiceAdapter.swift`

Bridge existing implementations to new protocol interfaces:

- **PersistenceServiceAdapter**: Wraps `PersistentContainer`
- **SecurityServiceAdapter**: Aggregates encryption, auth, and validation services
- **MarketDataServiceAdapter**: Wraps `CurrencyService` and `CurrencyManager`

**Key Design Decision**: Adapters maintain backward compatibility while providing clean protocol interfaces.

### 4. Configuration

**Location**: `Services/DependencyInjection/ServiceContainerConfiguration.swift`

Centralized service registration:

- `configureDefaultServices()` - Production services
- `configureTestServices()` - Mock services for testing

**Key Design Decision**: Includes mock implementations for all services to facilitate testing.

## Usage Patterns

### Property Wrapper Injection (Recommended)

```swift
class MyViewModel {
    @Injected var persistenceService: PersistenceServiceProtocol
    @Injected var securityService: SecurityServiceProtocol
    @OptionalInjected var optionalService: OptionalServiceProtocol?
    
    func saveData() async throws {
        try persistenceService.save()
    }
}
```

**Advantages**:
- Clean, declarative syntax
- Compile-time type checking
- Automatic resolution
- Works with Swift concurrency

### Manual Resolution

```swift
// Resolve required service
do {
    let service = try ServiceContainer.shared.resolve(PersistenceServiceProtocol.self)
    try service.save()
} catch {
    print("Service resolution failed: \(error)")
}

// Resolve optional service
if let service = ServiceContainer.shared.resolveOptional(OptionalServiceProtocol.self) {
    service.performOptionalOperation()
}
```

### SwiftUI Environment

```swift
struct MyView: View {
    @Environment(\.serviceContainer) private var container
    
    var body: some View {
        Button("Save") {
            if let service = try? container.resolve(PersistenceServiceProtocol.self) {
                try? service.save()
            }
        }
    }
}
```

## Service Scopes

### Singleton (Default)
- Single instance for entire app lifetime
- Cached after first resolution
- Thread-safe access
- **Use for**: Stateful services, shared resources

```swift
container.register(MyServiceProtocol.self, scope: .singleton) {
    MyServiceImplementation()
}
```

### Transient
- New instance for each resolution
- No caching
- **Use for**: Stateless operations, temporary workers

```swift
container.register(MyServiceProtocol.self, scope: .transient) {
    MyServiceImplementation()
}
```

### Scoped
- Instance per scope (e.g., per view hierarchy)
- **Use for**: Request-scoped services, view-specific state

```swift
container.register(MyServiceProtocol.self, scope: .scoped) {
    MyServiceImplementation()
}
```

## Testing

### Unit Testing

```swift
final class MyFeatureTests: XCTestCase {
    var container: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        container = ServiceContainer.shared
        container.reset()
        
        // Register mock
        container.register(MyServiceProtocol.self) {
            MockMyService()
        }
    }
    
    func testFeature() {
        let service = try! container.resolve(MyServiceProtocol.self)
        // Test with mock
    }
}
```

### Integration Testing

```swift
@MainActor
final class ServiceIntegrationTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        ServiceContainerConfiguration.configureTestServices()
    }
    
    func testServiceInteraction() async throws {
        let security = try container.resolve(SecurityServiceProtocol.self)
        let persistence = try container.resolve(PersistenceServiceProtocol.self)
        
        // Test service interactions
    }
}
```

## Performance Considerations

### Optimization Strategies

1. **Lazy Initialization**: Services created only when first requested
2. **Instance Caching**: Singleton instances cached for fast re-resolution
3. **Lock Granularity**: Fine-grained locking for minimal contention
4. **Memory Efficiency**: Weak references for scoped services

### Benchmarks

From `ServiceContainerTests`:
- Registration: ~1ms per 1000 services
- Resolution (singleton): ~0.01ms per call
- Concurrent access: Thread-safe with minimal contention

## Migration Guide

### From Singleton Pattern

**Before**:
```swift
class MyService {
    static let shared = MyService()
    private init() {}
}

let service = MyService.shared
```

**After**:
```swift
protocol MyServiceProtocol {
    func doWork()
}

class MyService: MyServiceProtocol {
    func doWork() { }
}

// Registration
container.register(MyServiceProtocol.self) { MyService() }

// Usage
@Injected var service: MyServiceProtocol
```

### From Direct Initialization

**Before**:
```swift
class MyViewModel {
    let service = MyService()
}
```

**After**:
```swift
class MyViewModel {
    @Injected var service: MyServiceProtocol
}
```

## Best Practices

### 1. Always Use Protocols
```swift
// Good
protocol UserServiceProtocol { }
@Injected var userService: UserServiceProtocol

// Avoid
@Injected var userService: UserService
```

### 2. Register Early
```swift
@main
struct MyApp: App {
    init() {
        ServiceContainerConfiguration.configureDefaultServices()
    }
}
```

### 3. Prefer Property Wrappers
```swift
// Good
@Injected var service: MyServiceProtocol

// Avoid (unless necessary)
let service = try! ServiceContainer.shared.resolve(MyServiceProtocol.self)
```

### 4. Test with Mocks
```swift
container.register(MyServiceProtocol.self) {
    MockMyService()
}
```

### 5. Use Appropriate Scopes
- Singleton: Database, API clients, caches
- Transient: Calculators, formatters, validators
- Scoped: Request handlers, view models

## Security Considerations

1. **Service Isolation**: Services should not expose sensitive data through protocols
2. **Thread Safety**: All service implementations must be thread-safe
3. **Error Handling**: Avoid exposing internal details in error messages
4. **Localization**: All error messages use NSLocalizedString

## Future Enhancements

### Planned Features

1. **Dependency Graph Visualization**: Tool to visualize service dependencies
2. **Service Health Monitoring**: Real-time service health tracking
3. **Automatic Dependency Resolution**: Resolve constructor dependencies automatically
4. **Service Decorators**: Wrap services with cross-cutting concerns (logging, metrics)
5. **Scoped Lifetime Management**: Advanced scope management for request/session lifetime

### Potential Improvements

1. **Property Graph**: Track and validate service dependency graph
2. **Lazy Property Injection**: Defer resolution until first access
3. **Service Events**: Observe service lifecycle events
4. **Configuration Validation**: Validate service registrations at startup

## Troubleshooting

### Common Issues

**Issue**: Service not registered
```
Solution: Ensure ServiceContainerConfiguration.configureDefaultServices() is called
```

**Issue**: Type mismatch error
```
Solution: Verify factory returns correct type implementing the protocol
```

**Issue**: Circular dependency
```
Solution: Break cycle by introducing an intermediate protocol
```

**Issue**: Thread safety concerns
```
Solution: ServiceContainer is thread-safe; ensure service implementations are too
```

## Additional Resources

- [ServiceProtocols.swift](../apple/WealthWise/WealthWise/Services/DependencyInjection/ServiceProtocols.swift) - Protocol definitions
- [ServiceContainer.swift](../apple/WealthWise/WealthWise/Services/DependencyInjection/ServiceContainer.swift) - Container implementation
- [README.md](../apple/WealthWise/WealthWise/Services/DependencyInjection/README.md) - Quick reference guide
- [ServiceContainerTests.swift](../apple/WealthWise/WealthWiseTests/DependencyInjection/ServiceContainerTests.swift) - Unit tests
- [ServiceProtocolIntegrationTests.swift](../apple/WealthWise/WealthWiseTests/DependencyInjection/ServiceProtocolIntegrationTests.swift) - Integration tests

## License

Copyright © 2025 WealthWise. All rights reserved.
