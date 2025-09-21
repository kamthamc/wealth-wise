# WealthWise Localization Infrastructure

## Overview
A comprehensive localization system supporting multiple languages, cultural preferences, RTL support, and region-specific formatting for numbers, dates, and currencies across all supported markets.

## Localization Architecture

### 1. Core Localization Types
```swift
struct LocalizationConfiguration {
    let language: LanguageCode
    let region: RegionCode
    let audience: PrimaryAudience
    let textDirection: TextDirection
    let numberFormatter: NumberFormatterConfiguration
    let dateFormatter: DateFormatterConfiguration
    let currencyFormatter: CurrencyFormatterConfiguration
    let culturalSettings: CulturalSettings
    
    static func configuration(
        for language: LanguageCode,
        audience: PrimaryAudience
    ) -> LocalizationConfiguration {
        return LocalizationConfiguration(
            language: language,
            region: audience.primaryRegion,
            audience: audience,
            textDirection: language.textDirection,
            numberFormatter: NumberFormatterConfiguration(
                for: language,
                audience: audience
            ),
            dateFormatter: DateFormatterConfiguration(
                for: language,
                audience: audience
            ),
            currencyFormatter: CurrencyFormatterConfiguration(
                for: language,
                audience: audience
            ),
            culturalSettings: CulturalSettings(
                for: language,
                audience: audience
            )
        )
    }
}

enum TextDirection: String, CaseIterable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"
    case topToBottom = "ttb" // For some Asian languages
}

extension LanguageCode {
    var textDirection: TextDirection {
        switch self {
        case .arabic, .hebrew: return .rightToLeft
        default: return .leftToRight
        }
    }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .spanish: return "Español"
        case .french: return "Français"
        case .mandarin: return "中文"
        case .cantonese: return "粵語"
        case .arabic: return "العربية"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .bengali: return "বাংলা"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        case .malay: return "Bahasa Melayu"
        }
    }
    
    var locale: Locale {
        switch self {
        case .english: return Locale(identifier: "en")
        case .hindi: return Locale(identifier: "hi_IN")
        case .spanish: return Locale(identifier: "es")
        case .french: return Locale(identifier: "fr")
        case .mandarin: return Locale(identifier: "zh_CN")
        case .cantonese: return Locale(identifier: "zh_HK")
        case .arabic: return Locale(identifier: "ar")
        case .tamil: return Locale(identifier: "ta_IN")
        case .telugu: return Locale(identifier: "te_IN")
        case .bengali: return Locale(identifier: "bn_IN")
        case .marathi: return Locale(identifier: "mr_IN")
        case .gujarati: return Locale(identifier: "gu_IN")
        case .kannada: return Locale(identifier: "kn_IN")
        case .malay: return Locale(identifier: "ms")
        }
    }
}

enum RegionCode: String, CaseIterable {
    case india = "IN"
    case unitedStates = "US"
    case unitedKingdom = "GB"
    case canada = "CA"
    case australia = "AU"
    case singapore = "SG"
    case hongKong = "HK"
    case uae = "AE"
    case germany = "DE"
    case france = "FR"
}

extension PrimaryAudience {
    var primaryRegion: RegionCode {
        switch self {
        case .indian: return .india
        case .american: return .unitedStates
        case .british: return .unitedKingdom
        case .canadian: return .canada
        case .australian: return .australia
        case .singaporean: return .singapore
        case .hongKong: return .hongKong
        case .emirati: return .uae
        case .global: return .unitedStates
        }
    }
}
```

### 2. String Catalog System
```swift
protocol StringCatalog {
    func localizedString(for key: LocalizationKey, language: LanguageCode) -> String
    func localizedString(for key: LocalizationKey, language: LanguageCode, arguments: [String]) -> String
}

enum LocalizationKey: String, CaseIterable {
    // Navigation & UI
    case dashboard = "dashboard"
    case portfolio = "portfolio"
    case transactions = "transactions"
    case goals = "goals"
    case settings = "settings"
    case reports = "reports"
    
    // Financial Terms
    case netWorth = "net_worth"
    case totalAssets = "total_assets"
    case totalLiabilities = "total_liabilities"
    case monthlyIncome = "monthly_income"
    case monthlyExpenses = "monthly_expenses"
    case savingsRate = "savings_rate"
    
    // Asset Types
    case bankAccount = "bank_account"
    case mutualFunds = "mutual_funds"
    case stocks = "stocks"
    case gold = "gold"
    case realEstate = "real_estate"
    case insurance = "insurance"
    case providentFund = "provident_fund"
    case nps = "nps"
    
    // Actions
    case addTransaction = "add_transaction"
    case createGoal = "create_goal"
    case viewDetails = "view_details"
    case editAmount = "edit_amount"
    case delete = "delete"
    case save = "save"
    case cancel = "cancel"
    
    // Indian Specific
    case lakhCrore = "lakh_crore"
    case bankLocker = "bank_locker"
    case informalLending = "informal_lending"
    case festivalBudget = "festival_budget"
    case familyFinance = "family_finance"
    
    // US Specific
    case retirementAccount = "retirement_account"
    case taxDeductible = "tax_deductible"
    case creditScore = "credit_score"
    case estate Planning = "estate_planning"
    
    // Tax Terms
    case taxLiability = "tax_liability"
    case advanceTax = "advance_tax"
    case taxSavings = "tax_savings"
    case deductions = "deductions"
    case resident = "resident"
    case nonResident = "non_resident"
    
    // Time & Dates
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisYear = "this_year"
    case lastMonth = "last_month"
    case lastYear = "last_year"
    
    // Numbers & Amounts
    case amount = "amount"
    case percentage = "percentage"
    case increase = "increase"
    case decrease = "decrease"
    case noChange = "no_change"
}

class StringCatalogManager: StringCatalog {
    static let shared = StringCatalogManager()
    private var catalogs: [LanguageCode: [LocalizationKey: String]] = [:]
    
    private init() {
        loadStringCatalogs()
    }
    
    func localizedString(for key: LocalizationKey, language: LanguageCode) -> String {
        return catalogs[language]?[key] ?? key.rawValue
    }
    
    func localizedString(for key: LocalizationKey, language: LanguageCode, arguments: [String]) -> String {
        let template = localizedString(for: key, language: language)
        return String(format: template, arguments: arguments)
    }
    
    private func loadStringCatalogs() {
        // English (Default)
        catalogs[.english] = [
            .dashboard: "Dashboard",
            .portfolio: "Portfolio",
            .transactions: "Transactions",
            .goals: "Goals",
            .settings: "Settings",
            .reports: "Reports",
            .netWorth: "Net Worth",
            .totalAssets: "Total Assets",
            .totalLiabilities: "Total Liabilities",
            .monthlyIncome: "Monthly Income",
            .monthlyExpenses: "Monthly Expenses",
            .savingsRate: "Savings Rate",
            .bankAccount: "Bank Account",
            .mutualFunds: "Mutual Funds",
            .stocks: "Stocks",
            .gold: "Gold",
            .realEstate: "Real Estate",
            .insurance: "Insurance",
            .providentFund: "Provident Fund",
            .nps: "National Pension System",
            .addTransaction: "Add Transaction",
            .createGoal: "Create Goal",
            .viewDetails: "View Details",
            .editAmount: "Edit Amount",
            .delete: "Delete",
            .save: "Save",
            .cancel: "Cancel",
            .lakhCrore: "Lakh/Crore",
            .bankLocker: "Bank Locker",
            .informalLending: "Informal Lending",
            .festivalBudget: "Festival Budget",
            .familyFinance: "Family Finance",
            .retirementAccount: "Retirement Account",
            .taxDeductible: "Tax Deductible",
            .creditScore: "Credit Score",
            .estatePlanning: "Estate Planning",
            .taxLiability: "Tax Liability",
            .advanceTax: "Advance Tax",
            .taxSavings: "Tax Savings",
            .deductions: "Deductions",
            .resident: "Resident",
            .nonResident: "Non-Resident",
            .today: "Today",
            .thisWeek: "This Week",
            .thisMonth: "This Month",
            .thisYear: "This Year",
            .lastMonth: "Last Month",
            .lastYear: "Last Year",
            .amount: "Amount",
            .percentage: "Percentage",
            .increase: "Increase",
            .decrease: "Decrease",
            .noChange: "No Change"
        ]
        
        // Hindi
        catalogs[.hindi] = [
            .dashboard: "डैशबोर्ड",
            .portfolio: "पोर्टफोलियो",
            .transactions: "लेन-देन",
            .goals: "लक्ष्य",
            .settings: "सेटिंग्स",
            .reports: "रिपोर्ट",
            .netWorth: "कुल संपत्ति",
            .totalAssets: "कुल संपत्ति",
            .totalLiabilities: "कुल देनदारी",
            .monthlyIncome: "मासिक आय",
            .monthlyExpenses: "मासिक खर्च",
            .savingsRate: "बचत दर",
            .bankAccount: "बैंक खाता",
            .mutualFunds: "म्यूचुअल फंड",
            .stocks: "शेयर",
            .gold: "सोना",
            .realEstate: "संपत्ति",
            .insurance: "बीमा",
            .providentFund: "भविष्य निधि",
            .nps: "राष्ट्रीय पेंशन योजना",
            .addTransaction: "लेन-देन जोड़ें",
            .createGoal: "लक्ष्य बनाएं",
            .viewDetails: "विवरण देखें",
            .editAmount: "राशि संपादित करें",
            .delete: "हटाएं",
            .save: "सेव करें",
            .cancel: "रद्द करें",
            .lakhCrore: "लाख/करोड़",
            .bankLocker: "बैंक लॉकर",
            .informalLending: "अनौपचारिक उधार",
            .festivalBudget: "त्योहार बजट",
            .familyFinance: "पारिवारिक वित्त",
            .taxLiability: "कर देनदारी",
            .advanceTax: "अग्रिम कर",
            .taxSavings: "कर बचत",
            .deductions: "कटौती",
            .resident: "निवासी",
            .nonResident: "अनिवासी",
            .today: "आज",
            .thisWeek: "इस सप्ताह",
            .thisMonth: "इस महीने",
            .thisYear: "इस साल",
            .lastMonth: "पिछले महीने",
            .lastYear: "पिछले साल",
            .amount: "राशि",
            .percentage: "प्रतिशत",
            .increase: "वृद्धि",
            .decrease: "कमी",
            .noChange: "कोई बदलाव नहीं"
        ]
        
        // Arabic
        catalogs[.arabic] = [
            .dashboard: "لوحة القيادة",
            .portfolio: "محفظة الاستثمار",
            .transactions: "المعاملات",
            .goals: "الأهداف",
            .settings: "الإعدادات",
            .reports: "التقارير",
            .netWorth: "صافي الثروة",
            .totalAssets: "إجمالي الأصول",
            .totalLiabilities: "إجمالي الخصوم",
            .monthlyIncome: "الدخل الشهري",
            .monthlyExpenses: "المصروفات الشهرية",
            .savingsRate: "معدل الادخار",
            .bankAccount: "حساب مصرفي",
            .mutualFunds: "صناديق الاستثمار",
            .stocks: "الأسهم",
            .gold: "الذهب",
            .realEstate: "العقارات",
            .insurance: "التأمين",
            .addTransaction: "إضافة معاملة",
            .createGoal: "إنشاء هدف",
            .viewDetails: "عرض التفاصيل",
            .editAmount: "تعديل المبلغ",
            .delete: "حذف",
            .save: "حفظ",
            .cancel: "إلغاء",
            .taxLiability: "الالتزام الضريبي",
            .taxSavings: "وفورات ضريبية",
            .deductions: "الخصومات",
            .resident: "مقيم",
            .nonResident: "غير مقيم",
            .today: "اليوم",
            .thisWeek: "هذا الأسبوع",
            .thisMonth: "هذا الشهر",
            .thisYear: "هذا العام",
            .lastMonth: "الشهر الماضي",
            .lastYear: "العام الماضي",
            .amount: "المبلغ",
            .percentage: "النسبة المئوية",
            .increase: "زيادة",
            .decrease: "نقصان",
            .noChange: "لا تغيير"
        ]
        
        // Add more languages as needed...
    }
}
```

### 3. Number Formatter Configuration
```swift
struct NumberFormatterConfiguration {
    let locale: Locale
    let numberingSystem: NumberingSystem
    let groupingSeparator: String
    let decimalSeparator: String
    let usesGroupingSeparator: Bool
    let minimumFractionDigits: Int
    let maximumFractionDigits: Int
    
    init(for language: LanguageCode, audience: PrimaryAudience) {
        self.locale = language.locale
        
        switch audience {
        case .indian:
            self.numberingSystem = .indian
            self.groupingSeparator = ","
            self.decimalSeparator = "."
            self.usesGroupingSeparator = true
            self.minimumFractionDigits = 0
            self.maximumFractionDigits = 2
            
        case .emirati:
            self.numberingSystem = .western
            self.groupingSeparator = language == .arabic ? "،" : ","
            self.decimalSeparator = language == .arabic ? "." : "."
            self.usesGroupingSeparator = true
            self.minimumFractionDigits = 0
            self.maximumFractionDigits = 2
            
        default:
            self.numberingSystem = .western
            self.groupingSeparator = ","
            self.decimalSeparator = "."
            self.usesGroupingSeparator = true
            self.minimumFractionDigits = 0
            self.maximumFractionDigits = 2
        }
    }
}

class LocalizedNumberFormatter {
    private let configuration: NumberFormatterConfiguration
    private let formatter: NumberFormatter
    
    init(configuration: NumberFormatterConfiguration) {
        self.configuration = configuration
        self.formatter = NumberFormatter()
        setupFormatter()
    }
    
    private func setupFormatter() {
        formatter.locale = configuration.locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = configuration.usesGroupingSeparator
        formatter.groupingSeparator = configuration.groupingSeparator
        formatter.decimalSeparator = configuration.decimalSeparator
        formatter.minimumFractionDigits = configuration.minimumFractionDigits
        formatter.maximumFractionDigits = configuration.maximumFractionDigits
        
        // Indian numbering system
        if configuration.numberingSystem == .indian {
            formatter.groupingSize = 3
            formatter.secondaryGroupingSize = 2
        }
    }
    
    func format(_ number: Decimal) -> String {
        return formatter.string(from: number as NSDecimalNumber) ?? "0"
    }
    
    func formatLargeNumber(_ number: Decimal) -> String {
        switch configuration.numberingSystem {
        case .indian:
            return formatIndianLargeNumber(number)
        case .western:
            return formatWesternLargeNumber(number)
        default:
            return format(number)
        }
    }
    
    private func formatIndianLargeNumber(_ number: Decimal) -> String {
        let absoluteNumber = abs(number)
        let isNegative = number < 0
        let prefix = isNegative ? "-" : ""
        
        if absoluteNumber >= 10000000 { // 1 Crore
            let crores = absoluteNumber / 10000000
            if crores >= 100 {
                return "\(prefix)\(format(crores)) Cr"
            } else {
                return "\(prefix)\(format(crores)) Crore"
            }
        } else if absoluteNumber >= 100000 { // 1 Lakh
            let lakhs = absoluteNumber / 100000
            return "\(prefix)\(format(lakhs)) Lakh"
        } else if absoluteNumber >= 1000 { // 1 Thousand
            let thousands = absoluteNumber / 1000
            return "\(prefix)\(format(thousands))K"
        } else {
            return format(number)
        }
    }
    
    private func formatWesternLargeNumber(_ number: Decimal) -> String {
        let absoluteNumber = abs(number)
        let isNegative = number < 0
        let prefix = isNegative ? "-" : ""
        
        if absoluteNumber >= 1000000000 { // 1 Billion
            let billions = absoluteNumber / 1000000000
            return "\(prefix)\(format(billions))B"
        } else if absoluteNumber >= 1000000 { // 1 Million
            let millions = absoluteNumber / 1000000
            return "\(prefix)\(format(millions))M"
        } else if absoluteNumber >= 1000 { // 1 Thousand
            let thousands = absoluteNumber / 1000
            return "\(prefix)\(format(thousands))K"
        } else {
            return format(number)
        }
    }
}
```

### 4. Date Formatter Configuration
```swift
struct DateFormatterConfiguration {
    let locale: Locale
    let dateFormat: String
    let timeFormat: String
    let calendar: Calendar
    let timeZone: TimeZone
    
    init(for language: LanguageCode, audience: PrimaryAudience) {
        self.locale = language.locale
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = language.locale
        
        switch audience {
        case .indian:
            self.dateFormat = "dd/MM/yyyy"
            self.timeFormat = "HH:mm"
            calendar.firstWeekday = 2 // Monday
            
        case .american:
            self.dateFormat = "MM/dd/yyyy"
            self.timeFormat = "h:mm a"
            calendar.firstWeekday = 1 // Sunday
            
        case .british, .australian, .singaporean:
            self.dateFormat = "dd/MM/yyyy"
            self.timeFormat = "HH:mm"
            calendar.firstWeekday = 2 // Monday
            
        case .canadian:
            self.dateFormat = "yyyy-MM-dd"
            self.timeFormat = "HH:mm"
            calendar.firstWeekday = 1 // Sunday
            
        case .emirati:
            self.dateFormat = "dd/MM/yyyy"
            self.timeFormat = "HH:mm"
            calendar.firstWeekday = 7 // Saturday
            
        default:
            self.dateFormat = "dd/MM/yyyy"
            self.timeFormat = "HH:mm"
            calendar.firstWeekday = 2 // Monday
        }
        
        self.calendar = calendar
        self.timeZone = TimeZone.current
    }
}

class LocalizedDateFormatter {
    private let configuration: DateFormatterConfiguration
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let relativeDateFormatter: RelativeDateTimeFormatter
    
    init(configuration: DateFormatterConfiguration) {
        self.configuration = configuration
        
        self.dateFormatter = DateFormatter()
        self.timeFormatter = DateFormatter()
        self.relativeDateFormatter = RelativeDateTimeFormatter()
        
        setupFormatters()
    }
    
    private func setupFormatters() {
        // Date formatter
        dateFormatter.locale = configuration.locale
        dateFormatter.dateFormat = configuration.dateFormat
        dateFormatter.calendar = configuration.calendar
        dateFormatter.timeZone = configuration.timeZone
        
        // Time formatter
        timeFormatter.locale = configuration.locale
        timeFormatter.dateFormat = configuration.timeFormat
        timeFormatter.calendar = configuration.calendar
        timeFormatter.timeZone = configuration.timeZone
        
        // Relative date formatter
        relativeDateFormatter.locale = configuration.locale
        relativeDateFormatter.calendar = configuration.calendar
        relativeDateFormatter.unitsStyle = .full
    }
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        return "\(formatDate(date)) \(formatTime(date))"
    }
    
    func formatRelativeDate(_ date: Date) -> String {
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    func formatFinancialYear(_ date: Date, audience: PrimaryAudience) -> String {
        let calendar = configuration.calendar
        let year = calendar.component(.year, from: date)
        
        switch audience.primaryCountry.taxYear {
        case .april: // India: Apr-Mar
            let month = calendar.component(.month, from: date)
            if month >= 4 {
                return "FY \(year)-\(String(year + 1).suffix(2))"
            } else {
                return "FY \(year - 1)-\(String(year).suffix(2))"
            }
            
        case .july: // Australia: Jul-Jun
            let month = calendar.component(.month, from: date)
            if month >= 7 {
                return "FY \(year)-\(String(year + 1).suffix(2))"
            } else {
                return "FY \(year - 1)-\(String(year).suffix(2))"
            }
            
        case .january: // Most countries: Jan-Dec
            return "FY \(year)"
        }
    }
}
```

### 5. Currency Formatter Configuration
```swift
struct CurrencyFormatterConfiguration {
    let locale: Locale
    let currencyCode: String
    let currencySymbol: String
    let symbolPosition: SymbolPosition
    let decimalPlaces: Int
    let showCurrencyCode: Bool
    
    enum SymbolPosition {
        case prefix    // $100
        case suffix    // 100$
        case spacePrefix // $ 100
        case spaceSuffix // 100 $
    }
    
    init(for language: LanguageCode, audience: PrimaryAudience) {
        self.locale = language.locale
        self.currencyCode = audience.primaryCurrency.rawValue
        self.currencySymbol = audience.primaryCurrency.symbol
        self.decimalPlaces = audience.primaryCurrency.decimalPlaces
        self.showCurrencyCode = false
        
        // Symbol position based on language/culture
        switch language {
        case .arabic:
            self.symbolPosition = .spaceSuffix
        case .french:
            self.symbolPosition = .spaceSuffix
        default:
            self.symbolPosition = .prefix
        }
    }
}

class LocalizedCurrencyFormatter {
    private let configuration: CurrencyFormatterConfiguration
    private let numberFormatter: LocalizedNumberFormatter
    
    init(
        configuration: CurrencyFormatterConfiguration,
        numberFormatter: LocalizedNumberFormatter
    ) {
        self.configuration = configuration
        self.numberFormatter = numberFormatter
    }
    
    func format(_ amount: Decimal, style: CurrencyStyle = .full) -> String {
        let formattedNumber = numberFormatter.format(amount)
        
        switch style {
        case .symbolOnly:
            return formatWithSymbol(formattedNumber)
        case .codeOnly:
            return "\(formattedNumber) \(configuration.currencyCode)"
        case .full:
            return configuration.showCurrencyCode ? 
                "\(formatWithSymbol(formattedNumber)) \(configuration.currencyCode)" :
                formatWithSymbol(formattedNumber)
        case .compact:
            return numberFormatter.formatLargeNumber(amount)
        }
    }
    
    private func formatWithSymbol(_ formattedNumber: String) -> String {
        switch configuration.symbolPosition {
        case .prefix:
            return "\(configuration.currencySymbol)\(formattedNumber)"
        case .suffix:
            return "\(formattedNumber)\(configuration.currencySymbol)"
        case .spacePrefix:
            return "\(configuration.currencySymbol) \(formattedNumber)"
        case .spaceSuffix:
            return "\(formattedNumber) \(configuration.currencySymbol)"
        }
    }
    
    enum CurrencyStyle {
        case symbolOnly  // $100
        case codeOnly    // 100 USD
        case full        // $100 USD
        case compact     // $1.2K
    }
}
```

### 6. Localization Manager
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: LanguageCode = .english
    @Published var currentAudience: PrimaryAudience = .indian
    @Published var currentConfiguration: LocalizationConfiguration
    
    private let stringCatalog = StringCatalogManager.shared
    private var numberFormatter: LocalizedNumberFormatter
    private var dateFormatter: LocalizedDateFormatter
    private var currencyFormatter: LocalizedCurrencyFormatter
    
    private init() {
        // Load saved preferences
        if let savedLanguage = UserDefaults.standard.string(forKey: "currentLanguage"),
           let language = LanguageCode(rawValue: savedLanguage) {
            currentLanguage = language
        }
        
        if let savedAudience = UserDefaults.standard.string(forKey: "primaryAudience"),
           let audience = PrimaryAudience(rawValue: savedAudience) {
            currentAudience = audience
        }
        
        // Initialize configuration
        currentConfiguration = LocalizationConfiguration.configuration(
            for: currentLanguage,
            audience: currentAudience
        )
        
        // Setup formatters
        numberFormatter = LocalizedNumberFormatter(
            configuration: currentConfiguration.numberFormatter
        )
        dateFormatter = LocalizedDateFormatter(
            configuration: currentConfiguration.dateFormatter
        )
        currencyFormatter = LocalizedCurrencyFormatter(
            configuration: currentConfiguration.currencyFormatter,
            numberFormatter: numberFormatter
        )
    }
    
    // MARK: - Language Management
    func switchLanguage(to language: LanguageCode) {
        currentLanguage = language
        updateConfiguration()
        UserDefaults.standard.set(language.rawValue, forKey: "currentLanguage")
        
        NotificationCenter.default.post(
            name: .languageChanged,
            object: LanguageChangeInfo(
                from: currentLanguage,
                to: language,
                textDirection: language.textDirection
            )
        )
    }
    
    func switchLocalization(for audience: PrimaryAudience) async {
        currentAudience = audience
        
        // Auto-select primary language for audience
        let primaryLanguage = getPrimaryLanguage(for: audience)
        if currentLanguage != primaryLanguage {
            currentLanguage = primaryLanguage
        }
        
        updateConfiguration()
        
        NotificationCenter.default.post(
            name: .localizationChanged,
            object: LocalizationChangeInfo(
                audience: audience,
                language: currentLanguage,
                configuration: currentConfiguration
            )
        )
    }
    
    private func updateConfiguration() {
        currentConfiguration = LocalizationConfiguration.configuration(
            for: currentLanguage,
            audience: currentAudience
        )
        
        // Update formatters
        numberFormatter = LocalizedNumberFormatter(
            configuration: currentConfiguration.numberFormatter
        )
        dateFormatter = LocalizedDateFormatter(
            configuration: currentConfiguration.dateFormatter
        )
        currencyFormatter = LocalizedCurrencyFormatter(
            configuration: currentConfiguration.currencyFormatter,
            numberFormatter: numberFormatter
        )
        
        objectWillChange.send()
    }
    
    private func getPrimaryLanguage(for audience: PrimaryAudience) -> LanguageCode {
        return audience.supportedLanguages.first ?? .english
    }
    
    // MARK: - Localization Methods
    func localizedString(_ key: LocalizationKey) -> String {
        return stringCatalog.localizedString(for: key, language: currentLanguage)
    }
    
    func localizedString(_ key: LocalizationKey, arguments: String...) -> String {
        return stringCatalog.localizedString(for: key, language: currentLanguage, arguments: arguments)
    }
    
    func formatNumber(_ number: Decimal) -> String {
        return numberFormatter.format(number)
    }
    
    func formatLargeNumber(_ number: Decimal) -> String {
        return numberFormatter.formatLargeNumber(number)
    }
    
    func formatCurrency(_ amount: Decimal, style: LocalizedCurrencyFormatter.CurrencyStyle = .full) -> String {
        return currencyFormatter.format(amount, style: style)
    }
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.formatDate(date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        return dateFormatter.formatDateTime(date)
    }
    
    func formatRelativeDate(_ date: Date) -> String {
        return dateFormatter.formatRelativeDate(date)
    }
    
    func formatFinancialYear(_ date: Date) -> String {
        return dateFormatter.formatFinancialYear(date, audience: currentAudience)
    }
    
    // MARK: - RTL Support
    var isRTL: Bool {
        return currentConfiguration.textDirection == .rightToLeft
    }
    
    var layoutDirection: LayoutDirection {
        return isRTL ? .rightToLeft : .leftToRight
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
    static let localizationChanged = Notification.Name("localizationChanged")
}

struct LanguageChangeInfo {
    let from: LanguageCode
    let to: LanguageCode
    let textDirection: TextDirection
}

struct LocalizationChangeInfo {
    let audience: PrimaryAudience
    let language: LanguageCode
    let configuration: LocalizationConfiguration
}
```

### 7. SwiftUI Integration
```swift
// MARK: - Environment Values
struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Modifiers
struct LocalizedTextModifier: ViewModifier {
    let key: LocalizationKey
    @Environment(\.localization) private var localization
    
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, localization.layoutDirection)
    }
}

extension View {
    func localized() -> some View {
        self.modifier(LocalizedTextModifier(key: .dashboard))
    }
}

// MARK: - Localized Components
struct LocalizedText: View {
    let key: LocalizationKey
    let arguments: [String]
    @Environment(\.localization) private var localization
    
    init(_ key: LocalizationKey, arguments: String... = []) {
        self.key = key
        self.arguments = arguments
    }
    
    var body: some View {
        Text(localization.localizedString(key, arguments: arguments))
    }
}

struct LocalizedCurrencyText: View {
    let amount: Decimal
    let style: LocalizedCurrencyFormatter.CurrencyStyle
    @Environment(\.localization) private var localization
    
    init(_ amount: Decimal, style: LocalizedCurrencyFormatter.CurrencyStyle = .full) {
        self.amount = amount
        self.style = style
    }
    
    var body: some View {
        Text(localization.formatCurrency(amount, style: style))
    }
}

struct LocalizedNumberText: View {
    let number: Decimal
    let large: Bool
    @Environment(\.localization) private var localization
    
    init(_ number: Decimal, large: Bool = false) {
        self.number = number
        self.large = large
    }
    
    var body: some View {
        Text(large ? localization.formatLargeNumber(number) : localization.formatNumber(number))
    }
}

struct LocalizedDateText: View {
    let date: Date
    let style: DateStyle
    @Environment(\.localization) private var localization
    
    enum DateStyle {
        case date, dateTime, relative, financialYear
    }
    
    init(_ date: Date, style: DateStyle = .date) {
        self.date = date
        self.style = style
    }
    
    var body: some View {
        Text(formattedDate)
    }
    
    private var formattedDate: String {
        switch style {
        case .date:
            return localization.formatDate(date)
        case .dateTime:
            return localization.formatDateTime(date)
        case .relative:
            return localization.formatRelativeDate(date)
        case .financialYear:
            return localization.formatFinancialYear(date)
        }
    }
}

// MARK: - Language Selector
struct LanguageSelector: View {
    @StateObject private var localization = LocalizationManager.shared
    @State private var showingLanguagePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                LocalizedText(.settings)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingLanguagePicker = true
                }) {
                    HStack {
                        Text(localization.currentLanguage.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // RTL Support Indicator
            if localization.isRTL {
                HStack {
                    Image(systemName: "text.alignright")
                        .foregroundColor(.blue)
                    Text("Right-to-Left Layout")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerSheet()
        }
        .environment(\.layoutDirection, localization.layoutDirection)
    }
}

struct LanguagePickerSheet: View {
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(localization.currentAudience.supportedLanguages, id: \.self) { language in
                    LanguageRow(language: language) {
                        localization.switchLanguage(to: language)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .environment(\.layoutDirection, localization.layoutDirection)
    }
}

struct LanguageRow: View {
    let language: LanguageCode
    let onSelect: () -> Void
    @StateObject private var localization = LocalizationManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if localization.currentLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
                
                if language.textDirection == .rightToLeft {
                    Image(systemName: "text.alignright")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
```

This comprehensive localization infrastructure provides:

1. **Multi-Language Support**: Full support for all major languages in target markets
2. **Cultural Adaptation**: Number, date, and currency formatting based on cultural preferences  
3. **RTL Support**: Complete right-to-left layout support for Arabic and Hebrew
4. **String Catalogs**: Organized, maintainable string management system
5. **Formatter Configuration**: Locale-specific formatting for numbers, dates, and currencies
6. **SwiftUI Integration**: Seamless integration with SwiftUI components and environment
7. **Dynamic Switching**: Runtime language and localization switching capabilities

The modular design makes it easy to add new languages and cultural preferences while maintaining consistency across the application.