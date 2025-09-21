# WealthWise Encryption Analysis

## Overview
This document analyzes encryption options for securing sensitive financial data in WealthWise, with focus on SwiftData persistence layer security.

## Key Requirements
- **FINANCIAL DATA SECURITY**: Protection of transaction amounts, account numbers, personal financial information
- **LOCAL-FIRST**: Encryption must work with offline-first architecture
- **CROSS-PLATFORM**: Solution should work across iOS, macOS, and potentially Android
- **REGULATORY COMPLIANCE**: Meet financial data protection requirements (PCI DSS, GDPR)
- **PERFORMANCE**: Minimal impact on app responsiveness
- **KEY MANAGEMENT**: Secure key storage and rotation

## Encryption Options Analysis

### 1. SwiftData Built-in Security (iOS 17+/macOS 14+)

#### Pros:
- **Native Integration**: Works seamlessly with SwiftData ModelContainer
- **FileProtection**: Automatic encryption when device is locked
- **Keychain Integration**: Secure key storage via iOS/macOS Keychain
- **Zero Configuration**: Default protection with minimal setup
- **App Transport Security**: Built-in secure data handling

#### Cons:
- **Device-Level Only**: Encryption tied to device unlock state
- **Limited Granular Control**: Cannot encrypt specific fields differently
- **iOS/macOS Only**: Not portable to Android

#### Implementation:
```swift
// SwiftData with file protection
let configuration = ModelConfiguration(
    schema: Schema([Asset.self, Portfolio.self, Transaction.self]),
    isStoredInMemoryOnly: false,
    allowsSave: true,
    groupContainer: .none,
    cloudKitDatabase: .none
)

// File protection applied automatically on iOS/macOS
configuration.fileProtection = .complete
```

### 2. SQLCipher Integration

#### Pros:
- **Strong Encryption**: AES-256 encryption for SQLite database
- **Cross-Platform**: Works on iOS, macOS, Android, Windows
- **Granular Control**: Per-column encryption possible
- **Industry Standard**: Widely used in financial applications
- **Key Derivation**: PBKDF2 key strengthening

#### Cons:
- **SwiftData Incompatible**: Requires custom Core Data or SQLite implementation
- **License Cost**: Commercial license required for non-GPL projects
- **Performance Overhead**: 5-15% performance impact
- **Complex Integration**: Manual schema management required

#### Implementation Challenge:
```swift
// Would require abandoning SwiftData for Core Data + SQLCipher
import SQLite3
import SQLCipher

// This breaks our SwiftData architecture
class EncryptedDataService {
    private var db: OpaquePointer?
    
    func openDatabase(password: String) throws {
        sqlite3_open(dbPath, &db)
        sqlite3_key(db, password, Int32(password.count))
    }
}
```

### 3. Hybrid Approach: SwiftData + Field-Level Encryption

#### Pros:
- **Best of Both Worlds**: Keep SwiftData benefits + add encryption
- **Selective Encryption**: Only sensitive fields encrypted
- **Performance Optimized**: Encrypt only what needs protection
- **SwiftData Compatible**: Works within existing architecture

#### Cons:
- **Implementation Complexity**: Custom encryption layer required
- **Key Management**: Need secure key storage strategy
- **Query Limitations**: Cannot query encrypted fields directly

#### Proposed Implementation:
```swift
import CryptoKit
import SwiftData

@Model
class Transaction {
    let id: UUID
    let assetId: UUID?
    let type: TransactionType
    
    // Encrypted sensitive fields
    @Attribute(.encrypt) private var _encryptedAmount: Data
    @Attribute(.encrypt) private var _encryptedNotes: Data?
    
    // Computed properties for transparent encryption
    var amount: Decimal {
        get { decrypt(_encryptedAmount) }
        set { _encryptedAmount = encrypt(newValue) }
    }
    
    var notes: String? {
        get { decryptOptional(_encryptedNotes) }
        set { _encryptedNotes = encryptOptional(newValue) }
    }
}

// Encryption service
class FieldEncryptionService {
    private let key: SymmetricKey
    
    func encrypt<T: Codable>(_ value: T) -> Data {
        let data = try! JSONEncoder().encode(value)
        let sealedBox = try! AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt<T: Codable>(_ data: Data, as type: T.Type) -> T {
        let sealedBox = try! AES.GCM.SealedBox(combined: data)
        let decryptedData = try! AES.GCM.open(sealedBox, using: key)
        return try! JSONDecoder().decode(type, from: decryptedData)
    }
}
```

### 4. Apple CryptoKit + Keychain

#### Pros:
- **Native Apple Framework**: Optimized for iOS/macOS
- **Hardware Security**: Secure Enclave integration
- **Modern Cryptography**: ChaCha20-Poly1305, AES-GCM support
- **Keychain Integration**: Secure key storage
- **Zero Third-Party Dependencies**: Pure Apple stack

#### Cons:
- **iOS/macOS Only**: Not cross-platform
- **Manual Implementation**: Requires custom encryption layer

## Recommended Approach

### Phase 1: SwiftData + CryptoKit (Immediate)
Use Apple's native encryption with SwiftData for maximum compatibility:

```swift
import SwiftData
import CryptoKit
import Security

// Encryption-aware SwiftData models
@Model
class SecureTransaction {
    let id: UUID
    let date: Date
    let category: TransactionCategory
    
    // Store encrypted data as Data
    private var encryptedAmount: Data
    private var encryptedDescription: Data
    
    // Transparent encryption via computed properties
    var amount: Decimal {
        get { CryptoService.shared.decrypt(encryptedAmount, as: Decimal.self) }
        set { encryptedAmount = CryptoService.shared.encrypt(newValue) }
    }
    
    var transactionDescription: String {
        get { CryptoService.shared.decrypt(encryptedDescription, as: String.self) }
        set { encryptedDescription = CryptoService.shared.encrypt(newValue) }
    }
}

// Centralized encryption service
class CryptoService {
    static let shared = CryptoService()
    
    private let key: SymmetricKey
    
    init() {
        // Load or generate key from Keychain
        self.key = loadOrCreateKey()
    }
    
    private func loadOrCreateKey() -> SymmetricKey {
        // Try to load existing key from Keychain
        if let keyData = loadKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key and store in Keychain
        let newKey = SymmetricKey(size: .bits256)
        storeKeyInKeychain(newKey.withUnsafeBytes { Data($0) })
        return newKey
    }
}
```

### Phase 2: Cross-Platform Consideration (Future)
If Android support is needed, evaluate:
- **SQLCipher**: Industry standard but requires Core Data migration
- **Realm Database**: Built-in encryption with cross-platform support
- **Custom Solution**: Shared encryption logic with platform-specific storage

## Security Considerations

### Key Management
1. **Key Generation**: Use CryptoKit.SymmetricKey with 256-bit entropy
2. **Key Storage**: iOS/macOS Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
3. **Key Rotation**: Implement annual key rotation with data re-encryption
4. **Backup Strategy**: Exclude encrypted keys from iCloud/Time Machine backups

### Threat Model
- **Device Theft**: Encrypted data unreadable without device unlock
- **Malware**: App-specific keychain isolation
- **Forensics**: Strong encryption resists offline attacks
- **Data Breach**: Local-only storage reduces attack surface

### Compliance
- **PCI DSS**: Encrypt cardholder data with strong cryptography
- **GDPR**: Encryption as technical safeguard for personal data
- **Financial Regulations**: Meet local data protection requirements

## Implementation Plan

### Step 1: Create Encryption Service
- Implement CryptoService with AES-GCM encryption
- Add Keychain key management
- Create unit tests for encryption/decryption

### Step 2: Update SwiftData Models
- Add encrypted fields to sensitive models
- Implement computed properties for transparent access
- Maintain backwards compatibility during migration

### Step 3: Security Hardening
- Implement key rotation mechanism
- Add biometric authentication for key access
- Create secure backup/restore functionality

### Step 4: Performance Testing
- Benchmark encryption overhead
- Optimize for common operations
- Implement async encryption for large datasets

## Conclusion

**Recommendation**: Implement Phase 1 (SwiftData + CryptoKit) for immediate security needs while maintaining SwiftData benefits. This provides strong encryption for financial data while preserving our modern Swift architecture.

The hybrid approach offers the best balance of:
- ✅ **Security**: AES-256 encryption for sensitive data
- ✅ **Performance**: Selective encryption minimizes overhead  
- ✅ **Compatibility**: Works with existing SwiftData models
- ✅ **Maintainability**: Pure Swift/Apple stack
- ✅ **Compliance**: Meets financial data protection requirements