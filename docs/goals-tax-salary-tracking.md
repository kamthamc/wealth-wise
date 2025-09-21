# WealthWise Financial Goals & Tax Management System

## Financial Goals Framework

### 1. Goal Types & Categories
```swift
enum FinancialGoalType: String, CaseIterable {
    // Wealth Building Goals
    case netWorthTarget = "Net Worth Target"
    case investmentCorpus = "Investment Corpus"
    case retirementFund = "Retirement Fund"
    case emergencyFund = "Emergency Fund"
    
    // Life Goals
    case houseDownPayment = "House Down Payment"
    case childEducation = "Child Education"
    case marriageExpenses = "Marriage Expenses"
    case worldTravel = "World Travel"
    case businessStartup = "Business Startup"
    
    // Asset Acquisition
    case realEstateInvestment = "Real Estate Investment"
    case goldAccumulation = "Gold Accumulation"
    case vehiclePurchase = "Vehicle Purchase"
    case luxuryPurchase = "Luxury Purchase"
    
    // Tax & Compliance
    case taxSaving80C = "Tax Saving (80C)"
    case taxAdvancePayment = "Tax Advance Payment"
    case gstCompliance = "GST Compliance"
    
    // Custom Goals
    case custom = "Custom Goal"
}

struct FinancialGoal: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: FinancialGoalType
    let targetAmount: Decimal
    let targetDate: Date
    let priority: GoalPriority
    let category: GoalCategory
    
    // Progress Tracking
    var currentAmount: Decimal = 0
    var monthlyContribution: Decimal = 0
    var contributions: [GoalContribution] = []
    
    // Checkpoints & Milestones
    var checkpoints: [GoalCheckpoint] = []
    var milestones: [GoalMilestone] = []
    
    // Investment Strategy
    var investmentPlan: InvestmentPlan?
    var linkedAccounts: [UUID] = [] // Linked investment accounts
    var autoContribution: AutoContributionSettings?
    
    // Analytics
    var projectedCompletion: Date?
    var riskLevel: RiskLevel = .moderate
    var inflationAdjusted: Bool = true
    
    // Tax Implications
    var taxBenefits: [TaxBenefit] = []
    var taxImplications: [TaxImplication] = []
}

enum GoalPriority: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum GoalCategory: String, CaseIterable {
    case shortTerm = "Short Term (< 2 years)"
    case mediumTerm = "Medium Term (2-5 years)"
    case longTerm = "Long Term (> 5 years)"
}

struct GoalCheckpoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let targetAmount: Decimal
    let description: String
    var actualAmount: Decimal?
    var isAchieved: Bool = false
    var notes: String = ""
}

struct GoalMilestone: Identifiable, Codable {
    let id = UUID()
    let percentage: Int // 25%, 50%, 75%, 100%
    let targetDate: Date
    let celebrationMessage: String
    var achievedDate: Date?
    var isAchieved: Bool = false
}
```

### 2. Advanced Goal Tracking System
```swift
class GoalTrackingManager: ObservableObject {
    @Published var goals: [FinancialGoal] = []
    @Published var goalProgress: [UUID: GoalProgress] = [:]
    @Published var recommendations: [GoalRecommendation] = []
    
    private let analyticsEngine = GoalAnalyticsEngine()
    private let inflationCalculator = InflationCalculator()
    private let taxCalculator = TaxCalculator()
    
    struct GoalProgress {
        let goalId: UUID
        let currentProgress: Double // 0.0 to 1.0
        let projectedCompletion: Date
        let monthlyRequiredContribution: Decimal
        let isOnTrack: Bool
        let timeToGoal: TimeInterval
        let inflationAdjustedTarget: Decimal
    }
    
    func createGoal(
        name: String,
        type: FinancialGoalType,
        targetAmount: Decimal,
        targetDate: Date,
        priority: GoalPriority
    ) -> FinancialGoal {
        var goal = FinancialGoal(
            name: name,
            type: type,
            targetAmount: targetAmount,
            targetDate: targetDate,
            priority: priority,
            category: determineCategory(targetDate: targetDate)
        )
        
        // Set up automatic checkpoints
        goal.checkpoints = generateCheckpoints(for: goal)
        goal.milestones = generateMilestones(for: goal)
        
        // Calculate inflation-adjusted target
        if goal.inflationAdjusted {
            goal.targetAmount = inflationCalculator.adjustForInflation(
                amount: targetAmount,
                years: targetDate.timeIntervalSinceNow / (365.25 * 24 * 3600),
                inflationRate: 0.06 // 6% average inflation in India
            )
        }
        
        // Add tax benefits if applicable
        goal.taxBenefits = identifyTaxBenefits(for: goal)
        
        goals.append(goal)
        updateGoalProgress(for: goal.id)
        
        return goal
    }
    
    func addContribution(to goalId: UUID, amount: Decimal, date: Date = Date(), source: ContributionSource) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }) else { return }
        
        let contribution = GoalContribution(
            amount: amount,
            date: date,
            source: source,
            taxImplications: taxCalculator.calculateTaxImplications(
                amount: amount,
                source: source,
                goal: goals[goalIndex]
            )
        )
        
        goals[goalIndex].contributions.append(contribution)
        goals[goalIndex].currentAmount += amount
        
        updateGoalProgress(for: goalId)
        checkMilestones(for: goalId)
        generateRecommendations()
    }
    
    private func generateCheckpoints(for goal: FinancialGoal) -> [GoalCheckpoint] {
        let timeToGoal = goal.targetDate.timeIntervalSinceNow
        let quarterlyCheckpoints = Int(timeToGoal / (90 * 24 * 3600)) // Every 3 months
        
        var checkpoints: [GoalCheckpoint] = []
        let checkpointAmount = goal.targetAmount / Decimal(quarterlyCheckpoints)
        
        for i in 1...quarterlyCheckpoints {
            let checkpointDate = Date().addingTimeInterval(TimeInterval(i) * 90 * 24 * 3600)
            let targetAmount = checkpointAmount * Decimal(i)
            
            checkpoints.append(GoalCheckpoint(
                date: checkpointDate,
                targetAmount: targetAmount,
                description: "Quarterly Checkpoint \(i)"
            ))
        }
        
        return checkpoints
    }
    
    private func updateGoalProgress(for goalId: UUID) {
        guard let goal = goals.first(where: { $0.id == goalId }) else { return }
        
        let progress = Double(truncating: goal.currentAmount / goal.targetAmount as NSNumber)
        let timeRemaining = goal.targetDate.timeIntervalSinceNow
        let monthlyRequired = calculateRequiredMonthlyContribution(for: goal)
        
        goalProgress[goalId] = GoalProgress(
            goalId: goalId,
            currentProgress: min(progress, 1.0),
            projectedCompletion: calculateProjectedCompletion(for: goal),
            monthlyRequiredContribution: monthlyRequired,
            isOnTrack: isGoalOnTrack(goal),
            timeToGoal: timeRemaining,
            inflationAdjustedTarget: goal.targetAmount
        )
    }
    
    private func calculateRequiredMonthlyContribution(for goal: FinancialGoal) -> Decimal {
        let remainingAmount = goal.targetAmount - goal.currentAmount
        let monthsRemaining = goal.targetDate.timeIntervalSinceNow / (30 * 24 * 3600)
        
        guard monthsRemaining > 0 else { return 0 }
        
        // Consider expected returns based on investment plan
        let expectedMonthlyReturn = goal.investmentPlan?.expectedAnnualReturn ?? 0.08
        let monthlyRate = expectedMonthlyReturn / 12
        
        // PMT calculation for future value
        let fv = remainingAmount
        let n = Decimal(monthsRemaining)
        let r = Decimal(monthlyRate)
        
        if r > 0 {
            return fv * r / (pow(1 + r, n) - 1)
        } else {
            return remainingAmount / Decimal(monthsRemaining)
        }
    }
}

struct GoalContribution: Identifiable, Codable {
    let id = UUID()
    let amount: Decimal
    let date: Date
    let source: ContributionSource
    let taxImplications: [TaxImplication]
    let notes: String = ""
}

enum ContributionSource: String, CaseIterable, Codable {
    case salary = "Salary"
    case bonus = "Bonus"
    case sip = "SIP Investment"
    case lumpsum = "Lump Sum"
    case dividends = "Dividends"
    case rental = "Rental Income"
    case business = "Business Income"
    case gift = "Gift/Inheritance"
    case other = "Other"
}
```

### 3. Goal Visualization & Progress Tracking
```swift
struct GoalProgressView: View {
    let goal: FinancialGoal
    @ObservedObject var goalManager: GoalTrackingManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Goal Header
                GoalHeaderCard(goal: goal)
                
                // Progress Visualization
                GoalProgressChart(goal: goal)
                
                // Checkpoints Timeline
                CheckpointsTimelineView(goal: goal)
                
                // Investment Breakdown
                InvestmentBreakdownView(goal: goal)
                
                // Tax Benefits Summary
                TaxBenefitsSummaryView(goal: goal)
                
                // Action Items
                GoalActionItemsView(goal: goal)
            }
        }
        .navigationTitle(goal.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Add Contribution") {
                        // Show add contribution sheet
                    }
                    Button("Edit Goal") {
                        // Show edit goal sheet
                    }
                    Button("Export Report") {
                        // Export goal report
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct GoalProgressChart: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Overview")
                .font(.headline)
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: progressPercentage)
                
                VStack {
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.title.bold())
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Details
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(goal.currentAmount, specifier: "%.0f")")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Target Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(goal.targetAmount, specifier: "%.0f")")
                        .font(.headline)
                }
            }
            
            // Time Remaining
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(timeRemainingText)
                    .font(.subheadline)
                
                Spacer()
                
                Text(onTrackStatus)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(onTrackColor.opacity(0.2))
                    .foregroundColor(onTrackColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var progressPercentage: Double {
        Double(truncating: goal.currentAmount / goal.targetAmount as NSNumber)
    }
    
    private var timeRemainingText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: goal.targetDate, relativeTo: Date())
    }
    
    private var onTrackStatus: String {
        // Calculate if on track based on time vs progress
        let timeProgress = 1.0 - (goal.targetDate.timeIntervalSinceNow / goal.targetDate.timeIntervalSince(goal.createdDate ?? Date()))
        let amountProgress = progressPercentage
        
        if amountProgress >= timeProgress * 1.1 {
            return "Ahead of Schedule"
        } else if amountProgress >= timeProgress * 0.9 {
            return "On Track"
        } else {
            return "Behind Schedule"
        }
    }
    
    private var onTrackColor: Color {
        switch onTrackStatus {
        case "Ahead of Schedule": return .green
        case "On Track": return .blue
        default: return .orange
        }
    }
}
```

## Tax Management System

### 1. Comprehensive Tax Tracking
```swift
struct TaxProfile: Codable {
    let userId: UUID
    let financialYear: String // "2024-25"
    let regime: TaxRegime
    
    // Income Sources
    var salaryIncome: SalaryIncomeDetails
    var businessIncome: Decimal = 0
    var capitalGains: CapitalGainsDetails
    var otherIncome: [OtherIncomeSource] = []
    
    // Deductions
    var section80C: Section80CDeductions
    var section80D: Section80DDeductions
    var otherDeductions: [TaxDeduction] = []
    
    // Tax Payments
    var advance_tax_paid: [AdvanceTaxPayment] = []
    var tds_deducted: [TDSEntry] = []
    var self_assessment_tax: Decimal = 0
    
    // Calculated Fields
    var total_income: Decimal { calculateTotalIncome() }
    var total_deductions: Decimal { calculateTotalDeductions() }
    var taxable_income: Decimal { total_income - total_deductions }
    var tax_liability: Decimal { calculateTaxLiability() }
    var advance_tax_due: [AdvanceTaxInstallment] { calculateAdvanceTaxDue() }
}

enum TaxRegime: String, CaseIterable, Codable {
    case old = "Old Tax Regime"
    case new = "New Tax Regime"
    
    var benefits: [String] {
        switch self {
        case .old:
            return ["80C deductions up to ₹1.5L", "HRA exemption", "LTA exemption"]
        case .new:
            return ["Lower tax rates", "Standard deduction ₹75,000", "No itemized deductions"]
        }
    }
}

struct SalaryIncomeDetails: Codable {
    var basic_salary: Decimal = 0
    var hra: Decimal = 0
    var special_allowance: Decimal = 0
    var pf_employer: Decimal = 0
    var gratuity: Decimal = 0
    var bonus: Decimal = 0
    
    // Deductions from Salary
    var pf_employee: Decimal = 0
    var professional_tax: Decimal = 0
    var insurance_premium: Decimal = 0
    var nps_contribution: Decimal = 0
    var espp_contribution: Decimal = 0
    var income_tax_deducted: Decimal = 0
    
    var gross_salary: Decimal {
        basic_salary + hra + special_allowance + pf_employer + gratuity + bonus
    }
    
    var net_salary: Decimal {
        gross_salary - pf_employee - professional_tax - insurance_premium - nps_contribution - espp_contribution - income_tax_deducted
    }
}

struct AdvanceTaxPayment: Identifiable, Codable {
    let id = UUID()
    let installment: AdvanceTaxInstallment
    let amount_paid: Decimal
    let payment_date: Date
    let challan_number: String
    let bank_name: String
}

enum AdvanceTaxInstallment: String, CaseIterable, Codable {
    case june15 = "June 15"
    case sept15 = "September 15"
    case dec15 = "December 15"
    case mar15 = "March 15"
    
    var percentage: Double {
        switch self {
        case .june15: return 0.15  // 15%
        case .sept15: return 0.45  // 45% (cumulative)
        case .dec15: return 0.75   // 75% (cumulative)
        case .mar15: return 1.00   // 100% (cumulative)
        }
    }
    
    var dueDate: Date {
        let year = Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current
        
        switch self {
        case .june15:
            return calendar.date(from: DateComponents(year: year, month: 6, day: 15))!
        case .sept15:
            return calendar.date(from: DateComponents(year: year, month: 9, day: 15))!
        case .dec15:
            return calendar.date(from: DateComponents(year: year, month: 12, day: 15))!
        case .mar15:
            return calendar.date(from: DateComponents(year: year + 1, month: 3, day: 15))!
        }
    }
}
```

### 2. Tax Calculator & Optimizer
```swift
class TaxCalculator: ObservableObject {
    @Published var taxProfile: TaxProfile
    @Published var taxSummary: TaxSummary
    @Published var optimizationSuggestions: [TaxOptimizationSuggestion] = []
    
    init() {
        self.taxProfile = TaxProfile()
        self.taxSummary = TaxSummary()
        calculateTax()
    }
    
    func calculateTax() {
        // Calculate tax liability based on regime
        let taxableIncome = taxProfile.taxable_income
        let taxLiability = calculateTaxLiability(income: taxableIncome, regime: taxProfile.regime)
        
        // Calculate advance tax installments
        let advanceTaxDue = calculateAdvanceTaxInstallments(taxLiability: taxLiability)
        
        // Update tax summary
        taxSummary = TaxSummary(
            totalIncome: taxProfile.total_income,
            totalDeductions: taxProfile.total_deductions,
            taxableIncome: taxableIncome,
            taxLiability: taxLiability,
            advanceTaxDue: advanceTaxDue,
            advanceTaxPaid: taxProfile.advance_tax_paid.reduce(0) { $0 + $1.amount_paid },
            remainingTaxLiability: taxLiability - taxProfile.advance_tax_paid.reduce(0) { $0 + $1.amount_paid }
        )
        
        // Generate optimization suggestions
        generateOptimizationSuggestions()
    }
    
    private func calculateTaxLiability(income: Decimal, regime: TaxRegime) -> Decimal {
        var tax: Decimal = 0
        
        switch regime {
        case .old:
            // Old tax regime slabs
            if income > 250000 {
                tax += min(income - 250000, 250000) * 0.05 // 5% for 2.5L-5L
            }
            if income > 500000 {
                tax += min(income - 500000, 500000) * 0.20 // 20% for 5L-10L
            }
            if income > 1000000 {
                tax += (income - 1000000) * 0.30 // 30% above 10L
            }
            
        case .new:
            // New tax regime slabs (2024-25)
            if income > 300000 {
                tax += min(income - 300000, 300000) * 0.05 // 5% for 3L-6L
            }
            if income > 600000 {
                tax += min(income - 600000, 300000) * 0.10 // 10% for 6L-9L
            }
            if income > 900000 {
                tax += min(income - 900000, 300000) * 0.15 // 15% for 9L-12L
            }
            if income > 1200000 {
                tax += min(income - 1200000, 300000) * 0.20 // 20% for 12L-15L
            }
            if income > 1500000 {
                tax += (income - 1500000) * 0.30 // 30% above 15L
            }
        }
        
        // Add cess (4% on tax)
        tax += tax * 0.04
        
        return tax
    }
    
    private func generateOptimizationSuggestions() {
        optimizationSuggestions = []
        
        // 80C optimization
        let remaining80C = 150000 - taxProfile.section80C.total_invested
        if remaining80C > 0 {
            optimizationSuggestions.append(TaxOptimizationSuggestion(
                type: .section80C,
                description: "Invest ₹\(remaining80C) more in 80C instruments",
                potentialSaving: remaining80C * Decimal(taxProfile.regime == .old ? 0.30 : 0.20),
                recommendation: "Consider ELSS, PPF, or NPS to save ₹\(remaining80C * Decimal(taxProfile.regime == .old ? 0.30 : 0.20)) in taxes"
            ))
        }
        
        // NPS additional deduction
        let remainingNPS = 50000 - taxProfile.section80C.nps_additional
        if remainingNPS > 0 {
            optimizationSuggestions.append(TaxOptimizationSuggestion(
                type: .npsAdditional,
                description: "Invest ₹\(remainingNPS) more in NPS for additional 80CCD(1B) benefit",
                potentialSaving: remainingNPS * Decimal(taxProfile.regime == .old ? 0.30 : 0.20),
                recommendation: "NPS Tier-I additional contribution can save ₹\(remainingNPS * Decimal(taxProfile.regime == .old ? 0.30 : 0.20))"
            ))
        }
        
        // Advance tax optimization
        let nextInstallment = getNextAdvanceTaxInstallment()
        if let installment = nextInstallment {
            let dueAmount = taxSummary.taxLiability * Decimal(installment.percentage) - taxProfile.advance_tax_paid.reduce(0) { $0 + $1.amount_paid }
            if dueAmount > 0 {
                optimizationSuggestions.append(TaxOptimizationSuggestion(
                    type: .advanceTax,
                    description: "Pay advance tax of ₹\(dueAmount) by \(installment.rawValue)",
                    potentialSaving: dueAmount * 0.01, // 1% interest saving per month
                    recommendation: "Avoid interest on advance tax by paying ₹\(dueAmount) before \(installment.rawValue)"
                ))
            }
        }
    }
}

struct TaxOptimizationSuggestion: Identifiable {
    let id = UUID()
    let type: OptimizationType
    let description: String
    let potentialSaving: Decimal
    let recommendation: String
    let priority: Priority = .medium
    
    enum OptimizationType {
        case section80C
        case section80D
        case npsAdditional
        case advanceTax
        case regimeSwitch
        case capitalGainsHarvesting
    }
    
    enum Priority {
        case high, medium, low
    }
}
```

## Salary Tracking System

### 3. Comprehensive Salary Management
```swift
struct SalaryStructure: Identifiable, Codable {
    let id = UUID()
    let employeeId: String
    let company: String
    let designation: String
    let effectiveDate: Date
    
    // Salary Components
    var basicSalary: Decimal
    var hra: Decimal
    var specialAllowance: Decimal
    var transportAllowance: Decimal
    var medicalAllowance: Decimal
    var otherAllowances: [AllowanceComponent] = []
    
    // Company Contributions
    var pfEmployer: Decimal
    var gratuity: Decimal
    var insurancePremium: Decimal
    var bonusEligibility: Decimal
    
    // Deductions
    var pfEmployee: Decimal
    var professionalTax: Decimal
    var insuranceDeduction: Decimal
    var npsContribution: Decimal
    var esppContribution: Decimal
    var loanEMI: Decimal = 0
    var otherDeductions: [DeductionComponent] = []
    
    // Tax Deductions
    var incomeTaxDeducted: Decimal = 0
    var surcharge: Decimal = 0
    var cess: Decimal = 0
    
    var grossSalary: Decimal {
        basicSalary + hra + specialAllowance + transportAllowance + medicalAllowance + 
        otherAllowances.reduce(0) { $0 + $1.amount } + pfEmployer + gratuity + insurancePremium
    }
    
    var totalDeductions: Decimal {
        pfEmployee + professionalTax + insuranceDeduction + npsContribution + 
        esppContribution + loanEMI + otherDeductions.reduce(0) { $0 + $1.amount } + 
        incomeTaxDeducted + surcharge + cess
    }
    
    var netSalary: Decimal {
        grossSalary - totalDeductions
    }
}

struct AllowanceComponent: Identifiable, Codable {
    let id = UUID()
    let name: String
    let amount: Decimal
    let isTaxable: Bool
    let description: String?
}

struct DeductionComponent: Identifiable, Codable {
    let id = UUID()
    let name: String
    let amount: Decimal
    let isPreTax: Bool // Before tax calculation
    let section: TaxSection? // 80C, 80D, etc.
    let description: String?
}

enum TaxSection: String, CaseIterable, Codable {
    case section80C = "80C"
    case section80D = "80D"
    case section80G = "80G"
    case section80E = "80E"
    case section80CCD1B = "80CCD(1B)"
}

class SalaryTracker: ObservableObject {
    @Published var salaryStructures: [SalaryStructure] = []
    @Published var payslips: [Payslip] = []
    @Published var yearlyProjection: YearlyProjection?
    @Published var taxImpact: TaxImpact?
    
    func addSalaryStructure(_ structure: SalaryStructure) {
        salaryStructures.append(structure)
        calculateYearlyProjection()
        calculateTaxImpact()
    }
    
    func addPayslip(_ payslip: Payslip) {
        payslips.append(payslip)
        updateProjections()
    }
    
    private func calculateYearlyProjection() {
        guard let currentStructure = salaryStructures.last else { return }
        
        let monthsRemaining = 12 - Calendar.current.component(.month, from: Date()) + 1
        let projectedGrossIncome = currentStructure.grossSalary * Decimal(monthsRemaining)
        let projectedDeductions = currentStructure.totalDeductions * Decimal(monthsRemaining)
        let projectedNetIncome = currentStructure.netSalary * Decimal(monthsRemaining)
        
        // Add already received salary
        let receivedGross = payslips.reduce(0) { $0 + $1.grossSalary }
        let receivedDeductions = payslips.reduce(0) { $0 + $1.totalDeductions }
        let receivedNet = payslips.reduce(0) { $0 + $1.netSalary }
        
        yearlyProjection = YearlyProjection(
            totalGrossIncome: projectedGrossIncome + receivedGross,
            totalDeductions: projectedDeductions + receivedDeductions,
            totalNetIncome: projectedNetIncome + receivedNet,
            averageMonthlyGross: (projectedGrossIncome + receivedGross) / 12,
            averageMonthlyNet: (projectedNetIncome + receivedNet) / 12
        )
    }
    
    private func calculateTaxImpact() {
        guard let structure = salaryStructures.last,
              let projection = yearlyProjection else { return }
        
        // Calculate tax savings from salary deductions
        let section80CSavings = (structure.pfEmployee + structure.npsContribution) * 0.30
        let section80DSavings = structure.insuranceDeduction * 0.30
        let totalTaxSavings = section80CSavings + section80DSavings
        
        // Calculate advance tax requirements if income increases
        let estimatedTax = calculateEstimatedTax(income: projection.totalGrossIncome)
        let currentTaxDeducted = projection.totalDeductions // Approximate
        let additionalTaxDue = max(0, estimatedTax - currentTaxDeducted)
        
        taxImpact = TaxImpact(
            estimatedAnnualTax: estimatedTax,
            taxSavingsFromSalary: totalTaxSavings,
            additionalTaxDue: additionalTaxDue,
            advanceTaxRequired: additionalTaxDue > 10000,
            nextAdvanceTaxDate: getNextAdvanceTaxDate(),
            recommendedAdvanceTaxAmount: additionalTaxDue / 4 // Quarterly
        )
    }
}

struct Payslip: Identifiable, Codable {
    let id = UUID()
    let month: String
    let year: Int
    let payDate: Date
    
    // Earnings
    let basicSalary: Decimal
    let hra: Decimal
    let specialAllowance: Decimal
    let otherEarnings: Decimal
    let bonus: Decimal
    let overtime: Decimal
    
    // Employer Contributions
    let pfEmployer: Decimal
    let gratuity: Decimal
    let insurancePremium: Decimal
    
    // Deductions
    let pfEmployee: Decimal
    let professionalTax: Decimal
    let insuranceDeduction: Decimal
    let npsContribution: Decimal
    let esppContribution: Decimal
    let loanEMI: Decimal
    let incomeTax: Decimal
    let otherDeductions: Decimal
    
    var grossSalary: Decimal {
        basicSalary + hra + specialAllowance + otherEarnings + bonus + overtime + 
        pfEmployer + gratuity + insurancePremium
    }
    
    var totalDeductions: Decimal {
        pfEmployee + professionalTax + insuranceDeduction + npsContribution + 
        esppContribution + loanEMI + incomeTax + otherDeductions
    }
    
    var netSalary: Decimal {
        grossSalary - totalDeductions
    }
}

struct YearlyProjection {
    let totalGrossIncome: Decimal
    let totalDeductions: Decimal
    let totalNetIncome: Decimal
    let averageMonthlyGross: Decimal
    let averageMonthlyNet: Decimal
}

struct TaxImpact {
    let estimatedAnnualTax: Decimal
    let taxSavingsFromSalary: Decimal
    let additionalTaxDue: Decimal
    let advanceTaxRequired: Bool
    let nextAdvanceTaxDate: Date?
    let recommendedAdvanceTaxAmount: Decimal
}
```

### 4. Integrated Dashboard Views
```swift
struct ComprehensiveFinancialDashboard: View {
    @StateObject private var goalManager = GoalTrackingManager()
    @StateObject private var taxCalculator = TaxCalculator()
    @StateObject private var salaryTracker = SalaryTracker()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Financial Goals Overview
                GoalsOverviewWidget(goalManager: goalManager)
                
                // Tax Summary Widget
                TaxSummaryWidget(taxCalculator: taxCalculator)
                
                // Salary Insights Widget
                SalaryInsightsWidget(salaryTracker: salaryTracker)
                
                // Integrated Recommendations
                FinancialRecommendationsWidget(
                    goals: goalManager.goals,
                    taxSuggestions: taxCalculator.optimizationSuggestions,
                    salaryData: salaryTracker.yearlyProjection
                )
            }
            .padding()
        }
        .navigationTitle("Financial Dashboard")
    }
}

struct GoalsOverviewWidget: View {
    @ObservedObject var goalManager: GoalTrackingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Financial Goals")
                    .font(.headline)
                Spacer()
                NavigationLink("View All", destination: GoalsListView(goalManager: goalManager))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if goalManager.goals.isEmpty {
                VStack {
                    Image(systemName: "target")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Set your first financial goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Create Goal") {
                        // Show goal creation sheet
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(goalManager.goals.prefix(3)) { goal in
                            GoalProgressCard(goal: goal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct TaxSummaryWidget: View {
    @ObservedObject var taxCalculator: TaxCalculator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tax Summary FY 2024-25")
                    .font(.headline)
                Spacer()
                NavigationLink("Details", destination: TaxDetailView(taxCalculator: taxCalculator))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Tax liability overview
            HStack {
                VStack(alignment: .leading) {
                    Text("Tax Liability")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(taxCalculator.taxSummary.taxLiability, specifier: "%.0f")")
                        .font(.title2.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Advance Tax Paid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(taxCalculator.taxSummary.advanceTaxPaid, specifier: "%.0f")")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
            }
            
            // Next advance tax installment
            if let nextInstallment = getNextAdvanceTaxInstallment() {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Next Advance Tax Due")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("₹\(calculateNextInstallmentAmount()) by \(nextInstallment.rawValue)")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                    }
                    Spacer()
                }
            }
            
            // Tax saving opportunities
            if !taxCalculator.optimizationSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tax Saving Opportunities")
                        .font(.subheadline.bold())
                    
                    ForEach(taxCalculator.optimizationSuggestions.prefix(2)) { suggestion in
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.yellow)
                            Text(suggestion.description)
                                .font(.caption)
                            Spacer()
                            Text("Save ₹\(suggestion.potentialSaving, specifier: "%.0f")")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}
```

This comprehensive system provides:

1. **Advanced Goal Tracking**: Multi-checkpoint goals with inflation adjustment and investment planning
2. **Tax Management**: Complete tax calculation, advance tax tracking, and optimization suggestions  
3. **Salary Tracking**: Detailed salary component tracking with tax implications
4. **Integrated Dashboard**: Unified view of goals, taxes, and salary with actionable recommendations
5. **Smart Recommendations**: AI-powered suggestions for tax savings and goal achievement
6. **Compliance Support**: Advance tax reminders and regulatory compliance tracking

The system handles complex Indian tax scenarios including multiple income sources, salary deductions, advance tax payments, and optimization across different tax regimes.