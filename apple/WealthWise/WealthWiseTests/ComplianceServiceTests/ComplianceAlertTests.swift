//
//  ComplianceAlertTests.swift
//  WealthWiseTests
//
//  Unit tests for ComplianceAlert model
//

import XCTest
@testable import WealthWise

final class ComplianceAlertTests: XCTestCase {
    
    func testComplianceAlertInitialization() {
        let alert = ComplianceAlert(
            alertType: .thresholdExceeded,
            severityLevel: .critical,
            title: "Test Alert",
            message: "Test message"
        )
        
        XCTAssertEqual(alert.alertType, .thresholdExceeded)
        XCTAssertEqual(alert.severityLevel, .critical)
        XCTAssertEqual(alert.status, .active)
        XCTAssertTrue(alert.requiresUserAction)
    }
    
    func testAlertUrgency() {
        let nearDeadline = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        
        let alert = ComplianceAlert(
            alertType: .deadlineApproaching,
            severityLevel: .high,
            title: "Urgent Alert",
            message: "Test",
            actionDeadline: nearDeadline
        )
        
        XCTAssertTrue(alert.isUrgent)
        XCTAssertFalse(alert.isOverdue)
    }
    
    func testAlertOverdue() {
        let pastDeadline = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        
        let alert = ComplianceAlert(
            alertType: .reportingRequired,
            severityLevel: .critical,
            title: "Overdue Alert",
            message: "Test",
            actionDeadline: pastDeadline
        )
        
        XCTAssertTrue(alert.isOverdue)
        XCTAssertFalse(alert.isUrgent)
    }
    
    func testAlertNeedsImmediateAttention() {
        let nearDeadline = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        
        let criticalAlert = ComplianceAlert(
            alertType: .complianceViolation,
            severityLevel: .critical,
            title: "Critical Alert",
            message: "Test",
            actionDeadline: nearDeadline
        )
        
        XCTAssertTrue(criticalAlert.needsImmediateAttention)
    }
    
    func testAlertPriorityScore() {
        let alert1 = ComplianceAlert(
            alertType: .thresholdExceeded,
            severityLevel: .critical,
            title: "Critical",
            message: "Test"
        )
        
        let alert2 = ComplianceAlert(
            alertType: .informational,
            severityLevel: .low,
            title: "Low",
            message: "Test"
        )
        
        XCTAssertGreaterThan(alert1.priorityScore, alert2.priorityScore)
    }
    
    func testAlertAcknowledge() {
        var alert = ComplianceAlert(
            alertType: .documentExpiring,
            severityLevel: .medium,
            title: "Test",
            message: "Test"
        )
        
        XCTAssertEqual(alert.status, .active)
        XCTAssertNil(alert.acknowledgedAt)
        
        alert.acknowledge()
        
        XCTAssertEqual(alert.status, .acknowledged)
        XCTAssertNotNil(alert.acknowledgedAt)
    }
    
    func testAlertResolve() {
        var alert = ComplianceAlert(
            alertType: .reportingRequired,
            severityLevel: .high,
            title: "Test",
            message: "Test"
        )
        
        alert.resolve(notes: "Resolved successfully")
        
        XCTAssertEqual(alert.status, .resolved)
        XCTAssertNotNil(alert.resolvedAt)
        XCTAssertEqual(alert.resolutionNotes, "Resolved successfully")
    }
    
    func testAlertDismiss() {
        var alert = ComplianceAlert(
            alertType: .informational,
            severityLevel: .informational,
            title: "Test",
            message: "Test"
        )
        
        alert.dismiss(reason: "Not applicable")
        
        XCTAssertEqual(alert.status, .dismissed)
        XCTAssertTrue(alert.isDismissed)
        XCTAssertEqual(alert.dismissReason, "Not applicable")
    }
    
    func testAlertStatusActionable() {
        XCTAssertTrue(AlertStatus.active.isActionable)
        XCTAssertTrue(AlertStatus.acknowledged.isActionable)
        XCTAssertTrue(AlertStatus.inProgress.isActionable)
        XCTAssertFalse(AlertStatus.resolved.isActionable)
        XCTAssertFalse(AlertStatus.dismissed.isActionable)
    }
    
    func testAlertComparable() {
        let criticalAlert = ComplianceAlert(
            alertType: .complianceViolation,
            severityLevel: .critical,
            title: "Critical",
            message: "Test"
        )
        
        let lowAlert = ComplianceAlert(
            alertType: .informational,
            severityLevel: .low,
            title: "Low",
            message: "Test"
        )
        
        XCTAssertTrue(criticalAlert < lowAlert)
    }
}
