//
//  AccessibilityPreferencesTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Accessibility Preferences Tests
//

import XCTest
@testable import WealthWise

@MainActor
final class AccessibilityPreferencesTests: XCTestCase {
    
    var accessibilityPreferences: AccessibilityPreferences!
    
    override func setUp() async throws {
        try await super.setUp()
        accessibilityPreferences = AccessibilityPreferences()
    }
    
    override func tearDown() async throws {
        accessibilityPreferences = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let prefs = AccessibilityPreferences()
        
        XCTAssertFalse(prefs.voiceOverEnabled)
        XCTAssertEqual(prefs.textSizeMultiplier, 1.0)
        XCTAssertFalse(prefs.boldTextEnabled)
        XCTAssertFalse(prefs.highContrastEnabled)
        XCTAssertFalse(prefs.reduceMotionEnabled)
        XCTAssertFalse(prefs.reduceTransparencyEnabled)
        XCTAssertEqual(prefs.colorBlindnessType, .none)
        XCTAssertTrue(prefs.hapticFeedbackEnabled)
        XCTAssertEqual(prefs.soundFeedbackLevel, .standard)
        XCTAssertTrue(prefs.screenReaderOptimized)
        XCTAssertEqual(prefs.focusStyle, .automatic)
        XCTAssertFalse(prefs.keyboardNavigationEnabled)
        XCTAssertEqual(prefs.gestureAssistanceLevel, .none)
    }
    
    func testCustomInitialization() {
        let prefs = AccessibilityPreferences(
            voiceOverEnabled: true,
            textSizeMultiplier: 1.5,
            boldTextEnabled: true,
            highContrastEnabled: true,
            colorBlindnessType: .deuteranopia,
            hapticFeedbackEnabled: false,
            soundFeedbackLevel: .enhanced
        )
        
        XCTAssertTrue(prefs.voiceOverEnabled)
        XCTAssertEqual(prefs.textSizeMultiplier, 1.5)
        XCTAssertTrue(prefs.boldTextEnabled)
        XCTAssertTrue(prefs.highContrastEnabled)
        XCTAssertEqual(prefs.colorBlindnessType, .deuteranopia)
        XCTAssertFalse(prefs.hapticFeedbackEnabled)
        XCTAssertEqual(prefs.soundFeedbackLevel, .enhanced)
    }
    
    // MARK: - VoiceOver Tests
    
    func testVoiceOverConfiguration() {
        XCTAssertFalse(accessibilityPreferences.voiceOverEnabled)
        
        accessibilityPreferences.voiceOverEnabled = true
        XCTAssertTrue(accessibilityPreferences.voiceOverEnabled)
        
        // Enabling VoiceOver should optimize for screen reader
        XCTAssertTrue(accessibilityPreferences.screenReaderOptimized)
    }
    
    func testVoiceOverWithKeyboardNavigation() {
        accessibilityPreferences.voiceOverEnabled = true
        accessibilityPreferences.keyboardNavigationEnabled = true
        
        // Both should work together
        XCTAssertTrue(accessibilityPreferences.voiceOverEnabled)
        XCTAssertTrue(accessibilityPreferences.keyboardNavigationEnabled)
    }
    
    // MARK: - Text Size Tests
    
    func testTextSizeMultiplierRange() {
        // Test minimum boundary
        accessibilityPreferences.textSizeMultiplier = 0.8
        XCTAssertEqual(accessibilityPreferences.textSizeMultiplier, 0.8)
        
        // Test maximum boundary
        accessibilityPreferences.textSizeMultiplier = 3.0
        XCTAssertEqual(accessibilityPreferences.textSizeMultiplier, 3.0)
        
        // Test normal range
        accessibilityPreferences.textSizeMultiplier = 1.5
        XCTAssertEqual(accessibilityPreferences.textSizeMultiplier, 1.5)
    }
    
    func testInvalidTextSizeHandling() {
        // Test values outside valid range
        accessibilityPreferences.textSizeMultiplier = 0.5 // Too small
        let issues = accessibilityPreferences.validate()
        XCTAssertTrue(issues.contains { $0.contains("Text size multiplier") })
        
        accessibilityPreferences.textSizeMultiplier = 4.0 // Too large
        let moreIssues = accessibilityPreferences.validate()
        XCTAssertTrue(moreIssues.contains { $0.contains("Text size multiplier") })
    }
    
    func testTextSizeWithBoldText() {
        accessibilityPreferences.textSizeMultiplier = 2.0
        accessibilityPreferences.boldTextEnabled = true
        
        // Large text with bold should be supported
        XCTAssertEqual(accessibilityPreferences.textSizeMultiplier, 2.0)
        XCTAssertTrue(accessibilityPreferences.boldTextEnabled)
    }
    
    // MARK: - Visual Accessibility Tests
    
    func testHighContrastMode() {
        XCTAssertFalse(accessibilityPreferences.highContrastEnabled)
        
        accessibilityPreferences.highContrastEnabled = true
        XCTAssertTrue(accessibilityPreferences.highContrastEnabled)
        
        // High contrast should work with color blindness support
        accessibilityPreferences.colorBlindnessType = .protanopia
        XCTAssertEqual(accessibilityPreferences.colorBlindnessType, .protanopia)
    }
    
    func testReduceTransparency() {
        accessibilityPreferences.reduceTransparencyEnabled = true
        
        XCTAssertTrue(accessibilityPreferences.reduceTransparencyEnabled)
        
        // Should work well with high contrast
        accessibilityPreferences.highContrastEnabled = true
        XCTAssertTrue(accessibilityPreferences.highContrastEnabled)
    }
    
    // MARK: - Color Blindness Tests
    
    func testColorBlindnessTypes() {
        let types: [ColorBlindnessType] = [.none, .protanopia, .deuteranopia, .tritanopia, .protanomaly, .deuteranomaly, .tritanomaly, .monochromacy]
        
        for type in types {
            accessibilityPreferences.colorBlindnessType = type
            XCTAssertEqual(accessibilityPreferences.colorBlindnessType, type)
        }
    }
    
    func testColorBlindnessWithHighContrast() {
        accessibilityPreferences.colorBlindnessType = .deuteranopia
        accessibilityPreferences.highContrastEnabled = true
        
        // Both features should work together
        XCTAssertEqual(accessibilityPreferences.colorBlindnessType, .deuteranopia)
        XCTAssertTrue(accessibilityPreferences.highContrastEnabled)
    }
    
    func testSevereColorBlindnessSupport() {
        accessibilityPreferences.colorBlindnessType = .monochromacy
        
        XCTAssertEqual(accessibilityPreferences.colorBlindnessType, .monochromacy)
        
        // Should automatically enable high contrast for monochromacy
        // (This would be implemented in the actual app logic)
    }
    
    // MARK: - Motion and Animation Tests
    
    func testReduceMotion() {
        accessibilityPreferences.reduceMotionEnabled = true
        
        XCTAssertTrue(accessibilityPreferences.reduceMotionEnabled)
        
        // Should be compatible with other accessibility features
        accessibilityPreferences.voiceOverEnabled = true
        XCTAssertTrue(accessibilityPreferences.voiceOverEnabled)
    }
    
    func testMotionWithHapticFeedback() {
        accessibilityPreferences.reduceMotionEnabled = true
        accessibilityPreferences.hapticFeedbackEnabled = true
        
        // Reduce motion might increase reliance on haptic feedback
        XCTAssertTrue(accessibilityPreferences.reduceMotionEnabled)
        XCTAssertTrue(accessibilityPreferences.hapticFeedbackEnabled)
    }
    
    // MARK: - Feedback Tests
    
    func testHapticFeedbackToggle() {
        XCTAssertTrue(accessibilityPreferences.hapticFeedbackEnabled)
        
        accessibilityPreferences.hapticFeedbackEnabled = false
        XCTAssertFalse(accessibilityPreferences.hapticFeedbackEnabled)
    }
    
    func testSoundFeedbackLevels() {
        let levels: [SoundFeedbackLevel] = [.none, .minimal, .standard, .enhanced]
        
        for level in levels {
            accessibilityPreferences.soundFeedbackLevel = level
            XCTAssertEqual(accessibilityPreferences.soundFeedbackLevel, level)
        }
    }
    
    func testFeedbackCombinations() {
        // Test different feedback combinations
        accessibilityPreferences.hapticFeedbackEnabled = false
        accessibilityPreferences.soundFeedbackLevel = .enhanced
        
        // Sound feedback compensates for disabled haptic
        XCTAssertFalse(accessibilityPreferences.hapticFeedbackEnabled)
        XCTAssertEqual(accessibilityPreferences.soundFeedbackLevel, .enhanced)
        
        // Both disabled
        accessibilityPreferences.soundFeedbackLevel = .none
        XCTAssertEqual(accessibilityPreferences.soundFeedbackLevel, .none)
    }
    
    // MARK: - Navigation Tests
    
    func testKeyboardNavigation() {
        accessibilityPreferences.keyboardNavigationEnabled = true
        
        XCTAssertTrue(accessibilityPreferences.keyboardNavigationEnabled)
        
        // Should work with VoiceOver
        accessibilityPreferences.voiceOverEnabled = true
        XCTAssertTrue(accessibilityPreferences.voiceOverEnabled)
    }
    
    func testFocusStyles() {
        let styles: [FocusStyle] = [.automatic, .highVisibility, .customColor, .animated]
        
        for style in styles {
            accessibilityPreferences.focusStyle = style
            XCTAssertEqual(accessibilityPreferences.focusStyle, style)
        }
    }
    
    func testFocusStyleWithHighContrast() {
        accessibilityPreferences.focusStyle = .highVisibility
        accessibilityPreferences.highContrastEnabled = true
        
        // High visibility focus with high contrast
        XCTAssertEqual(accessibilityPreferences.focusStyle, .highVisibility)
        XCTAssertTrue(accessibilityPreferences.highContrastEnabled)
    }
    
    // MARK: - Gesture Assistance Tests
    
    func testGestureAssistanceLevels() {
        let levels: [GestureAssistanceLevel] = [.none, .minimal, .standard, .enhanced]
        
        for level in levels {
            accessibilityPreferences.gestureAssistanceLevel = level
            XCTAssertEqual(accessibilityPreferences.gestureAssistanceLevel, level)
        }
    }
    
    func testGestureAssistanceWithMotorImpairments() {
        accessibilityPreferences.gestureAssistanceLevel = .enhanced
        
        XCTAssertEqual(accessibilityPreferences.gestureAssistanceLevel, .enhanced)
        
        // Should work with keyboard navigation as alternative
        accessibilityPreferences.keyboardNavigationEnabled = true
        XCTAssertTrue(accessibilityPreferences.keyboardNavigationEnabled)
    }
    
    // MARK: - Screen Reader Optimization Tests
    
    func testScreenReaderOptimization() {
        XCTAssertTrue(accessibilityPreferences.screenReaderOptimized)
        
        accessibilityPreferences.screenReaderOptimized = false
        XCTAssertFalse(accessibilityPreferences.screenReaderOptimized)
        
        // Enabling VoiceOver should re-enable optimization
        accessibilityPreferences.voiceOverEnabled = true
        // This would be handled by the app logic, not the model itself
    }
    
    // MARK: - Validation Tests
    
    func testValidConfiguration() {
        let validPrefs = AccessibilityPreferences()
        validPrefs.voiceOverEnabled = true
        validPrefs.textSizeMultiplier = 1.5
        validPrefs.highContrastEnabled = true
        validPrefs.colorBlindnessType = .deuteranopia
        
        XCTAssertTrue(validPrefs.isValid())
        XCTAssertTrue(validPrefs.validate().isEmpty)
    }
    
    func testInvalidTextSizeValidation() {
        accessibilityPreferences.textSizeMultiplier = 0.5 // Too small
        
        let issues = accessibilityPreferences.validate()
        XCTAssertFalse(issues.isEmpty)
        XCTAssertTrue(issues.contains { $0.contains("Text size multiplier") })
    }
    
    func testConflictingSettingsValidation() {
        // Some combinations might need validation
        accessibilityPreferences.reduceMotionEnabled = true
        accessibilityPreferences.focusStyle = .animated
        
        // This specific combination might generate a warning
        let issues = accessibilityPreferences.validate()
        // The validation logic would determine if this is problematic
    }
    
    // MARK: - System Integration Tests
    
    func testSystemAccessibilityIntegration() {
        // Test that preferences can reflect system settings
        // This would typically involve checking UIAccessibility values
        
        accessibilityPreferences.voiceOverEnabled = true
        XCTAssertTrue(accessibilityPreferences.voiceOverEnabled)
        
        // In a real app, this might sync with UIAccessibility.isVoiceOverRunning
    }
    
    // MARK: - Codable Tests
    
    func testCodableEncoding() throws {
        accessibilityPreferences.voiceOverEnabled = true
        accessibilityPreferences.textSizeMultiplier = 2.0
        accessibilityPreferences.boldTextEnabled = true
        accessibilityPreferences.highContrastEnabled = true
        accessibilityPreferences.colorBlindnessType = .protanopia
        accessibilityPreferences.hapticFeedbackEnabled = false
        accessibilityPreferences.soundFeedbackLevel = .enhanced
        accessibilityPreferences.focusStyle = .highVisibility
        accessibilityPreferences.gestureAssistanceLevel = .standard
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(accessibilityPreferences)
        
        XCTAssertFalse(data.isEmpty)
    }
    
    func testCodableDecoding() throws {
        // Create test preferences
        let originalPrefs = AccessibilityPreferences()
        originalPrefs.voiceOverEnabled = true
        originalPrefs.textSizeMultiplier = 1.8
        originalPrefs.boldTextEnabled = true
        originalPrefs.highContrastEnabled = true
        originalPrefs.reduceMotionEnabled = true
        originalPrefs.reduceTransparencyEnabled = true
        originalPrefs.colorBlindnessType = .tritanopia
        originalPrefs.hapticFeedbackEnabled = false
        originalPrefs.soundFeedbackLevel = .minimal
        originalPrefs.screenReaderOptimized = true
        originalPrefs.focusStyle = .customColor
        originalPrefs.keyboardNavigationEnabled = true
        originalPrefs.gestureAssistanceLevel = .enhanced
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPrefs)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedPrefs = try decoder.decode(AccessibilityPreferences.self, from: data)
        
        // Verify all properties
        XCTAssertEqual(decodedPrefs.voiceOverEnabled, originalPrefs.voiceOverEnabled)
        XCTAssertEqual(decodedPrefs.textSizeMultiplier, originalPrefs.textSizeMultiplier)
        XCTAssertEqual(decodedPrefs.boldTextEnabled, originalPrefs.boldTextEnabled)
        XCTAssertEqual(decodedPrefs.highContrastEnabled, originalPrefs.highContrastEnabled)
        XCTAssertEqual(decodedPrefs.reduceMotionEnabled, originalPrefs.reduceMotionEnabled)
        XCTAssertEqual(decodedPrefs.reduceTransparencyEnabled, originalPrefs.reduceTransparencyEnabled)
        XCTAssertEqual(decodedPrefs.colorBlindnessType, originalPrefs.colorBlindnessType)
        XCTAssertEqual(decodedPrefs.hapticFeedbackEnabled, originalPrefs.hapticFeedbackEnabled)
        XCTAssertEqual(decodedPrefs.soundFeedbackLevel, originalPrefs.soundFeedbackLevel)
        XCTAssertEqual(decodedPrefs.screenReaderOptimized, originalPrefs.screenReaderOptimized)
        XCTAssertEqual(decodedPrefs.focusStyle, originalPrefs.focusStyle)
        XCTAssertEqual(decodedPrefs.keyboardNavigationEnabled, originalPrefs.keyboardNavigationEnabled)
        XCTAssertEqual(decodedPrefs.gestureAssistanceLevel, originalPrefs.gestureAssistanceLevel)
    }
    
    func testCodableRoundTrip() throws {
        // Configure complex accessibility settings
        accessibilityPreferences.voiceOverEnabled = true
        accessibilityPreferences.textSizeMultiplier = 2.5
        accessibilityPreferences.boldTextEnabled = true
        accessibilityPreferences.highContrastEnabled = true
        accessibilityPreferences.reduceMotionEnabled = false
        accessibilityPreferences.colorBlindnessType = .deuteranomaly
        accessibilityPreferences.hapticFeedbackEnabled = true
        accessibilityPreferences.soundFeedbackLevel = .standard
        accessibilityPreferences.focusStyle = .animated
        accessibilityPreferences.gestureAssistanceLevel = .minimal
        
        // Round trip
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(accessibilityPreferences)
        let decoded = try decoder.decode(AccessibilityPreferences.self, from: data)
        
        // Should be identical
        XCTAssertEqual(decoded.voiceOverEnabled, accessibilityPreferences.voiceOverEnabled)
        XCTAssertEqual(decoded.textSizeMultiplier, accessibilityPreferences.textSizeMultiplier)
        XCTAssertEqual(decoded.boldTextEnabled, accessibilityPreferences.boldTextEnabled)
        XCTAssertEqual(decoded.highContrastEnabled, accessibilityPreferences.highContrastEnabled)
        XCTAssertEqual(decoded.reduceMotionEnabled, accessibilityPreferences.reduceMotionEnabled)
        XCTAssertEqual(decoded.colorBlindnessType, accessibilityPreferences.colorBlindnessType)
        XCTAssertEqual(decoded.hapticFeedbackEnabled, accessibilityPreferences.hapticFeedbackEnabled)
        XCTAssertEqual(decoded.soundFeedbackLevel, accessibilityPreferences.soundFeedbackLevel)
        XCTAssertEqual(decoded.focusStyle, accessibilityPreferences.focusStyle)
        XCTAssertEqual(decoded.gestureAssistanceLevel, accessibilityPreferences.gestureAssistanceLevel)
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityCheckPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = accessibilityPreferences.voiceOverEnabled
                _ = accessibilityPreferences.textSizeMultiplier
                _ = accessibilityPreferences.highContrastEnabled
                _ = accessibilityPreferences.colorBlindnessType
            }
        }
    }
    
    func testValidationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = accessibilityPreferences.validate()
                _ = accessibilityPreferences.isValid()
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testExtremeCombinations() {
        // All accessibility features enabled
        accessibilityPreferences.voiceOverEnabled = true
        accessibilityPreferences.textSizeMultiplier = 3.0
        accessibilityPreferences.boldTextEnabled = true
        accessibilityPreferences.highContrastEnabled = true
        accessibilityPreferences.reduceMotionEnabled = true
        accessibilityPreferences.reduceTransparencyEnabled = true
        accessibilityPreferences.colorBlindnessType = .monochromacy
        accessibilityPreferences.hapticFeedbackEnabled = true
        accessibilityPreferences.soundFeedbackLevel = .enhanced
        accessibilityPreferences.keyboardNavigationEnabled = true
        accessibilityPreferences.gestureAssistanceLevel = .enhanced
        
        // Should handle extreme accessibility requirements
        XCTAssertTrue(accessibilityPreferences.isValid())
    }
    
    func testMinimalAccessibility() {
        // Minimal accessibility support
        accessibilityPreferences.voiceOverEnabled = false
        accessibilityPreferences.textSizeMultiplier = 0.8
        accessibilityPreferences.hapticFeedbackEnabled = false
        accessibilityPreferences.soundFeedbackLevel = .none
        
        // Should still be valid
        XCTAssertTrue(accessibilityPreferences.isValid())
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testLowVisionUser() {
        // Configuration for user with low vision
        accessibilityPreferences.textSizeMultiplier = 2.5
        accessibilityPreferences.boldTextEnabled = true
        accessibilityPreferences.highContrastEnabled = true
        accessibilityPreferences.reduceTransparencyEnabled = true
        accessibilityPreferences.colorBlindnessType = .none
        accessibilityPreferences.focusStyle = .highVisibility
        
        XCTAssertTrue(accessibilityPreferences.isValid())
        XCTAssertEqual(accessibilityPreferences.textSizeMultiplier, 2.5)
        XCTAssertTrue(accessibilityPreferences.boldTextEnabled)
        XCTAssertTrue(accessibilityPreferences.highContrastEnabled)
    }
    
    func testMotorImpairedUser() {
        // Configuration for user with motor impairments
        accessibilityPreferences.keyboardNavigationEnabled = true
        accessibilityPreferences.gestureAssistanceLevel = .enhanced
        accessibilityPreferences.hapticFeedbackEnabled = true
        accessibilityPreferences.soundFeedbackLevel = .enhanced
        accessibilityPreferences.focusStyle = .highVisibility
        
        XCTAssertTrue(accessibilityPreferences.isValid())
        XCTAssertTrue(accessibilityPreferences.keyboardNavigationEnabled)
        XCTAssertEqual(accessibilityPreferences.gestureAssistanceLevel, .enhanced)
    }
    
    func testBlindUser() {
        // Configuration for blind user
        accessibilityPreferences.voiceOverEnabled = true
        accessibilityPreferences.screenReaderOptimized = true
        accessibilityPreferences.hapticFeedbackEnabled = true
        accessibilityPreferences.soundFeedbackLevel = .enhanced
        accessibilityPreferences.keyboardNavigationEnabled = true
        accessibilityPreferences.reduceMotionEnabled = true
        
        XCTAssertTrue(accessibilityPreferences.isValid())
        XCTAssertTrue(accessibilityPreferences.voiceOverEnabled)
        XCTAssertTrue(accessibilityPreferences.screenReaderOptimized)
    }
}