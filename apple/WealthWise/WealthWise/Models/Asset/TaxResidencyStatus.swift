import Foundation

/// Tax residency status classification for cross-border asset compliance
/// Handles multi-jurisdiction tax obligations and compliance requirements
public final class TaxResidencyStatus: Sendable, Codable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var countryCode: String
    public var residencyType: ResidencyType
    public var taxYear: String // Format: "FY2024-25" for India, "2024" for others
    public var effectiveDate: Date
    public var expiryDate: Date?
    public var isActive: Bool
    
    // MARK: - Documentation
    
    public var documentType: ResidencyDocumentType
    public var documentNumber: String?
    public var issuingAuthority: String?
    public var verificationStatus: DocumentVerificationStatus
    
    // MARK: - Compliance
    
    public var complianceObligations: Set<ComplianceObligation>
    public var reportingThresholds: [String: Decimal] // Currency -> Threshold amount
    public var withholdingTaxRates: [String: Double] // Asset type -> Rate percentage
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    public var notes: String?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        countryCode: String,
        residencyType: ResidencyType,
        taxYear: String,
        effectiveDate: Date,
        documentType: ResidencyDocumentType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.countryCode = countryCode
        self.residencyType = residencyType
        self.taxYear = taxYear
        self.effectiveDate = effectiveDate
        self.documentType = documentType
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isActive = true
        self.verificationStatus = .pending
        self.complianceObligations = Set()
        self.reportingThresholds = [:]
        self.withholdingTaxRates = [:]
        
        // Set default compliance obligations based on residency type
        setupDefaultComplianceObligations()
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultComplianceObligations() {
        switch residencyType {
        case .taxResident:
            complianceObligations.insert(.incomeTaxFiling)
            complianceObligations.insert(.capitalGainsTaxReporting)
            complianceObligations.insert(.foreignAssetReporting)
            
        case .nonResidentOrdinary:
            complianceObligations.insert(.withholdingTaxCompliance)
            complianceObligations.insert(.limitedTaxFiling)
            
        case .nonResidentNotOrdinary:
            complianceObligations.insert(.withholdingTaxCompliance)
            
        case .dualResident:
            complianceObligations.insert(.incomeTaxFiling)
            complianceObligations.insert(.foreignAssetReporting)
            complianceObligations.insert(.treatyBenefitClaims)
            complianceObligations.insert(.tieBreakingRuleCompliance)
        }
        
        // Country-specific obligations
        setupCountrySpecificObligations()
    }
    
    private func setupCountrySpecificObligations() {
        switch countryCode.uppercased() {
        case "IN": // India
            complianceObligations.insert(.liberalizedRemittanceScheme)
            reportingThresholds["USD"] = 250000 // LRS annual limit
            
        case "US": // United States
            complianceObligations.insert(.fatcaCompliance)
            complianceObligations.insert(.fbardReporting)
            reportingThresholds["USD"] = 10000 // FBAR threshold
            
        case "GB", "UK": // United Kingdom
            complianceObligations.insert(.overseasIncomeReporting)
            reportingThresholds["GBP"] = 2000 // Income threshold
            
        case "CA": // Canada
            complianceObligations.insert(.foreignIncomeVerification)
            reportingThresholds["CAD"] = 100000 // Foreign property threshold
            
        case "AU": // Australia
            complianceObligations.insert(.foreignIncomeReporting)
            reportingThresholds["AUD"] = 50000 // Foreign income threshold
            
        case "SG": // Singapore
            complianceObligations.insert(.foreignIncomeExemption)
            
        default:
            break
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether this residency status is currently valid
    public var isValid: Bool {
        guard isActive else { return false }
        if let expiry = expiryDate {
            return Date() < expiry
        }
        return true
    }
    
    /// Days until expiry (if applicable)
    public var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: expiry).day
    }
    
    /// Whether renewal is required soon
    public var requiresRenewal: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days <= 90 // Notify 90 days before expiry
    }
    
    /// Get applicable withholding tax rate for asset type
    public func getWithholdingTaxRate(for assetType: String) -> Double? {
        return withholdingTaxRates[assetType]
    }
    
    /// Get reporting threshold for currency
    public func getReportingThreshold(for currency: String) -> Decimal? {
        return reportingThresholds[currency]
    }
}

// MARK: - Supporting Enums

/// Type of tax residency
public enum ResidencyType: String, CaseIterable, Codable, Sendable {
    case taxResident = "taxResident"
    case nonResidentOrdinary = "nonResidentOrdinary"
    case nonResidentNotOrdinary = "nonResidentNotOrdinary"
    case dualResident = "dualResident"
    
    public var displayName: String {
        switch self {
        case .taxResident:
            return "Tax Resident"
        case .nonResidentOrdinary:
            return "Non-Resident Ordinary"
        case .nonResidentNotOrdinary:
            return "Non-Resident Not Ordinarily Resident"
        case .dualResident:
            return "Dual Tax Resident"
        }
    }
    
    public var description: String {
        switch self {
        case .taxResident:
            return "Full tax obligations in the country"
        case .nonResidentOrdinary:
            return "Limited tax obligations for residents returning from abroad"
        case .nonResidentNotOrdinary:
            return "Minimal tax obligations for non-residents"
        case .dualResident:
            return "Tax resident in multiple countries requiring treaty benefits"
        }
    }
}

/// Type of residency documentation
public enum ResidencyDocumentType: String, CaseIterable, Codable, Sendable {
    case taxResidencyCertificate = "taxResidencyCertificate"
    case formW8 = "formW8"
    case form15G = "form15G"
    case form15H = "form15H"
    case treatyBenefitClaim = "treatyBenefitClaim"
    case nonResidencyDeclaration = "nonResidencyDeclaration"
    case dualResidencyDeclaration = "dualResidencyDeclaration"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .taxResidencyCertificate:
            return "Tax Residency Certificate"
        case .formW8:
            return "Form W-8 (US)"
        case .form15G:
            return "Form 15G (India)"
        case .form15H:
            return "Form 15H (India)"
        case .treatyBenefitClaim:
            return "Treaty Benefit Claim"
        case .nonResidencyDeclaration:
            return "Non-Residency Declaration"
        case .dualResidencyDeclaration:
            return "Dual Residency Declaration"
        case .other:
            return "Other Documentation"
        }
    }
}

/// Document verification status
public enum DocumentVerificationStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case verified = "verified"
    case rejected = "rejected"
    case expired = "expired"
    case renewed = "renewed"
    
    public var displayName: String {
        switch self {
        case .pending:
            return "Pending Verification"
        case .verified:
            return "Verified"
        case .rejected:
            return "Rejected"
        case .expired:
            return "Expired"
        case .renewed:
            return "Renewed"
        }
    }
    
    public var isValid: Bool {
        return self == .verified || self == .renewed
    }
}

/// Compliance obligations for different residency types
public enum ComplianceObligation: String, CaseIterable, Codable, Sendable {
    // General Tax Obligations
    case incomeTaxFiling = "incomeTaxFiling"
    case capitalGainsTaxReporting = "capitalGainsTaxReporting"
    case withholdingTaxCompliance = "withholdingTaxCompliance"
    case limitedTaxFiling = "limitedTaxFiling"
    
    // Foreign Asset Reporting
    case foreignAssetReporting = "foreignAssetReporting"
    case foreignIncomeReporting = "foreignIncomeReporting"
    case overseasIncomeReporting = "overseasIncomeReporting"
    case foreignIncomeVerification = "foreignIncomeVerification"
    case foreignIncomeExemption = "foreignIncomeExemption"
    
    // Country-Specific
    case liberalizedRemittanceScheme = "liberalizedRemittanceScheme" // India LRS
    case fatcaCompliance = "fatcaCompliance" // US FATCA
    case fbardReporting = "fbardReporting" // US FBAR
    
    // Treaty and Dual Residency
    case treatyBenefitClaims = "treatyBenefitClaims"
    case tieBreakingRuleCompliance = "tieBreakingRuleCompliance"
    
    public var displayName: String {
        switch self {
        case .incomeTaxFiling:
            return "Income Tax Filing"
        case .capitalGainsTaxReporting:
            return "Capital Gains Tax Reporting"
        case .withholdingTaxCompliance:
            return "Withholding Tax Compliance"
        case .limitedTaxFiling:
            return "Limited Tax Filing"
        case .foreignAssetReporting:
            return "Foreign Asset Reporting"
        case .foreignIncomeReporting:
            return "Foreign Income Reporting"
        case .overseasIncomeReporting:
            return "Overseas Income Reporting"
        case .foreignIncomeVerification:
            return "Foreign Income Verification"
        case .foreignIncomeExemption:
            return "Foreign Income Exemption"
        case .liberalizedRemittanceScheme:
            return "LRS Compliance (India)"
        case .fatcaCompliance:
            return "FATCA Compliance (US)"
        case .fbardReporting:
            return "FBAR Reporting (US)"
        case .treatyBenefitClaims:
            return "Treaty Benefit Claims"
        case .tieBreakingRuleCompliance:
            return "Tie-Breaking Rule Compliance"
        }
    }
    
    public var description: String {
        switch self {
        case .incomeTaxFiling:
            return "Required to file annual income tax returns"
        case .capitalGainsTaxReporting:
            return "Report capital gains from asset sales"
        case .withholdingTaxCompliance:
            return "Comply with withholding tax on income"
        case .limitedTaxFiling:
            return "Limited tax filing for specific income types"
        case .foreignAssetReporting:
            return "Report foreign assets above threshold"
        case .liberalizedRemittanceScheme:
            return "Comply with India's $250,000 annual overseas investment limit"
        case .fatcaCompliance:
            return "Comply with US Foreign Account Tax Compliance Act"
        case .fbardReporting:
            return "Report Foreign Bank and Financial Accounts to US Treasury"
        case .treatyBenefitClaims:
            return "Claim benefits under tax treaties between countries"
        case .tieBreakingRuleCompliance:
            return "Apply tie-breaking rules for dual tax residents"
        default:
            return displayName
        }
    }
}

// MARK: - Codable Implementation
extension TaxResidencyStatus {
    enum CodingKeys: CodingKey {
        case id, countryCode, residencyType, taxYear, effectiveDate, expiryDate, isActive
        case documentType, documentNumber, issuingAuthority, verificationStatus
        case complianceObligations, reportingThresholds, withholdingTaxRates
        case createdAt, updatedAt, notes
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(residencyType, forKey: .residencyType)
        try container.encode(taxYear, forKey: .taxYear)
        try container.encode(effectiveDate, forKey: .effectiveDate)
        try container.encodeIfPresent(expiryDate, forKey: .expiryDate)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(documentType, forKey: .documentType)
        try container.encodeIfPresent(documentNumber, forKey: .documentNumber)
        try container.encodeIfPresent(issuingAuthority, forKey: .issuingAuthority)
        try container.encode(verificationStatus, forKey: .verificationStatus)
        try container.encode(Array(complianceObligations), forKey: .complianceObligations)
        try container.encode(reportingThresholds, forKey: .reportingThresholds)
        try container.encode(withholdingTaxRates, forKey: .withholdingTaxRates)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let countryCode = try container.decode(String.self, forKey: .countryCode)
        let residencyType = try container.decode(ResidencyType.self, forKey: .residencyType)
        let taxYear = try container.decode(String.self, forKey: .taxYear)
        let effectiveDate = try container.decode(Date.self, forKey: .effectiveDate)
        let documentType = try container.decode(ResidencyDocumentType.self, forKey: .documentType)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        self.init(
            id: id,
            countryCode: countryCode,
            residencyType: residencyType,
            taxYear: taxYear,
            effectiveDate: effectiveDate,
            documentType: documentType,
            createdAt: createdAt
        )
        
        self.expiryDate = try container.decodeIfPresent(Date.self, forKey: .expiryDate)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
        self.issuingAuthority = try container.decodeIfPresent(String.self, forKey: .issuingAuthority)
        self.verificationStatus = try container.decode(DocumentVerificationStatus.self, forKey: .verificationStatus)
        self.complianceObligations = Set(try container.decode([ComplianceObligation].self, forKey: .complianceObligations))
        self.reportingThresholds = try container.decode([String: Decimal].self, forKey: .reportingThresholds)
        self.withholdingTaxRates = try container.decode([String: Double].self, forKey: .withholdingTaxRates)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

// MARK: - Extensions

extension TaxResidencyStatus {
    
    /// Update compliance obligations when residency status changes
    public func updateComplianceObligations() {
        complianceObligations.removeAll()
        setupDefaultComplianceObligations()
        updatedAt = Date()
    }
    
    /// Add custom compliance obligation
    public func addComplianceObligation(_ obligation: ComplianceObligation) {
        complianceObligations.insert(obligation)
        updatedAt = Date()
    }
    
    /// Remove compliance obligation
    public func removeComplianceObligation(_ obligation: ComplianceObligation) {
        complianceObligations.remove(obligation)
        updatedAt = Date()
    }
    
    /// Set withholding tax rate for specific asset type
    public func setWithholdingTaxRate(_ rate: Double, for assetType: String) {
        withholdingTaxRates[assetType] = rate
        updatedAt = Date()
    }
    
    /// Set reporting threshold for currency
    public func setReportingThreshold(_ threshold: Decimal, for currency: String) {
        reportingThresholds[currency] = threshold
        updatedAt = Date()
    }
    
    /// Mark document as verified
    public func markDocumentVerified() {
        verificationStatus = .verified
        updatedAt = Date()
    }
    
    /// Mark document as expired and requiring renewal
    public func markDocumentExpired() {
        verificationStatus = .expired
        isActive = false
        updatedAt = Date()
    }
    
    /// Renew document with new expiry date
    public func renewDocument(expiryDate: Date? = nil) {
        self.expiryDate = expiryDate
        verificationStatus = .renewed
        isActive = true
        updatedAt = Date()
    }
}

// MARK: - Hashable & Equatable
extension TaxResidencyStatus: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: TaxResidencyStatus, rhs: TaxResidencyStatus) -> Bool {
        return lhs.id == rhs.id
    }
}