import Foundation

/// Cultural preferences and formatting configuration for different audiences
/// Provides market-specific adaptations for UI, data presentation, and user experience
public struct CulturalPreferences: Codable, Hashable {
    
    // MARK: - Properties
    
    /// Target audience identifier
    public let audienceIdentifier: String
    
    /// Preferred languages in order of preference
    public let languages: [String]
    
    /// Number formatting style identifier
    public let numberFormatStyle: String
    
    /// Date formatting style identifier
    public let dateFormatStyle: String
    
    /// Currency symbol position (before/after)
    public let currencySymbolPosition: String
    
    /// Text direction (ltr/rtl)
    public let textDirection: String
    
    /// Accent color preference
    public let accentColor: String
    
    /// Financial year start month (1-12)
    public let financialYearStartMonth: Int
    
    // MARK: - Initialization
    
    public init(
        audienceIdentifier: String,
        languages: [String] = ["en"],
        numberFormatStyle: String = "western",
        dateFormatStyle: String = "ddMMYYYY",
        currencySymbolPosition: String = "before",
        textDirection: String = "ltr",
        accentColor: String = "system",
        financialYearStartMonth: Int = 1
    ) {
        self.audienceIdentifier = audienceIdentifier
        self.languages = languages
        self.numberFormatStyle = numberFormatStyle
        self.dateFormatStyle = dateFormatStyle
        self.currencySymbolPosition = currencySymbolPosition
        self.textDirection = textDirection
        self.accentColor = accentColor
        self.financialYearStartMonth = financialYearStartMonth
    }
    
    /// Get cultural preferences for current device locale
    public static var current: CulturalPreferences {
        let localeId = Locale.current.identifier
        return CulturalPreferences(audienceIdentifier: localeId)
    }
    
    /// Predefined preferences for common audiences
    public static let indian = CulturalPreferences(
        audienceIdentifier: "indian",
        languages: ["hi", "en"],
        numberFormatStyle: "indian",
        dateFormatStyle: "ddMMYYYY",
        currencySymbolPosition: "before",
        textDirection: "ltr",
        accentColor: "orange",
        financialYearStartMonth: 4
    )
    
    public static let american = CulturalPreferences(
        audienceIdentifier: "american",
        languages: ["en"],
        numberFormatStyle: "western",
        dateFormatStyle: "mmDDYYYY",
        currencySymbolPosition: "before",
        textDirection: "ltr",
        accentColor: "blue",
        financialYearStartMonth: 1
    )
    
    public static let british = CulturalPreferences(
        audienceIdentifier: "british",
        languages: ["en"],
        numberFormatStyle: "british",
        dateFormatStyle: "ddMMYYYY",
        currencySymbolPosition: "before",
        textDirection: "ltr",
        accentColor: "blue",
        financialYearStartMonth: 4
    )
}