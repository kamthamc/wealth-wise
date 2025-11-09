//
//  AddTransactionView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Add new transaction form with account and category pickers
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: TransactionsViewModel
    @StateObject private var accountsViewModel: AccountsViewModel
    
    // Form fields
    @State private var amount: String = ""
    @State private var transactionType: WebAppTransaction.TransactionType = .debit
    @State private var date: Date = Date()
    @State private var selectedAccountId: UUID?
    @State private var selectedCategory: String = "Groceries"
    @State private var transactionDescription: String = ""
    @State private var notes: String = ""
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init(modelContext: ModelContext, accountId: UUID? = nil) {
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: modelContext))
        _accountsViewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: modelContext))
        _selectedAccountId = State(initialValue: accountId)
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
                        Text(NSLocalizedString("select_account", comment: "Select Account"))
                            .tag(nil as UUID?)
                        
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
                            .tag(account.id as UUID?)
                        }
                    }
                    
                    if accountsViewModel.accounts.isEmpty {
                        Label {
                            Text(NSLocalizedString("no_accounts_available", comment: "No accounts available"))
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
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
                    .textInputAutocapitalization(.sentences)
                    
                    TextField(
                        NSLocalizedString("notes_optional", comment: "Notes (optional)"),
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    
                } header: {
                    Text(NSLocalizedString("additional_info", comment: "Additional Information"))
                }
            }
            .navigationTitle(NSLocalizedString("add_transaction", comment: "Add Transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save", comment: "Save")) {
                        Task {
                            await createTransaction()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
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
            .alert(
                NSLocalizedString("error", comment: "Error"),
                isPresented: $showError
            ) {
                Button(NSLocalizedString("ok", comment: "OK"), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert(
                NSLocalizedString("success", comment: "Success"),
                isPresented: $showSuccess
            ) {
                Button(NSLocalizedString("ok", comment: "OK"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(NSLocalizedString("transaction_created", comment: "Transaction created successfully"))
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
        
        Picker(
            NSLocalizedString("category", comment: "Category"),
            selection: $selectedCategory
        ) {
            ForEach(categories.sorted(), id: \.self) { category in
                HStack {
                    Image(systemName: iconForCategory(category))
                        .foregroundStyle(colorForCategory(category))
                    Text(category)
                }
                .tag(category)
            }
        }
        
        // Category icon preview
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
        
        guard selectedAccountId != nil else {
            return false
        }
        
        guard !transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        return true
    }
    
    // MARK: - Actions
    
    private func createTransaction() async {
        guard isFormValid,
              let amountValue = Decimal(string: amount),
              let accountId = selectedAccountId else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedDescription = transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await viewModel.createTransaction(
                accountId: accountId,
                amount: amountValue,
                type: transactionType,
                category: selectedCategory,
                description: trimmedDescription,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                date: date
            )
            
            isLoading = false
            showSuccess = true
            
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
        // Income
        case "Salary": return "banknote"
        case "Business Income": return "building.2"
        case "Freelance": return "laptopcomputer"
        case "Investment Returns": return "chart.line.uptrend.xyaxis"
        case "Rental Income": return "house"
        case "Gift Received": return "gift"
        case "Refund": return "arrow.uturn.backward"
        case "Bonus": return "star.fill"
        case "Other Income": return "plus.circle"
        
        // Expenses
        case "Groceries": return "cart"
        case "Rent": return "house"
        case "Utilities": return "bolt"
        case "Transport": return "car"
        case "Healthcare": return "cross.case"
        case "Education": return "book"
        case "Entertainment": return "tv"
        case "Shopping": return "bag"
        case "Food & Dining": return "fork.knife"
        case "Insurance": return "shield"
        case "EMI": return "creditcard"
        case "Taxes": return "doc.text"
        case "Gift Given": return "gift"
        case "Personal Care": return "heart"
        case "Other Expenses": return "ellipsis.circle"
        
        // Investments
        case "Mutual Funds": return "chart.pie"
        case "Stocks": return "chart.bar"
        case "Fixed Deposit": return "banknote.fill"
        case "Recurring Deposit": return "repeat.circle"
        case "Gold": return "sparkles"
        case "PPF": return "building.columns"
        case "Other Investment": return "chart.line.uptrend.xyaxis.circle"
        
        default: return "questionmark.circle"
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
#Preview("Add Transaction") {
    let container = try! ModelContainer(
        for: Account.self, WebAppTransaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // Add sample account
    let account = Account(
        userId: "preview",
        name: "HDFC Savings",
        type: .bank,
        institution: "HDFC Bank"
    )
    container.mainContext.insert(account)
    
    return AddTransactionView(
        modelContext: container.mainContext,
        accountId: account.id
    )
}
#endif
