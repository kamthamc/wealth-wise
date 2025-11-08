//
//  DashboardView.swift
//  WealthWise
//
//  Main dashboard with financial overview
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel: DashboardViewModel
    @State private var showSettings = false
    
    init() {
        // ViewModel will be initialized properly when view appears
        let context = ModelContext(ModelContainer.shared)
        _viewModel = StateObject(wrappedValue: DashboardViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("dashboard", comment: "Dashboard"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.hasData {
                    ProgressView()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("welcome_back", comment: "Welcome back"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(authManager.currentUser?.displayName ?? NSLocalizedString("user", comment: "User"))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Circle()
                .fill(.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(authManager.currentUser?.displayName?.prefix(1).uppercased() ?? "W")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("overview", comment: "Overview"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                StatCard(
                    title: NSLocalizedString("total_balance", comment: "Total Balance"),
                    value: viewModel.formatCurrency(viewModel.totalBalance),
                    icon: "indianrupeesign.circle.fill",
                    color: .blue
                )
                
                HStack(spacing: 12) {
                    StatCard(
                        title: NSLocalizedString("income", comment: "Income"),
                        value: viewModel.formatCurrency(viewModel.monthlyIncome),
                        icon: "arrow.down.circle.fill",
                        color: .green,
                        compact: true
                    )
                    
                    StatCard(
                        title: NSLocalizedString("expenses", comment: "Expenses"),
                        value: viewModel.formatCurrency(viewModel.monthlyExpenses),
                        icon: "arrow.up.circle.fill",
                        color: .red,
                        compact: true
                    )
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("recent_activity", comment: "Recent Activity"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink {
                    TransactionsView()
                } label: {
                    Text(NSLocalizedString("see_all", comment: "See All"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            if viewModel.recentTransactions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        EmptyActivityRow()
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction, viewModel: viewModel)
                        if transaction.id != viewModel.recentTransactions.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("quick_actions", comment: "Quick Actions"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: NSLocalizedString("add_transaction", comment: "Add Transaction"),
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // Action
                }
                
                QuickActionButton(
                    title: NSLocalizedString("add_account", comment: "Add Account"),
                    icon: "wallet.pass.fill",
                    color: .green
                ) {
                    // Action
                }
                
                QuickActionButton(
                    title: NSLocalizedString("create_budget", comment: "Create Budget"),
                    icon: "chart.pie.fill",
                    color: .orange
                ) {
                    // Action
                }
                
                QuickActionButton(
                    title: NSLocalizedString("set_goal", comment: "Set Goal"),
                    icon: "target",
                    color: .purple
                ) {
                    // Action
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var compact: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(compact ? .title3 : .title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(compact ? .title2 : .largeTitle)
                .foregroundStyle(color.gradient)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EmptyActivityRow: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 10)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 14)
        }
        .padding()
    }
}

struct TransactionRow: View {
    let transaction: WebAppTransaction
    let viewModel: DashboardViewModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(categoryColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(transaction.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.formatCurrency(transaction.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == .credit ? .green : .red)
                
                Text(viewModel.formatDate(transaction.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var categoryColor: Color {
        switch transaction.category.lowercased() {
        case "food", "groceries": return .orange
        case "transport", "fuel": return .blue
        case "entertainment": return .purple
        case "shopping": return .pink
        case "bills", "utilities": return .yellow
        case "health", "medical": return .red
        case "salary", "income": return .green
        default: return .gray
        }
    }
    
    private var categoryIcon: String {
        switch transaction.category.lowercased() {
        case "food", "groceries": return "cart.fill"
        case "transport", "fuel": return "car.fill"
        case "entertainment": return "ticket.fill"
        case "shopping": return "bag.fill"
        case "bills", "utilities": return "bolt.fill"
        case "health", "medical": return "cross.case.fill"
        case "salary", "income": return "banknote.fill"
        default: return "tag.fill"
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color.gradient)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    DashboardView()
}
