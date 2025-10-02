import Foundation

/// Represents a tax optimization suggestion for potential savings
public struct TaxOptimizationSuggestion: Sendable, Codable, Hashable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let type: OptimizationType
    public let title: String
    public let description: String
    public let potentialSaving: Decimal
    public let currency: String
    public let priority: Priority
    public let actionRequired: String
    public let deadline: Date?
    public let relatedDeduction: TaxDeductionType?
    public let country: String
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        type: OptimizationType,
        title: String,
        description: String,
        potentialSaving: Decimal,
        currency: String,
        priority: Priority = .medium,
        actionRequired: String,
        deadline: Date? = nil,
        relatedDeduction: TaxDeductionType? = nil,
        country: String
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.potentialSaving = potentialSaving
        self.currency = currency
        self.priority = priority
        self.actionRequired = actionRequired
        self.deadline = deadline
        self.relatedDeduction = relatedDeduction
        self.country = country
    }
    
    // MARK: - Computed Properties
    
    /// Days until deadline (if applicable)
    public var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: deadline).day
    }
    
    /// Whether action is urgent (less than 30 days)
    public var isUrgent: Bool {
        guard let days = daysUntilDeadline else { return false }
        return days <= 30
    }
    
    /// Formatted potential saving
    public var formattedSaving: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: potentialSaving)) ?? "\(potentialSaving)"
    }
}

/// Types of tax optimization opportunities
public enum OptimizationType: String, CaseIterable, Codable, Sendable {
    case deductionMaximization = "deductionMaximization"
    case taxRegimeOptimization = "taxRegimeOptimization"
    case capitalGainsTiming = "capitalGainsTiming"
    case lossHarvesting = "lossHarvesting"
    case treatyBenefits = "treatyBenefits"
    case advanceTaxPlanning = "advanceTaxPlanning"
    case retirementContribution = "retirementContribution"
    case charitableDonation = "charitableDonation"
    case businessExpenseOptimization = "businessExpenseOptimization"
    case residencyPlanning = "residencyPlanning"
    
    public var displayName: String {
        switch self {
        case .deductionMaximization:
            return "Maximize Tax Deductions"
        case .taxRegimeOptimization:
            return "Optimize Tax Regime"
        case .capitalGainsTiming:
            return "Capital Gains Timing"
        case .lossHarvesting:
            return "Tax Loss Harvesting"
        case .treatyBenefits:
            return "Tax Treaty Benefits"
        case .advanceTaxPlanning:
            return "Advance Tax Planning"
        case .retirementContribution:
            return "Retirement Contributions"
        case .charitableDonation:
            return "Charitable Donations"
        case .businessExpenseOptimization:
            return "Business Expense Optimization"
        case .residencyPlanning:
            return "Residency Planning"
        }
    }
    
    public var icon: String {
        switch self {
        case .deductionMaximization: return "chart.bar.fill"
        case .taxRegimeOptimization: return "slider.horizontal.3"
        case .capitalGainsTiming: return "clock.fill"
        case .lossHarvesting: return "arrow.down.circle.fill"
        case .treatyBenefits: return "globe"
        case .advanceTaxPlanning: return "calendar"
        case .retirementContribution: return "building.columns.fill"
        case .charitableDonation: return "heart.fill"
        case .businessExpenseOptimization: return "briefcase.fill"
        case .residencyPlanning: return "location.fill"
        }
    }
}

/// Priority levels for suggestions
public enum Priority: String, CaseIterable, Codable, Sendable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    public var displayName: String {
        switch self {
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .low: return "Low Priority"
        }
    }
    
    public var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "blue"
        }
    }
}
