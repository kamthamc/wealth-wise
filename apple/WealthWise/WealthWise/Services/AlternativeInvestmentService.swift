//
//  AlternativeInvestmentService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Alternative Investments Service - Issue #5
//

import Foundation
import SwiftData

/// Service for managing alternative investments
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class AlternativeInvestmentService {
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Real Estate Operations
    
    /// Create a new real estate property
    public func createRealEstateProperty(_ property: RealEstateProperty) throws {
        modelContext.insert(property)
        try modelContext.save()
    }
    
    /// Fetch all real estate properties
    public func fetchRealEstateProperties() throws -> [RealEstateProperty] {
        let descriptor = FetchDescriptor<RealEstateProperty>(
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch properties by type
    public func fetchRealEstateProperties(ofType type: PropertyType) throws -> [RealEstateProperty] {
        let descriptor = FetchDescriptor<RealEstateProperty>(
            predicate: #Predicate { property in
                property.propertyType == type
            },
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch rented properties
    public func fetchRentedProperties() throws -> [RealEstateProperty] {
        let descriptor = FetchDescriptor<RealEstateProperty>(
            predicate: #Predicate { property in
                property.isRented == true
            },
            sortBy: [SortDescriptor(\.monthlyRent, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Update property valuation
    public func updatePropertyValuation(
        propertyId: UUID,
        newValue: Decimal,
        notes: String? = nil
    ) throws {
        let descriptor = FetchDescriptor<RealEstateProperty>(
            predicate: #Predicate { property in
                property.id == propertyId
            }
        )
        guard let property = try modelContext.fetch(descriptor).first else {
            throw AlternativeInvestmentError.propertyNotFound
        }
        
        property.updateValuation(newValue: newValue, notes: notes)
        try modelContext.save()
    }
    
    /// Delete real estate property
    public func deleteRealEstateProperty(_ property: RealEstateProperty) throws {
        modelContext.delete(property)
        try modelContext.save()
    }
    
    /// Calculate total real estate value
    public func calculateTotalRealEstateValue() throws -> Decimal {
        let properties = try fetchRealEstateProperties()
        return properties.reduce(0) { $0 + $1.currentValue }
    }
    
    /// Calculate total rental income
    public func calculateTotalRentalIncome() throws -> Decimal {
        let rentedProperties = try fetchRentedProperties()
        return rentedProperties.reduce(0) { total, property in
            total + (property.monthlyRent ?? 0) * 12
        }
    }
    
    // MARK: - Commodity Operations
    
    /// Create a new commodity
    public func createCommodity(_ commodity: Commodity) throws {
        modelContext.insert(commodity)
        try modelContext.save()
    }
    
    /// Fetch all commodities
    public func fetchCommodities() throws -> [Commodity] {
        let descriptor = FetchDescriptor<Commodity>(
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch commodities by type
    public func fetchCommodities(ofType type: CommodityType) throws -> [Commodity] {
        let descriptor = FetchDescriptor<Commodity>(
            predicate: #Predicate { commodity in
                commodity.commodityType == type
            },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Update commodity market price
    public func updateCommodityPrice(
        commodityId: UUID,
        marketPricePerUnit: Decimal,
        notes: String? = nil
    ) throws {
        let descriptor = FetchDescriptor<Commodity>(
            predicate: #Predicate { commodity in
                commodity.id == commodityId
            }
        )
        guard let commodity = try modelContext.fetch(descriptor).first else {
            throw AlternativeInvestmentError.commodityNotFound
        }
        
        commodity.updateValuation(marketPricePerUnit: marketPricePerUnit, notes: notes)
        try modelContext.save()
    }
    
    /// Delete commodity
    public func deleteCommodity(_ commodity: Commodity) throws {
        modelContext.delete(commodity)
        try modelContext.save()
    }
    
    /// Calculate total commodity value
    public func calculateTotalCommodityValue() throws -> Decimal {
        let commodities = try fetchCommodities()
        return commodities.reduce(0) { $0 + $1.currentValue }
    }
    
    /// Calculate total gold holdings (in grams)
    public func calculateTotalGoldHoldings() throws -> Decimal {
        let goldCommodities = try fetchCommodities(ofType: .gold)
        return goldCommodities.reduce(0) { total, commodity in
            if commodity.weightUnit == .grams {
                return total + commodity.weight
            } else if commodity.weightUnit == .kilograms {
                return total + (commodity.weight * 1000)
            }
            return total
        }
    }
    
    // MARK: - Bond Operations
    
    /// Create a new bond
    public func createBond(_ bond: Bond) throws {
        modelContext.insert(bond)
        try modelContext.save()
    }
    
    /// Fetch all bonds
    public func fetchBonds() throws -> [Bond] {
        let descriptor = FetchDescriptor<Bond>(
            sortBy: [SortDescriptor(\.maturityDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch bonds by type
    public func fetchBonds(ofType type: BondType) throws -> [Bond] {
        let descriptor = FetchDescriptor<Bond>(
            predicate: #Predicate { bond in
                bond.bondType == type
            },
            sortBy: [SortDescriptor(\.maturityDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch bonds maturing soon (within 6 months)
    public func fetchBondsMaturingSoon() throws -> [Bond] {
        let sixMonthsFromNow = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Bond>(
            predicate: #Predicate { bond in
                bond.maturityDate <= sixMonthsFromNow
            },
            sortBy: [SortDescriptor(\.maturityDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Record bond interest payment
    public func recordBondInterest(
        bondId: UUID,
        amount: Decimal,
        description: String? = nil
    ) throws {
        let descriptor = FetchDescriptor<Bond>(
            predicate: #Predicate { bond in
                bond.id == bondId
            }
        )
        guard let bond = try modelContext.fetch(descriptor).first else {
            throw AlternativeInvestmentError.bondNotFound
        }
        
        bond.recordInterestPayment(amount: amount, description: description)
        try modelContext.save()
    }
    
    /// Delete bond
    public func deleteBond(_ bond: Bond) throws {
        modelContext.delete(bond)
        try modelContext.save()
    }
    
    /// Calculate total bond value
    public func calculateTotalBondValue() throws -> Decimal {
        let bonds = try fetchBonds()
        return bonds.reduce(0) { $0 + $1.currentValue }
    }
    
    /// Calculate annual bond interest income
    public func calculateAnnualBondInterest() throws -> Decimal {
        let bonds = try fetchBonds()
        return bonds.reduce(0) { $0 + $1.annualInterestIncome }
    }
    
    // MARK: - Chit Fund Operations
    
    /// Create a new chit fund
    public func createChitFund(_ chitFund: ChitFund) throws {
        modelContext.insert(chitFund)
        try modelContext.save()
    }
    
    /// Fetch all chit funds
    public func fetchChitFunds() throws -> [ChitFund] {
        let descriptor = FetchDescriptor<ChitFund>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch active chit funds
    public func fetchActiveChitFunds() throws -> [ChitFund] {
        let descriptor = FetchDescriptor<ChitFund>(
            predicate: #Predicate { chitFund in
                chitFund.isActive == true
            },
            sortBy: [SortDescriptor(\.currentMonth, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch completed chit funds
    public func fetchCompletedChitFunds() throws -> [ChitFund] {
        let descriptor = FetchDescriptor<ChitFund>(
            predicate: #Predicate { chitFund in
                chitFund.isCompleted == true
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Record chit fund contribution
    public func recordChitContribution(
        chitFundId: UUID,
        amount: Decimal,
        month: Int,
        notes: String? = nil
    ) throws {
        let descriptor = FetchDescriptor<ChitFund>(
            predicate: #Predicate { chitFund in
                chitFund.id == chitFundId
            }
        )
        guard let chitFund = try modelContext.fetch(descriptor).first else {
            throw AlternativeInvestmentError.chitFundNotFound
        }
        
        chitFund.recordContribution(amount: amount, month: month, notes: notes)
        try modelContext.save()
    }
    
    /// Record chit fund payout
    public func recordChitPayout(
        chitFundId: UUID,
        amount: Decimal,
        month: Int,
        discount: Decimal,
        notes: String? = nil
    ) throws {
        let descriptor = FetchDescriptor<ChitFund>(
            predicate: #Predicate { chitFund in
                chitFund.id == chitFundId
            }
        )
        guard let chitFund = try modelContext.fetch(descriptor).first else {
            throw AlternativeInvestmentError.chitFundNotFound
        }
        
        chitFund.recordPayout(amount: amount, month: month, discount: discount, notes: notes)
        try modelContext.save()
    }
    
    /// Delete chit fund
    public func deleteChitFund(_ chitFund: ChitFund) throws {
        modelContext.delete(chitFund)
        try modelContext.save()
    }
    
    /// Calculate total chit fund contributions
    public func calculateTotalChitContributions() throws -> Decimal {
        let chitFunds = try fetchChitFunds()
        return chitFunds.reduce(0) { $0 + $1.totalContributed }
    }
    
    /// Calculate total chit fund payouts received
    public func calculateTotalChitPayouts() throws -> Decimal {
        let chitFunds = try fetchChitFunds()
        return chitFunds.reduce(0) { $0 + $1.totalPayoutsReceived }
    }
    
    // MARK: - Portfolio Analytics
    
    /// Calculate total alternative investments value
    public func calculateTotalAlternativeInvestmentsValue() throws -> Decimal {
        let realEstateValue = try calculateTotalRealEstateValue()
        let commodityValue = try calculateTotalCommodityValue()
        let bondValue = try calculateTotalBondValue()
        
        return realEstateValue + commodityValue + bondValue
    }
    
    /// Calculate annual alternative investment income
    public func calculateAnnualAlternativeIncome() throws -> Decimal {
        let rentalIncome = try calculateTotalRentalIncome()
        let bondInterest = try calculateAnnualBondInterest()
        
        return rentalIncome + bondInterest
    }
    
    /// Get portfolio summary
    public func getAlternativeInvestmentsSummary() throws -> AlternativeInvestmentsSummary {
        let realEstateProperties = try fetchRealEstateProperties()
        let commodities = try fetchCommodities()
        let bonds = try fetchBonds()
        let chitFunds = try fetchChitFunds()
        
        let totalValue = try calculateTotalAlternativeInvestmentsValue()
        let annualIncome = try calculateAnnualAlternativeIncome()
        
        return AlternativeInvestmentsSummary(
            totalValue: totalValue,
            annualIncome: annualIncome,
            realEstateCount: realEstateProperties.count,
            realEstateValue: try calculateTotalRealEstateValue(),
            commodityCount: commodities.count,
            commodityValue: try calculateTotalCommodityValue(),
            bondCount: bonds.count,
            bondValue: try calculateTotalBondValue(),
            chitFundCount: chitFunds.count,
            activeChitFunds: try fetchActiveChitFunds().count
        )
    }
}

// MARK: - Supporting Types

/// Summary of alternative investments portfolio
public struct AlternativeInvestmentsSummary: Codable, Sendable {
    public let totalValue: Decimal
    public let annualIncome: Decimal
    public let realEstateCount: Int
    public let realEstateValue: Decimal
    public let commodityCount: Int
    public let commodityValue: Decimal
    public let bondCount: Int
    public let bondValue: Decimal
    public let chitFundCount: Int
    public let activeChitFunds: Int
    
    public init(
        totalValue: Decimal,
        annualIncome: Decimal,
        realEstateCount: Int,
        realEstateValue: Decimal,
        commodityCount: Int,
        commodityValue: Decimal,
        bondCount: Int,
        bondValue: Decimal,
        chitFundCount: Int,
        activeChitFunds: Int
    ) {
        self.totalValue = totalValue
        self.annualIncome = annualIncome
        self.realEstateCount = realEstateCount
        self.realEstateValue = realEstateValue
        self.commodityCount = commodityCount
        self.commodityValue = commodityValue
        self.bondCount = bondCount
        self.bondValue = bondValue
        self.chitFundCount = chitFundCount
        self.activeChitFunds = activeChitFunds
    }
}

/// Alternative investment service errors
public enum AlternativeInvestmentError: Error, LocalizedError {
    case propertyNotFound
    case commodityNotFound
    case bondNotFound
    case chitFundNotFound
    case invalidData
    case saveFailed
    
    public var errorDescription: String? {
        switch self {
        case .propertyNotFound:
            return NSLocalizedString("error_property_not_found", comment: "Property not found error")
        case .commodityNotFound:
            return NSLocalizedString("error_commodity_not_found", comment: "Commodity not found error")
        case .bondNotFound:
            return NSLocalizedString("error_bond_not_found", comment: "Bond not found error")
        case .chitFundNotFound:
            return NSLocalizedString("error_chit_fund_not_found", comment: "Chit fund not found error")
        case .invalidData:
            return NSLocalizedString("error_invalid_data", comment: "Invalid data error")
        case .saveFailed:
            return NSLocalizedString("error_save_failed", comment: "Save operation failed error")
        }
    }
}
