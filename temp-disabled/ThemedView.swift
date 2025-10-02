//
//  ThemedView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Base themed view component
//

import SwiftUI

/// Base view that automatically applies theme styling
public struct ThemedView<Content: View>: View {
    
    // MARK: - Properties
    
    @Environment(\.themeConfiguration) private var themeConfiguration
    
    private let content: Content
    private let style: ThemedViewStyle
    
    // MARK: - Initialization
    
    public init(
        style: ThemedViewStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.x,
                y: shadowOffset.y
            )
            .animation(themeConfiguration.animationCurve, value: themeConfiguration.preferences.selectedTheme)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .default:
            return themeConfiguration.semanticColors.background
        case .card:
            return themeConfiguration.semanticColors.secondaryBackground
        case .elevated:
            return themeConfiguration.semanticColors.tertiaryBackground
        case .primary:
            return themeConfiguration.semanticColors.primary
        case .transparent:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .default, .card, .elevated, .transparent:
            return themeConfiguration.semanticColors.primaryText
        case .primary:
            return themeConfiguration.semanticColors.background
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .default, .transparent:
            return 0
        case .card:
            return themeConfiguration.cardCornerRadius
        case .elevated:
            return themeConfiguration.cardCornerRadius * 1.5
        case .primary:
            return themeConfiguration.cardCornerRadius * 0.75
        }
    }
    
    private var shadowColor: Color {
        guard style != .transparent else { return Color.clear }
        
        let shadow = themeConfiguration.cardShadow
        return shadow.color
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .default, .transparent:
            return 0
        case .card:
            return themeConfiguration.cardShadow.radius
        case .elevated:
            return themeConfiguration.cardShadow.radius * 2
        case .primary:
            return themeConfiguration.cardShadow.radius * 0.5
        }
    }
    
    private var shadowOffset: CGPoint {
        let shadow = themeConfiguration.cardShadow
        return CGPoint(x: shadow.x, y: shadow.y)
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .card || style == .elevated {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(themeConfiguration.semanticColors.cardStroke, lineWidth: 0.5)
        }
    }
}

// MARK: - Themed View Style

public enum ThemedViewStyle: String, CaseIterable, Sendable {
    case `default`
    case card
    case elevated
    case primary
    case transparent
    
    public var displayName: String {
        switch self {
        case .default:
            return NSLocalizedString("themed_view.style.default", comment: "Default view style")
        case .card:
            return NSLocalizedString("themed_view.style.card", comment: "Card view style")
        case .elevated:
            return NSLocalizedString("themed_view.style.elevated", comment: "Elevated view style")
        case .primary:
            return NSLocalizedString("themed_view.style.primary", comment: "Primary view style")
        case .transparent:
            return NSLocalizedString("themed_view.style.transparent", comment: "Transparent view style")
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply themed view styling
    func themedView(style: ThemedViewStyle = .default) -> some View {
        ThemedView(style: style) {
            self
        }
    }
    
    /// Apply card styling
    func themedCard() -> some View {
        themedView(style: .card)
    }
    
    /// Apply elevated styling
    func themedElevated() -> some View {
        themedView(style: .elevated)
    }
    
    /// Apply primary styling
    func themedPrimary() -> some View {
        themedView(style: .primary)
    }
}