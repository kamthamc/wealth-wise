//
//  ServiceProtocols.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Core Service Protocols
//

import Foundation
import CoreData
import SwiftData
import Combine

// MARK: - Persistence Service Protocol

/// Protocol defining persistence operations for the application
/// Abstracts Core Data and SwiftData operations
@available(iOS 18.6, macOS 15.6, *)
public protocol PersistenceServiceProtocol: AnyObject, Sendable {
    /// Main view context for UI operations
    var viewContext: NSManagedObjectContext { get }
    
    /// Check if persistence layer is loaded and ready
    var isLoaded: Bool { get }
    
    /// Create a new background context for heavy operations
    nonisolated func newBackgroundContext() -> NSManagedObjectContext
    
    /// Save the main context
    func save() throws
    
    /// Save a background context
    nonisolated func saveBackground(context: NSManagedObjectContext) throws
    
    /// Perform operation in background
    nonisolated func performBackgroundTask<T>(
        _ operation: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T
    
    /// Get database statistics
    nonisolated func getDatabaseStatistics() async -> DatabaseStatistics
    
    /// Clear memory caches
    func clearMemoryCaches()
    
    /// Reset contexts (for testing or cleanup)
    func resetContexts()
}

// MARK: - Security Service Protocol

/// Protocol defining security operations for the application
/// Abstracts encryption, key management, and biometric authentication
@available(iOS 18.6, macOS 15.6, *)
public protocol SecurityServiceProtocol: AnyObject, Sendable {
    /// Encryption service for data protection
    var encryptionService: EncryptionServiceProtocol { get }
    
    /// Key management service
    var keyManager: SecureKeyManagementProtocol { get }
    
    /// Biometric authentication service
    var biometricAuth: BiometricAuthenticationProtocol { get }
    
    /// Authentication state manager
    var authStateManager: AuthenticationStateProtocol { get }
    
    /// Security validation service
    var validationService: SecurityValidationProtocol { get }
    
    /// Encrypt sensitive data
    func encryptData(_ data: Data) async throws -> EncryptedData
    
    /// Decrypt encrypted data
    func decryptData(_ encryptedData: EncryptedData) async throws -> Data
    
    /// Authenticate user with biometrics
    func authenticateUser(reason: String) async throws -> AuthenticationResult
    
    /// Validate device security
    func validateDeviceSecurity() async -> Bool
    
    /// Generate secure key for encryption
    func generateSecureKey(identifier: String) throws -> SecureKey
}

// MARK: - Market Data Service Protocol

/// Protocol defining market data operations
/// Abstracts currency exchange rates and financial market data
@available(iOS 18.6, macOS 15.6, *)
public protocol MarketDataServiceProtocol: AnyObject, Sendable {
    /// Current base currency for conversions
    var baseCurrency: SupportedCurrency { get set }
    
    /// Whether market data is currently updating
    var isUpdating: Bool { get }
    
    /// Last update error if any
    var lastError: Error? { get }
    
    /// Update exchange rates from external sources
    func updateExchangeRates() async throws
    
    /// Get exchange rate between currencies
    func getExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate?
    
    /// Convert amount between currencies
    func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal?
    
    /// Format currency amount with localization
    func formatAmount(_ amount: Decimal, currency: SupportedCurrency, locale: Locale?) -> String
    
    /// Get supported currencies
    func getSupportedCurrencies() -> [SupportedCurrency]
}

// MARK: - Goal Tracking Service Protocol

/// Protocol defining goal tracking operations
/// Abstracts financial goal management and progress tracking
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public protocol GoalTrackingServiceProtocol: AnyObject {
    /// Currently tracked goals
    var activeGoals: [Goal] { get }
    
    /// Whether service is loading
    var isLoading: Bool { get }
    
    /// Last update timestamp
    var lastUpdated: Date? { get }
    
    /// Add new goal to tracking
    func addGoal(_ goal: Goal) async throws
    
    /// Update existing goal
    func updateGoal(_ goal: Goal) async throws
    
    /// Remove goal from tracking
    func removeGoal(_ goal: Goal) async throws
    
    /// Calculate progress for goal
    func calculateProgress(for goalId: UUID) async throws -> GoalProgressCalculator.GoalProgressAnalysis
    
    /// Get all active goals
    func fetchActiveGoals() async throws -> [Goal]
}

// MARK: - Service Lifecycle Protocol

/// Protocol for services that need lifecycle management
public protocol ServiceLifecycle: AnyObject {
    /// Initialize service resources
    func initialize() async throws
    
    /// Clean up service resources
    func cleanup() async
    
    /// Service is ready for use
    var isReady: Bool { get }
}

// MARK: - Observable Service Protocol

/// Protocol for services that publish state changes
@available(iOS 18.6, macOS 15.6, *)
public protocol ObservableServiceProtocol: ObservableObject {
    /// Service health status
    var healthStatus: ServiceHealthStatus { get }
}

// MARK: - Supporting Types

/// Service health status enumeration
public enum ServiceHealthStatus: String, Sendable, Codable {
    case healthy = "healthy"
    case degraded = "degraded"
    case unavailable = "unavailable"
    case initializing = "initializing"
    
    public var displayName: String {
        switch self {
        case .healthy: return NSLocalizedString("service_health_healthy", comment: "Service is healthy")
        case .degraded: return NSLocalizedString("service_health_degraded", comment: "Service is degraded")
        case .unavailable: return NSLocalizedString("service_health_unavailable", comment: "Service is unavailable")
        case .initializing: return NSLocalizedString("service_health_initializing", comment: "Service is initializing")
        }
    }
}

// MARK: - Service Registration

/// Service scope enumeration
public enum ServiceScope: Sendable {
    case singleton    // Single instance shared across app
    case transient    // New instance for each resolution
    case scoped       // Instance per scope (e.g., per view)
}

/// Service registration descriptor
public struct ServiceRegistration: Sendable {
    public let serviceType: String
    public let scope: ServiceScope
    public let factory: @Sendable () -> Any
    
    public init(serviceType: String, scope: ServiceScope, factory: @escaping @Sendable () -> Any) {
        self.serviceType = serviceType
        self.scope = scope
        self.factory = factory
    }
}
