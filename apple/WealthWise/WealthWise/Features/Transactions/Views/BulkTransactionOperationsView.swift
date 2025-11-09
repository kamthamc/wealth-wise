//
//  BulkTransactionOperationsView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Bulk operations interface for multiple transaction management
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct BulkTransactionOperationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: TransactionsViewModel
    
    @State private var selectedTransactions: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showDeleteConfirmation = false
    @State private var showCategoryEditor = false
    @State private var showAccountPicker = false
    
    @State private var newCategory: String = ""
    @State private var newAccountId: UUID?
    
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    let transactions: [WebAppTransaction]
    
    init(transactions: [WebAppTransaction], modelContext: ModelContext) {
        self.transactions = transactions
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selection toolbar
                if isSelectionMode {
                    selectionToolbar
                        .padding()
                        .background(Color.blue.opacity(0.1))
                }
                
                // Transaction list
                List {
                    ForEach(transactions) { transaction in
                        transactionRow(transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(transaction)
                            }
                    }
                }
                .listStyle(.plain)
                
                // Action toolbar
                if isSelectionMode && !selectedTransactions.isEmpty {
                    actionToolbar
                        .padding()
                        .background(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                }
            }
            .navigationTitle("Select Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isSelectionMode ? "Done" : "Select All") {
                        if isSelectionMode {
                            isSelectionMode = false
                            selectedTransactions.removeAll()
                        } else {
                            isSelectionMode = true
                            selectedTransactions = Set(transactions.map { $0.id })
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete Transactions",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(selectedTransactions.count) Transactions", role: .destructive) {
                    Task {
                        await bulkDelete()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedTransactions.count) transactions? This action cannot be undone.")
            }
            .sheet(isPresented: $showCategoryEditor) {
                categoryEditorSheet
            }
            .sheet(isPresented: $showAccountPicker) {
                accountPickerSheet
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    // MARK: - Selection Toolbar
    
    @ViewBuilder
    private var selectionToolbar: some View {
        HStack {
            Text("\(selectedTransactions.count) selected")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
            
            Spacer()
            
            if selectedTransactions.count < transactions.count {
                Button("Select All") {
                    selectedTransactions = Set(transactions.map { $0.id })
                }
                .font(.subheadline)
            } else {
                Button("Deselect All") {
                    selectedTransactions.removeAll()
                }
                .font(.subheadline)
            }
        }
    }
    
    // MARK: - Transaction Row
    
    @ViewBuilder
    private func transactionRow(_ transaction: WebAppTransaction) -> some View {
        HStack(spacing: 12) {
            // Selection checkbox
            if isSelectionMode {
                Image(systemName: selectedTransactions.contains(transaction.id) ? 
                      "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedTransactions.contains(transaction.id) ? 
                                   .blue : .secondary)
                    .font(.title3)
            }
            
            // Category icon
            Image(systemName: iconForCategory(transaction.category))
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(colorForTransactionType(transaction.type))
                )
            
            // Transaction info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
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
        .padding(.vertical, 4)
        .background(selectedTransactions.contains(transaction.id) ?
                   Color.blue.opacity(0.05) : Color.clear)
    }
    
    // MARK: - Action Toolbar
    
    @ViewBuilder
    private var actionToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Change Category
                Button {
                    showCategoryEditor = true
                } label: {
                    Label("Change Category", systemImage: "tag")
                }
                .buttonStyle(.bordered)
                
                // Move to Account
                Button {
                    showAccountPicker = true
                } label: {
                    Label("Move to Account", systemImage: "arrow.right.arrow.left")
                }
                .buttonStyle(.bordered)
                
                // Delete
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Category Editor Sheet
    
    @ViewBuilder
    private var categoryEditorSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(WebAppTransaction.defaultCategories.keys.sorted(), id: \.self) { category in
                        Button {
                            newCategory = category
                            Task {
                                await bulkUpdateCategory()
                            }
                        } label: {
                            HStack {
                                Image(systemName: iconForCategory(category))
                                    .foregroundStyle(colorForCategory(category))
                                Text(category)
                                Spacer()
                                if newCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select New Category")
                } footer: {
                    Text("This will change the category for all \(selectedTransactions.count) selected transactions")
                }
            }
            .navigationTitle("Change Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCategoryEditor = false
                    }
                }
            }
        }
    }
    
    // MARK: - Account Picker Sheet
    
    @ViewBuilder
    private var accountPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.accounts) { account in
                    Button {
                        newAccountId = account.id
                        Task {
                            await bulkMoveToAccount()
                        }
                    } label: {
                        HStack {
                            Image(systemName: iconForAccountType(account.type))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        colors: gradientForAccountType(account.type),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.subheadline.bold())
                                if let institution = account.institution {
                                    Text(institution)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if newAccountId == account.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAccountPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSelection(_ transaction: WebAppTransaction) {
        if !isSelectionMode {
            isSelectionMode = true
        }
        
        if selectedTransactions.contains(transaction.id) {
            selectedTransactions.remove(transaction.id)
        } else {
            selectedTransactions.insert(transaction.id)
        }
    }
    
    private func bulkDelete() async {
        isProcessing = true
        errorMessage = ""
        
        do {
            let transactionsToDelete = transactions.filter { selectedTransactions.contains($0.id) }
            
            for transaction in transactionsToDelete {
                modelContext.delete(transaction)
            }
            
            try modelContext.save()
            
            isProcessing = false
            successMessage = "Successfully deleted \(transactionsToDelete.count) transactions"
            showSuccess = true
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func bulkUpdateCategory() async {
        guard !newCategory.isEmpty else { return }
        
        isProcessing = true
        errorMessage = ""
        
        do {
            let transactionsToUpdate = transactions.filter { selectedTransactions.contains($0.id) }
            
            for transaction in transactionsToUpdate {
                transaction.category = newCategory
                transaction.updatedAt = Date()
            }
            
            try modelContext.save()
            
            isProcessing = false
            showCategoryEditor = false
            successMessage = "Successfully updated category for \(transactionsToUpdate.count) transactions"
            showSuccess = true
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func bulkMoveToAccount() async {
        guard let accountId = newAccountId else { return }
        
        isProcessing = true
        errorMessage = ""
        
        do {
            let transactionsToUpdate = transactions.filter { selectedTransactions.contains($0.id) }
            
            for transaction in transactionsToUpdate {
                transaction.accountId = accountId
                transaction.updatedAt = Date()
            }
            
            try modelContext.save()
            
            isProcessing = false
            showAccountPicker = false
            successMessage = "Successfully moved \(transactionsToUpdate.count) transactions"
            showSuccess = true
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Groceries": return "cart"
        case "Rent": return "house"
        case "Transport": return "car"
        case "Healthcare": return "cross.case"
        case "Entertainment": return "tv"
        case "Shopping": return "bag"
        case "Food & Dining": return "fork.knife"
        case "Utilities": return "bolt"
        case "Salary": return "briefcase"
        case "Business Income": return "building.2"
        case "Investment": return "chart.line.uptrend.xyaxis"
        default: return "tag"
        }
    }
    
    private func colorForTransactionType(_ type: WebAppTransaction.TransactionType) -> Color {
        type == .credit ? .green : .red
    }
    
    private func colorForCategory(_ category: String) -> Color {
        if let type = WebAppTransaction.defaultCategories[category] {
            switch type {
            case .income: return .green
            case .expense: return .red
            case .investment: return .blue
            }
        }
        return .gray
    }
    
    private func iconForAccountType(_ type: Account.AccountType) -> String {
        switch type {
        case .bank: return "banknote"
        case .creditCard: return "creditcard"
        case .upi: return "indianrupeesign.circle"
        case .brokerage: return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func gradientForAccountType(_ type: Account.AccountType) -> [Color] {
        switch type {
        case .bank: return [.blue, .cyan]
        case .creditCard: return [.orange, .pink]
        case .upi: return [.purple, .indigo]
        case .brokerage: return [.green, .mint]
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "₹0"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Bulk Operations") {
    let container = try! ModelContainer(
        for: WebAppTransaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let transactions = (1...10).map { i in
        WebAppTransaction(
            userId: "preview",
            accountId: UUID(),
            date: Date(),
            amount: Decimal(1000 * i),
            type: i % 2 == 0 ? .credit : .debit,
            category: i % 2 == 0 ? "Salary" : "Groceries",
            description: "Transaction \(i)"
        )
    }
    
    transactions.forEach { container.mainContext.insert($0) }
    
    return BulkTransactionOperationsView(
        transactions: transactions,
        modelContext: container.mainContext
    )
}
#endif
