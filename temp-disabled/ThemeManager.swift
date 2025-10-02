//
//  ThemeManager.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Central theme management and coordination
//

import Foundation
import SwiftUI
import Combine

/// Central theme management service for the WealthWise application
@Observable
@MainActor
public final class ThemeManager: Sendable {
    
    // MARK: - Properties
    
    /// Current theme preferences
    public var themePreferences: ThemePreferences
    
    /// Current system color scheme
    public var systemColorScheme: ColorScheme = .light
    
    /// Current effective color scheme (considering user preferences)
    public var effectiveColorScheme: ColorScheme {
        switch themePreferences.selectedTheme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// Whether high contrast mode is active
    public var isHighContrastEnabled: Bool {
        themePreferences.highContrastEnabled
    }
    
    /// Current semantic colors based on theme
    public var semanticColors: SemanticColors {
        SemanticColors(
            colorScheme: effectiveColorScheme,
            accentColor: themePreferences.accentColor,
            isHighContrast: isHighContrastEnabled
        )
    }
    
    /// Theme configuration for UI components
    public var themeConfiguration: ThemeConfiguration {
        ThemeConfiguration(
            preferences: themePreferences,
            effectiveColorScheme: effectiveColorScheme,
            semanticColors: semanticColors
        )
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "ThemePreferences"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    public static let shared = ThemeManager()
    
    private init() {
        self.themePreferences = Self.loadThemePreferences()
        setupSystemColorSchemeObserver()
        setupPreferencesObserver()
    }
    
    // MARK: - Theme Management
    
    /// Update theme preferences
    public func updateTheme(_ newPreferences: ThemePreferences) {
        themePreferences = newPreferences
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    /// Update specific theme property
    public func updateThemeType(_ themeType: ThemeType) {
        themePreferences.selectedTheme = themeType
        themePreferences.lastModified = Date()
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    /// Update accent color
    public func updateAccentColor(_ accentColor: AccentColor) {
        themePreferences.accentColor = accentColor
        themePreferences.lastModified = Date()
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    /// Toggle high contrast mode
    public func toggleHighContrast() {
        themePreferences.highContrastEnabled.toggle()
        themePreferences.lastModified = Date()
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    /// Update system color scheme (called by environment observer)
    public func updateSystemColorScheme(_ colorScheme: ColorScheme) {
        systemColorScheme = colorScheme
        sendThemeChangeNotification()
    }
    
    /// Reset theme to default settings
    public func resetToDefault() {
        themePreferences.resetToDefault()
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    /// Configure theme for specific audience
    public func configureForAudience(_ audience: PrimaryAudience) {
        themePreferences.configureForAudience(audience)
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    /// Update theme for cultural event
    public func updateForCulturalEvent(_ event: CulturalEvent) {
        themePreferences.updateForCulturalEvent(event)
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    // MARK: - Accessibility Support
    
    /// Check if current theme meets accessibility requirements
    public func validateAccessibility() -> [String] {
        var issues: [String] = []
        
        // Check contrast ratios
        if !semanticColors.meetsAccessibilityStandards() {
            issues.append(NSLocalizedString("theme.accessibility.contrast", 
                                           comment: "Theme does not meet contrast requirements"))
        }
        
        // Check motion preferences
        if themePreferences.animationsEnabled && themePreferences.reduceMotion {
            issues.append(NSLocalizedString("theme.accessibility.motion", 
                                           comment: "Animation settings conflict with reduce motion preference"))
        }
        
        return issues
    }
    
    /// Apply accessibility improvements
    public func enhanceAccessibility() {
        if !semanticColors.meetsAccessibilityStandards() {
            themePreferences.highContrastEnabled = true
        }
        
        // Respect system reduce motion setting
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            themePreferences.reduceMotion = true
            themePreferences.animationsEnabled = false
        }
        
        themePreferences.lastModified = Date()
        saveThemePreferences()
        sendThemeChangeNotification()
    }
    
    // MARK: - Private Methods
    
    private static func loadThemePreferences() -> ThemePreferences {
        guard let data = UserDefaults.standard.data(forKey: "ThemePreferences"),
              let preferences = try? JSONDecoder().decode(ThemePreferences.self, from: data) else {
            return ThemePreferences()
        }
        return preferences
    }
    
    public func saveThemePreferences() {
        do {
            let data = try JSONEncoder().encode(themePreferences)
            userDefaults.set(data, forKey: preferencesKey)
        } catch {
            print("Failed to save theme preferences: \(error)")
        }
    }
    
    private func setupSystemColorSchemeObserver() {
        // Monitor system appearance changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.detectSystemColorScheme()
                }
            }
            .store(in: &cancellables)
        
        // Initial detection
        detectSystemColorScheme()
    }
    
    private func detectSystemColorScheme() {
        let appearance = NSApp.effectiveAppearance
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            systemColorScheme = .dark
        } else {
            systemColorScheme = .light
        }
    }
    
    private func setupPreferencesObserver() {
        // Monitor UserDefaults changes for theme preferences
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                // Reload preferences if changed externally
                Task { @MainActor in
                    let newPreferences = Self.loadThemePreferences()
                    if newPreferences.lastModified != self?.themePreferences.lastModified {
                        self?.themePreferences = newPreferences
                        self?.sendThemeChangeNotification()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func sendThemeChangeNotification() {
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: self,
            userInfo: [
                "effectiveColorScheme": effectiveColorScheme,
                "semanticColors": semanticColors,
                "themeConfiguration": themeConfiguration
            ]
        )
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

// MARK: - Environment Key

public struct ThemeManagerKey: EnvironmentKey {
    public static let defaultValue: ThemeManager = ThemeManager.shared
}

public extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Modifier

public struct ThemeAwareModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    
    public func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, themeManager.effectiveColorScheme)
            .accentColor(themeManager.themePreferences.accentColor.swiftUIColor)
            .preferredColorScheme(
                themeManager.themePreferences.selectedTheme == .system ? nil : themeManager.effectiveColorScheme
            )
    }
}

public extension View {
    /// Apply theme-aware styling to the view
    func themeAware() -> some View {
        self.modifier(ThemeAwareModifier())
    }
}