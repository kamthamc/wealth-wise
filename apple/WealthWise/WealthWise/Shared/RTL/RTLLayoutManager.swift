//
//  RTLLayoutManager.swift
//  WealthWise
//
//  Comprehensive RTL layout management for SwiftUI views and components
//

import SwiftUI
import Foundation
import Combine

/// RTL layout manager for comprehensive right-to-left layout support
@MainActor
public final class RTLLayoutManager: ObservableObject {
    @Published public private(set) var isRTLLayout: Bool = false
    @Published public private(set) var effectiveLayoutDirection: LayoutDirection = .leftToRight
    
    private let textDirectionDetector = TextDirectionDetector()
    
    public init() {
        updateLayoutDirection()
        observeDirectionChanges()
    }
    
    /// Update layout direction based on current text direction
    public func updateLayoutDirection() {
        let direction = textDirectionDetector.currentDirection
        
        switch direction {
        case .rightToLeft:
            isRTLLayout = true
            effectiveLayoutDirection = .rightToLeft
        case .leftToRight:
            isRTLLayout = false
            effectiveLayoutDirection = .leftToRight
        case .auto:
            let detected = textDirectionDetector.detectedDirection
            isRTLLayout = detected.isRTL
            effectiveLayoutDirection = detected.layoutDirection
        }
    }
    
    /// Get appropriate alignment for RTL/LTR
    public func alignment(leading: Alignment = .leading, trailing: Alignment = .trailing) -> Alignment {
        return isRTLLayout ? trailing : leading
    }
    
    /// Get appropriate text alignment for RTL/LTR
    public func textAlignment(leading: TextAlignment = .leading, trailing: TextAlignment = .trailing) -> TextAlignment {
        return isRTLLayout ? trailing : leading
    }
    
    /// Get appropriate horizontal alignment for RTL/LTR
    public func horizontalAlignment(leading: HorizontalAlignment = .leading, trailing: HorizontalAlignment = .trailing) -> HorizontalAlignment {
        return isRTLLayout ? trailing : leading
    }
    
    /// Get appropriate edge for RTL/LTR
    public func edge(leading: Edge = .leading, trailing: Edge = .trailing) -> Edge {
        return isRTLLayout ? trailing : leading
    }
    
    /// Get appropriate edge set for RTL/LTR
    public func edgeSet(leading: Edge.Set = .leading, trailing: Edge.Set = .trailing) -> Edge.Set {
        return isRTLLayout ? trailing : leading
    }
    
    /// Apply RTL-aware padding
    public func padding(leading: CGFloat = 0, trailing: CGFloat = 0) -> EdgeInsets {
        return isRTLLayout ? 
            EdgeInsets(top: 0, leading: trailing, bottom: 0, trailing: leading) :
            EdgeInsets(top: 0, leading: leading, bottom: 0, trailing: trailing)
    }
    
    /// Get rotation angle for RTL icon mirroring
    public func iconRotation(shouldMirror: Bool = true) -> Angle {
        return (isRTLLayout && shouldMirror) ? .degrees(180) : .zero
    }
    
    /// Get scale transform for RTL icon mirroring
    public func iconScale(shouldMirror: Bool = true) -> CGSize {
        return (isRTLLayout && shouldMirror) ? CGSize(width: -1, height: 1) : CGSize(width: 1, height: 1)
    }
    
    /// Get layout direction for a specific text direction
    public func layoutDirection(for textDirection: TextDirection) -> LayoutDirection {
        return textDirection.layoutDirection
    }
    
    /// Determine if an icon should be mirrored based on type and direction
    public func shouldMirrorIcon(type: RTLIconType, in direction: TextDirection) -> Bool {
        guard direction.isRTL else { return false }
        
        switch type {
        case .navigational, .directional:
            return true  // These should mirror in RTL
        case .content, .status:
            return false  // These should NOT mirror
        case .action:
            return true  // Actions typically mirror
        }
    }
    
    /// Calculate RTL-aware padding by swapping leading and trailing
    public func calculateRTLPadding(_ padding: EdgeInsets) -> EdgeInsets {
        guard isRTLLayout else { return padding }
        
        return EdgeInsets(
            top: padding.top,
            leading: padding.trailing,
            bottom: padding.bottom,
            trailing: padding.leading
        )
    }
    
    private func observeDirectionChanges() {
        textDirectionDetector.$currentDirection
            .sink { [weak self] _ in
                self?.updateLayoutDirection()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

/// RTL layout configuration
public struct RTLLayoutConfiguration {
    public let shouldMirrorIcons: Bool
    public let shouldMirrorAnimations: Bool
    public let shouldAdjustSpacing: Bool
    public let customMirroringRules: [String: Bool]
    
    public init(
        shouldMirrorIcons: Bool = true,
        shouldMirrorAnimations: Bool = true,
        shouldAdjustSpacing: Bool = true,
        customMirroringRules: [String: Bool] = [:]
    ) {
        self.shouldMirrorIcons = shouldMirrorIcons
        self.shouldMirrorAnimations = shouldMirrorAnimations
        self.shouldAdjustSpacing = shouldAdjustSpacing
        self.customMirroringRules = customMirroringRules
    }
    
    public static let `default` = RTLLayoutConfiguration()
}

/// Environment key for RTL layout manager
struct RTLLayoutManagerKey: EnvironmentKey {
    static let defaultValue = RTLLayoutManager()
}

public extension EnvironmentValues {
    var rtlLayoutManager: RTLLayoutManager {
        get { self[RTLLayoutManagerKey.self] }
        set { self[RTLLayoutManagerKey.self] = newValue }
    }
}
