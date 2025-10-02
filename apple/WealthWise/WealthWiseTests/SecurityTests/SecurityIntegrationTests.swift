//
//  SecurityIntegrationTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Integration tests for security and encryption with Core Data - Issue #10
//

import XCTest
import CoreData
import CryptoKit
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class SecurityIntegrationTests: XCTestCase {
    
    var encryptionService: EncryptionService!
    var keyManager: MockSecureKeyManager!
    var testContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup encryption service
        keyManager = MockSecureKeyManager()
        encryptionService = EncryptionService(keyManager: keyManager)
        
        // Setup test Core Data container
        testContainer = NSPersistentContainer(name: "WealthWiseDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]
        
        let expectation = XCTestExpectation(description: "Load stores")
        testContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load stores: \(error)")
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        testContext = testContainer.viewContext
    }
    
    override func tearDown() async throws {
        encryptionService.clearKeyCache()
        encryptionService = nil
        keyManager = nil
        testContext = nil
        testContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - End-to-End Encryption Tests
    
    func testEncryptDataAndStoreInKeychain() async throws {
        let sensitiveData = "Bank Account: 1234-5678-9012 💳".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        // Encrypt data
        let encryptedData = try await encryptionService.encrypt(sensitiveData, using: key)
        
        // Store key in keychain (mock)
        try await keyManager.storeKey(key, identifier: "test-bank-key")
        
        // Retrieve key
        let retrievedKey = try await keyManager.retrieveKey(identifier: "test-bank-key")
        
        // Decrypt data
        let decryptedData = try await encryptionService.decrypt(encryptedData, using: retrievedKey)
        
        XCTAssertEqual(decryptedData, sensitiveData)
        
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(decryptedString, "Bank Account: 1234-5678-9012 💳")
    }
    
    func testEncryptMultipleFieldsWithDifferentKeys() async throws {
        let accountNumber = "123456789"
        let cardNumber = "4532-1234-5678-9010"
        let ssn = "123-45-6789"
        
        let key1 = encryptionService.generateRandomKey()
        let key2 = encryptionService.generateRandomKey()
        let key3 = encryptionService.generateRandomKey()
        
        // Encrypt each field with different keys
        let encryptedAccount = try await encryptionService.encrypt(accountNumber, using: key1)
        let encryptedCard = try await encryptionService.encrypt(cardNumber, using: key2)
        let encryptedSSN = try await encryptionService.encrypt(ssn, using: key3)
        
        // Decrypt and verify
        let decryptedAccount = try await encryptionService.decryptToString(encryptedAccount, using: key1)
        let decryptedCard = try await encryptionService.decryptToString(encryptedCard, using: key2)
        let decryptedSSN = try await encryptionService.decryptToString(encryptedSSN, using: key3)
        
        XCTAssertEqual(decryptedAccount, accountNumber)
        XCTAssertEqual(decryptedCard, cardNumber)
        XCTAssertEqual(decryptedSSN, ssn)
    }
    
    // MARK: - Key Rotation Tests
    
    func testKeyRotation() async throws {
        let originalData = "Financial data before rotation".data(using: .utf8)!
        let oldKey = encryptionService.generateRandomKey()
        let newKey = encryptionService.generateRandomKey()
        
        // Encrypt with old key
        let encryptedWithOldKey = try await encryptionService.encrypt(originalData, using: oldKey)
        
        // Decrypt with old key
        let decryptedData = try await encryptionService.decrypt(encryptedWithOldKey, using: oldKey)
        
        // Re-encrypt with new key
        let encryptedWithNewKey = try await encryptionService.encrypt(decryptedData, using: newKey)
        
        // Verify decryption with new key
        let finalData = try await encryptionService.decrypt(encryptedWithNewKey, using: newKey)
        
        XCTAssertEqual(finalData, originalData)
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityWithHMAC() async throws {
        let data = "Transaction: ₹50,000 transfer".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        // Encrypt data
        let encryptedData = try await encryptionService.encrypt(data, using: key)
        
        // Generate HMAC for integrity
        let combinedData = encryptedData.ciphertext + encryptedData.nonce + encryptedData.tag
        let hmac = encryptionService.generateHMAC(combinedData, key: key)
        
        // Verify HMAC
        let isValid = encryptionService.verifyHMAC(combinedData, hmac: hmac, key: key)
        XCTAssertTrue(isValid)
        
        // Tamper with data
        var tamperedData = combinedData
        tamperedData[0] ^= 0xFF
        
        // Verify tampered data fails
        let isTamperedValid = encryptionService.verifyHMAC(tamperedData, hmac: hmac, key: key)
        XCTAssertFalse(isTamperedValid)
    }
    
    func testEncryptedDataAuthenticity() async throws {
        let data = "Authenticated financial data".data(using: .utf8)!
        let key = encryptionService.generateRandomKey()
        
        // Encrypt (AES-GCM provides authentication)
        let encryptedData = try await encryptionService.encrypt(data, using: key)
        
        // Tamper with ciphertext
        var tamperedEncrypted = encryptedData
        var tamperedCiphertext = tamperedEncrypted.ciphertext
        tamperedCiphertext[0] ^= 0xFF
        tamperedEncrypted.ciphertext = tamperedCiphertext
        
        // Decryption should fail due to authentication failure
        do {
            _ = try await encryptionService.decrypt(tamperedEncrypted, using: key)
            XCTFail("Should fail to decrypt tampered data")
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    // MARK: - Password-Based Encryption Tests
    
    func testPasswordBasedEncryption() async throws {
        let password = "SecurePassword123!@#"
        let data = "User sensitive data".data(using: .utf8)!
        let salt = encryptionService.generateSalt()
        
        // Derive key from password
        let key = try encryptionService.deriveKey(from: password, salt: salt, iterations: 10_000)
        
        // Encrypt data
        let encryptedData = try await encryptionService.encrypt(data, using: key)
        
        // Store salt (would be stored unencrypted)
        XCTAssertNotNil(salt)
        
        // Simulate user entering password again
        let derivedKey2 = try encryptionService.deriveKey(from: password, salt: salt, iterations: 10_000)
        
        // Decrypt data
        let decryptedData = try await encryptionService.decrypt(encryptedData, using: derivedKey2)
        
        XCTAssertEqual(decryptedData, data)
    }
    
    func testPasswordBasedEncryptionWrongPassword() async throws {
        let correctPassword = "CorrectPassword123"
        let wrongPassword = "WrongPassword456"
        let data = "Protected data".data(using: .utf8)!
        let salt = encryptionService.generateSalt()
        
        // Derive key and encrypt
        let correctKey = try encryptionService.deriveKey(from: correctPassword, salt: salt, iterations: 10_000)
        let encryptedData = try await encryptionService.encrypt(data, using: correctKey)
        
        // Try to decrypt with wrong password
        let wrongKey = try encryptionService.deriveKey(from: wrongPassword, salt: salt, iterations: 10_000)
        
        do {
            _ = try await encryptionService.decrypt(encryptedData, using: wrongKey)
            XCTFail("Should fail with wrong password")
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    // MARK: - Secure Storage Integration Tests
    
    func testStoreAndRetrieveEncryptedData() async throws {
        let sensitiveInfo = "Credit Card: 4532-****-****-9010"
        let key = encryptionService.generateRandomKey()
        
        // Encrypt
        let encryptedData = try await encryptionService.encrypt(sensitiveInfo, using: key)
        
        // Store key identifier and encrypted data
        let keyIdentifier = "card-key-\(UUID().uuidString)"
        try await keyManager.storeKey(key, identifier: keyIdentifier)
        
        // Simulate app restart - retrieve key and decrypt
        let retrievedKey = try await keyManager.retrieveKey(identifier: keyIdentifier)
        let decryptedInfo = try await encryptionService.decryptToString(encryptedData, using: retrievedKey)
        
        XCTAssertEqual(decryptedInfo, sensitiveInfo)
    }
    
    func testDeleteSecureKey() async throws {
        let key = encryptionService.generateRandomKey()
        let identifier = "temp-key"
        
        // Store key
        try await keyManager.storeKey(key, identifier: identifier)
        
        // Verify key exists
        let exists1 = await keyManager.keyExists(identifier: identifier)
        XCTAssertTrue(exists1)
        
        // Delete key
        try await keyManager.deleteKey(identifier: identifier)
        
        // Verify key no longer exists
        let exists2 = await keyManager.keyExists(identifier: identifier)
        XCTAssertFalse(exists2)
        
        // Try to retrieve deleted key
        do {
            _ = try await keyManager.retrieveKey(identifier: identifier)
            XCTFail("Should fail to retrieve deleted key")
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    // MARK: - Batch Encryption Tests
    
    func testBatchEncryptionOfMultipleRecords() async throws {
        let records = [
            "Transaction 1: ₹1000",
            "Transaction 2: ₹2000",
            "Transaction 3: ₹3000",
            "Transaction 4: ₹4000",
            "Transaction 5: ₹5000"
        ]
        
        let key = encryptionService.generateRandomKey()
        var encryptedRecords: [EncryptedData] = []
        
        // Encrypt all records
        for record in records {
            let encrypted = try await encryptionService.encrypt(record, using: key)
            encryptedRecords.append(encrypted)
        }
        
        XCTAssertEqual(encryptedRecords.count, records.count)
        
        // Decrypt and verify
        for (index, encryptedRecord) in encryptedRecords.enumerated() {
            let decrypted = try await encryptionService.decryptToString(encryptedRecord, using: key)
            XCTAssertEqual(decrypted, records[index])
        }
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformanceWithLargeDataset() async throws {
        let key = encryptionService.generateRandomKey()
        let data = Data(repeating: 0xAB, count: 10 * 1024 * 1024) // 10MB
        
        let startTime = Date()
        
        let encrypted = try await encryptionService.encryptLargeData(data, using: key)
        let decrypted = try await encryptionService.decryptLargeData(encrypted, using: key)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertEqual(decrypted, data)
        print("Encryption/Decryption of 10MB took \(duration) seconds")
        
        // Should complete within reasonable time (adjust as needed)
        XCTAssertLessThan(duration, 10.0)
    }
    
    // MARK: - Key Management Integration Tests
    
    func testListAllStoredKeys() async throws {
        let key1 = encryptionService.generateRandomKey()
        let key2 = encryptionService.generateRandomKey()
        let key3 = encryptionService.generateRandomKey()
        
        try await keyManager.storeKey(key1, identifier: "key1")
        try await keyManager.storeKey(key2, identifier: "key2")
        try await keyManager.storeKey(key3, identifier: "key3")
        
        let keys = try await keyManager.listKeys()
        
        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("key1"))
        XCTAssertTrue(keys.contains("key2"))
        XCTAssertTrue(keys.contains("key3"))
    }
    
    func testKeyExistsCheck() async throws {
        let key = encryptionService.generateRandomKey()
        let identifier = "existence-test-key"
        
        // Key should not exist initially
        let existsBefore = await keyManager.keyExists(identifier: identifier)
        XCTAssertFalse(existsBefore)
        
        // Store key
        try await keyManager.storeKey(key, identifier: identifier)
        
        // Key should exist now
        let existsAfter = await keyManager.keyExists(identifier: identifier)
        XCTAssertTrue(existsAfter)
    }
}
