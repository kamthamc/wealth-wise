//
//  LocalizationConfig.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Localization Configuration
//

import Foundation
import SwiftUI

/// Localization configuration for language, region, and cultural preferences
/// Supports multiple languages and cultural adaptations
@Observable
public final class LocalizationConfig: Codable {
    
    // MARK: - Properties
    
    /// Selected app language
    public var appLanguage: AppLanguage
    
    /// Region/locale for number and date formatting
    public var region: String
    
    /// Number system preference (Western vs Indian)
    public var numberSystem: NumberSystem
    
    /// Date format preference
    public var dateFormat: LocalizationDateFormatStyle
    
    /// Time format preference (12/24 hour)
    public var timeFormat: TimeFormat
    
    /// Week start day
    public var weekStartDay: WeekDay
    
    /// Calendar system
    public var calendarSystem: CalendarSystem
    
    /// Use financial year (Apr-Mar for India, Jan-Dec for others)
    public var useFinancialYear: Bool
    
    /// RTL language support enabled
    public var isRTLEnabled: Bool
    
    /// Voice-over language preference
    public var voiceOverLanguage: String?
    
    // MARK: - Initialization
    
    public init() {
        // Initialize all properties with defaults
        appLanguage = .english
        region = "en_US"
        numberSystem = .western
        dateFormat = .system
        timeFormat = .system
        weekStartDay = .monday
        calendarSystem = .gregorian
        useFinancialYear = false
        isRTLEnabled = false
        voiceOverLanguage = nil
        
        // Configure based on system settings
        configureDefaults()
    }
    
    public init(forAudience audience: PrimaryAudience) {
        // Initialize all properties with defaults
        appLanguage = .english
        region = "en_US"
        numberSystem = .western
        dateFormat = .system
        timeFormat = .system
        weekStartDay = .monday
        calendarSystem = .gregorian
        useFinancialYear = false
        isRTLEnabled = false
        voiceOverLanguage = nil
        
        // Configure for specific audience
        configureForAudience(audience)
    }
    
    // MARK: - Configuration
    
    private func configureDefaults() {
        // Use system locale as default
        let systemLocale = Locale.current
        region = systemLocale.identifier
        
        // Set defaults based on system
        if systemLocale.language.languageCode?.identifier == "hi" {
            appLanguage = .hindi
            numberSystem = .indian
            useFinancialYear = true
        }
    }
    
    public func configureForAudience(_ audience: PrimaryAudience) {
        switch audience {
        case .indian:
            appLanguage = .english  // Primary language in India
            region = "en_IN"
            numberSystem = .indian
            useFinancialYear = true
            calendarSystem = .gregorian
            weekStartDay = .monday
            
        case .american:
            appLanguage = .english
            region = "en_US"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .sunday
            
        case .british:
            appLanguage = .english
            region = "en_GB"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .monday
            
        case .canadian:
            appLanguage = .english
            region = "en_CA"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .sunday
            
        case .australian:
            appLanguage = .english
            region = "en_AU"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .monday
            
        case .singaporean:
            appLanguage = .english
            region = "en_SG"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .monday
            
        case .german:
            appLanguage = .german
            region = "de_DE"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .monday
            
        case .french:
            appLanguage = .french
            region = "fr_FR"
            numberSystem = .western
            useFinancialYear = false
            weekStartDay = .monday
            
        default:
            configureDefaults()
        }
        
        // Set RTL based on language
        isRTLEnabled = appLanguage.isRTL
    }
    
    // MARK: - Computed Properties
    
    /// Current locale based on configuration
    public var currentLocale: Locale {
        Locale(identifier: region)
    }
    
    /// Current calendar based on configuration
    public var currentCalendar: Calendar {
        var calendar = Calendar(identifier: calendarSystem.identifier)
        calendar.firstWeekday = weekStartDay.rawValue
        return calendar
    }
    
    // MARK: - Validation
    
    public func validate() -> [String] {
        var issues: [String] = []
        
        // Validate region format
        if !region.contains("_") || region.count < 5 {
            issues.append("Invalid region format")
        }
        
        // Validate RTL consistency
        if isRTLEnabled && !appLanguage.isRTL {
            issues.append("RTL enabled for non-RTL language")
        }
        
        return issues
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case appLanguage
        case region
        case numberSystem
        case dateFormat
        case timeFormat
        case weekStartDay
        case calendarSystem
        case useFinancialYear
        case isRTLEnabled
        case voiceOverLanguage
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appLanguage, forKey: .appLanguage)
        try container.encode(region, forKey: .region)
        try container.encode(numberSystem, forKey: .numberSystem)
        try container.encode(dateFormat, forKey: .dateFormat)
        try container.encode(timeFormat, forKey: .timeFormat)
        try container.encode(weekStartDay, forKey: .weekStartDay)
        try container.encode(calendarSystem, forKey: .calendarSystem)
        try container.encode(useFinancialYear, forKey: .useFinancialYear)
        try container.encode(isRTLEnabled, forKey: .isRTLEnabled)
        try container.encode(voiceOverLanguage, forKey: .voiceOverLanguage)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appLanguage = try container.decode(AppLanguage.self, forKey: .appLanguage)
        region = try container.decode(String.self, forKey: .region)
        numberSystem = try container.decode(NumberSystem.self, forKey: .numberSystem)
        dateFormat = try container.decode(LocalizationDateFormatStyle.self, forKey: .dateFormat)
        timeFormat = try container.decode(TimeFormat.self, forKey: .timeFormat)
        weekStartDay = try container.decode(WeekDay.self, forKey: .weekStartDay)
        calendarSystem = try container.decode(CalendarSystem.self, forKey: .calendarSystem)
        useFinancialYear = try container.decode(Bool.self, forKey: .useFinancialYear)
        isRTLEnabled = try container.decode(Bool.self, forKey: .isRTLEnabled)
        voiceOverLanguage = try container.decodeIfPresent(String.self, forKey: .voiceOverLanguage)
    }
}

// MARK: - Supporting Types

/// Supported app languages
public enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case hindi = "hi"
    case arabic = "ar"
    case tamil = "ta"
    case telugu = "te"
    case bengali = "bn"
    case marathi = "mr"
    case gujarati = "gu"
    case kannada = "kn"
    case malayalam = "ml"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case portuguese = "pt"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case malay = "ms"
    case thai = "th"
    case vietnamese = "vi"
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिंदी"
        case .arabic: return "العربية"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .bengali: return "বাংলা"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        case .malayalam: return "മലയാളം"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .malay: return "Bahasa Melayu"
        case .thai: return "ไทย"
        case .vietnamese: return "Tiếng Việt"
        }
    }
    
    public var isRTL: Bool {
        return self == .arabic
    }
    
    public var languageCode: String {
        return rawValue
    }
}

/// Number system preferences
public enum NumberSystem: String, CaseIterable, Codable {
    case western = "western"    // 1,000,000 (million), 1,000,000,000 (billion)
    case indian = "indian"      // 10,00,000 (lakh), 1,00,00,000 (crore)
    
    public var displayName: String {
        switch self {
        case .western: return "Western (Million/Billion)"
        case .indian: return "Indian (Lakh/Crore)"
        }
    }
}

/// Date format styles
public enum LocalizationDateFormatStyle: String, CaseIterable, Codable {
    case system = "system"      // Follow system preference
    case ddmmyyyy = "dd/mm/yyyy"
    case mmddyyyy = "mm/dd/yyyy"
    case yyyymmdd = "yyyy-mm-dd"
    case relative = "relative"   // "2 days ago", "next week"
    
    public var displayName: String {
        switch self {
        case .system: return "System Default"
        case .ddmmyyyy: return "DD/MM/YYYY"
        case .mmddyyyy: return "MM/DD/YYYY"
        case .yyyymmdd: return "YYYY-MM-DD"
        case .relative: return "Relative (2 days ago)"
        }
    }
}

/// Time format preferences
public enum TimeFormat: String, CaseIterable, Codable {
    case system = "system"
    case twelve = "12"
    case twentyFour = "24"
    
    public var displayName: String {
        switch self {
        case .system: return "System Default"
        case .twelve: return "12 Hour (AM/PM)"
        case .twentyFour: return "24 Hour"
        }
    }
}

/// Week day enumeration
public enum WeekDay: Int, CaseIterable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    public var displayName: String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[self.rawValue - 1]
    }
}

/// Calendar system preferences
public enum CalendarSystem: String, CaseIterable, Codable {
    case gregorian = "gregorian"
    case buddhist = "buddhist"
    case chinese = "chinese"
    case coptic = "coptic"
    case ethiopicAmeteMihret = "ethiopicAmeteMihret"
    case hebrew = "hebrew"
    case indian = "indian"
    case islamic = "islamic"
    case islamicCivil = "islamicCivil"
    case islamicTabular = "islamicTabular"
    case islamicUmmAlQura = "islamicUmmAlQura"
    case iso8601 = "iso8601"
    case japanese = "japanese"
    case persian = "persian"
    case republicOfChina = "republicOfChina"
    
    public var displayName: String {
        switch self {
        case .gregorian: return "Gregorian"
        case .buddhist: return "Buddhist"
        case .chinese: return "Chinese"
        case .coptic: return "Coptic"
        case .ethiopicAmeteMihret: return "Ethiopic Amete Mihret"
        case .hebrew: return "Hebrew"
        case .indian: return "Indian National"
        case .islamic: return "Islamic"
        case .islamicCivil: return "Islamic Civil"
        case .islamicTabular: return "Islamic Tabular"
        case .islamicUmmAlQura: return "Islamic Umm al-Qura"
        case .iso8601: return "ISO 8601"
        case .japanese: return "Japanese"
        case .persian: return "Persian"
        case .republicOfChina: return "Republic of China"
        }
    }
    
    public var identifier: Calendar.Identifier {
        switch self {
        case .gregorian: return .gregorian
        case .buddhist: return .buddhist
        case .chinese: return .chinese
        case .coptic: return .coptic
        case .ethiopicAmeteMihret: return .ethiopicAmeteMihret
        case .hebrew: return .hebrew
        case .indian: return .indian
        case .islamic: return .islamic
        case .islamicCivil: return .islamicCivil
        case .islamicTabular: return .islamicTabular
        case .islamicUmmAlQura: return .islamicUmmAlQura
        case .iso8601: return .iso8601
        case .japanese: return .japanese
        case .persian: return .persian
        case .republicOfChina: return .republicOfChina
        }
    }
}