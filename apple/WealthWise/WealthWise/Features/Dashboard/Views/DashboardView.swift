//
//  DashboardView.swift
//  WealthWise
//
//  Main dashboard with financial overview
//

import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSettings = false
    
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
                    value: "₹0.00",
                    icon: "indianrupeesign.circle.fill",
                    color: .blue
                )
                
                HStack(spacing: 12) {
                    StatCard(
                        title: NSLocalizedString("income", comment: "Income"),
                        value: "₹0.00",
                        icon: "arrow.down.circle.fill",
                        color: .green,
                        compact: true
                    )
                    
                    StatCard(
                        title: NSLocalizedString("expenses", comment: "Expenses"),
                        value: "₹0.00",
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
            
            VStack(spacing: 0) {
                ForEach(0..<3) { _ in
                    EmptyActivityRow()
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EmptyActivityRow: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 10)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 14)
        }
        .padding()
        .background(Color(.systemBackground))
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
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
}
