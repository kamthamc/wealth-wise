import Foundation

/// Cultural numbering system for different locales and audiences
/// Supports Indian lakh/crore system vs Western million/billion system
public enum CulturalNumberingSystem: String, CaseIterable, Codable {
    case indian = "indian"
    case western = "western"
    case british = "british"
    case european = "european"
    case arabic = "arabic"
    
    /// Get numbering system based on audience
    public static func forAudience(_ audience: PrimaryAudience) -> CulturalNumberingSystem {
        switch audience {
        case .indian:
            return .indian
        case .american, .canadian, .australian, .singaporean:
            return .western
        case .british, .irish:
            return .british
        case .german, .french, .dutch, .swiss, .luxembourgish:
            return .european
        case .emirati, .qatari, .saudi:
            return .arabic
        default:
            return .western
        }
    }
    
    /// Number separators and formatting rules
    public var separators: NumberSeparators {
        switch self {
        case .indian:
            return NumberSeparators(
                decimalSeparator: ".",
                groupingSeparator: ",",
                groupingSize: [3, 2], // Indian: 1,00,00,000
                useGrouping: true
            )
        case .western, .british:
            return NumberSeparators(
                decimalSeparator: ".",
                groupingSeparator: ",",
                groupingSize: [3], // Western: 1,000,000
                useGrouping: true
            )
        case .european:
            return NumberSeparators(
                decimalSeparator: ",",
                groupingSeparator: ".",
                groupingSize: [3], // European: 1.000.000,00
                useGrouping: true
            )
        case .arabic:
            return NumberSeparators(
                decimalSeparator: ".",
                groupingSeparator: ",",
                groupingSize: [3],
                useGrouping: true
            )
        }
    }
    
    /// Large number abbreviations
    public func abbreviation(for value: Decimal) -> String? {
        let absValue = abs(value)
        
        switch self {
        case .indian:
            if absValue >= 10_000_000 { // 1 crore
                let crores = value / 10_000_000
                return formatAbbreviation(crores, suffix: "Cr")
            } else if absValue >= 100_000 { // 1 lakh
                let lakhs = value / 100_000
                return formatAbbreviation(lakhs, suffix: "L")
            } else if absValue >= 1_000 { // 1 thousand
                let thousands = value / 1_000
                return formatAbbreviation(thousands, suffix: "K")
            }
            
        case .western, .british, .arabic:
            if absValue >= 1_000_000_000 { // 1 billion
                let billions = value / 1_000_000_000
                return formatAbbreviation(billions, suffix: "B")
            } else if absValue >= 1_000_000 { // 1 million
                let millions = value / 1_000_000
                return formatAbbreviation(millions, suffix: "M")
            } else if absValue >= 1_000 { // 1 thousand
                let thousands = value / 1_000
                return formatAbbreviation(thousands, suffix: "K")
            }
            
        case .european:
            if absValue >= 1_000_000_000 { // 1 milliard
                let milliards = value / 1_000_000_000
                return formatAbbreviation(milliards, suffix: "Md")
            } else if absValue >= 1_000_000 { // 1 million
                let millions = value / 1_000_000
                return formatAbbreviation(millions, suffix: "M")
            } else if absValue >= 1_000 { // 1 thousand  
                let thousands = value / 1_000
                return formatAbbreviation(thousands, suffix: "k")
            }
        }
        
        return nil
    }
    
    /// Format abbreviated number with proper decimal places
    private func formatAbbreviation(_ value: Decimal, suffix: String) -> String {
        let nsValue = value as NSDecimalNumber
        let doubleValue = nsValue.doubleValue
        
        if doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
            // Whole number
            return "\(Int(doubleValue))\(suffix)"
        } else if doubleValue < 10 {
            // One decimal place for values < 10
            return String(format: "%.1f%@", doubleValue, suffix)
        } else {
            // No decimal places for values >= 10
            return "\(Int(doubleValue.rounded()))\(suffix)"
        }
    }
    
    /// Accessibility description for the numbering system
    public var accessibilityDescription: String {
        switch self {
        case .indian:
            return NSLocalizedString("numbering.system.indian", 
                                   comment: "Indian numbering system using lakh and crore")
        case .western:
            return NSLocalizedString("numbering.system.western", 
                                   comment: "Western numbering system using million and billion")
        case .british:
            return NSLocalizedString("numbering.system.british", 
                                   comment: "British numbering system")
        case .european:
            return NSLocalizedString("numbering.system.european", 
                                   comment: "European numbering system with comma decimal separator")
        case .arabic:
            return NSLocalizedString("numbering.system.arabic", 
                                   comment: "Arabic numbering system")
        }
    }
}

/// Number separator configuration
public struct NumberSeparators: Codable, Hashable {
    public let decimalSeparator: String
    public let groupingSeparator: String
    public let groupingSize: [Int]
    public let useGrouping: Bool
    
    public init(decimalSeparator: String, 
                groupingSeparator: String, 
                groupingSize: [Int], 
                useGrouping: Bool = true) {
        self.decimalSeparator = decimalSeparator
        self.groupingSeparator = groupingSeparator
        self.groupingSize = groupingSize
        self.useGrouping = useGrouping
    }
}