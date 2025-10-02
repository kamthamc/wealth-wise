//
//  AlternativeInvestmentServiceTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Tests for Alternative Investments Service - Issue #5
//

import XCTest
import SwiftData
@testable import WealthWise

@MainActor
final class AlternativeInvestmentServiceTests: XCTestCase {
    
    var modelContext: ModelContext!
    var service: AlternativeInvestmentService!
    
    override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            RealEstateProperty.self,
            Commodity.self,
            Bond.self,
            ChitFund.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        modelContext = ModelContext(container)
        service = AlternativeInvestmentService(modelContext: modelContext)
    }
    
    override func tearDown() {
        service = nil
        modelContext = nil
    }
    
    // MARK: - Real Estate Service Tests
    
    func testCreateAndFetchRealEstateProperty() throws {
        let address = PropertyAddress(
            city: "Mumbai",
            state: "Maharashtra"
        )
        
        let property = RealEstateProperty(
            name: "Test Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5500000
        )
        
        // Create property
        try service.createRealEstateProperty(property)
        
        // Fetch properties
        let properties = try service.fetchRealEstateProperties()
        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties[0].name, "Test Property")
        XCTAssertEqual(properties[0].currentValue, 5500000)
    }
    
    func testFetchPropertiesByType() throws {
        let address1 = PropertyAddress(city: "Mumbai", state: "Maharashtra")
        let property1 = RealEstateProperty(
            name: "Apartment 1",
            propertyType: .apartment,
            address: address1,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5500000
        )
        
        let address2 = PropertyAddress(city: "Bangalore", state: "Karnataka")
        let property2 = RealEstateProperty(
            name: "Villa 1",
            propertyType: .villa,
            address: address2,
            totalArea: 2000,
            purchaseDate: Date(),
            purchasePrice: 10000000,
            currentValue: 11000000
        )
        
        try service.createRealEstateProperty(property1)
        try service.createRealEstateProperty(property2)
        
        // Fetch apartments only
        let apartments = try service.fetchRealEstateProperties(ofType: .apartment)
        XCTAssertEqual(apartments.count, 1)
        XCTAssertEqual(apartments[0].name, "Apartment 1")
        
        // Fetch villas only
        let villas = try service.fetchRealEstateProperties(ofType: .villa)
        XCTAssertEqual(villas.count, 1)
        XCTAssertEqual(villas[0].name, "Villa 1")
    }
    
    func testFetchRentedProperties() throws {
        let address1 = PropertyAddress(city: "Delhi", state: "Delhi")
        let property1 = RealEstateProperty(
            name: "Rented Apartment",
            propertyType: .apartment,
            address: address1,
            totalArea: 1200,
            purchaseDate: Date(),
            purchasePrice: 6000000,
            currentValue: 6500000
        )
        property1.updateRentalInfo(isRented: true, monthlyRent: 40000)
        
        let address2 = PropertyAddress(city: "Chennai", state: "Tamil Nadu")
        let property2 = RealEstateProperty(
            name: "Owner Occupied",
            propertyType: .villa,
            address: address2,
            totalArea: 2500,
            purchaseDate: Date(),
            purchasePrice: 12000000,
            currentValue: 13000000
        )
        
        try service.createRealEstateProperty(property1)
        try service.createRealEstateProperty(property2)
        
        // Fetch rented properties
        let rentedProperties = try service.fetchRentedProperties()
        XCTAssertEqual(rentedProperties.count, 1)
        XCTAssertEqual(rentedProperties[0].name, "Rented Apartment")
        XCTAssertTrue(rentedProperties[0].isRented)
    }
    
    func testUpdatePropertyValuation() throws {
        let address = PropertyAddress(city: "Pune", state: "Maharashtra")
        let property = RealEstateProperty(
            name: "Test Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5000000
        )
        
        try service.createRealEstateProperty(property)
        
        // Update valuation
        try service.updatePropertyValuation(
            propertyId: property.id,
            newValue: 6000000,
            notes: "Market appreciation"
        )
        
        // Verify update
        let properties = try service.fetchRealEstateProperties()
        XCTAssertEqual(properties[0].currentValue, 6000000)
        XCTAssertEqual(properties[0].valuationHistory.count, 1)
    }
    
    func testCalculateTotalRealEstateValue() throws {
        let address1 = PropertyAddress(city: "Mumbai", state: "Maharashtra")
        let property1 = RealEstateProperty(
            name: "Property 1",
            propertyType: .apartment,
            address: address1,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5500000
        )
        
        let address2 = PropertyAddress(city: "Bangalore", state: "Karnataka")
        let property2 = RealEstateProperty(
            name: "Property 2",
            propertyType: .villa,
            address: address2,
            totalArea: 2000,
            purchaseDate: Date(),
            purchasePrice: 10000000,
            currentValue: 11000000
        )
        
        try service.createRealEstateProperty(property1)
        try service.createRealEstateProperty(property2)
        
        let totalValue = try service.calculateTotalRealEstateValue()
        XCTAssertEqual(totalValue, 16500000) // 5500000 + 11000000
    }
    
    func testCalculateTotalRentalIncome() throws {
        let address1 = PropertyAddress(city: "Delhi", state: "Delhi")
        let property1 = RealEstateProperty(
            name: "Rented 1",
            propertyType: .apartment,
            address: address1,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 6000000,
            currentValue: 6500000
        )
        property1.updateRentalInfo(isRented: true, monthlyRent: 40000)
        
        let address2 = PropertyAddress(city: "Chennai", state: "Tamil Nadu")
        let property2 = RealEstateProperty(
            name: "Rented 2",
            propertyType: .apartment,
            address: address2,
            totalArea: 1200,
            purchaseDate: Date(),
            purchasePrice: 7000000,
            currentValue: 7500000
        )
        property2.updateRentalInfo(isRented: true, monthlyRent: 50000)
        
        try service.createRealEstateProperty(property1)
        try service.createRealEstateProperty(property2)
        
        let totalRentalIncome = try service.calculateTotalRentalIncome()
        XCTAssertEqual(totalRentalIncome, 1080000) // (40000 + 50000) * 12
    }
    
    // MARK: - Commodity Service Tests
    
    func testCreateAndFetchCommodity() throws {
        let commodity = Commodity(
            name: "Gold Jewelry",
            commodityType: .gold,
            weight: 50,
            form: .jewelry,
            purchaseDate: Date(),
            purchasePrice: 250000,
            pricePerUnit: 5000,
            currentValue: 280000
        )
        
        try service.createCommodity(commodity)
        
        let commodities = try service.fetchCommodities()
        XCTAssertEqual(commodities.count, 1)
        XCTAssertEqual(commodities[0].name, "Gold Jewelry")
        XCTAssertEqual(commodities[0].commodityType, .gold)
    }
    
    func testFetchCommoditiesByType() throws {
        let gold = Commodity(
            name: "Gold Coins",
            commodityType: .gold,
            weight: 100,
            form: .coins,
            purchaseDate: Date(),
            purchasePrice: 500000,
            pricePerUnit: 5000,
            currentValue: 550000
        )
        
        let silver = Commodity(
            name: "Silver Bars",
            commodityType: .silver,
            weight: 1000,
            form: .bars,
            purchaseDate: Date(),
            purchasePrice: 65000,
            pricePerUnit: 65,
            currentValue: 70000
        )
        
        try service.createCommodity(gold)
        try service.createCommodity(silver)
        
        let goldCommodities = try service.fetchCommodities(ofType: .gold)
        XCTAssertEqual(goldCommodities.count, 1)
        XCTAssertEqual(goldCommodities[0].commodityType, .gold)
        
        let silverCommodities = try service.fetchCommodities(ofType: .silver)
        XCTAssertEqual(silverCommodities.count, 1)
        XCTAssertEqual(silverCommodities[0].commodityType, .silver)
    }
    
    func testUpdateCommodityPrice() throws {
        let commodity = Commodity(
            name: "Gold Bars",
            commodityType: .gold,
            weight: 100,
            form: .bars,
            purchaseDate: Date(),
            purchasePrice: 500000,
            pricePerUnit: 5000,
            currentValue: 500000
        )
        
        try service.createCommodity(commodity)
        
        // Update price
        try service.updateCommodityPrice(
            commodityId: commodity.id,
            marketPricePerUnit: 5500,
            notes: "Market price increased"
        )
        
        let commodities = try service.fetchCommodities()
        XCTAssertEqual(commodities[0].currentMarketPrice, 5500)
        XCTAssertEqual(commodities[0].currentValue, 550000) // 5500 * 100
    }
    
    func testCalculateTotalGoldHoldings() throws {
        let gold1 = Commodity(
            name: "Gold Jewelry",
            commodityType: .gold,
            weight: 50,
            weightUnit: .grams,
            form: .jewelry,
            purchaseDate: Date(),
            purchasePrice: 250000,
            pricePerUnit: 5000,
            currentValue: 280000
        )
        
        let gold2 = Commodity(
            name: "Gold Coins",
            commodityType: .gold,
            weight: 100,
            weightUnit: .grams,
            form: .coins,
            purchaseDate: Date(),
            purchasePrice: 500000,
            pricePerUnit: 5000,
            currentValue: 550000
        )
        
        try service.createCommodity(gold1)
        try service.createCommodity(gold2)
        
        let totalGold = try service.calculateTotalGoldHoldings()
        XCTAssertEqual(totalGold, 150) // 50 + 100 grams
    }
    
    // MARK: - Bond Service Tests
    
    func testCreateAndFetchBond() throws {
        let bond = Bond(
            name: "Government Bond",
            bondType: .governmentBond,
            issuer: "Government of India",
            faceValue: 1000,
            quantity: 100,
            purchaseDate: Date(),
            purchasePrice: 100000,
            currentValue: 102000,
            couponRate: 7.5,
            interestPaymentFrequency: .halfYearly,
            maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        
        try service.createBond(bond)
        
        let bonds = try service.fetchBonds()
        XCTAssertEqual(bonds.count, 1)
        XCTAssertEqual(bonds[0].name, "Government Bond")
        XCTAssertEqual(bonds[0].bondType, .governmentBond)
    }
    
    func testRecordBondInterest() throws {
        let bond = Bond(
            name: "Corporate Bond",
            bondType: .corporateBond,
            issuer: "Tata Motors",
            faceValue: 1000,
            quantity: 50,
            purchaseDate: Date(),
            purchasePrice: 50000,
            currentValue: 51000,
            couponRate: 8.0,
            interestPaymentFrequency: .quarterly,
            maturityDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date()
        )
        
        try service.createBond(bond)
        
        // Record interest payment
        try service.recordBondInterest(
            bondId: bond.id,
            amount: 1000,
            description: "Q1 interest"
        )
        
        let bonds = try service.fetchBonds()
        XCTAssertEqual(bonds[0].incomeHistory.count, 1)
        XCTAssertEqual(bonds[0].totalInterestReceived, 1000)
    }
    
    func testCalculateAnnualBondInterest() throws {
        let bond1 = Bond(
            name: "Bond 1",
            bondType: .governmentBond,
            issuer: "GOI",
            faceValue: 1000,
            quantity: 100,
            purchaseDate: Date(),
            purchasePrice: 100000,
            currentValue: 102000,
            couponRate: 7.5,
            interestPaymentFrequency: .annually,
            maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        
        let bond2 = Bond(
            name: "Bond 2",
            bondType: .corporateBond,
            issuer: "Company X",
            faceValue: 1000,
            quantity: 50,
            purchaseDate: Date(),
            purchasePrice: 50000,
            currentValue: 51000,
            couponRate: 8.0,
            interestPaymentFrequency: .annually,
            maturityDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date()
        )
        
        try service.createBond(bond1)
        try service.createBond(bond2)
        
        let totalInterest = try service.calculateAnnualBondInterest()
        XCTAssertEqual(totalInterest, 11500) // 7500 + 4000
    }
    
    // MARK: - Chit Fund Service Tests
    
    func testCreateAndFetchChitFund() throws {
        let chitFund = ChitFund(
            name: "Test Chit",
            organizer: "ABC Chits",
            totalMembers: 20,
            chitValue: 200000,
            monthlyContribution: 10000,
            duration: 20,
            startDate: Date()
        )
        
        try service.createChitFund(chitFund)
        
        let chitFunds = try service.fetchChitFunds()
        XCTAssertEqual(chitFunds.count, 1)
        XCTAssertEqual(chitFunds[0].name, "Test Chit")
    }
    
    func testRecordChitContribution() throws {
        let chitFund = ChitFund(
            name: "Monthly Chit",
            organizer: "XYZ Chits",
            totalMembers: 20,
            chitValue: 200000,
            monthlyContribution: 10000,
            duration: 20,
            startDate: Date()
        )
        
        try service.createChitFund(chitFund)
        
        // Record contributions
        try service.recordChitContribution(
            chitFundId: chitFund.id,
            amount: 10000,
            month: 1
        )
        try service.recordChitContribution(
            chitFundId: chitFund.id,
            amount: 10000,
            month: 2
        )
        
        let chitFunds = try service.fetchChitFunds()
        XCTAssertEqual(chitFunds[0].contributionHistory.count, 2)
        XCTAssertEqual(chitFunds[0].totalContributed, 20000)
    }
    
    func testRecordChitPayout() throws {
        let chitFund = ChitFund(
            name: "Payout Chit",
            organizer: "PQR Chits",
            totalMembers: 30,
            chitValue: 300000,
            monthlyContribution: 10000,
            duration: 30,
            startDate: Date()
        )
        
        try service.createChitFund(chitFund)
        
        // Record payout
        try service.recordChitPayout(
            chitFundId: chitFund.id,
            amount: 280000,
            month: 10,
            discount: 20000,
            notes: "Won auction"
        )
        
        let chitFunds = try service.fetchChitFunds()
        XCTAssertTrue(chitFunds[0].hasReceivedPayout)
        XCTAssertEqual(chitFunds[0].payoutAmount, 280000)
        XCTAssertEqual(chitFunds[0].totalPayoutsReceived, 280000)
    }
    
    func testFetchActiveChitFunds() throws {
        let activeChit = ChitFund(
            name: "Active Chit",
            organizer: "ABC",
            totalMembers: 20,
            chitValue: 200000,
            monthlyContribution: 10000,
            duration: 20,
            startDate: Date()
        )
        
        let completedChit = ChitFund(
            name: "Completed Chit",
            organizer: "XYZ",
            totalMembers: 12,
            chitValue: 120000,
            monthlyContribution: 10000,
            duration: 12,
            startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        )
        completedChit.markAsCompleted()
        
        try service.createChitFund(activeChit)
        try service.createChitFund(completedChit)
        
        let activeChits = try service.fetchActiveChitFunds()
        XCTAssertEqual(activeChits.count, 1)
        XCTAssertEqual(activeChits[0].name, "Active Chit")
        
        let completedChits = try service.fetchCompletedChitFunds()
        XCTAssertEqual(completedChits.count, 1)
        XCTAssertEqual(completedChits[0].name, "Completed Chit")
    }
    
    // MARK: - Portfolio Analytics Tests
    
    func testCalculateTotalAlternativeInvestmentsValue() throws {
        // Add real estate
        let address = PropertyAddress(city: "Mumbai", state: "Maharashtra")
        let property = RealEstateProperty(
            name: "Test Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5500000
        )
        try service.createRealEstateProperty(property)
        
        // Add commodity
        let commodity = Commodity(
            name: "Gold",
            commodityType: .gold,
            weight: 100,
            form: .coins,
            purchaseDate: Date(),
            purchasePrice: 500000,
            pricePerUnit: 5000,
            currentValue: 550000
        )
        try service.createCommodity(commodity)
        
        // Add bond
        let bond = Bond(
            name: "Bond",
            bondType: .governmentBond,
            issuer: "GOI",
            faceValue: 1000,
            quantity: 100,
            purchaseDate: Date(),
            purchasePrice: 100000,
            currentValue: 102000,
            couponRate: 7.5,
            interestPaymentFrequency: .annually,
            maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        try service.createBond(bond)
        
        let totalValue = try service.calculateTotalAlternativeInvestmentsValue()
        XCTAssertEqual(totalValue, 6152000) // 5500000 + 550000 + 102000
    }
    
    func testGetAlternativeInvestmentsSummary() throws {
        // Add multiple investments
        let address = PropertyAddress(city: "Mumbai", state: "Maharashtra")
        let property = RealEstateProperty(
            name: "Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5500000
        )
        property.updateRentalInfo(isRented: true, monthlyRent: 40000)
        try service.createRealEstateProperty(property)
        
        let commodity = Commodity(
            name: "Gold",
            commodityType: .gold,
            weight: 100,
            form: .coins,
            purchaseDate: Date(),
            purchasePrice: 500000,
            pricePerUnit: 5000,
            currentValue: 550000
        )
        try service.createCommodity(commodity)
        
        let bond = Bond(
            name: "Bond",
            bondType: .governmentBond,
            issuer: "GOI",
            faceValue: 1000,
            quantity: 100,
            purchaseDate: Date(),
            purchasePrice: 100000,
            currentValue: 102000,
            couponRate: 7.5,
            interestPaymentFrequency: .annually,
            maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        try service.createBond(bond)
        
        let chitFund = ChitFund(
            name: "Chit",
            organizer: "ABC",
            totalMembers: 20,
            chitValue: 200000,
            monthlyContribution: 10000,
            duration: 20,
            startDate: Date()
        )
        try service.createChitFund(chitFund)
        
        let summary = try service.getAlternativeInvestmentsSummary()
        
        XCTAssertEqual(summary.totalValue, 6152000)
        XCTAssertEqual(summary.annualIncome, 487500) // 480000 + 7500
        XCTAssertEqual(summary.realEstateCount, 1)
        XCTAssertEqual(summary.commodityCount, 1)
        XCTAssertEqual(summary.bondCount, 1)
        XCTAssertEqual(summary.chitFundCount, 1)
        XCTAssertEqual(summary.activeChitFunds, 1)
    }
}
