//
//  AccountDetailView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Detailed account view with transaction history and analytics
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var transactionsViewModel: TransactionsViewModel
    @StateObject private var accountsViewModel: AccountsViewModel
    
    let account: Account
    
    // UI state
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText: String = ""
    @State private var showAddTransaction = false
    @State private var showEditAccount = false
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expense = "Expense"
        case thisMonth = "This Month"
    }
    
    init(account: Account, modelContext: ModelContext) {
        self.account = account
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: modelContext))
        _accountsViewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account Header Card
                accountHeaderCard
                
                // Quick Stats
                quickStatsSection
                
                // Transaction Filter
                filterSection
                
                // Transactions List
                transactionsSection
            }
            .padding()
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditAccount = true
                    } label: {
                        Label("Edit Account", systemImage: "pencil")
                    }
                    
                    Button {
                        showAddTransaction = true
                    } label: {
                        Label("Add Transaction", systemImage: "plus.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        // Archive functionality
                    } label: {
                        Label(
                            account.isArchived ? "Unarchive" : "Archive",
                            systemImage: account.isArchived ? "archivebox" : "archivebox.fill"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(modelContext: modelContext, accountId: account.id)
        }
        .sheet(isPresented: $showEditAccount) {
            EditAccountView(account: account, modelContext: modelContext)
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Account Header Card
    
    @ViewBuilder
    private var accountHeaderCard: some View {
        VStack(spacing: 16) {
            // Account Icon and Type
            HStack {
                Image(systemName: account.iconName)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(gradientForAccountType(account.type))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.typeDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let institution = account.institution {
                        Text(institution)
                            .font(.subheadline.bold())
                    }
                    
                    Text(account.currency)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Current Balance
            VStack(spacing: 8) {
                Text("Current Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatCurrency(account.currentBalance))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(account.currentBalance >= 0 ? .primary : .red)
            }
            
            // Account Info
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Created")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(account.createdAt, style: .date)
                        .font(.caption)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Last Updated")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(account.updatedAt, style: .relative)
                        .font(.caption)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Status")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(account.isArchived ? "Archived" : "Active")
                        .font(.caption)
                        .foregroundStyle(account.isArchived ? .orange : .green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Quick Stats Section
    
    @ViewBuilder
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            statsCard(
                title: "Income",
                value: calculateIncome(),
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            statsCard(
                title: "Expense",
                value: calculateExpense(),
                color: .red,
                icon: "arrow.down.circle.fill"
            )
            
            statsCard(
                title: "Transactions",
                value: "\(filteredTransactions.count)",
                color: .blue,
                icon: "list.bullet"
            )
        }
    }
    
    @ViewBuilder
    private func statsCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - Filter Section
    
    @ViewBuilder
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search transactions...", text: $searchText)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        filterChip(filter)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func filterChip(_ filter: TransactionFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedFilter == filter ? Color.blue : Color(.systemGray5))
                .foregroundStyle(selectedFilter == filter ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Transactions Section
    
    @ViewBuilder
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transactions")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showAddTransaction = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
            }
            
            if filteredTransactions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTransactions) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func transactionRow(_ transaction: WebAppTransaction) -> some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: iconForCategory(transaction.category))
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(colorForCategory(transaction.category))
                .clipShape(Circle())
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.transactionDescription)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Amount
            Text(formatCurrency(transaction.amount))
                .font(.subheadline.bold())
                .foregroundStyle(transaction.type == .credit ? .green : .red)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Transactions")
                .font(.headline)
            
            Text("Add your first transaction to this account")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddTransaction = true
            } label: {
                Label("Add Transaction", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        await transactionsViewModel.loadTransactions()
    }
    
    // MARK: - Filtering
    
    private var filteredTransactions: [WebAppTransaction] {
        var transactions = transactionsViewModel.transactions.filter { $0.accountId == account.id }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .income:
            transactions = transactions.filter { $0.type == .credit }
        case .expense:
            transactions = transactions.filter { $0.type == .debit }
        case .thisMonth:
            let calendar = Calendar.current
            transactions = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.transactionDescription.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    // MARK: - Calculations
    
    private func calculateIncome() -> String {
        let income = filteredTransactions
            .filter { $0.type == .credit }
            .reduce(Decimal(0)) { $0 + $1.amount }
        return formatCurrency(income)
    }
    
    private func calculateExpense() -> String {
        let expense = filteredTransactions
            .filter { $0.type == .debit }
            .reduce(Decimal(0)) { $0 + $1.amount }
        return formatCurrency(expense)
    }
    
    // MARK: - Helper Methods
    
    private func gradientForAccountType(_ type: Account.AccountType) -> LinearGradient {
        switch type {
        case .bank:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .creditCard:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .upi:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .brokerage:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Salary": return "banknote"
        case "Groceries": return "cart"
        case "Transport": return "car"
        case "Healthcare": return "cross.case"
        case "Entertainment": return "tv"
        case "Shopping": return "bag"
        case "Food & Dining": return "fork.knife"
        default: return "tag"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        guard let categoryType = WebAppTransaction.defaultCategories[category] else {
            return .gray
        }
        
        switch categoryType {
        case .income: return .green
        case .expense: return .red
        case .investment: return .blue
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: amount as NSNumber) ?? "₹0"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Account Detail") {
    let container = try! ModelContainer(
        for: Account.self, WebAppTransaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let account = Account(
        userId: "preview",
        name: "HDFC Savings",
        type: .bank,
        institution: "HDFC Bank",
        currentBalance: 125000
    )
    container.mainContext.insert(account)
    
    // Add sample transactions
    let transaction1 = WebAppTransaction(
        userId: "preview",
        accountId: account.id,
        date: Date(),
        amount: 5000,
        type: .credit,
        category: "Salary",
        description: "Monthly salary"
    )
    container.mainContext.insert(transaction1)
    
    return NavigationStack {
        AccountDetailView(account: account, modelContext: container.mainContext)
    }
}
#endif
