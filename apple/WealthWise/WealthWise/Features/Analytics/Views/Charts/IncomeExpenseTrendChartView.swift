//
//  IncomeExpenseTrendChartView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Line chart showing income vs expense trends over time
//

import SwiftUI
import Charts

@available(iOS 18, macOS 15, *)
struct IncomeExpenseTrendChartView: View {
    let data: [MonthlyData]
    let dateRange: DateRange
    
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: Date
        let income: Decimal
        let expense: Decimal
        
        var netIncome: Decimal {
            income - expense
        }
    }
    
    enum DateRange: String, CaseIterable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"
        
        var months: Int? {
            switch self {
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            case .all: return nil
            }
        }
    }
    
    @State private var selectedRange: DateRange
    
    init(data: [MonthlyData], dateRange: DateRange = .sixMonths) {
        self.data = data
        self.dateRange = dateRange
        _selectedRange = State(initialValue: dateRange)
    }
    
    var filteredData: [MonthlyData] {
        guard let months = selectedRange.months else { return data }
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        return data.filter { $0.month >= cutoffDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Income vs Expenses")
                    .font(.headline)
                
                Spacer()
                
                // Date range picker
                Picker("Range", selection: $selectedRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            if filteredData.isEmpty {
                emptyState
            } else {
                // Chart
                Chart {
                    ForEach(filteredData) { item in
                        // Income line
                        LineMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.income as NSNumber))
                        )
                        .foregroundStyle(.green)
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)
                        
                        // Expense line
                        LineMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.expense as NSNumber))
                        )
                        .foregroundStyle(.red)
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)
                        
                        // Area under income
                        AreaMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.income as NSNumber))
                        )
                        .foregroundStyle(.green.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                        
                        // Area under expense
                        AreaMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", Double(truncating: item.expense as NSNumber))
                        )
                        .foregroundStyle(.red.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated))
                            }
                        }
                        AxisGridLine()
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
                    HStack(spacing: 24) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Income")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Expenses")
                                .font(.caption)
                        }
                    }
                }
                
                // Summary stats
                summaryStats
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("income_expense_trend_chart", comment: "Income vs Expense Trend Chart"))
        .accessibilityValue(accessibilityChartSummary)
        .accessibilityHint(NSLocalizedString("shows_income_and_expense_over_time", comment: "Shows income and expense trends over the selected time period"))
    }
    
    private var accessibilityChartSummary: String {
        guard !filteredData.isEmpty else {
            return NSLocalizedString("no_data_available", comment: "No data available")
        }
        
        let totalIncome = filteredData.reduce(Decimal(0)) { $0 + $1.income }
        let totalExpense = filteredData.reduce(Decimal(0)) { $0 + $1.expense }
        let netSavings = totalIncome - totalExpense
        
        let periodText = "\(selectedRange.rawValue) period"
        let incomeText = "Average income: \(formatCurrency(averageIncome))"
        let expenseText = "Average expenses: \(formatCurrency(averageExpense))"
        let savingsText = "Average savings: \(formatCurrency(averageSavings))"
        let netText = netSavings >= 0 ? "positive" : "negative"
        
        return "\(periodText). \(incomeText). \(expenseText). \(savingsText). Net \(netText)."
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No trend data available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var summaryStats: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "Avg. Income",
                value: formatCurrency(averageIncome),
                color: .green
            )
            
            StatBox(
                title: "Avg. Expense",
                value: formatCurrency(averageExpense),
                color: .red
            )
            
            StatBox(
                title: "Avg. Savings",
                value: formatCurrency(averageSavings),
                color: averageSavings >= 0 ? .blue : .orange
            )
        }
    }
    
    @ViewBuilder
    private func StatBox(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var averageIncome: Decimal {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(Decimal(0)) { $0 + $1.income }
        return total / Decimal(filteredData.count)
    }
    
    private var averageExpense: Decimal {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(Decimal(0)) { $0 + $1.expense }
        return total / Decimal(filteredData.count)
    }
    
    private var averageSavings: Decimal {
        averageIncome - averageExpense
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
#Preview("Income Expense Trend") {
    let calendar = Calendar.current
    let data = (0..<12).reversed().map { monthsAgo in
        let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date())!
        return IncomeExpenseTrendChartView.MonthlyData(
            month: date,
            income: Decimal(Double.random(in: 50000...100000)),
            expense: Decimal(Double.random(in: 30000...70000))
        )
    }
    
    return IncomeExpenseTrendChartView(data: data)
        .padding()
}
#endif
