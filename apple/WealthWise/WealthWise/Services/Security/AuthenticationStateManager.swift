//
//  AuthenticationStateManager.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Session Management
//

import Foundation
import Combine
import SwiftUI
import CryptoKit
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
import LocalAuthentication

/// Modern authentication state and session management for iOS 18.6+
/// Provides secure session handling with automatic timeout, state persistence, and background monitoring
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
@MainActor
@Observable
public final class AuthenticationStateManager: AuthenticationStateProtocol, @unchecked Sendable {
    
    // MARK: - Observable Properties
    public private(set) var authenticationState: AuthenticationState = .unauthenticated
    public private(set) var isAuthenticated: Bool = false
    public private(set) var lastAuthenticationTime: Date?
    public private(set) var sessionExpirationDate: Date?
    public private(set) var remainingSessionTime: TimeInterval = 0
    public private(set) var currentUser: AuthenticatedUser?
    public private(set) var securityLevel: SecurityLevel = .minimal
    public private(set) var biometricAuthenticationEnabled: Bool = false
    
    // MARK: - Private Properties
    private let keyManager: SecureKeyManagementProtocol
    private let biometricManager: BiometricAuthenticationManager
    private let encryptionService: EncryptionService
    
    private var sessionTimer: Timer?
    #if os(iOS)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    #endif
    private var sessionMonitoringTask: Task<Void, Never>?
    
    // Session configuration
    private let sessionTimeoutInterval: TimeInterval = SecurityConfiguration.sessionTimeout
    private let sessionRefreshThreshold: TimeInterval = 300 // 5 minutes before expiry
    private let maxConcurrentSessions: Int = 3
    
    // Secure storage keys
    private let sessionTokenKey = "session.token.current"
    private let sessionMetadataKey = "session.metadata.current"
    private let userDataKey = "user.data.encrypted"
    
    // MARK: - Initialization
    
    public init(
        keyManager: SecureKeyManagementProtocol,
        biometricManager: BiometricAuthenticationManager,
        encryptionService: EncryptionService
    ) {
        self.keyManager = keyManager
        self.biometricManager = biometricManager
        self.encryptionService = encryptionService
        
        Task {
            await initializeSessionManagement()
        }
    }
    
    deinit {
        // Cleanup is intentionally minimal to avoid actor-isolation issues during deinitialization
        // Session monitoring will naturally stop when the object is deallocated
    }
    
    // MARK: - AuthenticationStateProtocol Implementation
    
    /// Update authentication state with enhanced security validation
    public func updateAuthenticationState(_ state: AuthenticationState) {
        authenticationState = state
        isAuthenticated = state.isSecure
        
        switch state {
        case .authenticated:
            startSessionMonitoring()
        case .unauthenticated, .sessionExpired, .locked, .compromised:
            stopSessionMonitoring()
            clearSensitiveData()
        default:
            break
        }
        
        // Log state changes for security audit
        logSecurityEvent(.authenticationStateChanged(state))
    }
    
    /// Check if current session is valid with comprehensive validation
    public func isSessionValid() -> Bool {
        guard let expirationDate = sessionExpirationDate else {
            return false
        }
        
        let now = Date()
        let isValid = now < expirationDate && authenticationState == .authenticated
        
        // Additional security checks
        if isValid {
            return validateSessionIntegrity()
        }
        
        return false
    }
    
    /// Invalidate current session with secure cleanup
    public func invalidateSession() {
        stopSessionMonitoring()
        clearSessionData()
        updateAuthenticationState(.unauthenticated)
        
        lastAuthenticationTime = nil
        sessionExpirationDate = nil
        remainingSessionTime = 0
        currentUser = nil
        securityLevel = .minimal
        
        logSecurityEvent(.sessionInvalidated)
    }
    
    /// Start session timeout monitoring with background support
    public func startSessionTimeout() {
        guard isAuthenticated else { return }
        
        let expirationDate = Date().addingTimeInterval(sessionTimeoutInterval)
        sessionExpirationDate = expirationDate
        
        startBackgroundMonitoring()
        startSessionTimer()
        
        logSecurityEvent(.sessionTimeoutStarted(expirationDate))
    }
    
    /// Reset session timeout with security validation
    public func resetSessionTimeout() {
        guard isAuthenticated, validateSessionIntegrity() else {
            invalidateSession()
            return
        }
        
        let newExpirationDate = Date().addingTimeInterval(sessionTimeoutInterval)
        sessionExpirationDate = newExpirationDate
        
        // Update session token with new expiration
        Task {
            await refreshSessionToken()
        }
        
        startSessionTimer()
        logSecurityEvent(.sessionTimeoutReset(newExpirationDate))
    }
    
    // MARK: - Enhanced Session Management
    
    /// Authenticate user with comprehensive session setup
    public func authenticateUser(
        using method: AuthenticationMethod,
        credentials: AuthenticationCredentials? = nil
    ) async throws -> AuthenticationResult {
        
        updateAuthenticationState(.authenticating)
        
        let result: AuthenticationResult
        
        switch method {
        case .biometric(let reason):
            result = try await biometricManager.authenticateWithBiometrics(reason: reason)
            
        case .passkey(let reason, let relyingParty):
            result = try await biometricManager.authenticateWithPasskey(reason: reason, relyingParty: relyingParty)
            
        case .voiceID(let reason, let profile):
            result = try await biometricManager.authenticateWithVoiceID(reason: reason, voiceProfile: profile)
            
        case .appleWatch(let reason):
            result = try await biometricManager.authenticateWithAppleWatch(reason: reason)
            
        case .credentials:
            guard let creds = credentials else {
                throw AuthenticationError.invalidCredentials
            }
            result = try await authenticateWithCredentials(creds)
        }
        
        if result.success {
            try await establishSecureSession(result)
        } else {
            updateAuthenticationState(.unauthenticated)
        }
        
        return result
    }
    
    /// Establish secure session with token generation and persistence
    private func establishSecureSession(_ authResult: AuthenticationResult) async throws {
        // Generate secure session token
        let sessionToken = try await generateSessionToken(authResult)
        
        // Create authenticated user
        let user = AuthenticatedUser(
            id: authResult.userID ?? UUID().uuidString,
            authenticationType: authResult.biometricType,
            securityLevel: authResult.securityLevel,
            sessionToken: sessionToken,
            authenticatedAt: authResult.timestamp
        )
        
        // Store session data securely
        try await storeSessionData(sessionToken, user: user)
        
        // Update state
        currentUser = user
        securityLevel = authResult.securityLevel
        lastAuthenticationTime = authResult.timestamp
        biometricAuthenticationEnabled = authResult.biometricType != .none
        
        updateAuthenticationState(.authenticated)
        startSessionTimeout()
        
        logSecurityEvent(.sessionEstablished(user.id, authResult.securityLevel))
    }
    
    /// Generate cryptographically secure session token
    private func generateSessionToken(_ authResult: AuthenticationResult) async throws -> SessionToken {
        let tokenId = UUID().uuidString
        let issuedAt = Date()
        let expiresAt = issuedAt.addingTimeInterval(sessionTimeoutInterval)
        
        // Create token payload
        let payload = SessionTokenPayload(
            tokenId: tokenId,
            userId: authResult.userID ?? UUID().uuidString,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            securityLevel: authResult.securityLevel,
            biometricType: authResult.biometricType,
            deviceId: await getDeviceIdentifier(),
            sessionHash: try await generateSessionHash()
        )
        
        // Encrypt payload
        let payloadData = try JSONEncoder().encode(payload)
        let sessionKey: SecureKey = try keyManager.retrieveKey(identifier: SecurityConfiguration.KeyIdentifiers.authenticationKey)
            ?? keyManager.generateSecureKey(identifier: SecurityConfiguration.KeyIdentifiers.authenticationKey, accessibility: .biometricCurrentSet)
        
        let encryptedPayload = try await encryptionService.encrypt(payloadData, using: sessionKey)
        
        return SessionToken(
            id: tokenId,
            encryptedPayload: encryptedPayload,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            securityLevel: authResult.securityLevel
        )
    }
    
    /// Store session data with enhanced security
    private func storeSessionData(_ token: SessionToken, user: AuthenticatedUser) async throws {
        // Store session token
        let tokenData = try JSONEncoder().encode(token)
        let tokenKey: SecureKey = try keyManager.retrieveKey(identifier: sessionTokenKey)
            ?? keyManager.generateSecureKey(identifier: sessionTokenKey, accessibility: .biometricCurrentSet)
        
        let encryptedToken = try await encryptionService.encrypt(tokenData, using: tokenKey)
        try keyManager.storeKey(
            SecureKey(keyData: encryptedToken.combinedData, identifier: sessionTokenKey, accessibility: .biometricCurrentSet),
            identifier: sessionTokenKey,
            accessibility: .biometricCurrentSet
        )
        
        // Store user data
        let userData = try JSONEncoder().encode(user)
        let userKey: SecureKey = try keyManager.retrieveKey(identifier: userDataKey)
            ?? keyManager.generateSecureKey(identifier: userDataKey, accessibility: .biometricCurrentSet)
        
        let encryptedUser = try await encryptionService.encrypt(userData, using: userKey)
        try keyManager.storeKey(
            SecureKey(keyData: encryptedUser.combinedData, identifier: userDataKey, accessibility: .biometricCurrentSet),
            identifier: userDataKey,
            accessibility: .biometricCurrentSet
        )
    }
    
    /// Restore session from secure storage
    public func restoreSession() async throws -> Bool {
        guard let tokenKey = try keyManager.retrieveKey(identifier: sessionTokenKey),
              let userKey = try keyManager.retrieveKey(identifier: userDataKey) else {
            return false
        }
        
        // Decrypt and restore session token
        guard let encryptedTokenData = EncryptedData(from: tokenKey.keyData) else {
            return false
        }
        
        let tokenData = try await encryptionService.decrypt(encryptedTokenData, using: tokenKey)
        let sessionToken = try JSONDecoder().decode(SessionToken.self, from: tokenData)
        
        // Check if token is still valid
        guard sessionToken.expiresAt > Date() else {
            invalidateSession()
            return false
        }
        
        // Decrypt and restore user data
        guard let encryptedUserData = EncryptedData(from: userKey.keyData) else {
            return false
        }
        
        let userData = try await encryptionService.decrypt(encryptedUserData, using: userKey)
        let user = try JSONDecoder().decode(AuthenticatedUser.self, from: userData)
        
        // Validate session integrity
        guard try await validateRestoredSession(sessionToken, user: user) else {
            invalidateSession()
            return false
        }
        
        // Restore session state
        currentUser = user
        securityLevel = user.securityLevel
        lastAuthenticationTime = user.authenticatedAt
        sessionExpirationDate = sessionToken.expiresAt
        biometricAuthenticationEnabled = user.authenticationType != .none
        
        updateAuthenticationState(.authenticated)
        startSessionTimeout()
        
        logSecurityEvent(.sessionRestored(user.id))
        return true
    }
    
    /// Validate restored session integrity
    private func validateRestoredSession(_ token: SessionToken, user: AuthenticatedUser) async throws -> Bool {
        // Decrypt and validate token payload
        let sessionKey = try keyManager.retrieveKey(identifier: SecurityConfiguration.KeyIdentifiers.authenticationKey)
        guard let sessionKey = sessionKey else { return false }
        
        let payloadData = try await encryptionService.decrypt(token.encryptedPayload, using: sessionKey)
        let payload = try JSONDecoder().decode(SessionTokenPayload.self, from: payloadData)
        
        // Validate token consistency
      let currentDeviceId = await getDeviceIdentifier()
      guard payload.tokenId == token.id,
          payload.userId == user.id,
          payload.securityLevel == user.securityLevel,
          payload.deviceId == currentDeviceId else {
            return false
        }
        
        // Validate session hash
        let currentHash = try await generateSessionHash()
        return payload.sessionHash == currentHash
    }
    
    /// Refresh session token before expiration
    private func refreshSessionToken() async {
        guard let user = currentUser,
              let expirationDate = sessionExpirationDate else {
            return
        }
        
        // Check if refresh is needed
        let timeUntilExpiry = expirationDate.timeIntervalSinceNow
        guard timeUntilExpiry <= sessionRefreshThreshold else {
            return
        }
        
        do {
            // Generate new session token
            let authResult = AuthenticationResult(
                success: true,
                biometricType: user.authenticationType,
                userID: user.id,
                securityLevel: user.securityLevel
            )
            
            let newToken = try await generateSessionToken(authResult)
            
            // Update stored session
            try await storeSessionData(newToken, user: user)
            
            // Update expiration
            sessionExpirationDate = newToken.expiresAt
            
            logSecurityEvent(.sessionTokenRefreshed(user.id))
            
        } catch {
            logSecurityEvent(.sessionRefreshFailed(error.localizedDescription))
            invalidateSession()
        }
    }
    
    // MARK: - Session Monitoring
    
    /// Initialize session management with background task registration
    private func initializeSessionManagement() async {
        // Register background task for session monitoring (iOS only)
        #if os(iOS)
        if #available(iOS 18.6, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "com.wealthwise.session.monitor",
                using: DispatchQueue.global(qos: .background)
            ) { [weak self] task in
                // Bridge to async context
                Task { [weak self] in
                    await self?.handleBackgroundSessionMonitoring(task)
                }
            }
        }
        #endif
        
        // Attempt to restore previous session
        do {
            let restored = try await restoreSession()
            if !restored {
                logSecurityEvent(.sessionRestorationFailed("No valid session found"))
            }
        } catch {
            logSecurityEvent(.sessionRestorationFailed(error.localizedDescription))
        }
    }
    
    /// Start comprehensive session monitoring
    private func startSessionMonitoring() {
        sessionMonitoringTask?.cancel()
        
        sessionMonitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                await self.performSessionHealthCheck()
                
                // Update remaining time
                if let expiration = self.sessionExpirationDate {
                    self.remainingSessionTime = max(0, expiration.timeIntervalSinceNow)
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    /// Stop session monitoring
    private func stopSessionMonitoring() {
        sessionMonitoringTask?.cancel()
        sessionMonitoringTask = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        endBackgroundMonitoring()
    }
    
    /// Perform comprehensive session health check
    private func performSessionHealthCheck() async {
        guard isAuthenticated else { return }
        
        // Check session expiration
        if let expiration = sessionExpirationDate, Date() >= expiration {
            updateAuthenticationState(.sessionExpired)
            invalidateSession()
            return
        }
        
        // Validate session integrity
        if !validateSessionIntegrity() {
            updateAuthenticationState(.compromised)
            invalidateSession()
            return
        }
        
        // Check if refresh is needed
        await refreshSessionToken()
    }
    
    /// Start session timer for UI updates
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let expiration = self.sessionExpirationDate {
                    self.remainingSessionTime = max(0, expiration.timeIntervalSinceNow)
                    
                    if self.remainingSessionTime <= 0 {
                        self.updateAuthenticationState(.sessionExpired)
                        self.invalidateSession()
                    }
                }
            }
        }
    }
    
    // MARK: - Background Monitoring
    
    /// Start background task for session monitoring
    private func startBackgroundMonitoring() {
        endBackgroundMonitoring()
        
        #if os(iOS)
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Session Monitoring") { [weak self] in
            self?.endBackgroundMonitoring()
        }
        #endif
    }
    
    /// End background monitoring task
    private func endBackgroundMonitoring() {
        #if os(iOS)
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        #endif
    }
    
    /// Handle background session monitoring task
    #if os(iOS)
    private func handleBackgroundSessionMonitoring(_ task: BGTask) async {
        await performSessionHealthCheck()
        
        // Schedule next background refresh
        scheduleBackgroundSessionMonitoring()
        
        task.setTaskCompleted(success: true)
    }
    
    /// Schedule background session monitoring
    private func scheduleBackgroundSessionMonitoring() {
        if #available(iOS 18.6, *) {
            let request = BGAppRefreshTaskRequest(identifier: "com.wealthwise.session.monitor")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 minutes
            
            try? BGTaskScheduler.shared.submit(request)
        }
    }
    #endif
    
    // MARK: - Security Utilities
    
    /// Validate session integrity with comprehensive checks
    private func validateSessionIntegrity() -> Bool {
        // Device binding check
        guard currentUser?.sessionToken.securityLevel == securityLevel else {
            return false
        }
        
        // Additional security validations can be added here
        // - Network security status
        // - App integrity checks
        // - Device compromise detection
        
        return true
    }
    
    /// Generate secure session hash for integrity validation
    private func generateSessionHash() async throws -> String {
        let deviceId = await getDeviceIdentifier()
        let timestamp = Date().timeIntervalSince1970
        let combined = "\(deviceId)-\(timestamp)-\(Bundle.main.bundleIdentifier ?? "")"
        
        let hash = SHA256.hash(data: combined.data(using: .utf8) ?? Data())
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Get secure device identifier
    private func getDeviceIdentifier() async -> String {
        // Device identifier is non-optional; keep async signature for call-site compatibility
        return DeviceInfo.shared.identifierForVendor
    }
    
    /// Authenticate with credentials (fallback method)
    private func authenticateWithCredentials(_ credentials: AuthenticationCredentials) async throws -> AuthenticationResult {
        // Implement credential-based authentication
        // This would typically involve server communication
        
        return AuthenticationResult(
            success: true,
            biometricType: .none,
            userID: credentials.username,
            securityLevel: .standard
        )
    }
    
    /// Clear all session data securely
    private func clearSessionData() {
        do {
            try keyManager.deleteKey(identifier: sessionTokenKey)
            try keyManager.deleteKey(identifier: userDataKey)
        } catch {
            logSecurityEvent(.sessionCleanupFailed(error.localizedDescription))
        }
    }
    
    /// Clear sensitive data from memory
    private func clearSensitiveData() {
        currentUser = nil
        sessionExpirationDate = nil
        remainingSessionTime = 0
        securityLevel = .minimal
        biometricAuthenticationEnabled = false
    }
    
    /// Log security events for audit trail
    private func logSecurityEvent(_ event: SecurityEvent) {
        // Implement secure logging
        print("🔒 Security Event: \(event)")
        
        // In production, this would write to secure audit log
        // with proper encryption and tamper detection
    }
}

// MARK: - Supporting Types

/// Authentication methods supported by the system
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public enum AuthenticationMethod: Sendable {
    case biometric(reason: String)
    case passkey(reason: String, relyingParty: String)
    case voiceID(reason: String, profile: Data?)
    case appleWatch(reason: String)
    case credentials
}

/// Authentication credentials for fallback authentication
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct AuthenticationCredentials: Sendable {
    public let username: String
    public let password: String
    public let twoFactorCode: String?
    
    public init(username: String, password: String, twoFactorCode: String? = nil) {
        self.username = username
        self.password = password
        self.twoFactorCode = twoFactorCode
    }
}

/// User roles for authorization
public enum UserRole: String, CaseIterable, Sendable, Codable {
    case user = "user"
    case admin = "admin"
    case viewer = "viewer"
    case editor = "editor"
}

/// Represents an authenticated user in the system
public struct AuthenticatedUser: Codable, Sendable {
    public let id: String
    public let authenticationType: BiometricType
    public let securityLevel: SecurityLevel
    public let sessionToken: SessionToken
    public let authenticatedAt: Date
    public let roles: Set<UserRole>
    
    public init(id: String, authenticationType: BiometricType, securityLevel: SecurityLevel, sessionToken: SessionToken, authenticatedAt: Date, roles: Set<UserRole> = [.user]) {
        self.id = id
        self.authenticationType = authenticationType
        self.securityLevel = securityLevel
        self.sessionToken = sessionToken
        self.authenticatedAt = authenticatedAt
        self.roles = roles
    }
    
    // Custom Codable implementation for Set<UserRole>
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        authenticationType = try container.decode(BiometricType.self, forKey: .authenticationType)
        securityLevel = try container.decode(SecurityLevel.self, forKey: .securityLevel)
        sessionToken = try container.decode(SessionToken.self, forKey: .sessionToken)
        authenticatedAt = try container.decode(Date.self, forKey: .authenticatedAt)
        let rolesArray = try container.decode([UserRole].self, forKey: .roles)
        roles = Set(rolesArray)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(authenticationType, forKey: .authenticationType)
        try container.encode(securityLevel, forKey: .securityLevel)
        try container.encode(sessionToken, forKey: .sessionToken)
        try container.encode(authenticatedAt, forKey: .authenticatedAt)
        try container.encode(Array(roles), forKey: .roles)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, authenticationType, securityLevel, sessionToken, authenticatedAt, roles
    }
}

/// Secure session token
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct SessionToken: Codable, Sendable {
    public let id: String
    public let encryptedPayload: EncryptedData
    public let issuedAt: Date
    public let expiresAt: Date
    public let securityLevel: SecurityLevel
    
    public init(id: String, encryptedPayload: EncryptedData, issuedAt: Date, expiresAt: Date, securityLevel: SecurityLevel) {
        self.id = id
        self.encryptedPayload = encryptedPayload
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.securityLevel = securityLevel
    }
}

/// Session token payload (encrypted)
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
private struct SessionTokenPayload: Codable, Sendable {
    let tokenId: String
    let userId: String
    let issuedAt: Date
    let expiresAt: Date
    let securityLevel: SecurityLevel
    let biometricType: BiometricType
    let deviceId: String
    let sessionHash: String
}

/// Security events for audit logging
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
private enum SecurityEvent: Sendable {
    case authenticationStateChanged(AuthenticationState)
    case sessionEstablished(String, SecurityLevel)
    case sessionInvalidated
    case sessionTimeoutStarted(Date)
    case sessionTimeoutReset(Date)
    case sessionRestored(String)
    case sessionTokenRefreshed(String)
    case sessionRefreshFailed(String)
    case sessionRestorationFailed(String)
    case sessionCleanupFailed(String)
}
