//
//  RecentTransactionsWidget.swift
//  WealthWise
//
//  Recent transactions list widget
//

import SwiftUI

@available(iOS 18.6, macOS 15.6, *)
struct RecentTransactionsWidget: View {
    let transactions: [TransactionSummary]
    let localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Transaction List
            if transactions.isEmpty {
                emptyStateView
            } else {
                transactionListView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("dashboard.recent_transactions", comment: "Recent Transactions"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("dashboard.last_transactions", comment: "Last 7 days"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // View all transactions action
            }) {
                Text(NSLocalizedString("dashboard.view_all", comment: "View All"))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var transactionListView: some View {
        VStack(spacing: 12) {
            ForEach(transactions.prefix(5)) { transaction in
                transactionRow(transaction)
            }
        }
    }
    
    private func transactionRow(_ transaction: TransactionSummary) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor(for: transaction.type))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName(for: transaction.type))
                    .font(.system(size: 18))
                    .foregroundColor(iconColor(for: transaction.type))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(transaction.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(transaction.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(transaction.amount, type: transaction.type))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(amountColor(for: transaction.type))
                
                Text(transaction.currency)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("dashboard.no_transactions", comment: "No recent transactions"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Formatting Helpers
    
    private func formatAmount(_ amount: Decimal, type: String) -> String {
        let prefix = type.lowercased().contains("income") ? "+" : "-"
        return prefix + localizationManager.formatCurrency(amount, currencyCode: "INR")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    private func iconName(for type: String) -> String {
        let typeKey = type.lowercased()
        if typeKey.contains("income") {
            return "arrow.down.circle.fill"
        } else if typeKey.contains("expense") {
            return "arrow.up.circle.fill"
        } else if typeKey.contains("investment") {
            return "chart.line.uptrend.xyaxis"
        } else {
            return "arrow.left.arrow.right"
        }
    }
    
    private func iconColor(for type: String) -> Color {
        let typeKey = type.lowercased()
        if typeKey.contains("income") {
            return .green
        } else if typeKey.contains("expense") {
            return .red
        } else if typeKey.contains("investment") {
            return .blue
        } else {
            return .orange
        }
    }
    
    private func iconBackgroundColor(for type: String) -> Color {
        iconColor(for: type).opacity(0.15)
    }
    
    private func amountColor(for type: String) -> Color {
        let typeKey = type.lowercased()
        if typeKey.contains("income") {
            return .green
        } else if typeKey.contains("expense") {
            return .red
        } else {
            return .primary
        }
    }
}

#Preview {
    RecentTransactionsWidget(transactions: [
        TransactionSummary(
            description: "Monthly Salary",
            amount: 150000,
            currency: "INR",
            date: Date(),
            type: "Income",
            category: "Salary"
        ),
        TransactionSummary(
            description: "Mutual Fund Investment",
            amount: 50000,
            currency: "INR",
            date: Date().addingTimeInterval(-86400),
            type: "Investment",
            category: "Mutual Funds"
        ),
        TransactionSummary(
            description: "Grocery Shopping",
            amount: 5000,
            currency: "INR",
            date: Date().addingTimeInterval(-172800),
            type: "Expense",
            category: "Food & Dining"
        )
    ])
    .frame(maxWidth: 400)
    .padding()
}
