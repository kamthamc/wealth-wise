//
//  ThemedCard.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Themed card component with financial styling
//

import SwiftUI

/// Themed card component for displaying financial information
public struct ThemedCard<Content: View>: View {
    
    // MARK: - Properties
    
    @Environment(\.themeConfiguration) private var themeConfiguration
    
    private let content: Content
    private let style: ThemedCardStyle
    private let padding: EdgeInsets?
    private let header: String?
    private let footer: String?
    
    // MARK: - Initialization
    
    public init(
        style: ThemedCardStyle = .standard,
        padding: EdgeInsets? = nil,
        header: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.header = header
        self.footer = footer
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header = header {
                headerView(header)
            }
            
            content
                .padding(effectivePadding)
            
            if let footer = footer {
                footerView(footer)
            }
        }
        .background(backgroundColor)
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
    
    // MARK: - Header and Footer
    
    @ViewBuilder
    private func headerView(_ title: String) -> some View {
        ThemedText.secondary(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, effectivePadding.leading)
            .padding(.top, effectivePadding.top)
            .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func footerView(_ title: String) -> some View {
        Divider()
            .overlay(themeConfiguration.semanticColors.separator)
        
        ThemedText.tertiary(title)
            .font(.caption2)
            .padding(.horizontal, effectivePadding.leading)
            .padding(.bottom, effectivePadding.bottom)
            .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .standard:
            return themeConfiguration.semanticColors.secondaryBackground
        case .elevated:
            return themeConfiguration.semanticColors.background
        case .outlined:
            return themeConfiguration.semanticColors.background
        case .financial:
            return themeConfiguration.semanticColors.secondaryBackground
        case .warning:
            return themeConfiguration.semanticColors.warning.opacity(0.1)
        case .success:
            return themeConfiguration.semanticColors.positive.opacity(0.1)
        case .error:
            return themeConfiguration.semanticColors.negative.opacity(0.1)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(strokeColor, lineWidth: strokeWidth)
    }
    
    private var strokeColor: Color {
        switch style {
        case .standard, .elevated, .financial:
            return themeConfiguration.semanticColors.cardStroke
        case .outlined:
            return themeConfiguration.semanticColors.separator
        case .warning:
            return themeConfiguration.semanticColors.warning.opacity(0.3)
        case .success:
            return themeConfiguration.semanticColors.positive.opacity(0.3)
        case .error:
            return themeConfiguration.semanticColors.negative.opacity(0.3)
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .standard, .elevated, .financial:
            return 0.5
        case .outlined:
            return 1.0
        case .warning, .success, .error:
            return 1.0
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard, .outlined:
            return themeConfiguration.cardCornerRadius
        case .elevated:
            return themeConfiguration.cardCornerRadius * 1.2
        case .financial:
            return themeConfiguration.cardCornerRadius * 0.8
        case .warning, .success, .error:
            return themeConfiguration.cardCornerRadius
        }
    }
    
    private var shadowColor: Color {
        let baseShadow = themeConfiguration.cardShadow
        
        switch style {
        case .standard, .financial:
            return baseShadow.color
        case .elevated:
            return baseShadow.color.opacity(0.15)
        case .outlined:
            return Color.clear
        case .warning:
            return themeConfiguration.semanticColors.warning.opacity(0.1)
        case .success:
            return themeConfiguration.semanticColors.positive.opacity(0.1)
        case .error:
            return themeConfiguration.semanticColors.negative.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        let baseShadow = themeConfiguration.cardShadow
        
        switch style {
        case .standard, .financial:
            return baseShadow.radius
        case .elevated:
            return baseShadow.radius * 2
        case .outlined:
            return 0
        case .warning, .success, .error:
            return baseShadow.radius * 0.5
        }
    }
    
    private var shadowOffset: CGPoint {
        let baseShadow = themeConfiguration.cardShadow
        
        switch style {
        case .elevated:
            return CGPoint(x: baseShadow.x, y: baseShadow.y * 2)
        default:
            return CGPoint(x: baseShadow.x, y: baseShadow.y)
        }
    }
    
    private var effectivePadding: EdgeInsets {
        if let padding = padding {
            return padding
        }
        
        switch style {
        case .standard, .outlined:
            return themeConfiguration.cardPadding
        case .elevated:
            let base = themeConfiguration.cardPadding
            return EdgeInsets(
                top: base.top * 1.2,
                leading: base.leading * 1.2,
                bottom: base.bottom * 1.2,
                trailing: base.trailing * 1.2
            )
        case .financial:
            let base = themeConfiguration.cardPadding
            return EdgeInsets(
                top: base.top * 0.8,
                leading: base.leading,
                bottom: base.bottom * 0.8,
                trailing: base.trailing
            )
        case .warning, .success, .error:
            return themeConfiguration.cardPadding
        }
    }
}

// MARK: - Card Styles

public enum ThemedCardStyle: String, CaseIterable, Sendable {
    case standard
    case elevated
    case outlined
    case financial
    case warning
    case success
    case error
    
    public var displayName: String {
        switch self {
        case .standard:
            return NSLocalizedString("card.style.standard", comment: "Standard card style")
        case .elevated:
            return NSLocalizedString("card.style.elevated", comment: "Elevated card style")
        case .outlined:
            return NSLocalizedString("card.style.outlined", comment: "Outlined card style")
        case .financial:
            return NSLocalizedString("card.style.financial", comment: "Financial card style")
        case .warning:
            return NSLocalizedString("card.style.warning", comment: "Warning card style")
        case .success:
            return NSLocalizedString("card.style.success", comment: "Success card style")
        case .error:
            return NSLocalizedString("card.style.error", comment: "Error card style")
        }
    }
}

// MARK: - Convenience Extensions

public extension View {
    /// Wrap view in themed card
    func themedCard(
        style: ThemedCardStyle = .standard,
        padding: EdgeInsets? = nil,
        header: String? = nil,
        footer: String? = nil
    ) -> some View {
        ThemedCard(style: style, padding: padding, header: header, footer: footer) {
            self
        }
    }
    
    /// Wrap view in financial card
    func financialCard(
        header: String? = nil,
        footer: String? = nil
    ) -> some View {
        themedCard(style: .financial, header: header, footer: footer)
    }
    
    /// Wrap view in elevated card
    func elevatedCard(
        header: String? = nil,
        footer: String? = nil
    ) -> some View {
        themedCard(style: .elevated, header: header, footer: footer)
    }
}

// MARK: - Financial Card Variants

public extension ThemedCard {
    /// Create financial summary card
    static func financialSummary<T: View>(
        title: String,
        @ViewBuilder content: @escaping () -> T
    ) -> ThemedCard<T> {
        ThemedCard<T>(
            style: .financial,
            header: title,
            content: content
        )
    }
    
    /// Create account balance card
    static func accountBalance<T: View>(
        accountName: String,
        @ViewBuilder content: @escaping () -> T
    ) -> ThemedCard<T> {
        ThemedCard<T>(
            style: .financial,
            header: accountName,
            footer: NSLocalizedString("card.footer.updated_now", comment: "Updated now"),
            content: content
        )
    }
    
    /// Create warning card
    static func warning<T: View>(
        title: String,
        @ViewBuilder content: @escaping () -> T
    ) -> ThemedCard<T> {
        ThemedCard<T>(
            style: .warning,
            header: title,
            content: content
        )
    }
}