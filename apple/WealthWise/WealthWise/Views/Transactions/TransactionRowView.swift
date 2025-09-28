//
//  TransactionRowView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Transaction Management System: Individual transaction row component
//

import SwiftUI

/// Individual transaction row view with comprehensive transaction information
@available(iOS 18.6, macOS 15.6, *)
public struct TransactionRowView: View {
    
    // MARK: - Properties
    
    let transaction: Transaction
    let isSelected: Bool
    
    @Environment(\.themeConfiguration) private var themeConfiguration
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 12) {
            // Transaction type icon
            transactionIcon
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                // Description and category
                HStack {
                    Text(transaction.transactionDescription)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Amount
                    amountView
                }
                
                // Category and additional info
                HStack {
                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: transaction.category.systemImageName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(transaction.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Time and additional indicators
                    HStack(spacing: 8) {
                        // Cross-border indicator
                        if transaction.isCrossBorder {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // Tax indicator
                        if transaction.isTaxable {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        // Recurring indicator
                        if transaction.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        
                        // Time
                        Text(DateFormatter.timeFormatter.string(from: transaction.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tags if present
                if !transaction.tags.isEmpty {
                    tagsView
                }
                
                // Notes if present
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var transactionIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: transaction.transactionType.systemImageName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconForegroundColor)
        }
    }
    
    @ViewBuilder
    private var amountView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Main amount
            Text(formattedAmount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(amountColor)
            
            // Original currency amount if different
            if transaction.isCrossBorder,
               let originalAmount = transaction.originalAmount,
               let originalCurrency = transaction.originalCurrency {
              Text(
                CurrencyFormatter.shared
                  .format(
                    originalAmount,
                    currency: SupportedCurrency(
                      rawValue: originalCurrency
                    ) ?? .INR
                  )
              )
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(transaction.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                        )
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 1) // Prevent clipping
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedAmount: String {
        let amount = transaction.baseCurrencyAmount
        let prefix = transaction.transactionType == .expense ? "-" : (transaction.transactionType == .income ? "+" : "")
      return prefix + CurrencyFormatter.shared
        .format(abs(amount), currency: .INR)
    }
    
    private var amountColor: Color {
        switch transaction.transactionType {
        case .income, .refund, .dividend, .interest, .capital_gain:
            return themeConfiguration.semanticColors.positive
        case .expense, .capital_loss:
            return themeConfiguration.semanticColors.negative
        case .transfer:
            return themeConfiguration.semanticColors.neutral
        case .investment:
            return themeConfiguration.semanticColors.primary
        }
    }
    
    private var iconBackgroundColor: Color {
        switch transaction.transactionType {
        case .income, .refund, .dividend, .interest, .capital_gain:
            return themeConfiguration.semanticColors.positive.opacity(0.2)
        case .expense, .capital_loss:
            return themeConfiguration.semanticColors.negative.opacity(0.2)
        case .transfer:
            return themeConfiguration.semanticColors.neutral.opacity(0.2)
        case .investment:
            return themeConfiguration.semanticColors.primary.opacity(0.2)
        }
    }
    
    private var iconForegroundColor: Color {
        switch transaction.transactionType {
        case .income, .refund, .dividend, .interest, .capital_gain:
            return themeConfiguration.semanticColors.positive
        case .expense, .capital_loss:
            return themeConfiguration.semanticColors.negative
        case .transfer:
            return themeConfiguration.semanticColors.neutral
        case .investment:
            return themeConfiguration.semanticColors.primary
        }
    }
}

// MARK: - Preview

@available(iOS 18.6, macOS 15.6, *)
#Preview {
    NavigationStack {
        List {
            TransactionRowView(
                transaction: Transaction.sampleIncome,
                isSelected: false
            )
            
            TransactionRowView(
                transaction: Transaction.sampleExpense,
                isSelected: true
            )
            
            TransactionRowView(
                transaction: Transaction.sampleInvestment,
                isSelected: false
            )
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #else
        .listStyle(.insetGrouped)
        #endif
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

// MARK: - Sample Data

@available(iOS 18.6, macOS 15.6, *)
private extension Transaction {
    static var sampleIncome: Transaction {
        Transaction(
            amount: 75000,
            currency: "INR",
            transactionDescription: "Software Engineering Salary",
            notes: "Monthly salary payment",
            date: Date(),
            transactionType: .income,
            category: .salary,
            source: .manual
        )
    }
    
    static var sampleExpense: Transaction {
        Transaction(
            amount: 2500,
            currency: "INR",
            transactionDescription: "Grocery Shopping",
            notes: "Weekly groceries from BigBasket",
            date: Date().addingTimeInterval(-3600),
            transactionType: .expense,
            category: .food_dining,
            source: .manual
        )
    }
    
    static var sampleInvestment: Transaction {
        Transaction(
            amount: 10000,
            currency: "INR",
            transactionDescription: "SIP Investment",
            notes: "Monthly SIP in HDFC Top 100 Fund",
            date: Date().addingTimeInterval(-7200),
            transactionType: .investment,
            category: .mutual_funds,
            source: .manual
        )
    }
}
