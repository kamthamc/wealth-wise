//
//  AccessibilityPreferences.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Accessibility Configuration
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation

/// Accessibility preferences for VoiceOver, display settings, and assistive technologies
/// Ensures comprehensive accessibility support across the application
@MainActor
@Observable
public final class AccessibilityPreferences: Codable {
    
    // MARK: - VoiceOver Settings
    
    /// Enable VoiceOver optimizations
    public var voiceOverEnabled: Bool
    
    /// VoiceOver speaking rate (0.0 to 1.0)
    public var voiceOverRate: Float
    
    /// VoiceOver pitch (0.5 to 2.0)
    public var voiceOverPitch: Float
    
    /// VoiceOver volume (0.0 to 1.0)
    public var voiceOverVolume: Float
    
    /// Preferred voice for VoiceOver
    public var voiceOverVoice: String?
    
    /// Announce financial values in detail
    public var announceFinancialDetails: Bool
    
    /// Use phonetic pronunciation for currency codes
    public var usePhoneticCurrencyCodes: Bool
    
    // MARK: - Display Settings
    
    /// Reduce motion animations
    public var reduceMotion: Bool
    
    /// Reduce transparency effects
    public var reduceTransparency: Bool
    
    /// Increase contrast
    public var increaseContrast: Bool
    
    /// Use high contrast colors
    public var useHighContrastColors: Bool
    
    /// Large text support
    public var preferLargeText: Bool
    
    /// Dynamic type scaling factor
    public var textSizeMultiplier: CGFloat
    
    /// Bold text preference
    public var preferBoldText: Bool
    
    /// Button shapes enabled
    public var showButtonShapes: Bool
    
    // MARK: - Interaction Settings
    
    /// Guided access mode
    public var guidedAccessEnabled: Bool
    
    /// Switch control enabled
    public var switchControlEnabled: Bool
    
    /// Voice control enabled
    public var voiceControlEnabled: Bool
    
    /// Sticky keys (hold to activate)
    public var stickyKeysEnabled: Bool
    
    /// Touch accommodations
    public var touchAccommodationsEnabled: Bool
    
    /// Hold duration for touch (in seconds)
    public var touchHoldDuration: TimeInterval
    
    /// Ignore repeat touches
    public var ignoreRepeatTouches: Bool
    
    // MARK: - Audio Settings
    
    /// Mono audio for single-ear usage
    public var monoAudio: Bool
    
    /// Audio descriptions for charts and graphs
    public var audioDescriptionsEnabled: Bool
    
    /// Sound effects enabled
    public var soundEffectsEnabled: Bool
    
    /// Haptic feedback level
    public var hapticFeedbackLevel: HapticFeedbackLevel
    
    // MARK: - Content Settings
    
    /// Simplified UI mode
    public var simplifiedUIMode: Bool
    
    /// Skip non-essential animations
    public var skipNonEssentialAnimations: Bool
    
    /// Auto-play media content
    public var autoPlayMedia: Bool
    
    /// Show alternative text for images
    public var showImageDescriptions: Bool
    
    /// Color blind friendly palette
    public var useColorBlindFriendlyPalette: Bool
    
    /// Color blindness type
    public var colorBlindnessType: ColorBlindnessType
    
    // MARK: - Navigation Settings
    
    /// Focus indicator enhancement
    public var enhanceFocusIndicator: Bool
    
    /// Keyboard navigation priority
    public var prioritizeKeyboardNavigation: Bool
    
    /// Tab order customization
    public var customTabOrder: Bool
    
    /// Skip to content shortcuts
    public var enableSkipLinks: Bool
    
    // MARK: - Initialization
    
    public init() {
        // Initialize all properties with defaults first
        voiceOverEnabled = false
        voiceOverRate = 0.5
        voiceOverPitch = 1.0
        voiceOverVolume = 1.0
        voiceOverVoice = nil
        announceFinancialDetails = true
        usePhoneticCurrencyCodes = false
        reduceMotion = false
        reduceTransparency = false
        increaseContrast = false
        useHighContrastColors = false
        preferLargeText = false
        textSizeMultiplier = 1.0
        preferBoldText = false
        showButtonShapes = false
        guidedAccessEnabled = false
        switchControlEnabled = false
        voiceControlEnabled = false
        stickyKeysEnabled = false
        touchAccommodationsEnabled = false
        touchHoldDuration = 0.1
        ignoreRepeatTouches = false
        monoAudio = false
        audioDescriptionsEnabled = true
        soundEffectsEnabled = true
        hapticFeedbackLevel = .standard
        simplifiedUIMode = false
        skipNonEssentialAnimations = false
        autoPlayMedia = true
        showImageDescriptions = true
        useColorBlindFriendlyPalette = false
        colorBlindnessType = .none
        enhanceFocusIndicator = false
        prioritizeKeyboardNavigation = false
        customTabOrder = false
        enableSkipLinks = true
        
        // Now load system settings to override defaults
        loadSystemAccessibilitySettings()
    }
    
    public init(forAudience audience: PrimaryAudience) {
        // Initialize all properties with defaults first
        voiceOverEnabled = false
        voiceOverRate = 0.5
        voiceOverPitch = 1.0
        voiceOverVolume = 1.0
        voiceOverVoice = nil
        announceFinancialDetails = true
        usePhoneticCurrencyCodes = false
        reduceMotion = false
        reduceTransparency = false
        increaseContrast = false
        useHighContrastColors = false
        preferLargeText = false
        textSizeMultiplier = 1.0
        preferBoldText = false
        showButtonShapes = false
        guidedAccessEnabled = false
        switchControlEnabled = false
        voiceControlEnabled = false
        stickyKeysEnabled = false
        touchAccommodationsEnabled = false
        touchHoldDuration = 0.1
        ignoreRepeatTouches = false
        monoAudio = false
        audioDescriptionsEnabled = true
        soundEffectsEnabled = true
        hapticFeedbackLevel = .standard
        simplifiedUIMode = false
        skipNonEssentialAnimations = false
        autoPlayMedia = true
        showImageDescriptions = true
        useColorBlindFriendlyPalette = false
        colorBlindnessType = .none
        enhanceFocusIndicator = false
        prioritizeKeyboardNavigation = false
        customTabOrder = false
        enableSkipLinks = true
        
        // Now load system settings and configure for audience
        loadSystemAccessibilitySettings()
        configureForAudience(audience)
    }
    
    // MARK: - Configuration
    
    private func loadSystemAccessibilitySettings() {
        #if canImport(UIKit)
        voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        reduceMotion = UIAccessibility.isReduceMotionEnabled
        reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        increaseContrast = UIAccessibility.isDarkerSystemColorsEnabled
        preferBoldText = UIAccessibility.isBoldTextEnabled
        showButtonShapes = UIAccessibility.isButtonShapesEnabled
        guidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled
        switchControlEnabled = UIAccessibility.isSwitchControlRunning
        monoAudio = UIAccessibility.isMonoAudioEnabled
        
        // Set text size based on system preference
        let preferredContentSize = UIApplication.shared.preferredContentSizeCategory
        textSizeMultiplier = contentSizeMultiplier(for: preferredContentSize)
        preferLargeText = preferredContentSize.isAccessibilityCategory
        #else
        // macOS defaults
        voiceOverEnabled = false
        reduceMotion = false
        reduceTransparency = false
        increaseContrast = false
        preferBoldText = false
        showButtonShapes = false
        guidedAccessEnabled = false
        switchControlEnabled = false
        monoAudio = false
        textSizeMultiplier = 1.0
        preferLargeText = false
        #endif
        
        // Initialize all remaining properties with defaults
        voiceOverRate = 0.5
        voiceOverPitch = 1.0
        voiceOverVolume = 1.0
        voiceOverVoice = nil
        announceFinancialDetails = true
        usePhoneticCurrencyCodes = false
        useHighContrastColors = false
        voiceControlEnabled = false
        stickyKeysEnabled = false
        touchAccommodationsEnabled = false
        touchHoldDuration = 0.1
        ignoreRepeatTouches = false
        audioDescriptionsEnabled = true
        soundEffectsEnabled = true
        hapticFeedbackLevel = .standard
        simplifiedUIMode = false
        skipNonEssentialAnimations = false
        autoPlayMedia = true
        showImageDescriptions = true
        useColorBlindFriendlyPalette = false
        colorBlindnessType = .none
        enhanceFocusIndicator = false
        prioritizeKeyboardNavigation = false
        customTabOrder = false
        enableSkipLinks = true
    }
    
    public func configureForAudience(_ audience: PrimaryAudience) {
        switch audience {
        case .indian:
            // Configure for Indian accessibility standards
            announceFinancialDetails = true
            usePhoneticCurrencyCodes = true // For Indian currency terms
            
        case .american, .british, .canadian, .australian:
            // Standard Western accessibility settings
            announceFinancialDetails = true
            usePhoneticCurrencyCodes = false
            
        default:
            // Default settings
            break
        }
    }
    
    // MARK: - Helper Methods
    
    #if canImport(UIKit)
    private func contentSizeMultiplier(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.5
        case .accessibilityLarge: return 1.7
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.3
        case .accessibilityExtraExtraExtraLarge: return 2.7
        default: return 1.0
        }
    }
    #endif
    
    // MARK: - Validation
    
    public func validate() -> [String] {
        var issues: [String] = []
        
        // Validate VoiceOver settings
        if voiceOverRate < 0.0 || voiceOverRate > 1.0 {
            issues.append("VoiceOver rate must be between 0.0 and 1.0")
        }
        
        if voiceOverPitch < 0.5 || voiceOverPitch > 2.0 {
            issues.append("VoiceOver pitch must be between 0.5 and 2.0")
        }
        
        if voiceOverVolume < 0.0 || voiceOverVolume > 1.0 {
            issues.append("VoiceOver volume must be between 0.0 and 1.0")
        }
        
        // Validate text scaling
        if textSizeMultiplier < 0.5 || textSizeMultiplier > 3.0 {
            issues.append("Text size multiplier must be between 0.5 and 3.0")
        }
        
        // Validate touch settings
        if touchHoldDuration < 0.1 || touchHoldDuration > 4.0 {
            issues.append("Touch hold duration must be between 0.1 and 4.0 seconds")
        }
        
        return issues
    }
    
    // MARK: - System Integration
    
    /// Update settings based on current system accessibility state
    public func syncWithSystemSettings() {
        loadSystemAccessibilitySettings()
    }
    
    /// Check if any high contrast settings are enabled
    public var isHighContrastMode: Bool {
        return increaseContrast || useHighContrastColors
    }
    
    /// Check if any motion reduction settings are enabled
    public var isMotionReduced: Bool {
        return reduceMotion || skipNonEssentialAnimations
    }
    
    /// Check if assistive technology is active
    public var isAssistiveTechnologyActive: Bool {
        return voiceOverEnabled || switchControlEnabled || voiceControlEnabled
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case voiceOverEnabled
        case voiceOverRate
        case voiceOverPitch
        case voiceOverVolume
        case voiceOverVoice
        case announceFinancialDetails
        case usePhoneticCurrencyCodes
        case reduceMotion
        case reduceTransparency
        case increaseContrast
        case useHighContrastColors
        case preferLargeText
        case textSizeMultiplier
        case preferBoldText
        case showButtonShapes
        case guidedAccessEnabled
        case switchControlEnabled
        case voiceControlEnabled
        case stickyKeysEnabled
        case touchAccommodationsEnabled
        case touchHoldDuration
        case ignoreRepeatTouches
        case monoAudio
        case audioDescriptionsEnabled
        case soundEffectsEnabled
        case hapticFeedbackLevel
        case simplifiedUIMode
        case skipNonEssentialAnimations
        case autoPlayMedia
        case showImageDescriptions
        case useColorBlindFriendlyPalette
        case colorBlindnessType
        case enhanceFocusIndicator
        case prioritizeKeyboardNavigation
        case customTabOrder
        case enableSkipLinks
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(voiceOverEnabled, forKey: .voiceOverEnabled)
        try container.encode(voiceOverRate, forKey: .voiceOverRate)
        try container.encode(voiceOverPitch, forKey: .voiceOverPitch)
        try container.encode(voiceOverVolume, forKey: .voiceOverVolume)
        try container.encode(voiceOverVoice, forKey: .voiceOverVoice)
        try container.encode(announceFinancialDetails, forKey: .announceFinancialDetails)
        try container.encode(usePhoneticCurrencyCodes, forKey: .usePhoneticCurrencyCodes)
        try container.encode(reduceMotion, forKey: .reduceMotion)
        try container.encode(reduceTransparency, forKey: .reduceTransparency)
        try container.encode(increaseContrast, forKey: .increaseContrast)
        try container.encode(useHighContrastColors, forKey: .useHighContrastColors)
        try container.encode(preferLargeText, forKey: .preferLargeText)
        try container.encode(textSizeMultiplier, forKey: .textSizeMultiplier)
        try container.encode(preferBoldText, forKey: .preferBoldText)
        try container.encode(showButtonShapes, forKey: .showButtonShapes)
        try container.encode(guidedAccessEnabled, forKey: .guidedAccessEnabled)
        try container.encode(switchControlEnabled, forKey: .switchControlEnabled)
        try container.encode(voiceControlEnabled, forKey: .voiceControlEnabled)
        try container.encode(stickyKeysEnabled, forKey: .stickyKeysEnabled)
        try container.encode(touchAccommodationsEnabled, forKey: .touchAccommodationsEnabled)
        try container.encode(touchHoldDuration, forKey: .touchHoldDuration)
        try container.encode(ignoreRepeatTouches, forKey: .ignoreRepeatTouches)
        try container.encode(monoAudio, forKey: .monoAudio)
        try container.encode(audioDescriptionsEnabled, forKey: .audioDescriptionsEnabled)
        try container.encode(soundEffectsEnabled, forKey: .soundEffectsEnabled)
        try container.encode(hapticFeedbackLevel, forKey: .hapticFeedbackLevel)
        try container.encode(simplifiedUIMode, forKey: .simplifiedUIMode)
        try container.encode(skipNonEssentialAnimations, forKey: .skipNonEssentialAnimations)
        try container.encode(autoPlayMedia, forKey: .autoPlayMedia)
        try container.encode(showImageDescriptions, forKey: .showImageDescriptions)
        try container.encode(useColorBlindFriendlyPalette, forKey: .useColorBlindFriendlyPalette)
        try container.encode(colorBlindnessType, forKey: .colorBlindnessType)
        try container.encode(enhanceFocusIndicator, forKey: .enhanceFocusIndicator)
        try container.encode(prioritizeKeyboardNavigation, forKey: .prioritizeKeyboardNavigation)
        try container.encode(customTabOrder, forKey: .customTabOrder)
        try container.encode(enableSkipLinks, forKey: .enableSkipLinks)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        voiceOverEnabled = try container.decode(Bool.self, forKey: .voiceOverEnabled)
        voiceOverRate = try container.decode(Float.self, forKey: .voiceOverRate)
        voiceOverPitch = try container.decode(Float.self, forKey: .voiceOverPitch)
        voiceOverVolume = try container.decode(Float.self, forKey: .voiceOverVolume)
        voiceOverVoice = try container.decodeIfPresent(String.self, forKey: .voiceOverVoice)
        announceFinancialDetails = try container.decode(Bool.self, forKey: .announceFinancialDetails)
        usePhoneticCurrencyCodes = try container.decode(Bool.self, forKey: .usePhoneticCurrencyCodes)
        reduceMotion = try container.decode(Bool.self, forKey: .reduceMotion)
        reduceTransparency = try container.decode(Bool.self, forKey: .reduceTransparency)
        increaseContrast = try container.decode(Bool.self, forKey: .increaseContrast)
        useHighContrastColors = try container.decode(Bool.self, forKey: .useHighContrastColors)
        preferLargeText = try container.decode(Bool.self, forKey: .preferLargeText)
        textSizeMultiplier = try container.decode(CGFloat.self, forKey: .textSizeMultiplier)
        preferBoldText = try container.decode(Bool.self, forKey: .preferBoldText)
        showButtonShapes = try container.decode(Bool.self, forKey: .showButtonShapes)
        guidedAccessEnabled = try container.decode(Bool.self, forKey: .guidedAccessEnabled)
        switchControlEnabled = try container.decode(Bool.self, forKey: .switchControlEnabled)
        voiceControlEnabled = try container.decode(Bool.self, forKey: .voiceControlEnabled)
        stickyKeysEnabled = try container.decode(Bool.self, forKey: .stickyKeysEnabled)
        touchAccommodationsEnabled = try container.decode(Bool.self, forKey: .touchAccommodationsEnabled)
        touchHoldDuration = try container.decode(TimeInterval.self, forKey: .touchHoldDuration)
        ignoreRepeatTouches = try container.decode(Bool.self, forKey: .ignoreRepeatTouches)
        monoAudio = try container.decode(Bool.self, forKey: .monoAudio)
        audioDescriptionsEnabled = try container.decode(Bool.self, forKey: .audioDescriptionsEnabled)
        soundEffectsEnabled = try container.decode(Bool.self, forKey: .soundEffectsEnabled)
        hapticFeedbackLevel = try container.decode(HapticFeedbackLevel.self, forKey: .hapticFeedbackLevel)
        simplifiedUIMode = try container.decode(Bool.self, forKey: .simplifiedUIMode)
        skipNonEssentialAnimations = try container.decode(Bool.self, forKey: .skipNonEssentialAnimations)
        autoPlayMedia = try container.decode(Bool.self, forKey: .autoPlayMedia)
        showImageDescriptions = try container.decode(Bool.self, forKey: .showImageDescriptions)
        useColorBlindFriendlyPalette = try container.decode(Bool.self, forKey: .useColorBlindFriendlyPalette)
        colorBlindnessType = try container.decode(ColorBlindnessType.self, forKey: .colorBlindnessType)
        enhanceFocusIndicator = try container.decode(Bool.self, forKey: .enhanceFocusIndicator)
        prioritizeKeyboardNavigation = try container.decode(Bool.self, forKey: .prioritizeKeyboardNavigation)
        customTabOrder = try container.decode(Bool.self, forKey: .customTabOrder)
        enableSkipLinks = try container.decode(Bool.self, forKey: .enableSkipLinks)
    }
}

// MARK: - Supporting Types

/// Haptic feedback intensity levels
public enum HapticFeedbackLevel: String, CaseIterable, Codable {
    case none = "none"
    case light = "light"
    case standard = "standard"
    case strong = "strong"
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .light: return "Light"
        case .standard: return "Standard"
        case .strong: return "Strong"
        }
    }
}

/// Color blindness types for accessibility adaptations
public enum ColorBlindnessType: String, CaseIterable, Codable {
    case none = "none"
    case protanopia = "protanopia"          // Red-blind
    case protanomaly = "protanomaly"        // Red-weak
    case deuteranopia = "deuteranopia"      // Green-blind
    case deuteranomaly = "deuteranomaly"    // Green-weak
    case tritanopia = "tritanopia"          // Blue-blind
    case tritanomaly = "tritanomaly"        // Blue-weak
    case achromatopsia = "achromatopsia"    // Complete color blindness
    case achromatomaly = "achromatomaly"    // Partial color blindness
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .protanopia: return "Protanopia (Red-blind)"
        case .protanomaly: return "Protanomaly (Red-weak)"
        case .deuteranopia: return "Deuteranopia (Green-blind)"
        case .deuteranomaly: return "Deuteranomaly (Green-weak)"
        case .tritanopia: return "Tritanopia (Blue-blind)"
        case .tritanomaly: return "Tritanomaly (Blue-weak)"
        case .achromatopsia: return "Achromatopsia (Complete)"
        case .achromatomaly: return "Achromatomaly (Partial)"
        }
    }
    
    public var description: String {
        switch self {
        case .none: return "No color vision deficiency"
        case .protanopia: return "Cannot distinguish red colors"
        case .protanomaly: return "Reduced sensitivity to red colors"
        case .deuteranopia: return "Cannot distinguish green colors"
        case .deuteranomaly: return "Reduced sensitivity to green colors"
        case .tritanopia: return "Cannot distinguish blue colors"
        case .tritanomaly: return "Reduced sensitivity to blue colors"
        case .achromatopsia: return "Cannot see any colors"
        case .achromatomaly: return "Limited color vision"
        }
    }
}