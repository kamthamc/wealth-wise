//
//  Text+BiDirectional.swift
//  WealthWise
//
//  SwiftUI Text extensions for comprehensive bidirectional text support
//

import SwiftUI
import Foundation

public extension Text {
    
    /// Create text with automatic bidirectional support
    static func biDirectional(
        _ content: String,
        direction: TextDirection = .auto
    ) -> Text {
        let handler = BiDirectionalTextHandler()
        let analysis = handler.analyzeBiDiText(content)
        
        // Use attributed string for complex bidirectional content
        if analysis.isMixed {
            let attributedString = handler.createAttributedString(from: content, baseDirection: direction)
            return Text(AttributedString(attributedString))
        } else {
            return Text(content)
        }
    }
    
    /// Create currency text with proper RTL formatting
    static func currency(
        amount: String,
        symbol: String,
        direction: TextDirection = .auto
    ) -> Text {
        let handler = BiDirectionalTextHandler()
        let formattedCurrency = handler.formatCurrency(amount, symbol: symbol, direction: direction)
        return Text.biDirectional(formattedCurrency, direction: direction)
    }
    
    /// Create number text with proper RTL formatting
    static func number(
        _ number: String,
        direction: TextDirection = .auto
    ) -> Text {
        let handler = BiDirectionalTextHandler()
        let formattedNumber = handler.formatNumber(number, in: direction)
        return Text.biDirectional(formattedNumber, direction: direction)
    }
    
    /// Apply bidirectional formatting to existing text
    func biDirectional(direction: TextDirection = .auto) -> Text {
        // Extract string content (simplified for demo)
        // In real implementation, would need to extract from Text view
        let _ = BiDirectionalTextHandler()
        return self
    }
    
    /// Apply RTL-aware text alignment
    func rtlAlignment(_ alignment: TextAlignment = .leading) -> some View {
        self.modifier(RTLTextAlignmentModifier(alignment: alignment))
    }
    
    /// Apply RTL-aware line limit with proper truncation
    func rtlLineLimit(_ limit: Int) -> some View {
        self.modifier(RTLLineLimitModifier(limit: limit))
    }
    
    /// Apply RTL-aware truncation mode
    func rtlTruncationMode(_ mode: Text.TruncationMode) -> some View {
        self.modifier(RTLTruncationModifier(mode: mode))
    }
    
    /// Apply directional marks for proper display
    func withDirectionalMarks(direction: TextDirection) -> Text {
        // Note: This is a simplified version - actual implementation would require
        // text extraction and recomposition
        return self
    }
}

// MARK: - RTL Text Modifiers

/// RTL-aware text alignment modifier
struct RTLTextAlignmentModifier: ViewModifier {
    let alignment: TextAlignment
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var effectiveAlignment: TextAlignment {
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
        content
            .multilineTextAlignment(effectiveAlignment)
    }
}

/// RTL-aware line limit modifier
struct RTLLineLimitModifier: ViewModifier {
    let limit: Int
    
    func body(content: Content) -> some View {
        content
            .lineLimit(limit)
    }
}

/// RTL-aware truncation modifier
struct RTLTruncationModifier: ViewModifier {
    let mode: Text.TruncationMode
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var effectiveMode: Text.TruncationMode {
        guard layoutDirection == .rightToLeft else { return mode }
        
        switch mode {
        case .head:
            return .tail
        case .tail:
            return .head
        default:
            return mode
        }
    }
    
    func body(content: Content) -> some View {
        content
            .truncationMode(effectiveMode)
    }
}

// MARK: - Bidirectional Text Helpers

/// Helper for creating bidirectional text components
public struct BiDirectionalTextView: View {
    let content: String
    let direction: TextDirection
    let font: Font
    let color: Color
    
    private let handler = BiDirectionalTextHandler()
    
    public init(
        _ content: String,
        direction: TextDirection = .auto,
        font: Font = .body,
        color: Color = .primary
    ) {
        self.content = content
        self.direction = direction
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        let analysis = handler.analyzeBiDiText(content)
        
        if analysis.isMixed {
            let attributedString = handler.createAttributedString(from: content, baseDirection: direction)
            Text(AttributedString(attributedString))
                .font(font)
                .foregroundColor(color)
        } else {
            Text(content)
                .font(font)
                .foregroundColor(color)
                .rtlAware(direction)
        }
    }
}

/// Helper for creating currency display
public struct CurrencyText: View {
    let amount: String
    let symbol: String
    let direction: TextDirection
    let font: Font
    let color: Color
    
    private let handler = BiDirectionalTextHandler()
    
    public init(
        amount: String,
        symbol: String,
        direction: TextDirection = .auto,
        font: Font = .body,
        color: Color = .primary
    ) {
        self.amount = amount
        self.symbol = symbol
        self.direction = direction
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        let formattedCurrency = handler.formatCurrency(amount, symbol: symbol, direction: direction)
        
        BiDirectionalTextView(
            formattedCurrency,
            direction: direction,
            font: font,
            color: color
        )
    }
}
