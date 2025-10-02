//
//  CulturalContext.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Cultural context management for audience-specific adaptations
//

import Foundation
import SwiftUI
import Combine

/// Represents the complete cultural context for the application
/// Includes locale, audience, formatting preferences, and UI adaptations
@Observable
public final class CulturalContext: Codable, Sendable {
    
    // MARK: - Properties
    
    /// Primary target audience determining cultural adaptations
    public var audience: PrimaryAudience
    
    /// Localization configuration
    public var localizationConfig: LocalizationConfig
    
    /// Text direction for UI layout
    public var textDirection: TextDirection
    
    /// Color scheme preference (light/dark mode)
    public var colorScheme: ColorScheme?
    
    /// Accessibility preferences
    public var isAccessibilityEnabled: Bool
    
    /// High contrast mode for accessibility
    public var isHighContrastEnabled: Bool
    
    /// Reduced motion preference
    public var isReducedMotionEnabled: Bool
    
    /// Created timestamp
    public private(set) var createdAt: Date
    
    /// Last updated timestamp
    public private(set) var updatedAt: Date
    
    // MARK: - Initialization
    
    public init() {
        let currentAudience = PrimaryAudience.current
        self.audience = currentAudience
        self.localizationConfig = LocalizationConfig(forAudience: currentAudience)
        self.textDirection = currentAudience.isRTL ? .rightToLeft : .leftToRight
        self.colorScheme = nil
        self.isAccessibilityEnabled = false
        self.isHighContrastEnabled = false
        self.isReducedMotionEnabled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(audience: PrimaryAudience) {
        self.audience = audience
        self.localizationConfig = LocalizationConfig(forAudience: audience)
        self.textDirection = audience.isRTL ? .rightToLeft : .leftToRight
        self.colorScheme = nil
        self.isAccessibilityEnabled = false
        self.isHighContrastEnabled = false
        self.isReducedMotionEnabled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Current locale based on localization config
    public var currentLocale: Locale {
        localizationConfig.currentLocale
    }
    
    /// Current calendar based on localization config
    public var currentCalendar: Calendar {
        localizationConfig.currentCalendar
    }
    
    /// Number system in use
    public var numberSystem: NumberSystem {
        localizationConfig.numberSystem
    }
    
    /// Whether RTL layout is active
    public var isRTL: Bool {
        textDirection.isRTL
    }
    
    /// Layout direction for SwiftUI
    public var layoutDirection: LayoutDirection {
        textDirection.layoutDirection
    }
    
    /// Currency code for the audience
    public var primaryCurrencyCode: String {
        switch audience {
        case .indian: return "INR"
        case .american: return "USD"
        case .british: return "GBP"
        case .canadian: return "CAD"
        case .australian: return "AUD"
        case .singaporean: return "SGD"
        case .german, .french, .dutch, .irish, .luxembourgish: return "EUR"
        case .swiss: return "CHF"
        case .japanese: return "JPY"
        case .hongKongese: return "HKD"
        case .newZealander: return "NZD"
        case .malaysian: return "MYR"
        case .thai: return "THB"
        case .filipino: return "PHP"
        case .emirati: return "AED"
        case .qatari: return "QAR"
        case .saudi: return "SAR"
        case .brazilian: return "BRL"
        case .mexican: return "MXN"
        }
    }
    
    // MARK: - Public Methods
    
    /// Update the primary audience and reconfigure context
    public func updateAudience(_ newAudience: PrimaryAudience) {
        audience = newAudience
        localizationConfig.configureForAudience(newAudience)
        textDirection = newAudience.isRTL ? .rightToLeft : .leftToRight
        updatedAt = Date()
    }
    
    /// Update text direction explicitly
    public func updateTextDirection(_ direction: TextDirection) {
        textDirection = direction
        localizationConfig.isRTLEnabled = direction.isRTL
        updatedAt = Date()
    }
    
    /// Update accessibility settings
    public func updateAccessibility(
        enabled: Bool,
        highContrast: Bool = false,
        reducedMotion: Bool = false
    ) {
        isAccessibilityEnabled = enabled
        isHighContrastEnabled = highContrast
        isReducedMotionEnabled = reducedMotion
        updatedAt = Date()
    }
    
    /// Validate the cultural context
    public func validate() -> [String] {
        var issues: [String] = []
        
        // Validate localization config
        issues.append(contentsOf: localizationConfig.validate())
        
        // Validate RTL consistency
        if textDirection.isRTL != audience.isRTL {
            issues.append("Text direction inconsistent with audience RTL preference")
        }
        
        // Validate locale consistency
        if !audience.primaryLanguages.contains(localizationConfig.appLanguage.languageCode) {
            issues.append("Selected language not in audience's primary languages")
        }
        
        return issues
    }
    
    /// Create a copy of this context
    public func copy() -> CulturalContext {
        let copy = CulturalContext(audience: audience)
        copy.localizationConfig = localizationConfig
        copy.textDirection = textDirection
        copy.colorScheme = colorScheme
        copy.isAccessibilityEnabled = isAccessibilityEnabled
        copy.isHighContrastEnabled = isHighContrastEnabled
        copy.isReducedMotionEnabled = isReducedMotionEnabled
        return copy
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case audience
        case localizationConfig
        case textDirection
        case colorScheme
        case isAccessibilityEnabled
        case isHighContrastEnabled
        case isReducedMotionEnabled
        case createdAt
        case updatedAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(audience, forKey: .audience)
        try container.encode(localizationConfig, forKey: .localizationConfig)
        try container.encode(textDirection, forKey: .textDirection)
        
        // Encode colorScheme as string
        if let scheme = colorScheme {
            try container.encode(scheme == .dark ? "dark" : "light", forKey: .colorScheme)
        }
        
        try container.encode(isAccessibilityEnabled, forKey: .isAccessibilityEnabled)
        try container.encode(isHighContrastEnabled, forKey: .isHighContrastEnabled)
        try container.encode(isReducedMotionEnabled, forKey: .isReducedMotionEnabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        audience = try container.decode(PrimaryAudience.self, forKey: .audience)
        localizationConfig = try container.decode(LocalizationConfig.self, forKey: .localizationConfig)
        textDirection = try container.decode(TextDirection.self, forKey: .textDirection)
        
        // Decode colorScheme from string
        if let schemeString = try container.decodeIfPresent(String.self, forKey: .colorScheme) {
            colorScheme = schemeString == "dark" ? .dark : .light
        } else {
            colorScheme = nil
        }
        
        isAccessibilityEnabled = try container.decode(Bool.self, forKey: .isAccessibilityEnabled)
        isHighContrastEnabled = try container.decode(Bool.self, forKey: .isHighContrastEnabled)
        isReducedMotionEnabled = try container.decode(Bool.self, forKey: .isReducedMotionEnabled)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

// MARK: - Equatable
extension CulturalContext: Equatable {
    public static func == (lhs: CulturalContext, rhs: CulturalContext) -> Bool {
        lhs.audience == rhs.audience &&
        lhs.textDirection == rhs.textDirection &&
        lhs.colorScheme == rhs.colorScheme &&
        lhs.isAccessibilityEnabled == rhs.isAccessibilityEnabled &&
        lhs.isHighContrastEnabled == rhs.isHighContrastEnabled &&
        lhs.isReducedMotionEnabled == rhs.isReducedMotionEnabled
    }
}

// MARK: - Hashable
extension CulturalContext: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(audience)
        hasher.combine(textDirection)
        hasher.combine(colorScheme)
        hasher.combine(isAccessibilityEnabled)
        hasher.combine(isHighContrastEnabled)
        hasher.combine(isReducedMotionEnabled)
    }
}
