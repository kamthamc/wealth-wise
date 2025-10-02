//
//  PortfolioService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Portfolio Management System: Core business logic service
//

import Foundation
import SwiftData
import OSLog

/// Service for managing investment portfolios with CRUD operations, P&L calculations, and performance analytics
@available(iOS 18.6, macOS 15.6, *)
@Observable
public final class PortfolioService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.wealthwise.app", category: "PortfolioService")
    
    /// Published properties for reactive UI updates
    public private(set) var portfolios: [Portfolio] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: PortfolioError?
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadPortfolios()
        }
    }
    
    // MARK: - Portfolio CRUD Operations
    
    /// Create a new portfolio
    @MainActor
    public func createPortfolio(_ portfolio: Portfolio) async throws {
        logger.info("Creating new portfolio: \(portfolio.name)")
        
        do {
            // Validate portfolio
            try validatePortfolio(portfolio)
            
            // Insert into context
            modelContext.insert(portfolio)
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Portfolio created successfully with ID: \(portfolio.id)")
            
        } catch {
            logger.error("Failed to create portfolio: \(error.localizedDescription)")
            self.error = .creationFailed(error)
            throw PortfolioError.creationFailed(error)
        }
    }
    
    /// Update an existing portfolio
    @MainActor
    public func updatePortfolio(_ portfolio: Portfolio) async throws {
        logger.info("Updating portfolio: \(portfolio.id)")
        
        do {
            // Validate portfolio
            try validatePortfolio(portfolio)
            
            // Update timestamp
            portfolio.updatedAt = Date()
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Portfolio updated successfully")
            
        } catch {
            logger.error("Failed to update portfolio: \(error.localizedDescription)")
            self.error = .updateFailed(error)
            throw PortfolioError.updateFailed(error)
        }
    }
    
    /// Delete a portfolio
    @MainActor
    public func deletePortfolio(_ portfolio: Portfolio) async throws {
        logger.info("Deleting portfolio: \(portfolio.id)")
        
        do {
            // Delete from context (cascade will handle holdings and transactions)
            modelContext.delete(portfolio)
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Portfolio deleted successfully")
            
        } catch {
            logger.error("Failed to delete portfolio: \(error.localizedDescription)")
            self.error = .deletionFailed(error)
            throw PortfolioError.deletionFailed(error)
        }
    }
    
    /// Fetch portfolio by ID
    @MainActor
    public func getPortfolio(by id: UUID) async throws -> Portfolio? {
        let descriptor = FetchDescriptor<Portfolio>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            logger.error("Failed to fetch portfolio: \(error.localizedDescription)")
            self.error = .fetchFailed(error)
            throw PortfolioError.fetchFailed(error)
        }
    }
    
    // MARK: - Holding CRUD Operations
    
    /// Add a new holding to a portfolio
    @MainActor
    public func addHolding(_ holding: Holding, to portfolio: Portfolio) async throws {
        logger.info("Adding holding \(holding.symbol) to portfolio \(portfolio.name)")
        
        do {
            // Validate holding
            try validateHolding(holding)
            
            // Check for duplicate symbol in portfolio
            if portfolio.holdings.contains(where: { $0.symbol == holding.symbol }) {
                throw PortfolioError.duplicateHolding(holding.symbol)
            }
            
            // Add holding to portfolio
            portfolio.holdings.append(holding)
            portfolio.updatedAt = Date()
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Holding added successfully")
            
        } catch {
            logger.error("Failed to add holding: \(error.localizedDescription)")
            if let portfolioError = error as? PortfolioError {
                self.error = portfolioError
                throw portfolioError
            } else {
                self.error = .holdingOperationFailed(error)
                throw PortfolioError.holdingOperationFailed(error)
            }
        }
    }
    
    /// Update an existing holding
    @MainActor
    public func updateHolding(_ holding: Holding) async throws {
        logger.info("Updating holding: \(holding.symbol)")
        
        do {
            // Validate holding
            try validateHolding(holding)
            
            // Update timestamp
            holding.updatedAt = Date()
            
            if let portfolio = holding.portfolio {
                portfolio.updatedAt = Date()
            }
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Holding updated successfully")
            
        } catch {
            logger.error("Failed to update holding: \(error.localizedDescription)")
            self.error = .holdingOperationFailed(error)
            throw PortfolioError.holdingOperationFailed(error)
        }
    }
    
    /// Remove a holding from a portfolio
    @MainActor
    public func removeHolding(_ holding: Holding, from portfolio: Portfolio) async throws {
        logger.info("Removing holding \(holding.symbol) from portfolio \(portfolio.name)")
        
        do {
            // Remove holding from portfolio
            if let index = portfolio.holdings.firstIndex(where: { $0.id == holding.id }) {
                portfolio.holdings.remove(at: index)
            }
            
            // Delete holding
            modelContext.delete(holding)
            portfolio.updatedAt = Date()
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Holding removed successfully")
            
        } catch {
            logger.error("Failed to remove holding: \(error.localizedDescription)")
            self.error = .holdingOperationFailed(error)
            throw PortfolioError.holdingOperationFailed(error)
        }
    }
    
    // MARK: - Transaction Operations
    
    /// Record a new portfolio transaction
    @MainActor
    public func addTransaction(_ transaction: PortfolioTransaction, to portfolio: Portfolio) async throws {
        logger.info("Adding \(transaction.transactionType.rawValue) transaction for \(transaction.symbol)")
        
        do {
            // Find or create holding for this symbol
            var holding = portfolio.holdings.first(where: { $0.symbol == transaction.symbol })
            
            if holding == nil {
                // Create new holding for first buy
                if transaction.transactionType == .buy {
                    holding = Holding(
                        symbol: transaction.symbol,
                        name: transaction.assetName,
                        assetType: .publicEquityDomestic, // Default, should be set properly
                        assetClass: "Stock",
                        quantity: 0,
                        averageCost: 0,
                        currentPrice: transaction.pricePerUnit,
                        currency: transaction.currency,
                        firstPurchaseDate: transaction.date
                    )
                    portfolio.holdings.append(holding!)
                } else {
                    throw PortfolioError.holdingNotFound(transaction.symbol)
                }
            }
            
            // Process transaction based on type
            switch transaction.transactionType {
            case .buy:
                holding!.addUnits(quantity: transaction.quantity, costPerUnit: transaction.pricePerUnit)
                
            case .sell:
                if let realizedGainLoss = holding!.removeUnits(quantity: transaction.quantity) {
                    transaction.realizedGainLoss = realizedGainLoss
                    transaction.averageCostBasis = holding!.averageCost
                } else {
                    throw PortfolioError.insufficientQuantity(holding!.symbol, holding!.quantity)
                }
                
            case .dividend:
                // Dividend doesn't affect quantity, just record transaction
                break
                
            case .bonus, .split:
                // Adjust quantity without changing average cost basis
                holding!.quantity += transaction.quantity
                holding!.lastTransactionDate = transaction.date
                holding!.updatedAt = Date()
                
            case .rights, .merger, .spinoff:
                // Handle special cases - for now just record transaction
                break
            }
            
            // Add transaction to portfolio
            portfolio.transactions.append(transaction)
            portfolio.updatedAt = Date()
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadPortfolios()
            
            logger.info("Transaction added successfully")
            
        } catch {
            logger.error("Failed to add transaction: \(error.localizedDescription)")
            if let portfolioError = error as? PortfolioError {
                self.error = portfolioError
                throw portfolioError
            } else {
                self.error = .transactionFailed(error)
                throw PortfolioError.transactionFailed(error)
            }
        }
    }
    
    // MARK: - Portfolio Analytics
    
    /// Calculate portfolio value
    public func calculatePortfolioValue(_ portfolio: Portfolio) -> PortfolioValue {
        logger.info("Calculating portfolio value for: \(portfolio.name)")
        
        let totalValue = portfolio.totalValue
        let totalCost = portfolio.totalInvested
        let unrealizedGainLoss = portfolio.unrealizedGainLoss
        let unrealizedGainLossPercentage = portfolio.unrealizedGainLossPercentage
        let realizedGains = portfolio.realizedGains
        
        return PortfolioValue(
            totalValue: totalValue,
            totalCost: totalCost,
            unrealizedGainLoss: unrealizedGainLoss,
            unrealizedGainLossPercentage: unrealizedGainLossPercentage,
            realizedGains: realizedGains,
            currency: portfolio.baseCurrency
        )
    }
    
    /// Calculate performance metrics
    public func calculatePerformanceMetrics(_ portfolio: Portfolio) -> PortfolioPerformanceMetrics {
        logger.info("Calculating performance metrics for: \(portfolio.name)")
        
        let value = calculatePortfolioValue(portfolio)
        
        // Calculate XIRR (Extended Internal Rate of Return)
        let xirr = calculateXIRR(portfolio)
        
        // Calculate CAGR if applicable
        let cagr = calculateCAGR(portfolio)
        
        // Calculate absolute return
        let absoluteReturn = value.unrealizedGainLossPercentage
        
        // Calculate diversification score
        let diversificationScore = calculateDiversificationScore(portfolio)
        
        // Calculate top holdings
        let topHoldings = portfolio.activeHoldings
            .sorted { $0.currentValue > $1.currentValue }
            .prefix(5)
            .map { TopHoldingInfo(symbol: $0.symbol, name: $0.name, value: $0.currentValue, weight: $0.portfolioWeight(in: portfolio)) }
        
        return PortfolioPerformanceMetrics(
            xirr: xirr,
            cagr: cagr,
            absoluteReturn: absoluteReturn,
            diversificationScore: diversificationScore,
            topHoldings: Array(topHoldings),
            totalHoldings: portfolio.activeHoldings.count,
            lastUpdated: Date()
        )
    }
    
    /// Calculate XIRR for portfolio
    private func calculateXIRR(_ portfolio: Portfolio) -> Double? {
        // Simplified XIRR calculation - in production would use Newton-Raphson method
        // For now, return approximate return based on weighted average holding period
        
        var totalInvested: Decimal = 0
        var weightedReturn: Double = 0
        
        for holding in portfolio.activeHoldings {
            let cost = holding.totalCost
            let returnPct = holding.unrealizedGainLossPercentage
            
            totalInvested += cost
            weightedReturn += Double(truncating: cost as NSDecimalNumber) * returnPct
        }
        
        guard totalInvested > 0 else { return nil }
        
        let avgReturn = weightedReturn / Double(truncating: totalInvested as NSDecimalNumber)
        return avgReturn
    }
    
    /// Calculate CAGR for portfolio
    private func calculateCAGR(_ portfolio: Portfolio) -> Double? {
        // Calculate CAGR if we have sufficient history
        guard let oldestHolding = portfolio.holdings.min(by: { ($0.firstPurchaseDate ?? Date()) < ($1.firstPurchaseDate ?? Date()) }),
              let startDate = oldestHolding.firstPurchaseDate else {
            return nil
        }
        
        let years = Date().timeIntervalSince(startDate) / (365.25 * 24 * 60 * 60)
        guard years >= 1.0 else { return nil }
        
        let currentValue = portfolio.totalValue
        let investedValue = portfolio.totalInvested
        
        guard investedValue > 0 else { return nil }
        
        let growthFactor = Double(truncating: (currentValue / investedValue) as NSDecimalNumber)
        let cagr = (pow(growthFactor, 1.0 / years) - 1.0) * 100.0
        
        return cagr
    }
    
    /// Calculate diversification score
    private func calculateDiversificationScore(_ portfolio: Portfolio) -> Double {
        let holdings = portfolio.activeHoldings
        guard holdings.count > 1 else { return 0 }
        
        let totalValue = portfolio.totalValue
        guard totalValue > 0 else { return 0 }
        
        // Calculate Herfindahl-Hirschman Index for concentration
        var hhi: Double = 0
        for holding in holdings {
            let weight = Double(truncating: (holding.currentValue / totalValue * 100) as NSDecimalNumber)
            hhi += weight * weight
        }
        
        // Convert to diversification score (100 - normalized HHI)
        let maxHHI = 10000.0 // Maximum concentration (100% in one holding)
        let diversificationScore = max(0, 100 - (hhi / maxHHI * 100))
        
        return diversificationScore
    }
    
    // MARK: - Private Helpers
    
    /// Load all portfolios from storage
    @MainActor
    private func loadPortfolios() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<Portfolio>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            portfolios = try modelContext.fetch(descriptor)
            logger.info("Loaded \(portfolios.count) portfolios")
        } catch {
            logger.error("Failed to load portfolios: \(error.localizedDescription)")
            self.error = .fetchFailed(error)
        }
    }
    
    /// Validate portfolio data
    private func validatePortfolio(_ portfolio: Portfolio) throws {
        if portfolio.name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw PortfolioError.invalidPortfolioName
        }
        
        if portfolio.baseCurrency.isEmpty {
            throw PortfolioError.invalidCurrency
        }
    }
    
    /// Validate holding data
    private func validateHolding(_ holding: Holding) throws {
        if holding.symbol.trimmingCharacters(in: .whitespaces).isEmpty {
            throw PortfolioError.invalidHoldingSymbol
        }
        
        if holding.quantity < 0 {
            throw PortfolioError.invalidQuantity
        }
        
        if holding.averageCost < 0 {
            throw PortfolioError.invalidPrice
        }
    }
}

// MARK: - Supporting Types

/// Portfolio value calculation result
public struct PortfolioValue {
    public let totalValue: Decimal
    public let totalCost: Decimal
    public let unrealizedGainLoss: Decimal
    public let unrealizedGainLossPercentage: Double
    public let realizedGains: Decimal
    public let currency: String
}

/// Portfolio performance metrics
public struct PortfolioPerformanceMetrics {
    public let xirr: Double?
    public let cagr: Double?
    public let absoluteReturn: Double
    public let diversificationScore: Double
    public let topHoldings: [TopHoldingInfo]
    public let totalHoldings: Int
    public let lastUpdated: Date
}

/// Top holding information
public struct TopHoldingInfo {
    public let symbol: String
    public let name: String
    public let value: Decimal
    public let weight: Double
}

/// Portfolio service errors
public enum PortfolioError: LocalizedError {
    case creationFailed(Error)
    case updateFailed(Error)
    case deletionFailed(Error)
    case fetchFailed(Error)
    case holdingOperationFailed(Error)
    case transactionFailed(Error)
    case invalidPortfolioName
    case invalidCurrency
    case invalidHoldingSymbol
    case invalidQuantity
    case invalidPrice
    case duplicateHolding(String)
    case holdingNotFound(String)
    case insufficientQuantity(String, Decimal)
    
    public var errorDescription: String? {
        switch self {
        case .creationFailed(let error):
            return NSLocalizedString("error_portfolio_creation_failed", comment: "Portfolio creation failed") + ": \(error.localizedDescription)"
        case .updateFailed(let error):
            return NSLocalizedString("error_portfolio_update_failed", comment: "Portfolio update failed") + ": \(error.localizedDescription)"
        case .deletionFailed(let error):
            return NSLocalizedString("error_portfolio_deletion_failed", comment: "Portfolio deletion failed") + ": \(error.localizedDescription)"
        case .fetchFailed(let error):
            return NSLocalizedString("error_portfolio_fetch_failed", comment: "Portfolio fetch failed") + ": \(error.localizedDescription)"
        case .holdingOperationFailed(let error):
            return NSLocalizedString("error_holding_operation_failed", comment: "Holding operation failed") + ": \(error.localizedDescription)"
        case .transactionFailed(let error):
            return NSLocalizedString("error_transaction_failed", comment: "Transaction failed") + ": \(error.localizedDescription)"
        case .invalidPortfolioName:
            return NSLocalizedString("error_invalid_portfolio_name", comment: "Invalid portfolio name")
        case .invalidCurrency:
            return NSLocalizedString("error_invalid_currency", comment: "Invalid currency")
        case .invalidHoldingSymbol:
            return NSLocalizedString("error_invalid_holding_symbol", comment: "Invalid holding symbol")
        case .invalidQuantity:
            return NSLocalizedString("error_invalid_quantity", comment: "Invalid quantity")
        case .invalidPrice:
            return NSLocalizedString("error_invalid_price", comment: "Invalid price")
        case .duplicateHolding(let symbol):
            return NSLocalizedString("error_duplicate_holding", comment: "Duplicate holding") + ": \(symbol)"
        case .holdingNotFound(let symbol):
            return NSLocalizedString("error_holding_not_found", comment: "Holding not found") + ": \(symbol)"
        case .insufficientQuantity(let symbol, let available):
            return NSLocalizedString("error_insufficient_quantity", comment: "Insufficient quantity") + ": \(symbol) (available: \(available))"
        }
    }
}
