//
//  ExpenseCategoryChartView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Pie chart for expense breakdown by category
//

import SwiftUI
import Charts

@available(iOS 18, macOS 15, *)
struct ExpenseCategoryChartView: View {
    let data: [CategoryExpense]
    let totalExpense: Decimal
    
    struct CategoryExpense: Identifiable {
        let id = UUID()
        let category: String
        let amount: Decimal
        let color: Color
        
        var percentage: Double {
            0 // Calculated externally
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expenses by Category")
                .font(.headline)
            
            if data.isEmpty {
                emptyState
            } else {
                HStack(spacing: 24) {
                    // Pie Chart
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Amount", Double(truncating: item.amount as NSNumber)),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartLegend(.hidden)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data.prefix(5)) { item in
                            legendItem(item)
                        }
                        
                        if data.count > 5 {
                            Text("+ \(data.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("expense_category_chart", comment: "Expenses by Category Chart"))
        .accessibilityValue(accessibilityChartSummary)
        .accessibilityHint(NSLocalizedString("shows_expense_distribution", comment: "Shows how expenses are distributed across categories"))
    }
    
    private var accessibilityChartSummary: String {
        guard !data.isEmpty else {
            return NSLocalizedString("no_expense_data", comment: "No expense data available")
        }
        
        let topCategories = data.prefix(3).map { category in
            let percentage = formatPercentage(category.amount)
            return "\(category.category): \(formatCurrency(category.amount)) (\(percentage))"
        }.joined(separator: ", ")
        
        return "Total expenses: \(formatCurrency(totalExpense)). Top categories: \(topCategories)"
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No expense data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func legendItem(_ item: CategoryExpense) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(formatCurrency(item.amount))
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatPercentage(item.amount))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func formatPercentage(_ amount: Decimal) -> String {
        guard totalExpense > 0 else { return "0%" }
        let percentage = (Double(truncating: amount as NSNumber) / 
                         Double(truncating: totalExpense as NSNumber)) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "₹0"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Expense Category Chart") {
    ExpenseCategoryChartView(
        data: [
            .init(category: "Groceries", amount: 15000, color: .red),
            .init(category: "Transport", amount: 8000, color: .orange),
            .init(category: "Entertainment", amount: 5000, color: .purple),
            .init(category: "Healthcare", amount: 3000, color: .blue),
            .init(category: "Utilities", amount: 2000, color: .green)
        ],
        totalExpense: 33000
    )
    .padding()
}
#endif
