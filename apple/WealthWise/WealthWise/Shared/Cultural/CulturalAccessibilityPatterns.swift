//
//  CulturalAccessibilityPatterns.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Cultural accessibility patterns for reading order and navigation
//

import Foundation
import SwiftUI

/// Provides cultural accessibility patterns for reading order, navigation, and VoiceOver
@available(iOS 18.6, macOS 15.6, *)
public final class CulturalAccessibilityPatterns: Sendable {
    
    // MARK: - Properties
    
    private let culturalContext: CulturalContext
    
    // MARK: - Initialization
    
    public init(culturalContext: CulturalContext) {
        self.culturalContext = culturalContext
    }
    
    // MARK: - Reading Order
    
    /// Get reading order for elements
    public func readingOrder() -> AccessibilityReadingOrder {
        culturalContext.isRTL ? .rightToLeft : .leftToRight
    }
    
    /// Get sort priority for accessibility elements based on cultural reading patterns
    public func sortPriority(for element: AccessibilityElement) -> AccessibilitySortPriority {
        if culturalContext.isRTL {
            // RTL reading: right to left, top to bottom
            switch element.position {
            case .topTrailing:
                return .highest
            case .topLeading:
                return .high
            case .bottomTrailing:
                return .medium
            case .bottomLeading:
                return .low
            case .center:
                return .medium
            }
        } else {
            // LTR reading: left to right, top to bottom
            switch element.position {
            case .topLeading:
                return .highest
            case .topTrailing:
                return .high
            case .bottomLeading:
                return .medium
            case .bottomTrailing:
                return .low
            case .center:
                return .medium
            }
        }
    }
    
    // MARK: - Navigation Patterns
    
    /// Get preferred navigation direction
    public func navigationDirection() -> NavigationDirection {
        culturalContext.isRTL ? .rightToLeft : .leftToRight
    }
    
    /// Get gesture hint for navigation
    public func navigationGestureHint() -> String {
        if culturalContext.isRTL {
            return NSLocalizedString("accessibility.gesture.swipeLeft", comment: "Swipe left to go forward")
        } else {
            return NSLocalizedString("accessibility.gesture.swipeRight", comment: "Swipe right to go forward")
        }
    }
    
    /// Get back navigation gesture hint
    public func backNavigationGestureHint() -> String {
        if culturalContext.isRTL {
            return NSLocalizedString("accessibility.gesture.swipeRight", comment: "Swipe right to go back")
        } else {
            return NSLocalizedString("accessibility.gesture.swipeLeft", comment: "Swipe left to go back")
        }
    }
    
    // MARK: - VoiceOver Patterns
    
    /// Generate accessibility label for financial amount
    public func accessibilityLabel(for amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = culturalContext.currentLocale
        
        guard let formattedAmount = formatter.string(from: NSDecimalNumber(decimal: amount)) else {
            return "\(amount) \(currency)"
        }
        
        // Add cultural context
        let amountLabel = NSLocalizedString("accessibility.label.amount", comment: "Amount")
        return "\(amountLabel): \(formattedAmount)"
    }
    
    /// Generate accessibility label for date
    public func accessibilityLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = culturalContext.currentLocale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        
        let formattedDate = formatter.string(from: date)
        let dateLabel = NSLocalizedString("accessibility.label.date", comment: "Date")
        
        return "\(dateLabel): \(formattedDate)"
    }
    
    /// Generate accessibility hint for action
    public func accessibilityHint(for action: AccessibilityAction) -> String {
        let baseKey: String
        
        switch action {
        case .tap:
            baseKey = "accessibility.hint.tap"
        case .doubleTap:
            baseKey = "accessibility.hint.doubleTap"
        case .longPress:
            baseKey = "accessibility.hint.longPress"
        case .swipe:
            baseKey = "accessibility.hint.swipe"
        }
        
        return NSLocalizedString(baseKey, comment: "Accessibility hint")
    }
    
    /// Generate accessibility value for progress
    public func accessibilityValue(for progress: Double, total: Double) -> String {
        let percentage = (progress / total) * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.locale = culturalContext.currentLocale
        
        if let formattedPercentage = formatter.string(from: NSNumber(value: percentage / 100)) {
            let progressLabel = NSLocalizedString("accessibility.value.progress", comment: "Progress")
            return "\(progressLabel): \(formattedPercentage)"
        }
        
        return "\(Int(percentage))%"
    }
    
    // MARK: - Cultural Screen Reader Patterns
    
    /// Get culturally appropriate reading speed hint
    public func readingSpeedHint() -> String {
        // Some languages/scripts benefit from different reading speeds
        switch culturalContext.localizationConfig.appLanguage {
        case .arabic, .thai, .malayalam:
            return NSLocalizedString("accessibility.hint.slowReading", comment: "Consider slower reading speed")
        case .japanese, .chinese:
            return NSLocalizedString("accessibility.hint.normalReading", comment: "Normal reading speed")
        default:
            return NSLocalizedString("accessibility.hint.normalReading", comment: "Normal reading speed")
        }
    }
    
    /// Get culturally appropriate pause duration between elements
    public func pauseDuration() -> TimeInterval {
        switch culturalContext.localizationConfig.appLanguage {
        case .arabic, .thai:
            return 0.5 // Longer pause for complex scripts
        case .japanese, .chinese:
            return 0.3 // Moderate pause for logographic scripts
        default:
            return 0.2 // Standard pause
        }
    }
    
    // MARK: - Element Description Patterns
    
    /// Generate comprehensive accessibility description
    public func generateDescription(
        label: String,
        value: String?,
        hint: String?,
        traits: AccessibilityTraits
    ) -> AccessibilityDescription {
        var description = label
        
        if let value = value {
            description += ". \(value)"
        }
        
        if let hint = hint {
            description += ". \(hint)"
        }
        
        // Add trait descriptions
        if traits.contains(.button) {
            description += ". " + NSLocalizedString("accessibility.trait.button", comment: "Button")
        }
        if traits.contains(.link) {
            description += ". " + NSLocalizedString("accessibility.trait.link", comment: "Link")
        }
        if traits.contains(.header) {
            description += ". " + NSLocalizedString("accessibility.trait.header", comment: "Header")
        }
        
        return AccessibilityDescription(
            fullDescription: description,
            shortDescription: label,
            value: value,
            hint: hint,
            traits: traits
        )
    }
    
    // MARK: - Focus Management
    
    /// Determine if element should auto-focus based on cultural patterns
    public func shouldAutoFocus(element: AccessibilityElement) -> Bool {
        // In RTL layouts, focus patterns may differ
        if culturalContext.isRTL {
            // Focus on rightmost primary element first
            return element.position == .topTrailing && element.importance == .high
        } else {
            // Focus on leftmost primary element first
            return element.position == .topLeading && element.importance == .high
        }
    }
    
    /// Get focus announcement for context change
    public func focusAnnouncement(for context: String) -> String {
        let announcementKey = "accessibility.announcement.contextChange"
        return String(format: NSLocalizedString(announcementKey, comment: "Context changed"), context)
    }
}

// MARK: - Supporting Types

/// Reading order preference
public enum AccessibilityReadingOrder: Sendable {
    case leftToRight
    case rightToLeft
    case topToBottom
}

/// Sort priority for accessibility elements
public enum AccessibilitySortPriority: Int, Comparable, Sendable {
    case lowest = 0
    case low = 25
    case medium = 50
    case high = 75
    case highest = 100
    
    public static func < (lhs: AccessibilitySortPriority, rhs: AccessibilitySortPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Navigation direction
public enum NavigationDirection: Sendable {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
}

/// Accessibility actions
public enum AccessibilityAction: Sendable {
    case tap
    case doubleTap
    case longPress
    case swipe
}

/// Element position for accessibility ordering
public enum ElementPosition: Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
    case center
}

/// Element importance for focus management
public enum ElementImportance: Sendable {
    case low
    case medium
    case high
    case critical
}

/// Accessibility traits
public struct AccessibilityTraits: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let button = AccessibilityTraits(rawValue: 1 << 0)
    public static let link = AccessibilityTraits(rawValue: 1 << 1)
    public static let header = AccessibilityTraits(rawValue: 1 << 2)
    public static let staticText = AccessibilityTraits(rawValue: 1 << 3)
    public static let image = AccessibilityTraits(rawValue: 1 << 4)
}

/// Accessibility element information
public struct AccessibilityElement: Sendable {
    public let position: ElementPosition
    public let importance: ElementImportance
    public let traits: AccessibilityTraits
    
    public init(position: ElementPosition, importance: ElementImportance, traits: AccessibilityTraits) {
        self.position = position
        self.importance = importance
        self.traits = traits
    }
}

/// Complete accessibility description
public struct AccessibilityDescription: Sendable {
    public let fullDescription: String
    public let shortDescription: String
    public let value: String?
    public let hint: String?
    public let traits: AccessibilityTraits
    
    public init(
        fullDescription: String,
        shortDescription: String,
        value: String?,
        hint: String?,
        traits: AccessibilityTraits
    ) {
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.value = value
        self.hint = hint
        self.traits = traits
    }
}

// MARK: - SwiftUI Extensions

@available(iOS 18.6, macOS 15.6, *)
public extension View {
    /// Apply cultural accessibility patterns
    func culturalAccessibility(using patterns: CulturalAccessibilityPatterns) -> some View {
        self.modifier(CulturalAccessibilityModifier(patterns: patterns))
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct CulturalAccessibilityModifier: ViewModifier {
    let patterns: CulturalAccessibilityPatterns
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
    }
}
