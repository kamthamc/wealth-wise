//
//  ThemedButton.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Themed button component with accessibility support
//

import SwiftUI

/// Themed button that adapts to current theme configuration
public struct ThemedButton: View {
    
    // MARK: - Properties
    
    @Environment(\.themeConfiguration) private var themeConfiguration
    @Environment(\.isEnabled) private var isEnabled
    
    private let title: String
    private let action: () -> Void
    private let style: ThemedButtonStyle
    private let size: ThemedButtonSize
    private let icon: String?
    
    // MARK: - State
    
    @State private var isPressed = false
    
    // MARK: - Initialization
    
    public init(
        _ title: String,
        style: ThemedButtonStyle = .primary,
        size: ThemedButtonSize = .medium,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: size.iconSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.iconFont)
                }
                
                Text(title)
                    .font(size.textFont)
                    .fontWeight(style.fontWeight)
            }
            .padding(size.padding)
            .frame(minWidth: size.minWidth, minHeight: size.minHeight)
        }
        .buttonStyle(ThemedButtonStyleModifier(
            style: style,
            size: size,
            themeConfiguration: themeConfiguration,
            isPressed: $isPressed
        ))
        .disabled(!isEnabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityHint: String {
        if !isEnabled {
            return NSLocalizedString("button.disabled.hint", comment: "Button is disabled")
        }
        
        switch style {
        case .primary:
            return NSLocalizedString("button.primary.hint", comment: "Primary action button")
        case .secondary:
            return NSLocalizedString("button.secondary.hint", comment: "Secondary action button")
        case .tertiary:
            return NSLocalizedString("button.tertiary.hint", comment: "Tertiary action button")
        case .destructive:
            return NSLocalizedString("button.destructive.hint", comment: "Destructive action button")
        case .success:
            return NSLocalizedString("button.success.hint", comment: "Success action button")
        }
    }
}

// MARK: - Button Style Modifier

private struct ThemedButtonStyleModifier: ButtonStyle {
    let style: ThemedButtonStyle
    let size: ThemedButtonSize
    let themeConfiguration: ThemeConfiguration
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(foregroundColor)
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(opacity)
            .animation(themeConfiguration.animationCurve, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        let baseColor = style.backgroundColor(from: themeConfiguration.semanticColors)
        
        if isPressed {
            return baseColor.opacity(0.8)
        }
        
        return baseColor
    }
    
    private var foregroundColor: Color {
        style.foregroundColor(from: themeConfiguration.semanticColors)
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style.hasStroke {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(strokeColor, lineWidth: strokeWidth)
        }
    }
    
    private var strokeColor: Color {
        style.strokeColor(from: themeConfiguration.semanticColors)
    }
    
    private var strokeWidth: CGFloat {
        style.strokeWidth
    }
    
    private var cornerRadius: CGFloat {
        size.cornerRadius
    }
    
    private var opacity: Double {
        themeConfiguration.preferences.animationsEnabled ? 1.0 : 0.9
    }
}

// MARK: - Button Styles

public enum ThemedButtonStyle: String, CaseIterable, Sendable {
    case primary
    case secondary
    case tertiary
    case destructive
    case success
    
    public var displayName: String {
        switch self {
        case .primary:
            return NSLocalizedString("button.style.primary", comment: "Primary button style")
        case .secondary:
            return NSLocalizedString("button.style.secondary", comment: "Secondary button style")
        case .tertiary:
            return NSLocalizedString("button.style.tertiary", comment: "Tertiary button style")
        case .destructive:
            return NSLocalizedString("button.style.destructive", comment: "Destructive button style")
        case .success:
            return NSLocalizedString("button.style.success", comment: "Success button style")
        }
    }
    
    func backgroundColor(from colors: SemanticColors) -> Color {
        switch self {
        case .primary:
            return colors.primary
        case .secondary:
            return colors.secondaryBackground
        case .tertiary:
            return Color.clear
        case .destructive:
            return colors.negative
        case .success:
            return colors.positive
        }
    }
    
    func foregroundColor(from colors: SemanticColors) -> Color {
        switch self {
        case .primary:
            return colors.background
        case .secondary:
            return colors.primaryText
        case .tertiary:
            return colors.primary
        case .destructive:
            return colors.background
        case .success:
            return colors.background
        }
    }
    
    func strokeColor(from colors: SemanticColors) -> Color {
        switch self {
        case .primary, .destructive, .success:
            return Color.clear
        case .secondary:
            return colors.cardStroke
        case .tertiary:
            return colors.primary
        }
    }
    
    var hasStroke: Bool {
        switch self {
        case .primary, .destructive, .success:
            return false
        case .secondary, .tertiary:
            return true
        }
    }
    
    var strokeWidth: CGFloat {
        hasStroke ? 1.0 : 0.0
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .primary, .destructive, .success:
            return .semibold
        case .secondary:
            return .medium
        case .tertiary:
            return .regular
        }
    }
}

// MARK: - Button Sizes

public enum ThemedButtonSize: String, CaseIterable, Sendable {
    case small
    case medium
    case large
    
    public var displayName: String {
        switch self {
        case .small:
            return NSLocalizedString("button.size.small", comment: "Small button size")
        case .medium:
            return NSLocalizedString("button.size.medium", comment: "Medium button size")
        case .large:
            return NSLocalizedString("button.size.large", comment: "Large button size")
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .large:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 4
        case .medium:
            return 6
        case .large:
            return 8
        }
    }
    
    var minWidth: CGFloat {
        switch self {
        case .small:
            return 60
        case .medium:
            return 80
        case .large:
            return 100
        }
    }
    
    var minHeight: CGFloat {
        switch self {
        case .small:
            return 28
        case .medium:
            return 36
        case .large:
            return 44
        }
    }
    
    var textFont: Font {
        switch self {
        case .small:
            return .caption
        case .medium:
            return .body
        case .large:
            return .title3
        }
    }
    
    var iconFont: Font {
        switch self {
        case .small:
            return .caption2
        case .medium:
            return .callout
        case .large:
            return .title3
        }
    }
    
    var iconSpacing: CGFloat {
        switch self {
        case .small:
            return 4
        case .medium:
            return 6
        case .large:
            return 8
        }
    }
}

// MARK: - Convenience Initializers

public extension ThemedButton {
    /// Create primary button
    static func primary(
        _ title: String,
        size: ThemedButtonSize = .medium,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ThemedButton {
        ThemedButton(title, style: .primary, size: size, icon: icon, action: action)
    }
    
    /// Create secondary button
    static func secondary(
        _ title: String,
        size: ThemedButtonSize = .medium,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ThemedButton {
        ThemedButton(title, style: .secondary, size: size, icon: icon, action: action)
    }
    
    /// Create destructive button
    static func destructive(
        _ title: String,
        size: ThemedButtonSize = .medium,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ThemedButton {
        ThemedButton(title, style: .destructive, size: size, icon: icon, action: action)
    }
    
    /// Create success button
    static func success(
        _ title: String,
        size: ThemedButtonSize = .medium,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ThemedButton {
        ThemedButton(title, style: .success, size: size, icon: icon, action: action)
    }
}