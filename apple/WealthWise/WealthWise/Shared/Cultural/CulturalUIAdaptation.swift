//
//  CulturalUIAdaptation.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Cultural UI adaptation for layouts, colors, and interaction patterns
//

import Foundation
import SwiftUI

/// Provides cultural adaptations for UI elements
@available(iOS 18.6, macOS 15.6, *)
public final class CulturalUIAdaptation: Sendable {
    
    // MARK: - Properties
    
    private let culturalContext: CulturalContext
    
    // MARK: - Initialization
    
    public init(culturalContext: CulturalContext) {
        self.culturalContext = culturalContext
    }
    
    // MARK: - Layout Adaptations
    
    /// Get padding values adapted for cultural preferences
    public func adaptedPadding(base: CGFloat = 16) -> EdgeInsets {
        // RTL may need different padding adjustments
        if culturalContext.isRTL {
            return EdgeInsets(
                top: base,
                leading: base * 1.1,
                bottom: base,
                trailing: base * 0.9
            )
        } else {
            return EdgeInsets(
                top: base,
                leading: base,
                bottom: base,
                trailing: base
            )
        }
    }
    
    /// Get spacing adapted for cultural preferences
    public func adaptedSpacing(base: CGFloat = 8) -> CGFloat {
        // Some cultures prefer more whitespace
        switch culturalContext.audience {
        case .japanese, .chinese:
            return base * 1.2
        case .indian:
            return base * 0.9
        default:
            return base
        }
    }
    
    /// Get alignment adapted for text direction
    public func adaptedAlignment() -> HorizontalAlignment {
        culturalContext.isRTL ? .trailing : .leading
    }
    
    /// Get text alignment adapted for text direction
    public func adaptedTextAlignment() -> TextAlignment {
        culturalContext.isRTL ? .trailing : .leading
    }
    
    // MARK: - Color Adaptations
    
    /// Get culturally appropriate primary color
    public func primaryColor() -> Color {
        // Different cultures have different color associations
        switch culturalContext.audience {
        case .indian:
            // Orange/saffron has cultural significance
            return Color(red: 0.98, green: 0.55, blue: 0.0)
        case .chinese, .hongKongese:
            // Red is auspicious
            return Color(red: 0.85, green: 0.0, blue: 0.0)
        case .japanese:
            // Subtle red
            return Color(red: 0.7, green: 0.0, blue: 0.0)
        case .emirati, .qatari, .saudi:
            // Green is important
            return Color(red: 0.0, green: 0.5, blue: 0.0)
        default:
            // Standard blue
            return Color.blue
        }
    }
    
    /// Get culturally appropriate accent color
    public func accentColor() -> Color {
        switch culturalContext.audience {
        case .indian:
            return Color(red: 0.0, green: 0.5, blue: 0.2) // Green
        case .chinese, .hongKongese:
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case .japanese:
            return Color(red: 1.0, green: 0.0, blue: 0.5) // Pink
        case .emirati, .qatari, .saudi:
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        default:
            return Color.orange
        }
    }
    
    /// Get color for positive financial values (profit, gain)
    public func positiveFinancialColor() -> Color {
        // In most cultures, green = positive
        // But in some contexts, red might be positive (e.g., Chinese stock markets)
        switch culturalContext.audience {
        case .chinese, .hongKongese, .japanese:
            return Color.red // Red is positive in East Asian stock markets
        default:
            return Color.green
        }
    }
    
    /// Get color for negative financial values (loss, debt)
    public func negativeFinancialColor() -> Color {
        switch culturalContext.audience {
        case .chinese, .hongKongese, .japanese:
            return Color.green // Green is negative in East Asian stock markets
        default:
            return Color.red
        }
    }
    
    // MARK: - Typography Adaptations
    
    /// Get font size adapted for cultural reading patterns
    public func adaptedFontSize(base: CGFloat = 17) -> CGFloat {
        var size = base
        
        // Adjust for script complexity
        switch culturalContext.localizationConfig.appLanguage {
        case .arabic, .thai, .malayalam, .kannada, .telugu:
            // Complex scripts may need larger size for readability
            size *= 1.1
        default:
            break
        }
        
        // Adjust for accessibility
        if culturalContext.isAccessibilityEnabled {
            size *= 1.2
        }
        
        return size
    }
    
    /// Get line spacing adapted for script
    public func adaptedLineSpacing(base: CGFloat = 4) -> CGFloat {
        switch culturalContext.localizationConfig.appLanguage {
        case .arabic, .thai, .malayalam:
            return base * 1.3 // More vertical script complexity
        default:
            return base
        }
    }
    
    // MARK: - Interaction Pattern Adaptations
    
    /// Get swipe direction for delete action
    public func deleteSwipeDirection() -> SwipeDirection {
        // RTL languages typically swipe opposite direction
        culturalContext.isRTL ? .leading : .trailing
    }
    
    /// Get preferred navigation style
    public func preferredNavigationStyle() -> NavigationStyle {
        switch culturalContext.audience {
        case .japanese:
            return .minimal // Japanese prefer minimal UI
        case .indian:
            return .detailed // Indian users prefer more visible options
        default:
            return .standard
        }
    }
    
    /// Get animation duration adapted for cultural preferences
    public func animationDuration(base: TimeInterval = 0.3) -> TimeInterval {
        if culturalContext.isReducedMotionEnabled {
            return 0.1 // Minimal animation
        }
        
        switch culturalContext.audience {
        case .japanese:
            return base * 0.8 // Faster, more efficient
        case .indian:
            return base * 1.2 // Slightly slower for visibility
        default:
            return base
        }
    }
    
    // MARK: - Content Adaptations
    
    /// Get culturally appropriate empty state message
    public func emptyStateMessage(for context: ContentContext) -> String {
        let key: String
        
        switch context {
        case .transactions:
            key = "emptyState.transactions"
        case .accounts:
            key = "emptyState.accounts"
        case .goals:
            key = "emptyState.goals"
        case .reports:
            key = "emptyState.reports"
        }
        
        return NSLocalizedString(key, comment: "Empty state message")
    }
    
    /// Get culturally appropriate icon for financial concepts
    public func iconForFinancialConcept(_ concept: FinancialConcept) -> String {
        switch (concept, culturalContext.audience) {
        case (.savings, .japanese):
            return "yensign.circle" // Use yen symbol
        case (.savings, .indian):
            return "indianrupeesign.circle" // Use rupee symbol
        case (.savings, _):
            return "dollarsign.circle"
            
        case (.investment, .indian):
            return "chart.line.uptrend.xyaxis"
        case (.investment, _):
            return "chart.xyaxis.line"
            
        case (.goal, _):
            return "flag.fill"
            
        case (.transaction, _):
            return "arrow.left.arrow.right"
        }
    }
    
    // MARK: - Number Formatting Hints
    
    /// Get format hint for number display
    public func numberFormatHint() -> String {
        switch culturalContext.numberSystem {
        case .indian:
            return NSLocalizedString("format.hint.indian", comment: "Format: Lakh/Crore")
        case .western:
            return NSLocalizedString("format.hint.western", comment: "Format: Million/Billion")
        }
    }
    
    /// Get format hint for date display
    public func dateFormatHint() -> String {
        switch culturalContext.audience.dateFormatStyle {
        case .ddMMYYYY:
            return "DD/MM/YYYY"
        case .mmDDYYYY:
            return "MM/DD/YYYY"
        case .yyyyMMDD:
            return "YYYY/MM/DD"
        case .mixed:
            return NSLocalizedString("format.hint.dateAuto", comment: "Auto")
        }
    }
}

// MARK: - Supporting Types

/// Swipe direction for interactions
public enum SwipeDirection: Sendable {
    case leading
    case trailing
}

/// Navigation style preferences
public enum NavigationStyle: Sendable {
    case minimal
    case standard
    case detailed
}

/// Content context for empty states
public enum ContentContext: Sendable {
    case transactions
    case accounts
    case goals
    case reports
}

/// Financial concept for icon selection
public enum FinancialConcept: Sendable {
    case savings
    case investment
    case goal
    case transaction
}

// MARK: - SwiftUI View Extensions

@available(iOS 18.6, macOS 15.6, *)
public extension View {
    /// Apply cultural adaptations to a view
    func culturallyAdapted(using adapter: CulturalUIAdaptation) -> some View {
        self.modifier(CulturalAdaptationModifier(adapter: adapter))
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct CulturalAdaptationModifier: ViewModifier {
    let adapter: CulturalUIAdaptation
    
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, adapter.culturalContext.layoutDirection)
            .accentColor(adapter.accentColor())
    }
}

// MARK: - Environment Key

@available(iOS 18.6, macOS 15.6, *)
struct CulturalUIAdaptationKey: EnvironmentKey {
    static let defaultValue: CulturalUIAdaptation? = nil
}

@available(iOS 18.6, macOS 15.6, *)
public extension EnvironmentValues {
    var culturalUIAdaptation: CulturalUIAdaptation? {
        get { self[CulturalUIAdaptationKey.self] }
        set { self[CulturalUIAdaptationKey.self] = newValue }
    }
}
