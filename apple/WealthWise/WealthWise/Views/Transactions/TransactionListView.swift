//
//  TransactionListView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Transaction Management System: Transaction list UI component
//

import SwiftUI
import SwiftData

/// Main transaction list view with search, filtering, and management capabilities
@available(iOS 18.6, macOS 15.6, *)
public struct TransactionListView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @State private var transactionService: TransactionService?
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var selectedType: TransactionType?
    @State private var selectedCategory: TransactionCategory?
    @State private var showingAddTransaction = false
    @State private var showingFilterSheet = false
    @State private var selectedTransactions = Set<Transaction.ID>()
    @State private var showingBulkActions = false
    
    // Filter states
    @State private var dateRange: DateInterval?
    @State private var amountRange: ClosedRange<Decimal>?
    @State private var selectedCurrency: String?
    
    // MARK: - Computed Properties
    
    private var filteredTransactions: [Transaction] {
        guard let service = transactionService else { return [] }
        
        var filtered = service.transactions
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.transactionDescription.localizedCaseInsensitiveContains(searchText) ||
                transaction.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                transaction.merchantName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply type filter
        if let type = selectedType {
            filtered = filtered.filter { $0.transactionType == type }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply date range filter
        if let range = dateRange {
            filtered = filtered.filter { range.contains($0.date) }
        }
        
        // Apply amount range filter
        if let range = amountRange {
            filtered = filtered.filter { range.contains(abs($0.amount)) }
        }
        
        // Apply currency filter
        if let currency = selectedCurrency {
            filtered = filtered.filter { $0.currency == currency }
        }
        
        return filtered
    }
    
    private var hasActiveFilters: Bool {
        selectedType != nil || selectedCategory != nil || dateRange != nil || 
        amountRange != nil || selectedCurrency != nil
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with search and filters
                headerView
                
                // Transaction list
                transactionListContent
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    toolbarButtons
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions")
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    selectedType: $selectedType,
                    selectedCategory: $selectedCategory,
                    dateRange: $dateRange,
                    amountRange: $amountRange,
                    selectedCurrency: $selectedCurrency
                )
            }
            .sheet(isPresented: $showingBulkActions) {
                BulkActionsView(
                    selectedTransactions: Array(selectedTransactions.compactMap { id in
                        transactionService?.transactions.first { $0.id == id }
                    }),
                    transactionService: transactionService
                )
            }
        }
        .onAppear {
            if transactionService == nil {
                transactionService = TransactionService(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerView: some View {
        if hasActiveFilters || !selectedTransactions.isEmpty {
            HStack {
                if hasActiveFilters {
                    filterChipsView
                }
                
                Spacer()
                
                if !selectedTransactions.isEmpty {
                    Text("\(selectedTransactions.count) selected")
                        .foregroundColor(.secondary)
                    
                    Button("Bulk Actions") {
                        showingBulkActions = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let type = selectedType {
                    FilterChip(
                        title: type.displayName,
                        systemImage: type.systemImageName
                    ) {
                        selectedType = nil
                    }
                }
                
                if let category = selectedCategory {
                    FilterChip(
                        title: category.displayName,
                        systemImage: category.systemImageName
                    ) {
                        selectedCategory = nil
                    }
                }
                
                if dateRange != nil {
                    FilterChip(
                        title: "Date Range",
                        systemImage: "calendar"
                    ) {
                        dateRange = nil
                    }
                }
                
                if amountRange != nil {
                    FilterChip(
                        title: "Amount Range",
                        systemImage: "dollarsign.circle"
                    ) {
                        amountRange = nil
                    }
                }
                
                if selectedCurrency != nil {
                    FilterChip(
                        title: selectedCurrency ?? "",
                        systemImage: "banknote"
                    ) {
                        selectedCurrency = nil
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var transactionListContent: some View {
        if let service = transactionService {
            if service.isLoading {
                ProgressView("Loading transactions...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTransactions.isEmpty {
                emptyStateView
            } else {
                List(selection: $selectedTransactions) {
                    ForEach(groupedTransactions, id: \.key) { date, transactions in
                        Section(header: sectionHeader(for: date)) {
                            ForEach(transactions) { transaction in
                                TransactionRowView(
                                    transaction: transaction,
                                    isSelected: selectedTransactions.contains(transaction.id)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(for: transaction)
                                }
                            }
                            .onDelete { indexSet in
                                deleteTransactions(at: indexSet, from: transactions)
                            }
                        }
                    }
                }
                #if os(macOS)
            .listStyle(.sidebar)
            #else
            .listStyle(.insetGrouped)
            #endif
            }
            
            if let error = service.error {
                ErrorBanner(error: error)
            }
        } else {
            ProgressView("Initializing...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Transactions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(searchText.isEmpty ? 
                 "Add your first transaction to get started" : 
                 "No transactions match your search")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                Button("Add Transaction") {
                    showingAddTransaction = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var toolbarButtons: some View {
        HStack {
            Button {
                showingFilterSheet = true
            } label: {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            
            Button {
                showingAddTransaction = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var groupedTransactions: [(key: String, value: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            DateFormatter.dayFormatter.string(from: transaction.date)
        }
        
        return grouped.sorted { first, second in
            guard let firstDate = DateFormatter.dayFormatter.date(from: first.key),
                  let secondDate = DateFormatter.dayFormatter.date(from: second.key) else {
                return first.key > second.key
            }
            return firstDate > secondDate
        }
    }
    
    private func sectionHeader(for dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let date = DateFormatter.dayFormatter.date(from: dateString) {
                let dayTransactions = filteredTransactions.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
                
                let totalAmount = dayTransactions.reduce(0) { total, transaction in
                    switch transaction.transactionType {
                    case .income:
                        return total + NSDecimalNumber(decimal: transaction.baseCurrencyAmount).intValue
                    case .expense:
                        return total - abs(transaction.baseCurrencyAmount)
                    case .transfer, .investment:
                        return total
                    }
                }
                
                Text(CurrencyFormatter.shared.format(totalAmount))
                    .font(.subheadline)
                    .foregroundColor(totalAmount >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleSelection(for transaction: Transaction) {
        if selectedTransactions.contains(transaction.id) {
            selectedTransactions.remove(transaction.id)
        } else {
            selectedTransactions.insert(transaction.id)
        }
    }
    
    private func deleteTransactions(at indexSet: IndexSet, from transactions: [Transaction]) {
        let transactionsToDelete = indexSet.map { transactions[$0] }
        
        Task {
            do {
                try await transactionService?.deleteTransactions(transactionsToDelete)
            } catch {
                print("Failed to delete transactions: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption)
            
            Text(title)
                .font(.caption)
                .lineLimit(1)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(12)
    }
}

private struct ErrorBanner: View {
    let error: TransactionError
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}