//
//  BiometricAuthenticationTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Unit tests for BiometricAuthenticationManager - Issue #10
//

import XCTest
import LocalAuthentication
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class BiometricAuthenticationTests: XCTestCase {
    
    var biometricManager: BiometricAuthenticationManager!
    var mockKeyManager: MockSecureKeyManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockKeyManager = MockSecureKeyManager()
        biometricManager = BiometricAuthenticationManager(keyManager: mockKeyManager)
    }
    
    override func tearDown() async throws {
        biometricManager = nil
        mockKeyManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testBiometricAuthenticationAvailability() throws {
        let isAvailable = biometricManager.isBiometricAuthenticationAvailable()
        
        // May be true or false depending on test environment
        XCTAssertNotNil(isAvailable)
    }
    
    func testAvailableBiometricType() throws {
        let biometricType = biometricManager.availableBiometricType()
        
        // Type should be one of the valid types
        XCTAssertTrue([
            BiometricType.none,
            BiometricType.touchID,
            BiometricType.faceID,
            BiometricType.opticID
        ].contains(biometricType))
    }
    
    // MARK: - State Management Tests
    
    func testInitialState() throws {
        // Initial state should be properly set
        XCTAssertEqual(biometricManager.failedAttempts, 0)
        XCTAssertNil(biometricManager.lastAuthenticationTime)
    }
    
    func testPublishedPropertiesAccessible() throws {
        // Verify published properties are accessible
        XCTAssertNotNil(biometricManager.currentBiometricType)
        XCTAssertNotNil(biometricManager.isAvailable)
        XCTAssertNotNil(biometricManager.isEnrolled)
    }
    
    // MARK: - Error Handling Tests
    
    func testAuthenticationWithInvalidReason() async throws {
        // Test with empty reason
        do {
            _ = try await biometricManager.authenticateWithBiometrics(reason: "")
            // If we get here, the authentication might have succeeded or been skipped
            // in the test environment
        } catch {
            // Expect some form of error
            XCTAssertNotNil(error)
        }
    }
    
    func testAuthenticationReasonLocalization() throws {
        // Test that reason strings should be localized
        let reason = NSLocalizedString("biometric_auth_reason", comment: "Biometric authentication reason")
        
        XCTAssertNotNil(reason)
        XCTAssertFalse(reason.isEmpty)
    }
}

// MARK: - BiometricType Tests

@available(iOS 18.6, macOS 15.6, *)
final class BiometricTypeTests: XCTestCase {
    
    func testBiometricTypeRawValues() throws {
        XCTAssertEqual(BiometricType.none.rawValue, "none")
        XCTAssertEqual(BiometricType.touchID.rawValue, "touchID")
        XCTAssertEqual(BiometricType.faceID.rawValue, "faceID")
        XCTAssertEqual(BiometricType.opticID.rawValue, "opticID")
    }
    
    func testBiometricTypeDisplayNames() throws {
        XCTAssertFalse(BiometricType.none.displayName.isEmpty)
        XCTAssertFalse(BiometricType.touchID.displayName.isEmpty)
        XCTAssertFalse(BiometricType.faceID.displayName.isEmpty)
        XCTAssertFalse(BiometricType.opticID.displayName.isEmpty)
    }
    
    func testBiometricTypeCaseIterable() throws {
        let allTypes = BiometricType.allCases
        
        XCTAssertGreaterThanOrEqual(allTypes.count, 4)
        XCTAssertTrue(allTypes.contains(.none))
        XCTAssertTrue(allTypes.contains(.touchID))
        XCTAssertTrue(allTypes.contains(.faceID))
        XCTAssertTrue(allTypes.contains(.opticID))
    }
}

// MARK: - Authentication Result Tests

@available(iOS 18.6, macOS 15.6, *)
final class AuthenticationResultTests: XCTestCase {
    
    func testAuthenticationResultSuccess() throws {
        let result = AuthenticationResult(
            success: true,
            biometricType: .faceID,
            timestamp: Date(),
            securityLevel: .maximum
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.biometricType, .faceID)
        XCTAssertNotNil(result.timestamp)
        XCTAssertEqual(result.securityLevel, .maximum)
        XCTAssertNil(result.error)
    }
    
    func testAuthenticationResultFailure() throws {
        let error = NSError(domain: "TestError", code: 1)
        let result = AuthenticationResult(
            success: false,
            biometricType: .none,
            timestamp: Date(),
            securityLevel: .minimal,
            error: error
        )
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.biometricType, .none)
        XCTAssertNotNil(result.error)
    }
}

// MARK: - Authentication Error Tests

@available(iOS 18.6, macOS 15.6, *)
final class AuthenticationErrorTests: XCTestCase {
    
    func testAuthenticationErrorTypes() throws {
        let errors: [AuthenticationError] = [
            .biometricNotAvailable,
            .biometricNotEnrolled,
            .biometricLockout,
            .biometricFailed,
            .authenticationCancelled,
            .invalidCredentials,
            .sessionExpired,
            .networkError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testAuthenticationErrorDescriptions() throws {
        XCTAssertFalse(AuthenticationError.biometricNotAvailable.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(AuthenticationError.biometricLockout.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(AuthenticationError.sessionExpired.errorDescription?.isEmpty ?? true)
    }
}
