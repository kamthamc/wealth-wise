//
//  ThemePreferences.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Theme Preferences
//

import Foundation
import SwiftUI

/// User theme preferences for customizing app appearance
@Observable
public final class ThemePreferences: Codable, Sendable {
    
    // MARK: - Theme Properties
    
    /// Selected theme preference
    public var selectedTheme: ThemeType
    
    /// Accent color preference
    public var accentColor: AccentColor
    
    /// Chart color palette preference
    public var chartColorPalette: ChartColorPalette
    
    /// Animation preferences
    public var animationsEnabled: Bool
    
    /// High contrast accessibility setting
    public var highContrastEnabled: Bool
    
    /// Card display style
    public var cardStyle: CardStyle
    
    /// Graph display style
    public var graphStyle: GraphStyle
    
    /// Cultural theme preference
    public var culturalTheme: CulturalTheme
    
    /// Date of last modification
    public var lastModified: Date
    
    /// Reduce motion accessibility setting
    public var reduceMotion: Bool
    
    // MARK: - Computed Properties
    
    /// Appearance mode (computed from selectedTheme)
    public var appearanceMode: AppearanceMode {
        switch selectedTheme {
        case .system:
            return .automatic
        case .light:
            return .alwaysLight
        case .dark:
            return .alwaysDark
        }
    }
    
    // MARK: - Initialization
    
    public init(
        selectedTheme: ThemeType = .system,
        accentColor: AccentColor = .blue,
        chartColorPalette: ChartColorPalette = .balanced,
        animationsEnabled: Bool = true,
        highContrastEnabled: Bool = false,
        cardStyle: CardStyle = .standard,
        graphStyle: GraphStyle = .modern,
        culturalTheme: CulturalTheme = .none,
        reduceMotion: Bool = false
    ) {
        self.selectedTheme = selectedTheme
        self.accentColor = accentColor
        self.chartColorPalette = chartColorPalette
        self.animationsEnabled = animationsEnabled
        self.highContrastEnabled = highContrastEnabled
        self.cardStyle = cardStyle
        self.graphStyle = graphStyle
        self.culturalTheme = culturalTheme
        self.lastModified = Date()
        self.reduceMotion = reduceMotion
    }
    
    // MARK: - Theme Configuration
    
    /// Configure theme preferences for specific audience
    public func configureForAudience(_ audience: PrimaryAudience) {
        switch audience {
        case .indian:
            selectedTheme = .light
            accentColor = .orange
        case .american:
            selectedTheme = .system
            accentColor = .blue
        case .british:
            selectedTheme = .system
            accentColor = .blue
        case .canadian:
            selectedTheme = .system
            accentColor = .green
        case .australian:
            selectedTheme = .light
            accentColor = .orange
        case .singaporean, .german, .french, .dutch, .swiss, .irish, .luxembourgish, .japanese, .hongKongese, .newZealander, .malaysian, .thai, .filipino, .emirati, .qatari, .saudi, .brazilian, .mexican:
            selectedTheme = .system
            accentColor = .blue
        }
        lastModified = Date()
    }
    
    /// Validate theme preferences for consistency
    public func validate() -> [String] {
        var issues: [String] = []
        
        // Validate accessibility
        if !animationsEnabled && highContrastEnabled {
            issues.append(NSLocalizedString("theme.validation.motion.accessibility", 
                                           comment: "Accessibility improvements may require animations"))
        }
        
        return issues
    }
    
    /// Configure theme based on current cultural context
    public func configureColorScheme(for event: CulturalEvent) {
        switch event {
        case .diwali:
            accentColor = .orange
            culturalTheme = .festival
        case .christmas:
            accentColor = .green
            culturalTheme = .seasonal
        case .newyear:
            accentColor = .blue
            culturalTheme = .celebration
        }
        lastModified = Date()
    }
    
    /// Update theme based on cultural events
    public func updateForCulturalEvent(_ event: CulturalEvent) {
        lastModified = Date()
        configureColorScheme(for: event)
    }
    
    /// Reset to default theme
    public func resetToDefault() {
        selectedTheme = .system
        accentColor = .blue
        chartColorPalette = .balanced
        animationsEnabled = true
        highContrastEnabled = false
        cardStyle = .standard
        graphStyle = .modern
        culturalTheme = .none
        reduceMotion = false
        lastModified = Date()
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case selectedTheme
        case accentColor
        case chartColorPalette
        case animationsEnabled
        case highContrastEnabled
        case cardStyle
        case graphStyle
        case culturalTheme
        case lastModified
        case reduceMotion
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedTheme, forKey: .selectedTheme)
        try container.encode(accentColor, forKey: .accentColor)
        try container.encode(chartColorPalette, forKey: .chartColorPalette)
        try container.encode(animationsEnabled, forKey: .animationsEnabled)
        try container.encode(highContrastEnabled, forKey: .highContrastEnabled)
        try container.encode(cardStyle, forKey: .cardStyle)
        try container.encode(graphStyle, forKey: .graphStyle)
        try container.encode(culturalTheme, forKey: .culturalTheme)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(reduceMotion, forKey: .reduceMotion)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedTheme = try container.decode(ThemeType.self, forKey: .selectedTheme)
        accentColor = try container.decode(AccentColor.self, forKey: .accentColor)
        chartColorPalette = try container.decode(ChartColorPalette.self, forKey: .chartColorPalette)
        animationsEnabled = try container.decode(Bool.self, forKey: .animationsEnabled)
        highContrastEnabled = try container.decode(Bool.self, forKey: .highContrastEnabled)
        cardStyle = try container.decode(CardStyle.self, forKey: .cardStyle)
        graphStyle = try container.decode(GraphStyle.self, forKey: .graphStyle)
        culturalTheme = try container.decode(CulturalTheme.self, forKey: .culturalTheme)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        reduceMotion = try container.decode(Bool.self, forKey: .reduceMotion)
    }
}

// MARK: - Supporting Enums

/// Available theme types
public enum ThemeType: String, CaseIterable, Codable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("theme.type.system", comment: "System theme option")
        case .light:
            return NSLocalizedString("theme.type.light", comment: "Light theme option")
        case .dark:
            return NSLocalizedString("theme.type.dark", comment: "Dark theme option")
        }
    }
}

/// Available accent colors
public enum AccentColor: String, CaseIterable, Codable, Sendable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case indigo = "indigo"
    
    public var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        case .yellow: return .yellow
        case .indigo: return .indigo
        }
    }
    
    public var displayName: String {
        switch self {
        case .blue:
            return NSLocalizedString("accent.blue", comment: "Blue accent color")
        case .green:
            return NSLocalizedString("accent.green", comment: "Green accent color")
        case .orange:
            return NSLocalizedString("accent.orange", comment: "Orange accent color")
        case .red:
            return NSLocalizedString("accent.red", comment: "Red accent color")
        case .purple:
            return NSLocalizedString("accent.purple", comment: "Purple accent color")
        case .pink:
            return NSLocalizedString("accent.pink", comment: "Pink accent color")
        case .yellow:
            return NSLocalizedString("accent.yellow", comment: "Yellow accent color")
        case .indigo:
            return NSLocalizedString("accent.indigo", comment: "Indigo accent color")
        }
    }
}

/// Chart color palettes
public enum ChartColorPalette: String, CaseIterable, Codable, Sendable {
    case standard = "standard"
    case accessible = "accessible"
    case monochrome = "monochrome"
    case vibrant = "vibrant"
    case balanced = "balanced"
    
    public var displayName: String {
        switch self {
        case .standard:
            return NSLocalizedString("palette.standard", comment: "Standard color palette")
        case .accessible:
            return NSLocalizedString("palette.accessible", comment: "Accessible color palette")
        case .monochrome:
            return NSLocalizedString("palette.monochrome", comment: "Monochrome color palette")
        case .vibrant:
            return NSLocalizedString("palette.vibrant", comment: "Vibrant color palette")
        case .balanced:
            return NSLocalizedString("palette.balanced", comment: "Balanced color palette")
        }
    }
}

/// Appearance modes
public enum AppearanceMode: String, CaseIterable, Codable, Sendable {
    case automatic = "automatic"
    case alwaysLight = "alwaysLight"
    case alwaysDark = "alwaysDark"
    
    public var displayName: String {
        switch self {
        case .automatic:
            return NSLocalizedString("appearance.automatic", comment: "Automatic appearance mode")
        case .alwaysLight:
            return NSLocalizedString("appearance.light", comment: "Always light appearance mode")
        case .alwaysDark:
            return NSLocalizedString("appearance.dark", comment: "Always dark appearance mode")
        }
    }
}

/// Card display styles
public enum CardStyle: String, CaseIterable, Codable, Sendable {
    case standard = "standard"
    case minimal = "minimal"
    case detailed = "detailed"
    
    public var displayName: String {
        switch self {
        case .standard:
            return NSLocalizedString("card.standard", comment: "Standard card style")
        case .minimal:
            return NSLocalizedString("card.minimal", comment: "Minimal card style")
        case .detailed:
            return NSLocalizedString("card.detailed", comment: "Detailed card style")
        }
    }
}

/// Graph display styles
public enum GraphStyle: String, CaseIterable, Codable, Sendable {
    case smooth = "smooth"
    case sharp = "sharp"
    case stepped = "stepped"
    case modern = "modern"
    
    public var displayName: String {
        switch self {
        case .smooth:
            return NSLocalizedString("graph.smooth", comment: "Smooth graph style")
        case .sharp:
            return NSLocalizedString("graph.sharp", comment: "Sharp graph style")
        case .stepped:
            return NSLocalizedString("graph.stepped", comment: "Stepped graph style")
        case .modern:
            return NSLocalizedString("graph.modern", comment: "Modern graph style")
        }
    }
}

/// Cultural theme preferences
public enum CulturalTheme: String, CaseIterable, Codable, Sendable {
    case none = "none"
    case festival = "festival"
    case seasonal = "seasonal"
    case celebration = "celebration"
    
    public var displayName: String {
        switch self {
        case .none:
            return NSLocalizedString("cultural.none", comment: "No cultural theme")
        case .festival:
            return NSLocalizedString("cultural.festival", comment: "Festival cultural theme")
        case .seasonal:
            return NSLocalizedString("cultural.seasonal", comment: "Seasonal cultural theme")
        case .celebration:
            return NSLocalizedString("cultural.celebration", comment: "Celebration cultural theme")
        }
    }
}

/// Cultural events that can influence theme
public enum CulturalEvent: String, CaseIterable, Codable, Sendable {
    case diwali = "diwali"
    case christmas = "christmas"
    case newyear = "newyear"
    
    public var displayName: String {
        switch self {
        case .diwali:
            return NSLocalizedString("event.diwali", comment: "Diwali festival")
        case .christmas:
            return NSLocalizedString("event.christmas", comment: "Christmas celebration")
        case .newyear:
            return NSLocalizedString("event.newyear", comment: "New Year celebration")
        }
    }
}