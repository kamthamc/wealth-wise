//
//  ServiceContainerConfiguration.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Container Configuration
//

import Foundation

/// Configuration and setup for the service container
/// Registers all default services and their dependencies
@available(iOS 18.6, macOS 15.6, *)
public final class ServiceContainerConfiguration {
    
    // MARK: - Configuration
    
    /// Configure all default services in the container
    /// - Parameter container: Service container to configure
    @MainActor
    public static func configureDefaultServices(container: ServiceContainer = .shared) {
        // Register Persistence Service
        container.register(PersistenceServiceProtocol.self, scope: .singleton) {
            PersistenceServiceAdapter.createDefault()
        }
        
        // Register Security Service
        container.register(SecurityServiceProtocol.self, scope: .singleton) {
            SecurityServiceAdapter.createDefault()
        }
        
        // Register Market Data Service
        container.register(MarketDataServiceProtocol.self, scope: .singleton) {
            MarketDataServiceAdapter.createDefault()
        }
        
        print(NSLocalizedString(
            "service_container_configured",
            comment: "Service container configured with default services"
        ))
    }
    
    /// Configure services for testing environment
    /// - Parameter container: Service container to configure
    @MainActor
    public static func configureTestServices(container: ServiceContainer = .shared) {
        // Register mock services for testing
        container.register(PersistenceServiceProtocol.self, scope: .singleton) {
            MockPersistenceService()
        }
        
        container.register(SecurityServiceProtocol.self, scope: .singleton) {
            MockSecurityService()
        }
        
        container.register(MarketDataServiceProtocol.self, scope: .singleton) {
            MockMarketDataService()
        }
        
        print(NSLocalizedString(
            "test_services_configured",
            comment: "Service container configured with test services"
        ))
    }
}

// MARK: - Mock Services for Testing

@available(iOS 18.6, macOS 15.6, *)
@MainActor
private final class MockPersistenceService: PersistenceServiceProtocol, @unchecked Sendable {
    var isLoaded: Bool = true
    var viewContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    
    nonisolated func newBackgroundContext() -> NSManagedObjectContext {
        return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }
    
    func save() throws {
        // Mock implementation
    }
    
    nonisolated func saveBackground(context: NSManagedObjectContext) throws {
        // Mock implementation
    }
    
    nonisolated func performBackgroundTask<T>(
        _ operation: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        return try operation(context)
    }
    
    nonisolated func getDatabaseStatistics() async -> DatabaseStatistics {
        return DatabaseStatistics(
            totalAssets: 0,
            totalPerformanceRecords: 0,
            totalCurrencyRiskRecords: 0,
            totalTaxResidencyRecords: 0,
            databaseSize: 0,
            lastUpdated: Date()
        )
    }
    
    func clearMemoryCaches() {
        // Mock implementation
    }
    
    func resetContexts() {
        // Mock implementation
    }
}

@available(iOS 18.6, macOS 15.6, *)
@MainActor
private final class MockSecurityService: SecurityServiceProtocol, @unchecked Sendable {
    var encryptionService: EncryptionServiceProtocol {
        MockEncryptionService()
    }
    
    var keyManager: SecureKeyManagementProtocol {
        MockKeyManager()
    }
    
    var biometricAuth: BiometricAuthenticationProtocol {
        MockBiometricAuth()
    }
    
    var authStateManager: AuthenticationStateProtocol {
        MockAuthStateManager()
    }
    
    var validationService: SecurityValidationProtocol {
        MockValidationService()
    }
    
    func encryptData(_ data: Data) async throws -> EncryptedData {
        return EncryptedData(
            ciphertext: data,
            nonce: Data(count: 12),
            tag: Data(count: 16),
            algorithm: .aes256GCM
        )
    }
    
    func decryptData(_ encryptedData: EncryptedData) async throws -> Data {
        return encryptedData.ciphertext
    }
    
    func authenticateUser(reason: String) async throws -> AuthenticationResult {
        return AuthenticationResult(
            success: true,
            biometricType: .none,
            timestamp: Date(),
            error: nil,
            userID: "test-user",
            securityLevel: .standard
        )
    }
    
    func validateDeviceSecurity() async -> Bool {
        return true
    }
    
    func generateSecureKey(identifier: String) throws -> SecureKey {
        return SecureKey(
            keyData: Data(count: 32),
            identifier: identifier,
            algorithm: .aes256,
            keySize: 256
        )
    }
}

@available(iOS 18.6, macOS 15.6, *)
@MainActor
private final class MockMarketDataService: MarketDataServiceProtocol, @unchecked Sendable {
    var baseCurrency: SupportedCurrency = .USD
    var isUpdating: Bool = false
    var lastError: Error? = nil
    
    func updateExchangeRates() async throws {
        // Mock implementation
    }
    
    func getExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        return ExchangeRate(from: from, to: to, rate: 1.0, source: "Mock")
    }
    
    func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal? {
        return amount
    }
    
    func formatAmount(_ amount: Decimal, currency: SupportedCurrency, locale: Locale?) -> String {
        return "\(currency.symbol)\(amount)"
    }
    
    func getSupportedCurrencies() -> [SupportedCurrency] {
        return [.USD, .EUR, .INR]
    }
}

// Mock helper classes
@available(iOS 18.6, macOS 15.6, *)
private final class MockEncryptionService: EncryptionServiceProtocol, @unchecked Sendable {
    func encrypt(_ data: Data, using key: SecureKey) async throws -> EncryptedData {
        return EncryptedData(ciphertext: data, nonce: Data(count: 12), tag: Data(count: 16))
    }
    
    func decrypt(_ encryptedData: EncryptedData, using key: SecureKey) async throws -> Data {
        return encryptedData.ciphertext
    }
    
    func generateRandomKey() -> SecureKey {
        return SecureKey(keyData: Data(count: 32), identifier: "mock", algorithm: .aes256, keySize: 256)
    }
    
    func deriveKey(from password: String, salt: Data, iterations: Int) throws -> SecureKey {
        return SecureKey(keyData: Data(count: 32), identifier: "mock-derived", algorithm: .aes256, keySize: 256)
    }
}

@available(iOS 18.6, macOS 15.6, *)
private final class MockKeyManager: SecureKeyManagementProtocol, @unchecked Sendable {
    func generateSecureKey(identifier: String, accessibility: KeyAccessibility) throws -> SecureKey {
        return SecureKey(keyData: Data(count: 32), identifier: identifier, algorithm: .aes256, keySize: 256)
    }
    
    func storeKey(_ key: SecureKey, identifier: String, accessibility: KeyAccessibility) throws {}
    
    func retrieveKey(identifier: String) throws -> SecureKey? {
        return SecureKey(keyData: Data(count: 32), identifier: identifier, algorithm: .aes256, keySize: 256)
    }
    
    func deleteKey(identifier: String) throws {}
    
    func keyExists(identifier: String) -> Bool { return true }
    
    func updateKeyAccessibility(identifier: String, accessibility: KeyAccessibility) throws {}
}

@available(iOS 18.6, macOS 15.6, *)
private final class MockBiometricAuth: BiometricAuthenticationProtocol, @unchecked Sendable {
    func isBiometricAuthenticationAvailable() -> Bool { return true }
    
    func availableBiometricType() -> BiometricType { return .none }
    
    func authenticateWithBiometrics(reason: String) async throws -> AuthenticationResult {
        return AuthenticationResult(success: true, biometricType: .none)
    }
    
    func isBiometricEnrolled() -> Bool { return true }
}

@available(iOS 18.6, macOS 15.6, *)
private final class MockAuthStateManager: AuthenticationStateProtocol, ObservableObject, @unchecked Sendable {
    @Published var authenticationState: AuthenticationState = .authenticated
    var isAuthenticated: Bool { return true }
    var lastAuthenticationTime: Date? = Date()
    
    func updateAuthenticationState(_ state: AuthenticationState) {}
    func isSessionValid() -> Bool { return true }
    func invalidateSession() {}
    func startSessionTimeout() {}
    func resetSessionTimeout() {}
}

@available(iOS 18.6, macOS 15.6, *)
private final class MockValidationService: SecurityValidationProtocol, @unchecked Sendable {
    func isDeviceCompromised() async -> Bool { return false }
    func isAppIntegrityValid() async -> Bool { return true }
    func isDebuggerAttached() -> Bool { return false }
    func validateCertificatePinning(for url: URL) -> Bool { return true }
    func detectSuspiciousActivity() -> [SecurityThreat] { return [] }
}
