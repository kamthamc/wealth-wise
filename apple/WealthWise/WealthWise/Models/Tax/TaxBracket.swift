import Foundation

/// Represents a tax bracket with income range and tax rate
public struct TaxBracket: Sendable, Codable, Hashable {
    
    // MARK: - Properties
    
    public let minIncome: Decimal
    public let maxIncome: Decimal?  // nil means unlimited
    public let rate: Double  // Tax rate as decimal (0.10 = 10%)
    public let description: String
    
    // MARK: - Initialization
    
    public init(
        minIncome: Decimal,
        maxIncome: Decimal? = nil,
        rate: Double,
        description: String
    ) {
        self.minIncome = minIncome
        self.maxIncome = maxIncome
        self.rate = rate
        self.description = description
    }
    
    // MARK: - Computed Properties
    
    /// Whether this bracket applies to the given income
    public func applies(to income: Decimal) -> Bool {
        guard income >= minIncome else { return false }
        if let max = maxIncome {
            return income <= max
        }
        return true
    }
    
    /// Calculate taxable amount within this bracket for given income
    public func taxableAmount(for income: Decimal) -> Decimal {
        guard applies(to: income) else { return 0 }
        
        let effectiveMin = minIncome
        let effectiveMax = maxIncome ?? income
        let taxableInThisBracket = min(income, effectiveMax) - effectiveMin
        
        return max(0, taxableInThisBracket)
    }
    
    /// Calculate tax for this bracket on given income
    public func calculateTax(for income: Decimal) -> Decimal {
        let taxable = taxableAmount(for: income)
        return taxable * Decimal(rate)
    }
    
    /// Display range for UI
    public var rangeDescription: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        let minStr = formatter.string(from: NSDecimalNumber(decimal: minIncome)) ?? "\(minIncome)"
        
        if let max = maxIncome {
            let maxStr = formatter.string(from: NSDecimalNumber(decimal: max)) ?? "\(max)"
            return "\(minStr) - \(maxStr)"
        } else {
            return "\(minStr)+"
        }
    }
    
    /// Display rate as percentage
    public var ratePercentage: String {
        return String(format: "%.1f%%", rate * 100)
    }
}

// MARK: - Comparable
extension TaxBracket: Comparable {
    public static func < (lhs: TaxBracket, rhs: TaxBracket) -> Bool {
        lhs.minIncome < rhs.minIncome
    }
}
