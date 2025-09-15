import SwiftUI
import SwiftData

struct MacContentView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            DetailView()
        }
        .navigationTitle(L10n.App.name)
    }
}

struct SidebarView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    
    var body: some View {
        List(selection: $navigationManager.currentView) {
            Section(L10n.Sidebar.overview) {
                NavigationLink(value: NavigationManager.AppView.dashboard) {
                    Label(L10n.Nav.dashboard, systemImage: "chart.pie.fill")
                }
                
                NavigationLink(value: NavigationManager.AppView.portfolio) {
                    Label(L10n.Nav.portfolio, systemImage: "chart.line.uptrend.xyaxis")
                }
            }
            
            Section(L10n.Sidebar.assets) {
                NavigationLink(value: NavigationManager.AppView.assets) {
                    Label(L10n.Sidebar.allAssets, systemImage: "building.columns")
                }
                
                Label(L10n.Sidebar.stocksETFs, systemImage: "chart.bar")
                    .foregroundColor(.secondary)
                
                Label(L10n.Sidebar.realEstate, systemImage: "house")
                    .foregroundColor(.secondary)
                
                Label(L10n.Sidebar.commodities, systemImage: "diamond")
                    .foregroundColor(.secondary)
                
                Label(L10n.Sidebar.fixedDeposits, systemImage: "banknote")
                    .foregroundColor(.secondary)
                
                Label(L10n.Sidebar.cash, systemImage: "dollarsign.circle")
                    .foregroundColor(.secondary)
            }
            
            Section(L10n.Sidebar.reports) {
                NavigationLink(value: NavigationManager.AppView.reports) {
                    Label(L10n.Nav.reports, systemImage: "doc.text")
                }
                
                Label(L10n.Sidebar.taxReports, systemImage: "percent")
                    .foregroundColor(.secondary)
                
                Label(L10n.Sidebar.performance, systemImage: "chart.xyaxis.line")
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.App.name)
    }
}

struct DetailView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    
    var body: some View {
        Group {
            switch navigationManager.currentView {
            case .dashboard:
                DashboardView()
            case .portfolio:
                PortfolioView()
            case .assets:
                AssetsView()
            case .reports:
                ReportsView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Placeholder Views

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.Dashboard.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.App.welcome)
                .font(.title2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                DashboardCard(title: L10n.Dashboard.netWorth, value: "\(L10n.Currency.inr)0", color: .blue)
                DashboardCard(title: L10n.Dashboard.portfolioValue, value: "\(L10n.Currency.inr)0", color: .green)
                DashboardCard(title: L10n.Dashboard.realEstate, value: "\(L10n.Currency.inr)0", color: .orange)
                DashboardCard(title: L10n.Dashboard.cashDeposits, value: "\(L10n.Currency.inr)0", color: .purple)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .accessibilityLabel(L10n.Accessibility.dashboardCard(title, value))
    }
}

struct PortfolioView: View {
    var body: some View {
        VStack {
            Text(L10n.Nav.portfolio)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.Placeholder.portfolio)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct AssetsView: View {
    var body: some View {
        VStack {
            Text(L10n.Nav.assets)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.Placeholder.assets)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct ReportsView: View {
    var body: some View {
        VStack {
            Text(L10n.Nav.reports)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.Placeholder.reports)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Text(L10n.Nav.settings)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.Placeholder.settings)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    MacContentView()
}