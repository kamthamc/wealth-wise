import XCTest
@testable import WealthWise

/// Comprehensive unit tests for TaxResidencyStatus model
/// Tests tax residency classification, compliance obligations, and document management
final class TaxResidencyStatusTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testTaxResidencyStatusInitialization() {
        let status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        XCTAssertEqual(status.countryCode, "IN")
        XCTAssertEqual(status.residencyType, .taxResident)
        XCTAssertEqual(status.taxYear, "FY2024-25")
        XCTAssertEqual(status.documentType, .taxResidencyCertificate)
        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.verificationStatus, .pending)
        XCTAssertFalse(status.complianceObligations.isEmpty)
    }
    
    func testTaxResidencyStatusComputedProperties() {
        let status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        // Test validity
        XCTAssertTrue(status.isValid)
        
        // Test expiry calculations
        XCTAssertNil(status.daysUntilExpiry) // No expiry date set
        XCTAssertFalse(status.requiresRenewal)
        
        // Set expiry date and test
        let futureDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        var statusWithExpiry = status
        statusWithExpiry.expiryDate = futureDate
        
        XCTAssertNotNil(statusWithExpiry.daysUntilExpiry)
        XCTAssertTrue(statusWithExpiry.requiresRenewal) // Less than 90 days
    }
    
    // MARK: - Residency Type Tests
    
    func testResidencyTypeProperties() {
        let taxResident = ResidencyType.taxResident
        XCTAssertEqual(taxResident.displayName, "Tax Resident")
        XCTAssertFalse(taxResident.description.isEmpty)
        
        let nonResident = ResidencyType.nonResidentOrdinary
        XCTAssertEqual(nonResident.displayName, "Non-Resident Ordinary")
        XCTAssertFalse(nonResident.description.isEmpty)
        
        let dualResident = ResidencyType.dualResident
        XCTAssertEqual(dualResident.displayName, "Dual Tax Resident")
        XCTAssertFalse(dualResident.description.isEmpty)
    }
    
    func testAllResidencyTypesHaveDisplayNames() {
        for residencyType in ResidencyType.allCases {
            XCTAssertFalse(residencyType.displayName.isEmpty, "Residency type \(residencyType) should have display name")
            XCTAssertFalse(residencyType.description.isEmpty, "Residency type \(residencyType) should have description")
        }
    }
    
    // MARK: - Document Type Tests
    
    func testDocumentTypeProperties() {
        let taxCert = ResidencyDocumentType.taxResidencyCertificate
        XCTAssertEqual(taxCert.displayName, "Tax Residency Certificate")
        
        let formW8 = ResidencyDocumentType.formW8
        XCTAssertEqual(formW8.displayName, "Form W-8 (US)")
        
        let form15G = ResidencyDocumentType.form15G
        XCTAssertEqual(form15G.displayName, "Form 15G (India)")
    }
    
    func testAllDocumentTypesHaveDisplayNames() {
        for documentType in ResidencyDocumentType.allCases {
            XCTAssertFalse(documentType.displayName.isEmpty, "Document type \(documentType) should have display name")
        }
    }
    
    // MARK: - Verification Status Tests
    
    func testDocumentVerificationStatus() {
        let pending = DocumentVerificationStatus.pending
        XCTAssertEqual(pending.displayName, "Pending Verification")
        XCTAssertFalse(pending.isValid)
        
        let verified = DocumentVerificationStatus.verified
        XCTAssertEqual(verified.displayName, "Verified")
        XCTAssertTrue(verified.isValid)
        
        let expired = DocumentVerificationStatus.expired
        XCTAssertEqual(expired.displayName, "Expired")
        XCTAssertFalse(expired.isValid)
        
        let renewed = DocumentVerificationStatus.renewed
        XCTAssertEqual(renewed.displayName, "Renewed")
        XCTAssertTrue(renewed.isValid)
    }
    
    // MARK: - Compliance Obligations Tests
    
    func testComplianceObligationsSetup() {
        // Test tax resident obligations
        let taxResident = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        XCTAssertTrue(taxResident.complianceObligations.contains(.incomeTaxFiling))
        XCTAssertTrue(taxResident.complianceObligations.contains(.capitalGainsTaxReporting))
        XCTAssertTrue(taxResident.complianceObligations.contains(.foreignAssetReporting))
        
        // Test non-resident obligations
        let nonResident = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .nonResidentOrdinary,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .nonResidencyDeclaration
        )
        
        XCTAssertTrue(nonResident.complianceObligations.contains(.withholdingTaxCompliance))
        XCTAssertTrue(nonResident.complianceObligations.contains(.limitedTaxFiling))
        XCTAssertFalse(nonResident.complianceObligations.contains(.incomeTaxFiling))
    }
    
    func testCountrySpecificCompliance() {
        // Test India-specific compliance
        let indiaResident = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        XCTAssertTrue(indiaResident.complianceObligations.contains(.liberalizedRemittanceScheme))
        XCTAssertEqual(indiaResident.reportingThresholds["USD"], 250000)
        
        // Test US-specific compliance
        let usResident = TaxResidencyStatus(
            countryCode: "US",
            residencyType: .taxResident,
            taxYear: "2024",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        XCTAssertTrue(usResident.complianceObligations.contains(.fatcaCompliance))
        XCTAssertTrue(usResident.complianceObligations.contains(.fbardReporting))
        XCTAssertEqual(usResident.reportingThresholds["USD"], 10000)
    }
    
    func testComplianceObligationProperties() {
        for obligation in ComplianceObligation.allCases {
            XCTAssertFalse(obligation.displayName.isEmpty, "Obligation \(obligation) should have display name")
            XCTAssertFalse(obligation.description.isEmpty, "Obligation \(obligation) should have description")
        }
        
        let lrs = ComplianceObligation.liberalizedRemittanceScheme
        XCTAssertEqual(lrs.displayName, "LRS Compliance (India)")
        XCTAssertTrue(lrs.description.contains("$250,000"))
        
        let fatca = ComplianceObligation.fatcaCompliance
        XCTAssertEqual(fatca.displayName, "FATCA Compliance (US)")
        XCTAssertTrue(fatca.description.contains("Foreign Account Tax Compliance Act"))
    }
    
    // MARK: - Tax Rates and Thresholds Tests
    
    func testWithholdingTaxRates() {
        var status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        // Test setting withholding tax rates
        status.setWithholdingTaxRate(20.0, for: "dividends")
        status.setWithholdingTaxRate(10.0, for: "interest")
        
        XCTAssertEqual(status.getWithholdingTaxRate(for: "dividends"), 20.0)
        XCTAssertEqual(status.getWithholdingTaxRate(for: "interest"), 10.0)
        XCTAssertNil(status.getWithholdingTaxRate(for: "capital_gains"))
    }
    
    func testReportingThresholds() {
        var status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        // Test setting reporting thresholds
        status.setReportingThreshold(1000000, for: "INR")
        status.setReportingThreshold(50000, for: "USD")
        
        XCTAssertEqual(status.getReportingThreshold(for: "INR"), 1000000)
        XCTAssertEqual(status.getReportingThreshold(for: "USD"), 50000)
        XCTAssertNil(status.getReportingThreshold(for: "EUR"))
    }
    
    // MARK: - Document Management Tests
    
    func testDocumentVerification() {
        var status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        // Initially pending
        XCTAssertEqual(status.verificationStatus, .pending)
        XCTAssertFalse(status.verificationStatus.isValid)
        
        // Mark as verified
        status.markDocumentVerified()
        XCTAssertEqual(status.verificationStatus, .verified)
        XCTAssertTrue(status.verificationStatus.isValid)
        
        // Mark as expired
        status.markDocumentExpired()
        XCTAssertEqual(status.verificationStatus, .expired)
        XCTAssertFalse(status.verificationStatus.isValid)
        XCTAssertFalse(status.isActive)
        
        // Renew document
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        status.renewDocument(expiryDate: futureDate)
        XCTAssertEqual(status.verificationStatus, .renewed)
        XCTAssertTrue(status.verificationStatus.isValid)
        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.expiryDate, futureDate)
    }
    
    // MARK: - Compliance Management Tests
    
    func testComplianceObligationManagement() {
        var status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        let initialCount = status.complianceObligations.count
        
        // Add new obligation
        status.addComplianceObligation(.crsReporting)
        XCTAssertEqual(status.complianceObligations.count, initialCount + 1)
        XCTAssertTrue(status.complianceObligations.contains(.crsReporting))
        
        // Remove existing obligation
        status.removeComplianceObligation(.incomeTaxFiling)
        XCTAssertFalse(status.complianceObligations.contains(.incomeTaxFiling))
        
        // Update all obligations
        status.updateComplianceObligations()
        // Should reset to default obligations for tax resident in India
        XCTAssertTrue(status.complianceObligations.contains(.incomeTaxFiling))
    }
    
    // MARK: - Codable Tests
    
    func testTaxResidencyStatusCodable() throws {
        let originalStatus = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .dualResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .treatyBenefitClaim
        )
        
        originalStatus.documentNumber = "TRC-2024-001"
        originalStatus.issuingAuthority = "Income Tax Department"
        originalStatus.notes = "Dual resident with treaty benefits"
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalStatus)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedStatus = try decoder.decode(TaxResidencyStatus.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedStatus.id, originalStatus.id)
        XCTAssertEqual(decodedStatus.countryCode, originalStatus.countryCode)
        XCTAssertEqual(decodedStatus.residencyType, originalStatus.residencyType)
        XCTAssertEqual(decodedStatus.taxYear, originalStatus.taxYear)
        XCTAssertEqual(decodedStatus.documentType, originalStatus.documentType)
        XCTAssertEqual(decodedStatus.documentNumber, originalStatus.documentNumber)
        XCTAssertEqual(decodedStatus.issuingAuthority, originalStatus.issuingAuthority)
        XCTAssertEqual(decodedStatus.notes, originalStatus.notes)
        XCTAssertEqual(decodedStatus.complianceObligations, originalStatus.complianceObligations)
    }
    
    // MARK: - Hashable and Equatable Tests
    
    func testTaxResidencyStatusHashableEquatable() {
        let status1 = TaxResidencyStatus(
            id: UUID(),
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        let status2 = TaxResidencyStatus(
            id: status1.id, // Same ID
            countryCode: "US", // Different country
            residencyType: .nonResidentOrdinary,
            taxYear: "2024",
            effectiveDate: Date(),
            documentType: .formW8
        )
        
        let status3 = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        // Same ID should be equal
        XCTAssertEqual(status1, status2)
        XCTAssertEqual(status1.hashValue, status2.hashValue)
        
        // Different ID should not be equal
        XCTAssertNotEqual(status1, status3)
        XCTAssertNotEqual(status1.hashValue, status3.hashValue)
    }
    
    // MARK: - Performance Tests
    
    func testTaxResidencyStatusPerformance() {
        measure {
            for _ in 0..<1000 {
                let status = TaxResidencyStatus(
                    countryCode: "IN",
                    residencyType: .taxResident,
                    taxYear: "FY2024-25",
                    effectiveDate: Date(),
                    documentType: .taxResidencyCertificate
                )
                
                let _ = status.isValid
                let _ = status.requiresRenewal
            }
        }
    }
    
    func testComplianceSetupPerformance() {
        measure {
            for _ in 0..<100 {
                var status = TaxResidencyStatus(
                    countryCode: ["IN", "US", "GB", "CA", "AU"].randomElement()!,
                    residencyType: ResidencyType.allCases.randomElement()!,
                    taxYear: "FY2024-25",
                    effectiveDate: Date(),
                    documentType: ResidencyDocumentType.allCases.randomElement()!
                )
                
                status.addComplianceObligation(.crsReporting)
                status.setWithholdingTaxRate(Double.random(in: 0...30), for: "dividends")
                status.setReportingThreshold(Decimal(Int.random(in: 1000...100000)), for: "USD")
            }
        }
    }
}