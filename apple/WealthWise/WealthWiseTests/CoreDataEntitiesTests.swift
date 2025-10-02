import XCTest
import CoreData
@testable import WealthWise

/// Comprehensive tests for Core Data entity models
/// Tests Portfolio, Commodity, RealEstate, Bond, ChitFund, FixedDeposit, and CashHolding entities
final class CoreDataEntitiesTests: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory persistent container for testing
        persistentContainer = NSPersistentContainer(name: "WealthWiseDataModel")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load persistent stores: \(error)")
            }
        }
        
        context = persistentContainer.viewContext
    }
    
    override func tearDown() {
        context = nil
        persistentContainer = nil
        super.tearDown()
    }
    
    // MARK: - Portfolio Entity Tests
    
    func testPortfolioCreation() throws {
        let portfolio = PortfolioEntity.create(
            in: context,
            name: "My Portfolio",
            currency: "INR",
            description: "Test portfolio",
            isDefault: true
        )
        
        XCTAssertNotNil(portfolio.id)
        XCTAssertEqual(portfolio.name, "My Portfolio")
        XCTAssertEqual(portfolio.currency, "INR")
        XCTAssertEqual(portfolio.portfolioDescription, "Test portfolio")
        XCTAssertTrue(portfolio.isDefault)
        XCTAssertEqual(portfolio.totalValue as Decimal, 0)
        XCTAssertNotNil(portfolio.createdAt)
        XCTAssertNotNil(portfolio.updatedAt)
    }
    
    func testPortfolioSave() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Test Portfolio")
        
        try context.save()
        
        let fetchRequest: NSFetchRequest<PortfolioEntity> = PortfolioEntity.fetchRequest()
        let results = try context.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Test Portfolio")
    }
    
    func testPortfolioTotalValueCalculation() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Test Portfolio")
        
        // Create and add assets
        let asset1 = CommodityEntity.create(
            in: context,
            name: "Gold",
            commodityType: .gold,
            quantity: 10,
            unit: "gram",
            currentValue: 50000
        )
        asset1.portfolio = portfolio
        
        let asset2 = CashHoldingEntity.create(
            in: context,
            name: "Savings",
            accountType: .savings,
            currentBalance: 100000
        )
        asset2.portfolio = portfolio
        
        let totalValue = portfolio.calculateTotalValue()
        XCTAssertEqual(totalValue, 150000)
    }
    
    // MARK: - Commodity Entity Tests
    
    func testCommodityCreation() throws {
        let commodity = CommodityEntity.create(
            in: context,
            name: "Gold Bars",
            commodityType: .gold,
            quantity: 100,
            unit: "gram",
            currentValue: 500000,
            currency: "INR"
        )
        
        XCTAssertNotNil(commodity.id)
        XCTAssertEqual(commodity.name, "Gold Bars")
        XCTAssertEqual(commodity.commodityType, "gold")
        XCTAssertEqual(commodity.quantity as Decimal, 100)
        XCTAssertEqual(commodity.unit, "gram")
        XCTAssertEqual(commodity.currentValue as Decimal, 500000)
        XCTAssertEqual(commodity.assetType, "commodity")
        XCTAssertEqual(commodity.assetCategory, "alternative")
    }
    
    func testCommodityValuePerUnit() throws {
        let commodity = CommodityEntity.create(
            in: context,
            name: "Silver Coins",
            commodityType: .silver,
            quantity: 50,
            unit: "gram",
            currentValue: 50000
        )
        
        let valuePerUnit = commodity.valuePerUnit
        XCTAssertNotNil(valuePerUnit)
        XCTAssertEqual(valuePerUnit, 1000)
    }
    
    func testCommodityPersistence() throws {
        let commodity = CommodityEntity.create(
            in: context,
            name: "Platinum",
            commodityType: .platinum,
            quantity: 10,
            unit: "gram",
            currentValue: 30000
        )
        
        try context.save()
        
        let fetchRequest: NSFetchRequest<CommodityEntity> = CommodityEntity.fetchRequest()
        let results = try context.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Platinum")
    }
    
    // MARK: - RealEstate Entity Tests
    
    func testRealEstateCreation() throws {
        let property = RealEstateEntity.create(
            in: context,
            name: "Apartment in Mumbai",
            propertyType: .residential,
            currentValue: 5000000,
            address: "123 Main Street",
            city: "Mumbai",
            state: "Maharashtra"
        )
        
        XCTAssertNotNil(property.id)
        XCTAssertEqual(property.name, "Apartment in Mumbai")
        XCTAssertEqual(property.propertyType, "residential")
        XCTAssertEqual(property.currentValue as Decimal, 5000000)
        XCTAssertEqual(property.address, "123 Main Street")
        XCTAssertEqual(property.city, "Mumbai")
        XCTAssertEqual(property.state, "Maharashtra")
        XCTAssertEqual(property.country, "India")
        XCTAssertFalse(property.isPrimaryResidence)
    }
    
    func testRealEstateRentalYield() throws {
        let property = RealEstateEntity.create(
            in: context,
            name: "Commercial Space",
            propertyType: .commercial,
            currentValue: 10000000
        )
        property.annualRentalIncome = 500000 as NSDecimalNumber
        
        let yield = property.rentalYield
        XCTAssertNotNil(yield)
        XCTAssertEqual(yield, 5.0, accuracy: 0.01)
    }
    
    func testRealEstateNetEquity() throws {
        let property = RealEstateEntity.create(
            in: context,
            name: "House with Mortgage",
            propertyType: .residential,
            currentValue: 8000000
        )
        property.mortgageAmount = 3000000 as NSDecimalNumber
        
        let equity = property.netEquity
        XCTAssertNotNil(equity)
        XCTAssertEqual(equity, 5000000)
    }
    
    // MARK: - Bond Entity Tests
    
    func testBondCreation() throws {
        let maturityDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        
        let bond = BondEntity.create(
            in: context,
            name: "Government Bond 2029",
            bondType: .government,
            issuer: "Government of India",
            faceValue: 100000,
            couponRate: 7.5,
            maturityDate: maturityDate,
            currentValue: 102000
        )
        
        XCTAssertNotNil(bond.id)
        XCTAssertEqual(bond.name, "Government Bond 2029")
        XCTAssertEqual(bond.bondType, "government")
        XCTAssertEqual(bond.issuer, "Government of India")
        XCTAssertEqual(bond.faceValue as Decimal, 100000)
        XCTAssertEqual(bond.couponRate as Decimal, 7.5)
        XCTAssertEqual(bond.currentValue as Decimal, 102000)
        XCTAssertEqual(bond.assetCategory, "fixedIncome")
    }
    
    func testBondAnnualInterest() throws {
        let bond = BondEntity.create(
            in: context,
            name: "Corporate Bond",
            bondType: .corporate,
            issuer: "XYZ Corp",
            faceValue: 100000,
            couponRate: 8.0,
            maturityDate: Date(),
            currentValue: 100000
        )
        
        let interest = bond.annualInterest
        XCTAssertNotNil(interest)
        XCTAssertEqual(interest, 8000)
    }
    
    func testBondCurrentYield() throws {
        let bond = BondEntity.create(
            in: context,
            name: "Test Bond",
            bondType: .corporate,
            issuer: "Test Corp",
            faceValue: 100000,
            couponRate: 10.0,
            maturityDate: Date(),
            currentValue: 95000
        )
        
        let yield = bond.currentYield
        XCTAssertNotNil(yield)
        XCTAssertEqual(yield!, 10.526, accuracy: 0.01)
    }
    
    func testBondMaturityCheck() throws {
        let pastDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let maturedBond = BondEntity.create(
            in: context,
            name: "Matured Bond",
            bondType: .government,
            issuer: "Govt",
            faceValue: 100000,
            couponRate: 7.0,
            maturityDate: pastDate,
            currentValue: 100000
        )
        
        let activeBond = BondEntity.create(
            in: context,
            name: "Active Bond",
            bondType: .government,
            issuer: "Govt",
            faceValue: 100000,
            couponRate: 7.0,
            maturityDate: futureDate,
            currentValue: 100000
        )
        
        XCTAssertTrue(maturedBond.hasMatured)
        XCTAssertFalse(activeBond.hasMatured)
    }
    
    // MARK: - ChitFund Entity Tests
    
    func testChitFundCreation() throws {
        let startDate = Date()
        
        let chit = ChitFundEntity.create(
            in: context,
            name: "Community Chit Fund",
            chitValue: 100000,
            monthlyContribution: 5000,
            totalMonths: 20,
            totalMembers: 20,
            startDate: startDate
        )
        
        XCTAssertNotNil(chit.id)
        XCTAssertEqual(chit.name, "Community Chit Fund")
        XCTAssertEqual(chit.chitValue as Decimal, 100000)
        XCTAssertEqual(chit.monthlyContribution as Decimal, 5000)
        XCTAssertEqual(chit.totalMonths, 20)
        XCTAssertEqual(chit.totalMembers, 20)
        XCTAssertEqual(chit.currentMonth, 0)
        XCTAssertFalse(chit.hasReceivedPrize)
        XCTAssertEqual(chit.assetType, "chitFund")
        XCTAssertEqual(chit.assetCategory, "alternative")
    }
    
    func testChitFundTotalPaid() throws {
        let chit = ChitFundEntity.create(
            in: context,
            name: "Test Chit",
            chitValue: 100000,
            monthlyContribution: 5000,
            totalMonths: 20,
            totalMembers: 20,
            startDate: Date()
        )
        
        chit.currentMonth = 10
        
        let totalPaid = chit.totalPaid
        XCTAssertEqual(totalPaid, 50000)
    }
    
    func testChitFundRemainingMonths() throws {
        let chit = ChitFundEntity.create(
            in: context,
            name: "Test Chit",
            chitValue: 100000,
            monthlyContribution: 5000,
            totalMonths: 20,
            totalMembers: 20,
            startDate: Date()
        )
        
        chit.currentMonth = 12
        
        XCTAssertEqual(chit.remainingMonths, 8)
        XCTAssertFalse(chit.isComplete)
        
        chit.currentMonth = 20
        XCTAssertTrue(chit.isComplete)
    }
    
    // MARK: - FixedDeposit Entity Tests
    
    func testFixedDepositCreation() throws {
        let maturityDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let fd = FixedDepositEntity.create(
            in: context,
            name: "HDFC FD",
            bankName: "HDFC Bank",
            depositType: .fixedDeposit,
            principalAmount: 100000,
            interestRate: 7.0,
            tenure: 12,
            maturityDate: maturityDate,
            interestFrequency: .quarterly
        )
        
        XCTAssertNotNil(fd.id)
        XCTAssertEqual(fd.name, "HDFC FD")
        XCTAssertEqual(fd.bankName, "HDFC Bank")
        XCTAssertEqual(fd.depositType, "fixedDeposit")
        XCTAssertEqual(fd.currentValue as Decimal, 100000)
        XCTAssertEqual(fd.interestRate as Decimal, 7.0)
        XCTAssertEqual(fd.tenure, 12)
        XCTAssertFalse(fd.autoRenewal)
        XCTAssertEqual(fd.assetType, "fixedDeposit")
        XCTAssertEqual(fd.assetCategory, "fixedIncome")
    }
    
    func testFixedDepositMaturityCalculation() throws {
        let maturityDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let fd = FixedDepositEntity.create(
            in: context,
            name: "Test FD",
            bankName: "Test Bank",
            depositType: .fixedDeposit,
            principalAmount: 100000,
            interestRate: 7.0,
            tenure: 12,
            maturityDate: maturityDate,
            interestFrequency: .quarterly
        )
        
        let maturityAmount = fd.maturityAmount as Decimal?
        XCTAssertNotNil(maturityAmount)
        
        // Maturity should be greater than principal
        XCTAssertGreaterThan(maturityAmount!, 100000)
        
        // Expected maturity with quarterly compounding
        // A = P(1 + r/n)^(nt) = 100000(1 + 0.07/4)^(4*1) ≈ 107186
        XCTAssertEqual(maturityAmount!, 107186, accuracy: 100)
    }
    
    func testFixedDepositExpectedReturn() throws {
        let maturityDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let fd = FixedDepositEntity.create(
            in: context,
            name: "Test FD",
            bankName: "Test Bank",
            depositType: .fixedDeposit,
            principalAmount: 100000,
            interestRate: 7.0,
            tenure: 12,
            maturityDate: maturityDate,
            interestFrequency: .quarterly
        )
        
        let expectedReturn = fd.expectedReturn
        XCTAssertNotNil(expectedReturn)
        XCTAssertGreaterThan(expectedReturn!, 0)
    }
    
    func testFixedDepositMaturityStatus() throws {
        let pastDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        
        let maturedFD = FixedDepositEntity.create(
            in: context,
            name: "Matured FD",
            bankName: "Test Bank",
            depositType: .fixedDeposit,
            principalAmount: 100000,
            interestRate: 7.0,
            tenure: 12,
            maturityDate: pastDate,
            interestFrequency: .quarterly
        )
        
        let activeFD = FixedDepositEntity.create(
            in: context,
            name: "Active FD",
            bankName: "Test Bank",
            depositType: .fixedDeposit,
            principalAmount: 100000,
            interestRate: 7.0,
            tenure: 12,
            maturityDate: futureDate,
            interestFrequency: .quarterly
        )
        
        XCTAssertTrue(maturedFD.hasMatured)
        XCTAssertFalse(activeFD.hasMatured)
        XCTAssertGreaterThan(activeFD.daysUntilMaturity, 0)
    }
    
    // MARK: - CashHolding Entity Tests
    
    func testCashHoldingCreation() throws {
        let cash = CashHoldingEntity.create(
            in: context,
            name: "Savings Account",
            accountType: .savings,
            currentBalance: 50000,
            bankName: "SBI",
            accountNumber: "1234567890"
        )
        
        XCTAssertNotNil(cash.id)
        XCTAssertEqual(cash.name, "Savings Account")
        XCTAssertEqual(cash.accountType, "savings")
        XCTAssertEqual(cash.currentValue as Decimal, 50000)
        XCTAssertEqual(cash.bankName, "SBI")
        XCTAssertEqual(cash.accountNumber, "1234567890")
        XCTAssertFalse(cash.isLinkedUPI)
        XCTAssertEqual(cash.assetType, "cash")
        XCTAssertEqual(cash.assetCategory, "cash")
    }
    
    func testCashHoldingMinimumBalance() throws {
        let cash = CashHoldingEntity.create(
            in: context,
            name: "Savings",
            accountType: .savings,
            currentBalance: 8000
        )
        cash.minimumBalance = 10000 as NSDecimalNumber
        
        XCTAssertTrue(cash.isBelowMinimum)
        
        cash.currentValue = 15000 as NSDecimalNumber
        XCTAssertFalse(cash.isBelowMinimum)
        
        let excess = cash.excessBalance
        XCTAssertNotNil(excess)
        XCTAssertEqual(excess, 5000)
    }
    
    func testCashHoldingPersistence() throws {
        let cash = CashHoldingEntity.create(
            in: context,
            name: "Current Account",
            accountType: .current,
            currentBalance: 100000
        )
        
        try context.save()
        
        let fetchRequest: NSFetchRequest<CashHoldingEntity> = CashHoldingEntity.fetchRequest()
        let results = try context.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Current Account")
    }
    
    // MARK: - Transaction Entity Tests
    
    func testTransactionCreation() throws {
        let transaction = TransactionEntity.create(
            in: context,
            type: .buy,
            amount: 10000,
            date: Date()
        )
        
        XCTAssertNotNil(transaction.id)
        XCTAssertEqual(transaction.transactionType, "buy")
        XCTAssertEqual(transaction.amount as Decimal, 10000)
        XCTAssertNotNil(transaction.transactionDate)
        XCTAssertNotNil(transaction.createdAt)
    }
    
    func testTransactionWithAsset() throws {
        let commodity = CommodityEntity.create(
            in: context,
            name: "Gold",
            commodityType: .gold,
            quantity: 10,
            unit: "gram",
            currentValue: 50000
        )
        
        let transaction = TransactionEntity.create(
            in: context,
            type: .buy,
            amount: 50000,
            date: Date(),
            asset: commodity
        )
        
        XCTAssertNotNil(transaction.asset)
        XCTAssertEqual(transaction.asset?.name, "Gold")
    }
    
    func testTransactionWithPortfolio() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Investment Portfolio")
        
        let transaction = TransactionEntity.create(
            in: context,
            type: .deposit,
            amount: 100000,
            date: Date(),
            portfolio: portfolio
        )
        
        XCTAssertNotNil(transaction.portfolio)
        XCTAssertEqual(transaction.portfolio?.name, "Investment Portfolio")
    }
    
    // MARK: - Relationship Tests
    
    func testPortfolioAssetRelationship() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Main Portfolio")
        
        let asset1 = CommodityEntity.create(
            in: context,
            name: "Gold",
            commodityType: .gold,
            quantity: 10,
            unit: "gram",
            currentValue: 50000
        )
        asset1.portfolio = portfolio
        
        let asset2 = CashHoldingEntity.create(
            in: context,
            name: "Savings",
            accountType: .savings,
            currentBalance: 100000
        )
        asset2.portfolio = portfolio
        
        try context.save()
        
        XCTAssertEqual(portfolio.assets?.count, 2)
        XCTAssertNotNil(asset1.portfolio)
        XCTAssertEqual(asset1.portfolio?.name, "Main Portfolio")
    }
    
    func testAssetTransactionRelationship() throws {
        let bond = BondEntity.create(
            in: context,
            name: "Govt Bond",
            bondType: .government,
            issuer: "GOI",
            faceValue: 100000,
            couponRate: 7.0,
            maturityDate: Date(),
            currentValue: 100000
        )
        
        let transaction1 = TransactionEntity.create(
            in: context,
            type: .buy,
            amount: 100000,
            date: Date(),
            asset: bond
        )
        
        let transaction2 = TransactionEntity.create(
            in: context,
            type: .interest,
            amount: 7000,
            date: Date(),
            asset: bond
        )
        
        try context.save()
        
        XCTAssertEqual(bond.transactions?.count, 2)
    }
    
    func testCascadeDelete() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Test Portfolio")
        
        let asset = CommodityEntity.create(
            in: context,
            name: "Gold",
            commodityType: .gold,
            quantity: 10,
            unit: "gram",
            currentValue: 50000
        )
        asset.portfolio = portfolio
        
        let transaction = TransactionEntity.create(
            in: context,
            type: .buy,
            amount: 50000,
            date: Date(),
            asset: asset,
            portfolio: portfolio
        )
        
        try context.save()
        
        // Delete portfolio should cascade delete assets and transactions
        context.delete(portfolio)
        try context.save()
        
        let assetFetch: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
        let assets = try context.fetch(assetFetch)
        XCTAssertEqual(assets.count, 0)
        
        let transactionFetch: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let transactions = try context.fetch(transactionFetch)
        XCTAssertEqual(transactions.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testBulkAssetCreation() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Large Portfolio")
        
        measure {
            for i in 0..<100 {
                let asset = CommodityEntity.create(
                    in: context,
                    name: "Asset \(i)",
                    commodityType: .gold,
                    quantity: Decimal(i + 1),
                    unit: "gram",
                    currentValue: Decimal((i + 1) * 1000)
                )
                asset.portfolio = portfolio
            }
            
            do {
                try context.save()
            } catch {
                XCTFail("Failed to save: \(error)")
            }
        }
    }
    
    func testPortfolioValueCalculationPerformance() throws {
        let portfolio = PortfolioEntity.create(in: context, name: "Performance Portfolio")
        
        // Create 100 assets
        for i in 0..<100 {
            let asset = CommodityEntity.create(
                in: context,
                name: "Asset \(i)",
                commodityType: .gold,
                quantity: Decimal(i + 1),
                unit: "gram",
                currentValue: Decimal((i + 1) * 1000)
            )
            asset.portfolio = portfolio
        }
        
        measure {
            _ = portfolio.calculateTotalValue()
        }
    }
}
