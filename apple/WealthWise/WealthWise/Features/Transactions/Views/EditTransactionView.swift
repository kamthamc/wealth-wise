//
//  EditTransactionView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Edit existing transaction with delete functionality
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: TransactionsViewModel
    @StateObject private var accountsViewModel: AccountsViewModel
    
    let transaction: WebAppTransaction
    
    // Form fields
    @State private var amount: String
    @State private var transactionType: WebAppTransaction.TransactionType
    @State private var date: Date
    @State private var selectedAccountId: UUID
    @State private var selectedCategory: String
    @State private var transactionDescription: String
    @State private var notes: String
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showDeleteConfirmation = false
    
    init(transaction: WebAppTransaction, modelContext: ModelContext) {
        self.transaction = transaction
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: modelContext))
        _accountsViewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: modelContext))
        
        // Initialize state from transaction
        _amount = State(initialValue: transaction.amount.description)
        _transactionType = State(initialValue: transaction.type)
        _date = State(initialValue: transaction.date)
        _selectedAccountId = State(initialValue: transaction.accountId)
        _selectedCategory = State(initialValue: transaction.category)
        _transactionDescription = State(initialValue: transaction.transactionDescription)
        _notes = State(initialValue: transaction.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Transaction Type Section
                Section {
                    Picker(
                        NSLocalizedString("transaction_type", comment: "Type"),
                        selection: $transactionType
                    ) {
                        Label {
                            Text(NSLocalizedString("transaction_type_expense", comment: "Expense"))
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .tag(WebAppTransaction.TransactionType.debit)
                        
                        Label {
                            Text(NSLocalizedString("transaction_type_income", comment: "Income"))
                        } icon: {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .tag(WebAppTransaction.TransactionType.credit)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(NSLocalizedString("transaction_type", comment: "Type"))
                }
                
                // Amount Section
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            NSLocalizedString("amount", comment: "Amount"),
                            text: $amount
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title2.bold())
                    }
                    
                    if let amountValue = Decimal(string: amount) {
                        Text(formatCurrency(amountValue))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    DatePicker(
                        NSLocalizedString("date", comment: "Date"),
                        selection: $date,
                        displayedComponents: .date
                    )
                    
                } header: {
                    Text(NSLocalizedString("transaction_details", comment: "Transaction Details"))
                }
                
                // Account Section
                Section {
                    Picker(
                        NSLocalizedString("account", comment: "Account"),
                        selection: $selectedAccountId
                    ) {
                        ForEach(accountsViewModel.accounts) { account in
                            HStack {
                                Image(systemName: account.iconName)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                    if let institution = account.institution {
                                        Text(institution)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .tag(account.id)
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("account", comment: "Account"))
                }
                
                // Category Section
                Section {
                    categoryPicker
                } header: {
                    Text(NSLocalizedString("category", comment: "Category"))
                }
                
                // Description Section
                Section {
                    TextField(
                        NSLocalizedString("description", comment: "Description"),
                        text: $transactionDescription
                    )
                    
                    TextField(
                        NSLocalizedString("notes_optional", comment: "Notes (optional)"),
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    
                } header: {
                    Text(NSLocalizedString("additional_info", comment: "Additional Information"))
                }
                
                // Transaction Info
                Section {
                    LabeledContent {
                        Text(transaction.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Created", systemImage: "calendar.badge.plus")
                    }
                    
                    LabeledContent {
                        Text(transaction.updatedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Last Updated", systemImage: "clock")
                    }
                } header: {
                    Text("Information")
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Transaction", systemImage: "trash")
                    }
                } footer: {
                    Text("Deleting this transaction will permanently remove it from your records. This action cannot be undone.")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateTransaction()
                        }
                    }
                    .disabled(!isFormValid || isLoading || !hasChanges)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .confirmationDialog(
                "Delete Transaction",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteTransaction()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this transaction? This action cannot be undone.")
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
                Text("Transaction updated successfully")
            }
            .task {
                await accountsViewModel.loadAccounts()
            }
        }
    }
    
    // MARK: - Category Picker
    
    @ViewBuilder
    private var categoryPicker: some View {
        let categories = categoriesForType(transactionType)
        
        Picker("Category", selection: $selectedCategory) {
            ForEach(categories.sorted(), id: \.self) { category in
                HStack {
                    Image(systemName: iconForCategory(category))
                        .foregroundStyle(colorForCategory(category))
                    Text(category)
                }
                .tag(category)
            }
        }
        
        Label {
            Text(selectedCategory)
        } icon: {
            Image(systemName: iconForCategory(selectedCategory))
                .foregroundStyle(colorForCategory(selectedCategory))
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            return false
        }
        
        guard !transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        return true
    }
    
    private var hasChanges: Bool {
        guard let amountValue = Decimal(string: amount) else { return false }
        
        let trimmedDescription = transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return amountValue != transaction.amount ||
               transactionType != transaction.type ||
               date != transaction.date ||
               selectedAccountId != transaction.accountId ||
               selectedCategory != transaction.category ||
               trimmedDescription != transaction.transactionDescription ||
               trimmedNotes != (transaction.notes ?? "")
    }
    
    // MARK: - Actions
    
    private func updateTransaction() async {
        guard isFormValid, hasChanges,
              let amountValue = Decimal(string: amount) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedDescription = transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Update transaction properties
            transaction.amount = amountValue
            transaction.type = transactionType
            transaction.date = date
            transaction.accountId = selectedAccountId
            transaction.category = selectedCategory
            transaction.transactionDescription = trimmedDescription
            transaction.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            transaction.updatedAt = Date()
            
            // Save through repository
            try await viewModel.updateTransaction(transaction)
            
            isLoading = false
            showSuccess = true
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteTransaction() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await viewModel.deleteTransaction(transaction)
            isLoading = false
            dismiss()
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func categoriesForType(_ type: WebAppTransaction.TransactionType) -> [String] {
        WebAppTransaction.defaultCategories
            .filter { category, categoryType in
                switch type {
                case .debit:
                    return categoryType == .expense || categoryType == .investment
                case .credit:
                    return categoryType == .income
                }
            }
            .map { $0.key }
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
#Preview("Edit Transaction") {
    let container = try! ModelContainer(
        for: Account.self, WebAppTransaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let account = Account(
        userId: "preview",
        name: "HDFC Savings",
        type: .bank
    )
    container.mainContext.insert(account)
    
    let transaction = WebAppTransaction(
        userId: "preview",
        accountId: account.id,
        date: Date(),
        amount: 1200,
        type: .debit,
        category: "Groceries",
        description: "Weekly groceries"
    )
    container.mainContext.insert(transaction)
    
    return EditTransactionView(
        transaction: transaction,
        modelContext: container.mainContext
    )
}
#endif
