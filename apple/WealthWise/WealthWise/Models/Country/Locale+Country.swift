import Foundation

/// Extensions to Foundation's Locale for country and audience integration
extension Locale {
    
    /// Get the country code for the current locale
    public var countryCodeString: String? {
        if #available(macOS 13.0, iOS 16.0, *) {
            return self.region?.identifier
        } else {
            return self.regionCode
        }
    }
    
    /// Get display name for a country code in this locale
    public func displayName(for countryCode: String) -> String? {
        return self.localizedString(forRegionCode: countryCode.uppercased())
    }
    
    /// Check if this locale uses right-to-left text direction
    public var isRightToLeft: Bool {
        let languageId: String
        if #available(macOS 13.0, iOS 16.0, *) {
            languageId = self.language.languageCode?.identifier ?? "en"
            return Locale.Language(identifier: languageId).characterDirection == .rightToLeft
        } else {
            languageId = self.languageCode ?? "en"
            return Locale.characterDirection(forLanguage: languageId) == .rightToLeft
        }
    }
    
    /// Get the currency code for this locale's region
    public var currencyCodeString: String? {
        if #available(macOS 13.0, iOS 16.0, *) {
            return self.currency?.identifier
        } else {
            return self.currencyCode
        }
    }
    
    /// Check if this locale represents an Indian audience
    public var isIndianAudience: Bool {
        guard let countryCode = countryCodeString else { return false }
        return countryCode.uppercased() == "IN" || countryCode.uppercased() == "IND"
    }
    
    /// Check if this locale represents an English-speaking audience
    public var isEnglishSpeaking: Bool {
        if #available(macOS 13.0, iOS 16.0, *) {
            return self.language.languageCode?.identifier == "en"
        } else {
            return self.languageCode == "en"
        }
    }
    
    /// Get the financial year start month based on locale
    public var financialYearStartMonth: Int {
        guard let countryCode = countryCodeString else { return 1 }
        
        switch countryCode.uppercased() {
        case "IN", "IND", "GB", "GBR":
            return 4  // April
        default:
            return 1  // January
        }
    }
    
    /// Get preferred number formatting style based on locale
    public var preferredNumberFormatStyle: String {
        guard let countryCode = countryCodeString else { return "western" }
        
        switch countryCode.uppercased() {
        case "IN", "IND":
            return "indian"  // Lakh/Crore system
        case "DE", "DEU", "FR", "FRA", "NL", "NLD":
            return "european"  // European formatting
        case "JP", "JPN":
            return "japanese"  // Japanese formatting
        case "BR", "BRA":
            return "brazilian"  // Brazilian formatting
        case "MX", "MEX":
            return "mexican"  // Mexican formatting
        case "GB", "GBR":
            return "british"  // Mixed British formatting
        default:
            return "western"  // Standard Western formatting
        }
    }
    
    /// Get preferred date format style based on locale
    public var preferredDateFormatStyle: String {
        guard let countryCode = countryCodeString else { return "ddMMYYYY" }
        
        switch countryCode.uppercased() {
        case "US", "USA":
            return "mmDDYYYY"  // MM/DD/YYYY
        case "JP", "JPN":
            return "yyyyMMDD"  // YYYY/MM/DD
        case "CA", "CAN":
            return "mixed"  // Both formats common
        default:
            return "ddMMYYYY"  // DD/MM/YYYY
        }
    }
    
    /// Create a simple cultural preferences object from this locale
    public var culturalPreferences: SimpleCulturalPreferences {
        let langCode: String
        if #available(macOS 13.0, iOS 16.0, *) {
            langCode = self.language.languageCode?.identifier ?? "en"
        } else {
            langCode = self.languageCode ?? "en"
        }
        
        return SimpleCulturalPreferences(
            localeIdentifier: self.identifier,
            countryCode: countryCodeString ?? "US",
            languageCode: langCode,
            currencyCode: currencyCodeString ?? "USD",
            isRTL: isRightToLeft,
            numberFormatStyle: preferredNumberFormatStyle,
            dateFormatStyle: preferredDateFormatStyle,
            financialYearStartMonth: financialYearStartMonth
        )
    }
}

/// Simple cultural preferences derived from locale
public struct SimpleCulturalPreferences: Codable, Hashable {
    public let localeIdentifier: String
    public let countryCode: String
    public let languageCode: String
    public let currencyCode: String
    public let isRTL: Bool
    public let numberFormatStyle: String
    public let dateFormatStyle: String
    public let financialYearStartMonth: Int
    
    /// Get current locale preferences
    public static var current: SimpleCulturalPreferences {
        return Locale.current.culturalPreferences
    }
    
    /// Check if this represents an Indian market audience
    public var isIndianMarket: Bool {
        return countryCode.uppercased() == "IN" || countryCode.uppercased() == "IND"
    }
    
    /// Check if this represents a Western market audience
    public var isWesternMarket: Bool {
        let westernCountries = ["US", "USA", "CA", "CAN", "GB", "GBR", "AU", "AUS", "NZ", "NZL", "DE", "DEU", "FR", "FRA", "NL", "NLD", "CH", "CHE"]
        return westernCountries.contains(countryCode.uppercased())
    }
    
    /// Check if this represents an Asian market audience
    public var isAsianMarket: Bool {
        let asianCountries = ["IN", "IND", "SG", "SGP", "JP", "JPN", "HK", "HKG", "MY", "MYS", "TH", "THA", "PH", "PHL"]
        return asianCountries.contains(countryCode.uppercased())
    }
    
    /// Get accent color preference based on culture
    public var preferredAccentColor: String {
        switch countryCode.uppercased() {
        case "IN", "IND":
            return "orange"  // Saffron
        case "US", "USA", "GB", "GBR":
            return "blue"    // Patriotic blue
        case "CA", "CAN":
            return "red"     // Maple leaf red
        case "IE", "IRL":
            return "green"   // Irish green
        default:
            return "system"  // System default
        }
    }
}