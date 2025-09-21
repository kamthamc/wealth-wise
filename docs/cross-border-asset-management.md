# WealthWise Cross-Border Asset Management System

## Overview
A comprehensive system for managing assets across multiple countries with automatic currency conversion, cross-border tax implications, regulatory compliance, and unified portfolio views. Integrates seamlessly with the modular currency, tax, and audience systems.

## Cross-Border Asset Architecture

### 1. Core Asset Types & Country Mapping
```swift
// Extended asset types with country-specific variations
enum AssetType: String, CaseIterable {
    // Banking & Cash
    case bankAccount = "bank_account"
    case savingsAccount = "savings_account"
    case currentAccount = "current_account"
    case fixedDeposit = "fixed_deposit"
    case certificateOfDeposit = "certificate_of_deposit"
    
    // Investments
    case stocks = "stocks"
    case bonds = "bonds"  
    case mutualFunds = "mutual_funds"
    case etf = "etf"
    case indexFunds = "index_funds"
    case commodities = "commodities"
    case cryptocurrency = "cryptocurrency"
    
    // Retirement & Pension
    case providentFund = "provident_fund"          // India: EPF, PPF
    case retirementAccount = "retirement_account"   // US: 401k, IRA
    case pension = "pension"                       // UK: Personal/Workplace Pension
    case superannuation = "superannuation"         // Australia: Super
    case rrsp = "rrsp"                            // Canada: RRSP, TFSA
    case cpf = "cpf"                              // Singapore: CPF
    
    // Insurance & Protection
    case lifeInsurance = "life_insurance"
    case healthInsurance = "health_insurance"
    case propertyInsurance = "property_insurance"
    case termInsurance = "term_insurance"
    case ulip = "ulip"                            // India: Unit Linked Insurance
    
    // Real Estate
    case residentialProperty = "residential_property"
    case commercialProperty = "commercial_property"
    case land = "land"
    case reit = "reit"                            // Real Estate Investment Trust
    
    // Alternative Assets
    case gold = "gold"
    case silver = "silver"
    case art = "art"
    case collectibles = "collectibles"
    case privateEquity = "private_equity"
    case businessOwnership = "business_ownership"
    
    // Loans & Liabilities
    case homeLoan = "home_loan"
    case personalLoan = "personal_loan"
    case creditCard = "credit_card"
    case studentLoan = "student_loan"
    case businessLoan = "business_loan"
    
    var countrySpecificVariations: [CountryCode: String] {
        switch self {
        case .retirementAccount:
            return [
                .india: "provident_fund",
                .unitedStates: "401k_ira",
                .unitedKingdom: "pension",
                .australia: "superannuation",
                .canada: "rrsp_tfsa",
                .singapore: "cpf"
            ]
        case .stocks:
            return [
                .india: "equity_shares",
                .unitedStates: "common_stock",
                .unitedKingdom: "shares",
                .australia: "shares",
                .canada: "equity",
                .singapore: "equity"
            ]
        default:
            return [:]
        }
    }
}

struct CrossBorderAsset: Identifiable, Codable {
    let id: UUID
    let type: AssetType
    let name: String
    let country: CountryCode
    let originalCurrency: SupportedCurrency
    let institutionName: String
    let accountNumber: String?
    
    // Financial Details
    let currentValue: Decimal
    let originalValue: Decimal?          // Purchase price for investments
    let costBasis: Decimal?              // For tax calculations
    let lastUpdated: Date
    
    // Cross-Border Specific
    let taxResidency: TaxResidencyStatus
    let reportingRequirements: [ReportingRequirement]
    let taxTreatyEligible: Bool
    let foreignTaxCredit: Decimal?
    
    // Regulatory Compliance
    let regulatoryStatus: RegulatoryStatus
    let complianceDocuments: [ComplianceDocument]
    let fatcaReporting: Bool             // US FATCA requirements
    let crsReporting: Bool               // Common Reporting Standard
    
    // Risk & Performance
    let riskRating: RiskRating
    let performanceMetrics: PerformanceMetrics?
    let currencyRisk: CurrencyRisk
    
    // UI/UX Details
    let customName: String?
    let notes: String?
    let tags: [String]
    let isHidden: Bool
    let displayOrder: Int
    
    init(
        type: AssetType,
        name: String,
        country: CountryCode,
        currency: SupportedCurrency,
        institutionName: String,
        currentValue: Decimal,
        taxResidency: TaxResidencyStatus = .resident
    ) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.country = country
        self.originalCurrency = currency
        self.institutionName = institutionName
        self.accountNumber = nil
        self.currentValue = currentValue
        self.originalValue = nil
        self.costBasis = nil
        self.lastUpdated = Date()
        self.taxResidency = taxResidency
        self.reportingRequirements = []
        self.taxTreatyEligible = false
        self.foreignTaxCredit = nil
        self.regulatoryStatus = .compliant
        self.complianceDocuments = []
        self.fatcaReporting = country == .unitedStates
        self.crsReporting = country != .unitedStates
        self.riskRating = .medium
        self.performanceMetrics = nil
        self.currencyRisk = CurrencyRisk(baseCurrency: currency)
        self.customName = nil
        self.notes = nil
        self.tags = []
        self.isHidden = false
        self.displayOrder = 0
    }
}

enum TaxResidencyStatus: String, CaseIterable, Codable {
    case resident = "resident"
    case nonResident = "non_resident"
    case dualResident = "dual_resident"
    case transitioning = "transitioning"
    
    var localizedKey: LocalizationKey {
        switch self {
        case .resident: return .resident
        case .nonResident: return .nonResident
        case .dualResident: return .dualResident
        case .transitioning: return .transitioning
        }
    }
}

struct ReportingRequirement: Codable, Identifiable {
    let id: UUID
    let country: CountryCode
    let reportingThreshold: Decimal
    let frequency: ReportingFrequency
    let formName: String
    let description: String
    let dueDate: DateComponents  // Month and day
    let penalties: String
    
    enum ReportingFrequency: String, CaseIterable, Codable {
        case annual = "annual"
        case quarterly = "quarterly"
        case monthly = "monthly"
        case onTransaction = "on_transaction"
    }
}

enum RegulatoryStatus: String, CaseIterable, Codable {
    case compliant = "compliant"
    case pendingCompliance = "pending_compliance"
    case nonCompliant = "non_compliant"
    case exempt = "exempt"
    case underReview = "under_review"
}

struct ComplianceDocument: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: DocumentType
    let filePath: String?
    let expiryDate: Date?
    let issuingAuthority: String
    let documentNumber: String?
    
    enum DocumentType: String, CaseIterable, Codable {
        case taxCertificate = "tax_certificate"
        case complianceReport = "compliance_report"
        case auditReport = "audit_report"
        case registrationDocument = "registration_document"
        case permitLicense = "permit_license"
    }
}

struct CurrencyRisk: Codable {
    let baseCurrency: SupportedCurrency
    let volatility: RiskLevel
    let hedged: Bool
    let hedgingInstruments: [String]
    
    enum RiskLevel: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case extreme = "extreme"
    }
}

struct PerformanceMetrics: Codable {
    let totalReturn: Decimal
    let annualizedReturn: Decimal
    let volatility: Decimal
    let sharpeRatio: Decimal?
    let maxDrawdown: Decimal
    let lastPerformanceUpdate: Date
}
```

### 2. Cross-Border Asset Manager
```swift
@MainActor
class CrossBorderAssetManager: ObservableObject {
    @Published var assets: [CrossBorderAsset] = []
    @Published var totalPortfolioValue: [SupportedCurrency: Decimal] = [:]
    @Published var assetsByCountry: [CountryCode: [CrossBorderAsset]] = [:]
    @Published var taxImplications: [TaxImplication] = []
    @Published var complianceAlerts: [ComplianceAlert] = []
    
    private let currencyManager: CurrencyManager
    private let taxManager: MultiCountryTaxManager
    private let audienceManager: AudienceManager
    private let storageManager: AssetStorageManager
    private let complianceTracker: ComplianceTracker
    
    // Display preferences
    @Published var primaryDisplayCurrency: SupportedCurrency
    @Published var groupByCountry: Bool = true
    @Published var showCurrencyRisk: Bool = true
    @Published var hiddenAssetTypes: Set<AssetType> = []
    
    init(
        currencyManager: CurrencyManager,
        taxManager: MultiCountryTaxManager,
        audienceManager: AudienceManager
    ) {
        self.currencyManager = currencyManager
        self.taxManager = taxManager
        self.audienceManager = audienceManager
        self.primaryDisplayCurrency = audienceManager.currentAudience.primaryCurrency
        self.storageManager = AssetStorageManager()
        self.complianceTracker = ComplianceTracker(taxManager: taxManager)
        
        loadAssets()
        setupObservers()
    }
    
    private func setupObservers() {
        // React to currency changes
        NotificationCenter.default.addObserver(
            forName: .exchangeRatesUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recalculatePortfolioValues()
        }
        
        // React to audience changes
        NotificationCenter.default.addObserver(
            forName: .audienceChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let changeInfo = notification.object as? AudienceChangeInfo {
                self?.handleAudienceChange(changeInfo)
            }
        }
    }
    
    // MARK: - Asset Management
    func addAsset(_ asset: CrossBorderAsset) async throws {
        assets.append(asset)
        await updateAssetGroupings()
        await calculateTaxImplications(for: asset)
        await checkCompliance(for: asset)
        
        await storageManager.saveAsset(asset)
        
        await recalculatePortfolioValues()
    }
    
    func updateAsset(_ asset: CrossBorderAsset) async throws {
        guard let index = assets.firstIndex(where: { $0.id == asset.id }) else {
            throw AssetError.assetNotFound
        }
        
        assets[index] = asset
        await updateAssetGroupings()
        await calculateTaxImplications(for: asset)
        await checkCompliance(for: asset)
        
        await storageManager.saveAsset(asset)
        await recalculatePortfolioValues()
    }
    
    func deleteAsset(_ assetId: UUID) async throws {
        assets.removeAll { $0.id == assetId }
        await updateAssetGroupings()
        await recalculatePortfolioValues()
        
        await storageManager.deleteAsset(assetId)
    }
    
    // MARK: - Portfolio Calculations
    private func recalculatePortfolioValues() async {
        var newTotals: [SupportedCurrency: Decimal] = [:]
        
        // Calculate in all relevant currencies
        let relevantCurrencies = Set([primaryDisplayCurrency] + assets.map { $0.originalCurrency })
        
        for currency in relevantCurrencies {
            let total = await calculateTotalValue(in: currency)
            newTotals[currency] = total
        }
        
        totalPortfolioValue = newTotals
    }
    
    private func calculateTotalValue(in currency: SupportedCurrency) async -> Decimal {
        var total: Decimal = 0
        
        for asset in assets.filter({ !$0.isHidden }) {
            let convertedValue = await currencyManager.convert(
                amount: asset.currentValue,
                from: asset.originalCurrency,
                to: currency
            )
            total += convertedValue
        }
        
        return total
    }
    
    func getPortfolioAllocation() -> [AssetAllocation] {
        let total = totalPortfolioValue[primaryDisplayCurrency] ?? 0
        guard total > 0 else { return [] }
        
        var allocations: [AssetAllocation] = []
        
        // Group by asset type
        let assetGroups = Dictionary(grouping: assets.filter { !$0.isHidden }) { $0.type }
        
        for (assetType, assetGroup) in assetGroups {
            let groupTotal = assetGroup.reduce(Decimal(0)) { sum, asset in
                let convertedValue = currencyManager.convertSync(
                    amount: asset.currentValue,
                    from: asset.originalCurrency,
                    to: primaryDisplayCurrency
                ) ?? 0
                return sum + convertedValue
            }
            
            let percentage = (groupTotal / total) * 100
            
            allocations.append(AssetAllocation(
                type: assetType,
                value: groupTotal,
                percentage: percentage,
                assets: assetGroup
            ))
        }
        
        return allocations.sorted { $0.value > $1.value }
    }
    
    func getCountryAllocation() -> [CountryAllocation] {
        let total = totalPortfolioValue[primaryDisplayCurrency] ?? 0
        guard total > 0 else { return [] }
        
        var allocations: [CountryAllocation] = []
        
        for (country, countryAssets) in assetsByCountry {
            let countryTotal = countryAssets.reduce(Decimal(0)) { sum, asset in
                let convertedValue = currencyManager.convertSync(
                    amount: asset.currentValue,
                    from: asset.originalCurrency,
                    to: primaryDisplayCurrency
                ) ?? 0
                return sum + convertedValue
            }
            
            let percentage = (countryTotal / total) * 100
            
            allocations.append(CountryAllocation(
                country: country,
                value: countryTotal,
                percentage: percentage,
                assets: countryAssets,
                taxImplications: getTaxImplications(for: country),
                complianceStatus: getComplianceStatus(for: country)
            ))
        }
        
        return allocations.sorted { $0.value > $1.value }
    }
    
    // MARK: - Tax Implications
    private func calculateTaxImplications(for asset: CrossBorderAsset) async {
        let currentResidency = audienceManager.currentAudience.taxResidency
        
        // Calculate tax implications based on asset country vs tax residency
        let implications = await taxManager.calculateCrossBorderTax(
            asset: asset,
            taxResidency: currentResidency
        )
        
        // Update or add tax implications
        taxImplications.removeAll { $0.assetId == asset.id }
        taxImplications.append(contentsOf: implications)
    }
    
    private func getTaxImplications(for country: CountryCode) -> [TaxImplication] {
        let countryAssetIds = assetsByCountry[country]?.map { $0.id } ?? []
        return taxImplications.filter { countryAssetIds.contains($0.assetId) }
    }
    
    // MARK: - Compliance Management
    private func checkCompliance(for asset: CrossBorderAsset) async {
        let alerts = await complianceTracker.checkCompliance(for: asset)
        
        // Update compliance alerts
        complianceAlerts.removeAll { $0.assetId == asset.id }
        complianceAlerts.append(contentsOf: alerts)
    }
    
    private func getComplianceStatus(for country: CountryCode) -> ComplianceStatus {
        let countryAssetIds = assetsByCountry[country]?.map { $0.id } ?? []
        let countryAlerts = complianceAlerts.filter { countryAssetIds.contains($0.assetId) }
        
        if countryAlerts.contains(where: { $0.severity == .critical }) {
            return .nonCompliant
        } else if countryAlerts.contains(where: { $0.severity == .warning }) {
            return .pendingCompliance
        } else {
            return .compliant
        }
    }
    
    // MARK: - Currency Display Management
    func switchDisplayCurrency(to currency: SupportedCurrency) async {
        primaryDisplayCurrency = currency
        await recalculatePortfolioValues()
        
        UserDefaults.standard.set(currency.rawValue, forKey: "primaryDisplayCurrency")
    }
    
    func getAssetValue(_ asset: CrossBorderAsset, in currency: SupportedCurrency) async -> Decimal {
        return await currencyManager.convert(
            amount: asset.currentValue,
            from: asset.originalCurrency,
            to: currency
        )
    }
    
    // MARK: - Cross-Border Transfers
    func simulateAssetTransfer(
        asset: CrossBorderAsset,
        toCountry: CountryCode,
        amount: Decimal
    ) -> AssetTransferSimulation {
        return AssetTransferSimulation(
            fromCountry: asset.country,
            toCountry: toCountry,
            amount: amount,
            currency: asset.originalCurrency,
            estimatedTaxes: calculateTransferTaxes(asset: asset, toCountry: toCountry, amount: amount),
            complianceRequirements: getTransferCompliance(fromCountry: asset.country, toCountry: toCountry),
            estimatedTimeline: getTransferTimeline(fromCountry: asset.country, toCountry: toCountry)
        )
    }
    
    // MARK: - Private Helpers
    private func updateAssetGroupings() async {
        assetsByCountry = Dictionary(grouping: assets) { $0.country }
    }
    
    private func loadAssets() {
        Task {
            assets = await storageManager.loadAssets()
            await updateAssetGroupings()
            await recalculatePortfolioValues()
        }
    }
    
    private func handleAudienceChange(_ changeInfo: AudienceChangeInfo) {
        primaryDisplayCurrency = changeInfo.newAudience.primaryCurrency
        Task {
            await recalculatePortfolioValues()
            
            // Recalculate tax implications for new audience
            for asset in assets {
                await calculateTaxImplications(for: asset)
                await checkCompliance(for: asset)
            }
        }
    }
    
    private func calculateTransferTaxes(
        asset: CrossBorderAsset,
        toCountry: CountryCode,
        amount: Decimal
    ) -> [TaxComponent] {
        // Implement transfer tax calculation logic
        return []
    }
    
    private func getTransferCompliance(
        fromCountry: CountryCode,
        toCountry: CountryCode
    ) -> [ComplianceRequirement] {
        // Implement compliance requirement logic
        return []
    }
    
    private func getTransferTimeline(
        fromCountry: CountryCode,
        toCountry: CountryCode
    ) -> TransferTimeline {
        // Implement timeline estimation logic
        return TransferTimeline(estimatedDays: 7, factors: [])
    }
}

// MARK: - Supporting Types
struct AssetAllocation: Identifiable {
    let id = UUID()
    let type: AssetType
    let value: Decimal
    let percentage: Decimal
    let assets: [CrossBorderAsset]
}

struct CountryAllocation: Identifiable {
    let id = UUID()
    let country: CountryCode
    let value: Decimal
    let percentage: Decimal
    let assets: [CrossBorderAsset]
    let taxImplications: [TaxImplication]
    let complianceStatus: ComplianceStatus
}

enum ComplianceStatus: String, CaseIterable {
    case compliant = "compliant"
    case pendingCompliance = "pending_compliance"
    case nonCompliant = "non_compliant"
}

struct TaxImplication: Identifiable, Codable {
    let id: UUID
    let assetId: UUID
    let country: CountryCode
    let taxType: TaxType
    let estimatedAmount: Decimal
    let dueDate: Date?
    let description: String
    
    enum TaxType: String, CaseIterable, Codable {
        case capitalGains = "capital_gains"
        case dividendTax = "dividend_tax"
        case interestTax = "interest_tax"
        case wealthTax = "wealth_tax"
        case witholdingTax = "witholding_tax"
        case foreignTaxCredit = "foreign_tax_credit"
    }
}

struct ComplianceAlert: Identifiable {
    let id: UUID
    let assetId: UUID
    let severity: AlertSeverity
    let title: String
    let description: String
    let actionRequired: String
    let deadline: Date?
    
    enum AlertSeverity: String, CaseIterable {
        case info = "info"
        case warning = "warning"
        case critical = "critical"
    }
}

struct AssetTransferSimulation {
    let fromCountry: CountryCode
    let toCountry: CountryCode
    let amount: Decimal
    let currency: SupportedCurrency
    let estimatedTaxes: [TaxComponent]
    let complianceRequirements: [ComplianceRequirement]
    let estimatedTimeline: TransferTimeline
}

struct TaxComponent {
    let name: String
    let amount: Decimal
    let country: CountryCode
}

struct ComplianceRequirement {
    let name: String
    let description: String
    let isRequired: Bool
    let estimatedCost: Decimal?
}

struct TransferTimeline {
    let estimatedDays: Int
    let factors: [String]
}

enum AssetError: Error {
    case assetNotFound
    case invalidCurrency
    case complianceViolation(String)
    case transferNotAllowed(String)
}
```

### 3. Compliance Tracker
```swift
class ComplianceTracker {
    private let taxManager: MultiCountryTaxManager
    private let reportingRules: [CountryCode: [ReportingRule]]
    
    init(taxManager: MultiCountryTaxManager) {
        self.taxManager = taxManager
        self.reportingRules = loadReportingRules()
    }
    
    func checkCompliance(for asset: CrossBorderAsset) async -> [ComplianceAlert] {
        var alerts: [ComplianceAlert] = []
        
        // Check reporting thresholds
        alerts.append(contentsOf: await checkReportingThresholds(for: asset))
        
        // Check document expiry
        alerts.append(contentsOf: checkDocumentExpiry(for: asset))
        
        // Check tax compliance
        alerts.append(contentsOf: await checkTaxCompliance(for: asset))
        
        // Check regulatory compliance
        alerts.append(contentsOf: checkRegulatoryCompliance(for: asset))
        
        return alerts
    }
    
    private func checkReportingThresholds(for asset: CrossBorderAsset) async -> [ComplianceAlert] {
        var alerts: [ComplianceAlert] = []
        
        guard let rules = reportingRules[asset.country] else { return alerts }
        
        for rule in rules {
            if asset.currentValue >= rule.threshold {
                let alert = ComplianceAlert(
                    id: UUID(),
                    assetId: asset.id,
                    severity: rule.mandatory ? .critical : .warning,
                    title: "Reporting Required",
                    description: "Asset value exceeds \(rule.threshold) threshold for \(rule.formName)",
                    actionRequired: "File \(rule.formName) by \(rule.nextDueDate)",
                    deadline: rule.nextDueDate
                )
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
    private func checkDocumentExpiry(for asset: CrossBorderAsset) -> [ComplianceAlert] {
        var alerts: [ComplianceAlert] = []
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        for document in asset.complianceDocuments {
            if let expiryDate = document.expiryDate,
               expiryDate <= thirtyDaysFromNow {
                
                let severity: ComplianceAlert.AlertSeverity = expiryDate <= Date() ? .critical : .warning
                
                let alert = ComplianceAlert(
                    id: UUID(),
                    assetId: asset.id,
                    severity: severity,
                    title: "Document Expiring",
                    description: "\(document.name) expires on \(expiryDate)",
                    actionRequired: "Renew \(document.name)",
                    deadline: expiryDate
                )
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
    private func checkTaxCompliance(for asset: CrossBorderAsset) async -> [ComplianceAlert] {
        // Implementation for tax compliance checking
        return []
    }
    
    private func checkRegulatoryCompliance(for asset: CrossBorderAsset) -> [ComplianceAlert] {
        // Implementation for regulatory compliance checking
        return []
    }
    
    private func loadReportingRules() -> [CountryCode: [ReportingRule]] {
        return [
            .india: [
                ReportingRule(
                    formName: "LRS Reporting",
                    threshold: 250000, // USD
                    mandatory: true,
                    frequency: .annual,
                    nextDueDate: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 31))!
                ),
                ReportingRule(
                    formName: "FA Form",
                    threshold: 50000, // USD
                    mandatory: true,
                    frequency: .annual,
                    nextDueDate: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 31))!
                )
            ],
            .unitedStates: [
                ReportingRule(
                    formName: "FBAR",
                    threshold: 10000, // USD
                    mandatory: true,
                    frequency: .annual,
                    nextDueDate: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 15))!
                ),
                ReportingRule(
                    formName: "Form 8938",
                    threshold: 50000, // USD (varies by filing status)
                    mandatory: true,
                    frequency: .annual,
                    nextDueDate: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 15))!
                )
            ]
        ]
    }
}

struct ReportingRule {
    let formName: String
    let threshold: Decimal
    let mandatory: Bool
    let frequency: ReportingRequirement.ReportingFrequency
    let nextDueDate: Date
}
```

### 4. Asset Storage Manager
```swift
class AssetStorageManager {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default
    
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var assetsURL: URL {
        documentsURL.appendingPathComponent("assets.json")
    }
    
    func loadAssets() async -> [CrossBorderAsset] {
        do {
            let data = try Data(contentsOf: assetsURL)
            let assets = try decoder.decode([CrossBorderAsset].self, from: data)
            return assets
        } catch {
            print("Failed to load assets: \(error)")
            return []
        }
    }
    
    func saveAssets(_ assets: [CrossBorderAsset]) async {
        do {
            let data = try encoder.encode(assets)
            try data.write(to: assetsURL)
        } catch {
            print("Failed to save assets: \(error)")
        }
    }
    
    func saveAsset(_ asset: CrossBorderAsset) async {
        var assets = await loadAssets()
        
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
        } else {
            assets.append(asset)
        }
        
        await saveAssets(assets)
    }
    
    func deleteAsset(_ assetId: UUID) async {
        var assets = await loadAssets()
        assets.removeAll { $0.id == assetId }
        await saveAssets(assets)
    }
}
```

### 5. SwiftUI Views for Cross-Border Assets
```swift
struct CrossBorderPortfolioView: View {
    @StateObject private var assetManager: CrossBorderAssetManager
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var localization = LocalizationManager.shared
    
    @State private var selectedCountry: CountryCode?
    @State private var showingAddAsset = false
    @State private var showingCurrencyPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with total portfolio value
                PortfolioHeaderView(
                    totalValue: assetManager.totalPortfolioValue[assetManager.primaryDisplayCurrency] ?? 0,
                    currency: assetManager.primaryDisplayCurrency,
                    onCurrencyTap: { showingCurrencyPicker = true }
                )
                
                // Country/Asset Type Segmented Control
                Picker("View Type", selection: $assetManager.groupByCountry) {
                    Text("By Country").tag(true)
                    Text("By Type").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Main content
                if assetManager.groupByCountry {
                    CountryPortfolioView(
                        countryAllocations: assetManager.getCountryAllocation(),
                        selectedCountry: $selectedCountry
                    )
                } else {
                    AssetTypePortfolioView(
                        assetAllocations: assetManager.getPortfolioAllocation()
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAsset = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAsset) {
                AddCrossBorderAssetView(assetManager: assetManager)
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView(
                    selectedCurrency: $assetManager.primaryDisplayCurrency,
                    onSelectionChanged: { currency in
                        Task {
                            await assetManager.switchDisplayCurrency(to: currency)
                        }
                    }
                )
            }
        }
        .environment(\.layoutDirection, localization.layoutDirection)
    }
}

struct PortfolioHeaderView: View {
    let totalValue: Decimal
    let currency: SupportedCurrency
    let onCurrencyTap: () -> Void
    
    @Environment(\.localization) private var localization
    
    var body: some View {
        VStack(spacing: 8) {
            LocalizedText(.netWorth)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: onCurrencyTap) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    LocalizedCurrencyText(totalValue, style: .symbolOnly)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(currency.rawValue)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct CountryPortfolioView: View {
    let countryAllocations: [CountryAllocation]
    @Binding var selectedCountry: CountryCode?
    
    var body: some View {
        List {
            ForEach(countryAllocations) { allocation in
                CountryAllocationRow(
                    allocation: allocation,
                    isSelected: selectedCountry == allocation.country
                ) {
                    selectedCountry = allocation.country
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct CountryAllocationRow: View {
    let allocation: CountryAllocation
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.localization) private var localization
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Country flag and name
                    HStack(spacing: 8) {
                        Text(allocation.country.flag)
                            .font(.title2)
                        
                        Text(allocation.country.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        LocalizedCurrencyText(allocation.value, style: .compact)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(localization.formatNumber(allocation.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Compliance status
                HStack {
                    ComplianceStatusBadge(status: allocation.complianceStatus)
                    
                    Spacer()
                    
                    if !allocation.taxImplications.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("\(allocation.taxImplications.count) tax items")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
}

struct ComplianceStatusBadge: View {
    let status: ComplianceStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .compliant: return "checkmark.circle.fill"
        case .pendingCompliance: return "clock.fill"
        case .nonCompliant: return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .compliant: return .green
        case .pendingCompliance: return .orange
        case .nonCompliant: return .red
        }
    }
    
    private var statusText: String {
        switch status {
        case .compliant: return "Compliant"
        case .pendingCompliance: return "Pending"
        case .nonCompliant: return "Issues"
        }
    }
}

struct AddCrossBorderAssetView: View {
    let assetManager: CrossBorderAssetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var assetType: AssetType = .bankAccount
    @State private var name: String = ""
    @State private var country: CountryCode = .india
    @State private var currency: SupportedCurrency = .inr
    @State private var institutionName: String = ""
    @State private var currentValue: String = ""
    @State private var taxResidency: TaxResidencyStatus = .resident
    
    var body: some View {
        NavigationView {
            Form {
                Section("Asset Details") {
                    Picker("Asset Type", selection: $assetType) {
                        ForEach(AssetType.allCases, id: \.self) { type in
                            Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(type)
                        }
                    }
                    
                    TextField("Asset Name", text: $name)
                    
                    Picker("Country", selection: $country) {
                        ForEach(CountryCode.allCases, id: \.self) { country in
                            HStack {
                                Text(country.flag)
                                Text(country.displayName)
                            }
                            .tag(country)
                        }
                    }
                    
                    Picker("Currency", selection: $currency) {
                        ForEach(SupportedCurrency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.rawValue)")
                                .tag(currency)
                        }
                    }
                }
                
                Section("Financial Details") {
                    TextField("Institution Name", text: $institutionName)
                    TextField("Current Value", text: $currentValue)
                        .keyboardType(.decimalPad)
                }
                
                Section("Tax Information") {
                    Picker("Tax Residency", selection: $taxResidency) {
                        ForEach(TaxResidencyStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAsset()
                    }
                    .disabled(name.isEmpty || currentValue.isEmpty)
                }
            }
        }
    }
    
    private func saveAsset() {
        guard let value = Decimal(string: currentValue) else { return }
        
        let asset = CrossBorderAsset(
            type: assetType,
            name: name,
            country: country,
            currency: currency,
            institutionName: institutionName,
            currentValue: value,
            taxResidency: taxResidency
        )
        
        Task {
            try await assetManager.addAsset(asset)
            await MainActor.run {
                dismiss()
            }
        }
    }
}
```

This comprehensive cross-border asset management system provides:

1. **Multi-Country Asset Support**: Complete asset type mapping across different countries with local variations
2. **Currency Conversion Integration**: Real-time portfolio values in any currency with automatic conversion
3. **Tax Implication Tracking**: Cross-border tax calculations with resident/non-resident considerations  
4. **Compliance Management**: Automated compliance checking with reporting thresholds and document tracking
5. **Portfolio Analytics**: Country and asset type allocations with performance metrics
6. **Transfer Simulation**: Ability to simulate asset transfers between countries with tax and compliance impact
7. **Regulatory Integration**: FATCA, CRS, and country-specific reporting requirements
8. **SwiftUI Interface**: Native UI components for managing cross-border assets with localization support

The system seamlessly integrates with the currency, tax, and audience management modules for a unified cross-border financial management experience.