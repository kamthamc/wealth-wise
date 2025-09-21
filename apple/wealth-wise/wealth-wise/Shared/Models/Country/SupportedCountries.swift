import Foundation

/// Predefined country configurations for major markets
public struct SupportedCountries {
    
    // MARK: - Primary Market (India)
    
    public static let india = Country(
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
        commonInvestmentTypes: [
            .retirementPPF, .retirementEPF, .retirementELSS, .retirementNSC,
            .stocksLocal, .stocksMutualFunds, .stocksETF,
            .bondsGovernment, .bondsFixed,
            .realEstateREIT, .realEstateDirect,
            .alternativeGold,
            .cashSavings
        ],
        bankingFeatures: BankingFeatures(
            hasUPI: true,
            hasInstantTransfers: true,
            hasWireTransfers: true,
            hasRTGS: true,
            hasNEFT: true,
            supportedAccountTypes: [.savings, .checking, .currentAccount, .fixedDeposit, .recurringDeposit, .joint]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .monday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday],
            commonHolidays: ["Diwali", "Holi", "Eid", "Dussehra", "Gandhi Jayanti", "Independence Day", "Republic Day"],
            timeFormat: .twelve,
            familyFinanceStyle: .joint,
            savingsPreference: .conservative,
            investmentRiskTolerance: .moderate
        )
    )
    
    // MARK: - Major Markets
    
    public static let unitedStates = Country(
        id: "US",
        name: "United States",
        displayName: "United States",
        flag: "🇺🇸",
        primaryCurrency: .usd,
        secondaryCurrencies: [],
        region: .northAmerica,
        regulatoryZone: .ccpa,
        financialYearStart: .january,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 67, early: 62, maximum: 70, pensionEligibility: 62),
        commonInvestmentTypes: [
            .retirement401k, .retirementIRA, .retirementRoth,
            .stocksLocal, .stocksInternational, .stocksETF, .stocksMutualFunds, .stocksIndexFunds,
            .bondsGovernment, .bondsCorporate,
            .realEstateREIT, .realEstateDirect,
            .alternativeCrypto, .alternativeCommodities,
            .cashSavings, .cashCD, .cashMoneyMarket
        ],
        bankingFeatures: BankingFeatures(
            hasInstantTransfers: true,
            hasWireTransfers: true,
            hasACH: true,
            supportedAccountTypes: [.checking, .savings, .moneyMarket, .cd, .business, .joint, .trust]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .monthDayYear,
            weekStartsOn: .sunday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["New Year's Day", "Independence Day", "Thanksgiving", "Christmas", "Labor Day", "Memorial Day"],
            timeFormat: .twelve,
            familyFinanceStyle: .individual,
            savingsPreference: .balanced,
            investmentRiskTolerance: .moderate
        )
    )
    
    public static let unitedKingdom = Country(
        id: "GB",
        name: "United Kingdom",
        displayName: "United Kingdom",
        flag: "🇬🇧",
        primaryCurrency: .gbp,
        secondaryCurrencies: [.eur, .usd],
        region: .europe,
        regulatoryZone: .gdpr,
        financialYearStart: .april,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 66, early: 55, maximum: 75, pensionEligibility: 66),
        commonInvestmentTypes: [
            .stocksLocal, .stocksInternational, .stocksETF, .stocksMutualFunds,
            .bondsGovernment, .bondsCorporate,
            .realEstateREIT, .realEstateDirect,
            .alternativeGold,
            .cashSavings
        ],
        bankingFeatures: BankingFeatures(
            hasOpenBanking: true,
            hasInstantTransfers: true,
            hasWireTransfers: true,
            supportedAccountTypes: [.checking, .savings, .business, .joint, .currentAccount]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .monday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["Christmas", "New Year's Day", "Easter", "Bank Holidays", "Queen's Birthday"],
            timeFormat: .twentyFour,
            familyFinanceStyle: .individual,
            savingsPreference: .conservative,
            investmentRiskTolerance: .low
        )
    )
    
    public static let canada = Country(
        id: "CA",
        name: "Canada",
        displayName: "Canada",
        flag: "🇨🇦",
        primaryCurrency: .cad,
        secondaryCurrencies: [.usd],
        region: .northAmerica,
        regulatoryZone: .pipeda,
        financialYearStart: .january,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 65, early: 60, maximum: 70, pensionEligibility: 65),
        commonInvestmentTypes: [
            .stocksLocal, .stocksInternational, .stocksETF, .stocksMutualFunds,
            .bondsGovernment, .bondsCorporate,
            .realEstateREIT, .realEstateDirect,
            .cashSavings, .cashCD
        ],
        bankingFeatures: BankingFeatures(
            hasInstantTransfers: true,
            hasWireTransfers: true,
            hasInterac: true,
            supportedAccountTypes: [.checking, .savings, .business, .joint]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .sunday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["New Year's Day", "Canada Day", "Christmas", "Victoria Day", "Labour Day"],
            timeFormat: .twelve,
            familyFinanceStyle: .individual,
            savingsPreference: .balanced,
            investmentRiskTolerance: .moderate
        )
    )
    
    public static let australia = Country(
        id: "AU",
        name: "Australia",
        displayName: "Australia",
        flag: "🇦🇺",
        primaryCurrency: .aud,
        secondaryCurrencies: [.usd],
        region: .oceania,
        regulatoryZone: .other,
        financialYearStart: .july,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 67, early: 60, maximum: 75, pensionEligibility: 67),
        commonInvestmentTypes: [
            .retirementSuperannuation,
            .stocksLocal, .stocksInternational, .stocksETF,
            .bondsGovernment, .bondsCorporate,
            .realEstateREIT, .realEstateDirect,
            .cashSavings
        ],
        bankingFeatures: BankingFeatures(
            hasInstantTransfers: true,
            hasWireTransfers: true,
            supportedAccountTypes: [.checking, .savings, .business, .joint]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .monday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["Australia Day", "ANZAC Day", "Christmas", "New Year's Day", "Queen's Birthday"],
            timeFormat: .twentyFour,
            familyFinanceStyle: .individual,
            savingsPreference: .balanced,
            investmentRiskTolerance: .moderate
        )
    )
    
    public static let germany = Country(
        id: "DE",
        name: "Germany",
        displayName: "Germany",
        flag: "🇩🇪",
        primaryCurrency: .eur,
        secondaryCurrencies: [.usd],
        region: .europe,
        regulatoryZone: .gdpr,
        financialYearStart: .january,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 67, early: 63, maximum: 70, pensionEligibility: 67),
        commonInvestmentTypes: [
            .stocksLocal, .stocksInternational, .stocksETF,
            .bondsGovernment, .bondsCorporate,
            .realEstateREIT, .realEstateDirect,
            .cashSavings
        ],
        bankingFeatures: BankingFeatures(
            hasOpenBanking: true,
            hasInstantTransfers: true,
            hasWireTransfers: true,
            hasSEPA: true,
            supportedAccountTypes: [.checking, .savings, .business, .joint]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .monday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["Christmas", "New Year's Day", "Easter", "German Unity Day", "Labour Day"],
            timeFormat: .twentyFour,
            familyFinanceStyle: .individual,
            savingsPreference: .conservative,
            investmentRiskTolerance: .low
        )
    )
    
    public static let japan = Country(
        id: "JP",
        name: "Japan",
        displayName: "Japan",
        flag: "🇯🇵",
        primaryCurrency: .jpy,
        secondaryCurrencies: [.usd],
        region: .asia,
        regulatoryZone: .appi,
        financialYearStart: .april,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 65, early: 60, maximum: 70, pensionEligibility: 65),
        commonInvestmentTypes: [
            .stocksLocal, .stocksInternational,
            .bondsGovernment,
            .realEstateDirect,
            .cashSavings
        ],
        bankingFeatures: BankingFeatures(
            hasInstantTransfers: true,
            hasWireTransfers: true,
            supportedAccountTypes: [.savings, .checking, .business]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .yearMonthDay,
            weekStartsOn: .sunday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday],
            commonHolidays: ["New Year's Day", "Golden Week", "Obon", "Emperor's Birthday", "Children's Day"],
            timeFormat: .twentyFour,
            familyFinanceStyle: .joint,
            savingsPreference: .conservative,
            investmentRiskTolerance: .low
        )
    )
    
    public static let singapore = Country(
        id: "SG",
        name: "Singapore",
        displayName: "Singapore",
        flag: "🇸🇬",
        primaryCurrency: .sgd,
        secondaryCurrencies: [.usd, .eur],
        region: .asia,
        regulatoryZone: .pdpa,
        financialYearStart: .january,
        numberingSystem: .western,
        taxSystem: .progressive,
        retirementAge: RetirementAge(standard: 65, early: 62, maximum: 70, pensionEligibility: 65),
        commonInvestmentTypes: [
            .stocksLocal, .stocksInternational, .stocksETF,
            .bondsGovernment, .bondsCorporate,
            .realEstateREIT, .realEstateDirect,
            .cashSavings
        ],
        bankingFeatures: BankingFeatures(
            hasInstantTransfers: true,
            hasWireTransfers: true,
            supportedAccountTypes: [.savings, .checking, .business, .joint]
        ),
        culturalPreferences: CulturalPreferences(
            dateFormat: .dayMonthYear,
            weekStartsOn: .monday,
            workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            commonHolidays: ["Chinese New Year", "Deepavali", "Hari Raya", "Christmas", "National Day"],
            timeFormat: .twentyFour,
            familyFinanceStyle: .joint,
            savingsPreference: .balanced,
            investmentRiskTolerance: .moderate
        )
    )
    
    // MARK: - All Supported Countries
    
    public static let allCountries: [Country] = [
        india,
        unitedStates,
        unitedKingdom,
        canada,
        australia,
        germany,
        japan,
        singapore
    ]
    
    // MARK: - Helper Methods
    
    public static func country(by id: String) -> Country? {
        return allCountries.first { $0.id.lowercased() == id.lowercased() }
    }
    
    public static func country(by currency: SupportedCurrency) -> Country? {
        return allCountries.first { $0.primaryCurrency == currency }
    }
    
    public static func countries(in region: GeographicRegion) -> [Country] {
        return allCountries.filter { $0.region == region }
    }
    
    public static func countries(with regulatoryZone: RegulatoryZone) -> [Country] {
        return allCountries.filter { $0.regulatoryZone == regulatoryZone }
    }
    
    public static func preferredCountry(for locale: Locale) -> Country {
        // Try to match by region code first
        if let regionCode = locale.regionCode,
           let country = country(by: regionCode) {
            return country
        }
        
        // Try to match by language/region combination
        let localeIdentifier = locale.identifier.lowercased()
        
        if localeIdentifier.contains("in") && localeIdentifier.contains("en") {
            return india
        } else if localeIdentifier.contains("us") {
            return unitedStates
        } else if localeIdentifier.contains("gb") || localeIdentifier.contains("uk") {
            return unitedKingdom
        } else if localeIdentifier.contains("ca") {
            return canada
        } else if localeIdentifier.contains("au") {
            return australia
        } else if localeIdentifier.contains("de") {
            return germany
        } else if localeIdentifier.contains("jp") {
            return japan
        } else if localeIdentifier.contains("sg") {
            return singapore
        }
        
        // Default to India (primary target market)
        return india
    }
}

// MARK: - Country Extension

extension Country {
    /// Returns whether this country supports a specific investment type
    public func supports(investmentType: InvestmentType) -> Bool {
        return commonInvestmentTypes.contains(investmentType)
    }
    
    /// Returns whether this country supports a specific bank account type
    public func supports(accountType: BankAccountType) -> Bool {
        return bankingFeatures.supportedAccountTypes.contains(accountType)
    }
    
    /// Returns whether this country has instant payment systems
    public var hasInstantPayments: Bool {
        return bankingFeatures.hasUPI || 
               bankingFeatures.hasInstantTransfers || 
               bankingFeatures.hasInterac
    }
    
    /// Returns the current financial year for this country
    public func currentFinancialYear(date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let year = components.year,
              let month = components.month else {
            return calendar.component(.year, from: date)
        }
        
        if month >= financialYearStart.startMonth {
            return year
        } else {
            return year - 1
        }
    }
    
    /// Returns the investment types suitable for a given risk tolerance
    public func recommendedInvestments(for riskTolerance: RiskTolerance) -> [InvestmentType] {
        let allRecommended = commonInvestmentTypes.filter { investmentType in
            switch riskTolerance {
            case .veryLow:
                return [.cashSavings, .bondsGovernment, .bondsFixed].contains(investmentType)
            case .low:
                return [.cashSavings, .bondsGovernment, .bondsFixed, .bondsCorporate, .realEstateREIT].contains(investmentType)
            case .moderate:
                return ![.alternativeCrypto, .alternativeP2P].contains(investmentType)
            case .high:
                return true // All investment types
            case .veryHigh:
                return true // All investment types
            }
        }
        
        return Array(Set(allRecommended)) // Remove duplicates
    }
    
    /// Returns accessibility label for screen readers
    public var accessibilityLabel: String {
        return "\(displayName), primary currency \(primaryCurrency.displayName), located in \(region.displayName)"
    }
}