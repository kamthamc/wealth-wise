//
//  LocalizationKey.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Comprehensive localization key management for WealthWise application
//

import Foundation

/// Comprehensive localization key enumeration covering all user-facing strings in WealthWise
/// Organized by functional categories for maintainability and cultural context
public enum LocalizationKey: String, CaseIterable, Sendable {
    
    // MARK: - Asset Types
    case assetTypeStocks = "asset.type.stocks"
    case assetTypeBonds = "asset.type.bonds"
    case assetTypeMutualFunds = "asset.type.mutual_funds"
    case assetTypeETFs = "asset.type.etfs"
    case assetTypeRealEstate = "asset.type.real_estate"
    case assetTypeCommodities = "asset.type.commodities"
    case assetTypeCryptocurrency = "asset.type.cryptocurrency"
    case assetTypeCash = "asset.type.cash"
    case assetTypeFixedDeposits = "asset.type.fixed_deposits"
    case assetTypePPF = "asset.type.ppf"
    case assetTypeEPF = "asset.type.epf"
    case assetTypeNSC = "asset.type.nsc"
    case assetTypeGoldBonds = "asset.type.gold_bonds"
    case assetTypeTreasuryBills = "asset.type.treasury_bills"
    case assetTypeCorporateBonds = "asset.type.corporate_bonds"
    case assetTypeInternationalStocks = "asset.type.international_stocks"
    case assetTypePrivateBusiness = "asset.type.private_business"
    case assetTypeAlternativeInvestments = "asset.type.alternative_investments"
    case assetTypeInsurance = "asset.type.insurance"
    case assetTypeOther = "asset.type.other"
    
    // MARK: - Currencies
    case currencyINR = "currency.inr"
    case currencyUSD = "currency.usd"
    case currencyEUR = "currency.eur"
    case currencyGBP = "currency.gbp"
    case currencyJPY = "currency.jpy"
    case currencyCAD = "currency.cad"
    case currencyAUD = "currency.aud"
    case currencyCHF = "currency.chf"
    case currencyCNY = "currency.cny"
    case currencySGD = "currency.sgd"
    case currencyHKD = "currency.hkd"
    case currencyNZD = "currency.nzd"
    case currencySEK = "currency.sek"
    case currencyNOK = "currency.nok"
    case currencyDKK = "currency.dkk"
    case currencyPLN = "currency.pln"
    case currencyCZK = "currency.czk"
    case currencyHUF = "currency.huf"
    case currencyRUB = "currency.rub"
    case currencyBRL = "currency.brl"
    case currencyKRW = "currency.krw"
    case currencyMXN = "currency.mxn"
    case currencyZAR = "currency.zar"
    
    // MARK: - Countries
    case countryIndia = "country.india"
    case countryUnitedStates = "country.united_states"
    case countryUnitedKingdom = "country.united_kingdom"
    case countryCanada = "country.canada"
    case countryAustralia = "country.australia"
    case countrySingapore = "country.singapore"
    case countryGermany = "country.germany"
    case countryFrance = "country.france"
    case countryJapan = "country.japan"
    case countrySwitzerland = "country.switzerland"
    case countryChina = "country.china"
    case countryHongKong = "country.hong_kong"
    case countryNewZealand = "country.new_zealand"
    case countrySweden = "country.sweden"
    case countryNorway = "country.norway"
    case countryDenmark = "country.denmark"
    case countryPoland = "country.poland"
    case countryCzechRepublic = "country.czech_republic"
    case countryHungary = "country.hungary"
    case countryRussia = "country.russia"
    case countryBrazil = "country.brazil"
    case countrySouthKorea = "country.south_korea"
    case countryMexico = "country.mexico"
    case countrySouthAfrica = "country.south_africa"
    
    // MARK: - General UI
    case generalLoading = "general.loading"
    case generalError = "general.error"
    case generalSuccess = "general.success"
    case generalWarning = "general.warning"
    case generalCancel = "general.cancel"
    case generalSave = "general.save"
    case generalDelete = "general.delete"
    case generalEdit = "general.edit"
    case generalDone = "general.done"
    case generalBack = "general.back"
    case generalNext = "general.next"
    case generalPrevious = "general.previous"
    case generalClose = "general.close"
    case generalAdd = "general.add"
    case generalRemove = "general.remove"
    case generalClear = "general.clear"
    case generalRefresh = "general.refresh"
    case generalSearch = "general.search"
    case generalFilter = "general.filter"
    case generalSort = "general.sort"
    case generalExport = "general.export"
    case generalImport = "general.import"
    case generalSettings = "general.settings"
    case generalHelp = "general.help"
    case generalAbout = "general.about"
    
    // MARK: - Navigation
    case navDashboard = "nav.dashboard"
    case navAssets = "nav.assets"
    case navGoals = "nav.goals"
    case navTaxes = "nav.taxes"
    case navReports = "nav.reports"
    case navSettings = "nav.settings"
    case navProfile = "nav.profile"
    case navPreferences = "nav.preferences"
    case navSecurity = "nav.security"
    case navBackup = "nav.backup"
    
    // MARK: - Financial Terms
    case finAmount = "financial.amount"
    case finBalance = "financial.balance"
    case finValue = "financial.value"
    case finPrice = "financial.price"
    case finCost = "financial.cost"
    case finProfit = "financial.profit"
    case finLoss = "financial.loss"
    case finGain = "financial.gain"
    case finReturn = "financial.return"
    case finYield = "financial.yield"
    case finDividend = "financial.dividend"
    case finInterest = "financial.interest"
    case finFees = "financial.fees"
    case finTax = "financial.tax"
    case finCapitalGains = "financial.capital_gains"
    case finNetWorth = "financial.net_worth"
    case finPortfolio = "financial.portfolio"
    case finAllocation = "financial.allocation"
    case finPerformance = "financial.performance"
    case finRisk = "financial.risk"
    case finVolatility = "financial.volatility"
    case finCompoundInterest = "financial.compound_interest"
    case finFutureValue = "financial.future_value"
    case finPresentValue = "financial.present_value"
    case finAnnuity = "financial.annuity"
    case finPerpetuity = "financial.perpetuity"
    case finNPV = "financial.net_present_value"
    case finIRR = "financial.internal_rate_return"
    case finTimeValueMoney = "financial.time_value_money"
    
    // MARK: - Goal Tracking
    case goalTitle = "goal.title"
    case goalDescription = "goal.description"
    case goalTarget = "goal.target"
    case goalCurrent = "goal.current"
    case goalProgress = "goal.progress"
    case goalDeadline = "goal.deadline"
    case goalPriority = "goal.priority"
    case goalStatus = "goal.status"
    case goalAchieved = "goal.achieved"
    case goalInProgress = "goal.in_progress"
    case goalOverdue = "goal.overdue"
    case goalOnTrack = "goal.on_track"
    case goalBehindSchedule = "goal.behind_schedule"
    case goalAheadSchedule = "goal.ahead_schedule"
    case goalMilestone = "goal.milestone"
    case goalContribution = "goal.contribution"
    case goalProjection = "goal.projection"
    case goalRecommendation = "goal.recommendation"
    
    // MARK: - Error Messages
    case errorNetwork = "error.network"
    case errorInvalidInput = "error.invalid_input"
    case errorFileNotFound = "error.file_not_found"
    case errorPermissionDenied = "error.permission_denied"
    case errorDataCorrupted = "error.data_corrupted"
    case errorQuotaExceeded = "error.quota_exceeded"
    case errorTimeout = "error.timeout"
    case errorUnknown = "error.unknown"
    case errorValidation = "error.validation"
    case errorAuthentication = "error.authentication"
    case errorAuthorization = "error.authorization"
    case errorServerError = "error.server_error"
    case errorMaintenance = "error.maintenance"
    
    // MARK: - Accessibility
    case accessibilityButton = "accessibility.button"
    case accessibilityLink = "accessibility.link"
    case accessibilityHeading = "accessibility.heading"
    case accessibilityLabel = "accessibility.label"
    case accessibilityValue = "accessibility.value"
    case accessibilityHint = "accessibility.hint"
    case accessibilitySelected = "accessibility.selected"
    case accessibilityNotSelected = "accessibility.not_selected"
    case accessibilityExpanded = "accessibility.expanded"
    case accessibilityCollapsed = "accessibility.collapsed"
    case accessibilityLoading = "accessibility.loading"
    case accessibilityError = "accessibility.error"
    case accessibilitySuccess = "accessibility.success"
    
    // MARK: - Date & Time
    case dateToday = "date.today"
    case dateYesterday = "date.yesterday"
    case dateTomorrow = "date.tomorrow"
    case dateThisWeek = "date.this_week"
    case dateLastWeek = "date.last_week"
    case dateNextWeek = "date.next_week"
    case dateThisMonth = "date.this_month"
    case dateLastMonth = "date.last_month"
    case dateNextMonth = "date.next_month"
    case dateThisYear = "date.this_year"
    case dateLastYear = "date.last_year"
    case dateNextYear = "date.next_year"
    
    // MARK: - Numbering Systems
    case numberLakh = "number.lakh"
    case numberCrore = "number.crore"
    case numberMillion = "number.million"
    case numberBillion = "number.billion"
    case numberTrillion = "number.trillion"
    case numberThousand = "number.thousand"
    case numberHundred = "number.hundred"
    
    // MARK: - Cultural Context
    case culturalIndian = "cultural.indian"
    case culturalWestern = "cultural.western"
    case culturalBritish = "cultural.british"
    case culturalEuropean = "cultural.european"
    case culturalAmerican = "cultural.american"
    case culturalCanadian = "cultural.canadian"
    case culturalAustralian = "cultural.australian"
    case culturalSingaporean = "cultural.singaporean"
    case culturalGlobal = "cultural.global"
    case culturalMultiCountry = "cultural.multi_country"
    
    // MARK: - User Interface States
    case stateEmpty = "state.empty"
    case stateNoData = "state.no_data"
    case stateOffline = "state.offline"
    case stateConnecting = "state.connecting"
    case stateSyncing = "state.syncing"
    case stateUpdating = "state.updating"
    case stateProcessing = "state.processing"
    case stateCompleted = "state.completed"
    case stateFailed = "state.failed"
    case statePending = "state.pending"
    case stateActive = "state.active"
    case stateInactive = "state.inactive"
    case stateEnabled = "state.enabled"
    case stateDisabled = "state.disabled"
    
    // MARK: - Computed Properties
    
    /// Localized string value for the key
    public var localizedString: String {
        NSLocalizedString(self.rawValue, comment: self.comment)
    }
    
    /// Localized string with parameter substitution
    /// - Parameter arguments: Arguments for string interpolation
    /// - Returns: Formatted localized string
    public func localizedString(with arguments: CVarArg...) -> String {
        String(format: localizedString, arguments: arguments)
    }
    
    /// Comment for translators explaining the context of this string
    public var comment: String {
        switch self {
        // Asset Types
        case .assetTypeStocks: return "Stock market investments"
        case .assetTypeBonds: return "Bond investments"
        case .assetTypeMutualFunds: return "Mutual fund investments"
        case .assetTypeETFs: return "Exchange-traded fund investments"
        case .assetTypeRealEstate: return "Real estate properties"
        case .assetTypeCommodities: return "Commodity investments like gold, silver"
        case .assetTypeCryptocurrency: return "Cryptocurrency holdings"
        case .assetTypeCash: return "Cash in hand or savings"
        case .assetTypeFixedDeposits: return "Fixed deposit accounts"
        case .assetTypePPF: return "Public Provident Fund (India)"
        case .assetTypeEPF: return "Employee Provident Fund (India)"
        case .assetTypeNSC: return "National Savings Certificate (India)"
        case .assetTypeGoldBonds: return "Government gold bonds"
        case .assetTypeTreasuryBills: return "Government treasury bills"
        case .assetTypeCorporateBonds: return "Corporate bond investments"
        case .assetTypeInternationalStocks: return "International stock market investments"
        case .assetTypePrivateBusiness: return "Private business ownership"
        case .assetTypeAlternativeInvestments: return "Alternative investment classes"
        case .assetTypeInsurance: return "Insurance policies with investment components"
        case .assetTypeOther: return "Other asset types not listed"
        
        // General UI
        case .generalLoading: return "Loading indicator text"
        case .generalError: return "Generic error message"
        case .generalSuccess: return "Success message"
        case .generalWarning: return "Warning message"
        case .generalCancel: return "Cancel button"
        case .generalSave: return "Save button"
        case .generalDelete: return "Delete button"
        case .generalEdit: return "Edit button"
        case .generalDone: return "Done button"
        case .generalBack: return "Back navigation button"
        case .generalNext: return "Next button"
        case .generalPrevious: return "Previous button"
        case .generalClose: return "Close button or dialog"
        case .generalAdd: return "Add new item button"
        case .generalRemove: return "Remove item button"
        case .generalClear: return "Clear all button"
        case .generalRefresh: return "Refresh/reload button"
        case .generalSearch: return "Search functionality"
        case .generalFilter: return "Filter options"
        case .generalSort: return "Sort options"
        case .generalExport: return "Export data"
        case .generalImport: return "Import data"
        case .generalSettings: return "Settings/preferences"
        case .generalHelp: return "Help documentation"
        case .generalAbout: return "About the application"
        
        // Financial Terms
        case .finAmount: return "Generic amount of money"
        case .finBalance: return "Account or portfolio balance"
        case .finValue: return "Current value of asset"
        case .finPrice: return "Purchase or market price"
        case .finCost: return "Cost or expense"
        case .finProfit: return "Profit from investment"
        case .finLoss: return "Loss from investment"
        case .finGain: return "Capital or investment gain"
        case .finReturn: return "Investment return percentage"
        case .finYield: return "Investment yield"
        case .finDividend: return "Dividend payment"
        case .finInterest: return "Interest earned or paid"
        case .finFees: return "Fees or charges"
        case .finTax: return "Tax liability or payment"
        case .finCapitalGains: return "Capital gains from investments"
        case .finNetWorth: return "Total net worth calculation"
        case .finPortfolio: return "Investment portfolio"
        case .finAllocation: return "Asset allocation strategy"
        case .finPerformance: return "Investment performance metrics"
        case .finRisk: return "Investment risk level"
        case .finVolatility: return "Market volatility measure"
        case .finCompoundInterest: return "Compound interest calculation"
        case .finFutureValue: return "Future value of investment"
        case .finPresentValue: return "Present value calculation"
        case .finAnnuity: return "Annuity payment"
        case .finPerpetuity: return "Perpetual payment stream"
        case .finNPV: return "Net Present Value calculation"
        case .finIRR: return "Internal Rate of Return"
        case .finTimeValueMoney: return "Time value of money concept"
        
        // Goal Tracking
        case .goalTitle: return "Financial goal title"
        case .goalDescription: return "Goal description or details"
        case .goalTarget: return "Target amount for goal"
        case .goalCurrent: return "Current progress amount"
        case .goalProgress: return "Progress percentage or status"
        case .goalDeadline: return "Goal deadline date"
        case .goalPriority: return "Goal priority level"
        case .goalStatus: return "Current status of goal"
        case .goalAchieved: return "Goal has been achieved"
        case .goalInProgress: return "Goal is currently in progress"
        case .goalOverdue: return "Goal deadline has passed"
        case .goalOnTrack: return "Goal is on track to be achieved"
        case .goalBehindSchedule: return "Goal is behind schedule"
        case .goalAheadSchedule: return "Goal is ahead of schedule"
        case .goalMilestone: return "Goal milestone marker"
        case .goalContribution: return "Contribution to goal"
        case .goalProjection: return "Projected goal completion"
        case .goalRecommendation: return "Recommendation for goal achievement"
        
        // Error Messages
        case .errorNetwork: return "Network connection error"
        case .errorInvalidInput: return "User input validation error"
        case .errorFileNotFound: return "File not found error"
        case .errorPermissionDenied: return "Permission denied error"
        case .errorDataCorrupted: return "Data corruption error"
        case .errorQuotaExceeded: return "Storage or API quota exceeded"
        case .errorTimeout: return "Operation timeout error"
        case .errorUnknown: return "Unknown error occurred"
        case .errorValidation: return "Data validation error"
        case .errorAuthentication: return "Authentication failed"
        case .errorAuthorization: return "Authorization failed"
        case .errorServerError: return "Server-side error"
        case .errorMaintenance: return "System under maintenance"
        
        // Accessibility
        case .accessibilityButton: return "Accessibility label for button"
        case .accessibilityLink: return "Accessibility label for link"
        case .accessibilityHeading: return "Accessibility heading role"
        case .accessibilityLabel: return "Generic accessibility label"
        case .accessibilityValue: return "Accessibility value description"
        case .accessibilityHint: return "Accessibility usage hint"
        case .accessibilitySelected: return "Item is selected state"
        case .accessibilityNotSelected: return "Item is not selected state"
        case .accessibilityExpanded: return "Expandable item is expanded"
        case .accessibilityCollapsed: return "Expandable item is collapsed"
        case .accessibilityLoading: return "Loading state for screen readers"
        case .accessibilityError: return "Error state for screen readers"
        case .accessibilitySuccess: return "Success state for screen readers"
        
        // Default cases for other enums
        default: return "Localization key: \(self.rawValue)"
        }
    }
    
    /// Category grouping for organizational purposes
    public var category: LocalizationCategory {
        switch self {
        case let key where key.rawValue.hasPrefix("asset."):
            return .assets
        case let key where key.rawValue.hasPrefix("currency."):
            return .currencies
        case let key where key.rawValue.hasPrefix("country."):
            return .countries
        case let key where key.rawValue.hasPrefix("general."):
            return .general
        case let key where key.rawValue.hasPrefix("nav."):
            return .navigation
        case let key where key.rawValue.hasPrefix("financial."):
            return .financial
        case let key where key.rawValue.hasPrefix("goal."):
            return .goals
        case let key where key.rawValue.hasPrefix("error."):
            return .errors
        case let key where key.rawValue.hasPrefix("accessibility."):
            return .accessibility
        case let key where key.rawValue.hasPrefix("date."):
            return .dateTime
        case let key where key.rawValue.hasPrefix("number."):
            return .numbers
        case let key where key.rawValue.hasPrefix("cultural."):
            return .cultural
        case let key where key.rawValue.hasPrefix("state."):
            return .states
        default:
            return .other
        }
    }
}

/// Categories for organizing localization keys
public enum LocalizationCategory: String, CaseIterable, Sendable {
    case assets = "Assets"
    case currencies = "Currencies"
    case countries = "Countries"
    case general = "General UI"
    case navigation = "Navigation"
    case financial = "Financial Terms"
    case goals = "Goal Tracking"
    case errors = "Error Messages"
    case accessibility = "Accessibility"
    case dateTime = "Date & Time"
    case numbers = "Numbers"
    case cultural = "Cultural Context"
    case states = "UI States"
    case other = "Other"
    
    /// Display name for the category
    public var displayName: String {
        rawValue
    }
    
    /// All keys belonging to this category
    public var keys: [LocalizationKey] {
        LocalizationKey.allCases.filter { $0.category == self }
    }
}