import Foundation
import SwiftData

@Model
final class Asset {
    var id: UUID
    var name: String
    var type: AssetType
    var currentValue: Double
    var purchasePrice: Double?
    var purchaseDate: Date?
    var currency: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        type: AssetType,
        currentValue: Double,
        purchasePrice: Double? = nil,
        purchaseDate: Date? = nil,
        currency: String = "INR",
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.currentValue = currentValue
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.currency = currency
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum AssetType: String, CaseIterable, Codable {
    case stock = "stock"
    case mutualFund = "mutualFund"
    case etf = "etf"
    case bond = "bond"
    case realEstate = "realEstate"
    case commodity = "commodity"
    case fixedDeposit = "fixedDeposit"
    case cash = "cash"
    case chit = "chit"
    case crypto = "crypto"
    
    var displayName: String {
        switch self {
        case .stock:
            return NSLocalizedString("asset.stock", comment: "Stock asset type")
        case .mutualFund:
            return NSLocalizedString("asset.mutual_fund", comment: "Mutual fund asset type")
        case .etf:
            return NSLocalizedString("asset.etf", comment: "ETF asset type")
        case .bond:
            return NSLocalizedString("asset.bond", comment: "Bond asset type")
        case .realEstate:
            return NSLocalizedString("asset.real_estate", comment: "Real estate asset type")
        case .commodity:
            return NSLocalizedString("asset.commodity", comment: "Commodity asset type")
        case .fixedDeposit:
            return NSLocalizedString("asset.fixed_deposit", comment: "Fixed deposit asset type")
        case .cash:
            return NSLocalizedString("asset.cash", comment: "Cash asset type")
        case .chit:
            return NSLocalizedString("asset.chit_fund", comment: "Chit fund asset type")
        case .crypto:
            return NSLocalizedString("asset.cryptocurrency", comment: "Cryptocurrency asset type")
        }
    }
    
    var systemImage: String {
        switch self {
        case .stock, .etf:
            return "chart.line.uptrend.xyaxis"
        case .mutualFund:
            return "chart.pie"
        case .bond:
            return "doc.text"
        case .realEstate:
            return "house"
        case .commodity:
            return "diamond"
        case .fixedDeposit:
            return "banknote"
        case .cash:
            return "dollarsign.circle"
        case .chit:
            return "person.3"
        case .crypto:
            return "bitcoinsign.circle"
        }
    }
}

@Model
final class Portfolio {
    var id: UUID
    var name: String
    var assets: [Asset]
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.assets = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var totalValue: Double {
        assets.reduce(0) { $0 + $1.currentValue }
    }
}

@Model
final class Transaction {
    var id: UUID
    var assetId: UUID
    var type: TransactionType
    var amount: Double
    var quantity: Double?
    var price: Double?
    var date: Date
    var notes: String?
    var createdAt: Date
    
    init(
        assetId: UUID,
        type: TransactionType,
        amount: Double,
        quantity: Double? = nil,
        price: Double? = nil,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = UUID()
        self.assetId = assetId
        self.type = type
        self.amount = amount
        self.quantity = quantity
        self.price = price
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }
}

enum TransactionType: String, CaseIterable, Codable {
    case buy = "buy"
    case sell = "sell"
    case dividend = "dividend"
    case interest = "interest"
    case bonus = "bonus"
    case split = "split"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .buy:
            return NSLocalizedString("transaction.buy", comment: "Buy transaction type")
        case .sell:
            return NSLocalizedString("transaction.sell", comment: "Sell transaction type")
        case .dividend:
            return NSLocalizedString("transaction.dividend", comment: "Dividend transaction type")
        case .interest:
            return NSLocalizedString("transaction.interest", comment: "Interest transaction type")
        case .bonus:
            return NSLocalizedString("transaction.bonus", comment: "Bonus transaction type")
        case .split:
            return NSLocalizedString("transaction.stock_split", comment: "Stock split transaction type")
        case .other:
            return NSLocalizedString("transaction.other", comment: "Other transaction type")
        }
    }
}