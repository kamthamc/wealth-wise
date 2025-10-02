//
//  ServiceContainer.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection Container - Core Infrastructure
//

import Foundation
import SwiftUI
import Combine

/// Dependency injection container for managing service lifecycle and dependencies
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class ServiceContainer: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ServiceContainer()
    
    // MARK: - Service Registry
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Service Registration
    
    /// Register a singleton service instance
    public func register<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        services[key] = instance
    }
    
    /// Register a service factory for lazy initialization
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Register a service with automatic initialization
    public func registerLazy<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, factory: factory)
    }
    
    // MARK: - Service Resolution
    
    /// Resolve a registered service
    public func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        // Check if instance already exists
        if let service = services[key] as? T {
            return service
        }
        
        // Try to create from factory
        if let factory = factories[key] {
            let instance = factory()
            services[key] = instance
            return instance as? T
        }
        
        return nil
    }
    
    /// Resolve a required service (force unwrap)
    public func resolveRequired<T>(_ type: T.Type) -> T {
        guard let service = resolve(type) else {
            fatalError("Service \(String(describing: type)) not registered")
        }
        return service
    }
    
    // MARK: - Service Removal
    
    /// Remove a service from the container
    public func remove<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        services.removeValue(forKey: key)
        factories.removeValue(forKey: key)
    }
    
    /// Clear all services (useful for testing)
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        services.removeAll()
        factories.removeAll()
    }
    
    // MARK: - Default Service Registration
    
    private func registerDefaultServices() {
        // Security Services
        registerLazy(SecureKeyManagementProtocol.self) {
            SecureKeyManager()
        }
        
        registerLazy(EncryptionServiceProtocol.self) {
            EncryptionService(keyManager: self.resolveRequired(SecureKeyManagementProtocol.self))
        }
        
        registerLazy(BiometricAuthenticationProtocol.self) {
            BiometricAuthenticationManager()
        }
        
        registerLazy(AuthenticationStateProtocol.self) {
            AuthenticationStateManager()
        }
        
        registerLazy(SecurityValidationProtocol.self) {
            SecurityValidationService()
        }
        
        // Data Services
        registerLazy(DataServiceProtocol.self) {
            DataService()
        }
        
        // Transaction Services
        registerLazy(TransactionServiceProtocol.self) {
            TransactionService()
        }
        
        // Currency Services
        registerLazy(CurrencyServiceProtocol.self) {
            CurrencyService()
        }
    }
}

// MARK: - Service Protocols

/// Protocol for data persistence operations
@available(iOS 18.6, macOS 15.6, *)
public protocol DataServiceProtocol: AnyObject, Sendable {
    func save() async throws
    func fetch<T>(_ type: T.Type, predicate: NSPredicate?) async throws -> [T]
    func delete(_ object: Any) async throws
}

/// Protocol for transaction management
@available(iOS 18.6, macOS 15.6, *)
public protocol TransactionServiceProtocol: AnyObject, Sendable {
    func createTransaction(_ transaction: Transaction) async throws
    func fetchTransactions(accountId: String?) async throws -> [Transaction]
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: UUID) async throws
}

/// Protocol for currency operations
@available(iOS 18.6, macOS 15.6, *)
public protocol CurrencyServiceProtocol: AnyObject, Sendable {
    func getExchangeRate(from: String, to: String) async throws -> Decimal
    func convertAmount(_ amount: Decimal, from: String, to: String) async throws -> Decimal
}

// MARK: - Default Implementations

/// Default data service implementation
@available(iOS 18.6, macOS 15.6, *)
@MainActor
fileprivate final class DataService: DataServiceProtocol, @unchecked Sendable {
    
    nonisolated public func save() async throws {
        // Implementation will be added when integrating with persistence layer
        print("DataService.save() called")
    }
    
    nonisolated public func fetch<T>(_ type: T.Type, predicate: NSPredicate?) async throws -> [T] {
        // Implementation will be added when integrating with persistence layer
        print("DataService.fetch() called for type: \(type)")
        return []
    }
    
    nonisolated public func delete(_ object: Any) async throws {
        // Implementation will be added when integrating with persistence layer
        print("DataService.delete() called")
    }
}

// MARK: - Environment Key

@available(iOS 18.6, macOS 15.6, *)
private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = ServiceContainer.shared
}

@available(iOS 18.6, macOS 15.6, *)
extension EnvironmentValues {
    public var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
