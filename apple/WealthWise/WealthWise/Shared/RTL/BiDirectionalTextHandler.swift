//
//  BiDirectionalTextHandler.swift
//  WealthWise
//
//  Comprehensive bidirectional text handling for mixed RTL/LTR content
//

import Foundation
import SwiftUI
import Combine

/// Bidirectional text handler for mixed RTL/LTR content
public final class BiDirectionalTextHandler: ObservableObject {
    
    @Published private var lastAnalyzedText: String = ""
    
    /// Text segment with direction information
    public struct TextSegment {
        public let text: String
        public let direction: TextDirection
        public let range: NSRange
        
        public init(text: String, direction: TextDirection, range: NSRange) {
            self.text = text
            self.direction = direction
            self.range = range
        }
    }
    
    /// Bidirectional text analysis result
    public struct BiDiAnalysis {
        public let segments: [TextSegment]
        public let overallDirection: TextDirection
        public let hasRTLContent: Bool
        public let hasLTRContent: Bool
        public let isMixed: Bool
        
        public init(segments: [TextSegment], overallDirection: TextDirection) {
            self.segments = segments
            self.overallDirection = overallDirection
            self.hasRTLContent = segments.contains { $0.direction.isRTL }
            self.hasLTRContent = segments.contains { $0.direction.isLTR }
            self.isMixed = hasRTLContent && hasLTRContent
        }
    }
    
    private let rtlDetector = TextDirectionDetector()
    
    public init() {}
    
    /// Analyze bidirectional text content
    public func analyzeBiDiText(_ text: String) -> BiDiAnalysis {
        guard !text.isEmpty else {
            return BiDiAnalysis(segments: [], overallDirection: .leftToRight)
        }
        
        let segments = segmentText(text)
        let overallDirection = determineOverallDirection(segments)
        
        return BiDiAnalysis(segments: segments, overallDirection: overallDirection)
    }
    
    /// Create attributed string with proper bidirectional support
    public func createAttributedString(from text: String, baseDirection: TextDirection? = nil) -> NSAttributedString {
        let analysis = analyzeBiDiText(text)
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply writing direction attributes
        let direction = baseDirection ?? analysis.overallDirection
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.baseWritingDirection = direction.isRTL ? .rightToLeft : .leftToRight
        
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: text.count)
        )
        
        // Apply segment-specific directions
        for segment in analysis.segments {
            if segment.direction != direction {
                let segmentDirection: NSWritingDirection = segment.direction.isRTL ? .rightToLeft : .leftToRight
                attributedString.addAttribute(
                    .writingDirection,
                    value: [segmentDirection.rawValue],
                    range: segment.range
                )
            }
        }
        
        return attributedString
    }
    
    /// Format number or currency for bidirectional context
    public func formatNumber(_ number: String, in direction: TextDirection) -> String {
        guard direction.isRTL else { return number }
        
        // Add RTL mark to ensure proper number display in RTL context
        let rtlMark = "\u{200F}" // Right-to-Left Mark
        let ltrMark = "\u{200E}" // Left-to-Right Mark
        
        // Wrap numbers in LTR marks to maintain proper display
        return "\(rtlMark)\(ltrMark)\(number)\(ltrMark)\(rtlMark)"
    }
    
    /// Format currency for bidirectional context
    public func formatCurrency(_ amount: String, symbol: String, direction: TextDirection) -> String {
        if direction.isRTL {
            // RTL: symbol comes after amount
            return "\(formatNumber(amount, in: direction)) \(symbol)"
        } else {
            // LTR: symbol comes before amount
            return "\(symbol)\(formatNumber(amount, in: direction))"
        }
    }
    
    /// Create text with directional marks for proper display
    public func wrapWithDirectionalMarks(_ text: String, direction: TextDirection) -> String {
        let startMark: String
        let endMark = "\u{202C}" // Pop Directional Formatting
        
        switch direction {
        case .rightToLeft:
            startMark = "\u{202E}" // Right-to-Left Override
        case .leftToRight:
            startMark = "\u{202D}" // Left-to-Right Override
        case .auto:
            return text // No override needed
        }
        
        return "\(startMark)\(text)\(endMark)"
    }
    
    private func segmentText(_ text: String) -> [TextSegment] {
        var segments: [TextSegment] = []
        var currentSegmentStart = 0
        var currentDirection: TextDirection?
        
        for (index, character) in text.enumerated() {
            let charDirection = getCharacterDirection(character)
            
            if currentDirection == nil {
                currentDirection = charDirection
            } else if currentDirection != charDirection && charDirection != .auto {
                // Create segment for previous direction
                if currentSegmentStart < index {
                    let segmentText = String(text[text.index(text.startIndex, offsetBy: currentSegmentStart)..<text.index(text.startIndex, offsetBy: index)])
                    let range = NSRange(location: currentSegmentStart, length: index - currentSegmentStart)
                    segments.append(TextSegment(text: segmentText, direction: currentDirection!, range: range))
                }
                
                currentSegmentStart = index
                currentDirection = charDirection
            }
        }
        
        // Add final segment
        if currentSegmentStart < text.count, let direction = currentDirection {
            let segmentText = String(text[text.index(text.startIndex, offsetBy: currentSegmentStart)...])
            let range = NSRange(location: currentSegmentStart, length: text.count - currentSegmentStart)
            segments.append(TextSegment(text: segmentText, direction: direction, range: range))
        }
        
        return segments
    }
    
    private func getCharacterDirection(_ character: Character) -> TextDirection {
        let scalar = character.unicodeScalars.first!
        
        // RTL scripts
        if scalar.value >= 0x0590 && scalar.value <= 0x05FF || // Hebrew
           scalar.value >= 0x0600 && scalar.value <= 0x06FF || // Arabic
           scalar.value >= 0x0750 && scalar.value <= 0x077F || // Arabic Supplement
           scalar.value >= 0x08A0 && scalar.value <= 0x08FF || // Arabic Extended-A
           scalar.value >= 0xFB50 && scalar.value <= 0xFDFF || // Arabic Presentation Forms-A
           scalar.value >= 0xFE70 && scalar.value <= 0xFEFF {  // Arabic Presentation Forms-B
            return .rightToLeft
        }
        
        // LTR scripts (Latin, Cyrillic, etc.)
        if scalar.value >= 0x0041 && scalar.value <= 0x005A || // A-Z
           scalar.value >= 0x0061 && scalar.value <= 0x007A || // a-z
           scalar.value >= 0x00C0 && scalar.value <= 0x00FF || // Latin-1 Supplement
           scalar.value >= 0x0100 && scalar.value <= 0x017F {  // Latin Extended-A
            return .leftToRight
        }
        
        // Neutral characters
        return .auto
    }
    
    private func determineOverallDirection(_ segments: [TextSegment]) -> TextDirection {
        let rtlCount = segments.filter { $0.direction.isRTL }.count
        let ltrCount = segments.filter { $0.direction.isLTR }.count
        
        if rtlCount > ltrCount {
            return .rightToLeft
        } else if ltrCount > rtlCount {
            return .leftToRight
        } else {
            return .auto
        }
    }
}