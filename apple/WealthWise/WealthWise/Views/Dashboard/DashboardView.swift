//
//  DashboardView.swift
//  WealthWise
//
//  Main dashboard view with all widgets
//

import SwiftUI

@available(iOS 18.6, macOS 15.6, *)
struct DashboardView: View {
    @State private var coordinator = DashboardCoordinator.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if coordinator.isLoading {
                    loadingView
                } else {
                    dashboardContent
                }
            }
            .navigationTitle(NSLocalizedString("dashboard.title", comment: "Dashboard"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                toolbarContent
            }
            .refreshable {
                await coordinator.refreshDashboardData()
            }
        }
    }
    
    private var dashboardContent: some View {
        LazyVStack(spacing: 20) {
            // Timeframe Selector
            timeframeSelectorView
            
            // Net Worth Widget
            NetWorthWidget(netWorthData: coordinator.dashboardData.netWorth)
            
            // Two-column layout for medium widgets
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                twoColumnLayout
            } else {
                singleColumnLayout
            }
            #else
            twoColumnLayout
            #endif
            
            // Recent Transactions (full width)
            RecentTransactionsWidget(transactions: coordinator.dashboardData.recentTransactions)
            
            // Alerts (full width)
            if !coordinator.dashboardData.alerts.isEmpty {
                AlertsWidget(alerts: coordinator.dashboardData.alerts)
            }
            
            // Last Updated
            lastUpdatedView
        }
        .padding()
    }
    
    private var singleColumnLayout: some View {
        VStack(spacing: 20) {
            AssetAllocationWidget(allocations: coordinator.dashboardData.assetAllocation)
            PerformanceMetricsWidget(metrics: coordinator.dashboardData.performanceMetrics)
        }
    }
    
    private var twoColumnLayout: some View {
        HStack(alignment: .top, spacing: 20) {
            AssetAllocationWidget(allocations: coordinator.dashboardData.assetAllocation)
                .frame(maxWidth: .infinity)
            
            PerformanceMetricsWidget(metrics: coordinator.dashboardData.performanceMetrics)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var timeframeSelectorView: some View {
        HStack(spacing: 8) {
            ForEach(DashboardTimeFrame.allCases, id: \.self) { timeframe in
                Button(action: {
                    coordinator.switchTimeframe(timeframe)
                }) {
                    Text(timeframe.displayName)
                        .font(.caption)
                        .fontWeight(coordinator.selectedTimeframe == timeframe ? .semibold : .regular)
                        .foregroundColor(coordinator.selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            coordinator.selectedTimeframe == timeframe ?
                                Color.blue : Color(.systemGray5)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var lastUpdatedView: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                
                Text(NSLocalizedString("dashboard.last_updated", comment: "Last updated"))
                    .font(.caption2)
                
                Text(formatLastUpdated(coordinator.lastUpdated))
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(NSLocalizedString("general.loading", comment: "Loading..."))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                menuContent
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            Menu {
                menuContent
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        #endif
    }
    
    @ViewBuilder
    private var menuContent: some View {
        Button(action: {
            Task {
                await coordinator.refreshDashboardData()
            }
        }) {
            Label(NSLocalizedString("dashboard.refresh", comment: "Refresh"), systemImage: "arrow.clockwise")
        }
        
        Divider()
        
        Menu(NSLocalizedString("dashboard.currency", comment: "Currency")) {
            Button("INR - ₹") {
                coordinator.switchCurrency("INR")
            }
            Button("USD - $") {
                coordinator.switchCurrency("USD")
            }
            Button("EUR - €") {
                coordinator.switchCurrency("EUR")
            }
        }
        
        Menu(NSLocalizedString("dashboard.view", comment: "View")) {
            ForEach(DashboardViewType.allCases, id: \.self) { viewType in
                Button(action: {
                    coordinator.switchView(viewType)
                }) {
                    Label(viewType.displayName, systemImage: viewType.icon)
                }
            }
        }
        
        Divider()
        
        Button(action: {
            // Settings action
        }) {
            Label(NSLocalizedString("general.settings", comment: "Settings"), systemImage: "gear")
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview("Dashboard - Light Mode") {
    DashboardView()
        .preferredColorScheme(.light)
}

#Preview("Dashboard - Dark Mode") {
    DashboardView()
        .preferredColorScheme(.dark)
}
