//
//  TransactionsView.swift
//  WealthWise
//
//  Transactions list and filtering
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TransactionsViewModel
    @State private var showAddTransaction = false
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: context))
    }
    
    enum TransactionFilter: String, CaseIterable {
        case all, income, expense
        
        var localizedName: String {
            switch self {
            case .all:
                return NSLocalizedString("all", comment: "All")
            case .income:
                return NSLocalizedString("income", comment: "Income")
            case .expense:
                return NSLocalizedString("expense", comment: "Expense")
            }
        }
        
        var vmFilter: TransactionsViewModel.TransactionFilter {
            switch self {
            case .all: return .all
            case .income: return .income
            case .expense: return .expense
            }
        }
    }
    
    @State private var selectedFilter: TransactionFilter = .all
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        Text(filter.localizedName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedFilter) { _, newValue in
                    viewModel.setFilter(newValue.vmFilter)
                }
                
                // Transactions List
                if viewModel.hasTransactions && !viewModel.filteredTransactions.isEmpty {
                    List {
                        ForEach(viewModel.transactionsByDate(), id: \.0) { date, transactions in
                            Section(header: Text(viewModel.formatDateHeader(date))) {
                                ForEach(transactions) { transaction in
                                    TransactionListRow(transaction: transaction, viewModel: viewModel)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                Task {
                                                    await viewModel.deleteTransaction(transaction)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        EmptyStateView(
                            icon: "list.bullet.rectangle.fill",
                            title: NSLocalizedString("no_transactions", comment: "No Transactions"),
                            message: NSLocalizedString("add_transaction_message", comment: "Add your first transaction to see it here")
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("transactions", comment: "Transactions"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.updateSearchText($0) }
                ),
                prompt: NSLocalizedString("search_transactions", comment: "Search transactions")
            )
            .task {
                await viewModel.loadTransactions()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showAddTransaction) {
                Text("Add Transaction Form")
            }
        }
    }
}

// MARK: - Supporting Views

struct TransactionListRow: View {
    let transaction: WebAppTransaction
    let viewModel: TransactionsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(categoryColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.accountName(for: transaction))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(viewModel.formatCurrency(transaction.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(transaction.type == .credit ? .green : .red)
        }
        .padding(.vertical, 4)
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

#Preview {
    TransactionsView()
}
