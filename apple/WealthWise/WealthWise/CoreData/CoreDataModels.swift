import Foundation
import CoreData

// MARK: - Portfolio Extensions

extension PortfolioEntity {
    
    /// Create a new portfolio with default values
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        currency: String = "INR",
        description: String? = nil,
        isDefault: Bool = false
    ) -> PortfolioEntity {
        let portfolio = PortfolioEntity(context: context)
        portfolio.id = UUID()
        portfolio.name = name
        portfolio.currency = currency
        portfolio.portfolioDescription = description
        portfolio.isDefault = isDefault
        portfolio.totalValue = 0
        portfolio.createdAt = Date()
        portfolio.updatedAt = Date()
        return portfolio
    }
    
    /// Calculate total portfolio value from all assets
    func calculateTotalValue() -> Decimal {
        guard let assets = assets?.allObjects as? [AssetEntity] else {
            return 0
        }
        return assets.reduce(Decimal.zero) { $0 + ($1.currentValue as Decimal? ?? 0) }
    }
    
    /// Update total value and save
    func updateTotalValue() {
        totalValue = calculateTotalValue() as NSDecimalNumber
        updatedAt = Date()
    }
}

// MARK: - Asset Base Extensions

extension AssetEntity {
    
    /// Calculate unrealized gain/loss
    var unrealizedGainLoss: Decimal? {
        guard let purchase = purchasePrice as Decimal?,
              let current = currentValue as Decimal? else {
            return nil
        }
        return current - purchase
    }
    
    /// Calculate unrealized gain/loss percentage
    var unrealizedGainLossPercentage: Double? {
        guard let purchase = purchasePrice as Decimal?,
              purchase > 0,
              let current = currentValue as Decimal? else {
            return nil
        }
        let gainLoss = current - purchase
        return Double(truncating: gainLoss / purchase * 100 as NSDecimalNumber)
    }
}

// MARK: - Commodity Extensions

extension CommodityEntity {
    
    /// Commodity type enumeration
    enum CommodityType: String, CaseIterable {
        case gold = "gold"
        case silver = "silver"
        case platinum = "platinum"
        case palladium = "palladium"
        case copper = "copper"
        case oil = "oil"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .gold: return NSLocalizedString("Gold", comment: "Gold commodity")
            case .silver: return NSLocalizedString("Silver", comment: "Silver commodity")
            case .platinum: return NSLocalizedString("Platinum", comment: "Platinum commodity")
            case .palladium: return NSLocalizedString("Palladium", comment: "Palladium commodity")
            case .copper: return NSLocalizedString("Copper", comment: "Copper commodity")
            case .oil: return NSLocalizedString("Oil", comment: "Oil commodity")
            case .other: return NSLocalizedString("Other", comment: "Other commodity")
            }
        }
    }
    
    /// Create a new commodity asset
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        commodityType: CommodityType,
        quantity: Decimal,
        unit: String,
        currentValue: Decimal,
        currency: String = "INR"
    ) -> CommodityEntity {
        let commodity = CommodityEntity(context: context)
        commodity.id = UUID()
        commodity.name = name
        commodity.assetType = "commodity"
        commodity.assetCategory = "alternative"
        commodity.commodityType = commodityType.rawValue
        commodity.quantity = quantity as NSDecimalNumber
        commodity.unit = unit
        commodity.currentValue = currentValue as NSDecimalNumber
        commodity.currency = currency
        commodity.isActive = true
        commodity.createdAt = Date()
        commodity.updatedAt = Date()
        return commodity
    }
    
    /// Calculate value per unit
    var valuePerUnit: Decimal? {
        guard let qty = quantity as Decimal?, qty > 0,
              let value = currentValue as Decimal? else {
            return nil
        }
        return value / qty
    }
}

// MARK: - RealEstate Extensions

extension RealEstateEntity {
    
    /// Property type enumeration
    enum PropertyType: String, CaseIterable {
        case residential = "residential"
        case commercial = "commercial"
        case agricultural = "agricultural"
        case industrial = "industrial"
        case plot = "plot"
        
        var displayName: String {
            switch self {
            case .residential: return NSLocalizedString("Residential", comment: "Residential property")
            case .commercial: return NSLocalizedString("Commercial", comment: "Commercial property")
            case .agricultural: return NSLocalizedString("Agricultural", comment: "Agricultural property")
            case .industrial: return NSLocalizedString("Industrial", comment: "Industrial property")
            case .plot: return NSLocalizedString("Plot", comment: "Land plot")
            }
        }
    }
    
    /// Create a new real estate asset
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        propertyType: PropertyType,
        currentValue: Decimal,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        currency: String = "INR"
    ) -> RealEstateEntity {
        let property = RealEstateEntity(context: context)
        property.id = UUID()
        property.name = name
        property.assetType = "realEstate"
        property.assetCategory = "alternative"
        property.propertyType = propertyType.rawValue
        property.currentValue = currentValue as NSDecimalNumber
        property.currency = currency
        property.address = address
        property.city = city
        property.state = state
        property.country = "India"
        property.isPrimaryResidence = false
        property.isActive = true
        property.createdAt = Date()
        property.updatedAt = Date()
        return property
    }
    
    /// Calculate annual rental yield percentage
    var rentalYield: Double? {
        guard let rental = annualRentalIncome as Decimal?,
              let value = currentValue as Decimal?,
              value > 0 else {
            return nil
        }
        return Double(truncating: rental / value * 100 as NSDecimalNumber)
    }
    
    /// Calculate net equity (value - mortgage)
    var netEquity: Decimal? {
        guard let value = currentValue as Decimal? else {
            return nil
        }
        let mortgage = mortgageAmount as Decimal? ?? 0
        return value - mortgage
    }
}

// MARK: - Bond Extensions

extension BondEntity {
    
    /// Bond type enumeration
    enum BondType: String, CaseIterable {
        case government = "government"
        case corporate = "corporate"
        case municipal = "municipal"
        case convertible = "convertible"
        case zeroCoupon = "zeroCoupon"
        
        var displayName: String {
            switch self {
            case .government: return NSLocalizedString("Government Bond", comment: "Government bond")
            case .corporate: return NSLocalizedString("Corporate Bond", comment: "Corporate bond")
            case .municipal: return NSLocalizedString("Municipal Bond", comment: "Municipal bond")
            case .convertible: return NSLocalizedString("Convertible Bond", comment: "Convertible bond")
            case .zeroCoupon: return NSLocalizedString("Zero Coupon Bond", comment: "Zero coupon bond")
            }
        }
    }
    
    /// Create a new bond asset
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        bondType: BondType,
        issuer: String,
        faceValue: Decimal,
        couponRate: Decimal,
        maturityDate: Date,
        currentValue: Decimal,
        currency: String = "INR"
    ) -> BondEntity {
        let bond = BondEntity(context: context)
        bond.id = UUID()
        bond.name = name
        bond.assetType = "bond"
        bond.assetCategory = "fixedIncome"
        bond.bondType = bondType.rawValue
        bond.issuer = issuer
        bond.faceValue = faceValue as NSDecimalNumber
        bond.couponRate = couponRate as NSDecimalNumber
        bond.maturityDate = maturityDate
        bond.currentValue = currentValue as NSDecimalNumber
        bond.currency = currency
        bond.isActive = true
        bond.createdAt = Date()
        bond.updatedAt = Date()
        return bond
    }
    
    /// Calculate annual interest income
    var annualInterest: Decimal? {
        guard let face = faceValue as Decimal?,
              let rate = couponRate as Decimal? else {
            return nil
        }
        return face * rate / 100
    }
    
    /// Calculate current yield
    var currentYield: Double? {
        guard let annual = annualInterest,
              let value = currentValue as Decimal?,
              value > 0 else {
            return nil
        }
        return Double(truncating: annual / value * 100 as NSDecimalNumber)
    }
    
    /// Check if bond has matured
    var hasMatured: Bool {
        guard let maturity = maturityDate else { return false }
        return maturity < Date()
    }
}

// MARK: - ChitFund Extensions

extension ChitFundEntity {
    
    /// Create a new chit fund asset
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        chitValue: Decimal,
        monthlyContribution: Decimal,
        totalMonths: Int16,
        totalMembers: Int16,
        startDate: Date,
        currency: String = "INR"
    ) -> ChitFundEntity {
        let chit = ChitFundEntity(context: context)
        chit.id = UUID()
        chit.name = name
        chit.assetType = "chitFund"
        chit.assetCategory = "alternative"
        chit.chitValue = chitValue as NSDecimalNumber
        chit.monthlyContribution = monthlyContribution as NSDecimalNumber
        chit.totalMonths = totalMonths
        chit.totalMembers = totalMembers
        chit.startDate = startDate
        chit.currentMonth = 0
        chit.hasReceivedPrize = false
        chit.currency = currency
        chit.isActive = true
        chit.createdAt = Date()
        chit.updatedAt = Date()
        
        // Initial current value is total contributions
        chit.currentValue = (monthlyContribution * Decimal(totalMonths)) as NSDecimalNumber
        
        return chit
    }
    
    /// Calculate total amount paid so far
    var totalPaid: Decimal {
        let contribution = monthlyContribution as Decimal? ?? 0
        return contribution * Decimal(currentMonth)
    }
    
    /// Calculate remaining months
    var remainingMonths: Int16 {
        return totalMonths - currentMonth
    }
    
    /// Check if chit fund is complete
    var isComplete: Bool {
        return currentMonth >= totalMonths
    }
    
    /// Calculate expected maturity value
    var expectedMaturityValue: Decimal {
        return chitValue as Decimal? ?? 0
    }
}

// MARK: - FixedDeposit Extensions

extension FixedDepositEntity {
    
    /// Deposit type enumeration
    enum DepositType: String, CaseIterable {
        case fixedDeposit = "fixedDeposit"
        case recurringDeposit = "recurringDeposit"
        case taxSaverFD = "taxSaverFD"
        case seniorCitizenFD = "seniorCitizenFD"
        
        var displayName: String {
            switch self {
            case .fixedDeposit: return NSLocalizedString("Fixed Deposit", comment: "Fixed deposit")
            case .recurringDeposit: return NSLocalizedString("Recurring Deposit", comment: "Recurring deposit")
            case .taxSaverFD: return NSLocalizedString("Tax Saver FD", comment: "Tax saver fixed deposit")
            case .seniorCitizenFD: return NSLocalizedString("Senior Citizen FD", comment: "Senior citizen fixed deposit")
            }
        }
    }
    
    /// Interest frequency enumeration
    enum InterestFrequency: String, CaseIterable {
        case monthly = "monthly"
        case quarterly = "quarterly"
        case halfYearly = "halfYearly"
        case annual = "annual"
        case maturity = "maturity"
        
        var displayName: String {
            switch self {
            case .monthly: return NSLocalizedString("Monthly", comment: "Monthly frequency")
            case .quarterly: return NSLocalizedString("Quarterly", comment: "Quarterly frequency")
            case .halfYearly: return NSLocalizedString("Half-Yearly", comment: "Half-yearly frequency")
            case .annual: return NSLocalizedString("Annual", comment: "Annual frequency")
            case .maturity: return NSLocalizedString("At Maturity", comment: "At maturity frequency")
            }
        }
        
        var compoundingFrequency: Int {
            switch self {
            case .monthly: return 12
            case .quarterly: return 4
            case .halfYearly: return 2
            case .annual: return 1
            case .maturity: return 1
            }
        }
    }
    
    /// Create a new fixed deposit asset
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        bankName: String,
        depositType: DepositType,
        principalAmount: Decimal,
        interestRate: Decimal,
        tenure: Int16,
        maturityDate: Date,
        interestFrequency: InterestFrequency,
        currency: String = "INR"
    ) -> FixedDepositEntity {
        let fd = FixedDepositEntity(context: context)
        fd.id = UUID()
        fd.name = name
        fd.assetType = "fixedDeposit"
        fd.assetCategory = "fixedIncome"
        fd.bankName = bankName
        fd.depositType = depositType.rawValue
        fd.currentValue = principalAmount as NSDecimalNumber
        fd.purchasePrice = principalAmount as NSDecimalNumber
        fd.interestRate = interestRate as NSDecimalNumber
        fd.tenure = tenure
        fd.maturityDate = maturityDate
        fd.interestFrequency = interestFrequency.rawValue
        fd.autoRenewal = false
        fd.currency = currency
        fd.isActive = true
        fd.createdAt = Date()
        fd.updatedAt = Date()
        
        // Calculate maturity amount
        fd.maturityAmount = calculateMaturityAmount(
            principal: principalAmount,
            rate: interestRate,
            tenure: tenure,
            frequency: interestFrequency
        ) as NSDecimalNumber
        
        return fd
    }
    
    /// Calculate maturity amount using compound interest
    static func calculateMaturityAmount(
        principal: Decimal,
        rate: Decimal,
        tenure: Int16,
        frequency: InterestFrequency
    ) -> Decimal {
        let p = Double(truncating: principal as NSDecimalNumber)
        let r = Double(truncating: rate as NSDecimalNumber) / 100
        let n = Double(frequency.compoundingFrequency)
        let t = Double(tenure) / 12.0 // tenure in months, convert to years
        
        let maturity = p * pow(1 + r/n, n * t)
        return Decimal(maturity)
    }
    
    /// Calculate expected return
    var expectedReturn: Decimal? {
        guard let maturity = maturityAmount as Decimal?,
              let principal = currentValue as Decimal? else {
            return nil
        }
        return maturity - principal
    }
    
    /// Check if FD has matured
    var hasMatured: Bool {
        return maturityDate < Date()
    }
    
    /// Days until maturity
    var daysUntilMaturity: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: maturityDate).day
        return max(0, days ?? 0)
    }
}

// MARK: - CashHolding Extensions

extension CashHoldingEntity {
    
    /// Account type enumeration
    enum AccountType: String, CaseIterable {
        case savings = "savings"
        case current = "current"
        case salary = "salary"
        case cashInHand = "cashInHand"
        case moneyMarket = "moneyMarket"
        
        var displayName: String {
            switch self {
            case .savings: return NSLocalizedString("Savings Account", comment: "Savings account")
            case .current: return NSLocalizedString("Current Account", comment: "Current account")
            case .salary: return NSLocalizedString("Salary Account", comment: "Salary account")
            case .cashInHand: return NSLocalizedString("Cash in Hand", comment: "Cash in hand")
            case .moneyMarket: return NSLocalizedString("Money Market Account", comment: "Money market account")
            }
        }
    }
    
    /// Create a new cash holding asset
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        accountType: AccountType,
        currentBalance: Decimal,
        bankName: String? = nil,
        accountNumber: String? = nil,
        currency: String = "INR"
    ) -> CashHoldingEntity {
        let cash = CashHoldingEntity(context: context)
        cash.id = UUID()
        cash.name = name
        cash.assetType = "cash"
        cash.assetCategory = "cash"
        cash.accountType = accountType.rawValue
        cash.currentValue = currentBalance as NSDecimalNumber
        cash.bankName = bankName
        cash.accountNumber = accountNumber
        cash.currency = currency
        cash.isLinkedUPI = false
        cash.lastUpdated = Date()
        cash.isActive = true
        cash.createdAt = Date()
        cash.updatedAt = Date()
        return cash
    }
    
    /// Check if balance is below minimum
    var isBelowMinimum: Bool {
        guard let balance = currentValue as Decimal?,
              let minimum = minimumBalance as Decimal? else {
            return false
        }
        return balance < minimum
    }
    
    /// Calculate excess over minimum balance
    var excessBalance: Decimal? {
        guard let balance = currentValue as Decimal?,
              let minimum = minimumBalance as Decimal? else {
            return nil
        }
        return max(0, balance - minimum)
    }
}

// MARK: - Transaction Extensions

extension TransactionEntity {
    
    /// Transaction type enumeration
    enum TransactionType: String, CaseIterable {
        case buy = "buy"
        case sell = "sell"
        case deposit = "deposit"
        case withdrawal = "withdrawal"
        case dividend = "dividend"
        case interest = "interest"
        case fee = "fee"
        case transfer = "transfer"
        
        var displayName: String {
            switch self {
            case .buy: return NSLocalizedString("Buy", comment: "Buy transaction")
            case .sell: return NSLocalizedString("Sell", comment: "Sell transaction")
            case .deposit: return NSLocalizedString("Deposit", comment: "Deposit transaction")
            case .withdrawal: return NSLocalizedString("Withdrawal", comment: "Withdrawal transaction")
            case .dividend: return NSLocalizedString("Dividend", comment: "Dividend transaction")
            case .interest: return NSLocalizedString("Interest", comment: "Interest transaction")
            case .fee: return NSLocalizedString("Fee", comment: "Fee transaction")
            case .transfer: return NSLocalizedString("Transfer", comment: "Transfer transaction")
            }
        }
        
        var isIncome: Bool {
            switch self {
            case .dividend, .interest, .sell, .deposit:
                return true
            default:
                return false
            }
        }
    }
    
    /// Create a new transaction
    static func create(
        in context: NSManagedObjectContext,
        type: TransactionType,
        amount: Decimal,
        date: Date,
        asset: AssetEntity? = nil,
        portfolio: PortfolioEntity? = nil
    ) -> TransactionEntity {
        let transaction = TransactionEntity(context: context)
        transaction.id = UUID()
        transaction.transactionType = type.rawValue
        transaction.amount = amount as NSDecimalNumber
        transaction.transactionDate = date
        transaction.asset = asset
        transaction.portfolio = portfolio
        transaction.createdAt = Date()
        return transaction
    }
}
