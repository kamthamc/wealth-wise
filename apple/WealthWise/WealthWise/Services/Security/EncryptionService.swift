//
//  EncryptionService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Encryption Services
//

import Foundation
import Security
import CryptoKit
import Combine

/// AES-256-GCM encryption service implementation
/// Provides secure encryption/decryption with authenticated encryption
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
@MainActor
open class EncryptionService: EncryptionServiceProtocol, ObservableObject, @unchecked Sendable {
    
    // MARK: - Properties
    private let keyManager: SecureKeyManagementProtocol
    private var cachedKeys: [String: SecureKey] = [:]
    private let queue = DispatchQueue(label: "com.wealthwise.encryption", qos: .userInitiated)
    
    // MARK: - Initialization
    
    public init(keyManager: SecureKeyManagementProtocol) {
        self.keyManager = keyManager
    }
    
    // MARK: - EncryptionServiceProtocol Implementation
    
    /// Encrypt data using AES-256-GCM with authenticated encryption
    public func encrypt(_ data: Data, using key: SecureKey) async throws -> EncryptedData {
        guard key.algorithm == .aes256, key.keySize == 256 else {
            throw EncryptionError.invalidKey
        }
        
        guard !data.isEmpty else {
            throw EncryptionError.invalidData
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key.keyData)
            let nonce = AES.GCM.Nonce()
            
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
            
            let ciphertext = sealedBox.ciphertext
            let tag = sealedBox.tag
            
            return EncryptedData(
                ciphertext: ciphertext,
                nonce: Data(nonce),
                tag: tag,
                algorithm: .aes256GCM,
                securityLevel: key.securityLevel,
                keyIdentifier: key.identifier
            )
            
        } catch {
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypt data using AES-256-GCM with authentication verification
    public func decrypt(_ encryptedData: EncryptedData, using key: SecureKey) async throws -> Data {
        guard key.algorithm == .aes256, key.keySize == 256 else {
            throw EncryptionError.invalidKey
        }
        
        guard encryptedData.algorithm == .aes256GCM else {
            throw EncryptionError.algorithmNotSupported
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key.keyData)
            let nonce = try AES.GCM.Nonce(data: encryptedData.nonce)
            
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: encryptedData.ciphertext,
                tag: encryptedData.tag
            )
            
            return try AES.GCM.open(sealedBox, using: symmetricKey)
            
        } catch {
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }
    
    /// Generate a cryptographically secure random key with enhanced iOS 18.6 security
    public func generateRandomKey(securityLevel: SecurityLevel = .maximum) -> SecureKey {
        let keySize: SymmetricKeySize = securityLevel == .quantum ? .bits256 : .bits256
        let keyData = SymmetricKey(size: keySize).withUnsafeBytes { Data($0) }
        
        return SecureKey(
            keyData: keyData,
            identifier: UUID().uuidString,
            algorithm: securityLevel == .quantum ? .kyber512 : .aes256,
            keySize: securityLevel == .quantum ? 512 : 256,
            accessibility: .secureEnclave,
            securityLevel: securityLevel
        )
    }
    
    /// Protocol conformance wrapper: generateRandomKey without parameters
    public func generateRandomKey() -> SecureKey {
        return generateRandomKey(securityLevel: .maximum)
    }
    
    /// Derive key from password using PBKDF2-SHA256 with enhanced iOS 18.6 security
    public func deriveKey(from password: String, salt: Data, iterations: Int = SecurityConfiguration.keyDerivationIterations, securityLevel: SecurityLevel = .maximum) throws -> SecureKey {
        guard !password.isEmpty else {
            throw EncryptionError.invalidData
        }
        
        guard salt.count >= SecurityConfiguration.saltSize else {
            throw EncryptionError.keyDerivationFailed
        }
        
        guard iterations >= 10_000 else {
            throw EncryptionError.keyDerivationFailed
        }
        
        do {
            let passwordData = password.data(using: .utf8) ?? Data()
            let derivedKey = try deriveKeyPBKDF2(password: passwordData, salt: salt, iterations: iterations, keyLength: 32)
            
            let keyDerivationContext = KeyDerivationContext(
                method: .pbkdf2,
                iterations: iterations,
                salt: salt,
                algorithm: .pbkdf2SHA256
            )
            
            return SecureKey(
                keyData: derivedKey,
                identifier: "derived-\(UUID().uuidString)",
                algorithm: .aes256,
                keySize: 256,
                accessibility: .secureEnclave,
                securityLevel: securityLevel,
                keyDerivationContext: keyDerivationContext
            )
        } catch {
            throw EncryptionError.keyDerivationFailed
        }
    }
    
    /// Protocol conformance wrapper: deriveKey without securityLevel parameter
    public func deriveKey(from password: String, salt: Data, iterations: Int) throws -> SecureKey {
        return try deriveKey(from: password, salt: salt, iterations: iterations, securityLevel: .maximum)
    }
    
    // MARK: - Extended Encryption Methods
    
    /// Encrypt string data with UTF-8 encoding
    public func encrypt(_ string: String, using key: SecureKey) async throws -> EncryptedData {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try await encrypt(data, using: key)
    }
    
    /// Decrypt to string with UTF-8 decoding
    public func decryptToString(_ encryptedData: EncryptedData, using key: SecureKey) async throws -> String {
        let data = try await decrypt(encryptedData, using: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed("Failed to decode UTF-8 string")
        }
        return string
    }
    
    /// Encrypt large data with chunking for memory efficiency
    public func encryptLargeData(_ data: Data, using key: SecureKey, chunkSize: Int = 1024 * 1024) async throws -> EncryptedData {
        guard data.count > chunkSize else {
            return try await encrypt(data, using: key)
        }
        
        var encryptedChunks: [EncryptedData] = []
        var offset = 0
        
        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)
            let encryptedChunk = try await encrypt(chunk, using: key)
            encryptedChunks.append(encryptedChunk)
            offset = end
        }
        
        // Combine all encrypted chunks
        let combinedData = try NSKeyedArchiver.archivedData(withRootObject: encryptedChunks, requiringSecureCoding: true)
        return try await encrypt(combinedData, using: key)
    }
    
    /// Decrypt large data with chunking
    public func decryptLargeData(_ encryptedData: EncryptedData, using key: SecureKey) async throws -> Data {
        let combinedData = try await decrypt(encryptedData, using: key)
        
        guard let encryptedChunks = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: combinedData) as? [EncryptedData] else {
            // If it's not chunked, treat as single data
            return combinedData
        }
        
        var decryptedData = Data()
        for chunk in encryptedChunks {
            let decryptedChunk = try await decrypt(chunk, using: key)
            decryptedData.append(decryptedChunk)
        }
        
        return decryptedData
    }
    
    /// Generate salt for key derivation
    public func generateSalt(size: Int = SecurityConfiguration.saltSize) -> Data {
        var salt = Data(count: size)
        let result = salt.withUnsafeMutableBytes { saltBytes in
            SecRandomCopyBytes(kSecRandomDefault, size, saltBytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            // Fallback to CryptoKit random generation
            return Data((0..<size).map { _ in UInt8.random(in: 0...255) })
        }
        
        return salt
    }
    
    /// Securely compare two data values (constant-time comparison)
    public func secureCompare(_ data1: Data, _ data2: Data) -> Bool {
        guard data1.count == data2.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<data1.count {
            result |= data1[i] ^ data2[i]
        }
        
        return result == 0
    }
    
    /// Hash data using SHA-256
    public func hashSHA256(_ data: Data) -> Data {
        return Data(SHA256.hash(data: data))
    }
    
    /// Hash string using SHA-256
    public func hashSHA256(_ string: String) -> Data {
        guard let data = string.data(using: .utf8) else {
            return Data()
        }
        return hashSHA256(data)
    }
    
    /// Generate HMAC-SHA256
    public func generateHMAC(_ data: Data, key: SecureKey) -> Data {
        let symmetricKey = SymmetricKey(data: key.keyData)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(hmac)
    }
    
    /// Verify HMAC-SHA256
    public func verifyHMAC(_ data: Data, hmac: Data, key: SecureKey) -> Bool {
        let computedHMAC = generateHMAC(data, key: key)
        return secureCompare(hmac, computedHMAC)
    }
    
    // MARK: - Key Caching
    
    /// Cache key for improved performance
    public func cacheKey(_ key: SecureKey, identifier: String) {
        Task { @MainActor in
            cachedKeys[identifier] = key
        }
    }
    
    /// Get cached key
    public func getCachedKey(identifier: String) -> SecureKey? {
        return queue.sync {
            return cachedKeys[identifier]
        }
    }
    
    /// Clear key cache
    public func clearKeyCache() {
        Task { @MainActor in
            cachedKeys.removeAll()
        }
    }
    
    /// Clear specific cached key
    public func clearCachedKey(identifier: String) {
        Task { @MainActor in
            cachedKeys.removeValue(forKey: identifier)
        }
    }
    
    // MARK: - Private Methods
    
    /// PBKDF2 key derivation using CommonCrypto
    private func deriveKeyPBKDF2(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
        var derivedKey = Data(count: keyLength)
        
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            password.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF_bridge(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress!,
                        password.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress!,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress!,
                        keyLength
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw EncryptionError.keyDerivationFailed
        }
        
        return derivedKey
    }
}

// MARK: - Advanced Encryption Service

/// Advanced encryption service with additional algorithms and features
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public final class AdvancedEncryptionService: EncryptionService, @unchecked Sendable {
    
    // MARK: - ChaCha20-Poly1305 Encryption
    
    /// Encrypt data using ChaCha20-Poly1305
    public func encryptChaCha20Poly1305(_ data: Data, using key: SecureKey) throws -> EncryptedData {
        guard key.keySize == 256 else {
            throw EncryptionError.insufficientKeySize
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key.keyData)
            let nonce = ChaChaPoly.Nonce()
            
            let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey, nonce: nonce)
            
            return EncryptedData(
                ciphertext: sealedBox.ciphertext,
                nonce: Data(nonce),
                tag: sealedBox.tag,
                algorithm: .chacha20Poly1305
            )
            
        } catch {
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypt data using ChaCha20-Poly1305
    public func decryptChaCha20Poly1305(_ encryptedData: EncryptedData, using key: SecureKey) throws -> Data {
        guard encryptedData.algorithm == .chacha20Poly1305 else {
            throw EncryptionError.algorithmNotSupported
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key.keyData)
            let nonce = try ChaChaPoly.Nonce(data: encryptedData.nonce)
            
            let sealedBox = try ChaChaPoly.SealedBox(
                nonce: nonce,
                ciphertext: encryptedData.ciphertext,
                tag: encryptedData.tag
            )
            
            return try ChaChaPoly.open(sealedBox, using: symmetricKey)
            
        } catch {
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Hybrid Encryption (RSA + AES)
    
    /// Generate RSA key pair for hybrid encryption
    public func generateRSAKeyPair(keySize: Int = 2048) throws -> (publicKey: SecKey, privateKey: SecKey) {
        let privateKeyAttrs: [String: Any] = [
            kSecAttrIsPermanent as String: false,
            kSecAttrApplicationTag as String: "com.wealthwise.rsa.private".data(using: .utf8) as Any
        ]
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: keySize,
            kSecPrivateKeyAttrs as String: privateKeyAttrs
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw EncryptionError.encryptionFailed(error?.takeRetainedValue().localizedDescription ?? "RSA private key generation failed")
        }
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw EncryptionError.encryptionFailed("Failed to derive RSA public key")
        }
        
        return (publicKey: publicKey, privateKey: privateKey)
    }
    
    /// Hybrid encryption: RSA for key exchange, AES for data
    public func hybridEncrypt(_ data: Data, using publicKey: SecKey) async throws -> HybridEncryptedData {
        // Generate random AES key
        let aesKey = generateRandomKey()
        
        // Encrypt data with AES
        let encryptedData = try await encrypt(data, using: aesKey)
        
        // Encrypt AES key with RSA public key
        let encryptedKey = try encryptRSA(aesKey.keyData, using: publicKey)
        
        return HybridEncryptedData(
            encryptedData: encryptedData,
            encryptedKey: encryptedKey,
            algorithm: .rsaAES256
        )
    }
    
    /// Hybrid decryption: RSA for key exchange, AES for data
    public func hybridDecrypt(_ hybridData: HybridEncryptedData, using privateKey: SecKey) async throws -> Data {
        // Decrypt AES key with RSA private key
        let aesKeyData = try decryptRSA(hybridData.encryptedKey, using: privateKey)
        
        let aesKey = SecureKey(
            keyData: aesKeyData,
            identifier: "hybrid-temp-key",
            algorithm: .aes256,
            keySize: 256
        )
        
        // Decrypt data with AES key
        return try await decrypt(hybridData.encryptedData, using: aesKey)
    }
    
    // MARK: - Private RSA Methods
    
    private func encryptRSA(_ data: Data, using publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionOAEPSHA256,
            data as CFData,
            &error
        ) else {
            throw EncryptionError.encryptionFailed(error?.takeRetainedValue().localizedDescription ?? "RSA encryption failed")
        }
        
        return encryptedData as Data
    }
    
    private func decryptRSA(_ encryptedData: Data, using privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionOAEPSHA256,
            encryptedData as CFData,
            &error
        ) else {
            throw EncryptionError.decryptionFailed(error?.takeRetainedValue().localizedDescription ?? "RSA decryption failed")
        }
        
        return decryptedData as Data
    }
}

// MARK: - Supporting Types

/// Hybrid encrypted data container
public struct HybridEncryptedData: Sendable {
    public let encryptedData: EncryptedData
    public let encryptedKey: Data
    public let algorithm: HybridEncryptionAlgorithm
    public let timestamp: Date
    public let securityLevel: SecurityLevel
    
    public init(encryptedData: EncryptedData, encryptedKey: Data, algorithm: HybridEncryptionAlgorithm, timestamp: Date = Date(), securityLevel: SecurityLevel = .maximum) {
        self.encryptedData = encryptedData
        self.encryptedKey = encryptedKey
        self.algorithm = algorithm
        self.timestamp = timestamp
        self.securityLevel = securityLevel
    }
}

/// Hybrid encryption algorithms
public enum HybridEncryptionAlgorithm: String, CaseIterable, Sendable {
    case rsaAES256 = "rsa-aes256"
    case rsaChaCha20 = "rsa-chacha20"
    case ecdhAES256 = "ecdh-aes256"
    case kyberAES256 = "kyber-aes256"      // Post-quantum hybrid
    case mlkemAES256 = "mlkem-aes256"      // NIST ML-KEM standard
    
    public var displayName: String {
        switch self {
        case .rsaAES256: return "RSA + AES-256-GCM"
        case .rsaChaCha20: return "RSA + ChaCha20-Poly1305"
        case .ecdhAES256: return "ECDH + AES-256-GCM"
        case .kyberAES256: return "Kyber + AES-256-GCM"
        case .mlkemAES256: return "ML-KEM + AES-256-GCM"
        }
    }
}

// MARK: - CommonCrypto Bridging

import CommonCrypto

// Expose CommonCrypto constants for PBKDF2
private let kCCSuccess = Int32(0)
private let kCCPBKDF2 = CCPBKDFAlgorithm(2)
private let kCCPRFHmacAlgSHA256 = CCPseudoRandomAlgorithm(3)

// PBKDF2 function declaration
private func CCKeyDerivationPBKDF_bridge(
    _ algorithm: CCPBKDFAlgorithm,
    _ password: UnsafePointer<Int8>,
    _ passwordLen: Int,
    _ salt: UnsafePointer<UInt8>,
    _ saltLen: Int,
    _ prf: CCPseudoRandomAlgorithm,
    _ rounds: UInt32,
    _ derivedKey: UnsafeMutablePointer<UInt8>,
    _ derivedKeyLen: Int
) -> Int32 {
    // Call through to CommonCrypto's C function
    return CommonCrypto.CCKeyDerivationPBKDF(algorithm, password, passwordLen, salt, saltLen, prf, rounds, derivedKey, derivedKeyLen)
}