//
//  ComplianceRuleTests.swift
//  WealthWiseTests
//
//  Unit tests for ComplianceRule model
//

import XCTest
@testable import WealthWise

final class ComplianceRuleTests: XCTestCase {
    
    func testComplianceRuleInitialization() {
        let rule = ComplianceRule(
            ruleCode: "TEST-001",
            ruleType: .reporting,
            countryCode: "IN",
            title: "Test Rule",
            description: "Test compliance rule",
            thresholdType: .annualAggregate,
            effectiveDate: Date(),
            deadlineType: .annual,
            alertDaysBefore: 30,
            severityLevel: .high,
            isMandatory: true,
            hasPenalties: true
        )
        
        XCTAssertEqual(rule.ruleCode, "TEST-001")
        XCTAssertEqual(rule.ruleType, .reporting)
        XCTAssertEqual(rule.countryCode, "IN")
        XCTAssertTrue(rule.isActive)
    }
    
    func testComplianceRuleEffectiveness() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        
        let rule = ComplianceRule(
            ruleCode: "TEST-002",
            ruleType: .threshold,
            countryCode: "US",
            title: "Test Rule",
            description: "Test",
            thresholdType: .annualAggregate,
            effectiveDate: pastDate,
            deadlineType: .annual,
            alertDaysBefore: 30,
            severityLevel: .medium,
            isMandatory: true,
            hasPenalties: false
        )
        
        XCTAssertTrue(rule.isEffective)
    }
    
    func testThresholdExceeded() {
        var rule = ComplianceRule(
            ruleCode: "TEST-003",
            ruleType: .threshold,
            countryCode: "IN",
            title: "Threshold Test",
            description: "Test",
            thresholdType: .annualAggregate,
            effectiveDate: Date(),
            deadlineType: .annual,
            alertDaysBefore: 30,
            severityLevel: .high,
            isMandatory: true,
            hasPenalties: true
        )
        
        rule.thresholdAmount = Decimal(100000)
        
        XCTAssertTrue(rule.isThresholdExceeded(for: Decimal(100000)))
        XCTAssertTrue(rule.isThresholdExceeded(for: Decimal(150000)))
        XCTAssertFalse(rule.isThresholdExceeded(for: Decimal(50000)))
    }
    
    func testApplicableAssetTypes() {
        var rule = ComplianceRule(
            ruleCode: "TEST-004",
            ruleType: .reporting,
            countryCode: "US",
            title: "Asset Type Test",
            description: "Test",
            thresholdType: .annualAggregate,
            effectiveDate: Date(),
            deadlineType: .annual,
            alertDaysBefore: 30,
            severityLevel: .medium,
            isMandatory: true,
            hasPenalties: false
        )
        
        XCTAssertTrue(rule.appliesTo(assetType: "publicEquityDomestic"))
        
        rule.applicableAssetTypes = ["publicEquityDomestic"]
        XCTAssertTrue(rule.appliesTo(assetType: "publicEquityDomestic"))
        XCTAssertFalse(rule.appliesTo(assetType: "realEstateCommercial"))
    }
    
    func testSeverityLevelNumericValues() {
        XCTAssertEqual(SeverityLevel.critical.numericValue, 5)
        XCTAssertEqual(SeverityLevel.high.numericValue, 4)
        XCTAssertEqual(SeverityLevel.medium.numericValue, 3)
        XCTAssertEqual(SeverityLevel.low.numericValue, 2)
        XCTAssertEqual(SeverityLevel.informational.numericValue, 1)
    }
    
    func testComplianceRuleCodable() throws {
        let rule = ComplianceRule(
            ruleCode: "TEST-006",
            ruleType: .withholding,
            countryCode: "CA",
            title: "Codable Test",
            description: "Test codable",
            thresholdType: .transactionBased,
            effectiveDate: Date(),
            deadlineType: .quarterly,
            alertDaysBefore: 15,
            severityLevel: .medium,
            isMandatory: true,
            hasPenalties: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)
        
        let decoder = JSONDecoder()
        let decodedRule = try decoder.decode(ComplianceRule.self, from: data)
        
        XCTAssertEqual(rule.id, decodedRule.id)
        XCTAssertEqual(rule.ruleCode, decodedRule.ruleCode)
    }
}
