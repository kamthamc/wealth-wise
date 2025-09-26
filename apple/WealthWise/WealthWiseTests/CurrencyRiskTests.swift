import XCTest
@testable import WealthWise

/// Comprehensive unit tests for CurrencyRisk model
/// Tests currency risk analysis, hedging strategies, and stress testing
final class CurrencyRiskTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testCurrencyRiskInitialization() {
        let assetId = UUID()
        let risk = CurrencyRisk(
            assetId: assetId,
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR", "GBP"]
        )
        
        XCTAssertEqual(risk.assetId, assetId)
        XCTAssertEqual(risk.baseCurrency, "INR")
        XCTAssertEqual(risk.exposedCurrencies, ["USD", "EUR", "GBP"])
        XCTAssertEqual(risk.hedgingPercentage, 0)
        XCTAssertEqual(risk.hedgingCost, 0)
        XCTAssertEqual(risk.overallRiskLevel, .unknown)
    }
    
    func testCurrencyRiskComputedProperties() {
        let risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR"]
        )
        
        // Test total exposure (should be 0 initially)
        XCTAssertEqual(risk.totalExposure, 0)
        
        // Test dominant currency (should be nil when no exposures)
        XCTAssertNil(risk.dominantCurrency)
        
        // Test hedging effectiveness (should be nil when no hedge or volatility data)
        XCTAssertNil(risk.hedgingEffectiveness)
        
        // Test is hedged (should be false with 0% hedging)
        XCTAssertFalse(risk.isHedged)
        
        // Test hedging strategy (should be none initially)
        XCTAssertEqual(risk.currentHedgingStrategy, .none)
    }
    
    // MARK: - Risk Level Tests
    
    func testRiskLevelCalculation() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        // Test very low risk
        risk.volatility = 0.03
        risk.valueAtRisk = -2.0
        XCTAssertEqual(risk.riskLevel, .veryLow)
        
        // Test low risk
        risk.volatility = 0.08
        risk.valueAtRisk = -6.0
        XCTAssertEqual(risk.riskLevel, .low)
        
        // Test medium risk
        risk.volatility = 0.15
        risk.valueAtRisk = -12.0
        XCTAssertEqual(risk.riskLevel, .medium)
        
        // Test high risk
        risk.volatility = 0.25
        risk.valueAtRisk = -20.0
        XCTAssertEqual(risk.riskLevel, .high)
        
        // Test very high risk  
        risk.volatility = 0.40
        risk.valueAtRisk = -35.0
        XCTAssertEqual(risk.riskLevel, .veryHigh)
    }
    
    func testRiskLevelProperties() {
        for riskLevel in RiskLevel.allCases {
            XCTAssertFalse(riskLevel.displayName.isEmpty, "Risk level \(riskLevel) should have display name")
            XCTAssertFalse(riskLevel.color.isEmpty, "Risk level \(riskLevel) should have color")
        }
        
        XCTAssertEqual(RiskLevel.low.displayName, "Low Risk")
        XCTAssertEqual(RiskLevel.high.displayName, "High Risk")
        XCTAssertEqual(RiskLevel.veryLow.color, "systemGreen")
        XCTAssertEqual(RiskLevel.veryHigh.color, "systemRed")
    }
    
    // MARK: - Hedging Strategy Tests
    
    func testHedgingStrategyProperties() {
        for strategy in HedgingStrategy.allCases {
            XCTAssertFalse(strategy.displayName.isEmpty, "Hedging strategy \(strategy) should have display name")
            XCTAssertFalse(strategy.description.isEmpty, "Hedging strategy \(strategy) should have description")
            XCTAssertGreaterThanOrEqual(strategy.costMultiplier, 0, "Cost multiplier should be non-negative")
            XCTAssertLessThanOrEqual(strategy.costMultiplier, 1, "Cost multiplier should not exceed 1")
        }
        
        XCTAssertEqual(HedgingStrategy.none.displayName, "No Hedging")
        XCTAssertEqual(HedgingStrategy.forwardContracts.displayName, "Forward Contracts")
        XCTAssertEqual(HedgingStrategy.currencyOptions.displayName, "Currency Options")
        XCTAssertEqual(HedgingStrategy.currencySwaps.displayName, "Currency Swaps")
        XCTAssertEqual(HedgingStrategy.naturalHedge.displayName, "Natural Hedge")
        
        XCTAssertEqual(HedgingStrategy.none.costMultiplier, 0)
        XCTAssertGreaterThan(HedgingStrategy.currencyOptions.costMultiplier, HedgingStrategy.forwardContracts.costMultiplier)
    }
    
    // MARK: - Currency Exposure Tests
    
    func testCurrencyExposure() {
        let exposure = CurrencyExposure(
            currency: "USD",
            amount: 10000,
            percentage: 60.0,
            volatility: 0.12,
            correlation: 0.25
        )
        
        XCTAssertEqual(exposure.currency, "USD")
        XCTAssertEqual(exposure.amount, 10000)
        XCTAssertEqual(exposure.percentage, 60.0)
        XCTAssertEqual(exposure.volatility, 0.12)
        XCTAssertEqual(exposure.correlation, 0.25)
        XCTAssertEqual(exposure.riskLevel, .medium) // 12% volatility = medium risk
        XCTAssertEqual(exposure.riskContribution, 7.2) // 60% * 12% volatility
    }
    
    func testCurrencyExposureRiskLevels() {
        var exposure = CurrencyExposure(currency: "USD", amount: 1000, percentage: 50.0)
        
        // Test very low risk
        exposure.volatility = 0.03
        XCTAssertEqual(exposure.riskLevel, .veryLow)
        
        // Test high risk
        exposure.volatility = 0.25
        XCTAssertEqual(exposure.riskLevel, .high)
        
        // Test very high risk
        exposure.volatility = 0.40
        XCTAssertEqual(exposure.riskLevel, .veryHigh)
    }
    
    // MARK: - Stress Test Result Tests
    
    func testStressTestResult() {
        let result = StressTestResult()
        result.testName = "2008 Financial Crisis"
        result.scenarioDescription = "Major global financial crisis with high volatility"
        result.projectedLoss = -25.5
        result.confidence = 0.95
        result.timeHorizon = 252 // 1 year trading days
        result.impactedCurrencies = ["USD", "EUR", "GBP"]
        
        XCTAssertEqual(result.testName, "2008 Financial Crisis")
        XCTAssertEqual(result.projectedLoss, -25.5)
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertEqual(result.timeHorizon, 252)
        XCTAssertEqual(result.impactedCurrencies.count, 3)
        XCTAssertEqual(result.severity, .high) // -25.5% loss = high severity
    }
    
    func testStressTestResultSeverity() {
        var result = StressTestResult()
        
        // Test low severity
        result.projectedLoss = -3.0
        XCTAssertEqual(result.severity, .low)
        
        // Test medium severity
        result.projectedLoss = -12.0
        XCTAssertEqual(result.severity, .medium)
        
        // Test high severity
        result.projectedLoss = -25.0
        XCTAssertEqual(result.severity, .high)
        
        // Test extreme severity
        result.projectedLoss = -45.0
        XCTAssertEqual(result.severity, .extreme)
    }
    
    // MARK: - Hedging Recommendation Tests
    
    func testHedgingRecommendation() {
        let recommendation = HedgingRecommendation(
            strategy: .forwardContracts,
            hedgeRatio: 0.75,
            estimatedCost: 0.025,
            expectedReduction: 0.60,
            timeHorizon: 180
        )
        recommendation.reasoning = "High USD exposure with increasing volatility"
        recommendation.confidence = 0.85
        
        XCTAssertEqual(recommendation.strategy, .forwardContracts)
        XCTAssertEqual(recommendation.hedgeRatio, 0.75)
        XCTAssertEqual(recommendation.estimatedCost, 0.025)
        XCTAssertEqual(recommendation.expectedReduction, 0.60)
        XCTAssertEqual(recommendation.timeHorizon, 180)
        XCTAssertEqual(recommendation.reasoning, "High USD exposure with increasing volatility")
        XCTAssertEqual(recommendation.confidence, 0.85)
        XCTAssertEqual(recommendation.priority, .high) // 75% hedge ratio = high priority
    }
    
    func testHedgingRecommendationPriority() {
        var recommendation = HedgingRecommendation(strategy: .none, hedgeRatio: 0.2, estimatedCost: 0.01, expectedReduction: 0.15)
        XCTAssertEqual(recommendation.priority, .low) // 20% hedge ratio = low priority
        
        recommendation.hedgeRatio = 0.5
        XCTAssertEqual(recommendation.priority, .medium) // 50% hedge ratio = medium priority
        
        recommendation.hedgeRatio = 0.8
        XCTAssertEqual(recommendation.priority, .high) // 80% hedge ratio = high priority
        
        recommendation.hedgeRatio = 0.95
        XCTAssertEqual(recommendation.priority, .critical) // 95% hedge ratio = critical priority
    }
    
    // MARK: - Currency Risk Management Tests
    
    func testCurrencyExposureManagement() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",  
            exposedCurrencies: ["USD", "EUR"]
        )
        
        let usdExposure = CurrencyExposure(
            currency: "USD",
            amount: 10000,
            percentage: 60.0,
            volatility: 0.15,
            correlation: 0.30
        )
        
        let eurExposure = CurrencyExposure(
            currency: "EUR",
            amount: 5000,
            percentage: 40.0,
            volatility: 0.12,
            correlation: 0.25
        )
        
        // Add exposures
        risk.addCurrencyExposure(usdExposure)
        risk.addCurrencyExposure(eurExposure)
        
        XCTAssertEqual(risk.currencyExposures.count, 2)
        XCTAssertEqual(risk.totalExposure, 15000)
        XCTAssertEqual(risk.dominantCurrency, "USD") // Highest exposure
        
        // Remove exposure
        risk.removeCurrencyExposure(currency: "EUR")
        
        XCTAssertEqual(risk.currencyExposures.count, 1)
        XCTAssertEqual(risk.totalExposure, 10000)
        XCTAssertEqual(risk.dominantCurrency, "USD")
    }
    
    func testStressTestManagement() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        let crisisTest = StressTestResult()
        crisisTest.testName = "Financial Crisis"
        crisisTest.projectedLoss = -20.0
        crisisTest.confidence = 0.95
        
        let recessionTest = StressTestResult()
        recessionTest.testName = "Economic Recession"
        recessionTest.projectedLoss = -12.0
        recessionTest.confidence = 0.90
        
        // Add stress tests
        risk.addStressTestResult(crisisTest)
        risk.addStressTestResult(recessionTest)
        
        XCTAssertEqual(risk.stressTestResults.count, 2)
        XCTAssertNotNil(risk.stressTestResults["Financial Crisis"])
        XCTAssertNotNil(risk.stressTestResults["Economic Recession"])
        
        // Remove stress test
        risk.removeStressTestResult(testName: "Economic Recession")
        
        XCTAssertEqual(risk.stressTestResults.count, 1)
        XCTAssertNil(risk.stressTestResults["Economic Recession"])
        XCTAssertNotNil(risk.stressTestResults["Financial Crisis"])
    }
    
    func testHedgingRecommendationManagement() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR"]
        )
        
        let forwardRec = HedgingRecommendation(
            strategy: .forwardContracts,
            hedgeRatio: 0.75,
            estimatedCost: 0.02,
            expectedReduction: 0.60
        )
        
        let optionRec = HedgingRecommendation(
            strategy: .currencyOptions,
            hedgeRatio: 0.50,
            estimatedCost: 0.035,
            expectedReduction: 0.45
        )
        
        // Add recommendations
        risk.addHedgingRecommendation(forwardRec)
        risk.addHedgingRecommendation(optionRec)
        
        XCTAssertEqual(risk.hedgingRecommendations.count, 2)
        
        // Get best recommendation (should be forward contracts with higher expected reduction)
        let bestRec = risk.getBestHedgingRecommendation()
        XCTAssertNotNil(bestRec)
        XCTAssertEqual(bestRec?.strategy, .forwardContracts)
        
        // Clear recommendations
        risk.clearHedgingRecommendations()
        XCTAssertEqual(risk.hedgingRecommendations.count, 0)
    }
    
    // MARK: - Risk Calculation Tests
    
    func testRiskCalculations() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR"]
        )
        
        let usdExposure = CurrencyExposure(
            currency: "USD",
            amount: 12000,
            percentage: 60.0,
            volatility: 0.15,
            correlation: 0.30
        )
        
        let eurExposure = CurrencyExposure(
            currency: "EUR",
            amount: 8000,
            percentage: 40.0,
            volatility: 0.12,
            correlation: 0.25
        )
        
        risk.addCurrencyExposure(usdExposure)
        risk.addCurrencyExposure(eurExposure)
        
        let originalUpdatedAt = risk.updatedAt
        Thread.sleep(forTimeInterval: 0.1)
        
        // Calculate risk metrics
        risk.calculateRiskMetrics()
        
        // Should have calculated portfolio volatility
        XCTAssertGreaterThan(risk.volatility ?? 0, 0)
        XCTAssertGreaterThan(risk.updatedAt, originalUpdatedAt)
        
        // Portfolio volatility should be less than sum of individual volatilities due to correlation
        let individualSum = 0.60 * 0.15 + 0.40 * 0.12 // Weighted sum = 0.138
        XCTAssertLessThan(risk.volatility ?? 1.0, individualSum)
    }
    
    func testVarCalculation() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        risk.volatility = 0.20
        let portfolioValue: Decimal = 100000
        
        let originalUpdatedAt = risk.updatedAt
        Thread.sleep(forTimeInterval: 0.1)
        
        // Calculate VaR
        risk.calculateValueAtRisk(portfolioValue: portfolioValue, confidence: 0.95, timeHorizon: 1)
        
        XCTAssertNotNil(risk.valueAtRisk)
        XCTAssertLessThan(risk.valueAtRisk ?? 0, 0) // VaR should be negative (loss)
        XCTAssertGreaterThan(risk.updatedAt, originalUpdatedAt)
        
        // VaR should be reasonable (around 1.65 * volatility * sqrt(time) * value for 95% confidence)
        let expectedVaR = -1.65 * 0.20 * 1.0 * Double(truncating: portfolioValue as NSNumber)
        let actualVaR = risk.valueAtRisk ?? 0
        XCTAssertLessThan(abs(actualVaR - expectedVaR), 5000) // Allow some tolerance
    }
    
    // MARK: - Hedging Analysis Tests
    
    func testHedgingEffectivenessCalculation() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        risk.volatility = 0.20 // Pre-hedge volatility
        risk.hedgingPercentage = 75.0 // 75% hedged
        risk.currentHedgingStrategy = .forwardContracts
        
        // Simulate post-hedge volatility calculation
        let postHedgeVolatility = 0.20 * (1.0 - 0.75 * 0.85) // 85% effectiveness for forwards
        
        let effectiveness = risk.calculateHedgingEffectiveness(postHedgeVolatility: postHedgeVolatility)
        
        XCTAssertNotNil(effectiveness)
        XCTAssertGreaterThan(effectiveness ?? 0, 0.8) // Should be > 80% effective
        XCTAssertLessThan(effectiveness ?? 1, 1.0) // Should be < 100% effective
    }
    
    func testHedgingCostCalculation() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        let portfolioValue: Decimal = 100000
        risk.hedgingPercentage = 50.0 // 50% hedged
        risk.currentHedgingStrategy = .currencyOptions
        
        let originalUpdatedAt = risk.updatedAt
        Thread.sleep(forTimeInterval: 0.1)
        
        // Calculate hedging cost
        risk.calculateHedgingCost(portfolioValue: portfolioValue, timeHorizon: 90)
        
        XCTAssertGreaterThan(risk.hedgingCost, 0) // Should have positive cost
        XCTAssertGreaterThan(risk.updatedAt, originalUpdatedAt)
        
        // Cost should be reasonable (hedge percentage * cost multiplier * portfolio value)
        let expectedCostRange = Double(truncating: portfolioValue as NSNumber) * 0.5 * 0.01 // ~0.5% for options
        XCTAssertLessThan(risk.hedgingCost, expectedCostRange * 2) // Allow some tolerance
    }
    
    // MARK: - Automatic Recommendation Tests
    
    func testAutomaticRecommendationGeneration() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        // Set up high risk scenario
        risk.volatility = 0.30 // High volatility
        risk.valueAtRisk = -25000 // High VaR
        
        let usdExposure = CurrencyExposure(
            currency: "USD",
            amount: 80000,
            percentage: 80.0, // High concentration
            volatility: 0.25,
            correlation: 0.40
        )
        risk.addCurrencyExposure(usdExposure)
        
        let originalRecommendationCount = risk.hedgingRecommendations.count
        
        // Generate recommendations
        risk.generateHedgingRecommendations(portfolioValue: 100000)
        
        XCTAssertGreaterThan(risk.hedgingRecommendations.count, originalRecommendationCount)
        
        // Should recommend hedging for high risk
        let bestRec = risk.getBestHedgingRecommendation()
        XCTAssertNotNil(bestRec)
        XCTAssertGreaterThan(bestRec?.hedgeRatio ?? 0, 0.5) // Should recommend significant hedging
    }
    
    // MARK: - Portfolio Risk Analysis Tests
    
    func testPortfolioRiskAnalysis() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR", "GBP"]
        )
        
        // Add multiple exposures
        risk.addCurrencyExposure(CurrencyExposure(
            currency: "USD",
            amount: 50000,
            percentage: 50.0,
            volatility: 0.15,
            correlation: 0.30
        ))
        
        risk.addCurrencyExposure(CurrencyExposure(
            currency: "EUR",
            amount: 30000,
            percentage: 30.0,
            volatility: 0.12,
            correlation: 0.25
        ))
        
        risk.addCurrencyExposure(CurrencyExposure(
            currency: "GBP",
            amount: 20000,
            percentage: 20.0,
            volatility: 0.18,
            correlation: 0.35
        ))
        
        // Perform comprehensive analysis
        risk.performPortfolioRiskAnalysis(portfolioValue: 100000)
        
        // Should have calculated portfolio metrics
        XCTAssertNotNil(risk.volatility)
        XCTAssertNotNil(risk.valueAtRisk)
        XCTAssertGreaterThan(risk.hedgingRecommendations.count, 0)
        
        // Overall risk level should be calculated
        XCTAssertNotEqual(risk.overallRiskLevel, .unknown)
    }
    
    // MARK: - Codable Tests
    
    func testCurrencyRiskCodable() throws {
        let originalRisk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR"]
        )
        
        originalRisk.volatility = 0.18
        originalRisk.valueAtRisk = -15000
        originalRisk.hedgingPercentage = 60.0
        originalRisk.notes = "High FX risk due to USD exposure"
        
        let usdExposure = CurrencyExposure(
            currency: "USD",
            amount: 12000,
            percentage: 60.0,
            volatility: 0.15,
            correlation: 0.30
        )
        originalRisk.addCurrencyExposure(usdExposure)
        
        let recommendation = HedgingRecommendation(
            strategy: .forwardContracts,
            hedgeRatio: 0.75,
            estimatedCost: 0.025,
            expectedReduction: 0.60
        )
        originalRisk.addHedgingRecommendation(recommendation)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalRisk)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedRisk = try decoder.decode(CurrencyRisk.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedRisk.id, originalRisk.id)
        XCTAssertEqual(decodedRisk.assetId, originalRisk.assetId)
        XCTAssertEqual(decodedRisk.baseCurrency, originalRisk.baseCurrency)
        XCTAssertEqual(decodedRisk.exposedCurrencies, originalRisk.exposedCurrencies)
        XCTAssertEqual(decodedRisk.volatility, originalRisk.volatility)
        XCTAssertEqual(decodedRisk.valueAtRisk, originalRisk.valueAtRisk)
        XCTAssertEqual(decodedRisk.hedgingPercentage, originalRisk.hedgingPercentage)
        XCTAssertEqual(decodedRisk.notes, originalRisk.notes)
        XCTAssertEqual(decodedRisk.currencyExposures.count, originalRisk.currencyExposures.count)
        XCTAssertEqual(decodedRisk.hedgingRecommendations.count, originalRisk.hedgingRecommendations.count)
    }
    
    // MARK: - Hashable and Equatable Tests
    
    func testCurrencyRiskHashableEquatable() {
        let id = UUID()
        let risk1 = CurrencyRisk(
            id: id,
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        let risk2 = CurrencyRisk(
            id: id, // Same ID
            assetId: UUID(), // Different asset ID
            baseCurrency: "USD", // Different base currency
            exposedCurrencies: ["EUR"] // Different exposed currencies
        )
        
        let risk3 = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        
        // Same ID should be equal
        XCTAssertEqual(risk1, risk2)
        XCTAssertEqual(risk1.hashValue, risk2.hashValue)
        
        // Different ID should not be equal
        XCTAssertNotEqual(risk1, risk3)
        XCTAssertNotEqual(risk1.hashValue, risk3.hashValue)
    }
    
    // MARK: - Performance Tests
    
    func testCurrencyRiskCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let risk = CurrencyRisk(
                    assetId: UUID(),
                    baseCurrency: ["INR", "USD", "EUR"].randomElement()!,
                    exposedCurrencies: ["USD", "EUR", "GBP", "JPY"].shuffled().prefix(Int.random(in: 1...3)).map(String.init)
                )
                
                let _ = risk.riskLevel
                let _ = risk.totalExposure
                let _ = risk.dominantCurrency
            }
        }
    }
    
    func testCurrencyRiskCalculationPerformance() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR", "GBP"]
        )
        
        // Add some exposures
        for (i, currency) in ["USD", "EUR", "GBP"].enumerated() {
            let exposure = CurrencyExposure(
                currency: currency,
                amount: Decimal(Double.random(in: 1000...50000)),
                percentage: Double.random(in: 10...50),
                volatility: Double.random(in: 0.05...0.30),
                correlation: Double.random(in: 0.1...0.8)
            )
            risk.addCurrencyExposure(exposure)
        }
        
        measure {
            for _ in 0..<100 {
                risk.calculateRiskMetrics()
                risk.calculateValueAtRisk(portfolioValue: 100000, confidence: 0.95, timeHorizon: 1)
                risk.generateHedgingRecommendations(portfolioValue: 100000)
                risk.performPortfolioRiskAnalysis(portfolioValue: 100000)
            }
        }
    }
    
    func testCurrencyExposureManagementPerformance() {
        var risk = CurrencyRisk(
            assetId: UUID(),
            baseCurrency: "INR",
            exposedCurrencies: []
        )
        
        let currencies = ["USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "SGD"]
        
        measure {
            for i in 0..<100 {
                let currency = currencies[i % currencies.count]
                let exposure = CurrencyExposure(
                    currency: "\(currency)\(i)",
                    amount: Decimal(Double.random(in: 1000...50000)),
                    percentage: Double.random(in: 5...30),
                    volatility: Double.random(in: 0.05...0.25),
                    correlation: Double.random(in: 0.1...0.6)
                )
                
                risk.addCurrencyExposure(exposure)
                
                if i % 10 == 0 && risk.currencyExposures.count > 5 {
                    let randomCurrency = risk.currencyExposures.keys.randomElement()!
                    risk.removeCurrencyExposure(currency: randomCurrency)
                }
            }
        }
    }
}