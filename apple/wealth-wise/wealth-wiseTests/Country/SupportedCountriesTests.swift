import XCTest
@testable import WealthWise

final class SupportedCountriesTests: XCTestCase {
    
    // MARK: - Predefined Countries Tests
    
    func testIndiaCountryConfiguration() {
        let india = SupportedCountries.india
        
        XCTAssertEqual(india.id, "IN")
        XCTAssertEqual(india.name, "India")
        XCTAssertEqual(india.flag, "🇮🇳")
        XCTAssertEqual(india.primaryCurrency, .inr)
        XCTAssertEqual(india.region, .asia)
        XCTAssertEqual(india.regulatoryZone, .dpia)
        XCTAssertEqual(india.financialYearStart, .april)
        XCTAssertEqual(india.numberingSystem, .indian)
        XCTAssertEqual(india.taxSystem, .progressive)
        XCTAssertEqual(india.retirementAge.standard, 60)
        
        // Check Indian-specific investment types
        XCTAssertTrue(india.commonInvestmentTypes.contains(.retirementPPF))
        XCTAssertTrue(india.commonInvestmentTypes.contains(.retirementEPF))
        XCTAssertTrue(india.commonInvestmentTypes.contains(.retirementELSS))
        XCTAssertTrue(india.commonInvestmentTypes.contains(.alternativeGold))
        
        // Check Indian banking features
        XCTAssertTrue(india.bankingFeatures.hasUPI)
        XCTAssertTrue(india.bankingFeatures.hasRTGS)
        XCTAssertTrue(india.bankingFeatures.hasNEFT)
        XCTAssertTrue(india.bankingFeatures.supportedAccountTypes.contains(.fixedDeposit))
        XCTAssertTrue(india.bankingFeatures.supportedAccountTypes.contains(.recurringDeposit))
        
        // Check cultural preferences
        XCTAssertEqual(india.culturalPreferences.dateFormat, .dayMonthYear)
        XCTAssertEqual(india.culturalPreferences.familyFinanceStyle, .joint)
        XCTAssertEqual(india.culturalPreferences.savingsPreference, .conservative)
        XCTAssertTrue(india.culturalPreferences.workingDays.contains(.saturday)) // India has 6-day work week
        XCTAssertTrue(india.culturalPreferences.commonHolidays.contains("Diwali"))
    }
    
    func testUnitedStatesCountryConfiguration() {
        let us = SupportedCountries.unitedStates
        
        XCTAssertEqual(us.id, "US")
        XCTAssertEqual(us.primaryCurrency, .usd)
        XCTAssertEqual(us.region, .northAmerica)
        XCTAssertEqual(us.regulatoryZone, .ccpa)
        XCTAssertEqual(us.financialYearStart, .january)
        XCTAssertEqual(us.numberingSystem, .western)
        XCTAssertEqual(us.retirementAge.standard, 67)
        
        // Check US-specific investment types
        XCTAssertTrue(us.commonInvestmentTypes.contains(.retirement401k))
        XCTAssertTrue(us.commonInvestmentTypes.contains(.retirementIRA))
        XCTAssertTrue(us.commonInvestmentTypes.contains(.retirementRoth))
        XCTAssertTrue(us.commonInvestmentTypes.contains(.alternativeCrypto))
        
        // Check US banking features
        XCTAssertTrue(us.bankingFeatures.hasACH)
        XCTAssertFalse(us.bankingFeatures.hasUPI) // US doesn't have UPI
        XCTAssertTrue(us.bankingFeatures.supportedAccountTypes.contains(.cd))
        XCTAssertTrue(us.bankingFeatures.supportedAccountTypes.contains(.moneyMarket))
        
        // Check cultural preferences
        XCTAssertEqual(us.culturalPreferences.dateFormat, .monthDayYear)
        XCTAssertEqual(us.culturalPreferences.weekStartsOn, .sunday)
        XCTAssertEqual(us.culturalPreferences.familyFinanceStyle, .individual)
        XCTAssertFalse(us.culturalPreferences.workingDays.contains(.saturday)) // 5-day work week
    }
    
    func testUnitedKingdomCountryConfiguration() {
        let uk = SupportedCountries.unitedKingdom
        
        XCTAssertEqual(uk.id, "GB")
        XCTAssertEqual(uk.primaryCurrency, .gbp)
        XCTAssertEqual(uk.region, .europe)
        XCTAssertEqual(uk.regulatoryZone, .gdpr)
        XCTAssertEqual(uk.financialYearStart, .april) // UK corporate/tax year
        XCTAssertEqual(uk.retirementAge.standard, 66)
        
        // Check UK banking features
        XCTAssertTrue(uk.bankingFeatures.hasOpenBanking)
        XCTAssertTrue(uk.bankingFeatures.supportedAccountTypes.contains(.currentAccount))
        
        // Check cultural preferences
        XCTAssertEqual(uk.culturalPreferences.dateFormat, .dayMonthYear)
        XCTAssertEqual(uk.culturalPreferences.timeFormat, .twentyFour)
        XCTAssertEqual(uk.culturalPreferences.savingsPreference, .conservative)
    }
    
    func testCanadaCountryConfiguration() {
        let canada = SupportedCountries.canada
        
        XCTAssertEqual(canada.id, "CA")
        XCTAssertEqual(canada.primaryCurrency, .cad)
        XCTAssertEqual(canada.regulatoryZone, .pipeda)
        XCTAssertTrue(canada.bankingFeatures.hasInterac)
        XCTAssertTrue(canada.culturalPreferences.commonHolidays.contains("Canada Day"))
    }
    
    func testAustraliaCountryConfiguration() {
        let australia = SupportedCountries.australia
        
        XCTAssertEqual(australia.id, "AU")
        XCTAssertEqual(australia.primaryCurrency, .aud)
        XCTAssertEqual(australia.financialYearStart, .july) // Australia's unique FY
        XCTAssertTrue(australia.commonInvestmentTypes.contains(.retirementSuperannuation))
    }
    
    func testGermanyCountryConfiguration() {
        let germany = SupportedCountries.germany
        
        XCTAssertEqual(germany.id, "DE")
        XCTAssertEqual(germany.primaryCurrency, .eur)
        XCTAssertEqual(germany.regulatoryZone, .gdpr)
        XCTAssertTrue(germany.bankingFeatures.hasSEPA)
        XCTAssertEqual(germany.culturalPreferences.timeFormat, .twentyFour)
    }
    
    func testJapanCountryConfiguration() {
        let japan = SupportedCountries.japan
        
        XCTAssertEqual(japan.id, "JP")
        XCTAssertEqual(japan.primaryCurrency, .jpy)
        XCTAssertEqual(japan.regulatoryZone, .appi)
        XCTAssertEqual(japan.financialYearStart, .april)
        XCTAssertEqual(japan.culturalPreferences.familyFinanceStyle, .joint)
        XCTAssertTrue(japan.culturalPreferences.workingDays.contains(.saturday)) // Japan often has Saturday work
    }
    
    func testSingaporeCountryConfiguration() {
        let singapore = SupportedCountries.singapore
        
        XCTAssertEqual(singapore.id, "SG")
        XCTAssertEqual(singapore.primaryCurrency, .sgd)
        XCTAssertEqual(singapore.regulatoryZone, .pdpa)
        XCTAssertTrue(singapore.culturalPreferences.commonHolidays.contains("Chinese New Year"))
        XCTAssertTrue(singapore.culturalPreferences.commonHolidays.contains("Deepavali"))
    }
    
    // MARK: - Helper Methods Tests
    
    func testAllCountries() {
        let allCountries = SupportedCountries.allCountries
        
        XCTAssertGreaterThanOrEqual(allCountries.count, 8) // At least 8 countries
        
        // Check that all major countries are included
        let countryIds = allCountries.map { $0.id }
        XCTAssertTrue(countryIds.contains("IN"))
        XCTAssertTrue(countryIds.contains("US"))
        XCTAssertTrue(countryIds.contains("GB"))
        XCTAssertTrue(countryIds.contains("CA"))
        XCTAssertTrue(countryIds.contains("AU"))
        XCTAssertTrue(countryIds.contains("DE"))
        XCTAssertTrue(countryIds.contains("JP"))
        XCTAssertTrue(countryIds.contains("SG"))
        
        // Ensure no duplicate IDs
        let uniqueIds = Set(countryIds)
        XCTAssertEqual(countryIds.count, uniqueIds.count)
    }
    
    func testCountryById() {
        XCTAssertEqual(SupportedCountries.country(by: "IN")?.name, "India")
        XCTAssertEqual(SupportedCountries.country(by: "US")?.name, "United States")
        XCTAssertEqual(SupportedCountries.country(by: "in")?.name, "India") // Case insensitive
        XCTAssertNil(SupportedCountries.country(by: "XX")) // Non-existent country
    }
    
    func testCountryByCurrency() {
        XCTAssertEqual(SupportedCountries.country(by: .inr)?.name, "India")
        XCTAssertEqual(SupportedCountries.country(by: .usd)?.name, "United States")
        XCTAssertEqual(SupportedCountries.country(by: .gbp)?.name, "United Kingdom")
        XCTAssertEqual(SupportedCountries.country(by: .jpy)?.name, "Japan")
    }
    
    func testCountriesInRegion() {
        let asianCountries = SupportedCountries.countries(in: .asia)
        let europeanCountries = SupportedCountries.countries(in: .europe)
        let northAmericanCountries = SupportedCountries.countries(in: .northAmerica)
        
        XCTAssertTrue(asianCountries.contains { $0.id == "IN" })
        XCTAssertTrue(asianCountries.contains { $0.id == "JP" })
        XCTAssertTrue(asianCountries.contains { $0.id == "SG" })
        
        XCTAssertTrue(europeanCountries.contains { $0.id == "GB" })
        XCTAssertTrue(europeanCountries.contains { $0.id == "DE" })
        
        XCTAssertTrue(northAmericanCountries.contains { $0.id == "US" })
        XCTAssertTrue(northAmericanCountries.contains { $0.id == "CA" })
    }
    
    func testCountriesWithRegulatoryZone() {
        let gdprCountries = SupportedCountries.countries(with: .gdpr)
        let dpiaCountries = SupportedCountries.countries(with: .dpia)
        let ccpaCountries = SupportedCountries.countries(with: .ccpa)
        
        XCTAssertTrue(gdprCountries.contains { $0.id == "GB" })
        XCTAssertTrue(gdprCountries.contains { $0.id == "DE" })
        
        XCTAssertTrue(dpiaCountries.contains { $0.id == "IN" })
        
        XCTAssertTrue(ccpaCountries.contains { $0.id == "US" })
    }
    
    func testPreferredCountryForLocale() {
        let indianLocale = Locale(identifier: "en_IN")
        let usLocale = Locale(identifier: "en_US")
        let ukLocale = Locale(identifier: "en_GB")
        let canadianLocale = Locale(identifier: "en_CA")
        let australianLocale = Locale(identifier: "en_AU")
        let germanLocale = Locale(identifier: "de_DE")
        let japaneseLocale = Locale(identifier: "ja_JP")
        let singaporeLocale = Locale(identifier: "en_SG")
        let unknownLocale = Locale(identifier: "xx_XX")
        
        XCTAssertEqual(SupportedCountries.preferredCountry(for: indianLocale).id, "IN")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: usLocale).id, "US")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: ukLocale).id, "GB")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: canadianLocale).id, "CA")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: australianLocale).id, "AU")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: germanLocale).id, "DE")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: japaneseLocale).id, "JP")
        XCTAssertEqual(SupportedCountries.preferredCountry(for: singaporeLocale).id, "SG")
        
        // Unknown locale should default to India (primary target market)
        XCTAssertEqual(SupportedCountries.preferredCountry(for: unknownLocale).id, "IN")
    }
    
    // MARK: - Country Extension Tests
    
    func testCountrySupportsInvestmentType() {
        let india = SupportedCountries.india
        let us = SupportedCountries.unitedStates
        
        // India-specific investments
        XCTAssertTrue(india.supports(investmentType: .retirementPPF))
        XCTAssertFalse(us.supports(investmentType: .retirementPPF))
        
        // US-specific investments
        XCTAssertTrue(us.supports(investmentType: .retirement401k))
        XCTAssertFalse(india.supports(investmentType: .retirement401k))
        
        // Common investments
        XCTAssertTrue(india.supports(investmentType: .stocksLocal))
        XCTAssertTrue(us.supports(investmentType: .stocksLocal))
    }
    
    func testCountrySupportsAccountType() {
        let india = SupportedCountries.india
        let us = SupportedCountries.unitedStates
        
        // India-specific account types
        XCTAssertTrue(india.supports(accountType: .fixedDeposit))
        XCTAssertFalse(us.supports(accountType: .fixedDeposit))
        
        // US-specific account types
        XCTAssertTrue(us.supports(accountType: .cd))
        XCTAssertFalse(india.supports(accountType: .cd))
        
        // Common account types
        XCTAssertTrue(india.supports(accountType: .savings))
        XCTAssertTrue(us.supports(accountType: .savings))
    }
    
    func testCountryHasInstantPayments() {
        let india = SupportedCountries.india
        let us = SupportedCountries.unitedStates
        let canada = SupportedCountries.canada
        let uk = SupportedCountries.unitedKingdom
        
        // Countries with instant payment systems
        XCTAssertTrue(india.hasInstantPayments) // UPI
        XCTAssertTrue(us.hasInstantPayments) // Instant transfers
        XCTAssertTrue(canada.hasInstantPayments) // Interac
        XCTAssertTrue(uk.hasInstantPayments) // Instant transfers
    }
    
    func testCountryCurrentFinancialYear() {
        let india = SupportedCountries.india // April start
        let us = SupportedCountries.unitedStates // January start
        let australia = SupportedCountries.australia // July start
        
        // Test with known dates
        let march2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15))!
        let april2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 15))!
        let july2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15))!
        
        // India (April start)
        XCTAssertEqual(india.currentFinancialYear(date: march2024), 2023)
        XCTAssertEqual(india.currentFinancialYear(date: april2024), 2024)
        
        // US (January start)
        XCTAssertEqual(us.currentFinancialYear(date: march2024), 2024)
        XCTAssertEqual(us.currentFinancialYear(date: april2024), 2024)
        
        // Australia (July start)
        XCTAssertEqual(australia.currentFinancialYear(date: april2024), 2023)
        XCTAssertEqual(australia.currentFinancialYear(date: july2024), 2024)
    }
    
    func testCountryRecommendedInvestments() {
        let india = SupportedCountries.india
        
        let veryLowRisk = india.recommendedInvestments(for: .veryLow)
        let moderateRisk = india.recommendedInvestments(for: .moderate)
        let highRisk = india.recommendedInvestments(for: .high)
        
        // Very low risk should be minimal and safe
        XCTAssertTrue(veryLowRisk.contains(.cashSavings))
        XCTAssertTrue(veryLowRisk.contains(.bondsGovernment))
        XCTAssertFalse(veryLowRisk.contains(.stocksLocal))
        
        // Moderate risk should exclude only highest risk investments
        XCTAssertTrue(moderateRisk.contains(.stocksLocal))
        XCTAssertTrue(moderateRisk.contains(.retirementPPF))
        
        // High risk should include all available investments
        XCTAssertTrue(highRisk.count >= moderateRisk.count)
        XCTAssertTrue(highRisk.contains(.alternativeGold))
    }
    
    func testCountryAccessibilityLabel() {
        let india = SupportedCountries.india
        let us = SupportedCountries.unitedStates
        
        let indiaLabel = india.accessibilityLabel
        let usLabel = us.accessibilityLabel
        
        XCTAssertTrue(indiaLabel.contains("India"))
        XCTAssertTrue(indiaLabel.contains("Indian Rupee"))
        XCTAssertTrue(indiaLabel.contains("Asia"))
        
        XCTAssertTrue(usLabel.contains("United States"))
        XCTAssertTrue(usLabel.contains("US Dollar"))
        XCTAssertTrue(usLabel.contains("North America"))
    }
    
    // MARK: - Performance Tests
    
    func testCountryLookupPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = SupportedCountries.country(by: "IN")
                _ = SupportedCountries.country(by: "US")
                _ = SupportedCountries.country(by: "GB")
            }
        }
    }
    
    func testRegionalFilteringPerformance() {
        measure {
            for _ in 0..<100 {
                _ = SupportedCountries.countries(in: .asia)
                _ = SupportedCountries.countries(in: .europe)
                _ = SupportedCountries.countries(in: .northAmerica)
            }
        }
    }
    
    func testPreferredCountryDetectionPerformance() {
        let locales = [
            Locale(identifier: "en_IN"),
            Locale(identifier: "en_US"),
            Locale(identifier: "en_GB"),
            Locale(identifier: "en_CA"),
            Locale(identifier: "en_AU")
        ]
        
        measure {
            for _ in 0..<100 {
                for locale in locales {
                    _ = SupportedCountries.preferredCountry(for: locale)
                }
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testAllCountriesHaveValidData() {
        for country in SupportedCountries.allCountries {
            // All countries should have valid basic properties
            XCTAssertFalse(country.id.isEmpty, "Country \(country.name) has empty ID")
            XCTAssertFalse(country.name.isEmpty, "Country \(country.id) has empty name")
            XCTAssertFalse(country.displayName.isEmpty, "Country \(country.id) has empty display name")
            XCTAssertFalse(country.flag.isEmpty, "Country \(country.id) has empty flag")
            
            // All countries should have at least one supported account type
            XCTAssertFalse(country.bankingFeatures.supportedAccountTypes.isEmpty, 
                          "Country \(country.id) has no supported account types")
            
            // All countries should have working days
            XCTAssertFalse(country.culturalPreferences.workingDays.isEmpty,
                          "Country \(country.id) has no working days")
            
            // Retirement age should be reasonable
            XCTAssertTrue(country.retirementAge.standard >= 50 && country.retirementAge.standard <= 75,
                         "Country \(country.id) has unreasonable retirement age: \(country.retirementAge.standard)")
            
            // Financial year start month should be valid
            let startMonth = country.financialYearStart.startMonth
            XCTAssertTrue(startMonth >= 1 && startMonth <= 12,
                         "Country \(country.id) has invalid FY start month: \(startMonth)")
        }
    }
    
    func testCountryUniqueness() {
        let allCountries = SupportedCountries.allCountries
        let ids = allCountries.map { $0.id }
        let names = allCountries.map { $0.name }
        let currencies = allCountries.map { $0.primaryCurrency }
        
        // IDs should be unique
        XCTAssertEqual(ids.count, Set(ids).count, "Country IDs are not unique")
        
        // Names should be unique
        XCTAssertEqual(names.count, Set(names).count, "Country names are not unique")
        
        // Primary currencies should mostly be unique (some may share EUR)
        let uniqueCurrencies = Set(currencies)
        XCTAssertGreaterThanOrEqual(uniqueCurrencies.count, allCountries.count - 2, 
                                   "Too many countries share primary currencies")
    }
    
    func testInvestmentTypeDistribution() {
        let allCountries = SupportedCountries.allCountries
        
        // All countries should support at least some basic investment types
        for country in allCountries {
            XCTAssertGreaterThanOrEqual(country.commonInvestmentTypes.count, 3,
                                       "Country \(country.id) supports too few investment types")
            
            // All countries should support local stocks and savings
            XCTAssertTrue(country.supports(investmentType: .stocksLocal) || 
                         country.supports(investmentType: .cashSavings),
                         "Country \(country.id) doesn't support basic investments")
        }
        
        // Ensure regional specializations exist
        let india = SupportedCountries.india
        let us = SupportedCountries.unitedStates
        let australia = SupportedCountries.australia
        
        // India should have PPF, EPF, etc.
        XCTAssertTrue(india.supports(investmentType: .retirementPPF))
        XCTAssertTrue(india.supports(investmentType: .retirementEPF))
        
        // US should have 401k, IRA, etc.
        XCTAssertTrue(us.supports(investmentType: .retirement401k))
        XCTAssertTrue(us.supports(investmentType: .retirementIRA))
        
        // Australia should have Superannuation
        XCTAssertTrue(australia.supports(investmentType: .retirementSuperannuation))
    }
}