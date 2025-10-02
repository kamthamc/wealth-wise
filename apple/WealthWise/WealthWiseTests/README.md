# WealthWise Test Suite Documentation

## Overview
This directory contains comprehensive unit tests, integration tests, and UI tests for the WealthWise application, addressing Issue #10: Testing & Quality Assurance.

## Test Structure

### Unit Tests
Unit tests focus on testing individual components in isolation with mocked dependencies.

#### Security Tests (`SecurityTests/`)
- **EncryptionServiceTests.swift** (52 test cases)
  - AES-256-GCM encryption/decryption
  - Key generation (random and quantum)
  - Key derivation with PBKDF2
  - Salt generation and validation
  - SHA-256 hashing
  - HMAC generation and verification
  - Secure comparison
  - Key caching mechanisms
  - Performance benchmarks

- **BiometricAuthenticationTests.swift** (15 test cases)
  - Biometric availability detection
  - Biometric type identification (Touch ID, Face ID, Optic ID)
  - Authentication state management
  - Error handling
  - Localization support

- **AuthenticationStateTests.swift** (25 test cases)
  - Authentication state transitions
  - Session validity checks
  - Security level management
  - Observable property verification
  - State enum validations

- **SecurityIntegrationTests.swift** (20 test cases)
  - End-to-end encryption workflows
  - Key management with keychain storage
  - Data integrity with HMAC
  - Password-based encryption
  - Key rotation scenarios
  - Batch encryption operations

#### Core Data Tests (`CoreDataTests/`)
- **PersistentContainerTests.swift** (38 test cases)
  - Container initialization and configuration
  - Context management (view and background)
  - Save operations and error handling
  - Fetch requests and queries
  - Merge policies
  - Background task execution
  - Memory management
  - Concurrency handling
  - Performance benchmarks

### Integration Tests
Integration tests verify interactions between multiple components and external systems.

- **SecurityIntegrationTests.swift**
  - Encryption service + Key manager integration
  - Core Data + Encryption integration
  - Authentication flow integration

### UI Tests
UI tests verify critical user flows and accessibility.

#### Critical Flow Tests (`WealthWiseUITests/`)
- **CriticalFlowUITests.swift** (22 test cases)
  - App launch and initialization
  - Dashboard navigation and scrolling
  - Login/authentication flows
  - Add asset form accessibility
  - Security settings access
  - VoiceOver support
  - Accessibility labels
  - Button interactions
  - Text input handling
  - App stability under various actions
  - Background/foreground transitions
  - Data persistence across launches
  - Performance metrics

## Running Tests

### Using Xcode
1. Open `WealthWise.xcodeproj`
2. Select the WealthWise scheme
3. Press `Cmd + U` to run all tests
4. Or use `Cmd + Ctrl + U` to run tests with coverage

### Using Command Line

#### macOS Tests
```bash
cd apple/WealthWise
xcodebuild test \
  -project WealthWise.xcodeproj \
  -scheme WealthWise \
  -destination "platform=macOS" \
  -enableCodeCoverage YES
```

#### iOS Simulator Tests
```bash
cd apple/WealthWise
xcodebuild test \
  -project WealthWise.xcodeproj \
  -scheme WealthWise \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
  -enableCodeCoverage YES
```

### Using VSCode Tasks
- `Test - WealthWise (macOS)` - Run tests on macOS
- `Test - WealthWise (iOS)` - Run tests on iOS Simulator

## Test Coverage

### Coverage Summary
- **Security Tests**: 112 test cases
  - Encryption: 52 tests
  - Biometric: 15 tests
  - Authentication State: 25 tests
  - Security Integration: 20 tests

- **Core Data Tests**: 38 test cases
  - Container management
  - CRUD operations
  - Concurrency handling

- **UI Tests**: 22 test cases
  - Critical user flows
  - Accessibility
  - Performance

**Total**: ~172 comprehensive test cases

### Coverage Goals
- Core business logic: 90%+ coverage
- Security components: 95%+ coverage
- Data persistence: 85%+ coverage
- UI critical flows: 80%+ coverage

## Test Patterns

### Mock Objects
Tests use mock implementations to isolate components:
- `MockSecureKeyManager` - Mock keychain storage
- In-memory Core Data containers - Isolated persistence testing

### Test Organization
Each test file follows this structure:
```swift
// MARK: - Setup/Teardown
// MARK: - [Feature] Tests
// MARK: - Error Handling Tests
// MARK: - Integration Tests
// MARK: - Performance Tests
```

### Naming Conventions
- Test methods: `test[Feature][Scenario]()`
- Example: `testEncryptDecryptData()`
- Example: `testDeriveKeyInvalidSaltSize()`

## Continuous Integration

Tests are automatically run on:
- Every push to main/develop branches
- Every pull request
- Feature branches matching `feature/*`
- Hotfix branches matching `hotfix/*`

See `.github/workflows/test.yml` for CI configuration.

## Test Data

### Sample Data
Tests use realistic sample data:
- Financial amounts in Indian Rupees (₹)
- Unicode characters and emojis
- Multi-language strings
- Large datasets (5MB+) for performance testing

### Security Test Data
- Multiple encryption keys
- Various password strengths
- Salt sizes and iterations
- Biometric scenarios

## Best Practices

### Writing New Tests
1. **Isolation**: Each test should be independent
2. **Coverage**: Test both success and failure paths
3. **Performance**: Use `measure` for performance-critical code
4. **Documentation**: Add comments for complex test scenarios
5. **Localization**: Use `NSLocalizedString` for user-facing strings

### Test Maintenance
1. Update tests when modifying business logic
2. Keep test data realistic and up-to-date
3. Remove obsolete tests
4. Refactor duplicate test code into helper methods

### Debugging Tests
1. Run individual tests to isolate failures
2. Use XCTest breakpoints
3. Check console output for detailed error messages
4. Use Instruments for performance analysis

## Known Issues

### Test Environment Limitations
- Biometric tests may not run in CI without simulator support
- Some UI tests require specific simulator configurations
- Network tests require connectivity or mocking

### Platform-Specific Considerations
- macOS vs iOS differences in biometric availability
- Simulator vs device differences in authentication
- Background task behavior varies by platform

## Future Improvements

### Planned Test Additions
- [ ] Advanced biometric scenarios
- [ ] Network request mocking
- [ ] Database migration tests
- [ ] Stress testing for large datasets
- [ ] Localization verification tests
- [ ] Screenshot tests for UI validation

### Test Infrastructure Enhancements
- [ ] Code coverage reporting in CI
- [ ] Test result dashboards
- [ ] Automated performance regression detection
- [ ] Parallel test execution
- [ ] Test flakiness detection

## Contributing

When adding new tests:
1. Follow existing test patterns
2. Ensure tests are deterministic
3. Add documentation for complex scenarios
4. Update this README if adding new test categories
5. Verify tests pass locally before committing

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Best Practices](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)

## Support

For test-related questions:
- Check existing test files for patterns
- Review Apple's XCTest documentation
- Consult the WealthWise development team
- Open an issue for test infrastructure problems
