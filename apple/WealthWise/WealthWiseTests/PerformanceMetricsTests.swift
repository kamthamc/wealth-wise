import XCTest
@testable import WealthWise

/// Comprehensive unit tests for PerformanceMetrics model
/// Tests performance tracking, risk metrics, and comparative analysis
final class PerformanceMetricsTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testPerformanceMetricsInitialization() {
        let assetId = UUID()
        let metrics = PerformanceMetrics(
            assetId: assetId,
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        XCTAssertEqual(metrics.assetId, assetId)
        XCTAssertEqual(metrics.baseCurrency, "INR")
        XCTAssertEqual(metrics.totalReturnAmount, 10000)
        XCTAssertEqual(metrics.totalReturnPercentage, 15.5)
        XCTAssertEqual(metrics.priceReturnAmount, 0)
        XCTAssertEqual(metrics.priceReturnPercentage, 0)
        XCTAssertEqual(metrics.incomeReturnAmount, 0)
        XCTAssertEqual(metrics.incomeReturnPercentage, 0)
        XCTAssertEqual(metrics.dataQualityScore, 100)
        XCTAssertEqual(metrics.confidenceLevel, 1.0)
        XCTAssertEqual(metrics.calculationMethod, .timeWeighted)
    }
    
    func testPerformanceMetricsComputedProperties() {
        let metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        // Test data freshness
        XCTAssertTrue(metrics.isDataFresh) // Just created, should be fresh
        
        // Test risk level (no volatility set, should be unknown)
        XCTAssertEqual(metrics.riskLevel, .unknown)
        
        // Test performance rating (no 1-year return set, should be not rated)
        XCTAssertEqual(metrics.performanceRating, .notRated)
        
        // Test currency diversification (no currency exposure set)
        XCTAssertEqual(metrics.currencyDiversificationScore, 0)
        
        // Test effective yield
        XCTAssertEqual(metrics.effectiveYield, 0) // No income return set
        
        // Test risk-adjusted score
        XCTAssertEqual(metrics.riskAdjustedScore, 15.5) // No Sharpe ratio, returns total return
    }
    
    // MARK: - Risk Level Tests
    
    func testRiskLevelCalculation() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        // Test very low risk
        metrics.volatility = 0.02
        XCTAssertEqual(metrics.riskLevel, .veryLow)
        
        // Test low risk
        metrics.volatility = 0.08
        XCTAssertEqual(metrics.riskLevel, .low)
        
        // Test medium risk
        metrics.volatility = 0.18
        XCTAssertEqual(metrics.riskLevel, .medium)
        
        // Test high risk
        metrics.volatility = 0.30
        XCTAssertEqual(metrics.riskLevel, .high)
        
        // Test very high risk
        metrics.volatility = 0.45
        XCTAssertEqual(metrics.riskLevel, .veryHigh)
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
    
    // MARK: - Performance Rating Tests
    
    func testPerformanceRatingCalculation() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        // Test excellent performance (high return, low volatility)
        metrics.returns1Year = 25.0
        metrics.volatility = 0.05
        XCTAssertEqual(metrics.performanceRating, .excellent)
        
        // Test good performance
        metrics.returns1Year = 15.0
        metrics.volatility = 0.10
        XCTAssertEqual(metrics.performanceRating, .good)
        
        // Test average performance
        metrics.returns1Year = 8.0
        metrics.volatility = 0.15
        XCTAssertEqual(metrics.performanceRating, .average)
        
        // Test below average performance
        metrics.returns1Year = -5.0
        metrics.volatility = 0.10
        XCTAssertEqual(metrics.performanceRating, .belowAverage)
        
        // Test poor performance
        metrics.returns1Year = -15.0
        metrics.volatility = 0.20
        XCTAssertEqual(metrics.performanceRating, .poor)
    }
    
    func testPerformanceRatingProperties() {
        for rating in PerformanceRating.allCases {
            XCTAssertFalse(rating.displayName.isEmpty, "Performance rating \(rating) should have display name")
            XCTAssertGreaterThanOrEqual(rating.stars, 0, "Performance rating \(rating) should have valid star count")
            XCTAssertLessThanOrEqual(rating.stars, 5, "Performance rating \(rating) should have valid star count")
        }
        
        XCTAssertEqual(PerformanceRating.excellent.stars, 5)
        XCTAssertEqual(PerformanceRating.good.stars, 4)
        XCTAssertEqual(PerformanceRating.average.stars, 3)
        XCTAssertEqual(PerformanceRating.belowAverage.stars, 2)
        XCTAssertEqual(PerformanceRating.poor.stars, 1)
        XCTAssertEqual(PerformanceRating.notRated.stars, 0)
    }
    
    // MARK: - Calculation Method Tests
    
    func testCalculationMethodProperties() {
        for method in CalculationMethod.allCases {
            XCTAssertFalse(method.displayName.isEmpty, "Calculation method \(method) should have display name")
            XCTAssertFalse(method.description.isEmpty, "Calculation method \(method) should have description")
        }
        
        XCTAssertEqual(CalculationMethod.timeWeighted.displayName, "Time-Weighted Return")
        XCTAssertEqual(CalculationMethod.moneyWeighted.displayName, "Money-Weighted Return (IRR)")
        XCTAssertTrue(CalculationMethod.timeWeighted.description.contains("eliminating impact"))
        XCTAssertTrue(CalculationMethod.moneyWeighted.description.contains("Internal rate"))
    }
    
    // MARK: - Benchmark Comparison Tests
    
    func testBenchmarkComparison() {
        let comparison = BenchmarkComparison(
            benchmarkName: "NIFTY 50",
            benchmarkReturn: 12.5,
            relativeReturn: 3.0, // Asset outperformed by 3%
            trackingError: 2.5,
            informationRatio: 1.2,
            correlationCoefficient: 0.85
        )
        
        XCTAssertEqual(comparison.benchmarkName, "NIFTY 50")
        XCTAssertEqual(comparison.benchmarkReturn, 12.5)
        XCTAssertEqual(comparison.relativeReturn, 3.0)
        XCTAssertEqual(comparison.trackingError, 2.5)
        XCTAssertEqual(comparison.informationRatio, 1.2)
        XCTAssertEqual(comparison.correlationCoefficient, 0.85)
        XCTAssertTrue(comparison.outperformed)
        XCTAssertEqual(comparison.performanceDifference, "+3.00%")
        
        // Test underperformance
        let underperformingComparison = BenchmarkComparison(
            benchmarkName: "S&P 500",
            benchmarkReturn: 15.0,
            relativeReturn: -2.5
        )
        
        XCTAssertFalse(underperformingComparison.outperformed)
        XCTAssertEqual(underperformingComparison.performanceDifference, "-2.50%")
    }
    
    // MARK: - Update Methods Tests
    
    func testUpdateReturns() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        let originalUpdatedAt = metrics.updatedAt
        
        // Sleep to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.1)
        
        metrics.updateReturns(
            totalReturn: 12000,
            totalReturnPercentage: 18.0,
            priceReturn: 8000,
            priceReturnPercentage: 12.0,
            incomeReturn: 4000,
            incomeReturnPercentage: 6.0
        )
        
        XCTAssertEqual(metrics.totalReturnAmount, 12000)
        XCTAssertEqual(metrics.totalReturnPercentage, 18.0)
        XCTAssertEqual(metrics.priceReturnAmount, 8000)
        XCTAssertEqual(metrics.priceReturnPercentage, 12.0)
        XCTAssertEqual(metrics.incomeReturnAmount, 4000)
        XCTAssertEqual(metrics.incomeReturnPercentage, 6.0)
        XCTAssertGreaterThan(metrics.updatedAt, originalUpdatedAt)
        XCTAssertGreaterThan(metrics.lastDataUpdate, originalUpdatedAt)
    }
    
    func testUpdateRiskMetrics() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        let originalUpdatedAt = metrics.updatedAt
        Thread.sleep(forTimeInterval: 0.1)
        
        metrics.updateRiskMetrics(
            volatility: 0.18,
            maxDrawdown: -15.2,
            sharpeRatio: 0.95,
            beta: 1.15,
            alpha: 2.5,
            valueAtRisk: -8500
        )
        
        XCTAssertEqual(metrics.volatility, 0.18)
        XCTAssertEqual(metrics.maxDrawdown, -15.2)
        XCTAssertEqual(metrics.sharpeRatio, 0.95)
        XCTAssertEqual(metrics.beta, 1.15)
        XCTAssertEqual(metrics.alpha, 2.5)
        XCTAssertEqual(metrics.valueAtRisk5Percent, -8500)
        XCTAssertGreaterThan(metrics.updatedAt, originalUpdatedAt)
    }
    
    func testBenchmarkComparisonManagement() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        let niftyComparison = BenchmarkComparison(
            benchmarkName: "NIFTY 50",
            benchmarkReturn: 12.5,
            relativeReturn: 3.0
        )
        
        let sensexComparison = BenchmarkComparison(
            benchmarkName: "SENSEX",
            benchmarkReturn: 13.0,
            relativeReturn: 2.5
        )
        
        // Add benchmarks
        metrics.addBenchmarkComparison(niftyComparison)
        metrics.addBenchmarkComparison(sensexComparison)
        
        XCTAssertEqual(metrics.benchmarkComparisons.count, 2)
        XCTAssertNotNil(metrics.benchmarkComparisons["NIFTY 50"])
        XCTAssertNotNil(metrics.benchmarkComparisons["SENSEX"])
        
        // Remove benchmark
        metrics.removeBenchmarkComparison(benchmarkName: "NIFTY 50")
        
        XCTAssertEqual(metrics.benchmarkComparisons.count, 1)
        XCTAssertNil(metrics.benchmarkComparisons["NIFTY 50"])
        XCTAssertNotNil(metrics.benchmarkComparisons["SENSEX"])
    }
    
    func testCurrencyExposureManagement() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        let currencyExposure = [
            "INR": 60.0,
            "USD": 30.0,
            "EUR": 10.0
        ]
        
        metrics.updateCurrencyExposure(currencyExposure)
        
        XCTAssertEqual(metrics.currencyExposure, currencyExposure)
        XCTAssertEqual(metrics.currencyDiversificationScore, 40) // 100 - 60 (top exposure)
    }
    
    // MARK: - Data Quality Tests
    
    func testDataQualityCalculation() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        // Initially should have perfect score
        XCTAssertEqual(metrics.dataQualityScore, 100)
        
        // Reduce data point count
        metrics.dataPointCount = 20 // Less than 30
        metrics.calculateDataQualityScore()
        XCTAssertLessThan(metrics.dataQualityScore, 100)
        
        // Set stale data
        metrics.lastDataUpdate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        metrics.calculateDataQualityScore()
        XCTAssertLessThan(metrics.dataQualityScore, 90)
        
        // Missing critical data
        metrics.returns1Year = nil
        metrics.volatility = nil
        metrics.sharpeRatio = nil
        metrics.calculateDataQualityScore()
        XCTAssertLessThan(metrics.dataQualityScore, 50)
    }
    
    // MARK: - Performance Summary Tests
    
    func testPerformanceSummaryGeneration() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        metrics.returns1Year = 12.5
        metrics.volatility = 0.18
        metrics.sharpeRatio = 0.95
        
        let summary = metrics.generatePerformanceSummary()
        
        XCTAssertTrue(summary.contains("Total Return: 15.50%"))
        XCTAssertTrue(summary.contains("1-Year Return: 12.50%"))
        XCTAssertTrue(summary.contains("Volatility: 18.00%"))
        XCTAssertTrue(summary.contains("Sharpe Ratio: 0.95"))
        XCTAssertTrue(summary.contains("Risk Level: Medium Risk"))
        XCTAssertTrue(summary.contains("Performance Rating:"))
    }
    
    // MARK: - Codable Tests
    
    func testPerformanceMetricsCodable() throws {
        let originalMetrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "USD",
            totalReturnAmount: 5000,
            totalReturnPercentage: 25.0
        )
        
        originalMetrics.returns1Year = 20.0
        originalMetrics.volatility = 0.15
        originalMetrics.sharpeRatio = 1.2
        originalMetrics.notes = "Strong performer"
        
        let niftyComparison = BenchmarkComparison(
            benchmarkName: "NIFTY 50",
            benchmarkReturn: 15.0,
            relativeReturn: 5.0
        )
        originalMetrics.addBenchmarkComparison(niftyComparison)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalMetrics)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedMetrics = try decoder.decode(PerformanceMetrics.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedMetrics.id, originalMetrics.id)
        XCTAssertEqual(decodedMetrics.assetId, originalMetrics.assetId)
        XCTAssertEqual(decodedMetrics.baseCurrency, originalMetrics.baseCurrency)
        XCTAssertEqual(decodedMetrics.totalReturnAmount, originalMetrics.totalReturnAmount)
        XCTAssertEqual(decodedMetrics.totalReturnPercentage, originalMetrics.totalReturnPercentage)
        XCTAssertEqual(decodedMetrics.returns1Year, originalMetrics.returns1Year)
        XCTAssertEqual(decodedMetrics.volatility, originalMetrics.volatility)
        XCTAssertEqual(decodedMetrics.sharpeRatio, originalMetrics.sharpeRatio)
        XCTAssertEqual(decodedMetrics.notes, originalMetrics.notes)
        XCTAssertEqual(decodedMetrics.benchmarkComparisons.count, originalMetrics.benchmarkComparisons.count)
    }
    
    // MARK: - Hashable and Equatable Tests
    
    func testPerformanceMetricsHashableEquatable() {
        let id = UUID()
        let metrics1 = PerformanceMetrics(
            id: id,
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        let metrics2 = PerformanceMetrics(
            id: id, // Same ID
            assetId: UUID(), // Different asset ID
            baseCurrency: "USD", // Different currency
            totalReturnAmount: 5000,
            totalReturnPercentage: 10.0
        )
        
        let metrics3 = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        // Same ID should be equal
        XCTAssertEqual(metrics1, metrics2)
        XCTAssertEqual(metrics1.hashValue, metrics2.hashValue)
        
        // Different ID should not be equal
        XCTAssertNotEqual(metrics1, metrics3)
        XCTAssertNotEqual(metrics1.hashValue, metrics3.hashValue)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMetricsCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let metrics = PerformanceMetrics(
                    assetId: UUID(),
                    baseCurrency: "INR",
                    totalReturnAmount: Decimal(Double.random(in: 1000...100000)),
                    totalReturnPercentage: Double.random(in: -20...50)
                )
                
                let _ = metrics.riskLevel
                let _ = metrics.performanceRating
                let _ = metrics.isDataFresh
            }
        }
    }
    
    func testPerformanceMetricsUpdatePerformance() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        measure {
            for _ in 0..<1000 {
                metrics.updateReturns(
                    totalReturn: Decimal(Double.random(in: 1000...100000)),
                    totalReturnPercentage: Double.random(in: -20...50)
                )
                
                metrics.updateRiskMetrics(
                    volatility: Double.random(in: 0.05...0.5),
                    sharpeRatio: Double.random(in: -2...3)
                )
                
                metrics.calculateDataQualityScore()
            }
        }
    }
    
    func testBenchmarkComparisonPerformance() {
        var metrics = PerformanceMetrics(
            assetId: UUID(),
            baseCurrency: "INR",
            totalReturnAmount: 10000,
            totalReturnPercentage: 15.5
        )
        
        measure {
            for i in 0..<100 {
                let comparison = BenchmarkComparison(
                    benchmarkName: "Benchmark \(i)",
                    benchmarkReturn: Double.random(in: 5...20),
                    relativeReturn: Double.random(in: -10...10)
                )
                
                metrics.addBenchmarkComparison(comparison)
                
                if i % 10 == 0 {
                    metrics.removeBenchmarkComparison(benchmarkName: "Benchmark \(i-5)")
                }
            }
        }
    }
}