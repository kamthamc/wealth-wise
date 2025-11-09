//
//  CategoryComparisonChartView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Bar chart comparing spending across categories
//

import SwiftUI
import Charts

@available(iOS 18, macOS 15, *)
struct CategoryComparisonChartView: View {
    let data: [CategoryData]
    let comparisonType: ComparisonType
    
    struct CategoryData: Identifiable {
        let id = UUID()
        let category: String
        let currentAmount: Decimal
        let previousAmount: Decimal
        let color: Color
        
        var change: Decimal {
            currentAmount - previousAmount
        }
        
        var changePercentage: Double {
            guard previousAmount > 0 else { return 0 }
            return Double(truncating: ((currentAmount - previousAmount) / previousAmount * 100) as NSNumber)
        }
    }
    
    enum ComparisonType: String, CaseIterable {
        case thisVsLastMonth = "Month"
        case thisVsLastQuarter = "Quarter"
        case thisVsLastYear = "Year"
        
        var description: String {
            switch self {
            case .thisVsLastMonth: return "This Month vs Last Month"
            case .thisVsLastQuarter: return "This Quarter vs Last Quarter"
            case .thisVsLastYear: return "This Year vs Last Year"
            }
        }
    }
    
    @State private var selectedComparison: ComparisonType
    
    init(data: [CategoryData], comparisonType: ComparisonType = .thisVsLastMonth) {
        self.data = data
        self.comparisonType = comparisonType
        _selectedComparison = State(initialValue: comparisonType)
    }
    
    var sortedData: [CategoryData] {
        data.sorted { $0.currentAmount > $1.currentAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category Comparison")
                    .font(.headline)
                
                Spacer()
                
                Picker("Period", selection: $selectedComparison) {
                    ForEach(ComparisonType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            
            Text(selectedComparison.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if sortedData.isEmpty {
                emptyState
            } else {
                // Bar Chart
                Chart {
                    ForEach(sortedData.prefix(8)) { item in
                        // Current period
                        BarMark(
                            x: .value("Category", item.category),
                            y: .value("Current", Double(truncating: item.currentAmount as NSNumber))
                        )
                        .foregroundStyle(item.color)
                        .position(by: .value("Period", "Current"))
                        
                        // Previous period
                        BarMark(
                            x: .value("Category", item.category),
                            y: .value("Previous", Double(truncating: item.previousAmount as NSNumber))
                        )
                        .foregroundStyle(item.color.opacity(0.5))
                        .position(by: .value("Period", "Previous"))
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks { value in
                        if let category = value.as(String.self) {
                            AxisValueLabel {
                                Text(category)
                                    .font(.caption2)
                                    .lineLimit(1)
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
                    HStack(spacing: 24) {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.blue)
                                .frame(width: 16, height: 8)
                            Text("Current")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.blue.opacity(0.5))
                                .frame(width: 16, height: 8)
                            Text("Previous")
                                .font(.caption)
                        }
                    }
                }
                
                // Top changes
                topChangesSection
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("category_comparison_chart", comment: "Category Comparison Chart"))
        .accessibilityValue(accessibilityChartSummary)
        .accessibilityHint(NSLocalizedString("compares_spending_across_periods", comment: "Compares spending across categories between time periods"))
    }
    
    private var accessibilityChartSummary: String {
        guard !sortedData.isEmpty else {
            return NSLocalizedString("no_comparison_data", comment: "No comparison data available")
        }
        
        let increases = sortedData.filter { $0.change > 0 }
        let decreases = sortedData.filter { $0.change < 0 }
        
        var summary = "\(selectedComparison.description). "
        
        if !increases.isEmpty {
            let topIncrease = increases[0]
            summary += "\(topIncrease.category) increased by \(String(format: "%.0f%%", topIncrease.changePercentage)). "
        }
        
        if !decreases.isEmpty {
            let topDecrease = decreases[0]
            summary += "\(topDecrease.category) decreased by \(String(format: "%.0f%%", abs(topDecrease.changePercentage)))."
        }
        
        return summary
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No comparison data available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var topChangesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Changes")
                .font(.subheadline.bold())
            
            let topChanges = sortedData
                .sorted { abs($0.change) > abs($1.change) }
                .prefix(3)
            
            ForEach(topChanges) { item in
                changeRow(item)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func changeRow(_ item: CategoryData) -> some View {
        HStack {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
            
            Text(item.category)
                .font(.caption)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: item.change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                Text(String(format: "%.0f%%", abs(item.changePercentage)))
                    .font(.caption.bold())
            }
            .foregroundStyle(item.change >= 0 ? .red : .green)
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
}

// MARK: - Preview

#if DEBUG
#Preview("Category Comparison") {
    let categories = ["Groceries", "Transport", "Entertainment", "Healthcare", "Utilities", "Shopping", "Food", "Education"]
    let data = categories.map { category in
        CategoryComparisonChartView.CategoryData(
            category: category,
            currentAmount: Decimal(Double.random(in: 5000...20000)),
            previousAmount: Decimal(Double.random(in: 5000...20000)),
            color: [.red, .orange, .purple, .blue, .green, .pink, .yellow, .indigo].randomElement()!
        )
    }
    
    return CategoryComparisonChartView(data: data)
        .padding()
}
#endif
