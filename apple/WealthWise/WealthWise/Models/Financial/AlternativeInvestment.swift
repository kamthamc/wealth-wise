//
//  AlternativeInvestment.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Alternative Investments Module - Issue #5
//

import Foundation
import SwiftData

/// Base protocol for alternative investment types
public protocol AlternativeInvestmentProtocol: Sendable {
    var id: UUID { get }
    var name: String { get }
    var assetType: AssetType { get }
    var purchaseDate: Date { get }
    var purchasePrice: Decimal { get }
    var currentValue: Decimal { get }
    var currency: String { get }
    var valuationHistory: [ValuationRecord] { get }
    var incomeHistory: [IncomeRecord] { get }
    var documents: [SecureDocument] { get }
}

// MARK: - Real Estate Property

/// Comprehensive real estate property tracking model
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class RealEstateProperty {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var propertyDescription: String?
    public var assetType: AssetType
    
    // MARK: - Property Details
    
    public var propertyType: PropertyType
    public var address: PropertyAddress
    public var totalArea: Decimal // in sq ft or sq meters
    public var areaUnit: AreaUnit
    public var numberOfBedrooms: Int?
    public var numberOfBathrooms: Int?
    
    // MARK: - Financial Details
    
    public var purchaseDate: Date
    public var purchasePrice: Decimal
    public var currentValue: Decimal
    public var currency: String
    public var stampDutyPaid: Decimal?
    public var registrationFees: Decimal?
    public var otherAcquisitionCosts: Decimal?
    
    // MARK: - Rental Income
    
    public var isRented: Bool
    public var monthlyRent: Decimal?
    public var rentalYield: Decimal? // Annual rental income / property value
    public var tenantName: String?
    public var leaseStartDate: Date?
    public var leaseEndDate: Date?
    
    // MARK: - Loan Details
    
    public var hasLoan: Bool
    public var loanAmount: Decimal?
    public var outstandingLoan: Decimal?
    public var monthlyEMI: Decimal?
    public var loanProvider: String?
    public var interestRate: Decimal?
    
    // MARK: - History and Tracking
    
    public var valuationHistory: [ValuationRecord]
    public var incomeHistory: [IncomeRecord]
    public var maintenanceHistory: [MaintenanceRecord]
    public var documents: [SecureDocument]
    
    // MARK: - Metadata
    
    public var notes: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        propertyDescription: String? = nil,
        assetType: AssetType = .realEstateResidential,
        propertyType: PropertyType,
        address: PropertyAddress,
        totalArea: Decimal,
        areaUnit: AreaUnit = .squareFeet,
        purchaseDate: Date,
        purchasePrice: Decimal,
        currentValue: Decimal,
        currency: String = "INR",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.propertyDescription = propertyDescription
        self.assetType = assetType
        self.propertyType = propertyType
        self.address = address
        self.totalArea = totalArea
        self.areaUnit = areaUnit
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currentValue = currentValue
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize rental details
        self.isRented = false
        
        // Initialize loan details
        self.hasLoan = false
        
        // Initialize collections
        self.valuationHistory = []
        self.incomeHistory = []
        self.maintenanceHistory = []
        self.documents = []
        self.tags = []
    }
    
    // MARK: - Computed Properties
    
    /// Total cost of acquisition including all fees
    public var totalAcquisitionCost: Decimal {
        var total = purchasePrice
        if let stampDuty = stampDutyPaid {
            total += stampDuty
        }
        if let registrationFee = registrationFees {
            total += registrationFee
        }
        if let otherCosts = otherAcquisitionCosts {
            total += otherCosts
        }
        return total
    }
    
    /// Current equity (property value - outstanding loan)
    public var currentEquity: Decimal {
        guard let outstanding = outstandingLoan else {
            return currentValue
        }
        return currentValue - outstanding
    }
    
    /// Capital appreciation since purchase
    public var capitalAppreciation: Decimal {
        return currentValue - purchasePrice
    }
    
    /// Capital appreciation percentage
    public var capitalAppreciationPercentage: Double {
        guard purchasePrice > 0 else { return 0 }
        return Double(truncating: ((capitalAppreciation / purchasePrice) * 100) as NSDecimalNumber)
    }
    
    /// Annual rental income (12 months)
    public var annualRentalIncome: Decimal {
        guard let rent = monthlyRent else { return 0 }
        return rent * 12
    }
    
    /// Total rental income received
    public var totalRentalIncome: Decimal {
        return incomeHistory
            .filter { $0.incomeType == .rent }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate rental yield
    public var calculatedRentalYield: Double {
        guard currentValue > 0, let rent = monthlyRent else { return 0 }
        let annualRent = rent * 12
        return Double(truncating: ((annualRent / currentValue) * 100) as NSDecimalNumber)
    }
    
    // MARK: - Business Logic Methods
    
    /// Update property valuation
    @MainActor
    public func updateValuation(newValue: Decimal, valuationDate: Date = Date(), notes: String? = nil) {
        let previousValue = currentValue
        currentValue = newValue
        updatedAt = Date()
        
        let record = ValuationRecord(
            date: valuationDate,
            value: newValue,
            previousValue: previousValue,
            changeAmount: newValue - previousValue,
            changePercentage: Double(truncating: (((newValue - previousValue) / previousValue) * 100) as NSDecimalNumber),
            valuationType: .manual,
            notes: notes
        )
        valuationHistory.append(record)
        
        // Update rental yield if property is rented
        if isRented {
            rentalYield = calculatedRentalYield
        }
    }
    
    /// Record rental income
    @MainActor
    public func recordRentalIncome(amount: Decimal, date: Date = Date(), description: String? = nil) {
        let record = IncomeRecord(
            date: date,
            amount: amount,
            incomeType: .rent,
            description: description ?? NSLocalizedString("rental_income", comment: "Monthly rental income"),
            currency: currency
        )
        incomeHistory.append(record)
        updatedAt = Date()
    }
    
    /// Record maintenance expense
    @MainActor
    public func recordMaintenance(amount: Decimal, date: Date = Date(), description: String, category: MaintenanceCategory) {
        let record = MaintenanceRecord(
            date: date,
            amount: amount,
            category: category,
            description: description,
            currency: currency
        )
        maintenanceHistory.append(record)
        updatedAt = Date()
    }
    
    /// Update rental information
    @MainActor
    public func updateRentalInfo(
        isRented: Bool,
        monthlyRent: Decimal? = nil,
        tenantName: String? = nil,
        leaseStartDate: Date? = nil,
        leaseEndDate: Date? = nil
    ) {
        self.isRented = isRented
        self.monthlyRent = monthlyRent
        self.tenantName = tenantName
        self.leaseStartDate = leaseStartDate
        self.leaseEndDate = leaseEndDate
        
        if isRented, monthlyRent != nil {
            self.rentalYield = calculatedRentalYield
        }
        
        updatedAt = Date()
    }
    
    /// Update loan information
    @MainActor
    public func updateLoanInfo(
        hasLoan: Bool,
        loanAmount: Decimal? = nil,
        outstandingLoan: Decimal? = nil,
        monthlyEMI: Decimal? = nil,
        loanProvider: String? = nil,
        interestRate: Decimal? = nil
    ) {
        self.hasLoan = hasLoan
        self.loanAmount = loanAmount
        self.outstandingLoan = outstandingLoan
        self.monthlyEMI = monthlyEMI
        self.loanProvider = loanProvider
        self.interestRate = interestRate
        updatedAt = Date()
    }
    
    /// Attach document
    @MainActor
    public func attachDocument(
        fileName: String,
        fileType: DocumentType,
        filePath: String,
        encryptionKey: String,
        fileSize: Int
    ) {
        let document = SecureDocument(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            encryptionKey: encryptionKey,
            fileSize: fileSize
        )
        documents.append(document)
        updatedAt = Date()
    }
}

// MARK: - Commodity Investment

/// Physical commodity investment tracking (gold, silver, etc.)
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Commodity {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var commodityDescription: String?
    public var assetType: AssetType
    
    // MARK: - Commodity Details
    
    public var commodityType: CommodityType
    public var weight: Decimal
    public var weightUnit: WeightUnit
    public var purity: Decimal? // e.g., 24K gold = 99.9% pure
    public var form: CommodityForm
    
    // MARK: - Financial Details
    
    public var purchaseDate: Date
    public var purchasePrice: Decimal
    public var pricePerUnit: Decimal // Price per gram/ounce
    public var currentValue: Decimal
    public var currentMarketPrice: Decimal? // Current market price per unit
    public var currency: String
    
    // MARK: - Storage Details
    
    public var storageLocation: StorageLocation
    public var isInsured: Bool
    public var insuranceValue: Decimal?
    public var insuranceProvider: String?
    
    // MARK: - Purchase Details
    
    public var vendorName: String?
    public var invoiceNumber: String?
    public var hallmarkDetails: String?
    
    // MARK: - History and Tracking
    
    public var valuationHistory: [ValuationRecord]
    public var documents: [SecureDocument]
    
    // MARK: - Metadata
    
    public var notes: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        commodityDescription: String? = nil,
        assetType: AssetType = .goldPhysical,
        commodityType: CommodityType,
        weight: Decimal,
        weightUnit: WeightUnit = .grams,
        purity: Decimal? = nil,
        form: CommodityForm,
        purchaseDate: Date,
        purchasePrice: Decimal,
        pricePerUnit: Decimal,
        currentValue: Decimal,
        currency: String = "INR",
        storageLocation: StorageLocation = .homeLocker,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.commodityDescription = commodityDescription
        self.assetType = assetType
        self.commodityType = commodityType
        self.weight = weight
        self.weightUnit = weightUnit
        self.purity = purity
        self.form = form
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.pricePerUnit = pricePerUnit
        self.currentValue = currentValue
        self.currency = currency
        self.storageLocation = storageLocation
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize flags
        self.isInsured = false
        
        // Initialize collections
        self.valuationHistory = []
        self.documents = []
        self.tags = []
    }
    
    // MARK: - Computed Properties
    
    /// Capital appreciation since purchase
    public var capitalAppreciation: Decimal {
        return currentValue - purchasePrice
    }
    
    /// Capital appreciation percentage
    public var capitalAppreciationPercentage: Double {
        guard purchasePrice > 0 else { return 0 }
        return Double(truncating: ((capitalAppreciation / purchasePrice) * 100) as NSDecimalNumber)
    }
    
    /// Current value per unit
    public var currentValuePerUnit: Decimal {
        guard weight > 0 else { return 0 }
        return currentValue / weight
    }
    
    /// Price appreciation per unit
    public var priceAppreciationPerUnit: Decimal {
        return currentValuePerUnit - pricePerUnit
    }
    
    // MARK: - Business Logic Methods
    
    /// Update commodity valuation based on current market price
    @MainActor
    public func updateValuation(marketPricePerUnit: Decimal, valuationDate: Date = Date(), notes: String? = nil) {
        let previousValue = currentValue
        currentMarketPrice = marketPricePerUnit
        currentValue = marketPricePerUnit * weight
        updatedAt = Date()
        
        let record = ValuationRecord(
            date: valuationDate,
            value: currentValue,
            previousValue: previousValue,
            changeAmount: currentValue - previousValue,
            changePercentage: Double(truncating: (((currentValue - previousValue) / previousValue) * 100) as NSDecimalNumber),
            valuationType: .marketPrice,
            notes: notes
        )
        valuationHistory.append(record)
    }
    
    /// Update insurance information
    @MainActor
    public func updateInsurance(
        isInsured: Bool,
        insuranceValue: Decimal? = nil,
        insuranceProvider: String? = nil
    ) {
        self.isInsured = isInsured
        self.insuranceValue = insuranceValue
        self.insuranceProvider = insuranceProvider
        updatedAt = Date()
    }
    
    /// Attach document (purchase invoice, hallmark certificate, etc.)
    @MainActor
    public func attachDocument(
        fileName: String,
        fileType: DocumentType,
        filePath: String,
        encryptionKey: String,
        fileSize: Int
    ) {
        let document = SecureDocument(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            encryptionKey: encryptionKey,
            fileSize: fileSize
        )
        documents.append(document)
        updatedAt = Date()
    }
}

// MARK: - Bond Investment

/// Bond investment tracking model
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Bond {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var bondDescription: String?
    public var assetType: AssetType
    
    // MARK: - Bond Details
    
    public var bondType: BondType
    public var issuer: String
    public var isin: String?
    public var faceValue: Decimal
    public var quantity: Decimal
    
    // MARK: - Financial Details
    
    public var purchaseDate: Date
    public var purchasePrice: Decimal
    public var currentValue: Decimal
    public var currency: String
    
    // MARK: - Interest Details
    
    public var couponRate: Decimal // Annual interest rate percentage
    public var interestPaymentFrequency: InterestFrequency
    public var nextInterestDate: Date?
    public var maturityDate: Date
    
    // MARK: - Yield Calculations
    
    public var currentYield: Decimal? // Annual interest / current market price
    public var yieldToMaturity: Decimal? // IRR considering all future cash flows
    
    // MARK: - Rating and Risk
    
    public var creditRating: String?
    public var ratingAgency: String?
    public var riskLevel: RiskLevel
    
    // MARK: - History and Tracking
    
    public var valuationHistory: [ValuationRecord]
    public var incomeHistory: [IncomeRecord]
    public var documents: [SecureDocument]
    
    // MARK: - Metadata
    
    public var notes: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        bondDescription: String? = nil,
        assetType: AssetType = .governmentBonds,
        bondType: BondType,
        issuer: String,
        isin: String? = nil,
        faceValue: Decimal,
        quantity: Decimal,
        purchaseDate: Date,
        purchasePrice: Decimal,
        currentValue: Decimal,
        currency: String = "INR",
        couponRate: Decimal,
        interestPaymentFrequency: InterestFrequency,
        maturityDate: Date,
        riskLevel: RiskLevel = .low,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bondDescription = bondDescription
        self.assetType = assetType
        self.bondType = bondType
        self.issuer = issuer
        self.isin = isin
        self.faceValue = faceValue
        self.quantity = quantity
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currentValue = currentValue
        self.currency = currency
        self.couponRate = couponRate
        self.interestPaymentFrequency = interestPaymentFrequency
        self.maturityDate = maturityDate
        self.riskLevel = riskLevel
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize collections
        self.valuationHistory = []
        self.incomeHistory = []
        self.documents = []
        self.tags = []
    }
    
    // MARK: - Computed Properties
    
    /// Total face value (face value * quantity)
    public var totalFaceValue: Decimal {
        return faceValue * quantity
    }
    
    /// Annual interest income
    public var annualInterestIncome: Decimal {
        return (totalFaceValue * couponRate) / 100
    }
    
    /// Days to maturity
    public var daysToMaturity: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: maturityDate).day ?? 0
    }
    
    /// Years to maturity
    public var yearsToMaturity: Double {
        return Double(daysToMaturity) / 365.25
    }
    
    /// Total interest received
    public var totalInterestReceived: Decimal {
        return incomeHistory
            .filter { $0.incomeType == .interest }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate current yield
    public var calculatedCurrentYield: Double {
        guard currentValue > 0 else { return 0 }
        return Double(truncating: ((annualInterestIncome / currentValue) * 100) as NSDecimalNumber)
    }
    
    // MARK: - Business Logic Methods
    
    /// Update bond valuation
    @MainActor
    public func updateValuation(newValue: Decimal, valuationDate: Date = Date(), notes: String? = nil) {
        let previousValue = currentValue
        currentValue = newValue
        currentYield = calculatedCurrentYield
        updatedAt = Date()
        
        let record = ValuationRecord(
            date: valuationDate,
            value: newValue,
            previousValue: previousValue,
            changeAmount: newValue - previousValue,
            changePercentage: Double(truncating: (((newValue - previousValue) / previousValue) * 100) as NSDecimalNumber),
            valuationType: .marketPrice,
            notes: notes
        )
        valuationHistory.append(record)
    }
    
    /// Record interest payment
    @MainActor
    public func recordInterestPayment(amount: Decimal, date: Date = Date(), description: String? = nil) {
        let record = IncomeRecord(
            date: date,
            amount: amount,
            incomeType: .interest,
            description: description ?? NSLocalizedString("bond_interest_payment", comment: "Bond interest payment"),
            currency: currency
        )
        incomeHistory.append(record)
        
        // Calculate next interest date
        if let currentNextDate = nextInterestDate {
            nextInterestDate = calculateNextInterestDate(from: currentNextDate)
        }
        
        updatedAt = Date()
    }
    
    /// Calculate next interest payment date
    private func calculateNextInterestDate(from currentDate: Date) -> Date? {
        let calendar = Calendar.current
        switch interestPaymentFrequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: currentDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: currentDate)
        case .halfYearly:
            return calendar.date(byAdding: .month, value: 6, to: currentDate)
        case .annually:
            return calendar.date(byAdding: .year, value: 1, to: currentDate)
        case .atMaturity:
            return maturityDate
        }
    }
    
    /// Attach document
    @MainActor
    public func attachDocument(
        fileName: String,
        fileType: DocumentType,
        filePath: String,
        encryptionKey: String,
        fileSize: Int
    ) {
        let document = SecureDocument(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            encryptionKey: encryptionKey,
            fileSize: fileSize
        )
        documents.append(document)
        updatedAt = Date()
    }
}

// MARK: - Chit Fund Investment

/// Traditional Indian chit fund tracking model
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class ChitFund {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var chitDescription: String?
    public var assetType: AssetType
    
    // MARK: - Chit Fund Details
    
    public var organizer: String
    public var totalMembers: Int
    public var chitValue: Decimal // Total chit amount
    public var monthlyContribution: Decimal
    public var duration: Int // Number of months
    
    // MARK: - Timeline
    
    public var startDate: Date
    public var endDate: Date
    public var currentMonth: Int
    
    // MARK: - Financial Details
    
    public var totalContributed: Decimal
    public var totalPayoutsReceived: Decimal
    public var currency: String
    
    // MARK: - Auction Details
    
    public var hasReceivedPayout: Bool
    public var payoutMonth: Int?
    public var payoutAmount: Decimal?
    public var discountReceived: Decimal? // Benefit received from discount
    
    // MARK: - Status
    
    public var isActive: Bool
    public var isCompleted: Bool
    public var completedAt: Date?
    
    // MARK: - History and Tracking
    
    public var contributionHistory: [ChitContribution]
    public var payoutHistory: [IncomeRecord]
    public var auctionHistory: [ChitAuction]
    public var documents: [SecureDocument]
    
    // MARK: - Metadata
    
    public var notes: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        chitDescription: String? = nil,
        assetType: AssetType = .chitFunds,
        organizer: String,
        totalMembers: Int,
        chitValue: Decimal,
        monthlyContribution: Decimal,
        duration: Int,
        startDate: Date,
        currency: String = "INR",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.chitDescription = chitDescription
        self.assetType = assetType
        self.organizer = organizer
        self.totalMembers = totalMembers
        self.chitValue = chitValue
        self.monthlyContribution = monthlyContribution
        self.duration = duration
        self.startDate = startDate
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Calculate end date
        self.endDate = Calendar.current.date(byAdding: .month, value: duration, to: startDate) ?? startDate
        
        // Initialize financial tracking
        self.totalContributed = 0
        self.totalPayoutsReceived = 0
        self.currentMonth = 1
        
        // Initialize status
        self.isActive = true
        self.isCompleted = false
        self.hasReceivedPayout = false
        
        // Initialize collections
        self.contributionHistory = []
        self.payoutHistory = []
        self.auctionHistory = []
        self.documents = []
        self.tags = []
    }
    
    // MARK: - Computed Properties
    
    /// Expected total contributions
    public var expectedTotalContributions: Decimal {
        return monthlyContribution * Decimal(duration)
    }
    
    /// Remaining contributions
    public var remainingContributions: Decimal {
        return expectedTotalContributions - totalContributed
    }
    
    /// Months remaining
    public var monthsRemaining: Int {
        return max(0, duration - currentMonth + 1)
    }
    
    /// Net benefit (payouts received - contributions made)
    public var netBenefit: Decimal {
        return totalPayoutsReceived - totalContributed
    }
    
    /// Return on investment percentage
    public var returnPercentage: Double {
        guard totalContributed > 0 else { return 0 }
        return Double(truncating: ((netBenefit / totalContributed) * 100) as NSDecimalNumber)
    }
    
    // MARK: - Business Logic Methods
    
    /// Record monthly contribution
    @MainActor
    public func recordContribution(amount: Decimal, month: Int, date: Date = Date(), notes: String? = nil) {
        let contribution = ChitContribution(
            month: month,
            amount: amount,
            date: date,
            notes: notes
        )
        contributionHistory.append(contribution)
        totalContributed += amount
        currentMonth = max(currentMonth, month)
        updatedAt = Date()
    }
    
    /// Record chit payout received
    @MainActor
    public func recordPayout(amount: Decimal, month: Int, discount: Decimal, date: Date = Date(), notes: String? = nil) {
        hasReceivedPayout = true
        payoutMonth = month
        payoutAmount = amount
        discountReceived = discount
        
        let record = IncomeRecord(
            date: date,
            amount: amount,
            incomeType: .chitPayout,
            description: notes ?? NSLocalizedString("chit_payout", comment: "Chit fund payout received"),
            currency: currency
        )
        payoutHistory.append(record)
        totalPayoutsReceived += amount
        updatedAt = Date()
    }
    
    /// Record auction details
    @MainActor
    public func recordAuction(month: Int, winnerName: String, bidAmount: Decimal, discount: Decimal, date: Date = Date()) {
        let auction = ChitAuction(
            month: month,
            winnerName: winnerName,
            bidAmount: bidAmount,
            discount: discount,
            date: date
        )
        auctionHistory.append(auction)
        updatedAt = Date()
    }
    
    /// Mark chit fund as completed
    @MainActor
    public func markAsCompleted() {
        isCompleted = true
        isActive = false
        completedAt = Date()
        updatedAt = Date()
    }
    
    /// Attach document
    @MainActor
    public func attachDocument(
        fileName: String,
        fileType: DocumentType,
        filePath: String,
        encryptionKey: String,
        fileSize: Int
    ) {
        let document = SecureDocument(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            encryptionKey: encryptionKey,
            fileSize: fileSize
        )
        documents.append(document)
        updatedAt = Date()
    }
}

// MARK: - Supporting Types

/// Property type classification
public enum PropertyType: String, CaseIterable, Codable, Sendable {
    case apartment = "apartment"
    case villa = "villa"
    case plotLand = "plot_land"
    case commercialOffice = "commercial_office"
    case commercialShop = "commercial_shop"
    case warehouse = "warehouse"
    case agricultural = "agricultural"
    case industrial = "industrial"
    
    public var displayName: String {
        switch self {
        case .apartment:
            return NSLocalizedString("property_type_apartment", comment: "Apartment property type")
        case .villa:
            return NSLocalizedString("property_type_villa", comment: "Villa property type")
        case .plotLand:
            return NSLocalizedString("property_type_plot", comment: "Plot/Land property type")
        case .commercialOffice:
            return NSLocalizedString("property_type_office", comment: "Commercial office property type")
        case .commercialShop:
            return NSLocalizedString("property_type_shop", comment: "Commercial shop property type")
        case .warehouse:
            return NSLocalizedString("property_type_warehouse", comment: "Warehouse property type")
        case .agricultural:
            return NSLocalizedString("property_type_agricultural", comment: "Agricultural property type")
        case .industrial:
            return NSLocalizedString("property_type_industrial", comment: "Industrial property type")
        }
    }
}

/// Property address
public struct PropertyAddress: Codable, Sendable {
    public let street: String?
    public let city: String
    public let state: String
    public let country: String
    public let postalCode: String?
    public let landmark: String?
    
    public init(
        street: String? = nil,
        city: String,
        state: String,
        country: String = "India",
        postalCode: String? = nil,
        landmark: String? = nil
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.landmark = landmark
    }
    
    public var fullAddress: String {
        var components: [String] = []
        if let street = street { components.append(street) }
        components.append(city)
        components.append(state)
        if let postalCode = postalCode { components.append(postalCode) }
        components.append(country)
        return components.joined(separator: ", ")
    }
}

/// Area measurement unit
public enum AreaUnit: String, CaseIterable, Codable, Sendable {
    case squareFeet = "sq_ft"
    case squareMeters = "sq_m"
    case acres = "acres"
    case hectares = "hectares"
    
    public var displayName: String {
        switch self {
        case .squareFeet:
            return NSLocalizedString("area_sq_ft", comment: "Square feet")
        case .squareMeters:
            return NSLocalizedString("area_sq_m", comment: "Square meters")
        case .acres:
            return NSLocalizedString("area_acres", comment: "Acres")
        case .hectares:
            return NSLocalizedString("area_hectares", comment: "Hectares")
        }
    }
}

/// Commodity type
public enum CommodityType: String, CaseIterable, Codable, Sendable {
    case gold = "gold"
    case silver = "silver"
    case platinum = "platinum"
    case palladium = "palladium"
    case diamond = "diamond"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .gold:
            return NSLocalizedString("commodity_gold", comment: "Gold commodity")
        case .silver:
            return NSLocalizedString("commodity_silver", comment: "Silver commodity")
        case .platinum:
            return NSLocalizedString("commodity_platinum", comment: "Platinum commodity")
        case .palladium:
            return NSLocalizedString("commodity_palladium", comment: "Palladium commodity")
        case .diamond:
            return NSLocalizedString("commodity_diamond", comment: "Diamond commodity")
        case .other:
            return NSLocalizedString("commodity_other", comment: "Other commodity")
        }
    }
}

/// Weight measurement unit
public enum WeightUnit: String, CaseIterable, Codable, Sendable {
    case grams = "grams"
    case kilograms = "kg"
    case ounces = "oz"
    case pounds = "lbs"
    
    public var displayName: String {
        switch self {
        case .grams:
            return NSLocalizedString("weight_grams", comment: "Grams")
        case .kilograms:
            return NSLocalizedString("weight_kg", comment: "Kilograms")
        case .ounces:
            return NSLocalizedString("weight_oz", comment: "Ounces")
        case .pounds:
            return NSLocalizedString("weight_lbs", comment: "Pounds")
        }
    }
}

/// Commodity form
public enum CommodityForm: String, CaseIterable, Codable, Sendable {
    case jewelry = "jewelry"
    case coins = "coins"
    case bars = "bars"
    case bullion = "bullion"
    case ornaments = "ornaments"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .jewelry:
            return NSLocalizedString("form_jewelry", comment: "Jewelry form")
        case .coins:
            return NSLocalizedString("form_coins", comment: "Coins form")
        case .bars:
            return NSLocalizedString("form_bars", comment: "Bars form")
        case .bullion:
            return NSLocalizedString("form_bullion", comment: "Bullion form")
        case .ornaments:
            return NSLocalizedString("form_ornaments", comment: "Ornaments form")
        case .other:
            return NSLocalizedString("form_other", comment: "Other form")
        }
    }
}

/// Storage location
public enum StorageLocation: String, CaseIterable, Codable, Sendable {
    case homeLocker = "home_locker"
    case bankLocker = "bank_locker"
    case vaultStorage = "vault_storage"
    case jewelerCustody = "jeweler_custody"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .homeLocker:
            return NSLocalizedString("storage_home_locker", comment: "Home locker storage")
        case .bankLocker:
            return NSLocalizedString("storage_bank_locker", comment: "Bank locker storage")
        case .vaultStorage:
            return NSLocalizedString("storage_vault", comment: "Vault storage")
        case .jewelerCustody:
            return NSLocalizedString("storage_jeweler", comment: "Jeweler custody")
        case .other:
            return NSLocalizedString("storage_other", comment: "Other storage")
        }
    }
}

/// Bond type
public enum BondType: String, CaseIterable, Codable, Sendable {
    case governmentBond = "government_bond"
    case corporateBond = "corporate_bond"
    case municipalBond = "municipal_bond"
    case treasuryBond = "treasury_bond"
    case savingsBond = "savings_bond"
    case zeroCouponBond = "zero_coupon_bond"
    case convertibleBond = "convertible_bond"
    
    public var displayName: String {
        switch self {
        case .governmentBond:
            return NSLocalizedString("bond_government", comment: "Government bond")
        case .corporateBond:
            return NSLocalizedString("bond_corporate", comment: "Corporate bond")
        case .municipalBond:
            return NSLocalizedString("bond_municipal", comment: "Municipal bond")
        case .treasuryBond:
            return NSLocalizedString("bond_treasury", comment: "Treasury bond")
        case .savingsBond:
            return NSLocalizedString("bond_savings", comment: "Savings bond")
        case .zeroCouponBond:
            return NSLocalizedString("bond_zero_coupon", comment: "Zero coupon bond")
        case .convertibleBond:
            return NSLocalizedString("bond_convertible", comment: "Convertible bond")
        }
    }
}

/// Interest payment frequency
public enum InterestFrequency: String, CaseIterable, Codable, Sendable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case halfYearly = "half_yearly"
    case annually = "annually"
    case atMaturity = "at_maturity"
    
    public var displayName: String {
        switch self {
        case .monthly:
            return NSLocalizedString("frequency_monthly", comment: "Monthly frequency")
        case .quarterly:
            return NSLocalizedString("frequency_quarterly", comment: "Quarterly frequency")
        case .halfYearly:
            return NSLocalizedString("frequency_half_yearly", comment: "Half-yearly frequency")
        case .annually:
            return NSLocalizedString("frequency_annually", comment: "Annual frequency")
        case .atMaturity:
            return NSLocalizedString("frequency_at_maturity", comment: "At maturity frequency")
        }
    }
}

/// Risk level
public enum RiskLevel: String, CaseIterable, Codable, Sendable {
    case veryLow = "very_low"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    public var displayName: String {
        switch self {
        case .veryLow:
            return NSLocalizedString("risk_very_low", comment: "Very low risk")
        case .low:
            return NSLocalizedString("risk_low", comment: "Low risk")
        case .medium:
            return NSLocalizedString("risk_medium", comment: "Medium risk")
        case .high:
            return NSLocalizedString("risk_high", comment: "High risk")
        case .veryHigh:
            return NSLocalizedString("risk_very_high", comment: "Very high risk")
        }
    }
}

/// Valuation record for tracking value changes
public struct ValuationRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let value: Decimal
    public let previousValue: Decimal
    public let changeAmount: Decimal
    public let changePercentage: Double
    public let valuationType: ValuationType
    public let notes: String?
    
    public init(
        id: UUID = UUID(),
        date: Date,
        value: Decimal,
        previousValue: Decimal,
        changeAmount: Decimal,
        changePercentage: Double,
        valuationType: ValuationType,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.previousValue = previousValue
        self.changeAmount = changeAmount
        self.changePercentage = changePercentage
        self.valuationType = valuationType
        self.notes = notes
    }
}

/// Valuation type
public enum ValuationType: String, CaseIterable, Codable, Sendable {
    case manual = "manual"
    case marketPrice = "market_price"
    case appraisal = "appraisal"
    case automated = "automated"
}

/// Income record for tracking rental income, interest, etc.
public struct IncomeRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let amount: Decimal
    public let incomeType: IncomeType
    public let description: String?
    public let currency: String
    
    public init(
        id: UUID = UUID(),
        date: Date,
        amount: Decimal,
        incomeType: IncomeType,
        description: String? = nil,
        currency: String = "INR"
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.incomeType = incomeType
        self.description = description
        self.currency = currency
    }
}

/// Income type
public enum IncomeType: String, CaseIterable, Codable, Sendable {
    case rent = "rent"
    case interest = "interest"
    case dividend = "dividend"
    case chitPayout = "chit_payout"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .rent:
            return NSLocalizedString("income_rent", comment: "Rental income")
        case .interest:
            return NSLocalizedString("income_interest", comment: "Interest income")
        case .dividend:
            return NSLocalizedString("income_dividend", comment: "Dividend income")
        case .chitPayout:
            return NSLocalizedString("income_chit_payout", comment: "Chit fund payout")
        case .other:
            return NSLocalizedString("income_other", comment: "Other income")
        }
    }
}

/// Maintenance record for property maintenance
public struct MaintenanceRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let amount: Decimal
    public let category: MaintenanceCategory
    public let description: String
    public let currency: String
    
    public init(
        id: UUID = UUID(),
        date: Date,
        amount: Decimal,
        category: MaintenanceCategory,
        description: String,
        currency: String = "INR"
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
        self.currency = currency
    }
}

/// Maintenance category
public enum MaintenanceCategory: String, CaseIterable, Codable, Sendable {
    case repair = "repair"
    case renovation = "renovation"
    case painting = "painting"
    case plumbing = "plumbing"
    case electrical = "electrical"
    case cleaning = "cleaning"
    case landscaping = "landscaping"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .repair:
            return NSLocalizedString("maintenance_repair", comment: "Repair maintenance")
        case .renovation:
            return NSLocalizedString("maintenance_renovation", comment: "Renovation maintenance")
        case .painting:
            return NSLocalizedString("maintenance_painting", comment: "Painting maintenance")
        case .plumbing:
            return NSLocalizedString("maintenance_plumbing", comment: "Plumbing maintenance")
        case .electrical:
            return NSLocalizedString("maintenance_electrical", comment: "Electrical maintenance")
        case .cleaning:
            return NSLocalizedString("maintenance_cleaning", comment: "Cleaning maintenance")
        case .landscaping:
            return NSLocalizedString("maintenance_landscaping", comment: "Landscaping maintenance")
        case .other:
            return NSLocalizedString("maintenance_other", comment: "Other maintenance")
        }
    }
}

/// Chit contribution record
public struct ChitContribution: Codable, Sendable, Identifiable {
    public let id: UUID
    public let month: Int
    public let amount: Decimal
    public let date: Date
    public let notes: String?
    
    public init(
        id: UUID = UUID(),
        month: Int,
        amount: Decimal,
        date: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.month = month
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}

/// Chit auction record
public struct ChitAuction: Codable, Sendable, Identifiable {
    public let id: UUID
    public let month: Int
    public let winnerName: String
    public let bidAmount: Decimal
    public let discount: Decimal
    public let date: Date
    
    public init(
        id: UUID = UUID(),
        month: Int,
        winnerName: String,
        bidAmount: Decimal,
        discount: Decimal,
        date: Date
    ) {
        self.id = id
        self.month = month
        self.winnerName = winnerName
        self.bidAmount = bidAmount
        self.discount = discount
        self.date = date
    }
}

/// Secure document with encryption support
public struct SecureDocument: Codable, Sendable, Identifiable {
    public let id: UUID
    public let fileName: String
    public let fileType: DocumentType
    public let filePath: String
    public let encryptionKey: String
    public let fileSize: Int
    public let uploadDate: Date
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        fileType: DocumentType,
        filePath: String,
        encryptionKey: String,
        fileSize: Int,
        uploadDate: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.filePath = filePath
        self.encryptionKey = encryptionKey
        self.fileSize = fileSize
        self.uploadDate = uploadDate
    }
}

/// Document type
public enum DocumentType: String, CaseIterable, Codable, Sendable {
    case saleAgreement = "sale_agreement"
    case titleDeed = "title_deed"
    case propertyTax = "property_tax"
    case insurance = "insurance"
    case invoice = "invoice"
    case hallmarkCertificate = "hallmark_certificate"
    case bondCertificate = "bond_certificate"
    case chitAgreement = "chit_agreement"
    case photo = "photo"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .saleAgreement:
            return NSLocalizedString("doc_sale_agreement", comment: "Sale agreement document")
        case .titleDeed:
            return NSLocalizedString("doc_title_deed", comment: "Title deed document")
        case .propertyTax:
            return NSLocalizedString("doc_property_tax", comment: "Property tax document")
        case .insurance:
            return NSLocalizedString("doc_insurance", comment: "Insurance document")
        case .invoice:
            return NSLocalizedString("doc_invoice", comment: "Invoice document")
        case .hallmarkCertificate:
            return NSLocalizedString("doc_hallmark", comment: "Hallmark certificate")
        case .bondCertificate:
            return NSLocalizedString("doc_bond_certificate", comment: "Bond certificate")
        case .chitAgreement:
            return NSLocalizedString("doc_chit_agreement", comment: "Chit agreement")
        case .photo:
            return NSLocalizedString("doc_photo", comment: "Photo document")
        case .other:
            return NSLocalizedString("doc_other", comment: "Other document")
        }
    }
}
