//
//  ComplianceRuleEngine.swift
//  WealthWise
//
//  Flexible rule engine for evaluating compliance across multiple jurisdictions
//

import Foundation

/// Rule engine for evaluating compliance requirements across jurisdictions
public final class ComplianceRuleEngine: Sendable {
    
    // MARK: - Properties
    
    private let countryCodes: Set<String>
    private var ruleCache: [UUID: ComplianceRule] = [:]
    private var countryRules: [String: [ComplianceRule]] = [:]
    
    // MARK: - Initialization
    
    public init(countryCodes: Set<String>) {
        self.countryCodes = countryCodes
        loadRules()
    }
    
    // MARK: - Rule Loading
    
    private func loadRules() {
        // Load rules for each country
        for countryCode in countryCodes {
            let rules = loadRulesForCountry(countryCode)
            countryRules[countryCode] = rules
            
            // Cache rules by ID
            for rule in rules {
                ruleCache[rule.id] = rule
            }
        }
    }
    
    private func loadRulesForCountry(_ countryCode: String) -> [ComplianceRule] {
        // Rules are loaded from country-specific rule providers
        switch countryCode.uppercased() {
        case "IN":
            return IndiaComplianceRules.getAllRules()
        case "US":
            return USComplianceRules.getAllRules()
        case "GB", "UK":
            return UKComplianceRules.getAllRules()
        case "CA":
            return CanadaComplianceRules.getAllRules()
        default:
            return CommonComplianceRules.getAllRules()
        }
    }
    
    // MARK: - Rule Retrieval
    
    /// Get all active rules
    public func getActiveRules() -> [ComplianceRule] {
        return Array(ruleCache.values).filter { $0.isActive && $0.isEffective }
    }
    
    /// Get rules for specific country
    public func getRules(forCountry countryCode: String) -> [ComplianceRule] {
        return countryRules[countryCode] ?? []
    }
    
    /// Get rules applicable to an asset
    public func getRulesForAsset(_ asset: CrossBorderAsset) -> [ComplianceRule] {
        let domicileRules = getRules(forCountry: asset.domicileCountryCode)
        let ownerRules = getRules(forCountry: asset.ownerCountryCode)
        
        let allRules = Set(domicileRules + ownerRules)
        
        return allRules.filter { rule in
            rule.isActive &&
            rule.isEffective &&
            rule.appliesTo(assetType: asset.assetType.rawValue)
        }
    }
    
    /// Get rules for specific compliance obligation
    public func getRulesForObligation(_ obligation: ComplianceObligation, countryCode: String) -> [ComplianceRule] {
        let countryRules = getRules(forCountry: countryCode)
        
        return countryRules.filter { rule in
            rule.isActive && rule.isEffective
        }
    }
    
    /// Get rules by type
    public func getRules(ofType ruleType: RuleType) -> [ComplianceRule] {
        return getActiveRules().filter { $0.ruleType == ruleType }
    }
    
    // MARK: - Rule Evaluation
    
    /// Evaluate rules against asset
    public func evaluateRules(for asset: CrossBorderAsset) -> [RuleEvaluationResult] {
        let applicableRules = getRulesForAsset(asset)
        
        return applicableRules.map { rule in
            evaluateRule(rule, for: asset)
        }
    }
    
    /// Evaluate single rule against asset
    public func evaluateRule(_ rule: ComplianceRule, for asset: CrossBorderAsset) -> RuleEvaluationResult {
        var result = RuleEvaluationResult(rule: rule, asset: asset)
        
        // Check threshold
        if let thresholdAmount = rule.thresholdAmount {
            result.isThresholdMet = asset.currentValue >= thresholdAmount
        }
        
        // Check applicability
        result.isApplicable = rule.appliesTo(assetType: asset.assetType.rawValue)
        
        // Determine compliance status
        if result.isApplicable && result.isThresholdMet {
            result.complianceStatus = .requiresAction
        } else if result.isApplicable {
            result.complianceStatus = .monitoring
        } else {
            result.complianceStatus = .notApplicable
        }
        
        return result
    }
    
    /// Check if asset exceeds any reporting thresholds
    public func checkThresholds(for asset: CrossBorderAsset) -> [ComplianceRule] {
        let rules = getRulesForAsset(asset)
        
        return rules.filter { rule in
            guard let threshold = rule.thresholdAmount else { return false }
            return asset.currentValue >= threshold
        }
    }
}

// MARK: - Supporting Types

/// Result of rule evaluation
public struct RuleEvaluationResult: Sendable {
    public let rule: ComplianceRule
    public let asset: CrossBorderAsset
    public var isApplicable: Bool = false
    public var isThresholdMet: Bool = false
    public var complianceStatus: EvaluationStatus = .notApplicable
    public let evaluatedAt: Date = Date()
    
    public init(rule: ComplianceRule, asset: CrossBorderAsset) {
        self.rule = rule
        self.asset = asset
    }
}

/// Status from rule evaluation
public enum EvaluationStatus: Sendable {
    case compliant
    case requiresAction
    case monitoring
    case notApplicable
}

// MARK: - Rule Providers (Stubs for country-specific rules)

/// India compliance rules
public struct IndiaComplianceRules {
    public static func getAllRules() -> [ComplianceRule] {
        return [
            // LRS Reporting
            ComplianceRule(
                ruleCode: "IN-LRS-001",
                ruleType: .threshold,
                countryCode: "IN",
                title: NSLocalizedString("lrs_annual_limit", comment: "LRS Annual Limit"),
                description: NSLocalizedString("lrs_limit_desc", comment: "India's Liberalised Remittance Scheme annual limit"),
                thresholdType: .annualAggregate,
                effectiveDate: Date(),
                deadlineType: .annual,
                alertDaysBefore: 30,
                severityLevel: .high,
                isMandatory: true,
                hasPenalties: true
            )
        ]
    }
}

/// US compliance rules
public struct USComplianceRules {
    public static func getAllRules() -> [ComplianceRule] {
        return [
            // FBAR Reporting
            ComplianceRule(
                ruleCode: "US-FBAR-001",
                ruleType: .reporting,
                countryCode: "US",
                title: NSLocalizedString("fbar_reporting", comment: "FBAR Reporting"),
                description: NSLocalizedString("fbar_desc", comment: "Foreign Bank Account Reporting"),
                thresholdType: .annualAggregate,
                effectiveDate: Date(),
                deadlineType: .annualTaxDay,
                alertDaysBefore: 60,
                severityLevel: .critical,
                isMandatory: true,
                hasPenalties: true
            )
        ]
    }
}

/// UK compliance rules
public struct UKComplianceRules {
    public static func getAllRules() -> [ComplianceRule] {
        return [
            // Overseas income reporting
            ComplianceRule(
                ruleCode: "UK-OI-001",
                ruleType: .reporting,
                countryCode: "GB",
                title: NSLocalizedString("uk_overseas_income", comment: "Overseas Income Reporting"),
                description: NSLocalizedString("uk_overseas_desc", comment: "UK overseas income reporting requirement"),
                thresholdType: .annualAggregate,
                effectiveDate: Date(),
                deadlineType: .annualTaxDay,
                alertDaysBefore: 60,
                severityLevel: .high,
                isMandatory: true,
                hasPenalties: true
            )
        ]
    }
}

/// Canada compliance rules
public struct CanadaComplianceRules {
    public static func getAllRules() -> [ComplianceRule] {
        return [
            // Foreign property reporting
            ComplianceRule(
                ruleCode: "CA-FP-001",
                ruleType: .reporting,
                countryCode: "CA",
                title: NSLocalizedString("ca_foreign_property", comment: "Foreign Property Reporting"),
                description: NSLocalizedString("ca_foreign_desc", comment: "Canada foreign property reporting"),
                thresholdType: .annualAggregate,
                effectiveDate: Date(),
                deadlineType: .annualTaxDay,
                alertDaysBefore: 60,
                severityLevel: .high,
                isMandatory: true,
                hasPenalties: true
            )
        ]
    }
}

/// Common compliance rules applicable across jurisdictions
public struct CommonComplianceRules {
    public static func getAllRules() -> [ComplianceRule] {
        return []
    }
}
