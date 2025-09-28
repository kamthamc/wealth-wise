//
//  View+RTL.swift
//  WealthWise
//
//  SwiftUI View extensions for comprehensive RTL layout support
//

import SwiftUI

public extension View {
    
    /// Apply RTL-aware layout direction
    func rtlAware(_ direction: TextDirection = .auto) -> some View {
        self.modifier(RTLAwareModifier(direction: direction))
    }
    
    /// Apply RTL-aware padding with automatic mirroring
    func rtlPadding(
        leading: CGFloat = 0,
        trailing: CGFloat = 0,
        top: CGFloat = 0,
        bottom: CGFloat = 0
    ) -> some View {
        self.modifier(RTLPaddingModifier(
            leading: leading,
            trailing: trailing,
            top: top,
            bottom: bottom
        ))
    }
    
    /// Apply RTL-aware horizontal padding
    func rtlHorizontalPadding(_ value: CGFloat) -> some View {
        self.rtlPadding(leading: value, trailing: value)
    }
    
    /// Apply RTL-aware alignment
    func rtlAlignment(_ alignment: HorizontalAlignment) -> some View {
        self.modifier(RTLAlignmentModifier(alignment: alignment))
    }
    
    /// Apply RTL-aware animation with direction consideration
    func rtlAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        direction: TextDirection = .auto
    ) -> some View {
        self.modifier(RTLAnimationModifier(animation: animation, value: value, direction: direction))
    }
    
    /// Apply RTL-aware offset
    func rtlOffset(x: CGFloat = 0, y: CGFloat = 0) -> some View {
        self.modifier(RTLOffsetModifier(x: x, y: y))
    }
    
    /// Apply RTL-aware accessibility ordering
    func rtlAccessibilityOrder(_ order: Int) -> some View {
        self.modifier(RTLAccessibilityModifier(order: order))
    }
    
    /// Apply RTL-aware gesture support
    func rtlGesture<T: Gesture>(_ gesture: T) -> some View {
        self.modifier(RTLGestureModifier(gesture: gesture))
    }
    
    /// Apply conditional RTL transformation
    func rtlConditional<T: View>(
        @ViewBuilder rtlTransform: @escaping (Self) -> T
    ) -> some View {
        RTLConditionalView(content: self, rtlTransform: rtlTransform)
    }
}

// MARK: - RTL View Modifiers

/// RTL-aware layout direction modifier
struct RTLAwareModifier: ViewModifier {
    let direction: TextDirection
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.locale) private var locale
    
    private var effectiveDirection: LayoutDirection {
        switch direction {
        case .leftToRight:
            return .leftToRight
        case .rightToLeft:
            return .rightToLeft
        case .auto:
            return Locale.Language(identifier: locale.identifier).characterDirection == .rightToLeft ? 
                   .rightToLeft : .leftToRight
        }
    }
    
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, effectiveDirection)
    }
}

/// RTL-aware padding modifier
struct RTLPaddingModifier: ViewModifier {
    let leading: CGFloat
    let trailing: CGFloat
    let top: CGFloat
    let bottom: CGFloat
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    func body(content: Content) -> some View {
        content
            .padding(.top, top)
            .padding(.bottom, bottom)
            .padding(.leading, layoutDirection == .rightToLeft ? trailing : leading)
            .padding(.trailing, layoutDirection == .rightToLeft ? leading : trailing)
    }
}

/// RTL-aware alignment modifier
struct RTLAlignmentModifier: ViewModifier {
    let alignment: HorizontalAlignment
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var effectiveAlignment: HorizontalAlignment {
        guard layoutDirection == .rightToLeft else { return alignment }
        
        switch alignment {
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        default:
            return alignment
        }
    }
    
    func body(content: Content) -> some View {
        HStack {
            if effectiveAlignment == .trailing {
                Spacer()
            }
            
            content
            
            if effectiveAlignment == .leading {
                Spacer()
            }
        }
    }
}

/// RTL-aware animation modifier
struct RTLAnimationModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    let direction: TextDirection
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    func body(content: Content) -> some View {
        content
            .animation(animation, value: value)
    }
}

/// RTL-aware offset modifier
struct RTLOffsetModifier: ViewModifier {
    let x: CGFloat
    let y: CGFloat
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var effectiveX: CGFloat {
        layoutDirection == .rightToLeft ? -x : x
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: effectiveX, y: y)
    }
}

/// RTL-aware accessibility modifier
struct RTLAccessibilityModifier: ViewModifier {
    let order: Int
    @Environment(\.rtlAccessibilityHelper) private var accessibilityHelper
    
    func body(content: Content) -> some View {
        content
            .accessibilitySortPriority(Double(accessibilityHelper.isRTLAccessibilityMode ? -order : order))
    }
}

/// RTL-aware gesture modifier
struct RTLGestureModifier<T: Gesture>: ViewModifier {
    let gesture: T
    @Environment(\.layoutDirection) private var layoutDirection
    
    func body(content: Content) -> some View {
        content
            .gesture(gesture)
    }
}

/// RTL conditional transformation view
struct RTLConditionalView<Content: View, Transform: View>: View {
    let content: Content
    let rtlTransform: (Content) -> Transform
    @Environment(\.layoutDirection) private var layoutDirection
    
    var body: some View {
        if layoutDirection == .rightToLeft {
            rtlTransform(content)
        } else {
            content
        }
    }
}
