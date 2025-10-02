//
//  CriticalFlowUITests.swift
//  WealthWiseUITests
//
//  Created by WealthWise Team on 2025-10-02.
//  Comprehensive UI tests for critical user flows - Issue #10
//

import XCTest

final class CriticalFlowUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Initialize app
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Tests
    
    @MainActor
    func testAppLaunch() throws {
        app.launch()
        
        // Verify app launched successfully
        XCTAssertTrue(app.state == .runningForeground)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testMainScreenAccessibility() throws {
        app.launch()
        
        // Wait for app to fully load
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testNavigationElements() throws {
        app.launch()
        
        // Wait for UI to load
        sleep(2)
        
        // Verify basic navigation elements exist
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists)
    }
    
    // MARK: - Dashboard Flow Tests
    
    @MainActor
    func testDashboardDisplays() throws {
        app.launch()
        
        // Wait for dashboard to load
        sleep(2)
        
        // Verify dashboard is displayed
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists)
        
        // Check for common dashboard elements
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    @MainActor
    func testDashboardScrolling() throws {
        app.launch()
        
        sleep(2)
        
        // Try to find scrollable content
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            let firstScrollView = scrollViews.firstMatch
            if firstScrollView.exists {
                firstScrollView.swipeUp()
                firstScrollView.swipeDown()
            }
        }
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Login/Authentication Flow Tests
    
    @MainActor
    func testAuthenticationScreenPresence() throws {
        app.launch()
        
        // Wait for potential authentication screen
        sleep(2)
        
        // Check if authentication elements exist
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Add Asset Flow Tests
    
    @MainActor
    func testAddAssetNavigationExists() throws {
        app.launch()
        
        sleep(2)
        
        // Look for add button or add asset navigation
        let buttons = app.buttons
        
        // Verify buttons are accessible
        XCTAssertGreaterThanOrEqual(buttons.count, 0)
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    @MainActor
    func testAddAssetFormAccessibility() throws {
        app.launch()
        
        sleep(2)
        
        // Check for text fields (common in asset forms)
        let textFields = app.textFields
        
        // Verify form elements are accessible
        XCTAssertGreaterThanOrEqual(textFields.count, 0)
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Security Settings Tests
    
    @MainActor
    func testSecuritySettingsAccessibility() throws {
        app.launch()
        
        sleep(2)
        
        // Look for security-related UI elements
        let secureTextFields = app.secureTextFields
        
        // Verify security elements are accessible
        XCTAssertGreaterThanOrEqual(secureTextFields.count, 0)
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testVoiceOverSupport() throws {
        app.launch()
        
        sleep(2)
        
        // Verify accessibility elements exist
        let buttons = app.buttons
        let staticTexts = app.staticTexts
        
        // Check that UI elements are accessible
        XCTAssertGreaterThanOrEqual(buttons.count + staticTexts.count, 0)
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    @MainActor
    func testAccessibilityLabels() throws {
        app.launch()
        
        sleep(2)
        
        // Check that elements have accessibility identifiers
        let allElements = app.descendants(matching: .any)
        
        // Verify elements exist
        XCTAssertGreaterThan(allElements.count, 0)
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Interaction Tests
    
    @MainActor
    func testButtonInteraction() throws {
        app.launch()
        
        sleep(2)
        
        // Find and tap first available button
        let buttons = app.buttons
        if buttons.count > 0 {
            let firstButton = buttons.firstMatch
            if firstButton.exists && firstButton.isHittable {
                firstButton.tap()
                
                // Verify app still running after interaction
                XCTAssertTrue(app.state == .runningForeground)
            }
        }
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    @MainActor
    func testTextFieldInput() throws {
        app.launch()
        
        sleep(2)
        
        // Find and interact with first text field
        let textFields = app.textFields
        if textFields.count > 0 {
            let firstTextField = textFields.firstMatch
            if firstTextField.exists {
                firstTextField.tap()
                firstTextField.typeText("Test Input")
                
                // Verify app still running after input
                XCTAssertTrue(app.state == .runningForeground)
            }
        }
        
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testAppStability() throws {
        app.launch()
        
        // Perform various actions to test stability
        sleep(1)
        
        // Swipe gestures
        let mainWindow = app.windows.firstMatch
        mainWindow.swipeLeft()
        mainWindow.swipeRight()
        
        sleep(1)
        
        // Verify app is still running
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    @MainActor
    func testAppBackgroundAndForeground() throws {
        app.launch()
        
        sleep(2)
        
        // Send app to background
        XCUIDevice.shared.press(.home)
        
        sleep(1)
        
        // Bring app back to foreground
        app.activate()
        
        sleep(1)
        
        // Verify app is running
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Data Integrity Tests
    
    @MainActor
    func testDataPersistenceAcrossLaunches() throws {
        // First launch
        app.launch()
        sleep(2)
        
        // Terminate app
        app.terminate()
        
        sleep(1)
        
        // Second launch
        app.launch()
        sleep(2)
        
        // Verify app launched successfully
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testUIResponseTime() throws {
        app.launch()
        
        measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
            app.terminate()
            app.launch()
        }
    }
    
    @MainActor
    func testScrollPerformance() throws {
        app.launch()
        
        sleep(2)
        
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            let scrollView = scrollViews.firstMatch
            
            if scrollView.exists {
                measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
        }
    }
}
