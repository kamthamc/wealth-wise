//
//  StatsCardView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Reusable statistics card component with icon and trend indicator
//

import SwiftUI

@available(iOS 18, macOS 15, *)
struct StatsCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let trend: Trend?
    let trendValue: String?
    
    enum Trend {
        case up
        case down
        case neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        trend: Trend? = nil,
        trendValue: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.trend = trend
        self.trendValue = trendValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            // Value and Trend
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let trend = trend, let trendValue = trendValue {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text(trendValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(trend.color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Convenience Initializers

@available(iOS 18, macOS 15, *)
extension StatsCardView {
    /// Create a stats card for currency values
    static func currency(
        icon: String,
        iconColor: Color,
        title: String,
        amount: Decimal,
        trend: Trend? = nil,
        trendValue: String? = nil
    ) -> StatsCardView {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        let value = formatter.string(from: amount as NSNumber) ?? "₹0"
        
        return StatsCardView(
            icon: icon,
            iconColor: iconColor,
            title: title,
            value: value,
            trend: trend,
            trendValue: trendValue
        )
    }
    
    /// Create a stats card for count values
    static func count(
        icon: String,
        iconColor: Color,
        title: String,
        count: Int,
        trend: Trend? = nil,
        trendValue: String? = nil
    ) -> StatsCardView {
        StatsCardView(
            icon: icon,
            iconColor: iconColor,
            title: title,
            value: "\(count)",
            trend: trend,
            trendValue: trendValue
        )
    }
    
    /// Create a stats card for percentage values
    static func percentage(
        icon: String,
        iconColor: Color,
        title: String,
        percentage: Double,
        trend: Trend? = nil,
        trendValue: String? = nil
    ) -> StatsCardView {
        StatsCardView(
            icon: icon,
            iconColor: iconColor,
            title: title,
            value: "\(Int(percentage))%",
            trend: trend,
            trendValue: trendValue
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Stats Card - Currency") {
    VStack(spacing: 20) {
        StatsCardView.currency(
            icon: "arrow.down.circle.fill",
            iconColor: .green,
            title: "Total Income",
            amount: 125000,
            trend: .up,
            trendValue: "12%"
        )
        
        StatsCardView.currency(
            icon: "arrow.up.circle.fill",
            iconColor: .red,
            title: "Total Expenses",
            amount: 85000,
            trend: .down,
            trendValue: "5%"
        )
        
        StatsCardView.currency(
            icon: "indianrupeesign.circle.fill",
            iconColor: .blue,
            title: "Net Worth",
            amount: 450000
        )
    }
    .padding()
}

#Preview("Stats Card - Count") {
    VStack(spacing: 20) {
        StatsCardView.count(
            icon: "list.bullet.circle.fill",
            iconColor: .purple,
            title: "Transactions",
            count: 127,
            trend: .up,
            trendValue: "23"
        )
        
        StatsCardView.count(
            icon: "chart.pie.fill",
            iconColor: .orange,
            title: "Active Budgets",
            count: 5
        )
        
        StatsCardView.count(
            icon: "target",
            iconColor: .pink,
            title: "Goals",
            count: 3,
            trend: .neutral,
            trendValue: "0"
        )
    }
    .padding()
}

#Preview("Stats Card - Percentage") {
    VStack(spacing: 20) {
        StatsCardView.percentage(
            icon: "chart.bar.fill",
            iconColor: .blue,
            title: "Savings Rate",
            percentage: 32,
            trend: .up,
            trendValue: "4%"
        )
        
        StatsCardView.percentage(
            icon: "gauge.with.dots.needle.50percent",
            iconColor: .orange,
            title: "Budget Used",
            percentage: 78,
            trend: .up,
            trendValue: "15%"
        )
        
        StatsCardView.percentage(
            icon: "flag.checkered",
            iconColor: .green,
            title: "Goal Progress",
            percentage: 45,
            trend: .up,
            trendValue: "8%"
        )
    }
    .padding()
}

#Preview("Stats Card - Grid Layout") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        StatsCardView.currency(
            icon: "arrow.down.circle.fill",
            iconColor: .green,
            title: "Income",
            amount: 125000
        )
        
        StatsCardView.currency(
            icon: "arrow.up.circle.fill",
            iconColor: .red,
            title: "Expenses",
            amount: 85000
        )
        
        StatsCardView.count(
            icon: "list.bullet.circle.fill",
            iconColor: .purple,
            title: "Transactions",
            count: 127
        )
        
        StatsCardView.percentage(
            icon: "chart.bar.fill",
            iconColor: .blue,
            title: "Savings",
            percentage: 32
        )
    }
    .padding()
}
#endif
