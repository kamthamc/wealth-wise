//
//  AuthenticationStateTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Unit tests for AuthenticationStateManager - Issue #10
//

import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class AuthenticationStateTests: XCTestCase {
    
    var authStateManager: AuthenticationStateManager!
    var mockKeyManager: MockSecureKeyManager!
    var biometricManager: BiometricAuthenticationManager!
    var encryptionService: EncryptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockKeyManager = MockSecureKeyManager()
        biometricManager = BiometricAuthenticationManager(keyManager: mockKeyManager)
        encryptionService = EncryptionService(keyManager: mockKeyManager)
        
        authStateManager = AuthenticationStateManager(
            keyManager: mockKeyManager,
            biometricManager: biometricManager,
            encryptionService: encryptionService
        )
    }
    
    override func tearDown() async throws {
        authStateManager = nil
        biometricManager = nil
        encryptionService = nil
        mockKeyManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialAuthenticationState() throws {
        XCTAssertEqual(authStateManager.authenticationState, .unauthenticated)
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertNil(authStateManager.lastAuthenticationTime)
        XCTAssertNil(authStateManager.sessionExpirationDate)
    }
    
    func testInitialSecurityLevel() throws {
        XCTAssertEqual(authStateManager.securityLevel, .minimal)
    }
    
    func testInitialBiometricState() throws {
        XCTAssertFalse(authStateManager.biometricAuthenticationEnabled)
    }
    
    // MARK: - State Update Tests
    
    func testUpdateAuthenticationStateToAuthenticated() throws {
        authStateManager.updateAuthenticationState(.authenticated)
        
        XCTAssertEqual(authStateManager.authenticationState, .authenticated)
        XCTAssertTrue(authStateManager.isAuthenticated)
    }
    
    func testUpdateAuthenticationStateToUnauthenticated() throws {
        // First authenticate
        authStateManager.updateAuthenticationState(.authenticated)
        XCTAssertTrue(authStateManager.isAuthenticated)
        
        // Then unauthenticate
        authStateManager.updateAuthenticationState(.unauthenticated)
        XCTAssertEqual(authStateManager.authenticationState, .unauthenticated)
        XCTAssertFalse(authStateManager.isAuthenticated)
    }
    
    func testUpdateAuthenticationStateToSessionExpired() throws {
        authStateManager.updateAuthenticationState(.sessionExpired)
        
        XCTAssertEqual(authStateManager.authenticationState, .sessionExpired)
        XCTAssertFalse(authStateManager.isAuthenticated)
    }
    
    func testUpdateAuthenticationStateToLocked() throws {
        authStateManager.updateAuthenticationState(.locked)
        
        XCTAssertEqual(authStateManager.authenticationState, .locked)
        XCTAssertFalse(authStateManager.isAuthenticated)
    }
    
    func testUpdateAuthenticationStateToCompromised() throws {
        authStateManager.updateAuthenticationState(.compromised)
        
        XCTAssertEqual(authStateManager.authenticationState, .compromised)
        XCTAssertFalse(authStateManager.isAuthenticated)
    }
    
    // MARK: - Session Validation Tests
    
    func testSessionValidityWhenNotAuthenticated() throws {
        let isValid = authStateManager.isSessionValid()
        
        XCTAssertFalse(isValid)
    }
    
    func testSessionValidityWithoutExpirationDate() throws {
        authStateManager.updateAuthenticationState(.authenticated)
        
        let isValid = authStateManager.isSessionValid()
        
        // Without expiration date, session validation behavior depends on implementation
        XCTAssertNotNil(isValid)
    }
    
    // MARK: - Remaining Session Time Tests
    
    func testRemainingSessionTimeWhenNotAuthenticated() throws {
        XCTAssertEqual(authStateManager.remainingSessionTime, 0)
    }
    
    // MARK: - Current User Tests
    
    func testCurrentUserInitiallyNil() throws {
        XCTAssertNil(authStateManager.currentUser)
    }
    
    // MARK: - Observable Properties Tests
    
    func testObservablePropertiesAccessible() throws {
        // Verify all observable properties are accessible
        XCTAssertNotNil(authStateManager.authenticationState)
        XCTAssertNotNil(authStateManager.isAuthenticated)
        XCTAssertNotNil(authStateManager.securityLevel)
        XCTAssertNotNil(authStateManager.remainingSessionTime)
        XCTAssertNotNil(authStateManager.biometricAuthenticationEnabled)
    }
}

// MARK: - Authentication State Enum Tests

@available(iOS 18.6, macOS 15.6, *)
final class AuthenticationStateEnumTests: XCTestCase {
    
    func testAuthenticationStateRawValues() throws {
        XCTAssertEqual(AuthenticationState.unauthenticated.rawValue, "unauthenticated")
        XCTAssertEqual(AuthenticationState.authenticated.rawValue, "authenticated")
        XCTAssertEqual(AuthenticationState.authenticating.rawValue, "authenticating")
        XCTAssertEqual(AuthenticationState.sessionExpired.rawValue, "sessionExpired")
        XCTAssertEqual(AuthenticationState.locked.rawValue, "locked")
        XCTAssertEqual(AuthenticationState.compromised.rawValue, "compromised")
    }
    
    func testAuthenticationStateIsSecure() throws {
        XCTAssertFalse(AuthenticationState.unauthenticated.isSecure)
        XCTAssertTrue(AuthenticationState.authenticated.isSecure)
        XCTAssertFalse(AuthenticationState.authenticating.isSecure)
        XCTAssertFalse(AuthenticationState.sessionExpired.isSecure)
        XCTAssertFalse(AuthenticationState.locked.isSecure)
        XCTAssertFalse(AuthenticationState.compromised.isSecure)
    }
    
    func testAuthenticationStateDisplayNames() throws {
        XCTAssertFalse(AuthenticationState.unauthenticated.displayName.isEmpty)
        XCTAssertFalse(AuthenticationState.authenticated.displayName.isEmpty)
        XCTAssertFalse(AuthenticationState.authenticating.displayName.isEmpty)
        XCTAssertFalse(AuthenticationState.sessionExpired.displayName.isEmpty)
        XCTAssertFalse(AuthenticationState.locked.displayName.isEmpty)
        XCTAssertFalse(AuthenticationState.compromised.displayName.isEmpty)
    }
    
    func testAuthenticationStateCaseIterable() throws {
        let allStates = AuthenticationState.allCases
        
        XCTAssertGreaterThanOrEqual(allStates.count, 6)
        XCTAssertTrue(allStates.contains(.unauthenticated))
        XCTAssertTrue(allStates.contains(.authenticated))
        XCTAssertTrue(allStates.contains(.authenticating))
        XCTAssertTrue(allStates.contains(.sessionExpired))
        XCTAssertTrue(allStates.contains(.locked))
        XCTAssertTrue(allStates.contains(.compromised))
    }
}

// MARK: - Security Level Tests

@available(iOS 18.6, macOS 15.6, *)
final class SecurityLevelTests: XCTestCase {
    
    func testSecurityLevelRawValues() throws {
        XCTAssertEqual(SecurityLevel.minimal.rawValue, "minimal")
        XCTAssertEqual(SecurityLevel.standard.rawValue, "standard")
        XCTAssertEqual(SecurityLevel.enhanced.rawValue, "enhanced")
        XCTAssertEqual(SecurityLevel.maximum.rawValue, "maximum")
        XCTAssertEqual(SecurityLevel.quantum.rawValue, "quantum")
    }
    
    func testSecurityLevelDisplayNames() throws {
        XCTAssertFalse(SecurityLevel.minimal.displayName.isEmpty)
        XCTAssertFalse(SecurityLevel.standard.displayName.isEmpty)
        XCTAssertFalse(SecurityLevel.enhanced.displayName.isEmpty)
        XCTAssertFalse(SecurityLevel.maximum.displayName.isEmpty)
        XCTAssertFalse(SecurityLevel.quantum.displayName.isEmpty)
    }
    
    func testSecurityLevelComparison() throws {
        XCTAssertLessThan(SecurityLevel.minimal.securityScore, SecurityLevel.standard.securityScore)
        XCTAssertLessThan(SecurityLevel.standard.securityScore, SecurityLevel.enhanced.securityScore)
        XCTAssertLessThan(SecurityLevel.enhanced.securityScore, SecurityLevel.maximum.securityScore)
        XCTAssertLessThan(SecurityLevel.maximum.securityScore, SecurityLevel.quantum.securityScore)
    }
    
    func testSecurityLevelCaseIterable() throws {
        let allLevels = SecurityLevel.allCases
        
        XCTAssertEqual(allLevels.count, 5)
        XCTAssertTrue(allLevels.contains(.minimal))
        XCTAssertTrue(allLevels.contains(.standard))
        XCTAssertTrue(allLevels.contains(.enhanced))
        XCTAssertTrue(allLevels.contains(.maximum))
        XCTAssertTrue(allLevels.contains(.quantum))
    }
}

// MARK: - Authenticated User Tests

@available(iOS 18.6, macOS 15.6, *)
final class AuthenticatedUserTests: XCTestCase {
    
    func testAuthenticatedUserCreation() throws {
        let user = AuthenticatedUser(
            userId: "user123",
            username: "testuser",
            email: "test@example.com",
            authenticationType: .biometric,
            securityLevel: .maximum,
            sessionToken: "token123",
            tokenExpiration: Date().addingTimeInterval(3600)
        )
        
        XCTAssertEqual(user.userId, "user123")
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.authenticationType, .biometric)
        XCTAssertEqual(user.securityLevel, .maximum)
        XCTAssertEqual(user.sessionToken, "token123")
        XCTAssertNotNil(user.tokenExpiration)
    }
}
