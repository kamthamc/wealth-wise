import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class FinancialYearFormatterTests: XCTestCase {
    
    var formatter: FinancialYearFormatter!
    var testCalendar: Calendar!
    
    override func setUp() {
        super.setUp()
        
        testCalendar = Calendar(identifier: .gregorian)
        testCalendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        formatter = FinancialYearFormatter(audience: .indian)
    }
    
    override func tearDown() {
        formatter = nil
        testCalendar = nil
        super.tearDown()
    }
    
    // MARK: - Financial Year Calculation Tests
    
    func testIndianFinancialYearStart() {
        // April 1, 2024 - start of FY 2024
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 1
        let fyStartDate = testCalendar.date(from: components)!
        
        let fy = fyStartDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2024, "April 1, 2024 should be start of FY 2024")
        
        let fyLabel = formatter.financialYearLabel(for: fyStartDate)
        XCTAssertTrue(fyLabel.contains("FY") && fyLabel.contains("2024"), 
                     "FY label should contain 'FY' and '2024'")
    }
    
    func testIndianFinancialYearEnd() {
        // March 31, 2025 - end of FY 2024
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 31
        let fyEndDate = testCalendar.date(from: components)!
        
        let fy = fyEndDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2024, "March 31, 2025 should be end of FY 2024")
    }
    
    func testIndianFinancialYearMidYear() {
        // September 15, 2024 - middle of FY 2024
        var components = DateComponents()
        components.year = 2024
        components.month = 9
        components.day = 15
        let midYearDate = testCalendar.date(from: components)!
        
        let fy = midYearDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2024, "September 15, 2024 should be in FY 2024")
    }
    
    func testIndianFinancialYearCrossover() {
        // January 15, 2025 - should be FY 2024 (previous calendar year)
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let crossoverDate = testCalendar.date(from: components)!
        
        let fy = crossoverDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2024, "January 15, 2025 should be in FY 2024")
    }
    
    // MARK: - Western Calendar Year Tests
    
    func testAmericanCalendarYear() {
        let americanFormatter = FinancialYearFormatter.american()
        
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 15
        let testDate = testCalendar.date(from: components)!
        
        let fy = testDate.financialYear(for: .american)
        XCTAssertEqual(fy, 2024, "American FY should match calendar year")
        
        let fyLabel = americanFormatter.financialYearLabel(for: testDate)
        XCTAssertTrue(fyLabel.contains("2024"), "American FY label should contain year")
        XCTAssertFalse(fyLabel.contains("FY"), "American FY label should not contain 'FY'")
    }
    
    // MARK: - Quarter Calculation Tests
    
    func testFinancialQuarterCalculation() {
        let testCases: [(month: Int, expectedQuarter: Int)] = [
            (4, 1),   // April - Q1
            (6, 1),   // June - Q1
            (7, 2),   // July - Q2
            (9, 2),   // September - Q2
            (10, 3),  // October - Q3
            (12, 3),  // December - Q3
            (1, 4),   // January - Q4
            (3, 4)    // March - Q4
        ]
        
        for (month, expectedQuarter) in testCases {
            var components = DateComponents()
            components.year = month <= 3 ? 2025 : 2024  // Handle year boundary
            components.month = month
            components.day = 15
            let testDate = testCalendar.date(from: components)!
            
            let quarter = testDate.financialQuarter(for: .indian)
            XCTAssertEqual(quarter, expectedQuarter, 
                          "Month \(month) should be in quarter \(expectedQuarter)")
        }
    }
    
    func testQuarterLabels() {
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 15
        let q1Date = testCalendar.date(from: components)!
        
        let quarterLabel = formatter.quarterLabel(for: q1Date)
        XCTAssertTrue(quarterLabel.contains("Q1") && quarterLabel.contains("FY") && quarterLabel.contains("2024"), 
                     "Quarter label should contain Q1, FY, and 2024")
    }
    
    // MARK: - Financial Year Range Tests
    
    func testFinancialYearRange() {
        var components = DateComponents()
        components.year = 2024
        components.month = 9
        components.day = 15
        let testDate = testCalendar.date(from: components)!
        
        let fyRange = formatter.financialYearRange(for: testDate)
        
        XCTAssertTrue(fyRange.contains("Apr") && fyRange.contains("2024"), 
                     "FY range should contain April 2024")
        XCTAssertTrue(fyRange.contains("Mar") && fyRange.contains("2025"), 
                     "FY range should contain March 2025")
    }
    
    // MARK: - Financial Year Boundary Tests
    
    func testFinancialYearStartDetection() {
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 15
        let aprilDate = testCalendar.date(from: components)!
        
        XCTAssertTrue(formatter.isFinancialYearStart(aprilDate), 
                     "April should be detected as FY start")
        
        components.month = 5
        let mayDate = testCalendar.date(from: components)!
        
        XCTAssertFalse(formatter.isFinancialYearStart(mayDate), 
                      "May should not be detected as FY start")
    }
    
    func testFinancialYearEndDetection() {
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 15
        let marchDate = testCalendar.date(from: components)!
        
        XCTAssertTrue(formatter.isFinancialYearEnd(marchDate), 
                     "March should be detected as FY end")
        
        components.month = 2
        let febDate = testCalendar.date(from: components)!
        
        XCTAssertFalse(formatter.isFinancialYearEnd(febDate), 
                      "February should not be detected as FY end")
    }
    
    // MARK: - Days Calculation Tests
    
    func testDaysRemainingInFinancialYear() {
        // Test from beginning of FY
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 1
        let fyStartDate = testCalendar.date(from: components)!
        
        let daysRemaining = formatter.daysRemainingInFinancialYear(from: fyStartDate)
        XCTAssertGreaterThan(daysRemaining, 360, "Should have ~365 days remaining from FY start")
        XCTAssertLessThan(daysRemaining, 370, "Should not exceed reasonable FY length")
    }
    
    func testDaysElapsedInFinancialYear() {
        // Test from end of FY
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 31
        let fyEndDate = testCalendar.date(from: components)!
        
        let daysElapsed = formatter.daysElapsedInFinancialYear(from: fyEndDate)
        XCTAssertGreaterThan(daysElapsed, 360, "Should have ~365 days elapsed by FY end")
        XCTAssertLessThan(daysElapsed, 370, "Should not exceed reasonable FY length")
    }
    
    // MARK: - Tax Year Tests
    
    func testTaxYearFormatting() {
        var components = DateComponents()
        components.year = 2024
        components.month = 9
        components.day = 15
        let testDate = testCalendar.date(from: components)!
        
        let taxYearString = formatter.taxYearString(from: testDate)
        
        XCTAssertFalse(taxYearString.isEmpty, "Tax year string should not be empty")
        XCTAssertTrue(taxYearString.contains("2024"), "Tax year should contain year 2024")
    }
    
    func testIndianTaxYear() {
        // For Indian audience, tax year = financial year
        var components = DateComponents()
        components.year = 2024
        components.month = 9
        components.day = 15
        let testDate = testCalendar.date(from: components)!
        
        let taxYearString = formatter.taxYearString(from: testDate)
        XCTAssertTrue(taxYearString.contains("2024"), "Indian tax year should be 2024 for Sep 2024")
    }
    
    func testAmericanTaxYear() {
        let americanFormatter = FinancialYearFormatter.american()
        
        var components = DateComponents()
        components.year = 2024
        components.month = 9
        components.day = 15
        let testDate = testCalendar.date(from: components)!
        
        let taxYearString = americanFormatter.taxYearString(from: testDate)
        XCTAssertTrue(taxYearString.contains("2024"), "American tax year should be 2024 for Sep 2024")
    }
    
    // MARK: - Progress Calculation Tests
    
    func testFinancialYearProgress() {
        // Test at FY start (April 1)
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 1
        let fyStartDate = testCalendar.date(from: components)!
        
        let startProgress = formatter.financialYearProgress(for: fyStartDate)
        XCTAssertEqual(startProgress, 0.0, accuracy: 0.01, "Progress should be 0% at FY start")
        
        // Test at FY end (March 31)
        components.year = 2025
        components.month = 3
        components.day = 31
        let fyEndDate = testCalendar.date(from: components)!
        
        let endProgress = formatter.financialYearProgress(for: fyEndDate)
        XCTAssertEqual(endProgress, 1.0, accuracy: 0.01, "Progress should be 100% at FY end")
        
        // Test at mid-year (roughly October 1)
        components.year = 2024
        components.month = 10
        components.day = 1
        let midYearDate = testCalendar.date(from: components)!
        
        let midProgress = formatter.financialYearProgress(for: midYearDate)
        XCTAssertGreaterThan(midProgress, 0.4, "Progress should be > 40% by October")
        XCTAssertLessThan(midProgress, 0.6, "Progress should be < 60% by October")
    }
    
    // MARK: - Multiple Audience Tests
    
    func testMultipleAudienceFormats() {
        let audiences: [PrimaryAudience] = [.indian, .american, .british, .canadian, .australian]
        
        var components = DateComponents()
        components.year = 2024
        components.month = 9
        components.day = 15
        let testDate = testCalendar.date(from: components)!
        
        for audience in audiences {
            let formatter = FinancialYearFormatter.formatter(for: audience)
            let result = formatter.string(from: testDate)
            
            XCTAssertFalse(result.isEmpty, "Financial year formatting should work for \(audience)")
            
            let fyLabel = formatter.financialYearLabel(for: testDate)
            XCTAssertTrue(fyLabel.contains("2024"), "\(audience) FY label should contain year 2024")
        }
    }
    
    // MARK: - Performance Tests
    
    func testFinancialYearCalculationPerformance() {
        let dates = (0..<1000).map { dayOffset in
            testCalendar.date(byAdding: .day, value: dayOffset, to: Date())!
        }
        
        measure {
            for date in dates {
                _ = date.financialYear(for: .indian)
                _ = date.financialQuarter(for: .indian)
            }
        }
    }
    
    func testFormatterPerformance() {
        let dates = (0..<500).map { dayOffset in
            testCalendar.date(byAdding: .day, value: dayOffset, to: Date())!
        }
        
        measure {
            for date in dates {
                _ = formatter.string(from: date)
                _ = formatter.quarterLabel(for: date)
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testLeapYearHandling() {
        // Test leap year boundary (Feb 29, 2024)
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 29
        let leapDate = testCalendar.date(from: components)!
        
        let fy = leapDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2023, "Feb 29, 2024 should be in FY 2023")
        
        let fyString = formatter.string(from: leapDate)
        XCTAssertFalse(fyString.isEmpty, "Should handle leap year dates")
    }
    
    func testCenturyBoundary() {
        // Test dates around century boundaries
        var components = DateComponents()
        components.year = 2000
        components.month = 4
        components.day = 1
        let centuryDate = testCalendar.date(from: components)!
        
        let fy = centuryDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2000, "Century boundary should be handled correctly")
    }
    
    func testVeryOldDates() {
        // Test with dates far in the past
        var components = DateComponents()
        components.year = 1900
        components.month = 4
        components.day = 1
        let oldDate = testCalendar.date(from: components)!
        
        let fyString = formatter.string(from: oldDate)
        XCTAssertFalse(fyString.isEmpty, "Should handle very old dates")
    }
    
    func testVeryFutureDates() {
        // Test with dates far in the future
        var components = DateComponents()
        components.year = 2100
        components.month = 4
        components.day = 1
        let futureDate = testCalendar.date(from: components)!
        
        let fyString = formatter.string(from: futureDate)
        XCTAssertFalse(fyString.isEmpty, "Should handle very future dates")
    }
}