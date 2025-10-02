//
//  LocalizationManager.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Centralized localization management integrating with cultural preferences
//

import Foundation
import SwiftUI
import Combine

/// Centralized localization manager integrating string catalog with cultural context
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class LocalizationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current locale
    @Published public private(set) var currentLocale: Locale
    
    /// Current text direction
    @Published public private(set) var textDirection: TextDirection
    
    /// Is RTL mode active
    @Published public private(set) var isRTLActive: Bool
    
    // MARK: - Dependencies
    
    private let stringCatalogManager: StringCatalogManager
    private var culturalContext: CulturalContext?
    
    // MARK: - Initialization
    
    public init(
        stringCatalogManager: StringCatalogManager? = nil,
        culturalContext: CulturalContext? = nil
    ) {
        self.stringCatalogManager = stringCatalogManager ?? StringCatalogManager()
        self.culturalContext = culturalContext
        
        // Initialize with current locale
        self.currentLocale = self.stringCatalogManager.currentLocale
        self.textDirection = culturalContext?.textDirection ?? .auto
        self.isRTLActive = self.textDirection.isRTL
    }
    
    // MARK: - Public API
    
    /// Get localized string for key
    public func string(for key: LocalizationKey) -> String {
        stringCatalogManager.localizedString(for: key)
    }
    
    /// Get localized string with context
    public func string(for key: LocalizationKey, context: LocalizationContext) -> String {
        stringCatalogManager.localizedString(for: key, context: context)
    }
    
    /// Get localized string with audience adaptation
    public func string(for key: LocalizationKey, audience: PrimaryAudience) -> String {
        stringCatalogManager.localizedString(for: key, context: .cultural, audience: audience)
    }
    
    /// Change locale
    public func changeLocale(to locale: Locale) {
        if stringCatalogManager.changeLocale(to: locale) {
            currentLocale = locale
            updateTextDirection()
        }
    }
    
    /// Update cultural context
    public func updateCulturalContext(_ context: CulturalContext) {
        culturalContext = context
        currentLocale = context.currentLocale
        textDirection = context.textDirection
        isRTLActive = context.isRTL
        
        stringCatalogManager.changeLocale(to: context.currentLocale)
    }
    
    /// Update text direction
    public func updateTextDirection(_ direction: TextDirection) {
        textDirection = direction
        isRTLActive = direction.isRTL
    }
    
    // MARK: - Private Implementation
    
    private func updateTextDirection() {
        let detector = TextDirectionDetector()
        detector.detectSystemDirection()
        textDirection = detector.detectedDirection
        isRTLActive = textDirection.isRTL
    }
}

// MARK: - Environment Support

@available(iOS 18.6, macOS 15.6, *)
struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue: LocalizationManager? = nil
}

@available(iOS 18.6, macOS 15.6, *)
public extension EnvironmentValues {
    var localizationManager: LocalizationManager? {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
