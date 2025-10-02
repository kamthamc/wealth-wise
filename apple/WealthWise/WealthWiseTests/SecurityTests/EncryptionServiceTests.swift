//
//  EncryptionServiceTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Comprehensive unit tests for EncryptionService - Issue #10
//

import XCTest
import CryptoKit
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class EncryptionServiceTests: XCTestCase {
    
    var encryptionService: EncryptionService!
    var keyManager: MockSecureKeyManager!
    
    override func setUp() async throws {
        try await super.setUp()
        keyManager = MockSecureKeyManager()
        encryptionService = EncryptionService(keyManager: keyManager)
    }
    
    override func tearDown() async throws {
        encryptionService.clearKeyCache()
        encryptionService = nil
        keyManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Key Generation Tests
    
    func testGenerateRandomKey() throws {
        let key = encryptionService.generateRandomKey()
        
        XCTAssertNotNil(key)
        XCTAssertEqual(key.keySize, 256)
        XCTAssertEqual(key.algorithm, .aes256)
        XCTAssertFalse(key.identifier.isEmpty)
        XCTAssertEqual(key.keyData.count, 32) // 256 bits = 32 bytes
    }
    
    func testGenerateRandomKeyWithMaximumSecurityLevel() throws {
        let key = encryptionService.generateRandomKey(securityLevel: .maximum)
        
        XCTAssertEqual(key.securityLevel, .maximum)
        XCTAssertEqual(key.keySize, 256)
        XCTAssertEqual(key.algorithm, .aes256)
    }
    
    func testGenerateRandomKeyWithQuantumSecurityLevel() throws {
        let key = encryptionService.generateRandomKey(securityLevel: .quantum)
        
        XCTAssertEqual(key.securityLevel, .quantum)
        XCTAssertEqual(key.keySize, 512)
        XCTAssertEqual(key.algorithm, .kyber512)
    }
    
    func testGenerateRandomKeyUniqueness() throws {
        let key1 = encryptionService.generateRandomKey()
        let key2 = encryptionService.generateRandomKey()
        
        // Keys should have unique identifiers
        XCTAssertNotEqual(key1.identifier, key2.identifier)
        
        // Key data should be different
        XCTAssertNotEqual(key1.keyData, key2.keyData)
    }
    
    // MARK: - Key Derivation Tests
    
    func testDeriveKeyFromPassword() throws {
        let password = "TestPassword123!@#"
        let salt = encryptionService.generateSalt()
        
        let derivedKey = try encryptionService.deriveKey(
            from: password,
            salt: salt,
            iterations: 10_000
        )
        
        XCTAssertNotNil(derivedKey)
        XCTAssertEqual(derivedKey.keySize, 256)
        XCTAssertEqual(derivedKey.algorithm, .aes256)
        XCTAssertTrue(derivedKey.identifier.contains("derived"))
    }
    
    func testDeriveKeyConsistency() throws {
        let password = "TestPassword123"
        let salt = encryptionService.generateSalt()
        
        let key1 = try encryptionService.deriveKey(from: password, salt: salt, iterations: 10_000)
        let key2 = try encryptionService.deriveKey(from: password, salt: salt, iterations: 10_000)
        
        // Same password and salt should produce same key
        XCTAssertEqual(key1.keyData, key2.keyData)
    }
    
    func testDeriveKeyDifferentPasswords() throws {
        let salt = encryptionService.generateSalt()
        
        let key1 = try encryptionService.deriveKey(from: "Password1", salt: salt, iterations: 10_000)
        let key2 = try encryptionService.deriveKey(from: "Password2", salt: salt, iterations: 10_000)
        
        // Different passwords should produce different keys
        XCTAssertNotEqual(key1.keyData, key2.keyData)
    }
    
    func testDeriveKeyDifferentSalts() throws {
        let password = "TestPassword"
        let salt1 = encryptionService.generateSalt()
        let salt2 = encryptionService.generateSalt()
        
        let key1 = try encryptionService.deriveKey(from: password, salt: salt1, iterations: 10_000)
        let key2 = try encryptionService.deriveKey(from: password, salt: salt2, iterations: 10_000)
        
        // Different salts should produce different keys
        XCTAssertNotEqual(key1.keyData, key2.keyData)
    }
    
    func testDeriveKeyEmptyPassword() throws {
        let salt = encryptionService.generateSalt()
        
        XCTAssertThrowsError(try encryptionService.deriveKey(from: "", salt: salt, iterations: 10_000)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testDeriveKeyInvalidSaltSize() throws {
        let password = "TestPassword"
        let invalidSalt = Data(count: 4) // Too small
        
        XCTAssertThrowsError(try encryptionService.deriveKey(from: password, salt: invalidSalt, iterations: 10_000)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testDeriveKeyInvalidIterations() throws {
        let password = "TestPassword"
        let salt = encryptionService.generateSalt()
        
        XCTAssertThrowsError(try encryptionService.deriveKey(from: password, salt: salt, iterations: 100)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    // MARK: - Encryption/Decryption Tests
    
    func testEncryptDecryptData() async throws {
        let originalData = "Sensitive financial data 💰".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        // Encrypt
        let encryptedData = try await encryptionService.encrypt(originalData, using: key)
        
        XCTAssertNotNil(encryptedData)
        XCTAssertEqual(encryptedData.algorithm, .aes256GCM)
        XCTAssertFalse(encryptedData.ciphertext.isEmpty)
        XCTAssertFalse(encryptedData.nonce.isEmpty)
        XCTAssertFalse(encryptedData.tag.isEmpty)
        
        // Decrypt
        let decryptedData = try await encryptionService.decrypt(encryptedData, using: key)
        
        XCTAssertEqual(decryptedData, originalData)
        
        // Verify original string
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(decryptedString, "Sensitive financial data 💰")
    }
    
    func testEncryptDecryptString() async throws {
        let originalString = "Test financial transaction 🏦"
        let key = encryptionService.generateRandomKey()
        
        let encryptedData = try await encryptionService.encrypt(originalString, using: key)
        let decryptedString = try await encryptionService.decryptToString(encryptedData, using: key)
        
        XCTAssertEqual(decryptedString, originalString)
    }
    
    func testEncryptEmptyData() async throws {
        let emptyData = Data()
        let key = encryptionService.generateRandomKey()
        
        do {
            _ = try await encryptionService.encrypt(emptyData, using: key)
            XCTFail("Should throw error for empty data")
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testDecryptWithWrongKey() async throws {
        let originalData = "Secret data".data(using: .utf8)!
        let correctKey = encryptionService.generateRandomKey()
        let wrongKey = encryptionService.generateRandomKey()
        
        let encryptedData = try await encryptionService.encrypt(originalData, using: correctKey)
        
        do {
            _ = try await encryptionService.decrypt(encryptedData, using: wrongKey)
            XCTFail("Should fail to decrypt with wrong key")
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testEncryptDecryptLargeData() async throws {
        // Create 5MB of data
        let largeData = Data(repeating: 0xAB, count: 5 * 1024 * 1024)
        let key = encryptionService.generateRandomKey()
        
        let encryptedData = try await encryptionService.encryptLargeData(largeData, using: key)
        let decryptedData = try await encryptionService.decryptLargeData(encryptedData, using: key)
        
        XCTAssertEqual(decryptedData, largeData)
    }
    
    // MARK: - Salt Generation Tests
    
    func testGenerateSalt() throws {
        let salt = encryptionService.generateSalt()
        
        XCTAssertNotNil(salt)
        XCTAssertEqual(salt.count, 32) // Default salt size
    }
    
    func testGenerateSaltCustomSize() throws {
        let salt = encryptionService.generateSalt(size: 64)
        
        XCTAssertEqual(salt.count, 64)
    }
    
    func testGenerateSaltUniqueness() throws {
        let salt1 = encryptionService.generateSalt()
        let salt2 = encryptionService.generateSalt()
        
        XCTAssertNotEqual(salt1, salt2)
    }
    
    // MARK: - Hash Tests
    
    func testHashSHA256Data() throws {
        let data = "Test data for hashing".data(using: .utf8)!
        
        let hash = encryptionService.hashSHA256(data)
        
        XCTAssertNotNil(hash)
        XCTAssertEqual(hash.count, 32) // SHA-256 produces 32 bytes
    }
    
    func testHashSHA256String() throws {
        let string = "Test string for hashing"
        
        let hash = encryptionService.hashSHA256(string)
        
        XCTAssertNotNil(hash)
        XCTAssertEqual(hash.count, 32)
    }
    
    func testHashConsistency() throws {
        let data = "Consistent data".data(using: .utf8)!
        
        let hash1 = encryptionService.hashSHA256(data)
        let hash2 = encryptionService.hashSHA256(data)
        
        XCTAssertEqual(hash1, hash2)
    }
    
    func testHashDifferentData() throws {
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!
        
        let hash1 = encryptionService.hashSHA256(data1)
        let hash2 = encryptionService.hashSHA256(data2)
        
        XCTAssertNotEqual(hash1, hash2)
    }
    
    // MARK: - HMAC Tests
    
    func testGenerateHMAC() throws {
        let data = "Data for HMAC".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        let hmac = encryptionService.generateHMAC(data, key: key)
        
        XCTAssertNotNil(hmac)
        XCTAssertEqual(hmac.count, 32) // HMAC-SHA256 produces 32 bytes
    }
    
    func testVerifyHMAC() throws {
        let data = "Data for HMAC verification".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        let hmac = encryptionService.generateHMAC(data, key: key)
        let isValid = encryptionService.verifyHMAC(data, hmac: hmac, key: key)
        
        XCTAssertTrue(isValid)
    }
    
    func testVerifyHMACInvalidData() throws {
        let originalData = "Original data".data(using: .utf8)!
        let tamperedData = "Tampered data".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        let hmac = encryptionService.generateHMAC(originalData, key: key)
        let isValid = encryptionService.verifyHMAC(tamperedData, hmac: hmac, key: key)
        
        XCTAssertFalse(isValid)
    }
    
    func testVerifyHMACInvalidKey() throws {
        let data = "Data for HMAC".data(using: .utf8)!
        let correctKey = encryptionService.generateRandomKey()
        let wrongKey = encryptionService.generateRandomKey()
        
        let hmac = encryptionService.generateHMAC(data, key: correctKey)
        let isValid = encryptionService.verifyHMAC(data, hmac: hmac, key: wrongKey)
        
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Secure Compare Tests
    
    func testSecureCompareEqual() throws {
        let data1 = Data([1, 2, 3, 4, 5])
        let data2 = Data([1, 2, 3, 4, 5])
        
        let result = encryptionService.secureCompare(data1, data2)
        
        XCTAssertTrue(result)
    }
    
    func testSecureCompareNotEqual() throws {
        let data1 = Data([1, 2, 3, 4, 5])
        let data2 = Data([1, 2, 3, 4, 6])
        
        let result = encryptionService.secureCompare(data1, data2)
        
        XCTAssertFalse(result)
    }
    
    func testSecureCompareDifferentLengths() throws {
        let data1 = Data([1, 2, 3])
        let data2 = Data([1, 2, 3, 4])
        
        let result = encryptionService.secureCompare(data1, data2)
        
        XCTAssertFalse(result)
    }
    
    // MARK: - Key Caching Tests
    
    func testCacheKey() throws {
        let key = encryptionService.generateRandomKey()
        let identifier = "test-key-id"
        
        encryptionService.cacheKey(key, identifier: identifier)
        
        // Allow time for async cache operation
        let expectation = XCTestExpectation(description: "Key cached")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let cachedKey = encryptionService.getCachedKey(identifier: identifier)
        
        XCTAssertNotNil(cachedKey)
        XCTAssertEqual(cachedKey?.identifier, key.identifier)
    }
    
    func testGetCachedKeyNotFound() throws {
        let cachedKey = encryptionService.getCachedKey(identifier: "non-existent")
        
        XCTAssertNil(cachedKey)
    }
    
    func testClearCachedKey() throws {
        let key = encryptionService.generateRandomKey()
        let identifier = "test-key-id"
        
        encryptionService.cacheKey(key, identifier: identifier)
        
        let expectation = XCTestExpectation(description: "Key cached and cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.encryptionService.clearCachedKey(identifier: identifier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
        
        let cachedKey = encryptionService.getCachedKey(identifier: identifier)
        XCTAssertNil(cachedKey)
    }
    
    func testClearKeyCache() throws {
        let key1 = encryptionService.generateRandomKey()
        let key2 = encryptionService.generateRandomKey()
        
        encryptionService.cacheKey(key1, identifier: "key1")
        encryptionService.cacheKey(key2, identifier: "key2")
        
        let expectation = XCTestExpectation(description: "Cache cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.encryptionService.clearKeyCache()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNil(encryptionService.getCachedKey(identifier: "key1"))
        XCTAssertNil(encryptionService.getCachedKey(identifier: "key2"))
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() throws {
        let data = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB
        let key = encryptionService.generateRandomKey()
        
        measure {
            Task {
                _ = try? await encryptionService.encrypt(data, using: key)
            }
        }
    }
    
    func testKeyGenerationPerformance() throws {
        measure {
            _ = encryptionService.generateRandomKey()
        }
    }
    
    func testKeyDerivationPerformance() throws {
        let password = "TestPassword123"
        let salt = encryptionService.generateSalt()
        
        measure {
            _ = try? encryptionService.deriveKey(from: password, salt: salt, iterations: 10_000)
        }
    }
}

// MARK: - Mock Secure Key Manager

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class MockSecureKeyManager: SecureKeyManagementProtocol {
    var storedKeys: [String: SecureKey] = [:]
    
    func storeKey(_ key: SecureKey, identifier: String) async throws {
        storedKeys[identifier] = key
    }
    
    func retrieveKey(identifier: String) async throws -> SecureKey {
        guard let key = storedKeys[identifier] else {
            throw EncryptionError.keyNotFound
        }
        return key
    }
    
    func deleteKey(identifier: String) async throws {
        storedKeys.removeValue(forKey: identifier)
    }
    
    func keyExists(identifier: String) async -> Bool {
        return storedKeys[identifier] != nil
    }
    
    func listKeys() async throws -> [String] {
        return Array(storedKeys.keys)
    }
}
