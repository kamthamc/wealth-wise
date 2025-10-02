//
//  MainView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Main Application View - Navigation Structure
//

import SwiftUI
import SwiftData

/// Main application view with navigation structure
@available(iOS 18.6, macOS 15.6, *)
struct MainView: View {
    
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @EnvironmentObject var serviceContainer: ServiceContainer
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - macOS Layout
    
    @ViewBuilder
    private var macOSLayout: some View {
        NavigationSplitView {
            SidebarView(navigationCoordinator: navigationCoordinator)
        } detail: {
            NavigationStack(path: $navigationCoordinator.navigationPath) {
                contentView
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
        }
        .sheet(isPresented: $navigationCoordinator.showingNewPortfolio) {
            NewPortfolioView()
        }
        .sheet(isPresented: $navigationCoordinator.showingNewAsset) {
            NewAssetView()
        }
        .sheet(isPresented: $navigationCoordinator.showingNewTransaction) {
            NewTransactionView()
        }
    }
    
    // MARK: - iOS Layout
    
    @ViewBuilder
    private var iOSLayout: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            ForEach(NavigationTab.allCases) { tab in
                NavigationStack(path: $navigationCoordinator.navigationPath) {
                    tabContent(for: tab)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            destinationView(for: destination)
                        }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .sheet(isPresented: $navigationCoordinator.showingNewPortfolio) {
            NewPortfolioView()
        }
        .sheet(isPresented: $navigationCoordinator.showingNewAsset) {
            NewAssetView()
        }
        .sheet(isPresented: $navigationCoordinator.showingNewTransaction) {
            NewTransactionView()
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        switch navigationCoordinator.selectedTab {
        case .dashboard:
            DashboardView()
        case .portfolios:
            PortfolioListView()
        case .assets:
            AssetListView()
        case .transactions:
            TransactionListView()
        case .reports:
            ReportsView()
        case .settings:
            SettingsView()
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: NavigationTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .portfolios:
            PortfolioListView()
        case .assets:
            AssetListView()
        case .transactions:
            TransactionListView()
        case .reports:
            ReportsView()
        case .settings:
            SettingsView()
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .portfolioDetail(let id):
            PortfolioDetailView(portfolioId: id)
        case .assetDetail(let id):
            AssetDetailView(assetId: id)
        case .transactionDetail(let id):
            TransactionDetailView(transactionId: id)
        case .addPortfolio:
            NewPortfolioView()
        case .addAsset:
            NewAssetView()
        case .addTransaction:
            NewTransactionView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Sidebar View

@available(iOS 18.6, macOS 15.6, *)
struct SidebarView: View {
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        List(selection: $navigationCoordinator.selectedTab) {
            Section("Overview") {
                ForEach([NavigationTab.dashboard, .portfolios, .assets]) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
                }
            }
            
            Section("Activity") {
                NavigationLink(value: NavigationTab.transactions) {
                    Label(NavigationTab.transactions.title, systemImage: NavigationTab.transactions.icon)
                }
                .tag(NavigationTab.transactions)
            }
            
            Section("Insights") {
                NavigationLink(value: NavigationTab.reports) {
                    Label(NavigationTab.reports.title, systemImage: NavigationTab.reports.icon)
                }
                .tag(NavigationTab.reports)
            }
        }
        .navigationTitle("WealthWise")
        .toolbar {
            ToolbarItem {
                Button(action: { navigationCoordinator.showNewPortfolio() }) {
                    Label("New Portfolio", systemImage: "plus")
                }
            }
        }
    }
}

// MARK: - Placeholder Views

@available(iOS 18.6, macOS 15.6, *)
struct DashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your financial overview will appear here")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Dashboard")
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct PortfolioListView: View {
    @Query private var portfolios: [Portfolio]
    
    var body: some View {
        VStack {
            if portfolios.isEmpty {
                ContentUnavailableView(
                    "No Portfolios",
                    systemImage: "folder.fill",
                    description: Text("Create your first portfolio to get started")
                )
            } else {
                List(portfolios) { portfolio in
                    NavigationLink(value: NavigationDestination.portfolioDetail(portfolio.id)) {
                        VStack(alignment: .leading) {
                            Text(portfolio.name)
                                .font(.headline)
                            Text("\(portfolio.assetCount) assets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Portfolios")
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct AssetListView: View {
    @Query private var assets: [Asset]
    
    var body: some View {
        VStack {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets",
                    systemImage: "dollarsign.circle.fill",
                    description: Text("Add assets to start tracking your wealth")
                )
            } else {
                List(assets) { asset in
                    NavigationLink(value: NavigationDestination.assetDetail(asset.id)) {
                        VStack(alignment: .leading) {
                            Text(asset.name)
                                .font(.headline)
                            Text(asset.assetType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Assets")
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct ReportsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            
            Text("Reports")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Financial reports and insights")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Reports")
    }
}

// MARK: - Detail Views

@available(iOS 18.6, macOS 15.6, *)
struct PortfolioDetailView: View {
    let portfolioId: UUID
    
    var body: some View {
        Text("Portfolio Detail: \(portfolioId.uuidString)")
            .navigationTitle("Portfolio Detail")
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct AssetDetailView: View {
    let assetId: UUID
    
    var body: some View {
        Text("Asset Detail: \(assetId.uuidString)")
            .navigationTitle("Asset Detail")
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct TransactionDetailView: View {
    let transactionId: UUID
    
    var body: some View {
        Text("Transaction Detail: \(transactionId.uuidString)")
            .navigationTitle("Transaction Detail")
    }
}

// MARK: - New Item Views

@available(iOS 18.6, macOS 15.6, *)
struct NewPortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var currency = "USD"
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $description)
                Picker("Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("INR").tag("INR")
                    Text("EUR").tag("EUR")
                }
            }
            .navigationTitle("New Portfolio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save logic
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct NewAssetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("New Asset Form")
            .navigationTitle("New Asset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct NewTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("New Transaction Form")
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}
