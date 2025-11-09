//
//  MonthlyComparisonChartView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Grouped bar chart comparing metrics across months
//

import SwiftUI
import Charts

@available(iOS 18, macOS 15, *)
struct MonthlyComparisonChartView: View {
    let data: [MonthData]
    
    struct MonthData: Identifiable {
        let id = UUID()
        let month: Date
        let income: Decimal
        let expense: Decimal
        let savings: Decimal
        
        var savingsRate: Double {
            guard income > 0 else { return 0 }
            return Double(truncating: (savings / income * 100) as NSNumber)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Comparison")
                .font(.headline)
            
            if data.isEmpty {
                emptyState
            } else {
                // Grouped Bar Chart
                Chart {
                    ForEach(data.suffix(6)) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.income as NSNumber))
                        )
                        .foregroundStyle(.green)
                        .position(by: .value("Type", "Income"))
                        
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.expense as NSNumber))
                        )
                        .foregroundStyle(.red)
                        .position(by: .value("Type", "Expense"))
                        
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.savings as NSNumber))
                        )
                        .foregroundStyle(.blue)
                        .position(by: .value("Type", "Savings"))
                    }
                }
                .frame(height: 280)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatAmount(Decimal(amount)))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartLegend(position: .bottom) {
                    HStack(spacing: 20) {
                        LegendItem(color: .green, label: "Income")
                        LegendItem(color: .red, label: "Expense")
                        LegendItem(color: .blue, label: "Savings")
                    }
                }
                
                // Insights
                insightsSection
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("monthly_comparison_chart", comment: "Monthly Comparison Chart"))
        .accessibilityValue(accessibilityChartSummary)
        .accessibilityHint(NSLocalizedString("compares_income_expense_savings", comment: "Compares income, expenses, and savings across months"))
    }
    
    private var accessibilityChartSummary: String {
        guard !data.isEmpty else {
            return NSLocalizedString("no_monthly_data", comment: "No monthly data available")
        }
        
        let lastMonth = data.last!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: lastMonth.month)
        
        return "Showing last 6 months. Latest month: \(monthName). Income: \(formatCurrency(lastMonth.income)). Expenses: \(formatCurrency(lastMonth.expense)). Savings: \(formatCurrency(lastMonth.savings)). Savings rate: \(String(format: "%.1f%%", lastMonth.savingsRate))."
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No monthly data available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.subheadline.bold())
            
            if let bestMonth = bestSavingsMonth {
                InsightRow(
                    icon: "star.fill",
                    color: .green,
                    title: "Best Savings Month",
                    value: bestMonth.month.formatted(.dateTime.month(.wide)),
                    detail: formatCurrency(bestMonth.savings)
                )
            }
            
            if let avgSavingsRate = averageSavingsRate {
                InsightRow(
                    icon: "percent",
                    color: .blue,
                    title: "Average Savings Rate",
                    value: String(format: "%.1f%%", avgSavingsRate),
                    detail: savingsRateDescription(avgSavingsRate)
                )
            }
            
            if let trend = expenseTrend {
                InsightRow(
                    icon: trend.isIncreasing ? "arrow.up.right" : "arrow.down.right",
                    color: trend.isIncreasing ? .orange : .green,
                    title: "Expense Trend",
                    value: trend.isIncreasing ? "Increasing" : "Decreasing",
                    detail: String(format: "%.1f%% change", abs(trend.percentage))
                )
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func LegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 8)
            Text(label)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func InsightRow(icon: String, color: Color, title: String, value: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var bestSavingsMonth: MonthData? {
        data.max { $0.savings < $1.savings }
    }
    
    private var averageSavingsRate: Double? {
        guard !data.isEmpty else { return nil }
        let total = data.reduce(0.0) { $0 + $1.savingsRate }
        return total / Double(data.count)
    }
    
    private var expenseTrend: (isIncreasing: Bool, percentage: Double)? {
        guard data.count >= 2 else { return nil }
        
        let recent = data.suffix(3)
        let older = data.prefix(3)
        
        let recentAvg = recent.reduce(Decimal(0)) { $0 + $1.expense } / Decimal(recent.count)
        let olderAvg = older.reduce(Decimal(0)) { $0 + $1.expense } / Decimal(older.count)
        
        guard olderAvg > 0 else { return nil }
        
        let change = (recentAvg - olderAvg) / olderAvg * 100
        return (isIncreasing: change > 0, percentage: Double(truncating: change as NSNumber))
    }
    
    private func savingsRateDescription(_ rate: Double) -> String {
        switch rate {
        case 0..<10: return "Consider increasing savings"
        case 10..<20: return "Good start, aim for 20%+"
        case 20..<30: return "Great savings rate!"
        case 30...: return "Excellent financial discipline"
        default: return ""
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let absAmount = abs(Double(truncating: amount as NSNumber))
        if absAmount >= 100000 {
            return String(format: "%.1fL", absAmount / 100000)
        } else if absAmount >= 1000 {
            return String(format: "%.0fK", absAmount / 1000)
        } else {
            return String(format: "%.0f", absAmount)
        }
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
#Preview("Monthly Comparison") {
    let calendar = Calendar.current
    let data = (0..<6).reversed().map { monthsAgo in
        let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date())!
        let income = Decimal(Double.random(in: 60000...100000))
        let expense = Decimal(Double.random(in: 40000...70000))
        return MonthlyComparisonChartView.MonthData(
            month: date,
            income: income,
            expense: expense,
            savings: income - expense
        )
    }
    
    return MonthlyComparisonChartView(data: data)
        .padding()
}
#endif
