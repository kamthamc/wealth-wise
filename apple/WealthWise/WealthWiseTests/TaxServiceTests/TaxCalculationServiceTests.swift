import XCTest
@testable import WealthWise

@MainActor
final class TaxCalculationServiceTests: XCTestCase {
    
    var service: TaxCalculationService!
    
    override func setUp() async throws {
        service = TaxCalculationService()
    }
    
    override func tearDown() {
        service = nil
    }
    
    // MARK: - Initialization Tests
    
    func testServiceInitialization() {
        XCTAssertNotNil(service)
        XCTAssertFalse(service.isCalculating)
        XCTAssertNil(service.lastError)
    }
    
    // MARK: - Supported Countries Tests
    
    func testGetSupportedCountries() {
        let supported = service.getSupportedCountries()
        
        XCTAssertFalse(supported.isEmpty)
        XCTAssertTrue(supported.contains("IND"))
        XCTAssertTrue(supported.contains("USA"))
    }
    
    func testIsCountrySupported() {
        XCTAssertTrue(service.isCountrySupported("IND"))
        XCTAssertTrue(service.isCountrySupported("USA"))
        XCTAssertTrue(service.isCountrySupported("GBR"))
        XCTAssertFalse(service.isCountrySupported("ZZZ"))
    }
    
    // MARK: - Simple Tax Calculation Tests
    
    func testCalculateSimpleTaxIndia() async {
        let result = await service.calculateSimpleTax(
            for: "IND",
            income: 1000000,
            residencyStatus: .taxResident
        )
        
        switch result {
        case .success(let calculation):
            XCTAssertEqual(calculation.country, "IND")
            XCTAssertEqual(calculation.grossIncome, 1000000)
            XCTAssertEqual(calculation.currency, "INR")
            XCTAssertGreaterThan(calculation.taxLiability, 0)
            
        case .failure(let error):
            XCTFail("Calculation failed: \(error)")
        }
    }
    
    func testCalculateSimpleTaxUS() async {
        let result = await service.calculateSimpleTax(
            for: "USA",
            income: 100000,
            residencyStatus: .taxResident
        )
        
        switch result {
        case .success(let calculation):
            XCTAssertEqual(calculation.country, "USA")
            XCTAssertEqual(calculation.grossIncome, 100000)
            XCTAssertEqual(calculation.currency, "USD")
            XCTAssertGreaterThan(calculation.taxLiability, 0)
            
        case .failure(let error):
            XCTFail("Calculation failed: \(error)")
        }
    }
    
    func testCalculateSimpleTaxUK() async {
        let result = await service.calculateSimpleTax(
            for: "GBR",
            income: 50000,
            residencyStatus: .taxResident
        )
        
        switch result {
        case .success(let calculation):
            XCTAssertEqual(calculation.country, "GBR")
            XCTAssertEqual(calculation.grossIncome, 50000)
            XCTAssertEqual(calculation.currency, "GBP")
            
        case .failure(let error):
            XCTFail("Calculation failed: \(error)")
        }
    }
    
    func testCalculateSimpleTaxUnsupportedCountry() async {
        let result = await service.calculateSimpleTax(
            for: "ZZZ",
            income: 100000
        )
        
        switch result {
        case .success:
            XCTFail("Should have failed for unsupported country")
            
        case .failure(let error):
            XCTAssertNotNil(error)
            XCTAssertNotNil(service.lastError)
        }
    }
    
    // MARK: - Full Calculation Tests
    
    func testCalculateTaxWithDeductions() async {
        let deduction = TaxDeduction(
            type: .standardDeduction,
            amount: 75000,
            currency: "INR",
            taxYear: "2025-26"
        )
        
        let breakdown = IncomeBreakdown(salary: 1000000)
        
        let result = await service.calculateTax(
            for: "IND",
            grossIncome: 1000000,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident,
            deductions: [deduction]
        )
        
        switch result {
        case .success(let calculation):
            XCTAssertEqual(calculation.totalDeductions, 75000)
            XCTAssertEqual(calculation.taxableIncome, 925000)
            
        case .failure(let error):
            XCTFail("Calculation failed: \(error)")
        }
    }
    
    func testCalculateTaxWithIncomeBreakdown() async {
        let breakdown = IncomeBreakdown(
            salary: 500000,
            business: 300000,
            capitalGains: 200000
        )
        
        let result = await service.calculateTax(
            for: "IND",
            grossIncome: 1000000,
            incomeBreakdown: breakdown,
            residencyStatus: .taxResident
        )
        
        switch result {
        case .success(let calculation):
            XCTAssertEqual(calculation.grossIncome, 1000000)
            XCTAssertEqual(calculation.incomeBreakdown.salary, 500000)
            XCTAssertEqual(calculation.incomeBreakdown.business, 300000)
            XCTAssertEqual(calculation.incomeBreakdown.capitalGains, 200000)
            
        case .failure(let error):
            XCTFail("Calculation failed: \(error)")
        }
    }
    
    // MARK: - Caching Tests
    
    func testCalculationCaching() async {
        let result = await service.calculateSimpleTax(
            for: "IND",
            income: 1000000
        )
        
        guard case .success = result else {
            XCTFail("Initial calculation failed")
            return
        }
        
        let cached = service.getCachedCalculation(for: "IND")
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.grossIncome, 1000000)
    }
    
    func testClearCache() async {
        _ = await service.calculateSimpleTax(for: "IND", income: 1000000)
        
        XCTAssertNotNil(service.getCachedCalculation(for: "IND"))
        
        service.clearCache()
        
        XCTAssertNil(service.getCachedCalculation(for: "IND"))
    }
    
    func testClearCacheForSpecificCountry() async {
        _ = await service.calculateSimpleTax(for: "IND", income: 1000000)
        _ = await service.calculateSimpleTax(for: "USA", income: 100000)
        
        XCTAssertNotNil(service.getCachedCalculation(for: "IND"))
        XCTAssertNotNil(service.getCachedCalculation(for: "USA"))
        
        service.clearCache(for: "IND")
        
        XCTAssertNil(service.getCachedCalculation(for: "IND"))
        XCTAssertNotNil(service.getCachedCalculation(for: "USA"))
    }
    
    // MARK: - Multi-Country Calculation Tests
    
    func testMultiCountryCalculation() async {
        let incomeByCountry: [String: (Decimal, IncomeBreakdown)] = [
            "IND": (1000000, IncomeBreakdown(salary: 1000000)),
            "USA": (50000, IncomeBreakdown(salary: 50000))
        ]
        
        let residencyByCountry: [String: ResidencyType] = [
            "IND": .taxResident,
            "USA": .nonResidentNotOrdinary
        ]
        
        let results = await service.calculateMultiCountryTax(
            incomeByCountry: incomeByCountry,
            residencyByCountry: residencyByCountry
        )
        
        XCTAssertEqual(results.count, 2)
        XCTAssertNotNil(results["IND"])
        XCTAssertNotNil(results["USA"])
        
        if let indCalc = results["IND"] {
            XCTAssertEqual(indCalc.grossIncome, 1000000)
        }
        
        if let usCalc = results["USA"] {
            XCTAssertEqual(usCalc.grossIncome, 50000)
        }
    }
    
    func testGetTotalTaxLiability() async {
        let incomeByCountry: [String: (Decimal, IncomeBreakdown)] = [
            "IND": (1000000, IncomeBreakdown(salary: 1000000)),
            "USA": (50000, IncomeBreakdown(salary: 50000))
        ]
        
        let residencyByCountry: [String: ResidencyType] = [
            "IND": .taxResident,
            "USA": .taxResident
        ]
        
        let calculations = await service.calculateMultiCountryTax(
            incomeByCountry: incomeByCountry,
            residencyByCountry: residencyByCountry
        )
        
        let totalsByCurrency = service.getTotalTaxLiability(from: calculations)
        
        XCTAssertFalse(totalsByCurrency.isEmpty)
        XCTAssertNotNil(totalsByCurrency["INR"])
        XCTAssertNotNil(totalsByCurrency["USD"])
    }
    
    // MARK: - Tax Brackets Query Tests
    
    func testGetTaxBrackets() {
        let brackets = service.getTaxBrackets(
            for: "IND",
            residencyStatus: .taxResident
        )
        
        XCTAssertNotNil(brackets)
        XCTAssertFalse(brackets?.isEmpty ?? true)
    }
    
    func testGetTaxBracketsUnsupportedCountry() {
        let brackets = service.getTaxBrackets(
            for: "ZZZ",
            residencyStatus: .taxResident
        )
        
        XCTAssertNil(brackets)
        XCTAssertNotNil(service.lastError)
    }
    
    // MARK: - Available Deductions Query Tests
    
    func testGetAvailableDeductions() {
        let deductions = service.getAvailableDeductions(
            for: "IND",
            residencyStatus: .taxResident
        )
        
        XCTAssertNotNil(deductions)
        XCTAssertFalse(deductions?.isEmpty ?? true)
    }
    
    // MARK: - Filing Deadlines Query Tests
    
    func testGetFilingDeadlines() {
        let deadlines = service.getFilingDeadlines(for: "IND")
        
        XCTAssertNotNil(deadlines)
        XCTAssertFalse(deadlines?.isEmpty ?? true)
    }
    
    // MARK: - Tax Comparison Tests
    
    func testCompareTaxBurden() async {
        let comparisons = await service.compareTaxBurden(
            income: 1000000,
            across: ["IND", "USA"],
            residencyStatus: .taxResident
        )
        
        XCTAssertEqual(comparisons.count, 2)
        
        if let indCalc = comparisons["IND"],
           let usCalc = comparisons["USA"] {
            // Both should have calculated tax
            XCTAssertGreaterThan(indCalc.taxLiability, 0)
            XCTAssertGreaterThan(usCalc.taxLiability, 0)
        }
    }
    
    // MARK: - State Management Tests
    
    func testIsCalculatingFlag() async {
        XCTAssertFalse(service.isCalculating)
        
        let task = Task {
            await service.calculateSimpleTax(for: "IND", income: 1000000)
        }
        
        // Wait briefly to allow calculation to start
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        await task.value
        
        // Should be false after completion
        XCTAssertFalse(service.isCalculating)
    }
    
    // MARK: - Performance Tests
    
    func testCalculationPerformance() {
        measure {
            Task { @MainActor in
                _ = await service.calculateSimpleTax(
                    for: "IND",
                    income: 1000000
                )
            }
        }
    }
}
