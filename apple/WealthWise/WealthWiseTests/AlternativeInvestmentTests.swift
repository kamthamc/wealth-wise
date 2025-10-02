//
//  AlternativeInvestmentTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Tests for Alternative Investments Module - Issue #5
//

import XCTest
import SwiftData
@testable import WealthWise

@MainActor
final class AlternativeInvestmentTests: XCTestCase {
    
    // MARK: - Real Estate Property Tests
    
    func testRealEstatePropertyCreation() throws {
        let address = PropertyAddress(
            street: "123 Main Street",
            city: "Mumbai",
            state: "Maharashtra",
            postalCode: "400001"
        )
        
        let property = RealEstateProperty(
            name: "Mumbai Apartment",
            propertyDescription: "2BHK apartment in prime location",
            propertyType: .apartment,
            address: address,
            totalArea: 1000,
            areaUnit: .squareFeet,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 6000000
        )
        
        XCTAssertEqual(property.name, "Mumbai Apartment")
        XCTAssertEqual(property.propertyType, .apartment)
        XCTAssertEqual(property.purchasePrice, 5000000)
        XCTAssertEqual(property.currentValue, 6000000)
        XCTAssertEqual(property.capitalAppreciation, 1000000)
        XCTAssertEqual(property.capitalAppreciationPercentage, 20.0, accuracy: 0.01)
        XCTAssertFalse(property.isRented)
        XCTAssertFalse(property.hasLoan)
    }
    
    func testRealEstateValuationUpdate() throws {
        let address = PropertyAddress(city: "Bangalore", state: "Karnataka")
        let property = RealEstateProperty(
            name: "Bangalore Villa",
            propertyType: .villa,
            address: address,
            totalArea: 2000,
            purchaseDate: Date(),
            purchasePrice: 8000000,
            currentValue: 8000000
        )
        
        // Update valuation
        property.updateValuation(newValue: 10000000, notes: "Market appraisal")
        
        XCTAssertEqual(property.currentValue, 10000000)
        XCTAssertEqual(property.valuationHistory.count, 1)
        XCTAssertEqual(property.valuationHistory[0].value, 10000000)
        XCTAssertEqual(property.valuationHistory[0].previousValue, 8000000)
        XCTAssertEqual(property.valuationHistory[0].changeAmount, 2000000)
        XCTAssertEqual(property.valuationHistory[0].changePercentage, 25.0, accuracy: 0.01)
    }
    
    func testRealEstateRentalIncome() throws {
        let address = PropertyAddress(city: "Delhi", state: "Delhi")
        let property = RealEstateProperty(
            name: "Delhi Apartment",
            propertyType: .apartment,
            address: address,
            totalArea: 1200,
            purchaseDate: Date(),
            purchasePrice: 7000000,
            currentValue: 7500000
        )
        
        // Update rental information
        property.updateRentalInfo(
            isRented: true,
            monthlyRent: 40000,
            tenantName: "John Doe",
            leaseStartDate: Date(),
            leaseEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
        
        XCTAssertTrue(property.isRented)
        XCTAssertEqual(property.monthlyRent, 40000)
        XCTAssertEqual(property.annualRentalIncome, 480000)
        XCTAssertNotNil(property.rentalYield)
        
        // Record rental income
        property.recordRentalIncome(amount: 40000, description: "June rent")
        property.recordRentalIncome(amount: 40000, description: "July rent")
        
        XCTAssertEqual(property.incomeHistory.count, 2)
        XCTAssertEqual(property.totalRentalIncome, 80000)
    }
    
    func testRealEstateLoanTracking() throws {
        let address = PropertyAddress(city: "Chennai", state: "Tamil Nadu")
        let property = RealEstateProperty(
            name: "Chennai Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1500,
            purchaseDate: Date(),
            purchasePrice: 6000000,
            currentValue: 6500000
        )
        
        // Update loan information
        property.updateLoanInfo(
            hasLoan: true,
            loanAmount: 4500000,
            outstandingLoan: 4000000,
            monthlyEMI: 45000,
            loanProvider: "HDFC Bank",
            interestRate: 8.5
        )
        
        XCTAssertTrue(property.hasLoan)
        XCTAssertEqual(property.loanAmount, 4500000)
        XCTAssertEqual(property.outstandingLoan, 4000000)
        XCTAssertEqual(property.currentEquity, 2500000) // 6500000 - 4000000
    }
    
    func testRealEstateMaintenanceTracking() throws {
        let address = PropertyAddress(city: "Pune", state: "Maharashtra")
        let property = RealEstateProperty(
            name: "Pune House",
            propertyType: .villa,
            address: address,
            totalArea: 2500,
            purchaseDate: Date(),
            purchasePrice: 10000000,
            currentValue: 11000000
        )
        
        // Record maintenance expenses
        property.recordMaintenance(
            amount: 50000,
            description: "Plumbing repairs",
            category: .plumbing
        )
        property.recordMaintenance(
            amount: 100000,
            description: "Exterior painting",
            category: .painting
        )
        
        XCTAssertEqual(property.maintenanceHistory.count, 2)
        XCTAssertEqual(property.maintenanceHistory[0].amount, 50000)
        XCTAssertEqual(property.maintenanceHistory[0].category, .plumbing)
    }
    
    func testRealEstateDocumentAttachment() throws {
        let address = PropertyAddress(city: "Hyderabad", state: "Telangana")
        let property = RealEstateProperty(
            name: "Hyderabad Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1100,
            purchaseDate: Date(),
            purchasePrice: 5500000,
            currentValue: 6000000
        )
        
        // Attach documents
        property.attachDocument(
            fileName: "sale_deed.pdf",
            fileType: .saleAgreement,
            filePath: "/secure/documents/sale_deed.pdf",
            encryptionKey: "encrypted_key_123",
            fileSize: 1024000
        )
        property.attachDocument(
            fileName: "property_tax_receipt.pdf",
            fileType: .propertyTax,
            filePath: "/secure/documents/tax_receipt.pdf",
            encryptionKey: "encrypted_key_456",
            fileSize: 512000
        )
        
        XCTAssertEqual(property.documents.count, 2)
        XCTAssertEqual(property.documents[0].fileName, "sale_deed.pdf")
        XCTAssertEqual(property.documents[0].fileType, .saleAgreement)
    }
    
    // MARK: - Commodity Tests
    
    func testCommodityCreation() throws {
        let commodity = Commodity(
            name: "Gold Jewelry Set",
            commodityDescription: "22K gold necklace and earrings",
            commodityType: .gold,
            weight: 50,
            weightUnit: .grams,
            purity: 91.6,
            form: .jewelry,
            purchaseDate: Date(),
            purchasePrice: 250000,
            pricePerUnit: 5000,
            currentValue: 280000
        )
        
        XCTAssertEqual(commodity.name, "Gold Jewelry Set")
        XCTAssertEqual(commodity.commodityType, .gold)
        XCTAssertEqual(commodity.weight, 50)
        XCTAssertEqual(commodity.purity, 91.6)
        XCTAssertEqual(commodity.form, .jewelry)
        XCTAssertEqual(commodity.purchasePrice, 250000)
        XCTAssertEqual(commodity.currentValue, 280000)
        XCTAssertEqual(commodity.capitalAppreciation, 30000)
    }
    
    func testCommodityValuationUpdate() throws {
        let commodity = Commodity(
            name: "Silver Bars",
            commodityType: .silver,
            weight: 1000,
            weightUnit: .grams,
            form: .bars,
            purchaseDate: Date(),
            purchasePrice: 65000,
            pricePerUnit: 65,
            currentValue: 65000
        )
        
        // Update valuation with new market price
        commodity.updateValuation(marketPricePerUnit: 75, notes: "Market price increased")
        
        XCTAssertEqual(commodity.currentMarketPrice, 75)
        XCTAssertEqual(commodity.currentValue, 75000) // 75 * 1000
        XCTAssertEqual(commodity.valuationHistory.count, 1)
        XCTAssertEqual(commodity.valuationHistory[0].value, 75000)
        XCTAssertEqual(commodity.valuationHistory[0].changeAmount, 10000)
    }
    
    func testCommodityPricePerUnit() throws {
        let commodity = Commodity(
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
        
        XCTAssertEqual(commodity.pricePerUnit, 5000)
        XCTAssertEqual(commodity.currentValuePerUnit, 5500) // 550000 / 100
        XCTAssertEqual(commodity.priceAppreciationPerUnit, 500) // 5500 - 5000
    }
    
    func testCommodityInsurance() throws {
        let commodity = Commodity(
            name: "Diamond Necklace",
            commodityType: .diamond,
            weight: 10,
            weightUnit: .grams,
            form: .jewelry,
            purchaseDate: Date(),
            purchasePrice: 1000000,
            pricePerUnit: 100000,
            currentValue: 1200000,
            storageLocation: .bankLocker
        )
        
        // Update insurance
        commodity.updateInsurance(
            isInsured: true,
            insuranceValue: 1200000,
            insuranceProvider: "ICICI Lombard"
        )
        
        XCTAssertTrue(commodity.isInsured)
        XCTAssertEqual(commodity.insuranceValue, 1200000)
        XCTAssertEqual(commodity.insuranceProvider, "ICICI Lombard")
    }
    
    // MARK: - Bond Tests
    
    func testBondCreation() throws {
        let bond = Bond(
            name: "Government of India Bond 2030",
            bondDescription: "7.5% GOI Bond",
            bondType: .governmentBond,
            issuer: "Government of India",
            isin: "IN0020130016",
            faceValue: 1000,
            quantity: 100,
            purchaseDate: Date(),
            purchasePrice: 100000,
            currentValue: 102000,
            couponRate: 7.5,
            interestPaymentFrequency: .halfYearly,
            maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        
        XCTAssertEqual(bond.name, "Government of India Bond 2030")
        XCTAssertEqual(bond.bondType, .governmentBond)
        XCTAssertEqual(bond.faceValue, 1000)
        XCTAssertEqual(bond.quantity, 100)
        XCTAssertEqual(bond.totalFaceValue, 100000)
        XCTAssertEqual(bond.couponRate, 7.5)
        XCTAssertEqual(bond.annualInterestIncome, 7500) // (100000 * 7.5) / 100
    }
    
    func testBondInterestTracking() throws {
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
        
        // Record interest payments
        bond.recordInterestPayment(amount: 1000, description: "Q1 interest")
        bond.recordInterestPayment(amount: 1000, description: "Q2 interest")
        
        XCTAssertEqual(bond.incomeHistory.count, 2)
        XCTAssertEqual(bond.totalInterestReceived, 2000)
        XCTAssertEqual(bond.incomeHistory[0].incomeType, .interest)
    }
    
    func testBondYieldCalculation() throws {
        let bond = Bond(
            name: "Treasury Bond",
            bondType: .treasuryBond,
            issuer: "Reserve Bank of India",
            faceValue: 1000,
            quantity: 100,
            purchaseDate: Date(),
            purchasePrice: 100000,
            currentValue: 105000,
            couponRate: 6.5,
            interestPaymentFrequency: .annually,
            maturityDate: Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date()
        )
        
        XCTAssertEqual(bond.annualInterestIncome, 6500) // (100000 * 6.5) / 100
        XCTAssertEqual(bond.calculatedCurrentYield, 6.19, accuracy: 0.01) // (6500 / 105000) * 100
        XCTAssertTrue(bond.yearsToMaturity > 9.9)
        XCTAssertTrue(bond.daysToMaturity > 3650)
    }
    
    func testBondValuation() throws {
        let bond = Bond(
            name: "Municipal Bond",
            bondType: .municipalBond,
            issuer: "Mumbai Municipal Corporation",
            faceValue: 1000,
            quantity: 50,
            purchaseDate: Date(),
            purchasePrice: 50000,
            currentValue: 50000,
            couponRate: 7.0,
            interestPaymentFrequency: .halfYearly,
            maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        
        // Update valuation
        bond.updateValuation(newValue: 52000, notes: "Market value increased")
        
        XCTAssertEqual(bond.currentValue, 52000)
        XCTAssertEqual(bond.valuationHistory.count, 1)
        XCTAssertEqual(bond.valuationHistory[0].changeAmount, 2000)
        XCTAssertNotNil(bond.currentYield)
    }
    
    // MARK: - Chit Fund Tests
    
    func testChitFundCreation() throws {
        let chitFund = ChitFund(
            name: "Shriram Chit Fund",
            chitDescription: "Monthly chit scheme",
            organizer: "Shriram Chits",
            totalMembers: 40,
            chitValue: 400000,
            monthlyContribution: 10000,
            duration: 40,
            startDate: Date()
        )
        
        XCTAssertEqual(chitFund.name, "Shriram Chit Fund")
        XCTAssertEqual(chitFund.organizer, "Shriram Chits")
        XCTAssertEqual(chitFund.totalMembers, 40)
        XCTAssertEqual(chitFund.chitValue, 400000)
        XCTAssertEqual(chitFund.monthlyContribution, 10000)
        XCTAssertEqual(chitFund.duration, 40)
        XCTAssertEqual(chitFund.expectedTotalContributions, 400000)
        XCTAssertTrue(chitFund.isActive)
        XCTAssertFalse(chitFund.isCompleted)
        XCTAssertFalse(chitFund.hasReceivedPayout)
    }
    
    func testChitFundContributions() throws {
        let chitFund = ChitFund(
            name: "Community Chit",
            organizer: "Local Community",
            totalMembers: 20,
            chitValue: 200000,
            monthlyContribution: 10000,
            duration: 20,
            startDate: Date()
        )
        
        // Record contributions
        chitFund.recordContribution(amount: 10000, month: 1, notes: "First month")
        chitFund.recordContribution(amount: 10000, month: 2, notes: "Second month")
        chitFund.recordContribution(amount: 10000, month: 3, notes: "Third month")
        
        XCTAssertEqual(chitFund.contributionHistory.count, 3)
        XCTAssertEqual(chitFund.totalContributed, 30000)
        XCTAssertEqual(chitFund.currentMonth, 3)
        XCTAssertEqual(chitFund.remainingContributions, 170000)
        XCTAssertEqual(chitFund.monthsRemaining, 18)
    }
    
    func testChitFundPayout() throws {
        let chitFund = ChitFund(
            name: "Business Chit",
            organizer: "ABC Chits",
            totalMembers: 30,
            chitValue: 300000,
            monthlyContribution: 10000,
            duration: 30,
            startDate: Date()
        )
        
        // Record some contributions first
        for month in 1...10 {
            chitFund.recordContribution(amount: 10000, month: month)
        }
        
        XCTAssertEqual(chitFund.totalContributed, 100000)
        
        // Record payout
        chitFund.recordPayout(
            amount: 280000,
            month: 10,
            discount: 20000,
            notes: "Won auction in month 10"
        )
        
        XCTAssertTrue(chitFund.hasReceivedPayout)
        XCTAssertEqual(chitFund.payoutMonth, 10)
        XCTAssertEqual(chitFund.payoutAmount, 280000)
        XCTAssertEqual(chitFund.discountReceived, 20000)
        XCTAssertEqual(chitFund.totalPayoutsReceived, 280000)
        XCTAssertEqual(chitFund.netBenefit, 180000) // 280000 - 100000
        XCTAssertEqual(chitFund.returnPercentage, 180.0, accuracy: 0.01)
    }
    
    func testChitFundAuctionTracking() throws {
        let chitFund = ChitFund(
            name: "Auction Chit",
            organizer: "XYZ Chits",
            totalMembers: 25,
            chitValue: 250000,
            monthlyContribution: 10000,
            duration: 25,
            startDate: Date()
        )
        
        // Record auctions
        chitFund.recordAuction(
            month: 1,
            winnerName: "Rajesh Kumar",
            bidAmount: 230000,
            discount: 20000
        )
        chitFund.recordAuction(
            month: 2,
            winnerName: "Priya Singh",
            bidAmount: 235000,
            discount: 15000
        )
        
        XCTAssertEqual(chitFund.auctionHistory.count, 2)
        XCTAssertEqual(chitFund.auctionHistory[0].winnerName, "Rajesh Kumar")
        XCTAssertEqual(chitFund.auctionHistory[0].bidAmount, 230000)
        XCTAssertEqual(chitFund.auctionHistory[0].discount, 20000)
    }
    
    func testChitFundCompletion() throws {
        let chitFund = ChitFund(
            name: "Completed Chit",
            organizer: "PQR Chits",
            totalMembers: 12,
            chitValue: 120000,
            monthlyContribution: 10000,
            duration: 12,
            startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        )
        
        // Record all contributions
        for month in 1...12 {
            chitFund.recordContribution(amount: 10000, month: month)
        }
        
        XCTAssertEqual(chitFund.totalContributed, 120000)
        XCTAssertEqual(chitFund.currentMonth, 12)
        
        // Mark as completed
        chitFund.markAsCompleted()
        
        XCTAssertTrue(chitFund.isCompleted)
        XCTAssertFalse(chitFund.isActive)
        XCTAssertNotNil(chitFund.completedAt)
    }
    
    // MARK: - Supporting Types Tests
    
    func testPropertyAddress() throws {
        let address = PropertyAddress(
            street: "456 Park Avenue",
            city: "Bangalore",
            state: "Karnataka",
            postalCode: "560001",
            landmark: "Near MG Road Metro"
        )
        
        XCTAssertEqual(address.city, "Bangalore")
        XCTAssertEqual(address.state, "Karnataka")
        XCTAssertTrue(address.fullAddress.contains("Bangalore"))
        XCTAssertTrue(address.fullAddress.contains("Karnataka"))
        XCTAssertTrue(address.fullAddress.contains("560001"))
    }
    
    func testValuationRecord() throws {
        let record = ValuationRecord(
            date: Date(),
            value: 1000000,
            previousValue: 900000,
            changeAmount: 100000,
            changePercentage: 11.11,
            valuationType: .appraisal,
            notes: "Professional appraisal"
        )
        
        XCTAssertEqual(record.value, 1000000)
        XCTAssertEqual(record.previousValue, 900000)
        XCTAssertEqual(record.changeAmount, 100000)
        XCTAssertEqual(record.changePercentage, 11.11, accuracy: 0.01)
        XCTAssertEqual(record.valuationType, .appraisal)
    }
    
    func testIncomeRecord() throws {
        let record = IncomeRecord(
            date: Date(),
            amount: 50000,
            incomeType: .rent,
            description: "Monthly rent received",
            currency: "INR"
        )
        
        XCTAssertEqual(record.amount, 50000)
        XCTAssertEqual(record.incomeType, .rent)
        XCTAssertEqual(record.currency, "INR")
    }
    
    func testSecureDocument() throws {
        let document = SecureDocument(
            fileName: "property_deed.pdf",
            fileType: .titleDeed,
            filePath: "/secure/docs/deed.pdf",
            encryptionKey: "aes256_encrypted_key",
            fileSize: 2048000
        )
        
        XCTAssertEqual(document.fileName, "property_deed.pdf")
        XCTAssertEqual(document.fileType, .titleDeed)
        XCTAssertEqual(document.fileSize, 2048000)
        XCTAssertNotNil(document.encryptionKey)
    }
    
    // MARK: - Performance Tests
    
    func testRealEstatePerformance() throws {
        measure {
            var properties: [RealEstateProperty] = []
            for i in 1...100 {
                let address = PropertyAddress(
                    city: "City \(i)",
                    state: "State \(i)"
                )
                let property = RealEstateProperty(
                    name: "Property \(i)",
                    propertyType: .apartment,
                    address: address,
                    totalArea: Decimal(1000 + i),
                    purchaseDate: Date(),
                    purchasePrice: Decimal(5000000 + i * 10000),
                    currentValue: Decimal(6000000 + i * 10000)
                )
                properties.append(property)
            }
            XCTAssertEqual(properties.count, 100)
        }
    }
    
    func testCommodityPerformance() throws {
        measure {
            var commodities: [Commodity] = []
            for i in 1...100 {
                let commodity = Commodity(
                    name: "Commodity \(i)",
                    commodityType: .gold,
                    weight: Decimal(50 + i),
                    form: .jewelry,
                    purchaseDate: Date(),
                    purchasePrice: Decimal(250000 + i * 1000),
                    pricePerUnit: Decimal(5000 + i * 10),
                    currentValue: Decimal(280000 + i * 1000)
                )
                commodities.append(commodity)
            }
            XCTAssertEqual(commodities.count, 100)
        }
    }
    
    // MARK: - Edge Cases
    
    func testRealEstateZeroAppreciation() throws {
        let address = PropertyAddress(city: "Test City", state: "Test State")
        let property = RealEstateProperty(
            name: "Stable Property",
            propertyType: .apartment,
            address: address,
            totalArea: 1000,
            purchaseDate: Date(),
            purchasePrice: 5000000,
            currentValue: 5000000
        )
        
        XCTAssertEqual(property.capitalAppreciation, 0)
        XCTAssertEqual(property.capitalAppreciationPercentage, 0.0)
    }
    
    func testChitFundZeroContributions() throws {
        let chitFund = ChitFund(
            name: "New Chit",
            organizer: "Test Organizer",
            totalMembers: 10,
            chitValue: 100000,
            monthlyContribution: 10000,
            duration: 10,
            startDate: Date()
        )
        
        XCTAssertEqual(chitFund.totalContributed, 0)
        XCTAssertEqual(chitFund.totalPayoutsReceived, 0)
        XCTAssertEqual(chitFund.netBenefit, 0)
        XCTAssertEqual(chitFund.returnPercentage, 0.0)
    }
}
