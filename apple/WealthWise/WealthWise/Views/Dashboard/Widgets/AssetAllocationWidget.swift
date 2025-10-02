//
//  AssetAllocationWidget.swift
//  WealthWise
//
//  Asset allocation pie chart widget
//

import SwiftUI
import Charts

@available(iOS 18.6, macOS 15.6, *)
struct AssetAllocationWidget: View {
    let allocations: [AssetAllocationSummary]
    let localizationManager = LocalizationManager.shared
    
    @State private var selectedAllocation: AssetAllocationSummary?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            HStack(spacing: 20) {
                // Pie Chart
                pieChartView
                    .frame(width: 140, height: 140)
                
                // Legend
                legendView
            }
            
            // Selected Asset Details
            if let selected = selectedAllocation {
                selectedAssetView(selected)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("financial.allocation", comment: "Asset Allocation"))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(NSLocalizedString("dashboard.allocation_subtitle", comment: "Portfolio Distribution"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var pieChartView: some View {
        Chart(allocations) { allocation in
            SectorMark(
                angle: .value(NSLocalizedString("dashboard.percentage", comment: "Percentage"), allocation.percentage),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value(NSLocalizedString("dashboard.asset_type", comment: "Asset Type"), allocation.type))
            .cornerRadius(4)
            .opacity(selectedAllocation == nil || selectedAllocation?.id == allocation.id ? 1.0 : 0.5)
        }
        .chartLegend(.hidden)
        .chartAngleSelection(value: $selectedAllocation)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(allocations) { allocation in
                Button(action: {
                    if selectedAllocation?.id == allocation.id {
                        selectedAllocation = nil
                    } else {
                        selectedAllocation = allocation
                    }
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorForAssetType(allocation.type))
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(allocation.type)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.0f%%", allocation.percentage))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(selectedAllocation == nil || selectedAllocation?.id == allocation.id ? 1.0 : 0.5)
            }
        }
    }
    
    private func selectedAssetView(_ allocation: AssetAllocationSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(allocation.type)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(localizationManager.formatCurrency(allocation.value, currencyCode: "INR"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f%%", allocation.percentage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: NSLocalizedString("dashboard.asset_count", comment: "%d assets"), allocation.count))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Color Mapping
    
    private func colorForAssetType(_ type: String) -> Color {
        let typeKey = type.lowercased()
        if typeKey.contains("stock") {
            return .blue
        } else if typeKey.contains("mutual") || typeKey.contains("fund") {
            return .green
        } else if typeKey.contains("real estate") || typeKey.contains("property") {
            return .orange
        } else if typeKey.contains("deposit") || typeKey.contains("bond") {
            return .purple
        } else if typeKey.contains("gold") || typeKey.contains("commodity") {
            return .yellow
        } else if typeKey.contains("crypto") {
            return .cyan
        } else {
            return .gray
        }
    }
}

#Preview {
    AssetAllocationWidget(allocations: [
        AssetAllocationSummary(type: "Stocks", value: 2000000, percentage: 40, count: 15),
        AssetAllocationSummary(type: "Mutual Funds", value: 1500000, percentage: 30, count: 8),
        AssetAllocationSummary(type: "Real Estate", value: 1000000, percentage: 20, count: 2),
        AssetAllocationSummary(type: "Fixed Deposits", value: 500000, percentage: 10, count: 5)
    ])
    .frame(maxWidth: 400)
    .padding()
}
