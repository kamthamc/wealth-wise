//
//  NetWorthWidget.swift
//  WealthWise
//
//  Net worth display widget with trend chart
//

import SwiftUI
import Charts

@available(iOS 18.6, macOS 15.6, *)
struct NetWorthWidget: View {
    let netWorthData: NetWorthData
    let localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Trend Chart
            if !netWorthData.history.isEmpty {
                trendChartView
            }
            
            // Asset Breakdown
            if !netWorthData.assetBreakdown.isEmpty {
                assetBreakdownView
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
                Text(NSLocalizedString("general.net_worth", comment: "Net Worth"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(netWorthData.total))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: netWorthData.monthlyChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(formatCurrency(abs(netWorthData.monthlyChange)))
                        .font(.caption)
                }
                .foregroundColor(netWorthData.monthlyChange >= 0 ? .green : .red)
                
                Text(String(format: "%.1f%%", netWorthData.monthlyChangePercent))
                    .font(.caption2)
                    .foregroundColor(netWorthData.monthlyChange >= 0 ? .green : .red)
            }
        }
    }
    
    private var trendChartView: some View {
        Chart(netWorthData.history) { point in
            LineMark(
                x: .value(NSLocalizedString("chart.date", comment: "Date"), point.date),
                y: .value(NSLocalizedString("general.net_worth", comment: "Net Worth"), Double(truncating: point.value as NSDecimalNumber))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value(NSLocalizedString("chart.date", comment: "Date"), point.date),
                y: .value(NSLocalizedString("general.net_worth", comment: "Net Worth"), Double(truncating: point.value as NSDecimalNumber))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: 120)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatAxisValue(Decimal(doubleValue)))
                    }
                }
            }
        }
    }
    
    private var assetBreakdownView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("dashboard.asset_breakdown", comment: "Asset Breakdown"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(netWorthData.assetBreakdown) { asset in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(asset.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(asset.category)
                                .font(.caption2)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Text(formatCurrency(asset.value))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("(\(String(format: "%.0f%%", asset.percentage)))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return localizationManager.formatCurrency(amount, currencyCode: netWorthData.currency)
    }
    
    private func formatAxisValue(_ amount: Decimal) -> String {
        return localizationManager.formatLargeNumber(amount)
    }
}

#Preview {
    NetWorthWidget(netWorthData: NetWorthData())
        .frame(maxWidth: 400)
        .padding()
}
