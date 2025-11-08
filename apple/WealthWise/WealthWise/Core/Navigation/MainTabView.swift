//
//  MainTabView.swift
//  WealthWise
//
//  Main tab navigation for authenticated users
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label(
                        NSLocalizedString("dashboard", comment: "Dashboard"),
                        systemImage: "chart.bar.fill"
                    )
                }
                .tag(0)
            
            // Accounts Tab
            AccountsView()
                .tabItem {
                    Label(
                        NSLocalizedString("accounts", comment: "Accounts"),
                        systemImage: "wallet.pass.fill"
                    )
                }
                .tag(1)
            
            // Transactions Tab
            TransactionsView()
                .tabItem {
                    Label(
                        NSLocalizedString("transactions", comment: "Transactions"),
                        systemImage: "list.bullet.rectangle.fill"
                    )
                }
                .tag(2)
            
            // Budgets Tab
            BudgetsView()
                .tabItem {
                    Label(
                        NSLocalizedString("budgets", comment: "Budgets"),
                        systemImage: "chart.pie.fill"
                    )
                }
                .tag(3)
            
            // Goals Tab
            GoalsView()
                .tabItem {
                    Label(
                        NSLocalizedString("goals", comment: "Goals"),
                        systemImage: "target"
                    )
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
