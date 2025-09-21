import XCTest
@testable import WealthWise

final class CountryTests: XCTestCase {
    
    // MARK: - Country Model Tests
    
    func testCountryInitialization() {
        let country = Country(
            id: "IN",
            name: "India",
            displayName: "India",
            flag: "🇮🇳",
            primaryCurrency: .inr,
            secondaryCurrencies: [.usd, .eur],
            region: .asia,
            regulatoryZone: .dpia,
            financialYearStart: .april,
            numberingSystem: .indian,
            taxSystem: .progressive,
            retirementAge: RetirementAge(standard: 60, early: 50, maximum: 70, pensionEligibility: 58),
            commonInvestmentTypes: [.retirementPPF, .stocksLocal],
            bankingFeatures: BankingFeatures(hasUPI: true, supportedAccountTypes: [.savings]),
            culturalPreferences: CulturalPreferences(
                dateFormat: .dayMonthYear,
                weekStartsOn: .monday,
                workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                commonHolidays: ["Diwali"],
                timeFormat: .twelve,
                familyFinanceStyle: .joint,
                savingsPreference: .conservative,
                investmentRiskTolerance: .moderate
            )
        )
        
        XCTAssertEqual(country.id, "IN")
        XCTAssertEqual(country.name, "India")
        XCTAssertEqual(country.displayName, "India")
        XCTAssertEqual(country.flag, "🇮🇳")
        XCTAssertEqual(country.primaryCurrency, .inr)
        XCTAssertEqual(country.secondaryCurrencies, [.usd, .eur])
        XCTAssertEqual(country.region, .asia)
        XCTAssertEqual(country.regulatoryZone, .dpia)
        XCTAssertEqual(country.financialYearStart, .april)
        XCTAssertEqual(country.numberingSystem, .indian)
        XCTAssertEqual(country.taxSystem, .progressive)
        XCTAssertEqual(country.retirementAge.standard, 60)
        XCTAssertTrue(country.commonInvestmentTypes.contains(.retirementPPF))
        XCTAssertTrue(country.bankingFeatures.hasUPI)
        XCTAssertEqual(country.culturalPreferences.dateFormat, .dayMonthYear)
    }
    
    func testCountrySupportsInvestmentType() {
        let country = SupportedCountries.india
        
        XCTAssertTrue(country.supports(investmentType: .retirementPPF))
        XCTAssertTrue(country.supports(investmentType: .stocksLocal))
        XCTAssertFalse(country.supports(investmentType: .retirement401k)) // US-specific
    }
    
    func testCountrySupportsAccountType() {
        let country = SupportedCountries.india
        
        XCTAssertTrue(country.supports(accountType: .savings))
        XCTAssertTrue(country.supports(accountType: .fixedDeposit))
        XCTAssertFalse(country.supports(accountType: .cd)) // US-specific
    }
    
    func testCountryHasInstantPayments() {
        let indiaCountry = SupportedCountries.india
        let usCountry = SupportedCountries.unitedStates
        let canadaCountry = SupportedCountries.canada
        
        XCTAssertTrue(indiaCountry.hasInstantPayments) // Has UPI
        XCTAssertTrue(usCountry.hasInstantPayments) // Has instant transfers
        XCTAssertTrue(canadaCountry.hasInstantPayments) // Has Interac
    }
    
    func testCurrentFinancialYear() {
        let indiaCountry = SupportedCountries.india // April start
        let usCountry = SupportedCountries.unitedStates // January start
        
        // Test April financial year
        let marchDate = Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15))!
        let aprilDate = Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 15))!
        
        XCTAssertEqual(indiaCountry.currentFinancialYear(date: marchDate), 2023) // Still in FY 2023-24
        XCTAssertEqual(indiaCountry.currentFinancialYear(date: aprilDate), 2024) // New FY 2024-25
        
        // Test January financial year
        let decemberDate = Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 15))!
        let januaryDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        
        XCTAssertEqual(usCountry.currentFinancialYear(date: decemberDate), 2023)
        XCTAssertEqual(usCountry.currentFinancialYear(date: januaryDate), 2024)
    }
    
    func testRecommendedInvestments() {
        let country = SupportedCountries.india
        
        let veryLowRisk = country.recommendedInvestments(for: .veryLow)
        let highRisk = country.recommendedInvestments(for: .high)
        
        // Very low risk should only include safe investments
        XCTAssertTrue(veryLowRisk.contains(.cashSavings))
        XCTAssertTrue(veryLowRisk.contains(.bondsGovernment))
        XCTAssertFalse(veryLowRisk.contains(.stocksLocal))
        
        // High risk should include all available investments
        XCTAssertTrue(highRisk.contains(.stocksLocal))
        XCTAssertTrue(highRisk.contains(.retirementPPF))
        XCTAssertTrue(highRisk.contains(.alternativeGold))
    }
    
    func testAccessibilityLabel() {
        let country = SupportedCountries.india
        let label = country.accessibilityLabel
        
        XCTAssertTrue(label.contains("India"))
        XCTAssertTrue(label.contains("Indian Rupee"))
        XCTAssertTrue(label.contains("Asia"))
    }
    
    // MARK: - Enum Tests
    
    func testGeographicRegion() {
        XCTAssertEqual(GeographicRegion.asia.displayName, "Asia")
        XCTAssertEqual(GeographicRegion.europe.displayName, "Europe")
        XCTAssertEqual(GeographicRegion.northAmerica.displayName, "North America")
    }
    
    func testRegulatoryZone() {
        XCTAssertEqual(RegulatoryZone.gdpr.displayName, "GDPR (EU)")
        XCTAssertEqual(RegulatoryZone.dpia.displayName, "DPIA (India)")
        
        XCTAssertTrue(RegulatoryZone.gdpr.requiresExplicitConsent)
        XCTAssertFalse(RegulatoryZone.ccpa.requiresExplicitConsent)
        
        XCTAssertNotNil(RegulatoryZone.gdpr.dataRetentionLimit)
        XCTAssertNil(RegulatoryZone.other.dataRetentionLimit)
    }
    
    func testFinancialYearStart() {
        XCTAssertEqual(FinancialYearStart.april.startMonth, 4)
        XCTAssertEqual(FinancialYearStart.january.startMonth, 1)
        XCTAssertEqual(FinancialYearStart.july.startMonth, 7)
        
        XCTAssertEqual(FinancialYearStart.april.displayName, "April (India/Japan style)")
    }
    
    func testNumberingSystem() {
        XCTAssertEqual(NumberingSystem.indian.displayName, "Indian (Lakh/Crore)")
        XCTAssertEqual(NumberingSystem.western.displayName, "Western (Million/Billion)")
        
        XCTAssertEqual(NumberingSystem.indian.thousandsSeparator, ",")
        XCTAssertEqual(NumberingSystem.arabic.thousandsSeparator, "٬")
        
        XCTAssertEqual(NumberingSystem.western.decimalSeparator, ".")
        XCTAssertEqual(NumberingSystem.arabic.decimalSeparator, "٫")
    }
    
    func testTaxSystemType() {
        XCTAssertEqual(TaxSystemType.progressive.displayName, "Progressive Tax System")
        XCTAssertEqual(TaxSystemType.flat.displayName, "Flat Tax System")
    }
    
    func testRetirementAge() {
        let retirement = RetirementAge(standard: 65, early: 60, maximum: 70, pensionEligibility: 65)
        
        XCTAssertEqual(retirement.standard, 65)
        XCTAssertEqual(retirement.early, 60)
        XCTAssertEqual(retirement.maximum, 70)
        XCTAssertEqual(retirement.pensionEligibility, 65)
    }
    
    func testInvestmentType() {
        XCTAssertEqual(InvestmentType.retirementPPF.displayName, "PPF (Public Provident Fund)")
        XCTAssertEqual(InvestmentType.retirement401k.displayName, "401(k)")
        XCTAssertEqual(InvestmentType.stocksLocal.displayName, "Local Stocks")
        
        XCTAssertEqual(InvestmentType.retirementPPF.category, .retirement)
        XCTAssertEqual(InvestmentType.stocksLocal.category, .equity)
        XCTAssertEqual(InvestmentType.bondsGovernment.category, .fixedIncome)
    }
    
    func testInvestmentCategory() {
        XCTAssertEqual(InvestmentCategory.retirement.displayName, "Retirement & Tax-Advantaged")
        XCTAssertEqual(InvestmentCategory.equity.displayName, "Stocks & Equity")
    }
    
    func testBankingFeatures() {
        let features = BankingFeatures(
            hasUPI: true,
            hasOpenBanking: false,
            hasInstantTransfers: true,
            supportedAccountTypes: [.savings, .checking]
        )
        
        XCTAssertTrue(features.hasUPI)
        XCTAssertFalse(features.hasOpenBanking)
        XCTAssertTrue(features.hasInstantTransfers)
        XCTAssertEqual(features.supportedAccountTypes.count, 2)
    }
    
    func testBankAccountType() {
        XCTAssertEqual(BankAccountType.savings.displayName, "Savings Account")
        XCTAssertEqual(BankAccountType.fixedDeposit.displayName, "Fixed Deposit")
        XCTAssertEqual(BankAccountType.currentAccount.displayName, "Current Account")
    }
    
    func testCulturalPreferences() {
        let preferences = CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .monday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["Diwali", "Holi"],
            timeFormat: .twelve,
            familyFinanceStyle: .joint,
            savingsPreference: .conservative,
            investmentRiskTolerance: .moderate
        )
        
        XCTAssertEqual(preferences.dateFormat, .dayMonthYear)
        XCTAssertEqual(preferences.weekStartsOn, .monday)
        XCTAssertEqual(preferences.workingDays.count, 5)
        XCTAssertEqual(preferences.commonHolidays.count, 2)
        XCTAssertEqual(preferences.timeFormat, .twelve)
        XCTAssertEqual(preferences.familyFinanceStyle, .joint)
        XCTAssertEqual(preferences.savingsPreference, .conservative)
        XCTAssertEqual(preferences.investmentRiskTolerance, .moderate)
    }
    
    func testDateFormatStyle() {
        XCTAssertEqual(DateFormatStyle.monthDayYear.displayName, "MM/DD/YYYY (US Style)")
        XCTAssertEqual(DateFormatStyle.dayMonthYear.displayName, "DD/MM/YYYY (European/Indian Style)")
        XCTAssertEqual(DateFormatStyle.yearMonthDay.displayName, "YYYY-MM-DD (ISO 8601)")
    }
    
    func testWeekday() {
        XCTAssertEqual(Weekday.monday.displayName, "Monday")
        XCTAssertEqual(Weekday.sunday.displayName, "Sunday")
    }
    
    func testTimeFormat() {
        XCTAssertEqual(TimeFormat.twelve.displayName, "12-hour (AM/PM)")
        XCTAssertEqual(TimeFormat.twentyFour.displayName, "24-hour")
    }
    
    func testFamilyFinanceStyle() {
        XCTAssertEqual(FamilyFinanceStyle.individual.displayName, "Individual Finance Management")
        XCTAssertEqual(FamilyFinanceStyle.joint.displayName, "Joint Family Finances")
        XCTAssertEqual(FamilyFinanceStyle.hybrid.displayName, "Hybrid (Individual + Shared)")
    }
    
    func testSavingsPreference() {
        XCTAssertEqual(SavingsPreference.conservative.displayName, "Conservative (Safety First)")
        XCTAssertEqual(SavingsPreference.aggressive.displayName, "Aggressive (Growth Focused)")
    }
    
    func testRiskTolerance() {
        XCTAssertEqual(RiskTolerance.veryLow.displayName, "Very Low Risk")
        XCTAssertEqual(RiskTolerance.veryHigh.displayName, "Very High Risk")
        
        XCTAssertEqual(RiskTolerance.veryLow.volatilityTolerance, 0.05)
        XCTAssertEqual(RiskTolerance.veryHigh.volatilityTolerance, 0.50)
    }
    
    // MARK: - Codable Tests
    
    func testCountryCodable() throws {
        let originalCountry = SupportedCountries.india
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalCountry)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCountry = try decoder.decode(Country.self, from: data)
        
        XCTAssertEqual(originalCountry.id, decodedCountry.id)
        XCTAssertEqual(originalCountry.name, decodedCountry.name)
        XCTAssertEqual(originalCountry.primaryCurrency, decodedCountry.primaryCurrency)
        XCTAssertEqual(originalCountry.region, decodedCountry.region)
        XCTAssertEqual(originalCountry.regulatoryZone, decodedCountry.regulatoryZone)
    }
    
    func testRetirementAgeCodable() throws {
        let retirement = RetirementAge(standard: 65, early: 60, maximum: 70, pensionEligibility: 65)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(retirement)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RetirementAge.self, from: data)
        
        XCTAssertEqual(retirement.standard, decoded.standard)
        XCTAssertEqual(retirement.early, decoded.early)
        XCTAssertEqual(retirement.maximum, decoded.maximum)
        XCTAssertEqual(retirement.pensionEligibility, decoded.pensionEligibility)
    }
    
    // MARK: - Performance Tests
    
    func testCountryCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = SupportedCountries.india
            }
        }
    }
    
    func testCountryRecommendationPerformance() {
        let country = SupportedCountries.india
        
        measure {
            for _ in 0..<1000 {
                _ = country.recommendedInvestments(for: .moderate)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testCountryWithMinimalData() {
        let minimalCountry = Country(
            id: "XX",
            name: "Test Country",
            displayName: "Test Country",
            flag: "🏳️",
            primaryCurrency: .usd,
            region: .other,
            regulatoryZone: .other,
            financialYearStart: .january,
            numberingSystem: .western,
            taxSystem: .flat,
            retirementAge: RetirementAge(standard: 65),
            commonInvestmentTypes: [],
            bankingFeatures: BankingFeatures(supportedAccountTypes: []),
            culturalPreferences: CulturalPreferences(
                dateFormat: .yearMonthDay,
                weekStartsOn: .monday,
                workingDays: [],
                commonHolidays: [],
                timeFormat: .twentyFour,
                familyFinanceStyle: .individual,
                savingsPreference: .balanced,
                investmentRiskTolerance: .moderate
            )
        )
        
        XCTAssertEqual(minimalCountry.id, "XX")
        XCTAssertEqual(minimalCountry.commonInvestmentTypes.count, 0)
        XCTAssertEqual(minimalCountry.bankingFeatures.supportedAccountTypes.count, 0)
        XCTAssertFalse(minimalCountry.hasInstantPayments)
    }
    
    func testAllEnumCasesAreCovered() {
        // Ensure all enum cases have proper display names
        for region in GeographicRegion.allCases {
            XCTAssertFalse(region.displayName.isEmpty)
        }
        
        for zone in RegulatoryZone.allCases {
            XCTAssertFalse(zone.displayName.isEmpty)
        }
        
        for fyStart in FinancialYearStart.allCases {
            XCTAssertFalse(fyStart.displayName.isEmpty)
            XCTAssertTrue(fyStart.startMonth >= 1 && fyStart.startMonth <= 12)
        }
        
        for numberingSystem in NumberingSystem.allCases {
            XCTAssertFalse(numberingSystem.displayName.isEmpty)
            XCTAssertFalse(numberingSystem.thousandsSeparator.isEmpty)
            XCTAssertFalse(numberingSystem.decimalSeparator.isEmpty)
        }
        
        for taxSystem in TaxSystemType.allCases {
            XCTAssertFalse(taxSystem.displayName.isEmpty)
        }
        
        for investmentType in InvestmentType.allCases {
            XCTAssertFalse(investmentType.displayName.isEmpty)
        }
        
        for category in InvestmentCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
        }
        
        for accountType in BankAccountType.allCases {
            XCTAssertFalse(accountType.displayName.isEmpty)
        }
        
        for dateFormat in DateFormatStyle.allCases {
            XCTAssertFalse(dateFormat.displayName.isEmpty)
        }
        
        for weekday in Weekday.allCases {
            XCTAssertFalse(weekday.displayName.isEmpty)
        }
        
        for timeFormat in TimeFormat.allCases {
            XCTAssertFalse(timeFormat.displayName.isEmpty)
        }
        
        for financeStyle in FamilyFinanceStyle.allCases {
            XCTAssertFalse(financeStyle.displayName.isEmpty)
        }
        
        for savings in SavingsPreference.allCases {
            XCTAssertFalse(savings.displayName.isEmpty)
        }
        
        for risk in RiskTolerance.allCases {
            XCTAssertFalse(risk.displayName.isEmpty)
            XCTAssertTrue(risk.volatilityTolerance > 0 && risk.volatilityTolerance <= 1.0)
        }
    }
}