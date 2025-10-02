//
//  PerformanceMetricsWidget.swift
//  WealthWise
//
//  Performance metrics display widget
//

import SwiftUI

@available(iOS 18.6, macOS 15.6, *)
struct PerformanceMetricsWidget: View {
    let metrics: PerformanceMetricsSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Returns Grid
            returnsGridView
            
            // Risk Metrics
            riskMetricsView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("financial.performance", comment: "Performance"))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(NSLocalizedString("dashboard.performance_subtitle", comment: "Portfolio Returns & Risk"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var returnsGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            if let return1M = metrics.return1Month {
                metricCard(
                    title: NSLocalizedString("dashboard.return_1m", comment: "1 Month"),
                    value: String(format: "%.1f%%", return1M),
                    isPositive: return1M >= 0
                )
            }
            
            if let return3M = metrics.return3Month {
                metricCard(
                    title: NSLocalizedString("dashboard.return_3m", comment: "3 Months"),
                    value: String(format: "%.1f%%", return3M),
                    isPositive: return3M >= 0
                )
            }
            
            if let return6M = metrics.return6Month {
                metricCard(
                    title: NSLocalizedString("dashboard.return_6m", comment: "6 Months"),
                    value: String(format: "%.1f%%", return6M),
                    isPositive: return6M >= 0
                )
            }
            
            if let return1Y = metrics.return1Year {
                metricCard(
                    title: NSLocalizedString("dashboard.return_1y", comment: "1 Year"),
                    value: String(format: "%.1f%%", return1Y),
                    isPositive: return1Y >= 0
                )
            }
        }
    }
    
    private var riskMetricsView: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.vertical, 4)
            
            HStack(spacing: 16) {
                if let volatility = metrics.volatility {
                    riskMetricItem(
                        icon: "waveform.path.ecg",
                        title: NSLocalizedString("financial.volatility", comment: "Volatility"),
                        value: String(format: "%.1f%%", volatility)
                    )
                }
                
                if let sharpe = metrics.sharpeRatio {
                    riskMetricItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: NSLocalizedString("dashboard.sharpe_ratio", comment: "Sharpe Ratio"),
                        value: String(format: "%.2f", sharpe)
                    )
                }
            }
        }
    }
    
    private func metricCard(title: String, value: String, isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func riskMetricItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PerformanceMetricsWidget(metrics: PerformanceMetricsSummary(
        return1Month: 2.5,
        return3Month: 8.3,
        return6Month: 15.2,
        return1Year: 28.7,
        volatility: 12.5,
        sharpeRatio: 1.8
    ))
    .frame(maxWidth: 400)
    .padding()
}
