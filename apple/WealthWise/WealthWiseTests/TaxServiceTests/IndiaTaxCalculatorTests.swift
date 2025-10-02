import XCTest
@testable import WealthWise

@MainActor
final class IndiaTaxCalculatorTests: XCTestCase {
    
    var calculator: IndiaTaxCalculator!
    
    override func setUp() async throws {
        calculator = IndiaTaxCalculator(taxYear: "2025-26", regime: .new)
    }
    
    override func tearDown() {
        calculator = nil
    }
    
    // MARK: - Initialization Tests
    
    func testCalculatorInitialization() {
        XCTAssertEqual(calculator.countryCode, "IND")
        XCTAssertEqual(calculator.taxYear, "2025-26")
        XCTAssertEqual(calculator.currency, "INR")
    }
    
    // MARK: - New Regime Tax Bracket Tests
    
    func testNewRegimeTaxBrackets() {
        let brackets = calculator.getTaxBrackets(for: .taxResident)
        
        XCTAssertEqual(brackets.count, 6)
        XCTAssertEqual(brackets[0].minIncome, 0)
        XCTAssertEqual(brackets[0].rate, 0)
        XCTAssertEqual(brackets[5].rate, 0.30)
    }
    
    // MARK: - Tax Calculation Tests - New Regime
    
    func testNewRegimeTaxBelowThreshold() async {
        let income: Decimal = 250000  // Below 3 lakh
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertEqual(calculation.grossIncome, 250000)
        XCTAssertEqual(calculation.taxableIncome, 250000)
        XCTAssertEqual(calculation.taxLiability, 0)  // No tax below 3L
    }
    
    func testNewRegimeTaxInFirstBracket() async {
        let income: Decimal = 500000  // 5 lakh
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        // Expected: (500000 - 300000) * 0.05 = 10000
        // Plus 4% cess: 10000 * 1.04 = 10400
        let expectedTax: Decimal = 10400
        
        XCTAssertEqual(calculation.taxableIncome, 500000)
        XCTAssertEqual(calculation.taxLiability, expectedTax)
    }
    
    func testNewRegimeTaxMultipleBrackets() async {
        let income: Decimal = 1500000  // 15 lakh
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        // Calculate expected tax:
        // 3L-7L: 400000 * 0.05 = 20000
        // 7L-10L: 300000 * 0.10 = 30000
        // 10L-12L: 200000 * 0.15 = 30000
        // 12L-15L: 300000 * 0.20 = 60000
        // Total: 140000
        // With 4% cess: 145600
        
        let expectedBaseTax: Decimal = 140000
        let expectedWithCess: Decimal = 145600
        
        XCTAssertEqual(calculation.taxableIncome, 1500000)
        XCTAssertEqual(calculation.taxLiability, expectedWithCess)
        XCTAssertGreaterThan(calculation.effectiveRate, 0)
        XCTAssertEqual(calculation.marginalRate, 20.0)  // In 20% bracket
    }
    
    func testNewRegimeTaxHighIncome() async {
        let income: Decimal = 2000000  // 20 lakh
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertEqual(calculation.marginalRate, 30.0)  // In top 30% bracket
        XCTAssertGreaterThan(calculation.taxLiability, 0)
        XCTAssertNotNil(calculation.cess)
    }
    
    // MARK: - Standard Deduction Tests
    
    func testNewRegimeWithStandardDeduction() async {
        let income: Decimal = 800000
        let breakdown = IncomeBreakdown(salary: income)
        
        let standardDeduction = TaxDeduction(
            type: .standardDeduction,
            amount: 75000,
            currency: "INR",
            taxYear: "2025-26"
        )
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: [standardDeduction]
        )
        
        XCTAssertEqual(calculation.totalDeductions, 75000)
        XCTAssertEqual(calculation.taxableIncome, 725000)
    }
    
    // MARK: - Surcharge Tests
    
    func testSurchargeForHighIncome() async {
        let income: Decimal = 6000000  // 60 lakh (above 50L)
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertNotNil(calculation.surcharge)
        XCTAssertGreaterThan(calculation.surcharge ?? 0, 0)
    }
    
    func testSurchargeForVeryHighIncome() async {
        let income: Decimal = 11000000  // 1.1 crore (above 1 crore)
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertNotNil(calculation.surcharge)
        // Surcharge should be 15% for income above 1 crore
        XCTAssertGreaterThan(calculation.surcharge ?? 0, 0)
    }
    
    // MARK: - Cess Tests
    
    func testCessCalculation() async {
        let income: Decimal = 1000000
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertNotNil(calculation.cess)
        // Cess should be 4% of base tax
        let cess = calculation.cess ?? 0
        XCTAssertGreaterThan(cess, 0)
    }
    
    // MARK: - Filing Deadlines Tests
    
    func testFilingDeadlines() {
        let deadlines = calculator.getFilingDeadlines()
        
        XCTAssertFalse(deadlines.isEmpty)
        
        // Should have ITR filing deadline
        let itrDeadline = deadlines.first { $0.description.contains("ITR") }
        XCTAssertNotNil(itrDeadline)
        
        // Should have advance tax deadlines
        let advanceTaxDeadlines = deadlines.filter { $0.description.contains("Advance Tax") }
        XCTAssertGreaterThanOrEqual(advanceTaxDeadlines.count, 4)
    }
    
    // MARK: - Available Deductions Tests
    
    func testNewRegimeAvailableDeductions() {
        let deductions = calculator.getAvailableDeductions(for: .taxResident)
        
        // New regime should only allow standard deduction
        XCTAssertEqual(deductions.count, 1)
        XCTAssertTrue(deductions.contains(.standardDeduction))
    }
    
    func testOldRegimeAvailableDeductions() {
        let oldRegimeCalc = IndiaTaxCalculator(taxYear: "2025-26", regime: .old)
        let deductions = oldRegimeCalc.getAvailableDeductions(for: .taxResident)
        
        // Old regime should allow multiple deductions
        XCTAssertGreaterThan(deductions.count, 1)
        XCTAssertTrue(deductions.contains(.section80C))
        XCTAssertTrue(deductions.contains(.section80D))
        XCTAssertTrue(deductions.contains(.nps))
    }
    
    // MARK: - Optimization Suggestions Tests
    
    func testOptimizationSuggestionsGenerated() async {
        let income: Decimal = 1200000
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertFalse(calculation.optimizationSuggestions.isEmpty)
    }
    
    func testAdvanceTaxSuggestionForHighIncome() async {
        let income: Decimal = 1500000
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        let advanceTaxSuggestion = calculation.optimizationSuggestions.first {
            $0.type == .advanceTaxPlanning
        }
        
        XCTAssertNotNil(advanceTaxSuggestion)
    }
    
    // MARK: - Filing Requirements Tests
    
    func testFilingRequirementsForTaxableIncome() async {
        let income: Decimal = 500000
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertFalse(calculation.filingRequirements.isEmpty)
        
        let hasITRRequirement = calculation.filingRequirements.contains { req in
            req.contains("ITR") || req.contains("Income Tax Return")
        }
        XCTAssertTrue(hasITRRequirement)
    }
    
    func testFilingRequirementsForNonResident() async {
        let income: Decimal = 500000
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .nonResidentNotOrdinary,
            deductions: []
        )
        
        let hasForm10F = calculation.filingRequirements.contains { req in
            req.contains("Form 10F")
        }
        XCTAssertTrue(hasForm10F)
    }
    
    // MARK: - Tax Breakdown Tests
    
    func testTaxBreakdownComponents() async {
        let income: Decimal = 1000000
        let breakdown = IncomeBreakdown(salary: income)
        
        let calculation = await calculator.calculateTax(
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: []
        )
        
        XCTAssertFalse(calculation.taxBreakdown.isEmpty)
        
        // Should have cess component
        let cessComponent = calculation.taxBreakdown.first { $0.name.contains("Cess") }
        XCTAssertNotNil(cessComponent)
    }
    
    // MARK: - Performance Tests
    
    func testTaxCalculationPerformance() {
        measure {
            Task { @MainActor in
                let income: Decimal = 1500000
                let breakdown = IncomeBreakdown(salary: income)
                
                _ = await calculator.calculateTax(
                    grossIncome: income,
                    incomeBreakdown: breakdown,
                    residencyStatus: .taxResident,
                    deductions: []
                )
            }
        }
    }
}
