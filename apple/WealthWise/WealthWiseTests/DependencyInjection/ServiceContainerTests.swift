//
//  ServiceContainerTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Service Container Tests
//

import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class ServiceContainerTests: XCTestCase {
    
    var container: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        container = ServiceContainer.shared
        container.reset()
    }
    
    override func tearDown() {
        container.reset()
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testRegisterSingletonService() {
        // Given
        let expectedValue = "TestService"
        
        // When
        container.register(TestServiceProtocol.self) {
            TestService(value: expectedValue)
        }
        
        // Then
        XCTAssertTrue(container.isRegistered(TestServiceProtocol.self))
    }
    
    func testRegisterTransientService() {
        // Given
        container.register(TestServiceProtocol.self, scope: .transient) {
            TestService(value: "Transient")
        }
        
        // When
        let instance1 = try? container.resolve(TestServiceProtocol.self)
        let instance2 = try? container.resolve(TestServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(instance1)
        XCTAssertNotNil(instance2)
        XCTAssertNotIdentical(instance1 as AnyObject, instance2 as AnyObject)
    }
    
    func testRegisterInstance() {
        // Given
        let instance = TestService(value: "Instance")
        
        // When
        container.registerInstance(TestServiceProtocol.self, instance: instance)
        
        // Then
        XCTAssertTrue(container.isRegistered(TestServiceProtocol.self))
        let resolved = try? container.resolve(TestServiceProtocol.self)
        XCTAssertIdentical(resolved as AnyObject, instance as AnyObject)
    }
    
    // MARK: - Resolution Tests
    
    func testResolveRegisteredService() throws {
        // Given
        container.register(TestServiceProtocol.self) {
            TestService(value: "Test")
        }
        
        // When
        let service = try container.resolve(TestServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service.value, "Test")
    }
    
    func testResolveUnregisteredServiceThrowsError() {
        // When/Then
        XCTAssertThrowsError(try container.resolve(TestServiceProtocol.self)) { error in
            XCTAssertTrue(error is ServiceContainerError)
            if case ServiceContainerError.serviceNotRegistered = error {
                // Expected error
            } else {
                XCTFail("Expected serviceNotRegistered error")
            }
        }
    }
    
    func testResolveOptionalReturnsNilForUnregistered() {
        // When
        let service = container.resolveOptional(TestServiceProtocol.self)
        
        // Then
        XCTAssertNil(service)
    }
    
    func testResolveOptionalReturnsServiceForRegistered() {
        // Given
        container.register(TestServiceProtocol.self) {
            TestService(value: "Optional")
        }
        
        // When
        let service = container.resolveOptional(TestServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.value, "Optional")
    }
    
    // MARK: - Singleton Behavior Tests
    
    func testSingletonReturnsSameInstance() throws {
        // Given
        container.register(TestServiceProtocol.self, scope: .singleton) {
            TestService(value: "Singleton")
        }
        
        // When
        let instance1 = try container.resolve(TestServiceProtocol.self)
        let instance2 = try container.resolve(TestServiceProtocol.self)
        
        // Then
        XCTAssertIdentical(instance1 as AnyObject, instance2 as AnyObject)
    }
    
    // MARK: - Lifecycle Tests
    
    func testResetClearsAllRegistrations() {
        // Given
        container.register(TestServiceProtocol.self) {
            TestService(value: "Test")
        }
        
        // When
        container.reset()
        
        // Then
        XCTAssertFalse(container.isRegistered(TestServiceProtocol.self))
    }
    
    func testUnregisterRemovesSpecificService() {
        // Given
        container.register(TestServiceProtocol.self) {
            TestService(value: "Test")
        }
        
        // When
        container.unregister(TestServiceProtocol.self)
        
        // Then
        XCTAssertFalse(container.isRegistered(TestServiceProtocol.self))
    }
    
    func testGetScopeReturnsCorrectScope() {
        // Given
        container.register(TestServiceProtocol.self, scope: .transient) {
            TestService(value: "Test")
        }
        
        // When
        let scope = container.getScope(TestServiceProtocol.self)
        
        // Then
        XCTAssertEqual(scope, .transient)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentRegistrationAndResolution() {
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 100
        
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<100 {
            queue.async {
                self.container.register(TestServiceProtocol.self, scope: .singleton) {
                    TestService(value: "Test\(i)")
                }
                
                _ = try? self.container.resolve(TestServiceProtocol.self)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Service Scope Tests
    
    func testServiceScopeEquality() {
        XCTAssertEqual(ServiceScope.singleton, ServiceScope.singleton)
        XCTAssertEqual(ServiceScope.transient, ServiceScope.transient)
        XCTAssertEqual(ServiceScope.scoped, ServiceScope.scoped)
        XCTAssertNotEqual(ServiceScope.singleton, ServiceScope.transient)
    }
    
    // MARK: - Error Tests
    
    func testServiceContainerErrorDescription() {
        let notRegisteredError = ServiceContainerError.serviceNotRegistered("TestService")
        XCTAssertNotNil(notRegisteredError.errorDescription)
        
        let typeMismatchError = ServiceContainerError.typeMismatch(expected: "TypeA", actual: "TypeB")
        XCTAssertNotNil(typeMismatchError.errorDescription)
        
        let circularError = ServiceContainerError.circularDependency("Service")
        XCTAssertNotNil(circularError.errorDescription)
        
        let initError = ServiceContainerError.initializationFailed("Service")
        XCTAssertNotNil(initError.errorDescription)
    }
    
    // MARK: - Performance Tests
    
    func testRegistrationPerformance() {
        measure {
            for i in 0..<1000 {
                container.register(TestServiceProtocol.self, scope: .transient) {
                    TestService(value: "Test\(i)")
                }
            }
            container.reset()
        }
    }
    
    func testResolutionPerformance() {
        container.register(TestServiceProtocol.self) {
            TestService(value: "Performance")
        }
        
        measure {
            for _ in 0..<1000 {
                _ = try? container.resolve(TestServiceProtocol.self)
            }
        }
    }
}

// MARK: - Test Helpers

protocol TestServiceProtocol: AnyObject {
    var value: String { get }
}

class TestService: TestServiceProtocol {
    let value: String
    
    init(value: String) {
        self.value = value
    }
}

extension ServiceScope: Equatable {
    public static func == (lhs: ServiceScope, rhs: ServiceScope) -> Bool {
        switch (lhs, rhs) {
        case (.singleton, .singleton),
             (.transient, .transient),
             (.scoped, .scoped):
            return true
        default:
            return false
        }
    }
}
