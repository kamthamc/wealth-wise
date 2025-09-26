//
//  FinancialModelsTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-27.
//  Tests for Financial Models Foundation - Issue #21
//

import XCTest
import SwiftData
@testable import WealthWise

@MainActor
final class FinancialModelsTests: XCTestCase {
    
    // MARK: - Goal Model Tests
    
    func testGoalCreation() throws {
        let goal = Goal(
            title: "5 Crore Investment Goal",
            goalDescription: "Achieve 5 crore investment target in 3 years",
            targetAmount: 50000000, // 5 crores
            targetDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date(),
            goalType: .investment,
            priority: .critical
        )
        
        XCTAssertEqual(goal.title, "5 Crore Investment Goal")
        XCTAssertEqual(goal.targetAmount, 50000000)
        XCTAssertEqual(goal.goalType, .investment)
        XCTAssertEqual(goal.priority, .critical)
        XCTAssertEqual(goal.currentAmount, 0)
        XCTAssertEqual(goal.progressPercentage, 0)
    }
    
    func testGoalProgressCalculation() throws {
        let goal = Goal(
            title: "Test Goal",
            targetAmount: 1000000,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        )
        
        // Test progress calculation
        goal.updateProgress(currentAmount: 250000) // 25% progress
        XCTAssertEqual(goal.progressPercentage, 25.0, accuracy: 0.01)
        
        goal.updateProgress(currentAmount: 500000) // 50% progress
        XCTAssertEqual(goal.progressPercentage, 50.0, accuracy: 0.01)
        
        goal.updateProgress(currentAmount: 1000000) // 100% progress
        XCTAssertEqual(goal.progressPercentage, 100.0, accuracy: 0.01)
        XCTAssertTrue(goal.isCompleted)
    }
    
    func testGoalMilestones() throws {
        let goal = Goal(
            title: "Test Goal",
            targetAmount: 1000000,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        )
        
        // Add milestones
        goal.addMilestone(percentage: 25, title: "25% Milestone")
        goal.addMilestone(percentage: 50, title: "50% Milestone")
        goal.addMilestone(percentage: 75, title: "75% Milestone")
        
        XCTAssertEqual(goal.milestones.count, 3)
        XCTAssertEqual(goal.milestones[0].percentage, 25)
        XCTAssertFalse(goal.milestones[0].isAchieved)
        
        // Update progress to trigger milestone achievement
        goal.updateProgress(currentAmount: 300000) // 30% progress
        XCTAssertTrue(goal.milestones[0].isAchieved) // 25% milestone should be achieved
        XCTAssertFalse(goal.milestones[1].isAchieved) // 50% milestone should not be achieved yet
    }
    
    func testGoalContributions() throws {
        let goal = Goal(
            title: "Test Goal",
            targetAmount: 1000000,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        )
        
        // Add contributions
        goal.addContribution(amount: 50000, description: "Initial investment")
        goal.addContribution(amount: 25000, description: "Monthly SIP")
        
        XCTAssertEqual(goal.contributions.count, 2)
        XCTAssertEqual(goal.contributedAmount, 75000)
        XCTAssertEqual(goal.currentAmount, 75000)
    }
    
    func testFiveCroreGoalFactory() throws {
        let goal = Goal.createFiveCroreGoal()
        
        XCTAssertEqual(goal.targetAmount, 50000000) // 5 crores
        XCTAssertEqual(goal.goalType, .investment)
        XCTAssertEqual(goal.priority, .critical)
        XCTAssertEqual(goal.riskTolerance, .aggressive)
        XCTAssertEqual(goal.expectedAnnualReturn, 15.0)
        XCTAssertEqual(goal.milestones.count, 3) // 25%, 50%, 75% milestones
    }
    
    // MARK: - Transaction Model Tests
    
    func testTransactionCreation() throws {
        let transaction = Transaction(
            amount: 50000,
            currency: "INR",
            transactionDescription: "Monthly salary",
            transactionType: .income,
            category: .salary
        )
        
        XCTAssertEqual(transaction.amount, 50000)
        XCTAssertEqual(transaction.currency, "INR")
        XCTAssertEqual(transaction.transactionDescription, "Monthly salary")
        XCTAssertEqual(transaction.transactionType, .income)
        XCTAssertEqual(transaction.category, .salary)
        XCTAssertTrue(transaction.isIncome)
        XCTAssertFalse(transaction.isExpense)
    }
    
    func testTransactionTypes() throws {
        let incomeTransaction = Transaction(
            amount: 50000,
            transactionDescription: "Salary",
            transactionType: .income,
            category: .salary
        )
        XCTAssertTrue(incomeTransaction.transactionType.isPositive)
        
        let expenseTransaction = Transaction(
            amount: 5000,
            transactionDescription: "Groceries",
            transactionType: .expense,
            category: .food_dining
        )
        XCTAssertFalse(expenseTransaction.transactionType.isPositive)
        
        let investmentTransaction = Transaction(
            amount: 10000,
            transactionDescription: "Mutual fund investment",
            transactionType: .investment,
            category: .mutual_funds
        )
        XCTAssertFalse(investmentTransaction.transactionType.isPositive) // Investment is an outflow
    }
    
    func testTransactionCategories() throws {
        let salaryTransaction = Transaction(
            amount: 50000,
            transactionDescription: "Monthly salary",
            transactionType: .income,
            category: .salary
        )
        XCTAssertEqual(salaryTransaction.category.displayName, "Salary")
        XCTAssertEqual(salaryTransaction.category.icon, "dollarsign.circle.fill")
        XCTAssertEqual(salaryTransaction.category.color, "green")
        
        let mutualFundTransaction = Transaction(
            amount: 10000,
            transactionDescription: "SIP investment",
            transactionType: .investment,
            category: .mutual_funds
        )
        XCTAssertEqual(mutualFundTransaction.category.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(mutualFundTransaction.category.color, "blue")
    }
    
    func testTransactionFactoryMethods() throws {
        // Test salary transaction
        let salaryTransaction = Transaction.createSalaryTransaction(amount: 75000)
        XCTAssertEqual(salaryTransaction.amount, 75000)
        XCTAssertEqual(salaryTransaction.transactionType, .income)
        XCTAssertEqual(salaryTransaction.category, .salary)
        
        // Test mutual fund investment
        let mfTransaction = Transaction.createMutualFundInvestment(
            amount: 10000,
            fundName: "Axis Bluechip Fund",
            units: 100,
            nav: 100
        )
        XCTAssertEqual(mfTransaction.amount, 10000)
        XCTAssertEqual(mfTransaction.transactionType, .investment)
        XCTAssertEqual(mfTransaction.category, .mutual_funds)
        XCTAssertEqual(mfTransaction.units, 100)
        XCTAssertEqual(mfTransaction.pricePerUnit, 100)
        
        // Test tax saving investment
        let taxSavingTransaction = Transaction.createTaxSavingInvestment(
            amount: 15000,
            description: "ELSS investment"
        )
        XCTAssertEqual(taxSavingTransaction.amount, 15000)
        XCTAssertEqual(taxSavingTransaction.category, .tax_saving_investment)
        XCTAssertTrue(taxSavingTransaction.isTaxDeductible)
    }
    
    // MARK: - Performance Tests
    
    func testGoalProgressPerformance() throws {
        let goal = Goal(
            title: "Performance Test Goal",
            targetAmount: 10000000,
            targetDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        )
        
        measure {
            for i in 1...1000 {
                goal.updateProgress(currentAmount: Decimal(i * 1000))
            }
        }
    }
    
    func testTransactionCreationPerformance() throws {
        measure {
            for i in 1...1000 {
                let _ = Transaction(
                    amount: Decimal(i * 100),
                    transactionDescription: "Test transaction \(i)",
                    transactionType: .expense,
                    category: .food_dining
                )
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testGoalTransactionIntegration() throws {
        let goal = Goal(
            title: "Integrated Goal",
            targetAmount: 500000,
            targetDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        )
        
        // Create transactions and link to goal
        let sipTransaction = Transaction.createMutualFundInvestment(
            amount: 10000,
            fundName: "Test Fund",
            units: 50,
            nav: 200
        )
        
        let taxSavingTransaction = Transaction.createTaxSavingInvestment(
            amount: 15000,
            description: "PPF investment"
        )
        
        // Add contributions to goal
        goal.addContribution(amount: sipTransaction.amount, description: "SIP investment")
        goal.addContribution(amount: taxSavingTransaction.amount, description: "PPF investment")
        
        XCTAssertEqual(goal.currentAmount, 25000)
        XCTAssertEqual(goal.contributions.count, 2)
        XCTAssertEqual(goal.progressPercentage, 5.0, accuracy: 0.01) // 25000/500000 = 5%
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testGoalEdgeCases() throws {
        // Test goal with zero target amount
        let zeroGoal = Goal(
            title: "Zero Goal",
            targetAmount: 0,
            targetDate: Date()
        )
        XCTAssertEqual(zeroGoal.progressPercentage, 0)
        XCTAssertEqual(zeroGoal.remainingAmount, 0)
        
        // Test goal with past target date
        let pastGoal = Goal(
            title: "Past Goal",
            targetAmount: 100000,
            targetDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        )
        XCTAssertTrue(pastGoal.daysRemaining <= 0)
        XCTAssertTrue(pastGoal.yearsRemaining <= 0)
    }
    
    func testTransactionEdgeCases() throws {
        // Test transaction with zero amount
        let zeroTransaction = Transaction(
            amount: 0,
            transactionDescription: "Zero transaction",
            transactionType: .expense,
            category: .other
        )
        XCTAssertEqual(zeroTransaction.amount, 0)
        
        // Test transaction with negative amount (should be allowed for returns/refunds)
        let negativeTransaction = Transaction(
            amount: -1000,
            transactionDescription: "Refund",
            transactionType: .refund,
            category: .other
        )
        XCTAssertEqual(negativeTransaction.amount, -1000)
    }
}