//
//  InsightsEngineTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Insights Engine Tests
//

import XCTest
import SwiftData
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class InsightsEngineTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var insightsEngine: InsightsEngine!
    
    @MainActor
    override func setUp() async throws {
        // Create in-memory model container
        let schema = Schema([
            Transaction.self,
            Goal.self,
            Report.self,
            TaxCalculation.self,
            Insight.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        
        insightsEngine = InsightsEngine(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        insightsEngine = nil
    }
    
    // MARK: - Rebalancing Insights Tests
    
    @MainActor
    func testGenerateRebalancingInsights_ImbalancedPortfolio() async throws {
        // Create imbalanced portfolio (80% equity, 10% debt, 10% gold)
        let equityAsset = CrossBorderAsset(
            name: "Equity Portfolio",
            assetType: .mutualFundsEquity,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 800000,
            nativeCurrencyCode: "INR"
        )
        
        let debtAsset = CrossBorderAsset(
            name: "Debt Portfolio",
            assetType: .bonds,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 100000,
            nativeCurrencyCode: "INR"
        )
        
        let goldAsset = CrossBorderAsset(
            name: "Gold Holdings",
            assetType: .gold,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 100000,
            nativeCurrencyCode: "INR"
        )
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [],
            assets: [equityAsset, debtAsset, goldAsset]
        )
        
        // Should generate rebalancing insight
        let rebalancingInsights = insights.filter { $0.category == .rebalancing }
        XCTAssertGreaterThan(rebalancingInsights.count, 0)
        XCTAssertTrue(rebalancingInsights[0].shouldShow)
    }
    
    @MainActor
    func testGenerateRebalancingInsights_BalancedPortfolio() async throws {
        // Create balanced portfolio (60% equity, 30% debt, 10% gold)
        let equityAsset = CrossBorderAsset(
            name: "Equity Portfolio",
            assetType: .mutualFundsEquity,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 600000,
            nativeCurrencyCode: "INR"
        )
        
        let debtAsset = CrossBorderAsset(
            name: "Debt Portfolio",
            assetType: .bonds,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 300000,
            nativeCurrencyCode: "INR"
        )
        
        let goldAsset = CrossBorderAsset(
            name: "Gold Holdings",
            assetType: .gold,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 100000,
            nativeCurrencyCode: "INR"
        )
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [],
            assets: [equityAsset, debtAsset, goldAsset]
        )
        
        // Should not generate rebalancing insight for balanced portfolio
        let rebalancingInsights = insights.filter { $0.category == .rebalancing }
        XCTAssertEqual(rebalancingInsights.count, 0)
    }
    
    // MARK: - Tax Saving Insights Tests
    
    @MainActor
    func testGenerateTaxSavingInsights_OpportunityExists() async throws {
        // Create transaction with low 80C investment
        let calendar = Calendar.current
        var fyComponents = DateComponents()
        fyComponents.year = 2024
        fyComponents.month = 4
        fyComponents.day = 1
        let fyStart = calendar.date(from: fyComponents)!
        
        let taxSaving = Transaction(
            amount: 50000, // Only 50k invested, 100k remaining
            transactionDescription: "PPF investment",
            date: fyStart,
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [taxSaving],
            goals: [],
            assets: []
        )
        
        // Should generate tax saving insight
        let taxSavingInsights = insights.filter { $0.category == .taxSaving }
        XCTAssertGreaterThan(taxSavingInsights.count, 0)
        XCTAssertNotNil(taxSavingInsights[0].impactAmount)
        XCTAssertGreaterThan(taxSavingInsights[0].impactAmount!, 0)
    }
    
    @MainActor
    func testGenerateTaxSavingInsights_LimitReached() async throws {
        // Create transaction with 80C limit reached
        let calendar = Calendar.current
        var fyComponents = DateComponents()
        fyComponents.year = 2024
        fyComponents.month = 4
        fyComponents.day = 1
        let fyStart = calendar.date(from: fyComponents)!
        
        let taxSaving = Transaction(
            amount: 150000, // Full limit
            transactionDescription: "PPF investment",
            date: fyStart,
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [taxSaving],
            goals: [],
            assets: []
        )
        
        // Should not generate tax saving insight when limit is reached
        let taxSavingInsights = insights.filter { $0.category == .taxSaving }
        XCTAssertEqual(taxSavingInsights.count, 0)
    }
    
    // MARK: - Performance Insights Tests
    
    @MainActor
    func testGeneratePerformanceInsights_UnderperformingAsset() async throws {
        // Create underperforming asset
        var asset = CrossBorderAsset(
            name: "Underperforming Stock",
            assetType: .stocks,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 70000,
            nativeCurrencyCode: "INR"
        )
        asset.originalInvestment = 100000 // -30% loss
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [],
            assets: [asset]
        )
        
        // Should generate underperforming asset insight
        let performanceInsights = insights.filter { $0.category == .underperforming }
        XCTAssertGreaterThan(performanceInsights.count, 0)
        XCTAssertEqual(performanceInsights[0].priority, .high) // >20% loss should be high priority
    }
    
    @MainActor
    func testGeneratePerformanceInsights_PerformingAsset() async throws {
        // Create well-performing asset
        var asset = CrossBorderAsset(
            name: "Performing Stock",
            assetType: .stocks,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 120000,
            nativeCurrencyCode: "INR"
        )
        asset.originalInvestment = 100000 // +20% gain
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [],
            assets: [asset]
        )
        
        // Should not generate underperforming insight for positive returns
        let performanceInsights = insights.filter { $0.category == .underperforming }
        XCTAssertEqual(performanceInsights.count, 0)
    }
    
    // MARK: - Goal Alignment Insights Tests
    
    @MainActor
    func testGenerateGoalAlignmentInsights_OffTrackGoal() async throws {
        // Create goal that is off track
        let goal = Goal(
            title: "House Down Payment",
            targetAmount: 5000000,
            targetDate: Calendar.current.date(byAdding: .year, value: 2, to: Date())!,
            priority: .critical
        )
        goal.currentAmount = 500000 // Only 10% achieved
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [goal],
            assets: []
        )
        
        // Should generate goal alignment insight
        let goalInsights = insights.filter { $0.category == .goalAlignment }
        XCTAssertGreaterThan(goalInsights.count, 0)
        XCTAssertEqual(goalInsights[0].priority, .urgent) // Critical goal should be urgent
    }
    
    @MainActor
    func testGenerateGoalAlignmentInsights_OnTrackGoal() async throws {
        // Create goal that is on track
        let goal = Goal(
            title: "Emergency Fund",
            targetAmount: 300000,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        )
        goal.currentAmount = 200000 // 67% achieved - on track
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [goal],
            assets: []
        )
        
        // Should not generate insight for on-track goal
        let goalInsights = insights.filter { $0.category == .goalAlignment }
        XCTAssertEqual(goalInsights.count, 0)
    }
    
    // MARK: - Diversification Insights Tests
    
    @MainActor
    func testGenerateDiversificationInsights_HighConcentration() async throws {
        // Create portfolio with high sector concentration
        var techAsset1 = CrossBorderAsset(
            name: "Tech Stock 1",
            assetType: .stocks,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 400000,
            nativeCurrencyCode: "INR"
        )
        techAsset1.sector = "Technology"
        
        var techAsset2 = CrossBorderAsset(
            name: "Tech Stock 2",
            assetType: .stocks,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 400000,
            nativeCurrencyCode: "INR"
        )
        techAsset2.sector = "Technology"
        
        var otherAsset = CrossBorderAsset(
            name: "Other Stock",
            assetType: .stocks,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 200000,
            nativeCurrencyCode: "INR"
        )
        otherAsset.sector = "Healthcare"
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [],
            goals: [],
            assets: [techAsset1, techAsset2, otherAsset]
        )
        
        // Should generate diversification insight (80% in tech)
        let diversificationInsights = insights.filter { $0.category == .diversification }
        XCTAssertGreaterThan(diversificationInsights.count, 0)
        XCTAssertEqual(diversificationInsights[0].priority, .high)
    }
    
    // MARK: - Comprehensive Insights Tests
    
    @MainActor
    func testGenerateInsights_ComprehensiveScenario() async throws {
        // Create comprehensive scenario with multiple insights
        
        // Imbalanced portfolio
        let equityAsset = CrossBorderAsset(
            name: "Equity Portfolio",
            assetType: .mutualFundsEquity,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 800000,
            nativeCurrencyCode: "INR"
        )
        
        // Underperforming asset
        var underperformer = CrossBorderAsset(
            name: "Bad Investment",
            assetType: .stocks,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 50000,
            nativeCurrencyCode: "INR"
        )
        underperformer.originalInvestment = 100000
        
        // Tax saving transaction (incomplete)
        let taxSaving = Transaction(
            amount: 30000,
            transactionDescription: "Small tax saving",
            date: Date(),
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        // Off-track goal
        let goal = Goal(
            title: "Retirement",
            targetAmount: 10000000,
            targetDate: Calendar.current.date(byAdding: .year, value: 5, to: Date())!,
            priority: .critical
        )
        goal.currentAmount = 500000
        
        let insights = try await insightsEngine.generateInsights(
            transactions: [taxSaving],
            goals: [goal],
            assets: [equityAsset, underperformer]
        )
        
        // Should generate multiple insights
        XCTAssertGreaterThan(insights.count, 0)
        
        // Verify different categories are present
        let categories = Set(insights.map { $0.category })
        XCTAssertTrue(categories.contains(.rebalancing))
        XCTAssertTrue(categories.contains(.taxSaving))
        XCTAssertTrue(categories.contains(.underperforming))
        XCTAssertTrue(categories.contains(.goalAlignment))
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testInsightsGenerationPerformance() async throws {
        // Create large dataset
        var assets: [CrossBorderAsset] = []
        var transactions: [Transaction] = []
        var goals: [Goal] = []
        
        // Create 50 assets
        for i in 0..<50 {
            let asset = CrossBorderAsset(
                name: "Asset \(i)",
                assetType: .stocks,
                domicileCountryCode: "IN",
                ownerCountryCode: "IN",
                currentValue: Decimal(10000 + i * 1000),
                nativeCurrencyCode: "INR"
            )
            assets.append(asset)
        }
        
        // Create 50 transactions
        for i in 0..<50 {
            let transaction = Transaction(
                amount: Decimal(5000 + i * 100),
                transactionDescription: "Transaction \(i)",
                date: Date(),
                transactionType: .income,
                category: .salary
            )
            transactions.append(transaction)
        }
        
        // Create 10 goals
        for i in 0..<10 {
            let goal = Goal(
                title: "Goal \(i)",
                targetAmount: Decimal((i + 1) * 100000),
                targetDate: Calendar.current.date(byAdding: .year, value: i + 1, to: Date())!
            )
            goals.append(goal)
        }
        
        measure {
            Task { @MainActor in
                _ = try? await insightsEngine.generateInsights(
                    transactions: transactions,
                    goals: goals,
                    assets: assets
                )
            }
        }
    }
}
