//
//  AccountsView.swift
//  WealthWise
//
//  Accounts list and management
//

import SwiftUI

struct AccountsView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Total Balance Card
                    totalBalanceCard
                    
                    // Accounts List
                    accountsListSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("accounts", comment: "Accounts"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Add account
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var totalBalanceCard: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("total_balance", comment: "Total Balance"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("₹0.00")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("0")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(NSLocalizedString("accounts", comment: "Accounts"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("₹0.00")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(NSLocalizedString("monthly_avg", comment: "Monthly Avg"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [.blue, .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("your_accounts", comment: "Your Accounts"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                EmptyStateView(
                    icon: "wallet.pass.fill",
                    title: NSLocalizedString("no_accounts_yet", comment: "No Accounts Yet"),
                    message: NSLocalizedString("add_account_message", comment: "Add your first account to start tracking your finances")
                )
            }
        }
    }
}

#Preview {
    AccountsView()
}
