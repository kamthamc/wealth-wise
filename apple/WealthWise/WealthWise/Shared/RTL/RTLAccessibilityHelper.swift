//
//  RTLAccessibilityHelper.swift
//  WealthWise
//
//  Comprehensive RTL accessibility support for VoiceOver and screen readers
//

import SwiftUI
import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// RTL accessibility helper for comprehensive screen reader support
@MainActor
public final class RTLAccessibilityHelper: ObservableObject {
    
    /// Accessibility reading order for RTL layouts
    public enum ReadingOrder {
        case natural
        case reversed
        case custom([Int])
    }
    
    /// Accessibility content configuration for RTL
    public struct AccessibilityConfiguration {
        public let readingOrder: ReadingOrder
        public let shouldAnnounceDirection: Bool
        public let shouldUseRTLGestures: Bool
        public let customLabels: [String: String]
        
        public init(
            readingOrder: ReadingOrder = .natural,
            shouldAnnounceDirection: Bool = false,
            shouldUseRTLGestures: Bool = true,
            customLabels: [String: String] = [:]
        ) {
            self.readingOrder = readingOrder
            self.shouldAnnounceDirection = shouldAnnounceDirection
            self.shouldUseRTLGestures = shouldUseRTLGestures
            self.customLabels = customLabels
        }
    }
    
    @Published public private(set) var isRTLAccessibilityMode: Bool = false
    @Published public private(set) var configuration: AccessibilityConfiguration = AccessibilityConfiguration()
    
    private let biDiHandler = BiDirectionalTextHandler()
    
    public init() {
        detectRTLAccessibilityMode()
        observeAccessibilityChanges()
    }
    
    /// Create accessibility label for RTL content
    public func createAccessibilityLabel(for text: String, context: String? = nil) -> String {
        let analysis = biDiHandler.analyzeBiDiText(text)
        var label = text
        
        // Add direction announcement if needed
        if configuration.shouldAnnounceDirection && analysis.isMixed {
            let directionHint = analysis.overallDirection.isRTL ? 
                NSLocalizedString("accessibility.rtl.content", comment: "Right-to-left content") :
                NSLocalizedString("accessibility.ltr.content", comment: "Left-to-right content")
            label = "\(directionHint), \(label)"
        }
        
        // Add context if provided
        if let context = context {
            label = "\(context), \(label)"
        }
        
        return label
    }
    
    /// Create accessibility hint for RTL navigation
    public func createNavigationHint(action: String, direction: TextDirection) -> String {
        let baseHint = NSLocalizedString("accessibility.navigation.\(action)", comment: "Navigation action: \(action)")
        
        if direction.isRTL && configuration.shouldUseRTLGestures {
            return NSLocalizedString("accessibility.rtl.\(action).hint", comment: "RTL navigation hint for \(action)")
        }
        
        return baseHint
    }
    
    /// Format currency value for accessibility in RTL context
    public func formatCurrencyForAccessibility(
        amount: String,
        currency: String,
        direction: TextDirection
    ) -> String {
        let currencyName = getCurrencyAccessibilityName(currency)
        
        if direction.isRTL {
            return String(format: NSLocalizedString(
                "accessibility.currency.rtl.format",
                value: "%@ %@",
                comment: "RTL currency format: amount currency"
            ), amount, currencyName)
        } else {
            return String(format: NSLocalizedString(
                "accessibility.currency.ltr.format",
                value: "%@ %@",
                comment: "LTR currency format: amount currency"
            ), amount, currencyName)
        }
    }
    
    /// Create accessibility traits for RTL controls
    public func accessibilityTraits(for controlType: String, isRTL: Bool) -> AccessibilityTraits {
        var traits: AccessibilityTraits = []
        
        switch controlType {
        case "button":
            _ = traits.insert(.isButton)
        case "link":
            _ = traits.insert(.isLink)
        case "header":
            _ = traits.insert(.isHeader)
        default:
            break
        }
        
        if isRTL {
            // Add RTL-specific traits if needed
            _ = traits.insert(.updatesFrequently)
        }
        
        return traits
    }
    
    /// Configure reading order for RTL container
    public func configureReadingOrder(for elements: [String], direction: TextDirection) -> [String] {
        guard direction.isRTL else { return elements }
        
        switch configuration.readingOrder {
        case .natural:
            return elements
        case .reversed:
            return elements.reversed()
        case .custom(let order):
            return order.compactMap { index in
                index < elements.count ? elements[index] : nil
            }
        }
    }
    
    /// Create accessibility action for RTL gesture
    public func createRTLAccessibilityAction(
        name: String,
        handler: @escaping () -> Void
    ) -> AccessibilityActionKind {
        return .default
    }
    
    /// Get VoiceOver gesture mapping for RTL
    public func getVoiceOverGestureMapping(for gesture: String, isRTL: Bool) -> String {
        guard isRTL && configuration.shouldUseRTLGestures else { return gesture }
        
        // Map common gestures for RTL
        switch gesture {
        case "swipeRight":
            return "swipeLeft"
        case "swipeLeft":
            return "swipeRight"
        case "flickRight":
            return "flickLeft"
        case "flickLeft":
            return "flickRight"
        default:
            return gesture
        }
    }
    
    /// Update accessibility configuration
    public func updateConfiguration(_ newConfiguration: AccessibilityConfiguration) {
        configuration = newConfiguration
    }
    
    private func detectRTLAccessibilityMode() {
        // Check if system is in RTL mode and accessibility is enabled
        #if canImport(UIKit)
        let isRTL = Locale.Language(identifier: Locale.current.identifier).characterDirection == .rightToLeft
        isRTLAccessibilityMode = UIAccessibility.isVoiceOverRunning && isRTL
        #else
        // macOS fallback - check if system locale is RTL
        isRTLAccessibilityMode = Locale.Language(identifier: Locale.current.identifier).characterDirection == .rightToLeft
        #endif
    }
    
    private func observeAccessibilityChanges() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectRTLAccessibilityMode()
        }
        #endif
        
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.detectRTLAccessibilityMode()
            }
        }
    }
    
    private func getCurrencyAccessibilityName(_ currencyCode: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
    }
}

/// Environment key for RTL accessibility helper
struct RTLAccessibilityHelperKey: EnvironmentKey {
    static let defaultValue = RTLAccessibilityHelper()
}

public extension EnvironmentValues {
    var rtlAccessibilityHelper: RTLAccessibilityHelper {
        get { self[RTLAccessibilityHelperKey.self] }
        set { self[RTLAccessibilityHelperKey.self] = newValue }
    }
}
