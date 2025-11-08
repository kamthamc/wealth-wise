//
//  AccountsView.swift
//  WealthWise
//
//  Accounts list and management
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AccountsViewModel
    @State private var showAddAccount = false
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _viewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: context))
    }
    
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
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadAccounts()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.hasAccounts {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showAddAccount) {
                Text("Add Account Form")
            }
        }
    }
    
    // MARK: - View Components
    
    private var totalBalanceCard: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("total_balance", comment: "Total Balance"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(viewModel.formatCurrency(viewModel.totalBalance))
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(viewModel.activeAccountCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(NSLocalizedString("accounts", comment: "Accounts"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(viewModel.formatCurrency(viewModel.monthlyAverage))
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("your_accounts", comment: "Your Accounts"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.hasAccounts {
                VStack(spacing: 12) {
                    ForEach(viewModel.accounts) { account in
                        AccountCard(account: account, viewModel: viewModel)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "wallet.pass.fill",
                    title: NSLocalizedString("no_accounts_yet", comment: "No Accounts Yet"),
                    message: NSLocalizedString("add_account_message", comment: "Add your first account to start tracking your finances")
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct AccountCard: View {
    let account: Account
    let viewModel: AccountsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(viewModel.accountTypeColor(account.type).opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: viewModel.accountTypeIcon(account.type))
                        .font(.title3)
                        .foregroundStyle(viewModel.accountTypeColor(account.type))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                
                if let institution = account.institution {
                    Text(institution)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.accountBalance(account))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(account.type.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AccountsView()
}
