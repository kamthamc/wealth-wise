//
//  CulturalContextCoordinator.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Coordinates all cultural components and ensures consistency
//

import Foundation
import SwiftUI
import Combine

/// Coordinates all cultural components to ensure consistency across the application
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class CulturalContextCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether coordination is in progress
    @Published public private(set) var isCoordinating: Bool = false
    
    /// Last coordination timestamp
    @Published public private(set) var lastCoordination: Date?
    
    // MARK: - Dependencies
    
    private let preferencesManager: CulturalPreferencesManager
    private let localizationManager: LocalizationManager
    
    // MARK: - Combine
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        preferencesManager: CulturalPreferencesManager,
        localizationManager: LocalizationManager? = nil
    ) {
        self.preferencesManager = preferencesManager
        self.localizationManager = localizationManager ?? LocalizationManager()
        
        setupCoordination()
    }
    
    // MARK: - Public API
    
    /// Coordinate a change to cultural context
    public func coordinateContextChange(to context: CulturalContext) async {
        isCoordinating = true
        defer {
            isCoordinating = false
            lastCoordination = Date()
        }
        
        // Update preferences manager
        await preferencesManager.switchContext(to: context)
        
        // Update localization manager
        localizationManager.updateCulturalContext(context)
        
        // Notify all observers
        NotificationCenter.default.post(
            name: .culturalContextCoordinated,
            object: self,
            userInfo: ["context": context]
        )
    }
    
    /// Coordinate audience change
    public func coordinateAudienceChange(to audience: PrimaryAudience) async {
        isCoordinating = true
        defer {
            isCoordinating = false
            lastCoordination = Date()
        }
        
        // Update preferences manager
        await preferencesManager.switchAudience(to: audience)
        
        // Update localization manager with new context
        let newContext = preferencesManager.currentContext
        localizationManager.updateCulturalContext(newContext)
        
        // Notify all observers
        NotificationCenter.default.post(
            name: .culturalAudienceChanged,
            object: self,
            userInfo: ["audience": audience]
        )
    }
    
    /// Coordinate text direction change
    public func coordinateTextDirectionChange(to direction: TextDirection) {
        // Update preferences manager
        preferencesManager.updateTextDirection(direction)
        
        // Update localization manager
        localizationManager.updateTextDirection(direction)
        
        // Notify all observers
        NotificationCenter.default.post(
            name: .culturalTextDirectionChanged,
            object: self,
            userInfo: ["direction": direction]
        )
    }
    
    /// Coordinate accessibility settings change
    public func coordinateAccessibilityChange(
        enabled: Bool,
        highContrast: Bool = false,
        reducedMotion: Bool = false
    ) {
        // Update preferences manager
        preferencesManager.updateAccessibility(
            enabled: enabled,
            highContrast: highContrast,
            reducedMotion: reducedMotion
        )
        
        // Notify all observers
        NotificationCenter.default.post(
            name: .culturalAccessibilityChanged,
            object: self,
            userInfo: [
                "enabled": enabled,
                "highContrast": highContrast,
                "reducedMotion": reducedMotion
            ]
        )
    }
    
    /// Validate entire cultural system consistency
    public func validateConsistency() -> [String] {
        var issues: [String] = []
        
        // Validate context
        issues.append(contentsOf: preferencesManager.currentContext.validate())
        
        // Validate locale consistency
        if localizationManager.currentLocale.identifier != preferencesManager.currentContext.currentLocale.identifier {
            issues.append("Locale mismatch between localization manager and cultural context")
        }
        
        // Validate text direction consistency
        if localizationManager.textDirection != preferencesManager.currentContext.textDirection {
            issues.append("Text direction mismatch between components")
        }
        
        return issues
    }
    
    /// Get current cultural state summary
    public func getCurrentState() -> CulturalState {
        CulturalState(
            audience: preferencesManager.currentContext.audience,
            locale: localizationManager.currentLocale,
            textDirection: localizationManager.textDirection,
            isRTL: localizationManager.isRTLActive,
            isAccessibilityEnabled: preferencesManager.currentContext.isAccessibilityEnabled,
            lastUpdate: lastCoordination ?? Date()
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupCoordination() {
        // Observe cultural context changes
        NotificationCenter.default.publisher(for: .culturalContextDidChange)
            .sink { [weak self] notification in
                Task { @MainActor [weak self] in
                    await self?.handleContextChange(notification)
                }
            }
            .store(in: &cancellables)
        
        // Observe text direction changes
        NotificationCenter.default.publisher(for: .textDirectionDidChange)
            .sink { [weak self] notification in
                Task { @MainActor [weak self] in
                    self?.handleTextDirectionChange(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleContextChange(_ notification: Notification) async {
        // Ensure localization manager is synced
        localizationManager.updateCulturalContext(preferencesManager.currentContext)
    }
    
    private func handleTextDirectionChange(_ notification: Notification) {
        if let direction = notification.userInfo?["direction"] as? TextDirection {
            localizationManager.updateTextDirection(direction)
        }
    }
}

// MARK: - Supporting Types

/// Summary of current cultural state
public struct CulturalState: Sendable {
    public let audience: PrimaryAudience
    public let locale: Locale
    public let textDirection: TextDirection
    public let isRTL: Bool
    public let isAccessibilityEnabled: Bool
    public let lastUpdate: Date
    
    public var description: String {
        """
        Cultural State:
        - Audience: \(audience.displayName)
        - Locale: \(locale.identifier)
        - Text Direction: \(textDirection.displayName)
        - RTL: \(isRTL)
        - Accessibility: \(isAccessibilityEnabled)
        - Last Updated: \(lastUpdate)
        """
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let culturalContextCoordinated = Notification.Name("CulturalContextCoordinated")
    static let culturalAudienceChanged = Notification.Name("CulturalAudienceChanged")
    static let culturalTextDirectionChanged = Notification.Name("CulturalTextDirectionChanged")
    static let culturalAccessibilityChanged = Notification.Name("CulturalAccessibilityChanged")
}

// MARK: - Environment Support

@available(iOS 18.6, macOS 15.6, *)
struct CulturalContextCoordinatorKey: EnvironmentKey {
    static let defaultValue: CulturalContextCoordinator? = nil
}

@available(iOS 18.6, macOS 15.6, *)
public extension EnvironmentValues {
    var culturalCoordinator: CulturalContextCoordinator? {
        get { self[CulturalContextCoordinatorKey.self] }
        set { self[CulturalContextCoordinatorKey.self] = newValue }
    }
}
