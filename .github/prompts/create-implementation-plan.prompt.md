---
mode: 'agent'
description: 'Create comprehensive implementation plans for cross-platform features with security-first design (iOS/Swift, Android/Kotlin, Windows/.NET)'
tools: ['semantic_search', 'grep_search', 'read_file', 'list_code_usages', 'get_errors', 'mcp_github_list_issues', 'mcp_github_get_issue', 'mcp_github_create_issue', 'fetch_webpage', 'github_repo', 'run_in_terminal']
---

# Create Cross-Platform Implementation Plan

## Primary Directive

Your goal is to create a new implementation plan file for `${input:FeatureName}`. Your output must be machine-readable, deterministic, and structured for autonomous execution by other AI systems or humans working on cross-platform applications (iOS/Swift, Android/Kotlin, Windows/.NET).

## Cross-Platform Context

This prompt is designed for implementing secure, cross-platform features with:
- Platform-appropriate encryption for all sensitive data
- Modern concurrency patterns for each platform
- Platform-native UI frameworks with latest features
- Advanced effects where platform-supported
- Comprehensive testing for accuracy and security

## Core Requirements

- Generate implementation plans that prioritize data security
- Use modern concurrency patterns appropriate for each platform
- Structure all content for automated parsing and execution by GitHub Copilot
- Ensure complete compliance with data protection standards
- Include comprehensive testing strategies for accuracy and reliability

## Cross-Platform Plan Structure Requirements

Plans must consist of discrete, atomic phases containing executable tasks focused on:
- **Security Phase**: Encryption, authentication, and key management implementation
- **Data Phase**: Data models with encryption attributes and precision requirements
- **Service Phase**: Service-based architecture with protocol-oriented design
- **UI Phase**: Platform-native UI components with accessibility and modern features
- **Testing Phase**: Comprehensive unit, integration, and security testing

## Phase Architecture

- Each phase must have measurable security and functionality completion criteria
- Tasks within phases must be executable in parallel unless dependencies are specified
- All task descriptions must include specific Swift file paths, protocol names, and exact implementation details
- Security tasks must include encryption verification and authentication testing
- Financial calculation tasks must specify Decimal precision requirements

## Swift 6 & Security Implementation Standards

- Use explicit actor isolation for financial service operations
- Structure all financial data models with encryption attributes
- Include specific Core Data schema definitions with @Attribute(.encrypt)
- Define all SwiftUI availability requirements (@available annotations)
- Provide complete actor-based service implementations
- Use standardized prefixes: SEC- (security), FIN- (financial), UI- (user interface), TEST- (testing)
- Include biometric authentication validation criteria

## Output File Specifications

- Save implementation plan files in `/docs/plans/` directory
- Use naming convention: `[purpose]-[feature]-[version].md`
- Purpose prefixes: `security|financial|ui|platform|integration|migration`
- Example: `security-encryption-service-1.md`, `financial-transaction-model-2.md`
- File must be valid Markdown with proper front matter structure

## WealthWise Template Structure

All implementation plans must strictly adhere to the following WealthWise-specific template:

```md
---
goal: [Concise Title Describing the WealthWise Feature Implementation Plan's Goal]
version: [e.g., 1.0, Date]
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
owner: [Team/Individual responsible for this feature]
status: 'Completed'|'In progress'|'Planned'|'Deprecated'|'On Hold'
tags: [List of relevant tags: `security`, `financial`, `swift6`, `ios`, `macos`, `encryption`, `ui`, etc.]
platform_requirements:
  ios_min: "18.6"
  macos_min: "15.6"
  swift_version: "6.0"
security_level: "high|critical"
financial_accuracy: "required"
---

# WealthWise Feature Implementation: [Feature Name]

![Status: <status>](https://img.shields.io/badge/status-<status>-<status_color>)
![Security](https://img.shields.io/badge/security-AES--256--GCM-brightgreen)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![iOS](https://img.shields.io/badge/iOS-18.6+-blue)
![macOS](https://img.shields.io/badge/macOS-15.6+-blue)

[A concise introduction to the financial feature and its security/business value]

## 1. Security & Financial Requirements

### Security Requirements
- **SEC-001**: All financial data encrypted with AES-256-GCM at rest
- **SEC-002**: Biometric authentication for sensitive operations
- **SEC-003**: Keychain integration for credential storage
- **SEC-004**: Secure key rotation every 90 days

### Financial Requirements  
- **FIN-001**: Use Decimal for all currency calculations (no Float/Double)
- **FIN-002**: Support Indian financial year (April-March)
- **FIN-003**: Handle multiple currency formats with proper rounding
- **FIN-004**: Transaction categorization with privacy-preserving logic

### Platform Requirements
- **PLT-001**: iOS 18.6+ with modern SwiftUI features
- **PLT-002**: macOS 15.6+ with menu bar integration
- **PLT-003**: Glass effects available only on iOS 26+/macOS 26+
- **PLT-004**: Full accessibility compliance (VoiceOver, Dynamic Type)

### Swift 6 Requirements
- **SW6-001**: Strict concurrency checking enabled
- **SW6-002**: Actor isolation for all financial services
- **SW6-003**: Typed throws for comprehensive error handling
- **SW6-004**: Sendable protocol compliance for data models

## 2. Implementation Steps

### Security Implementation Phase

**GOAL-001**: Implement comprehensive encryption and authentication foundation

| Task | Description | Security Validation | Completed | Date |
|------|-------------|-------------------|-----------|------|
| SEC-TASK-001 | Implement AES-256-GCM EncryptionService actor | Encryption/decryption unit tests | | |
| SEC-TASK-002 | Create BiometricAuthenticationManager | Face ID/Touch ID validation | | |
| SEC-TASK-003 | Implement SecureKeyManager with Keychain | Key storage/retrieval tests | | |
| SEC-TASK-004 | Add key rotation mechanism | Automated rotation testing | | |

### Financial Data Phase

**GOAL-002**: Create secure, encrypted financial data models with Core Data

| Task | Description | Financial Accuracy | Completed | Date |
|------|-------------|------------------|-----------|------|
| FIN-TASK-001 | Define Transaction model with @Attribute(.encrypt) | Decimal precision testing | | |
| FIN-TASK-002 | Create Account model with encrypted balance | Currency conversion accuracy | | |
| FIN-TASK-003 | Implement Category model with privacy protection | Categorization logic testing | | |
| FIN-TASK-004 | Add Budget model with encrypted limits | Financial calculations validation | | |

### Service Layer Phase

**GOAL-003**: Implement actor-based financial services with protocol-oriented design

| Task | Description | Concurrency Testing | Completed | Date |
|------|-------------|-------------------|-----------|------|
| SVC-TASK-001 | Create platform-appropriate service actor | Isolation verification | | |
| SVC-TASK-002 | Implement service protocol interface | Concurrent operation testing | | |
| SVC-TASK-003 | Create service with calculations | Precision validation | | |
| SVC-TASK-004 | Add analysis service | Performance benchmarking | | |

### UI Implementation Phase

**GOAL-004**: Build modern platform-native interfaces

| Task | Description | Platform Testing | Completed | Date |
|------|-------------|-----------------|-----------|------|
| UI-TASK-001 | Create data list view with platform patterns | Platform UI testing | | |
| UI-TASK-002 | Implement authentication view with biometrics | Authentication flow testing | | |
| UI-TASK-003 | Add dashboard with modern effects | Visual effects validation | | |
| UI-TASK-004 | Create accessibility-compliant navigation | Platform accessibility testing | | |

### Testing & Validation Phase

**GOAL-005**: Comprehensive testing for security, accuracy, and platform compatibility

| Task | Description | Success Criteria | Completed | Date |
|------|-------------|-----------------|-----------|------|
| TEST-TASK-001 | Unit tests for encryption/decryption | 100% code coverage | | |
| TEST-TASK-002 | Financial calculation accuracy tests | Decimal precision validation | | |
| TEST-TASK-003 | UI automation tests for critical flows | All user stories verified | | |
| TEST-TASK-004 | Security penetration testing | No vulnerabilities found | | |

## 3. Alternatives Considered

- **ALT-001**: Manual encryption vs platform-native secure storage
  - *Decision*: Platform-native for better integration and security
- **ALT-002**: Floating point vs precise arithmetic for calculations
  - *Decision*: Precise arithmetic for accuracy requirements
- **ALT-003**: Reactive vs modern async patterns
  - *Decision*: Modern async patterns for better concurrency

## 4. Dependencies

- **DEP-001**: Platform-appropriate encryption framework
- **DEP-002**: Platform authentication framework for biometrics
- **DEP-003**: Platform secure storage framework
- **DEP-004**: Platform data persistence framework

## 5. Files Affected

### New Files
- **FILE-001**: Platform-specific data models with encryption
- **FILE-002**: Platform encryption service implementation
- **FILE-003**: Platform service with modern concurrency
- **FILE-004**: `/Shared/Views/TransactionListView.swift` - Modern SwiftUI list

### Modified Files
- **FILE-005**: `/Shared/DependencyInjection/ServiceContainer.swift` - Register new services
- **FILE-006**: `/iOS/WealthWiseApp.swift` - Add encryption initialization
- **FILE-007**: `/macOS/WealthWiseMacApp.swift` - Add macOS-specific setup

## 6. Testing Strategy

### Unit Testing
- **TEST-001**: EncryptionService encrypt/decrypt operations
- **TEST-002**: Financial calculations with Decimal precision
- **TEST-003**: Actor isolation and concurrency safety
- **TEST-004**: Error handling with typed throws

### Integration Testing
- **TEST-005**: End-to-end transaction creation and encryption
- **TEST-006**: Biometric authentication flow integration
- **TEST-007**: Core Data persistence with encryption
- **TEST-008**: Cross-platform UI consistency

### Security Testing
- **TEST-009**: Encryption key security and rotation
- **TEST-010**: Biometric authentication bypass prevention
- **TEST-011**: Memory dump analysis for sensitive data
- **TEST-012**: Network traffic encryption validation

## 7. Risks & Mitigation

### Security Risks
- **RISK-001**: Encryption key compromise
  - *Mitigation*: Hardware Security Module integration, regular key rotation
- **RISK-002**: Biometric authentication bypass
  - *Mitigation*: Fallback to device passcode, audit logging

### Technical Risks
- **RISK-003**: Swift 6 migration complexity
  - *Mitigation*: Incremental migration, comprehensive testing
- **RISK-004**: Performance impact of encryption
  - *Mitigation*: Background queue processing, caching strategies

### Financial Risks
- **RISK-005**: Currency calculation precision errors
  - *Mitigation*: Decimal usage, comprehensive unit testing, validation rules

## 8. Success Criteria

- [ ] All financial data encrypted with AES-256-GCM
- [ ] Biometric authentication functional on all supported devices
- [ ] Modern concurrency compliance achieved
- [ ] Calculations accurate to required precision
- [ ] Latest platform compatibility verified
- [ ] Advanced effects working where platform-supported
- [ ] 100% unit test coverage for critical operations
- [ ] Accessibility compliance validated
- [ ] Performance benchmarks met for all operations

## 9. Related Documentation

- [Cross-Platform Instructions](../copilot-instructions.md)
- [Apple Development Guidelines](../instructions/apple.instructions.md)
- [Android Development Guidelines](../instructions/android.instructions.md)
- [Windows Development Guidelines](../instructions/windows.instructions.md)
```

This template ensures comprehensive planning for secure, Swift 6-compliant financial features with proper testing and validation strategies.