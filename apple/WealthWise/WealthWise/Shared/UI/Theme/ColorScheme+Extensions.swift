//
//  ColorScheme+Extensions.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: SwiftUI ColorScheme extensions and utilities
//

import Foundation
import SwiftUI
import Combine
import AppKit

// MARK: - ColorScheme Extensions

public extension ColorScheme {
    /// Human-readable name for the color scheme
    var displayName: String {
        switch self {
        case .light:
            return NSLocalizedString("colorscheme.light", comment: "Light color scheme")
        case .dark:
            return NSLocalizedString("colorscheme.dark", comment: "Dark color scheme")
        @unknown default:
            return NSLocalizedString("colorscheme.unknown", comment: "Unknown color scheme")
        }
    }
    
    /// Opposite color scheme
    var opposite: ColorScheme {
        switch self {  
        case .light:
            return .dark
        case .dark:
            return .light
        @unknown default:
            return .light
        }
    }
    
    /// Whether this is a dark color scheme
    var isDark: Bool {
        self == .dark
    }
    
    /// Whether this is a light color scheme  
    var isLight: Bool {
        self == .light
    }
}

// MARK: - Environment Helpers

public extension EnvironmentValues {
    /// Get the current theme manager from environment
    var currentThemeManager: ThemeManager {
        themeManager
    }
    
    /// Get effective color scheme considering user preferences
    var effectiveColorScheme: ColorScheme {
        themeManager.effectiveColorScheme
    }
    
    /// Get semantic colors for current theme
    var semanticColors: SemanticColors {
        themeManager.semanticColors
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply theme-aware color scheme
    func themeAwareColorScheme() -> some View {
        self.modifier(ThemeAwareColorSchemeModifier())
    }
    
    /// Adapt to system color scheme changes
    func adaptToSystemColorScheme() -> some View {
        self.modifier(SystemColorSchemeAdapter())
    }
    
    /// Apply accessibility-enhanced colors
    func accessibilityEnhanced() -> some View {
        self.modifier(AccessibilityEnhancedModifier())
    }
}

// MARK: - View Modifiers

/// Modifier that applies theme-aware color scheme
public struct ThemeAwareColorSchemeModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    
    public func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, themeManager.effectiveColorScheme)
            .preferredColorScheme(
                themeManager.themePreferences.selectedTheme == .system 
                    ? nil 
                    : themeManager.effectiveColorScheme
            )
    }
}

/// Modifier that adapts to system color scheme changes
public struct SystemColorSchemeAdapter: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var themeManager
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, newColorScheme in
                themeManager.updateSystemColorScheme(newColorScheme)
            }
            .onAppear {
                themeManager.updateSystemColorScheme(colorScheme)
            }
    }
}

/// Modifier that applies accessibility-enhanced colors
public struct AccessibilityEnhancedModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                updateAccessibilitySettings()
            }
            .onChange(of: reduceMotion) { _, newValue in
                updateReduceMotion(newValue)
            }
            .onChange(of: increaseContrast) { _, newValue in
                updateIncreaseContrast(newValue)
            }
    }
    
    private func updateAccessibilitySettings() {
        var needsUpdate = false
        
        if themeManager.themePreferences.reduceMotion != reduceMotion {
            themeManager.themePreferences.reduceMotion = reduceMotion
            needsUpdate = true
        }
        
        if themeManager.themePreferences.highContrastEnabled != increaseContrast {
            themeManager.themePreferences.highContrastEnabled = increaseContrast
            needsUpdate = true
        }
        
        if needsUpdate {
            themeManager.saveThemePreferences()
        }
    }
    
    private func updateReduceMotion(_ newValue: Bool) {
        if themeManager.themePreferences.reduceMotion != newValue {
            themeManager.themePreferences.reduceMotion = newValue
            themeManager.themePreferences.animationsEnabled = !newValue
            themeManager.saveThemePreferences()
        }
    }
    
    private func updateIncreaseContrast(_ newValue: Bool) {
        if themeManager.themePreferences.highContrastEnabled != newValue {
            themeManager.themePreferences.highContrastEnabled = newValue
            themeManager.saveThemePreferences()
        }
    }
}

// MARK: - Color Helpers

public extension Color {
    /// Create color that adapts to color scheme
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
    }
    
    /// Create semantic color from system color
    static func semantic(_ systemColor: NSColor) -> Color {
        Color(systemColor)
    }
    
    /// Get platform-specific system color
    static var systemBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    static var systemSecondaryBackground: Color {
        Color(NSColor.controlColor)
    }
    
    static var systemTertiaryBackground: Color {
        Color(NSColor.controlAccentColor.withAlphaComponent(0.1))
    }
    
    static var systemLabel: Color {
        Color(NSColor.labelColor)
    }
    
    static var systemSecondaryLabel: Color {
        Color(NSColor.secondaryLabelColor)
    }
    
    static var systemTertiaryLabel: Color {
        Color(NSColor.tertiaryLabelColor)
    }
    
    static var systemQuaternaryLabel: Color {
        Color(NSColor.quaternaryLabelColor)
    }
    
    static var systemSeparator: Color {
        Color(NSColor.separatorColor)
    }
    
    static var systemOpaqueSeparator: Color {
        Color(NSColor.separatorColor)
    }
}

// MARK: - Theme Detection

public struct ThemeDetector {
    /// Detect current system appearance
    public static func currentSystemAppearance() -> ColorScheme {
        let appearance = NSApp.effectiveAppearance
        return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }
    
    /// Check if system has dark mode enabled
    public static var isSystemDarkMode: Bool {
        currentSystemAppearance() == .dark
    }
    
    /// Check if system supports dark mode
    public static var supportsDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return true
        } else {
            return false
        }
    }
    
    /// Get system accent color
    public static var systemAccentColor: Color {
        Color(NSColor.controlAccentColor)
    }
}

// MARK: - Notification Extensions

public extension Notification.Name {
    static let systemAppearanceDidChange = Notification.Name("NSSystemColorsDidChangeNotification")
}

// MARK: - Environment Observation

/// Observable object for system color scheme changes
@Observable
public class SystemColorSchemeObserver {
    public var currentColorScheme: ColorScheme = ThemeDetector.currentSystemAppearance()
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupObserver()
    }
    
    private func setupObserver() {
        NotificationCenter.default.publisher(for: .systemAppearanceDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.currentColorScheme = ThemeDetector.currentSystemAppearance()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - PreferredColorScheme Helper

public extension View {
    /// Set preferred color scheme based on theme type
    func preferredColorScheme(from themeType: ThemeType) -> some View {
        switch themeType {
        case .system:
            return self.preferredColorScheme(nil)
        case .light:
            return self.preferredColorScheme(.light)
        case .dark:
            return self.preferredColorScheme(.dark)
        }
    }
}

// MARK: - Color Scheme Transition

public struct ColorSchemeTransition: ViewModifier {
    let duration: Double
    let curve: Animation
    
    public init(duration: Double = 0.3, curve: Animation = .easeInOut) {
        self.duration = duration
        self.curve = curve
    }
    
    public func body(content: Content) -> some View {
        content
            .animation(curve.speed(1.0 / duration), value: UUID()) // Trigger animation
    }
}

public extension View {
    /// Add smooth transition when color scheme changes
    func colorSchemeTransition(duration: Double = 0.3, curve: Animation = .easeInOut) -> some View {
        self.modifier(ColorSchemeTransition(duration: duration, curve: curve))
    }
}