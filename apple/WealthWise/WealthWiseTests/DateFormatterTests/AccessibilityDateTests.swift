import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class AccessibilityDateTests: XCTestCase {
    
    var formatter: AccessibleDateFormatter!
    var testDate: Date!
    var testCalendar: Calendar!
    
    override func setUp() {
        super.setUp()
        
        testCalendar = Calendar(identifier: .gregorian)
        testCalendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 15
        components.hour = 10
        components.minute = 30
        
        testDate = testCalendar.date(from: components)!
        formatter = AccessibleDateFormatter(audience: .indian)
    }
    
    override func tearDown() {
        formatter = nil
        testDate = nil
        testCalendar = nil
        super.tearDown()
    }
    
    // MARK: - Basic Accessibility Tests
    
    func testBasicAccessibilityFormatting() {
        let result = formatter.string(from: testDate)
        
        XCTAssertFalse(result.isEmpty, "Accessible date should not be empty")
        XCTAssertGreaterThan(result.count, 10, "Accessible date should be descriptive")
        XCTAssertTrue(result.contains("15") || result.contains("fifteen"), 
                     "Accessible date should contain day in numbers or words")
    }
    
    func testAccessibilityLabel() {
        let label = formatter.accessibilityLabel(for: testDate)
        
        XCTAssertFalse(label.isEmpty, "Accessibility label should not be empty")
        XCTAssertGreaterThan(label.count, 5, "Accessibility label should be meaningful")
    }
    
    func testAccessibilityHint() {
        let hint = formatter.accessibilityHint(for: testDate)
        
        XCTAssertFalse(hint.isEmpty, "Accessibility hint should not be empty")
        XCTAssertTrue(hint.lowercased().contains("date") || hint.lowercased().contains("tap"), 
                     "Accessibility hint should provide interaction guidance")
    }
    
    func testAccessibilityValue() {
        let value = formatter.accessibilityValue(for: testDate)
        
        XCTAssertFalse(value.isEmpty, "Accessibility value should not be empty")
        XCTAssertTrue(value.contains("April") || value.contains("04") || value.contains("15"), 
                     "Accessibility value should contain date information")
    }
    
    func testAccessibilityValueWithContext() {
        let context = "Transaction Date"
        let value = formatter.accessibilityValue(for: testDate, context: context)
        
        XCTAssertTrue(value.contains(context), "Accessibility value should include context")
        XCTAssertTrue(value.contains("April") || value.contains("04") || value.contains("15"), 
                     "Accessibility value should contain date information")
    }
    
    // MARK: - Relative Accessibility Tests
    
    func testRelativeAccessibilityToday() {
        let today = Date()
        let result = formatter.relativeString(from: today)
        
        XCTAssertTrue(result.lowercased().contains("today") || 
                     result.lowercased().contains("आज"), 
                     "Relative accessibility should identify today")
    }
    
    func testRelativeAccessibilityYesterday() {
        let yesterday = testCalendar.date(byAdding: .day, value: -1, to: Date())!
        let result = formatter.relativeString(from: yesterday)
        
        XCTAssertTrue(result.lowercased().contains("yesterday") || 
                     result.lowercased().contains("कल"), 
                     "Relative accessibility should identify yesterday")
    }
    
    func testRelativeAccessibilityTomorrow() {
        let tomorrow = testCalendar.date(byAdding: .day, value: 1, to: Date())!
        let result = formatter.relativeString(from: tomorrow)
        
        XCTAssertTrue(result.lowercased().contains("tomorrow") || 
                     result.lowercased().contains("कल"), 
                     "Relative accessibility should identify tomorrow")
    }
    
    func testRelativeAccessibilityWithAbsolute() {
        let pastDate = testCalendar.date(byAdding: .day, value: -5, to: Date())!
        let result = formatter.relativeString(from: pastDate)
        
        // Should contain both relative and absolute information
        XCTAssertTrue(result.contains("ago") || result.contains("days"), 
                     "Relative accessibility should contain time reference")
        XCTAssertGreaterThan(result.count, 20, "Should be descriptive with both relative and absolute info")
    }
    
    // MARK: - Financial Year Accessibility Tests
    
    func testFinancialYearAccessibility() {
        let result = formatter.financialYearString(from: testDate)
        
        XCTAssertFalse(result.isEmpty, "Financial year accessibility should not be empty")
        XCTAssertTrue(result.contains("FY") || result.contains("financial") || result.contains("2024"), 
                     "Should contain financial year context")
    }
    
    func testFinancialYearStartAccessibility() {
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 1
        let fyStartDate = testCalendar.date(from: components)!
        
        let result = formatter.financialYearString(from: fyStartDate)
        
        XCTAssertTrue(result.contains("FY") || result.contains("financial"), 
                     "FY start should be clearly identified in accessibility")
    }
    
    func testFinancialYearEndAccessibility() {
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 31
        let fyEndDate = testCalendar.date(from: components)!
        
        let result = formatter.financialYearString(from: fyEndDate)
        
        XCTAssertTrue(result.contains("FY") || result.contains("financial"), 
                     "FY end should be clearly identified in accessibility")
    }
    
    // MARK: - Business Day Accessibility Tests
    
    func testBusinessDayAccessibility() {
        // Test weekday
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 15  // Monday
        let weekday = testCalendar.date(from: components)!
        
        let weekdayResult = formatter.businessDayString(from: weekday)
        XCTAssertTrue(weekdayResult.lowercased().contains("weekday") || 
                     weekdayResult.lowercased().contains("business"), 
                     "Weekday should be identified as business day")
        
        // Test weekend
        components.day = 13  // Saturday
        let weekend = testCalendar.date(from: components)!
        
        let weekendResult = formatter.businessDayString(from: weekend)
        XCTAssertTrue(weekendResult.lowercased().contains("weekend") || 
                     weekendResult.lowercased().contains("saturday"), 
                     "Weekend should be identified as weekend")
    }
    
    // MARK: - Urgency Accessibility Tests
    
    func testUrgencyAccessibility() {
        let urgencyLevels = ["high", "medium", "low"]
        
        for urgency in urgencyLevels {
            let result = formatter.urgencyString(from: testDate, urgency: urgency)
            
            XCTAssertFalse(result.isEmpty, "Urgency accessibility should not be empty for \(urgency)")
            XCTAssertTrue(result.lowercased().contains(urgency) || 
                         result.lowercased().contains("urgent") || 
                         result.lowercased().contains("priority"), 
                         "Should contain urgency context for \(urgency)")
        }
    }
    
    func testHighUrgencyAccessibility() {
        let result = formatter.urgencyString(from: testDate, urgency: "high")
        
        XCTAssertTrue(result.lowercased().contains("high") || 
                     result.lowercased().contains("urgent") || 
                     result.lowercased().contains("critical"), 
                     "High urgency should be clearly communicated")
    }
    
    // MARK: - Table Cell Accessibility Tests
    
    func testTableCellAccessibility() {
        let columnContext = "Due Date Column"
        let result = formatter.tableCellString(from: testDate, columnContext: columnContext)
        
        XCTAssertTrue(result.contains(columnContext), "Should include column context")
        XCTAssertTrue(result.contains("April") || result.contains("04") || result.contains("15"), 
                     "Should contain date information")
    }
    
    func testTableCellAccessibilityVariousColumns() {
        let columns = ["Due Date", "Transaction Date", "Created Date", "Modified Date"]
        
        for column in columns {
            let result = formatter.tableCellString(from: testDate, columnContext: "\(column) Column")
            
            XCTAssertTrue(result.contains(column), "Should include \(column) context")
            XCTAssertGreaterThan(result.count, column.count + 10, "Should be descriptive")
        }
    }
    
    // MARK: - Validation Accessibility Tests
    
    func testValidDateAccessibility() {
        let result = formatter.validationString(from: testDate, isValid: true)
        
        XCTAssertTrue(result.lowercased().contains("valid") || 
                     result.lowercased().contains("correct") || 
                     !result.lowercased().contains("invalid"), 
                     "Valid date should be identified as valid")
    }
    
    func testInvalidDateAccessibility() {
        let validationMessage = "Date cannot be in the future"
        let result = formatter.validationString(from: testDate, isValid: false, validationMessage: validationMessage)
        
        XCTAssertTrue(result.lowercased().contains("invalid") || 
                     result.lowercased().contains("error"), 
                     "Invalid date should be identified as invalid")
        XCTAssertTrue(result.contains(validationMessage), "Should include validation message")
    }
    
    func testInvalidDateAccessibilityDefaultMessage() {
        let result = formatter.validationString(from: testDate, isValid: false)
        
        XCTAssertTrue(result.lowercased().contains("invalid") || 
                     result.lowercased().contains("error"), 
                     "Should use default invalid message")
    }
    
    // MARK: - Date Range Accessibility Tests
    
    func testDateRangeAccessibility() {
        let endDate = testCalendar.date(byAdding: .month, value: 2, to: testDate)!
        let result = formatter.accessibilityString(from: testDate, to: endDate)
        
        XCTAssertTrue(result.contains("April") || result.contains("04"), 
                     "Should contain start date information")
        XCTAssertTrue(result.contains("June") || result.contains("06"), 
                     "Should contain end date information")
        XCTAssertTrue(result.lowercased().contains("to") || 
                     result.lowercased().contains("through") || 
                     result.contains("–") || result.contains("-"), 
                     "Should indicate range relationship")
    }
    
    func testSameDateRangeAccessibility() {
        let result = formatter.accessibilityString(from: testDate, to: testDate)
        
        XCTAssertFalse(result.isEmpty, "Same date range should not be empty")
        // Should handle same start and end date gracefully
    }
    
    // MARK: - Pronunciation Guide Tests
    
    func testPronunciationGuide() {
        let guide = formatter.pronunciationGuide(for: testDate)
        
        // May be nil for some audiences/contexts
        if let guide = guide {
            XCTAssertFalse(guide.isEmpty, "Pronunciation guide should not be empty when provided")
            XCTAssertTrue(guide.contains("FY") || guide.contains("financial"), 
                         "Pronunciation guide should help with financial terms")
        }
    }
    
    func testIndianPronunciationGuide() {
        let indianFormatter = AccessibleDateFormatter.indian()
        let guide = indianFormatter.pronunciationGuide(for: testDate)
        
        // Indian context might have pronunciation guide for FY
        if let guide = guide {
            XCTAssertTrue(guide.contains("FY") || guide.contains("financial"), 
                         "Indian pronunciation guide should help with FY")
        }
    }
    
    // MARK: - Special Handling Tests
    
    func testSpecialHandlingDetection() {
        // Test FY boundary dates
        var components = DateComponents()
        components.year = 2024
        components.month = 4
        components.day = 1
        let fyStartDate = testCalendar.date(from: components)!
        
        XCTAssertTrue(formatter.needsSpecialHandling(for: fyStartDate), 
                     "FY start date should need special handling")
        
        components.year = 2025
        components.month = 3
        components.day = 31
        let fyEndDate = testCalendar.date(from: components)!
        
        XCTAssertTrue(formatter.needsSpecialHandling(for: fyEndDate), 
                     "FY end date should need special handling")
        
        // Regular date should not need special handling
        components.year = 2024
        components.month = 6
        components.day = 15
        let regularDate = testCalendar.date(from: components)!
        
        XCTAssertFalse(formatter.needsSpecialHandling(for: regularDate), 
                      "Regular date should not need special handling")
    }
    
    // MARK: - Multiple Audience Accessibility Tests
    
    func testMultipleAudienceAccessibility() {
        let audiences: [PrimaryAudience] = [.indian, .american, .british, .german, .japanese]
        
        for audience in audiences {
            let formatter = AccessibleDateFormatter.formatter(for: audience)
            let result = formatter.string(from: testDate)
            
            XCTAssertFalse(result.isEmpty, "Accessibility should work for \(audience)")
            XCTAssertGreaterThan(result.count, 10, "Should be descriptive for \(audience)")
        }
    }
    
    func testRTLLanguageAccessibility() {
        let rtlAudiences: [PrimaryAudience] = [.emirati, .qatari, .saudi]
        
        for audience in rtlAudiences {
            let formatter = AccessibleDateFormatter.formatter(for: audience)
            let result = formatter.string(from: testDate)
            
            XCTAssertFalse(result.isEmpty, "RTL accessibility should work for \(audience)")
        }
    }
    
    // MARK: - Accessibility Configuration Tests
    
    func testVoiceOverConfiguration() {
        let voiceOverFormatter = AccessibleDateFormatter.indian()
        voiceOverFormatter.configureForAccessibility(voiceOverEnabled: true, preferredContentSize: .large)
        
        let result = voiceOverFormatter.string(from: testDate)
        XCTAssertGreaterThan(result.count, 15, "VoiceOver configuration should produce detailed descriptions")
    }
    
    func testAccessibilitySizeConfiguration() {
        let formatter = AccessibleDateFormatter.indian()
        formatter.configureForAccessibility(voiceOverEnabled: false, preferredContentSize: .accessibilityExtraExtraExtraLarge)
        
        let result = formatter.string(from: testDate)
        XCTAssertFalse(result.isEmpty, "Should handle accessibility size categories")
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityPerformance() {
        let dates = (0..<100).map { dayOffset in
            testCalendar.date(byAdding: .day, value: dayOffset, to: testDate)!
        }
        
        measure {
            for date in dates {
                _ = formatter.string(from: date)
                _ = formatter.accessibilityLabel(for: date)
                _ = formatter.businessDayString(from: date)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAccessibilityWithExtremeDate() {
        let extremeDate = Date(timeIntervalSince1970: 0) // January 1, 1970
        let result = formatter.string(from: extremeDate)
        
        XCTAssertFalse(result.isEmpty, "Should handle extreme dates gracefully")
    }
    
    func testAccessibilityWithFutureDate() {
        let futureDate = Date(timeIntervalSince1970: 4000000000) // Far future
        let result = formatter.string(from: futureDate)
        
        XCTAssertFalse(result.isEmpty, "Should handle far future dates gracefully")
    }
}