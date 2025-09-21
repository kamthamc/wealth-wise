import Foundation

/// Regional mappings and localizations for different markets
/// Provides comprehensive geographic and cultural data integration
public struct RegionalMappings {
    
    // MARK: - Static Properties
    
    /// Predefined country information
    public static let supportedCountries: [String: CountryInfo] = [
        "IND": CountryInfo(code: "IND", displayName: "India", flagEmoji: "🇮🇳", currencyCode: "INR", timeZone: "Asia/Kolkata", languages: ["hi", "en"], isRTL: false, financialYearStartMonth: 4),
        "USA": CountryInfo(code: "USA", displayName: "United States", flagEmoji: "🇺🇸", currencyCode: "USD", timeZone: "America/New_York", languages: ["en"], isRTL: false, financialYearStartMonth: 1),
        "GBR": CountryInfo(code: "GBR", displayName: "United Kingdom", flagEmoji: "🇬🇧", currencyCode: "GBP", timeZone: "Europe/London", languages: ["en"], isRTL: false, financialYearStartMonth: 4),
        "CAN": CountryInfo(code: "CAN", displayName: "Canada", flagEmoji: "🇨🇦", currencyCode: "CAD", timeZone: "America/Toronto", languages: ["en", "fr"], isRTL: false, financialYearStartMonth: 1),
        "AUS": CountryInfo(code: "AUS", displayName: "Australia", flagEmoji: "🇦🇺", currencyCode: "AUD", timeZone: "Australia/Sydney", languages: ["en"], isRTL: false, financialYearStartMonth: 7),
        "SGP": CountryInfo(code: "SGP", displayName: "Singapore", flagEmoji: "🇸🇬", currencyCode: "SGD", timeZone: "Asia/Singapore", languages: ["en", "zh", "ms", "ta"], isRTL: false, financialYearStartMonth: 1),
        "DEU": CountryInfo(code: "DEU", displayName: "Germany", flagEmoji: "🇩🇪", currencyCode: "EUR", timeZone: "Europe/Berlin", languages: ["de"], isRTL: false, financialYearStartMonth: 1),
        "FRA": CountryInfo(code: "FRA", displayName: "France", flagEmoji: "🇫🇷", currencyCode: "EUR", timeZone: "Europe/Paris", languages: ["fr"], isRTL: false, financialYearStartMonth: 1),
        "JPN": CountryInfo(code: "JPN", displayName: "Japan", flagEmoji: "🇯🇵", currencyCode: "JPY", timeZone: "Asia/Tokyo", languages: ["ja"], isRTL: false, financialYearStartMonth: 4),
        "CHE": CountryInfo(code: "CHE", displayName: "Switzerland", flagEmoji: "🇨🇭", currencyCode: "CHF", timeZone: "Europe/Zurich", languages: ["de", "fr", "it"], isRTL: false, financialYearStartMonth: 1)
    ]
    
    /// Predefined audience information
    public static let supportedAudiences: [String: AudienceInfo] = [
        "indian": AudienceInfo(identifier: "indian", displayName: "Indian", countryCodes: ["IND"], numberFormatStyle: "indian", dateFormatStyle: "ddMMYYYY", languages: ["hi", "en"], isRTL: false, financialYearStartMonth: 4),
        "american": AudienceInfo(identifier: "american", displayName: "American", countryCodes: ["USA"], numberFormatStyle: "western", dateFormatStyle: "mmDDYYYY", languages: ["en"], isRTL: false, financialYearStartMonth: 1),
        "british": AudienceInfo(identifier: "british", displayName: "British", countryCodes: ["GBR"], numberFormatStyle: "british", dateFormatStyle: "ddMMYYYY", languages: ["en"], isRTL: false, financialYearStartMonth: 4),
        "canadian": AudienceInfo(identifier: "canadian", displayName: "Canadian", countryCodes: ["CAN"], numberFormatStyle: "western", dateFormatStyle: "mixed", languages: ["en", "fr"], isRTL: false, financialYearStartMonth: 1),
        "australian": AudienceInfo(identifier: "australian", displayName: "Australian", countryCodes: ["AUS"], numberFormatStyle: "western", dateFormatStyle: "ddMMYYYY", languages: ["en"], isRTL: false, financialYearStartMonth: 7),
        "singaporean": AudienceInfo(identifier: "singaporean", displayName: "Singaporean", countryCodes: ["SGP"], numberFormatStyle: "western", dateFormatStyle: "ddMMYYYY", languages: ["en", "zh"], isRTL: false, financialYearStartMonth: 1),
        "german": AudienceInfo(identifier: "german", displayName: "German", countryCodes: ["DEU"], numberFormatStyle: "european", dateFormatStyle: "ddMMYYYY", languages: ["de"], isRTL: false, financialYearStartMonth: 1),
        "japanese": AudienceInfo(identifier: "japanese", displayName: "Japanese", countryCodes: ["JPN"], numberFormatStyle: "japanese", dateFormatStyle: "yyyyMMDD", languages: ["ja"], isRTL: false, financialYearStartMonth: 4)
    ]
    
    // MARK: - Lookup Methods
    
    /// Get country information by country code
    public static func countryInfo(for countryCode: String) -> CountryInfo? {
        return supportedCountries[countryCode.uppercased()]
    }
    
    /// Get audience information by audience identifier
    public static func audienceInfo(for audienceId: String) -> AudienceInfo? {
        return supportedAudiences[audienceId.lowercased()]
    }
    

    
    /// Get all countries for a specific audience
    public static func countries(for audienceId: String) -> [CountryInfo] {
        guard let audienceInfo = audienceInfo(for: audienceId) else { return [] }
        
        return audienceInfo.countryCodes.compactMap { countryCode in
            countryInfo(for: countryCode)
        }
    }
    
    /// Get primary audience for a country
    public static func primaryAudience(for countryCode: String) -> AudienceInfo? {
        return supportedAudiences.values.first { audienceInfo in
            audienceInfo.countryCodes.contains(countryCode.uppercased())
        }
    }
    
    /// Get audiences that include a specific country
    public static func audiences(for countryCode: String) -> [AudienceInfo] {
        return supportedAudiences.values.filter { audienceInfo in
            audienceInfo.countryCodes.contains(countryCode.uppercased())
        }
    }
    
    // MARK: - Regional Groupings
    
    /// Countries in the European Union
    public static var europeanUnionCountries: [CountryInfo] {
        let euCountryCodes = ["DEU", "FRA", "NLD", "IRL", "LUX"]
        return euCountryCodes.compactMap { countryInfo(for: $0) }
    }
    
    /// English-speaking countries
    public static var englishSpeakingCountries: [CountryInfo] {
        return supportedCountries.values.filter { country in
            country.languages.contains("en")
        }
    }
    
    /// Countries with Indian expat communities
    public static var indianExpatCountries: [CountryInfo] {
        let expatCountryCodes = ["USA", "GBR", "CAN", "AUS", "SGP", "ARE", "DEU", "NLD"]
        return expatCountryCodes.compactMap { countryInfo(for: $0) }
    }
    
    /// Asian countries and territories
    public static var asianCountries: [CountryInfo] {
        let asianCountryCodes = ["IND", "SGP", "JPN", "HKG", "MYS", "THA", "PHL", "ARE", "QAT", "SAU"]
        return asianCountryCodes.compactMap { countryInfo(for: $0) }
    }
    
    /// Western countries (Americas, Europe, Oceania)
    public static var westernCountries: [CountryInfo] {
        let westernCountryCodes = ["USA", "CAN", "GBR", "AUS", "NZL", "DEU", "FRA", "NLD", "CHE", "IRL", "LUX"]
        return westernCountryCodes.compactMap { countryInfo(for: $0) }
    }
    
    // MARK: - Utility Methods
    
    /// Get default accent color for an audience
    private static func defaultAccentColor(for audienceId: String) -> String {
        switch audienceId.lowercased() {
        case "indian": return "orange"
        case "american": return "blue"
        case "british": return "blue"
        case "canadian": return "red"
        case "irish": return "green"
        default: return "system"
        }
    }
    
    /// Check if a country uses a specific currency
    public static func countriesUsing(currencyCode: String) -> [CountryInfo] {
        return supportedCountries.values.filter { country in
            country.currencyCode == currencyCode.uppercased()
        }
    }
    
    /// Get countries in a specific time zone
    public static func countriesIn(timeZone: String) -> [CountryInfo] {
        return supportedCountries.values.filter { country in
            country.timeZone == timeZone
        }
    }
    
    /// Get countries with a specific financial year start
    public static func countriesWithFinancialYear(startingIn month: Int) -> [CountryInfo] {
        return supportedCountries.values.filter { country in
            country.financialYearStartMonth == month
        }
    }
}

// MARK: - Supporting Data Types

/// Consolidated country information
public struct CountryInfo: Codable, Hashable {
    public let code: String
    public let displayName: String
    public let flagEmoji: String
    public let currencyCode: String
    public let timeZone: String
    public let languages: [String]
    public let isRTL: Bool
    public let financialYearStartMonth: Int
    
    public init(
        code: String,
        displayName: String,
        flagEmoji: String,
        currencyCode: String,
        timeZone: String,
        languages: [String],
        isRTL: Bool,
        financialYearStartMonth: Int
    ) {
        self.code = code
        self.displayName = displayName
        self.flagEmoji = flagEmoji
        self.currencyCode = currencyCode
        self.timeZone = timeZone
        self.languages = languages
        self.isRTL = isRTL
        self.financialYearStartMonth = financialYearStartMonth
    }
}

/// Consolidated audience information
public struct AudienceInfo: Codable, Hashable {
    public let identifier: String
    public let displayName: String
    public let countryCodes: [String]
    public let numberFormatStyle: String
    public let dateFormatStyle: String
    public let languages: [String]
    public let isRTL: Bool
    public let financialYearStartMonth: Int
    
    public init(
        identifier: String,
        displayName: String,
        countryCodes: [String],
        numberFormatStyle: String,
        dateFormatStyle: String,
        languages: [String],
        isRTL: Bool,
        financialYearStartMonth: Int
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.countryCodes = countryCodes
        self.numberFormatStyle = numberFormatStyle
        self.dateFormatStyle = dateFormatStyle
        self.languages = languages
        self.isRTL = isRTL
        self.financialYearStartMonth = financialYearStartMonth
    }
}

// MARK: - Extensions

extension RegionalMappings {
    
    /// Get localized display name for a country in the user's preferred language
    public static func localizedCountryName(_ countryCode: String, for locale: Locale = .current) -> String? {
        guard let countryInfo = countryInfo(for: countryCode) else { return nil }
        
        // Try to get localized name from system
        if let localizedName = locale.localizedString(forRegionCode: countryCode.uppercased()) {
            return localizedName
        }
        
        // Fallback to our display name
        return countryInfo.displayName
    }
    
    /// Get formatted currency display for a country
    public static func formattedCurrency(for countryCode: String, amount: Double = 1000) -> String? {
        guard let countryInfo = countryInfo(for: countryCode) else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = countryInfo.currencyCode
        
        return formatter.string(from: NSNumber(value: amount))
    }
    
    /// Check if two countries share similar financial systems
    public static func sharesSimilarFinancialSystem(_ country1: String, _ country2: String) -> Bool {
        guard let info1 = countryInfo(for: country1),
              let info2 = countryInfo(for: country2) else {
            return false
        }
        
        // Same currency or financial year
        return info1.currencyCode == info2.currencyCode ||
               info1.financialYearStartMonth == info2.financialYearStartMonth
    }
}