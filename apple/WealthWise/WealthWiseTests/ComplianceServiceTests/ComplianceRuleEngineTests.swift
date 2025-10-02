//
//  ComplianceRuleEngineTests.swift
//  WealthWiseTests
//
//  Unit tests for ComplianceRuleEngine
//

import XCTest
@testable import WealthWise

final class ComplianceRuleEngineTests: XCTestCase {
    
    var ruleEngine: ComplianceRuleEngine!
    
    override func setUp() {
        super.setUp()
        ruleEngine = ComplianceRuleEngine(countryCodes: ["IN", "US", "GB", "CA"])
    }
    
    override func tearDown() {
        ruleEngine = nil
        super.tearDown()
    }
    
    func testRuleEngineInitialization() {
        XCTAssertNotNil(ruleEngine)
    }
    
    func testGetActiveRules() {
        let activeRules = ruleEngine.getActiveRules()
        XCTAssertNotNil(activeRules)
        XCTAssertGreaterThan(activeRules.count, 0, "Should have at least one active rule")
    }
    
    func testGetRulesForCountry() {
        let indiaRules = ruleEngine.getRules(forCountry: "IN")
        XCTAssertNotNil(indiaRules)
        
        let usRules = ruleEngine.getRules(forCountry: "US")
        XCTAssertNotNil(usRules)
    }
    
    func testGetRulesForAsset() {
        let crossBorderAsset = CrossBorderAsset(
            name: "International Stock",
            assetType: .publicEquityInternational,
            domicileCountryCode: "US",
            ownerCountryCode: "IN",
            currentValue: 150000,
            nativeCurrencyCode: "USD"
        )
        
        let rules = ruleEngine.getRulesForAsset(crossBorderAsset)
        XCTAssertNotNil(rules)
    }
    
    func testGetRulesForObligation() {
        let rules = ruleEngine.getRulesForObligation(.foreignAssetReporting, countryCode: "IN")
        XCTAssertNotNil(rules)
    }
    
    func testGetRulesByType() {
        let reportingRules = ruleEngine.getRules(ofType: .reporting)
        XCTAssertNotNil(reportingRules)
        XCTAssertTrue(reportingRules.allSatisfy { $0.ruleType == .reporting })
    }
    
    func testEvaluateRulesForAsset() {
        let asset = CrossBorderAsset(
            name: "Test Asset",
            assetType: .publicEquityInternational,
            domicileCountryCode: "US",
            ownerCountryCode: "IN",
            currentValue: 200000,
            nativeCurrencyCode: "USD"
        )
        
        let results = ruleEngine.evaluateRules(for: asset)
        XCTAssertNotNil(results)
    }
    
    func testCheckThresholds() {
        let asset = CrossBorderAsset(
            name: "High Value Asset",
            assetType: .publicEquityInternational,
            domicileCountryCode: "US",
            ownerCountryCode: "IN",
            currentValue: 300000,
            nativeCurrencyCode: "USD"
        )
        
        let exceededRules = ruleEngine.checkThresholds(for: asset)
        XCTAssertNotNil(exceededRules)
    }
    
    func testIndiaComplianceRules() {
        let indiaRules = IndiaComplianceRules.getAllRules()
        XCTAssertGreaterThan(indiaRules.count, 0, "India should have compliance rules")
        XCTAssertTrue(indiaRules.allSatisfy { $0.countryCode == "IN" })
    }
    
    func testUSComplianceRules() {
        let usRules = USComplianceRules.getAllRules()
        XCTAssertGreaterThan(usRules.count, 0, "US should have compliance rules")
        XCTAssertTrue(usRules.allSatisfy { $0.countryCode == "US" })
    }
    
    func testUKComplianceRules() {
        let ukRules = UKComplianceRules.getAllRules()
        XCTAssertGreaterThan(ukRules.count, 0, "UK should have compliance rules")
        XCTAssertTrue(ukRules.allSatisfy { $0.countryCode == "GB" })
    }
    
    func testCanadaComplianceRules() {
        let canadaRules = CanadaComplianceRules.getAllRules()
        XCTAssertGreaterThan(canadaRules.count, 0, "Canada should have compliance rules")
        XCTAssertTrue(canadaRules.allSatisfy { $0.countryCode == "CA" })
    }
    
    func testRuleEvaluationResult() {
        let rule = ComplianceRule(
            ruleCode: "TEST-001",
            ruleType: .threshold,
            countryCode: "IN",
            title: "Test Rule",
            description: "Test",
            thresholdType: .annualAggregate,
            effectiveDate: Date(),
            deadlineType: .annual,
            alertDaysBefore: 30,
            severityLevel: .high,
            isMandatory: true,
            hasPenalties: true
        )
        
        let asset = CrossBorderAsset(
            name: "Test Asset",
            assetType: .publicEquityDomestic,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 100000,
            nativeCurrencyCode: "INR"
        )
        
        let result = ruleEngine.evaluateRule(rule, for: asset)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.rule.id, rule.id)
        XCTAssertEqual(result.asset.id, asset.id)
    }
}
