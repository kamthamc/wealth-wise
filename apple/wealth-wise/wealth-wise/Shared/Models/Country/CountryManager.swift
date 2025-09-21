import Foundation

/// Manages country and audience-specific configurations for WealthWise
public class CountryManager {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let currentCountryKey = "WealthWise.CurrentCountry"
    private let preferredCountriesKey = "WealthWise.PreferredCountries"
    
    @Published public private(set) var currentCountry: Country
    @Published public private(set) var preferredCountries: [Country]
    @Published public private(set) var availableCountries: [Country]
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.availableCountries = SupportedCountries.allCountries
        
        // Load current country from storage or detect from locale
        if let countryData = userDefaults.data(forKey: currentCountryKey),
           let storedCountry = try? JSONDecoder().decode(Country.self, from: countryData) {
            self.currentCountry = storedCountry
        } else {
            self.currentCountry = SupportedCountries.preferredCountry(for: Locale.current)
        }
        
        // Load preferred countries
        if let countriesData = userDefaults.data(forKey: preferredCountriesKey),
           let storedCountries = try? JSONDecoder().decode([Country].self, from: countriesData) {
            self.preferredCountries = storedCountries
        } else {
            // Default to current country and major markets
            self.preferredCountries = [
                currentCountry,
                SupportedCountries.unitedStates,
                SupportedCountries.unitedKingdom
            ].uniqued()
        }
    }
    
    // MARK: - Country Management
    
    /// Sets the current country and saves to persistent storage
    public func setCurrentCountry(_ country: Country) {
        currentCountry = country
        saveCurrentCountry()
        
        // Add to preferred countries if not already present
        if !preferredCountries.contains(where: { $0.id == country.id }) {
            preferredCountries.append(country)
            savePreferredCountries()
        }
    }
    
    /// Adds a country to the preferred list
    public func addPreferredCountry(_ country: Country) {
        if !preferredCountries.contains(where: { $0.id == country.id }) {
            preferredCountries.append(country)
            savePreferredCountries()
        }
    }
    
    /// Removes a country from the preferred list (cannot remove current country)
    public func removePreferredCountry(_ country: Country) {
        guard country.id != currentCountry.id else { return }
        
        preferredCountries.removeAll { $0.id == country.id }
        savePreferredCountries()
    }
    
    /// Reorders preferred countries
    public func reorderPreferredCountries(_ countries: [Country]) {
        // Ensure current country is always included
        var newOrder = countries
        if !newOrder.contains(where: { $0.id == currentCountry.id }) {
            newOrder.insert(currentCountry, at: 0)
        }
        
        preferredCountries = newOrder
        savePreferredCountries()
    }
    
    // MARK: - Country Discovery
    
    /// Automatically detects suitable countries based on user's locale and preferences
    public func detectSuitableCountries() -> [Country] {
        let locale = Locale.current
        var suggestions: [Country] = []
        
        // Add country matching current locale
        let localeCountry = SupportedCountries.preferredCountry(for: locale)
        suggestions.append(localeCountry)
        
        // Add countries in same region
        let regionCountries = SupportedCountries.countries(in: localeCountry.region)
        suggestions.append(contentsOf: regionCountries)
        
        // Add countries with same regulatory zone
        let regulatoryCountries = SupportedCountries.countries(with: localeCountry.regulatoryZone)
        suggestions.append(contentsOf: regulatoryCountries)
        
        // Add major financial markets
        suggestions.append(contentsOf: [
            SupportedCountries.unitedStates,
            SupportedCountries.unitedKingdom,
            SupportedCountries.singapore
        ])
        
        return suggestions.uniqued()
    }
    
    /// Finds countries that support a specific currency
    public func countries(supporting currency: SupportedCurrency) -> [Country] {
        return availableCountries.filter { country in
            country.primaryCurrency == currency || 
            country.secondaryCurrencies.contains(currency)
        }
    }
    
    /// Finds countries that support a specific investment type
    public func countries(supporting investmentType: InvestmentType) -> [Country] {
        return availableCountries.filter { $0.supports(investmentType: investmentType) }
    }
    
    /// Finds countries with specific banking features
    public func countries(with bankingFeature: BankingFeatureType) -> [Country] {
        return availableCountries.filter { country in
            switch bankingFeature {
            case .upi:
                return country.bankingFeatures.hasUPI
            case .openBanking:
                return country.bankingFeatures.hasOpenBanking
            case .instantTransfers:
                return country.bankingFeatures.hasInstantTransfers
            case .wireTransfers:
                return country.bankingFeatures.hasWireTransfers
            case .ach:
                return country.bankingFeatures.hasACH
            case .sepa:
                return country.bankingFeatures.hasSEPA
            case .rtgs:
                return country.bankingFeatures.hasRTGS
            case .neft:
                return country.bankingFeatures.hasNEFT
            case .interac:
                return country.bankingFeatures.hasInterac
            }
        }
    }
    
    // MARK: - Cultural Preferences
    
    /// Returns the appropriate date formatter for the current country
    public func dateFormatter(style: DateFormatter.Style = .medium) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        
        switch currentCountry.culturalPreferences.dateFormat {
        case .monthDayYear:
            formatter.locale = Locale(identifier: "en_US")
        case .dayMonthYear:
            formatter.locale = Locale(identifier: "en_GB")
        case .yearMonthDay:
            formatter.locale = Locale(identifier: "en_CA") // Uses ISO format
        }
        
        return formatter
    }
    
    /// Returns the appropriate time formatter for the current country
    public func timeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        
        switch currentCountry.culturalPreferences.timeFormat {
        case .twelve:
            formatter.dateFormat = "h:mm a"
        case .twentyFour:
            formatter.dateFormat = "HH:mm"
        }
        
        return formatter
    }
    
    /// Returns the current financial year for the current country
    public func currentFinancialYear() -> Int {
        return currentCountry.currentFinancialYear()
    }
    
    /// Returns working days for the current country
    public func workingDays() -> [Weekday] {
        return currentCountry.culturalPreferences.workingDays
    }
    
    /// Checks if a given date is a working day in the current country
    public func isWorkingDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        let weekdayMapping: [Int: Weekday] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        
        guard let day = weekdayMapping[weekday] else { return false }
        return currentCountry.culturalPreferences.workingDays.contains(day)
    }
    
    // MARK: - Investment Recommendations
    
    /// Returns investment recommendations based on current country and risk tolerance
    public func recommendedInvestments(for riskTolerance: RiskTolerance? = nil) -> [InvestmentType] {
        let tolerance = riskTolerance ?? currentCountry.culturalPreferences.investmentRiskTolerance
        return currentCountry.recommendedInvestments(for: tolerance)
    }
    
    /// Returns investment types grouped by category for the current country
    public func investmentsByCategory() -> [InvestmentCategory: [InvestmentType]] {
        var grouped: [InvestmentCategory: [InvestmentType]] = [:]
        
        for investmentType in currentCountry.commonInvestmentTypes {
            let category = investmentType.category
            if grouped[category] == nil {
                grouped[category] = []
            }
            grouped[category]?.append(investmentType)
        }
        
        return grouped
    }
    
    // MARK: - Compliance & Regulatory
    
    /// Returns whether explicit consent is required for data processing
    public func requiresExplicitConsent() -> Bool {
        return currentCountry.regulatoryZone.requiresExplicitConsent
    }
    
    /// Returns data retention limit for the current regulatory zone
    public func dataRetentionLimit() -> TimeInterval? {
        return currentCountry.regulatoryZone.dataRetentionLimit
    }
    
    /// Returns compliance requirements for the current country
    public func complianceRequirements() -> ComplianceRequirements {
        let zone = currentCountry.regulatoryZone
        
        return ComplianceRequirements(
            regulatoryZone: zone,
            requiresExplicitConsent: zone.requiresExplicitConsent,
            dataRetentionLimit: zone.dataRetentionLimit,
            allowsDataExport: true, // WealthWise allows local backup export
            requiresPrivacyPolicy: true,
            requiresTermsOfService: true,
            allowsCookies: false, // Native app, no cookies
            requiresDataProcessingAgreement: zone == .gdpr
        )
    }
    
    // MARK: - Persistence
    
    private func saveCurrentCountry() {
        if let data = try? JSONEncoder().encode(currentCountry) {
            userDefaults.set(data, forKey: currentCountryKey)
        }
    }
    
    private func savePreferredCountries() {
        if let data = try? JSONEncoder().encode(preferredCountries) {
            userDefaults.set(data, forKey: preferredCountriesKey)
        }
    }
    
    // MARK: - Reset
    
    /// Resets all country preferences and re-detects from locale
    public func resetToDefaults() {
        userDefaults.removeObject(forKey: currentCountryKey)
        userDefaults.removeObject(forKey: preferredCountriesKey)
        
        currentCountry = SupportedCountries.preferredCountry(for: Locale.current)
        preferredCountries = [
            currentCountry,
            SupportedCountries.unitedStates,
            SupportedCountries.unitedKingdom
        ].uniqued()
        
        saveCurrentCountry()
        savePreferredCountries()
    }
}

// MARK: - Supporting Types

public enum BankingFeatureType {
    case upi
    case openBanking
    case instantTransfers
    case wireTransfers
    case ach
    case sepa
    case rtgs
    case neft
    case interac
}

public struct ComplianceRequirements {
    public let regulatoryZone: RegulatoryZone
    public let requiresExplicitConsent: Bool
    public let dataRetentionLimit: TimeInterval?
    public let allowsDataExport: Bool
    public let requiresPrivacyPolicy: Bool
    public let requiresTermsOfService: Bool
    public let allowsCookies: Bool
    public let requiresDataProcessingAgreement: Bool
    
    public init(
        regulatoryZone: RegulatoryZone,
        requiresExplicitConsent: Bool,
        dataRetentionLimit: TimeInterval?,
        allowsDataExport: Bool,
        requiresPrivacyPolicy: Bool,
        requiresTermsOfService: Bool,
        allowsCookies: Bool,
        requiresDataProcessingAgreement: Bool
    ) {
        self.regulatoryZone = regulatoryZone
        self.requiresExplicitConsent = requiresExplicitConsent
        self.dataRetentionLimit = dataRetentionLimit
        self.allowsDataExport = allowsDataExport
        self.requiresPrivacyPolicy = requiresPrivacyPolicy
        self.requiresTermsOfService = requiresTermsOfService
        self.allowsCookies = allowsCookies
        self.requiresDataProcessingAgreement = requiresDataProcessingAgreement
    }
}

// MARK: - Extensions

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}