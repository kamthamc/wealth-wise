//
//  ServiceProtocolIntegrationTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Service Protocol Integration Tests
//

import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class ServiceProtocolIntegrationTests: XCTestCase {
    
    var container: ServiceContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        container = ServiceContainer.shared
        container.reset()
        
        // Configure test services
        ServiceContainerConfiguration.configureTestServices(container: container)
    }
    
    override func tearDown() {
        container.reset()
        super.tearDown()
    }
    
    // MARK: - Persistence Service Tests
    
    func testPersistenceServiceRegistration() throws {
        // When
        let service = try container.resolve(PersistenceServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service.isLoaded)
    }
    
    func testPersistenceServiceBackgroundContext() throws {
        // Given
        let service = try container.resolve(PersistenceServiceProtocol.self)
        
        // When
        let backgroundContext = service.newBackgroundContext()
        
        // Then
        XCTAssertNotNil(backgroundContext)
    }
    
    func testPersistenceServiceStatistics() async throws {
        // Given
        let service = try container.resolve(PersistenceServiceProtocol.self)
        
        // When
        let stats = await service.getDatabaseStatistics()
        
        // Then
        XCTAssertNotNil(stats)
        XCTAssertGreaterThanOrEqual(stats.totalAssets, 0)
    }
    
    // MARK: - Security Service Tests
    
    func testSecurityServiceRegistration() throws {
        // When
        let service = try container.resolve(SecurityServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.encryptionService)
        XCTAssertNotNil(service.keyManager)
        XCTAssertNotNil(service.biometricAuth)
    }
    
    func testSecurityServiceEncryption() async throws {
        // Given
        let service = try container.resolve(SecurityServiceProtocol.self)
        let testData = "Test Data".data(using: .utf8)!
        
        // When
        let encryptedData = try await service.encryptData(testData)
        
        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertFalse(encryptedData.ciphertext.isEmpty)
    }
    
    func testSecurityServiceDecryption() async throws {
        // Given
        let service = try container.resolve(SecurityServiceProtocol.self)
        let testData = "Test Data".data(using: .utf8)!
        
        // When
        let encryptedData = try await service.encryptData(testData)
        let decryptedData = try await service.decryptData(encryptedData)
        
        // Then
        XCTAssertEqual(decryptedData, testData)
    }
    
    func testSecurityServiceAuthentication() async throws {
        // Given
        let service = try container.resolve(SecurityServiceProtocol.self)
        
        // When
        let result = try await service.authenticateUser(reason: "Test authentication")
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(result.success)
    }
    
    func testSecurityServiceValidation() async throws {
        // Given
        let service = try container.resolve(SecurityServiceProtocol.self)
        
        // When
        let isValid = await service.validateDeviceSecurity()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testSecurityServiceKeyGeneration() throws {
        // Given
        let service = try container.resolve(SecurityServiceProtocol.self)
        
        // When
        let key = try service.generateSecureKey(identifier: "test-key")
        
        // Then
        XCTAssertNotNil(key)
        XCTAssertEqual(key.identifier, "test-key")
        XCTAssertEqual(key.keySize, 256)
    }
    
    // MARK: - Market Data Service Tests
    
    func testMarketDataServiceRegistration() throws {
        // When
        let service = try container.resolve(MarketDataServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.baseCurrency)
    }
    
    func testMarketDataServiceCurrencySupport() throws {
        // Given
        let service = try container.resolve(MarketDataServiceProtocol.self)
        
        // When
        let currencies = service.getSupportedCurrencies()
        
        // Then
        XCTAssertFalse(currencies.isEmpty)
        XCTAssertTrue(currencies.contains(.USD))
    }
    
    func testMarketDataServiceExchangeRate() throws {
        // Given
        let service = try container.resolve(MarketDataServiceProtocol.self)
        
        // When
        let rate = service.getExchangeRate(from: .USD, to: .EUR)
        
        // Then
        XCTAssertNotNil(rate)
    }
    
    func testMarketDataServiceConversion() throws {
        // Given
        let service = try container.resolve(MarketDataServiceProtocol.self)
        let amount: Decimal = 100
        
        // When
        let converted = service.convert(amount, from: .USD, to: .EUR)
        
        // Then
        XCTAssertNotNil(converted)
    }
    
    func testMarketDataServiceFormatting() throws {
        // Given
        let service = try container.resolve(MarketDataServiceProtocol.self)
        let amount: Decimal = 1234.56
        
        // When
        let formatted = service.formatAmount(amount, currency: .USD, locale: Locale(identifier: "en_US"))
        
        // Then
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("$"))
    }
    
    // MARK: - Service Health Status Tests
    
    func testServiceHealthStatusDisplayNames() {
        // Given/When/Then
        XCTAssertFalse(ServiceHealthStatus.healthy.displayName.isEmpty)
        XCTAssertFalse(ServiceHealthStatus.degraded.displayName.isEmpty)
        XCTAssertFalse(ServiceHealthStatus.unavailable.displayName.isEmpty)
        XCTAssertFalse(ServiceHealthStatus.initializing.displayName.isEmpty)
    }
    
    func testServiceHealthStatusCodable() throws {
        // Given
        let status = ServiceHealthStatus.healthy
        
        // When
        let encoded = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(ServiceHealthStatus.self, from: encoded)
        
        // Then
        XCTAssertEqual(status, decoded)
    }
    
    // MARK: - Integration Tests
    
    func testMultipleServicesCanBeResolved() throws {
        // When
        let persistenceService = try container.resolve(PersistenceServiceProtocol.self)
        let securityService = try container.resolve(SecurityServiceProtocol.self)
        let marketDataService = try container.resolve(MarketDataServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(persistenceService)
        XCTAssertNotNil(securityService)
        XCTAssertNotNil(marketDataService)
    }
    
    func testServicesAreSingletonsByDefault() throws {
        // When
        let service1 = try container.resolve(PersistenceServiceProtocol.self)
        let service2 = try container.resolve(PersistenceServiceProtocol.self)
        
        // Then
        XCTAssertIdentical(service1 as AnyObject, service2 as AnyObject)
    }
    
    // MARK: - Performance Tests
    
    func testServiceResolutionPerformance() {
        measure {
            for _ in 0..<100 {
                _ = try? container.resolve(PersistenceServiceProtocol.self)
                _ = try? container.resolve(SecurityServiceProtocol.self)
                _ = try? container.resolve(MarketDataServiceProtocol.self)
            }
        }
    }
}
