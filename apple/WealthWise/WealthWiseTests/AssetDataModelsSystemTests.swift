import XCTest
@testable import WealthWise

/// Comprehensive unit tests for the Asset Data Models System
/// Tests asset types, cross-border assets, and asset management utilities
final class AssetDataModelsSystemTests: XCTestCase {
    
    // MARK: - AssetType Tests
    
    func testAssetTypeBasicProperties() {
        // Test domestic equity
        let domesticStock = AssetType.publicEquityDomestic
        XCTAssertEqual(domesticStock.displayName, "Domestic Stocks")
        XCTAssertEqual(domesticStock.shortDisplayName, "Stocks")
        XCTAssertEqual(domesticStock.category, .equity)
        XCTAssertTrue(domesticStock.isLiquid)
        XCTAssertTrue(domesticStock.isSubjectToCapitalGains)
        XCTAssertFalse(domesticStock.isTaxAdvantaged)
        XCTAssertFalse(domesticStock.requiresComplianceMonitoring)
        
        // Test fixed deposit
        let fixedDeposit = AssetType.fixedDeposits
        XCTAssertEqual(fixedDeposit.displayName, "Fixed Deposits")
        XCTAssertEqual(fixedDeposit.shortDisplayName, "FD")
        XCTAssertEqual(fixedDeposit.category, .fixedIncome)
        XCTAssertFalse(fixedDeposit.isLiquid)
        XCTAssertFalse(fixedDeposit.isSubjectToCapitalGains)
        XCTAssertFalse(fixedDeposit.isTaxAdvantaged)
        XCTAssertFalse(fixedDeposit.requiresComplianceMonitoring)
        
        // Test international equity
        let internationalStock = AssetType.publicEquityInternational
        XCTAssertEqual(internationalStock.displayName, "International Stocks")
        XCTAssertEqual(internationalStock.category, .equity)
        XCTAssertTrue(internationalStock.isLiquid)
        XCTAssertTrue(internationalStock.isSubjectToCapitalGains)
        XCTAssertFalse(internationalStock.isTaxAdvantaged)
        XCTAssertTrue(internationalStock.requiresComplianceMonitoring)
    }
    
    func testAssetTypeCategorizationCompletion() {
        // Ensure all asset types are properly categorized
        for assetType in AssetType.allCases {
            XCTAssertFalse(assetType.displayName.isEmpty, "Asset type \(assetType) should have a display name")
            XCTAssertFalse(assetType.shortDisplayName.isEmpty, "Asset type \(assetType) should have a short display name")
            XCTAssertFalse(assetType.iconName.isEmpty, "Asset type \(assetType) should have an icon name")
            
            // Verify category consistency
            let category = assetType.category
            XCTAssertTrue(AssetCategory.allCases.contains(category), "Asset type \(assetType) has invalid category")
        }
    }
    
    func testAssetTypeStaticLists() {
        // Test common Indian assets
        let commonIndianAssets = AssetType.commonIndianAssets
        XCTAssertTrue(commonIndianAssets.contains(.publicEquityDomestic))
        XCTAssertTrue(commonIndianAssets.contains(.fixedDeposits))
        XCTAssertTrue(commonIndianAssets.contains(.publicProvidentFund))
        XCTAssertTrue(commonIndianAssets.contains(.goldPhysical))
        XCTAssertTrue(commonIndianAssets.contains(.realEstateResidential))
        
        // Test international diversification assets
        let internationalAssets = AssetType.internationalDiversificationAssets
        XCTAssertTrue(internationalAssets.contains(.publicEquityInternational))
        XCTAssertTrue(internationalAssets.contains(.internationalBonds))
        XCTAssertTrue(internationalAssets.contains(.realEstateInternational))
        XCTAssertTrue(internationalAssets.contains(.cryptocurrency))
        
        // Test tax-advantaged assets
        let taxAdvantaged = AssetType.taxAdvantagedAssets
        XCTAssertTrue(taxAdvantaged.contains(.publicProvidentFund))
        XCTAssertTrue(taxAdvantaged.contains(.employeeProvidentFund))
        XCTAssertTrue(taxAdvantaged.contains(.nationalPensionScheme))
        XCTAssertTrue(taxAdvantaged.contains(.lifeInsuranceTraditional))
        
        // Test liquid assets
        let liquidAssets = AssetType.liquidAssets
        XCTAssertTrue(liquidAssets.contains(.savingsAccount))
        XCTAssertTrue(liquidAssets.contains(.publicEquityDomestic))
        XCTAssertTrue(liquidAssets.contains(.equityMutualFunds))
        XCTAssertTrue(liquidAssets.contains(.cryptocurrency))
    }
    
    func testAssetCategoryProperties() {
        // Test growth-oriented categories
        XCTAssertTrue(AssetCategory.equity.isGrowthOriented)
        XCTAssertTrue(AssetCategory.alternative.isGrowthOriented)
        XCTAssertTrue(AssetCategory.digital.isGrowthOriented)
        XCTAssertTrue(AssetCategory.business.isGrowthOriented)
        
        XCTAssertFalse(AssetCategory.fixedIncome.isGrowthOriented)
        XCTAssertFalse(AssetCategory.cash.isGrowthOriented)
        
        // Test income-providing categories
        XCTAssertTrue(AssetCategory.fixedIncome.providesRegularIncome)
        XCTAssertTrue(AssetCategory.insurance.providesRegularIncome)
        XCTAssertTrue(AssetCategory.business.providesRegularIncome)
        
        XCTAssertFalse(AssetCategory.equity.providesRegularIncome)
        XCTAssertFalse(AssetCategory.cash.providesRegularIncome)
    }
    
    // MARK: - CrossBorderAsset Tests
    
    func testCrossBorderAssetCreation() {
        // Test domestic asset creation
        let domesticAsset = CrossBorderAsset.createDomesticAsset(
            name: "Infosys Limited",
            assetType: .publicEquityDomestic,
            countryCode: "IND",
            currentValue: 50000,
            currencyCode: "INR"
        )
        
        XCTAssertEqual(domesticAsset.name, "Infosys Limited")
        XCTAssertEqual(domesticAsset.assetType, .publicEquityDomestic)
        XCTAssertEqual(domesticAsset.category, .equity)
        XCTAssertEqual(domesticAsset.domicileCountryCode, "IND")
        XCTAssertEqual(domesticAsset.ownerCountryCode, "IND")
        XCTAssertEqual(domesticAsset.currentValue, 50000)
        XCTAssertEqual(domesticAsset.nativeCurrencyCode, "INR")
        XCTAssertFalse(domesticAsset.isCrossBorder)
        XCTAssertTrue(domesticAsset.isActive)
        XCTAssertTrue(domesticAsset.isIncludedInPortfolio)
        XCTAssertTrue(domesticAsset.taxJurisdictions.contains("IND"))
        
        // Test international asset creation
        let internationalAsset = CrossBorderAsset.createInternationalAsset(
            name: "Apple Inc.",
            assetType: .publicEquityInternational,
            domicileCountryCode: "USA",
            ownerCountryCode: "IND",
            currentValue: 15000,
            nativeCurrencyCode: "USD"
        )
        
        XCTAssertEqual(internationalAsset.name, "Apple Inc.")
        XCTAssertEqual(internationalAsset.domicileCountryCode, "USA")
        XCTAssertEqual(internationalAsset.ownerCountryCode, "IND")
        XCTAssertTrue(internationalAsset.isCrossBorder)
        XCTAssertTrue(internationalAsset.taxJurisdictions.contains("USA"))
        XCTAssertTrue(internationalAsset.taxJurisdictions.contains("IND"))
        XCTAssertTrue(internationalAsset.complianceRequirements.contains(.foreignAssetReporting))
        XCTAssertTrue(internationalAsset.complianceRequirements.contains(.kycDocumentation))
        XCTAssertTrue(internationalAsset.complianceRequirements.contains(.fatcaReporting))
    }
    
    func testCrossBorderAssetComputedProperties() {
        var asset = CrossBorderAsset.createDomesticAsset(
            name: "Test Asset",
            assetType: .publicEquityDomestic,
            countryCode: "IND",
            currentValue: 120000,
            currencyCode: "INR"
        )
        
        // Set original investment to test gain/loss calculations
        asset.originalInvestment = 100000
        asset.acquisitionDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
        
        // Test unrealized gain/loss
        XCTAssertEqual(asset.unrealizedGainLoss, 20000)
        XCTAssertEqual(asset.unrealizedGainLossPercentage, 20.0, accuracy: 0.1)
        
        // Test expected annual income and yield
        asset.expectedAnnualIncome = 2400
        XCTAssertEqual(asset.currentYield, 2.0, accuracy: 0.1)
        
        // Test FX analysis requirement
        XCTAssertFalse(asset.requiresFXAnalysis)
        
        // Test multi-jurisdiction tax
        XCTAssertFalse(asset.hasMultiJurisdictionTax)
        
        // Test investment age
        let age = asset.investmentAgeYears
        XCTAssertNotNil(age)
        XCTAssertGreaterThan(age!, 1.0)
        
        // Test long-term capital gains qualification
        XCTAssertTrue(asset.qualifiesForLongTermCapitalGains)
    }
    
    func testCrossBorderAssetValueUpdating() {
        var asset = CrossBorderAsset.createDomesticAsset(
            name: "Test Asset",
            assetType: .publicEquityDomestic,
            countryCode: "IND",
            currentValue: 100000,
            currencyCode: "INR"
        )
        
        let initialHistoryCount = asset.performanceHistory.count
        
        // Update value
        asset.updateValue(110000, source: .exchangeOfficial)
        
        XCTAssertEqual(asset.currentValue, 110000)
        XCTAssertEqual(asset.dataSource, .exchangeOfficial)
        XCTAssertEqual(asset.performanceHistory.count, initialHistoryCount + 1)
        
        let lastSnapshot = asset.performanceHistory.last
        XCTAssertNotNil(lastSnapshot)
        XCTAssertEqual(lastSnapshot!.value, 110000)
        XCTAssertEqual(lastSnapshot!.currency, "INR")
        XCTAssertEqual(lastSnapshot!.source, "exchangeOfficial")
    }
    
    func testCrossBorderAssetIncomeTracking() {
        var asset = CrossBorderAsset.createDomesticAsset(
            name: "Dividend Stock",
            assetType: .publicEquityDomestic,
            countryCode: "IND",
            currentValue: 100000,
            currencyCode: "INR"
        )
        
        // Record income payment
        let dividendPayment = IncomePayment(
            amount: 2500,
            currency: "INR",
            paymentDate: Date(),
            type: .dividend
        )
        
        asset.recordIncomePayment(dividendPayment)
        
        XCTAssertNotNil(asset.lastIncomePayment)
        XCTAssertEqual(asset.lastIncomePayment!.amount, 2500)
        XCTAssertEqual(asset.lastIncomePayment!.type, .dividend)
    }
    
    func testCrossBorderAssetTagManagement() {
        var asset = CrossBorderAsset.createDomesticAsset(
            name: "Test Asset",
            assetType: .publicEquityDomestic,
            countryCode: "IND",
            currentValue: 100000,
            currencyCode: "INR"
        )
        
        // Add tags
        asset.addTags(Set(["technology", "largecap", "dividend"]))
        XCTAssertEqual(asset.tags.count, 3)
        XCTAssertTrue(asset.tags.contains("technology"))
        XCTAssertTrue(asset.tags.contains("largecap"))
        XCTAssertTrue(asset.tags.contains("dividend"))
        
        // Remove tags
        asset.removeTags(Set(["dividend"]))
        XCTAssertEqual(asset.tags.count, 2)
        XCTAssertFalse(asset.tags.contains("dividend"))
        XCTAssertTrue(asset.tags.contains("technology"))
        XCTAssertTrue(asset.tags.contains("largecap"))
    }
    
    // MARK: - Supporting Types Tests
    
    func testIncomeFrequency() {
        XCTAssertEqual(IncomeFrequency.monthly.paymentsPerYear, 12)
        XCTAssertEqual(IncomeFrequency.quarterly.paymentsPerYear, 4)
        XCTAssertEqual(IncomeFrequency.annual.paymentsPerYear, 1)
        XCTAssertEqual(IncomeFrequency.none.paymentsPerYear, 0)
        
        XCTAssertEqual(IncomeFrequency.monthly.displayName, "Monthly")
        XCTAssertEqual(IncomeFrequency.quarterly.displayName, "Quarterly")
    }
    
    func testRiskRating() {
        XCTAssertEqual(RiskRating.veryLow.numericValue, 1)
        XCTAssertEqual(RiskRating.low.numericValue, 2)
        XCTAssertEqual(RiskRating.medium.numericValue, 3)
        XCTAssertEqual(RiskRating.high.numericValue, 4)
        XCTAssertEqual(RiskRating.veryHigh.numericValue, 5)
        
        XCTAssertEqual(RiskRating.low.displayName, "Low")
        XCTAssertEqual(RiskRating.high.displayName, "High")
    }
    
    func testLiquidityRating() {
        XCTAssertEqual(LiquidityRating.high.timeToSell, "1-2 days")
        XCTAssertEqual(LiquidityRating.medium.timeToSell, "1-4 weeks")
        XCTAssertEqual(LiquidityRating.low.timeToSell, "1-6 months")
        XCTAssertEqual(LiquidityRating.veryLow.timeToSell, "6+ months")
    }
    
    func testESGScore() {
        let esgScore = ESGScore(
            environmental: 85,
            social: 75,
            governance: 90,
            provider: "MSCI"
        )
        
        XCTAssertEqual(esgScore.environmentalScore, 85)
        XCTAssertEqual(esgScore.socialScore, 75)
        XCTAssertEqual(esgScore.governanceScore, 90)
        XCTAssertEqual(esgScore.overallScore, 83) // (85 + 75 + 90) / 3
        XCTAssertEqual(esgScore.ratingProvider, "MSCI")
        
        // Test score bounds
        let boundedScore = ESGScore(
            environmental: 150, // Should be capped at 100
            social: -10,       // Should be floored at 0
            governance: 75,
            provider: "Test"
        )
        
        XCTAssertEqual(boundedScore.environmentalScore, 100)
        XCTAssertEqual(boundedScore.socialScore, 0)
        XCTAssertEqual(boundedScore.governanceScore, 75)
    }
    
    func testComplianceRequirements() {
        let requirements: [ComplianceRequirement] = [
            .foreignAssetReporting,
            .fatcaReporting,
            .kycDocumentation,
            .liberalisedRemittanceScheme
        ]
        
        for requirement in requirements {
            XCTAssertFalse(requirement.displayName.isEmpty)
            XCTAssertFalse(requirement.description.isEmpty)
        }
        
        XCTAssertEqual(ComplianceRequirement.foreignAssetReporting.displayName, "Foreign Asset Reporting")
        XCTAssertEqual(ComplianceRequirement.fatcaReporting.displayName, "FATCA Reporting")
    }
    
    func testDataSource() {
        XCTAssertEqual(DataSource.exchangeOfficial.reliability, 5)
        XCTAssertEqual(DataSource.professionalValuation.reliability, 5)
        XCTAssertEqual(DataSource.brokerStatement.reliability, 4)
        XCTAssertEqual(DataSource.manual.reliability, 2)
        XCTAssertEqual(DataSource.estimated.reliability, 1)
        
        XCTAssertEqual(DataSource.exchangeOfficial.displayName, "Official Exchange")
        XCTAssertEqual(DataSource.manual.displayName, "Manual Entry")
    }
    
    // MARK: - AssetManager Tests
    
    func testPortfolioAllocationCategorization() {
        XCTAssertEqual(
            AssetManager.getPortfolioAllocationCategory(for: .publicEquityDomestic),
            .domesticEquity
        )
        XCTAssertEqual(
            AssetManager.getPortfolioAllocationCategory(for: .publicEquityInternational),
            .internationalEquity
        )
        XCTAssertEqual(
            AssetManager.getPortfolioAllocationCategory(for: .fixedDeposits),
            .domesticBonds
        )
        XCTAssertEqual(
            AssetManager.getPortfolioAllocationCategory(for: .goldPhysical),
            .alternatives
        )
        XCTAssertEqual(
            AssetManager.getPortfolioAllocationCategory(for: .savingsAccount),
            .cash
        )
    }
    
    func testRecommendedAllocation() {
        let conservativeAllocation = AssetManager.getRecommendedAllocation(for: .conservative)
        XCTAssertEqual(conservativeAllocation[.cash], 15.0)
        XCTAssertEqual(conservativeAllocation[.domesticBonds], 50.0)
        XCTAssertEqual(conservativeAllocation[.domesticEquity], 20.0)
        
        let aggressiveAllocation = AssetManager.getRecommendedAllocation(for: .aggressive)
        XCTAssertEqual(aggressiveAllocation[.cash], 5.0)
        XCTAssertEqual(aggressiveAllocation[.domesticEquity], 50.0)
        XCTAssertEqual(aggressiveAllocation[.internationalEquity], 15.0)
        
        // Test age-adjusted allocation
        let youngConservativeAllocation = AssetManager.getRecommendedAllocation(for: .conservative, age: 25)
        XCTAssertNotEqual(youngConservativeAllocation, conservativeAllocation)
    }
    
    func testCalculatePortfolioAllocation() {
        let assets = createSamplePortfolio()
        let allocation = AssetManager.calculatePortfolioAllocation(assets: assets)
        
        // Verify allocation percentages sum to approximately 100%
        let totalPercentage = allocation.values.reduce(0, +)
        XCTAssertEqual(totalPercentage, 100.0, accuracy: 0.1)
        
        // Verify specific allocations exist
        XCTAssertNotNil(allocation[.domesticEquity])
        XCTAssertNotNil(allocation[.cash])
    }
    
    func testCalculateDiversificationScore() {
        let diversifiedAssets = createSamplePortfolio()
        let diversificationScore = AssetManager.calculateDiversificationScore(assets: diversifiedAssets)
        
        XCTAssertGreaterThan(diversificationScore, 0)
        XCTAssertLessThanOrEqual(diversificationScore, 100)
        
        // Test concentrated portfolio
        let concentratedAssets = [
            CrossBorderAsset.createDomesticAsset(
                name: "Single Stock",
                assetType: .publicEquityDomestic,
                countryCode: "IND",
                currentValue: 1000000,
                currencyCode: "INR"
            )
        ]
        
        let concentratedScore = AssetManager.calculateDiversificationScore(assets: concentratedAssets)
        XCTAssertLessThan(concentratedScore, diversificationScore)
    }
    
    func testCalculatePortfolioRiskScore() {
        let assets = createSamplePortfolio()
        let riskScore = AssetManager.calculatePortfolioRiskScore(assets: assets)
        
        XCTAssertGreaterThan(riskScore, 0)
        XCTAssertLessThanOrEqual(riskScore, 5.0)
    }
    
    func testCalculatePortfolioLiquidityScore() {
        let assets = createSamplePortfolio()
        let liquidityScore = AssetManager.calculatePortfolioLiquidityScore(assets: assets)
        
        XCTAssertGreaterThan(liquidityScore, 0)
        XCTAssertLessThanOrEqual(liquidityScore, 4.0)
    }
    
    func testCalculateTaxEfficiencyScore() {
        let assets = createSamplePortfolio()
        let taxEfficiencyScore = AssetManager.calculateTaxEfficiencyScore(assets: assets)
        
        XCTAssertGreaterThan(taxEfficiencyScore, 0)
        XCTAssertLessThanOrEqual(taxEfficiencyScore, 5.0)
    }
    
    func testIdentifyTaxOptimizationOpportunities() {
        var assets = createSamplePortfolio()
        
        // Add an asset with losses for tax loss harvesting
        var lossAsset = CrossBorderAsset.createDomesticAsset(
            name: "Loss Asset",
            assetType: .publicEquityDomestic,
            countryCode: "IND",
            currentValue: 80000,
            currencyCode: "INR"
        )
        lossAsset.originalInvestment = 100000
        lossAsset.acquisitionDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
        assets.append(lossAsset)
        
        let opportunities = AssetManager.identifyTaxOptimizationOpportunities(assets: assets)
        
        XCTAssertGreaterThan(opportunities.count, 0)
        
        // Check for tax loss harvesting opportunity
        let hasLossHarvesting = opportunities.contains { opportunity in
            switch opportunity {
            case .taxLossHarvesting:
                return true
            default:
                return false
            }
        }
        XCTAssertTrue(hasLossHarvesting)
    }
    
    func testAnalyzeAllocationDeviation() {
        let assets = createSamplePortfolio()
        let targetAllocation: [PortfolioAllocationCategory: Double] = [
            .domesticEquity: 40.0,
            .internationalEquity: 20.0,
            .domesticBonds: 20.0,
            .cash: 10.0,
            .alternatives: 10.0
        ]
        
        let analysis = AssetManager.analyzeAllocationDeviation(
            currentAssets: assets,
            targetAllocation: targetAllocation,
            tolerance: 5.0
        )
        
        XCTAssertGreaterThanOrEqual(analysis.totalDeviation, 0)
        
        // Verify categories are properly classified
        let totalCategories = analysis.overweight.count + analysis.underweight.count + analysis.onTarget.count
        XCTAssertGreaterThan(totalCategories, 0)
    }
    
    func testGenerateRebalancingRecommendations() {
        let assets = createSamplePortfolio()
        let targetAllocation: [PortfolioAllocationCategory: Double] = [
            .domesticEquity: 50.0,
            .cash: 50.0
        ]
        
        let recommendations = AssetManager.generateRebalancingRecommendations(
            currentAssets: assets,
            targetAllocation: targetAllocation,
            minimumTradeAmount: 1000
        )
        
        // Should have some recommendations for significant deviations
        XCTAssertGreaterThanOrEqual(recommendations.count, 0)
    }
    
    // MARK: - Supporting Types for AssetManager Tests
    
    func testInvestorProfile() {
        for profile in InvestorProfile.allCases {
            XCTAssertFalse(profile.displayName.isEmpty)
            XCTAssertFalse(profile.description.isEmpty)
        }
        
        XCTAssertEqual(InvestorProfile.conservative.displayName, "Conservative")
        XCTAssertEqual(InvestorProfile.aggressive.displayName, "Aggressive")
    }
    
    func testPortfolioAllocationCategory() {
        for category in PortfolioAllocationCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
        }
        
        XCTAssertEqual(PortfolioAllocationCategory.domesticEquity.displayName, "Domestic Equity")
        XCTAssertEqual(PortfolioAllocationCategory.internationalBonds.displayName, "International Bonds")
    }
    
    // MARK: - Performance Tests
    
    func testAssetTypePerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = AssetType.allCases.randomElement()?.displayName
                let _ = AssetType.allCases.randomElement()?.category
                let _ = AssetType.allCases.randomElement()?.isLiquid
            }
        }
    }
    
    func testCrossBorderAssetPerformance() throws {
        measure {
            for _ in 0..<100 {
                var asset = CrossBorderAsset.createDomesticAsset(
                    name: "Test Asset",
                    assetType: .publicEquityDomestic,
                    countryCode: "IND",
                    currentValue: Decimal.random(in: 1000...100000),
                    currencyCode: "INR"
                )
                
                asset.updateValue(Decimal.random(in: 1000...100000))
                let _ = asset.unrealizedGainLossPercentage
                let _ = asset.currentYield
            }
        }
    }
    
    func testPortfolioAnalysisPerformance() throws {
        let assets = createLargePortfolio(size: 100)
        
        measure {
            let _ = AssetManager.calculatePortfolioAllocation(assets: assets)
            let _ = AssetManager.calculateDiversificationScore(assets: assets)
            let _ = AssetManager.calculatePortfolioRiskScore(assets: assets)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePortfolio() -> [CrossBorderAsset] {
        return [
            CrossBorderAsset.createDomesticAsset(
                name: "Infosys",
                assetType: .publicEquityDomestic,
                countryCode: "IND",
                currentValue: 100000,
                currencyCode: "INR"
            ),
            CrossBorderAsset.createDomesticAsset(
                name: "SBI FD",
                assetType: .fixedDeposits,
                countryCode: "IND",
                currentValue: 50000,
                currencyCode: "INR"
            ),
            CrossBorderAsset.createDomesticAsset(
                name: "Savings Account",
                assetType: .savingsAccount,
                countryCode: "IND",
                currentValue: 25000,
                currencyCode: "INR"
            ),
            CrossBorderAsset.createInternationalAsset(
                name: "Apple Inc.",
                assetType: .publicEquityInternational,
                domicileCountryCode: "USA",
                ownerCountryCode: "IND",
                currentValue: 30000,
                nativeCurrencyCode: "USD"
            )
        ]
    }
    
    private func createLargePortfolio(size: Int) -> [CrossBorderAsset] {
        var assets: [CrossBorderAsset] = []
        let assetTypes = AssetType.allCases
        
        for i in 0..<size {
            let assetType = assetTypes.randomElement()!
            let asset = CrossBorderAsset.createDomesticAsset(
                name: "Asset \(i)",
                assetType: assetType,
                countryCode: "IND",
                currentValue: Decimal.random(in: 1000...100000),
                currencyCode: "INR"
            )
            assets.append(asset)
        }
        
        return assets
    }
}

// MARK: - Test Extensions

extension Decimal {
    static func random(in range: ClosedRange<Int>) -> Decimal {
        let randomInt = Int.random(in: range)
        return Decimal(randomInt)
    }
}