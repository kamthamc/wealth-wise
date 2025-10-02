import XCTest
@testable import WealthWise

final class TaxBracketTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testTaxBracketInitialization() {
        let bracket = TaxBracket(
            minIncome: 0,
            maxIncome: 10000,
            rate: 0.10,
            description: "10% bracket"
        )
        
        XCTAssertEqual(bracket.minIncome, 0)
        XCTAssertEqual(bracket.maxIncome, 10000)
        XCTAssertEqual(bracket.rate, 0.10)
        XCTAssertEqual(bracket.description, "10% bracket")
    }
    
    func testTaxBracketWithoutMaxIncome() {
        let bracket = TaxBracket(
            minIncome: 100000,
            maxIncome: nil,
            rate: 0.30,
            description: "Top bracket"
        )
        
        XCTAssertEqual(bracket.minIncome, 100000)
        XCTAssertNil(bracket.maxIncome)
    }
    
    // MARK: - Applicability Tests
    
    func testBracketAppliesWithinRange() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        XCTAssertTrue(bracket.applies(to: 10000))
        XCTAssertTrue(bracket.applies(to: 15000))
        XCTAssertTrue(bracket.applies(to: 20000))
    }
    
    func testBracketDoesNotApplyBelowRange() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        XCTAssertFalse(bracket.applies(to: 9999))
    }
    
    func testBracketDoesNotApplyAboveRange() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        XCTAssertFalse(bracket.applies(to: 20001))
    }
    
    func testUnlimitedBracketAppliesAboveMinimum() {
        let bracket = TaxBracket(
            minIncome: 100000,
            maxIncome: nil,
            rate: 0.30,
            description: "Unlimited"
        )
        
        XCTAssertTrue(bracket.applies(to: 100000))
        XCTAssertTrue(bracket.applies(to: 1000000))
        XCTAssertFalse(bracket.applies(to: 99999))
    }
    
    // MARK: - Taxable Amount Tests
    
    func testTaxableAmountWithinBracket() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let taxable = bracket.taxableAmount(for: 15000)
        XCTAssertEqual(taxable, 5000)  // 15000 - 10000
    }
    
    func testTaxableAmountAtBracketTop() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let taxable = bracket.taxableAmount(for: 20000)
        XCTAssertEqual(taxable, 10000)  // Full bracket
    }
    
    func testTaxableAmountExceedingBracket() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let taxable = bracket.taxableAmount(for: 25000)
        XCTAssertEqual(taxable, 10000)  // Capped at bracket max
    }
    
    func testTaxableAmountBelowBracket() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let taxable = bracket.taxableAmount(for: 5000)
        XCTAssertEqual(taxable, 0)
    }
    
    // MARK: - Tax Calculation Tests
    
    func testCalculateTaxWithinBracket() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let tax = bracket.calculateTax(for: 15000)
        XCTAssertEqual(tax, 750)  // 5000 * 0.15
    }
    
    func testCalculateTaxFullBracket() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let tax = bracket.calculateTax(for: 25000)
        XCTAssertEqual(tax, 1500)  // 10000 * 0.15
    }
    
    func testCalculateTaxBelowBracket() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let tax = bracket.calculateTax(for: 5000)
        XCTAssertEqual(tax, 0)
    }
    
    // MARK: - Display Tests
    
    func testRangeDescriptionWithMaxIncome() {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test"
        )
        
        let description = bracket.rangeDescription
        XCTAssertTrue(description.contains("10"))
        XCTAssertTrue(description.contains("20"))
    }
    
    func testRangeDescriptionWithoutMaxIncome() {
        let bracket = TaxBracket(
            minIncome: 100000,
            maxIncome: nil,
            rate: 0.30,
            description: "Test"
        )
        
        let description = bracket.rangeDescription
        XCTAssertTrue(description.contains("+"))
    }
    
    func testRatePercentage() {
        let bracket = TaxBracket(
            minIncome: 0,
            maxIncome: 10000,
            rate: 0.15,
            description: "Test"
        )
        
        XCTAssertEqual(bracket.ratePercentage, "15.0%")
    }
    
    // MARK: - Comparable Tests
    
    func testBracketSorting() {
        let bracket1 = TaxBracket(minIncome: 20000, maxIncome: 30000, rate: 0.20, description: "20%")
        let bracket2 = TaxBracket(minIncome: 0, maxIncome: 10000, rate: 0.10, description: "10%")
        let bracket3 = TaxBracket(minIncome: 10000, maxIncome: 20000, rate: 0.15, description: "15%")
        
        let sorted = [bracket1, bracket2, bracket3].sorted()
        
        XCTAssertEqual(sorted[0].minIncome, 0)
        XCTAssertEqual(sorted[1].minIncome, 10000)
        XCTAssertEqual(sorted[2].minIncome, 20000)
    }
    
    // MARK: - Codable Tests
    
    func testEncodeDecode() throws {
        let bracket = TaxBracket(
            minIncome: 10000,
            maxIncome: 20000,
            rate: 0.15,
            description: "Test bracket"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(bracket)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TaxBracket.self, from: data)
        
        XCTAssertEqual(decoded.minIncome, bracket.minIncome)
        XCTAssertEqual(decoded.maxIncome, bracket.maxIncome)
        XCTAssertEqual(decoded.rate, bracket.rate)
        XCTAssertEqual(decoded.description, bracket.description)
    }
}
