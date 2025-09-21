import Foundation

// MARK: - Theme & Appearance Types

public enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    public var displayName: String {
        switch self {
        case .light:
            return NSLocalizedString("Light", comment: "Light theme")
        case .dark:
            return NSLocalizedString("Dark", comment: "Dark theme")
        case .system:
            return NSLocalizedString("System", comment: "System theme")
        }
    }
}

public enum ColorScheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    public var displayName: String {
        switch self {
        case .light:
            return NSLocalizedString("Light", comment: "Light color scheme")
        case .dark:
            return NSLocalizedString("Dark", comment: "Dark color scheme")
        case .system:
            return NSLocalizedString("System", comment: "System color scheme")
        }
    }
}

public enum AccentColor: String, Codable, CaseIterable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case teal = "teal"
    case indigo = "indigo"
    case mint = "mint"
    case cyan = "cyan"
    case yellow = "yellow"
    
    public var displayName: String {
        switch self {
        case .blue:
            return NSLocalizedString("Blue", comment: "Blue accent color")
        case .green:
            return NSLocalizedString("Green", comment: "Green accent color")
        case .orange:
            return NSLocalizedString("Orange", comment: "Orange accent color")
        case .red:
            return NSLocalizedString("Red", comment: "Red accent color")
        case .purple:
            return NSLocalizedString("Purple", comment: "Purple accent color")
        case .teal:
            return NSLocalizedString("Teal", comment: "Teal accent color")
        case .indigo:
            return NSLocalizedString("Indigo", comment: "Indigo accent color")
        case .mint:
            return NSLocalizedString("Mint", comment: "Mint accent color")
        case .cyan:
            return NSLocalizedString("Cyan", comment: "Cyan accent color")
        case .yellow:
            return NSLocalizedString("Yellow", comment: "Yellow accent color")
        }
    }
}

// MARK: - Currency & Financial Types

public enum CurrencyDisplayFormat: String, Codable, CaseIterable {
    case standard = "standard"           // $1,234.56
    case compact = "compact"             // $1.2K
    case abbreviated = "abbreviated"     // $1.23K
    case accounting = "accounting"       // $(1,234.56) for negative
    case minimal = "minimal"            // 1234.56 (no symbol)
    
    public var displayName: String {
        switch self {
        case .standard:
            return NSLocalizedString("Standard", comment: "Standard currency format")
        case .compact:
            return NSLocalizedString("Compact", comment: "Compact currency format")
        case .abbreviated:
            return NSLocalizedString("Abbreviated", comment: "Abbreviated currency format")
        case .accounting:
            return NSLocalizedString("Accounting", comment: "Accounting currency format")
        case .minimal:
            return NSLocalizedString("Minimal", comment: "Minimal currency format")
        }
    }
}

public enum NumberingSystem: String, Codable, CaseIterable {
    case western = "western"       // 1,234,567.89
    case indian = "indian"         // 12,34,567.89 (Indian lakh/crore system)
    case arabic = "arabic"         // Arabic-Indic digits
    case devanagari = "devanagari" // Devanagari digits
    case chinese = "chinese"       // Chinese numerals
    case japanese = "japanese"     // Japanese numerals
    
    public var displayName: String {
        switch self {
        case .western:
            return NSLocalizedString("Western", comment: "Western numbering system")
        case .indian:
            return NSLocalizedString("Indian", comment: "Indian numbering system")
        case .arabic:
            return NSLocalizedString("Arabic", comment: "Arabic numbering system")
        case .devanagari:
            return NSLocalizedString("Devanagari", comment: "Devanagari numbering system")
        case .chinese:
            return NSLocalizedString("Chinese", comment: "Chinese numbering system")
        case .japanese:
            return NSLocalizedString("Japanese", comment: "Japanese numbering system")
        }
    }
    
    public static func detectFromLocale() -> NumberingSystem {
        let locale = Locale.current
        let languageCode = locale.languageCode?.lowercased()
        let regionCode = locale.regionCode?.uppercased()
        
        switch (languageCode, regionCode) {
        case ("hi", "IN"), ("bn", "IN"), ("gu", "IN"), ("mr", "IN"), ("ta", "IN"), ("te", "IN"), ("kn", "IN"), ("ml", "IN"), ("or", "IN"), ("pa", "IN"):
            return .indian
        case ("ar", _):
            return .arabic
        case ("hi", _), ("ne", _), ("mr", _):
            return .devanagari
        case ("zh", _):
            return .chinese
        case ("ja", _):
            return .japanese
        default:
            return .western
        }
    }
    
    public func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        switch self {
        case .western:
            formatter.groupingSeparator = ","
            formatter.groupingSize = 3
        case .indian:
            return formatIndianNumbering(number)
        case .arabic:
            formatter.locale = Locale(identifier: "ar")
        case .devanagari:
            formatter.locale = Locale(identifier: "hi_IN@numbers=deva")
        case .chinese:
            formatter.locale = Locale(identifier: "zh_CN@numbers=hanidec")
        case .japanese:
            formatter.locale = Locale(identifier: "ja_JP@numbers=jpan")
        }
        
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
    
    private func formatIndianNumbering(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let absNumber = abs(number)
        let isNegative = number < 0
        
        if absNumber >= 10_000_000 { // 1 crore and above
            let crores = absNumber / 10_000_000
            let formattedCrores = formatter.string(from: NSNumber(value: crores)) ?? String(crores)
            let result = "\(formattedCrores) Cr"
            return isNegative ? "-\(result)" : result
        } else if absNumber >= 100_000 { // 1 lakh and above
            let lakhs = absNumber / 100_000
            let formattedLakhs = formatter.string(from: NSNumber(value: lakhs)) ?? String(lakhs)
            let result = "\(formattedLakhs) L"
            return isNegative ? "-\(result)" : result
        } else {
            // For numbers below 1 lakh, use standard formatting with Indian grouping
            let numberString = String(format: "%.2f", absNumber)
            let parts = numberString.components(separatedBy: ".")
            let integerPart = parts[0]
            let decimalPart = parts.count > 1 ? parts[1] : "00"
            
            let formattedInteger = addIndianGrouping(integerPart)
            let result = decimalPart == "00" ? formattedInteger : "\(formattedInteger).\(decimalPart)"
            return isNegative ? "-\(result)" : result
        }
    }
    
    private func addIndianGrouping(_ numberString: String) -> String {
        let reversed = String(numberString.reversed())
        var result = ""
        
        for (index, character) in reversed.enumerated() {
            if index == 3 || (index > 3 && (index - 3) % 2 == 0) {
                result += ","
            }
            result += String(character)
        }
        
        return String(result.reversed())
    }
}

public enum ExchangeRateUpdateFrequency: String, Codable, CaseIterable {
    case realTime = "realTime"     // Every few seconds (premium feature)
    case everyFiveMinutes = "everyFiveMinutes"
    case everyFifteenMinutes = "everyFifteenMinutes"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case manual = "manual"
    
    public var displayName: String {
        switch self {
        case .realTime:
            return NSLocalizedString("Real-time", comment: "Real-time exchange rate updates")
        case .everyFiveMinutes:
            return NSLocalizedString("Every 5 minutes", comment: "Exchange rate updates every 5 minutes")
        case .everyFifteenMinutes:
            return NSLocalizedString("Every 15 minutes", comment: "Exchange rate updates every 15 minutes")
        case .hourly:
            return NSLocalizedString("Hourly", comment: "Hourly exchange rate updates")
        case .daily:
            return NSLocalizedString("Daily", comment: "Daily exchange rate updates")
        case .weekly:
            return NSLocalizedString("Weekly", comment: "Weekly exchange rate updates")
        case .manual:
            return NSLocalizedString("Manual", comment: "Manual exchange rate updates")
        }
    }
    
    public var updateInterval: TimeInterval? {
        switch self {
        case .realTime:
            return 5 // 5 seconds
        case .everyFiveMinutes:
            return 300 // 5 minutes
        case .everyFifteenMinutes:
            return 900 // 15 minutes
        case .hourly:
            return 3600 // 1 hour
        case .daily:
            return 86400 // 24 hours
        case .weekly:
            return 604800 // 7 days
        case .manual:
            return nil
        }
    }
}

// MARK: - Accessibility Types

public enum FontSize: String, Codable, CaseIterable {
    case extraSmall = "extraSmall"
    case small = "small"  
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    case accessibility1 = "accessibility1"
    case accessibility2 = "accessibility2"
    case accessibility3 = "accessibility3"
    
    public var displayName: String {
        switch self {
        case .extraSmall:
            return NSLocalizedString("Extra Small", comment: "Extra small font size")
        case .small:
            return NSLocalizedString("Small", comment: "Small font size")
        case .medium:
            return NSLocalizedString("Medium", comment: "Medium font size")
        case .large:
            return NSLocalizedString("Large", comment: "Large font size")
        case .extraLarge:
            return NSLocalizedString("Extra Large", comment: "Extra large font size")
        case .accessibility1:
            return NSLocalizedString("Accessibility 1", comment: "Accessibility font size 1")
        case .accessibility2:
            return NSLocalizedString("Accessibility 2", comment: "Accessibility font size 2")
        case .accessibility3:
            return NSLocalizedString("Accessibility 3", comment: "Accessibility font size 3")
        }
    }
    
    public var scaleFactor: CGFloat {
        switch self {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.15
        case .extraLarge:
            return 1.3
        case .accessibility1:
            return 1.5
        case .accessibility2:
            return 1.75
        case .accessibility3:
            return 2.0
        }
    }
}

public enum HapticFeedbackLevel: String, Codable, CaseIterable {
    case off = "off"
    case light = "light"
    case medium = "medium"
    case strong = "strong"
    
    public var displayName: String {
        switch self {
        case .off:
            return NSLocalizedString("Off", comment: "Haptic feedback off")
        case .light:
            return NSLocalizedString("Light", comment: "Light haptic feedback")
        case .medium:
            return NSLocalizedString("Medium", comment: "Medium haptic feedback")
        case .strong:
            return NSLocalizedString("Strong", comment: "Strong haptic feedback")
        }
    }
}

// MARK: - Data & Privacy Types

public enum CloudBackupService: String, Codable, CaseIterable {
    case none = "none"
    case iCloud = "iCloud"
    case googleDrive = "googleDrive"
    case oneDrive = "oneDrive"
    case dropbox = "dropbox"
    
    public var displayName: String {
        switch self {
        case .none:
            return NSLocalizedString("None", comment: "No cloud backup")
        case .iCloud:
            return NSLocalizedString("iCloud", comment: "iCloud backup")
        case .googleDrive:
            return NSLocalizedString("Google Drive", comment: "Google Drive backup")
        case .oneDrive:
            return NSLocalizedString("OneDrive", comment: "OneDrive backup")
        case .dropbox:
            return NSLocalizedString("Dropbox", comment: "Dropbox backup")
        }
    }
    
    public static func detectFromPlatform() -> CloudBackupService {
        #if os(iOS) || os(macOS)
        return .iCloud
        #elseif os(Windows)
        return .oneDrive
        #else
        return .none
        #endif
    }
}

public enum DataRetentionPeriod: String, Codable, CaseIterable {
    case oneYear = "oneYear"
    case twoYears = "twoYears"
    case threeYears = "threeYears"
    case fiveYears = "fiveYears"
    case sevenYears = "sevenYears"
    case tenYears = "tenYears"
    case indefinite = "indefinite"
    
    public var displayName: String {
        switch self {
        case .oneYear:
            return NSLocalizedString("1 Year", comment: "One year data retention")
        case .twoYears:
            return NSLocalizedString("2 Years", comment: "Two years data retention")
        case .threeYears:
            return NSLocalizedString("3 Years", comment: "Three years data retention")
        case .fiveYears:
            return NSLocalizedString("5 Years", comment: "Five years data retention")
        case .sevenYears:
            return NSLocalizedString("7 Years", comment: "Seven years data retention")
        case .tenYears:
            return NSLocalizedString("10 Years", comment: "Ten years data retention")
        case .indefinite:
            return NSLocalizedString("Indefinite", comment: "Indefinite data retention")
        }
    }
    
    public var timeInterval: TimeInterval? {
        switch self {
        case .oneYear:
            return 365 * 24 * 60 * 60
        case .twoYears:
            return 2 * 365 * 24 * 60 * 60
        case .threeYears:
            return 3 * 365 * 24 * 60 * 60
        case .fiveYears:
            return 5 * 365 * 24 * 60 * 60
        case .sevenYears:
            return 7 * 365 * 24 * 60 * 60
        case .tenYears:
            return 10 * 365 * 24 * 60 * 60
        case .indefinite:
            return nil
        }
    }
}

// MARK: - Security Types

public enum AutoLockTimeout: String, Codable, CaseIterable {
    case immediate = "immediate"
    case thirtySeconds = "thirtySeconds"
    case oneMinute = "oneMinute"
    case twoMinutes = "twoMinutes"
    case fiveMinutes = "fiveMinutes"
    case tenMinutes = "tenMinutes"
    case fifteenMinutes = "fifteenMinutes"
    case thirtyMinutes = "thirtyMinutes"
    case oneHour = "oneHour"
    case never = "never"
    
    public var displayName: String {
        switch self {
        case .immediate:
            return NSLocalizedString("Immediate", comment: "Immediate auto-lock")
        case .thirtySeconds:
            return NSLocalizedString("30 seconds", comment: "30 seconds auto-lock")
        case .oneMinute:
            return NSLocalizedString("1 minute", comment: "1 minute auto-lock")
        case .twoMinutes:
            return NSLocalizedString("2 minutes", comment: "2 minutes auto-lock")
        case .fiveMinutes:
            return NSLocalizedString("5 minutes", comment: "5 minutes auto-lock")
        case .tenMinutes:
            return NSLocalizedString("10 minutes", comment: "10 minutes auto-lock")
        case .fifteenMinutes:
            return NSLocalizedString("15 minutes", comment: "15 minutes auto-lock")
        case .thirtyMinutes:
            return NSLocalizedString("30 minutes", comment: "30 minutes auto-lock")
        case .oneHour:
            return NSLocalizedString("1 hour", comment: "1 hour auto-lock")
        case .never:
            return NSLocalizedString("Never", comment: "Never auto-lock")
        }
    }
    
    public var timeInterval: TimeInterval? {
        switch self {
        case .immediate:
            return 0
        case .thirtySeconds:
            return 30
        case .oneMinute:
            return 60
        case .twoMinutes:
            return 120
        case .fiveMinutes:
            return 300
        case .tenMinutes:
            return 600
        case .fifteenMinutes:
            return 900
        case .thirtyMinutes:
            return 1800
        case .oneHour:
            return 3600
        case .never:
            return nil
        }
    }
}

// MARK: - Regional Settings Types

public enum DateFormatStyle: String, Codable, CaseIterable {
    case mdy = "mdy"         // MM/dd/yyyy (US)
    case dmy = "dmy"         // dd/MM/yyyy (UK, India)
    case ymd = "ymd"         // yyyy/MM/dd (ISO, Japan)
    case dmyDash = "dmyDash" // dd-MM-yyyy
    case ymdDash = "ymdDash" // yyyy-MM-dd
    case dmyDot = "dmyDot"   // dd.MM.yyyy (Germany)
    
    public var displayName: String {
        switch self {
        case .mdy:
            return NSLocalizedString("MM/dd/yyyy", comment: "US date format")
        case .dmy:
            return NSLocalizedString("dd/MM/yyyy", comment: "UK/India date format")
        case .ymd:
            return NSLocalizedString("yyyy/MM/dd", comment: "ISO date format")
        case .dmyDash:
            return NSLocalizedString("dd-MM-yyyy", comment: "Dash-separated date format")
        case .ymdDash:
            return NSLocalizedString("yyyy-MM-dd", comment: "ISO dash date format")
        case .dmyDot:
            return NSLocalizedString("dd.MM.yyyy", comment: "German date format")
        }
    }
    
    public var dateFormat: String {
        switch self {
        case .mdy:
            return "MM/dd/yyyy"
        case .dmy:
            return "dd/MM/yyyy"
        case .ymd:
            return "yyyy/MM/dd"
        case .dmyDash:
            return "dd-MM-yyyy"
        case .ymdDash:
            return "yyyy-MM-dd"
        case .dmyDot:
            return "dd.MM.yyyy"
        }
    }
}

public enum TimeFormat: String, Codable, CaseIterable {
    case twelve = "twelve"     // 12-hour (3:30 PM)
    case twentyFour = "twentyFour" // 24-hour (15:30)
    
    public var displayName: String {
        switch self {
        case .twelve:
            return NSLocalizedString("12-hour", comment: "12-hour time format")
        case .twentyFour:
            return NSLocalizedString("24-hour", comment: "24-hour time format")
        }
    }
}

public enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    public var displayName: String {
        switch self {
        case .sunday:
            return NSLocalizedString("Sunday", comment: "Sunday")
        case .monday:
            return NSLocalizedString("Monday", comment: "Monday")
        case .tuesday:
            return NSLocalizedString("Tuesday", comment: "Tuesday")
        case .wednesday:
            return NSLocalizedString("Wednesday", comment: "Wednesday")
        case .thursday:
            return NSLocalizedString("Thursday", comment: "Thursday")
        case .friday:
            return NSLocalizedString("Friday", comment: "Friday")
        case .saturday:
            return NSLocalizedString("Saturday", comment: "Saturday")
        }
    }
}

public enum FinancialYearStart: String, Codable, CaseIterable {
    case january = "january"       // January 1 (US, UK, most countries)
    case april = "april"           // April 1 (India, Japan)
    case july = "july"             // July 1 (Australia)
    case october = "october"       // October 1 (some companies)
    
    public var displayName: String {
        switch self {
        case .january:
            return NSLocalizedString("January", comment: "Financial year starts in January")
        case .april:
            return NSLocalizedString("April", comment: "Financial year starts in April")
        case .july:
            return NSLocalizedString("July", comment: "Financial year starts in July")
        case .october:
            return NSLocalizedString("October", comment: "Financial year starts in October")
        }
    }
    
    public var monthNumber: Int {
        switch self {
        case .january:
            return 1
        case .april:
            return 4
        case .july:
            return 7
        case .october:
            return 10
        }
    }
    
    public func startDate(for year: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = monthNumber
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }
    
    public func endDate(for year: Int) -> Date {
        let calendar = Calendar.current
        let startDate = self.startDate(for: year + 1)
        return calendar.date(byAdding: .day, value: -1, to: startDate) ?? Date()
    }
}