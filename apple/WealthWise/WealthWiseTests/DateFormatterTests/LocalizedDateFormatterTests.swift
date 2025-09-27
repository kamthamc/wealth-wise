import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class LocalizedDateFormatterTests: XCTestCase {
    
    var formatter: LocalizedDateFormatter!
    var testDate: Date!
    var testCalendar: Calendar!
    
    override func setUp() {
        super.setUp()
        
        // Create a fixed test date: April 15, 2024 (middle of Indian FY)
        testCalendar = Calendar(identifier: .gregorian)
        testCalendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 15
        components.hour = 10
        components.minute = 30
        
        testDate = testCalendar.date(from: components)!
        formatter = LocalizedDateFormatter(configuration: .indian)
    }
    
    override func tearDown() {
        formatter = nil
        testDate = nil
        testCalendar = nil
        super.tearDown()
    }
    
    // MARK: - Basic Formatting Tests
    
    func testBasicDateFormatting() {
        let result = formatter.string(from: testDate)
        XCTAssertFalse(result.isEmpty, "Formatted date should not be empty")
        XCTAssertTrue(result.contains("15"), "Formatted date should contain day 15")
        XCTAssertTrue(result.contains("Apr") || result.contains("04"), "Formatted date should contain April")
        XCTAssertTrue(result.contains("2024"), "Formatted date should contain year 2024")
    }
    
    func testIndianDateFormat() {
        let indianFormatter = LocalizedDateFormatter.indian()
        let result = indianFormatter.string(from: testDate)
        
        // Indian format should be DD/MM/YYYY or similar
        XCTAssertTrue(result.matches(pattern: "\\d{1,2}[/\\-.]\\d{1,2}[/\\-.]\\d{4}") || 
                     result.contains("Apr"), "Indian date format should follow DD/MM/YYYY pattern or use month names")
    }
    
    func testAmericanDateFormat() {
        let americanFormatter = LocalizedDateFormatter.american()
        let result = americanFormatter.string(from: testDate)
        
        // American format should be MM/DD/YYYY or similar
        XCTAssertFalse(result.isEmpty, "American formatted date should not be empty")
        XCTAssertTrue(result.contains("15") || result.contains("Apr"), "American date should contain day or month")
    }
    
    func testBritishDateFormat() {
        let britishFormatter = LocalizedDateFormatter.british()
        let result = britishFormatter.string(from: testDate)
        
        // British format should be DD/MM/YYYY or similar
        XCTAssertFalse(result.isEmpty, "British formatted date should not be empty")
        XCTAssertTrue(result.contains("15") || result.contains("Apr"), "British date should contain day or month")
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationChange() {
        let originalResult = formatter.string(from: testDate)
        
        // Change configuration
        formatter.configuration = .american
        let newResult = formatter.string(from: testDate)
        
        XCTAssertNotEqual(originalResult, newResult, "Date format should change when configuration changes")
    }
    
    func testCustomConfiguration() {
        let customConfig = DateFormatterConfiguration(
            audience: .indian,
            dateStyle: .short,
            timeStyle: .short,
            customFormat: "yyyy-MM-dd HH:mm"
        )
        
        formatter.configuration = customConfig
        let result = formatter.string(from: testDate)
        
        XCTAssertTrue(result.contains("2024-04-15"), "Custom format should be respected")
        XCTAssertTrue(result.contains("10:30"), "Custom format should include time")
    }
    
    // MARK: - Relative Formatting Tests
    
    func testRelativeFormatting() {
        let today = Date()
        let relativeResult = formatter.relativeString(from: today)
        
        XCTAssertTrue(relativeResult.lowercased().contains("today") || 
                     relativeResult.lowercased().contains("आज"), 
                     "Today should be formatted as 'today' or localized equivalent")
    }
    
    func testRelativeFormattingYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let relativeResult = formatter.relativeString(from: yesterday)
        
        XCTAssertTrue(relativeResult.lowercased().contains("yesterday") || 
                     relativeResult.lowercased().contains("कल"), 
                     "Yesterday should be formatted as 'yesterday' or localized equivalent")
    }
    
    func testRelativeFormattingTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let relativeResult = formatter.relativeString(from: tomorrow)
        
        XCTAssertTrue(relativeResult.lowercased().contains("tomorrow") || 
                     relativeResult.lowercased().contains("कल"), 
                     "Tomorrow should be formatted as 'tomorrow' or localized equivalent")
    }
    
    // MARK: - Financial Year Tests
    
    func testFinancialYearFormatting() {
        let fyResult = formatter.financialYearString(from: testDate)
        
        XCTAssertTrue(fyResult.contains("FY") || fyResult.contains("2024"), 
                     "Financial year formatting should include FY or year information")
    }
    
    func testIndianFinancialYear() {
        // Test date in April (start of Indian FY)
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 1
        let fyStartDate = testCalendar.date(from: components)!
        
        let fy = fyStartDate.financialYear(for: .indian)
        XCTAssertEqual(fy, 2024, "April 1, 2024 should be FY 2024 in Indian system")
        
        // Test date in March (end of Indian FY)
        components.year = 2025
        components.month = 3
        components.day = 31
        let fyEndDate = testCalendar.date(from: components)!
        
        let fyEnd = fyEndDate.financialYear(for: .indian)
        XCTAssertEqual(fyEnd, 2024, "March 31, 2025 should be FY 2024 in Indian system")
    }
    
    func testWesternCalendarYear() {
        let fy = testDate.financialYear(for: .american)
        XCTAssertEqual(fy, 2024, "April 15, 2024 should be year 2024 in Western system")
    }
    
    // MARK: - Date Range Tests
    
    func testDateRangeFormatting() {
        let startDate = testDate!
        let endDate = testCalendar.date(byAdding: .month, value: 2, to: startDate)!
        
        let rangeResult = formatter.string(from: startDate, to: endDate)
        
        XCTAssertFalse(rangeResult.isEmpty, "Date range should not be empty")
        XCTAssertTrue(rangeResult.contains("Apr") || rangeResult.contains("15"), 
                     "Date range should contain start date information")
        XCTAssertTrue(rangeResult.contains("Jun") || rangeResult.contains("15"), 
                     "Date range should contain end date information")
    }
    
    func testSameYearDateRange() {
        let startDate = testDate!
        let endDate = testCalendar.date(byAdding: .day, value: 30, to: startDate)!
        
        let rangeResult = formatter.string(from: startDate, to: endDate)
        
        // Should optimize format for same year
        let yearCount = rangeResult.components(separatedBy: "2024").count - 1
        XCTAssertLessThanOrEqual(yearCount, 1, "Same year range should not repeat year unnecessarily")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityFormatting() {
        let accessibleResult = formatter.accessibleString(from: testDate)
        
        XCTAssertFalse(accessibleResult.isEmpty, "Accessible formatting should not be empty")
        XCTAssertGreaterThan(accessibleResult.count, 10, "Accessible formatting should be descriptive")
    }
    
    // MARK: - Caching Tests
    
    func testFormattingCache() {
        // Format the same date multiple times
        let result1 = formatter.string(from: testDate)
        let result2 = formatter.string(from: testDate)
        let result3 = formatter.string(from: testDate)
        
        XCTAssertEqual(result1, result2, "Cached results should be identical")
        XCTAssertEqual(result2, result3, "Cached results should be identical")
    }
    
    func testCacheClearance() {
        let originalResult = formatter.string(from: testDate)
        
        formatter.clearCache()
        let newResult = formatter.string(from: testDate)
        
        XCTAssertEqual(originalResult, newResult, "Results should be same after cache clear")
    }
    
    // MARK: - Performance Tests
    
    func testFormattingPerformance() {
        let dates = (0..<1000).map { _ in
            testCalendar.date(byAdding: .day, value: Int.random(in: -365...365), to: testDate)!
        }
        
        measure {
            for date in dates {
                _ = formatter.string(from: date)
            }
        }
    }
    
    func testRelativeFormattingPerformance() {
        let dates = (0..<100).map { dayOffset in
            testCalendar.date(byAdding: .day, value: dayOffset - 50, to: Date())!
        }
        
        measure {
            for date in dates {
                _ = formatter.relativeString(from: date)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDateHandling() {
        // Test with very old date
        let oldDate = Date(timeIntervalSince1970: 0)
        let result = formatter.string(from: oldDate)
        
        XCTAssertFalse(result.isEmpty, "Should handle very old dates gracefully")
    }
    
    func testFutureDistantDateHandling() {
        // Test with very future date
        let futureDate = Date(timeIntervalSince1970: 4000000000) // Year 2096
        let result = formatter.string(from: futureDate)
        
        XCTAssertFalse(result.isEmpty, "Should handle very future dates gracefully")
    }
    
    // MARK: - Cultural Adaptation Tests
    
    func testMultipleCulturalFormats() {
        let audiences: [PrimaryAudience] = [.indian, .american, .british, .german, .japanese]
        
        for audience in audiences {
            let config = DateFormatterConfiguration(audience: audience)
            let formatter = LocalizedDateFormatter(configuration: config)
            let result = formatter.string(from: testDate)
            
            XCTAssertFalse(result.isEmpty, "Date formatting should work for \(audience) audience")
        }
    }
    
    func testWeekStartDayVariations() {
        let indianCalendar = Calendar.calendar(for: .indian)
        let americanCalendar = Calendar.calendar(for: .american)
        
        XCTAssertEqual(indianCalendar.firstWeekday, 2, "Indian calendar should start week on Monday")
        XCTAssertEqual(americanCalendar.firstWeekday, 1, "American calendar should start week on Sunday")
    }
}

// MARK: - Test Helpers

extension LocalizedDateFormatterTests {
    
    private func assertDateFormatValid(_ dateString: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(dateString.isEmpty, "Date string should not be empty", file: file, line: line)
        XCTAssertGreaterThan(dateString.count, 5, "Date string should be reasonably long", file: file, line: line)
    }
}

extension String {
    func matches(pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
}