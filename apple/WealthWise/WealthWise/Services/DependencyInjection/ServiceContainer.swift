//
//  ServiceContainer.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Service Container Implementation
//

import Foundation
import Combine

/// Thread-safe service container for dependency injection
/// Manages service lifecycle, registration, and resolution
@available(iOS 18.6, macOS 15.6, *)
public final class ServiceContainer: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = ServiceContainer()
    
    // MARK: - Properties
    
    private let lock = NSLock()
    private var services: [String: Any] = [:]
    private var factories: [String: ServiceFactory] = [:]
    private var scopes: [String: ServiceScope] = [:]
    
    // MARK: - Service Factory
    
    private struct ServiceFactory: Sendable {
        let create: @Sendable () -> Any
    }
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Registration
    
    /// Register a service with singleton scope
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - factory: Factory closure to create service instance
    public func register<T>(_ type: T.Type, factory: @escaping @Sendable () -> T) {
        register(type, scope: .singleton, factory: factory)
    }
    
    /// Register a service with specified scope
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - scope: Service lifecycle scope
    ///   - factory: Factory closure to create service instance
    public func register<T>(_ type: T.Type, scope: ServiceScope, factory: @escaping @Sendable () -> T) {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        factories[key] = ServiceFactory(create: factory)
        scopes[key] = scope
        
        // For singleton scope, create instance immediately
        if scope == .singleton {
            services[key] = factory()
        }
    }
    
    /// Register an existing instance as singleton
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - instance: Existing service instance
    public func registerInstance<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        services[key] = instance
        scopes[key] = .singleton
    }
    
    // MARK: - Resolution
    
    /// Resolve a service by type
    /// - Parameter type: Service protocol type
    /// - Returns: Service instance
    /// - Throws: ServiceContainerError if service not registered
    public func resolve<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        // Check if singleton instance exists
        if let existingInstance = services[key] as? T {
            return existingInstance
        }
        
        // Check if factory exists
        guard let factory = factories[key] else {
            throw ServiceContainerError.serviceNotRegistered(String(describing: type))
        }
        
        // Create new instance
        let instance = factory.create()
        
        guard let typedInstance = instance as? T else {
            throw ServiceContainerError.typeMismatch(
                expected: String(describing: type),
                actual: String(describing: Swift.type(of: instance))
            )
        }
        
        // Store if singleton
        let scope = scopes[key] ?? .singleton
        if scope == .singleton {
            services[key] = typedInstance
        }
        
        return typedInstance
    }
    
    /// Resolve a service optionally
    /// - Parameter type: Service protocol type
    /// - Returns: Service instance or nil if not registered
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        return try? resolve(type)
    }
    
    /// Check if service is registered
    /// - Parameter type: Service protocol type
    /// - Returns: True if service is registered
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        return services[key] != nil || factories[key] != nil
    }
    
    // MARK: - Lifecycle Management
    
    /// Remove all registrations and instances
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        services.removeAll()
        factories.removeAll()
        scopes.removeAll()
    }
    
    /// Remove specific service registration
    /// - Parameter type: Service protocol type
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        services.removeValue(forKey: key)
        factories.removeValue(forKey: key)
        scopes.removeValue(forKey: key)
    }
    
    /// Get service scope
    /// - Parameter type: Service protocol type
    /// - Returns: Service scope or nil if not registered
    public func getScope<T>(_ type: T.Type) -> ServiceScope? {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        return scopes[key]
    }
    
    /// Get all registered service types
    public var registeredServices: [String] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(Set(services.keys).union(Set(factories.keys)))
    }
}

// MARK: - Service Container Errors

public enum ServiceContainerError: Error, LocalizedError {
    case serviceNotRegistered(String)
    case typeMismatch(expected: String, actual: String)
    case circularDependency(String)
    case initializationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return NSLocalizedString(
                "service_not_registered",
                comment: "Service not registered in container: \(type)"
            )
        case .typeMismatch(let expected, let actual):
            return NSLocalizedString(
                "service_type_mismatch",
                comment: "Service type mismatch. Expected: \(expected), Actual: \(actual)"
            )
        case .circularDependency(let type):
            return NSLocalizedString(
                "circular_dependency",
                comment: "Circular dependency detected: \(type)"
            )
        case .initializationFailed(let type):
            return NSLocalizedString(
                "service_initialization_failed",
                comment: "Service initialization failed: \(type)"
            )
        }
    }
}

// MARK: - Convenience Extensions

@available(iOS 18.6, macOS 15.6, *)
extension ServiceContainer {
    /// Configure default services
    public func configureDefaultServices() {
        // This will be implemented in service adapters
    }
}

// MARK: - Property Wrapper for Dependency Injection

@available(iOS 18.6, macOS 15.6, *)
@propertyWrapper
public struct Injected<T> {
    private let container: ServiceContainer
    
    public init(container: ServiceContainer = .shared) {
        self.container = container
    }
    
    public var wrappedValue: T {
        get {
            do {
                return try container.resolve(T.self)
            } catch {
                fatalError("Failed to resolve dependency: \(T.self). Error: \(error)")
            }
        }
    }
}

@available(iOS 18.6, macOS 15.6, *)
@propertyWrapper
public struct OptionalInjected<T> {
    private let container: ServiceContainer
    
    public init(container: ServiceContainer = .shared) {
        self.container = container
    }
    
    public var wrappedValue: T? {
        get {
            return container.resolveOptional(T.self)
        }
    }
}
