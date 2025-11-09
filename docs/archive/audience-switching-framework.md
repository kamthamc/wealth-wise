# WealthWise Audience Switching Framework

## Overview
A modular audience system that adapts the entire application experience based on the user's primary market (Indian, US, UK, Canadian, etc.) while maintaining seamless switching capabilities and cross-border functionality.

## Audience Framework Architecture

### 1. Core Audience Types
```swift
enum PrimaryAudience: String, CaseIterable, Codable {
    case indian = "indian"
    case american = "american"
    case british = "british"
    case canadian = "canadian"
    case australian = "australian"
    case singaporean = "singaporean"
    case hongKong = "hong_kong"
    case emirati = "emirati"
    case global = "global"
    
    var displayName: String {
        switch self {
        case .indian: return "India"
        case .american: return "United States"
        case .british: return "United Kingdom"
        case .canadian: return "Canada"
        case .australian: return "Australia"
        case .singaporean: return "Singapore"
        case .hongKong: return "Hong Kong"
        case .emirati: return "United Arab Emirates"
        case .global: return "Global"
        }
    }
    
    var primaryCountry: SupportedCountry {
        switch self {
        case .indian: return .india
        case .american: return .unitedStates
        case .british: return .unitedKingdom
        case .canadian: return .canada
        case .australian: return .australia
        case .singaporean: return .singapore
        case .hongKong: return .hongKong
        case .emirati: return .uae
        case .global: return .unitedStates // Default to USD
        }
    }
    
    var primaryCurrency: SupportedCurrency {
        return primaryCountry.currency
    }
    
    var supportedLanguages: [LanguageCode] {
        switch self {
        case .indian: return [.english, .hindi, .tamil, .telugu, .bengali, .marathi, .gujarati, .kannada]
        case .american: return [.english, .spanish]
        case .british: return [.english]
        case .canadian: return [.english, .french]
        case .australian: return [.english]
        case .singaporean: return [.english, .mandarin, .malay, .tamil]
        case .hongKong: return [.english, .cantonese, .mandarin]
        case .emirati: return [.arabic, .english]
        case .global: return [.english]
        }
    }
    
    var culturalPreferences: CulturalPreferences {
        switch self {
        case .indian: return CulturalPreferences(
            numberSystem: .indian,
            dateFormat: .ddmmyyyy,
            weekStart: .monday,
            rtlSupport: false,
            familyFinanceSupport: true,
            festivalBudgeting: true,
            informalLendingSupport: true,
            physicalAssetFocus: true,
            golFocus: true
        )
        case .american: return CulturalPreferences(
            numberSystem: .western,
            dateFormat: .mmddyyyy,
            weekStart: .sunday,
            rtlSupport: false,
            familyFinanceSupport: false,
            festivalBudgeting: false,
            informalLendingSupport: false,
            physicalAssetFocus: false,
            goldFocus: false
        )
        case .british: return CulturalPreferences(
            numberSystem: .western,
            dateFormat: .ddmmyyyy,
            weekStart: .monday,
            rtlSupport: false,
            familyFinanceSupport: false,
            festivalBudgeting: false,
            informalLendingSupport: false,
            physicalAssetFocus: false,
            goldFocus: false
        )
        case .emirati: return CulturalPreferences(
            numberSystem: .western,
            dateFormat: .ddmmyyyy,
            weekStart: .saturday,
            rtlSupport: true,
            familyFinanceSupport: true,
            festivalBudgeting: true,
            informalLendingSupport: true,
            physicalAssetFocus: true,
            goldFocus: true
        )
        default: return CulturalPreferences.default
        }
    }
}

struct CulturalPreferences {
    let numberSystem: NumberingSystem
    let dateFormat: DateFormat
    let weekStart: WeekDay
    let rtlSupport: Bool
    let familyFinanceSupport: Bool
    let festivalBudgeting: Bool
    let informalLendingSupport: Bool
    let physicalAssetFocus: Bool
    let goldFocus: Bool
    
    static let `default` = CulturalPreferences(
        numberSystem: .western,
        dateFormat: .ddmmyyyy,
        weekStart: .monday,
        rtlSupport: false,
        familyFinanceSupport: false,
        festivalBudgeting: false,
        informalLendingSupport: false,
        physicalAssetFocus: false,
        goldFocus: false
    )
}

enum DateFormat {
    case ddmmyyyy
    case mmddyyyy
    case yyyymmdd
}

enum WeekDay: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

enum LanguageCode: String, CaseIterable {
    case english = "en"
    case hindi = "hi"
    case spanish = "es"
    case french = "fr"
    case mandarin = "zh"
    case cantonese = "yue"
    case arabic = "ar"
    case tamil = "ta"
    case telugu = "te"
    case bengali = "bn"
    case marathi = "mr"
    case gujarati = "gu"
    case kannada = "kn"
    case malay = "ms"
}
```

### 2. Audience Configuration System
```swift
struct AudienceConfiguration: Codable {
    let audience: PrimaryAudience
    let features: AudienceFeatures
    let regulations: RegulatoryFramework
    let financialInstruments: [FinancialInstrument]
    let integrations: [ServiceIntegration]
    let compliance: ComplianceRequirements
    
    static func configuration(for audience: PrimaryAudience) -> AudienceConfiguration {
        switch audience {
        case .indian:
            return AudienceConfiguration(
                audience: .indian,
                features: IndianAudienceFeatures(),
                regulations: IndianRegulatoryFramework(),
                financialInstruments: IndianFinancialInstruments.all,
                integrations: IndianServiceIntegrations.all,
                compliance: IndianComplianceRequirements()
            )
        case .american:
            return AudienceConfiguration(
                audience: .american,
                features: AmericanAudienceFeatures(),
                regulations: AmericanRegulatoryFramework(),
                financialInstruments: AmericanFinancialInstruments.all,
                integrations: AmericanServiceIntegrations.all,
                compliance: AmericanComplianceRequirements()
            )
        case .british:
            return AudienceConfiguration(
                audience: .british,
                features: BritishAudienceFeatures(),
                regulations: BritishRegulatoryFramework(),
                financialInstruments: BritishFinancialInstruments.all,
                integrations: BritishServiceIntegrations.all,
                compliance: BritishComplianceRequirements()
            )
        // Add other audiences...
        default:
            return AudienceConfiguration(
                audience: .global,
                features: GlobalAudienceFeatures(),
                regulations: GlobalRegulatoryFramework(),
                financialInstruments: GlobalFinancialInstruments.all,
                integrations: GlobalServiceIntegrations.all,
                compliance: GlobalComplianceRequirements()
            )
        }
    }
}

protocol AudienceFeatures {
    var dashboardLayout: DashboardLayout { get }
    var primaryActions: [PrimaryAction] { get }
    var assetCategories: [AssetCategory] { get }
    var reportingStyles: [ReportingStyle] { get }
    var budgetingApproach: BudgetingApproach { get }
    var goalCategories: [GoalCategory] { get }
}

struct IndianAudienceFeatures: AudienceFeatures {
    let dashboardLayout = DashboardLayout.netWorthFocused
    let primaryActions: [PrimaryAction] = [
        .addTransaction,
        .trackGoal,
        .manageTax,
        .viewPortfolio,
        .familyFinance,
        .goldTracker,
        .sipManagement
    ]
    let assetCategories: [AssetCategory] = [
        .bankAccounts,
        .mutualFunds,
        .stocks,
        .gold,
        .realEstate,
        .insurance,
        .providentFund,
        .nps,
        .bankLockerAssets,
        .informalLending
    ]
    let reportingStyles: [ReportingStyle] = [
        .netWorthStatement,
        .taxProjection,
        .goalProgress,
        .familyFinanceDashboard,
        .festivalBudget
    ]
    let budgetingApproach = BudgetingApproach.needWantSavings
    let goalCategories: [GoalCategory] = [
        .houseDownPayment,
        .childEducation,
        .retirement,
        .emergencyFund,
        .familyWedding,
        .festivalExpenses,
        .goldAccumulation
    ]
}

struct AmericanAudienceFeatures: AudienceFeatures {
    let dashboardLayout = DashboardLayout.cashFlowFocused
    let primaryActions: [PrimaryAction] = [
        .addTransaction,
        .budgetTracker,
        .investmentPortfolio,
        .retirementPlanning,
        .taxOptimization,
        .creditScore,
        .debtPayoff
    ]
    let assetCategories: [AssetCategory] = [
        .checkingAccounts,
        .savingsAccounts,
        .investmentAccounts,
        .retirementAccounts,
        .realEstate,
        .vehicles,
        .creditCards,
        .loans
    ]
    let reportingStyles: [ReportingStyle] = [
        .netWorthStatement,
        .cashFlowAnalysis,
        .investmentPerformance,
        .taxSummary,
        .retirementProjection
    ]
    let budgetingApproach = BudgetingApproach.fiftyThirtyTwenty
    let goalCategories: [GoalCategory] = [
        .emergencyFund,
        .retirement,
        .houseDownPayment,
        .vacation,
        .debtPayoff,
        .education
    ]
}
```

### 3. Audience Manager
```swift
class AudienceManager: ObservableObject {
    static let shared = AudienceManager()
    
    @Published var primaryAudience: PrimaryAudience = .indian
    @Published var currentConfiguration: AudienceConfiguration
    @Published var allowedCountries: [SupportedCountry] = []
    @Published var crossBorderMode: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        // Load saved audience preference
        if let savedAudience = userDefaults.string(forKey: "primaryAudience"),
           let audience = PrimaryAudience(rawValue: savedAudience) {
            primaryAudience = audience
        }
        
        currentConfiguration = AudienceConfiguration.configuration(for: primaryAudience)
        allowedCountries = [primaryAudience.primaryCountry]
        
        setupCrossBorderMode()
    }
    
    // MARK: - Audience Switching
    func switchToAudience(_ audience: PrimaryAudience) {
        let previousAudience = primaryAudience
        primaryAudience = audience
        currentConfiguration = AudienceConfiguration.configuration(for: audience)
        
        // Update currency if needed
        if CurrencyManager.shared.baseCurrency != audience.primaryCurrency {
            CurrencyManager.shared.setBaseCurrency(audience.primaryCurrency)
            CurrencyManager.shared.setDisplayCurrency(audience.primaryCurrency)
        }
        
        // Update allowed countries
        if !crossBorderMode {
            allowedCountries = [audience.primaryCountry]
        }
        
        // Save preference
        userDefaults.set(audience.rawValue, forKey: "primaryAudience")
        
        // Notify observers
        NotificationCenter.default.post(
            name: .audienceChanged,
            object: AudienceChangeInfo(
                from: previousAudience,
                to: audience,
                configuration: currentConfiguration
            )
        )
        
        objectWillChange.send()
    }
    
    func enableCrossBorderMode() {
        crossBorderMode = true
        allowedCountries = SupportedCountry.allCases
        userDefaults.set(true, forKey: "crossBorderMode")
        
        NotificationCenter.default.post(name: .crossBorderModeEnabled, object: nil)
    }
    
    func disableCrossBorderMode() {
        crossBorderMode = false
        allowedCountries = [primaryAudience.primaryCountry]
        userDefaults.set(false, forKey: "crossBorderMode")
        
        NotificationCenter.default.post(name: .crossBorderModeDisabled, object: nil)
    }
    
    // MARK: - Feature Availability
    func isFeatureAvailable(_ feature: AppFeature) -> Bool {
        switch feature {
        case .familyFinance:
            return currentConfiguration.features.assetCategories.contains(.familyAccounts)
        case .goldTracking:
            return primaryAudience.culturalPreferences.goldFocus
        case .informalLending:
            return primaryAudience.culturalPreferences.informalLendingSupport
        case .physicalAssets:
            return primaryAudience.culturalPreferences.physicalAssetFocus
        case .festivalBudgeting:
            return primaryAudience.culturalPreferences.festivalBudgeting
        case .multiCountryTax:
            return crossBorderMode
        case .cryptoTracking:
            return allowsCrypto()
        default:
            return true
        }
    }
    
    func getAvailableAssetTypes() -> [AssetType] {
        return currentConfiguration.features.assetCategories.flatMap { category in
            AssetType.types(for: category, audience: primaryAudience)
        }
    }
    
    func getRecommendedActions() -> [PrimaryAction] {
        return currentConfiguration.features.primaryActions
    }
    
    // MARK: - Localization Support
    func getSupportedLanguages() -> [LanguageCode] {
        return primaryAudience.supportedLanguages
    }
    
    func getCulturalPreferences() -> CulturalPreferences {
        return primaryAudience.culturalPreferences
    }
    
    // MARK: - Private Methods
    private func setupCrossBorderMode() {
        crossBorderMode = userDefaults.bool(forKey: "crossBorderMode")
        if crossBorderMode {
            allowedCountries = SupportedCountry.allCases
        }
    }
    
    private func allowsCrypto() -> Bool {
        // Check regulatory framework for crypto support
        switch primaryAudience {
        case .indian: return false // Currently restricted in India
        case .american, .british, .canadian, .australian, .singaporean: return true
        case .emirati: return false // Restricted
        default: return true
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let audienceChanged = Notification.Name("audienceChanged")
    static let crossBorderModeEnabled = Notification.Name("crossBorderModeEnabled")
    static let crossBorderModeDisabled = Notification.Name("crossBorderModeDisabled")
}

struct AudienceChangeInfo {
    let from: PrimaryAudience
    let to: PrimaryAudience
    let configuration: AudienceConfiguration
}
```

### 4. Financial Instruments by Audience
```swift
protocol FinancialInstrument {
    var name: String { get }
    var category: AssetCategory { get }
    var audience: PrimaryAudience { get }
    var regulatoryFramework: String { get }
    var taxImplications: [TaxImplication] { get }
}

struct IndianFinancialInstruments {
    static let all: [FinancialInstrument] = [
        // Savings & Banking
        SavingsBankAccount(regulatedBy: "RBI"),
        CurrentAccount(regulatedBy: "RBI"),
        FixedDeposit(regulatedBy: "RBI"),
        RecurringDeposit(regulatedBy: "RBI"),
        
        // Investments
        MutualFund(regulatedBy: "SEBI"),
        Stocks(regulatedBy: "SEBI"),
        ETF(regulatedBy: "SEBI"),
        BondsCorporate(regulatedBy: "SEBI"),
        BondsGovernment(regulatedBy: "RBI"),
        
        // Retirement
        ProvidentFund(regulatedBy: "EPFO"),
        NPS(regulatedBy: "PFRDA"),
        PPF(regulatedBy: "Ministry of Finance"),
        
        // Insurance
        LifeInsurance(regulatedBy: "IRDAI"),
        HealthInsurance(regulatedBy: "IRDAI"),
        ULIP(regulatedBy: "IRDAI"),
        
        // Physical Assets
        Gold(type: .physical),
        Silver(type: .physical),
        RealEstate(type: .residential),
        BankLockerAssets(),
        
        // Alternative
        InformalLending(),
        Cryptocurrency(legal: false) // Currently restricted
    ]
}

struct AmericanFinancialInstruments {
    static let all: [FinancialInstrument] = [
        // Banking
        CheckingAccount(regulatedBy: "FDIC"),
        SavingsAccount(regulatedBy: "FDIC"),
        MoneyMarketAccount(regulatedBy: "FDIC"),
        CertificateOfDeposit(regulatedBy: "FDIC"),
        
        // Investments
        Stocks(regulatedBy: "SEC"),
        Bonds(regulatedBy: "SEC"),
        MutualFunds(regulatedBy: "SEC"),
        ETFs(regulatedBy: "SEC"),
        REITs(regulatedBy: "SEC"),
        
        // Retirement
        K401(regulatedBy: "DOL"),
        TraditionalIRA(regulatedBy: "IRS"),
        RothIRA(regulatedBy: "IRS"),
        SEP_IRA(regulatedBy: "IRS"),
        
        // Real Estate
        PrimaryResidence(),
        InvestmentProperty(),
        
        // Alternative
        Cryptocurrency(legal: true),
        CommodityETFs(),
        PrivateEquity(),
        HedgeFunds()
    ]
}

// Sample implementation
struct MutualFund: FinancialInstrument {
    let name = "Mutual Fund"
    let category = AssetCategory.mutualFunds
    let audience: PrimaryAudience
    let regulatoryFramework: String
    let taxImplications: [TaxImplication]
    
    init(regulatedBy: String, audience: PrimaryAudience = .indian) {
        self.regulatoryFramework = regulatedBy
        self.audience = audience
        
        if audience == .indian {
            self.taxImplications = [
                TaxImplication(
                    type: .capitalGains,
                    rate: 0.10, // LTCG for equity funds
                    condition: "Equity funds held > 1 year"
                ),
                TaxImplication(
                    type: .capitalGains,
                    rate: 0.15, // STCG for equity funds
                    condition: "Equity funds held < 1 year"
                )
            ]
        } else {
            self.taxImplications = []
        }
    }
}
```

### 5. Audience-Specific UI Components
```swift
struct AudienceAwareView<Content: View>: View {
    @StateObject private var audienceManager = AudienceManager.shared
    let content: (AudienceConfiguration) -> Content
    
    var body: some View {
        content(audienceManager.currentConfiguration)
            .onReceive(NotificationCenter.default.publisher(for: .audienceChanged)) { _ in
                // React to audience changes
            }
    }
}

struct AudienceSwitcher: View {
    @StateObject private var audienceManager = AudienceManager.shared
    @State private var showingAudiencePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Current Audience Display
            HStack {
                VStack(alignment: .leading) {
                    Text("Primary Market")
                        .font(.headline)
                    Text(audienceManager.primaryAudience.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button("Switch") {
                    showingAudiencePicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Cross-Border Toggle
            Toggle("Multi-Country Mode", isOn: Binding(
                get: { audienceManager.crossBorderMode },
                set: { enabled in
                    if enabled {
                        audienceManager.enableCrossBorderMode()
                    } else {
                        audienceManager.disableCrossBorderMode()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle())
            
            if audienceManager.crossBorderMode {
                Text("Manage assets and taxes across multiple countries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick Audience Switcher
            QuickAudienceSwitcher()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .sheet(isPresented: $showingAudiencePicker) {
            AudiencePickerSheet()
        }
    }
}

struct QuickAudienceSwitcher: View {
    @StateObject private var audienceManager = AudienceManager.shared
    private let quickAudiences: [PrimaryAudience] = [.indian, .american, .british, .canadian, .australian]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Switch")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickAudiences, id: \.self) { audience in
                        AudienceButton(audience: audience)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct AudienceButton: View {
    let audience: PrimaryAudience
    @StateObject private var audienceManager = AudienceManager.shared
    
    var body: some View {
        Button(action: {
            audienceManager.switchToAudience(audience)
        }) {
            VStack(spacing: 4) {
                Text(audience.primaryCurrency.symbol)
                    .font(.title2)
                Text(audience.primaryCountry.rawValue)
                    .font(.caption)
            }
            .frame(width: 60, height: 50)
            .background(
                audienceManager.primaryAudience == audience ?
                Color.blue : Color.gray.opacity(0.2)
            )
            .foregroundColor(
                audienceManager.primaryAudience == audience ?
                .white : .primary
            )
            .cornerRadius(8)
        }
    }
}

struct AudiencePickerSheet: View {
    @StateObject private var audienceManager = AudienceManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(PrimaryAudience.allCases, id: \.self) { audience in
                    AudienceRow(audience: audience) {
                        audienceManager.switchToAudience(audience)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Market")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AudienceRow: View {
    let audience: PrimaryAudience
    let onSelect: () -> Void
    @StateObject private var audienceManager = AudienceManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audience.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(audience.primaryCurrency.displayName) • \(audience.primaryCurrency.symbol)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(audience.supportedLanguages.prefix(3), id: \.self) { language in
                            Text(language.rawValue.uppercased())
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                if audienceManager.primaryAudience == audience {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
```

### 6. Feature Gating System
```swift
struct FeatureGate<Content: View>: View {
    let feature: AppFeature
    let content: Content
    let fallback: AnyView?
    
    @StateObject private var audienceManager = AudienceManager.shared
    
    init(feature: AppFeature, @ViewBuilder content: () -> Content, fallback: (() -> AnyView)? = nil) {
        self.feature = feature
        self.content = content()
        self.fallback = fallback?()
    }
    
    var body: some View {
        if audienceManager.isFeatureAvailable(feature) {
            content
        } else if let fallback = fallback {
            fallback
        } else {
            EmptyView()
        }
    }
}

enum AppFeature {
    case familyFinance
    case goldTracking
    case informalLending
    case physicalAssets
    case festivalBudgeting
    case multiCountryTax
    case cryptoTracking
    case realEstateInvestment
    case retirementPlanning
    case taxOptimization
    case bankLockerAssets
    case sipManagement
    case options Trading
    case forexTrading
}

// Usage Example:
struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack {
                // Always visible
                NetWorthWidget()
                
                // India-specific features
                FeatureGate(feature: .goldTracking) {
                    GoldTrackingWidget()
                }
                
                FeatureGate(feature: .familyFinance) {
                    FamilyFinanceWidget()
                }
                
                // US-specific features
                FeatureGate(feature: .retirementPlanning) {
                    RetirementPlanningWidget()
                }
                
                // Global features with cross-border mode
                FeatureGate(feature: .multiCountryTax) {
                    MultiCountryTaxWidget()
                }
            }
        }
    }
}
```

### 7. Data Migration Between Audiences
```swift
class AudienceDataMigrator {
    static func migrateData(from: PrimaryAudience, to: PrimaryAudience) async throws {
        // 1. Currency conversion for all monetary values
        await migrateCurrencyData(from: from.primaryCurrency, to: to.primaryCurrency)
        
        // 2. Asset type mapping
        try await migrateAssetTypes(from: from, to: to)
        
        // 3. Tax profile conversion
        try await migrateTaxProfiles(from: from, to: to)
        
        // 4. Feature-specific data migration
        try await migrateFeatureData(from: from, to: to)
        
        // 5. Localization updates
        await updateLocalizedContent(for: to)
    }
    
    private static func migrateCurrencyData(from: SupportedCurrency, to: SupportedCurrency) async {
        // Convert all CurrencyAmount objects in the database
        // This would involve Core Data migration or similar
    }
    
    private static func migrateAssetTypes(from: PrimaryAudience, to: PrimaryAudience) async throws {
        // Map equivalent asset types between audiences
        let mappings = getAssetTypeMappings(from: from, to: to)
        
        for (sourceType, targetType) in mappings {
            // Update asset types in database
            try await updateAssetTypes(from: sourceType, to: targetType)
        }
    }
    
    private static func getAssetTypeMappings(from: PrimaryAudience, to: PrimaryAudience) -> [AssetType: AssetType] {
        // Define mappings between equivalent asset types
        switch (from, to) {
        case (.indian, .american):
            return [
                .providentFund: .k401,
                .mutualFunds: .mutualFunds,
                .stocks: .stocks,
                .bankSavings: .savingsAccount
            ]
        case (.american, .indian):
            return [
                .k401: .providentFund,
                .mutualFunds: .mutualFunds,
                .stocks: .stocks,
                .savingsAccount: .bankSavings
            ]
        default:
            return [:]
        }
    }
    
    private static func migrateTaxProfiles(from: PrimaryAudience, to: PrimaryAudience) async throws {
        // Create new tax profile for target audience
        // Mark existing profile as historical
    }
    
    private static func migrateFeatureData(from: PrimaryAudience, to: PrimaryAudience) async throws {
        // Handle feature-specific data that may not be available in target audience
        if from.culturalPreferences.goldFocus && !to.culturalPreferences.goldFocus {
            // Convert gold tracking to precious metals or investments
            try await convertGoldAssets()
        }
        
        if from.culturalPreferences.informalLendingSupport && !to.culturalPreferences.informalLendingSupport {
            // Convert informal lending to personal loans or other category
            try await convertInformalLending()
        }
    }
    
    private static func updateLocalizedContent(for audience: PrimaryAudience) async {
        // Update all localized strings for new audience
        let localizationManager = LocalizationManager.shared
        await localizationManager.switchLocalization(for: audience)
    }
    
    private static func convertGoldAssets() async throws {
        // Convert gold assets to precious metals or alternative investments
    }
    
    private static func convertInformalLending() async throws {
        // Convert informal lending to personal loans category
    }
    
    private static func updateAssetTypes(from: AssetType, to: AssetType) async throws {
        // Update database records
    }
}
```

This audience switching framework provides:

1. **Seamless Market Switching**: Easy switching between different regional audiences
2. **Cultural Adaptation**: Automatic UI/UX adaptation based on cultural preferences
3. **Feature Gating**: Show/hide features based on regulatory and cultural requirements
4. **Cross-Border Support**: Enable multi-country functionality when needed
5. **Data Migration**: Automatic data conversion when switching audiences
6. **Localization**: Language and formatting adaptation for each market
7. **Regulatory Compliance**: Audience-specific compliance and feature availability

The modular design ensures that adding new audiences requires minimal code changes while maintaining consistency across all supported markets.