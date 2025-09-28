//
//  AddTransactionView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Transaction Management System: Add/Edit transaction form
//

import SwiftUI
import SwiftData

/// Form view for adding or editing transactions
@available(iOS 18.6, macOS 15.6, *)
public struct AddTransactionView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeConfiguration) private var themeConfiguration
    
    // MARK: - Properties
    
    let transaction: Transaction?
    private let isEditing: Bool
    
    @State private var transactionService: TransactionService?
    
    // MARK: - Form State
    
    @State private var amount: String = ""
    @State private var transactionDescription: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: TransactionCategory = .food_dining
    @State private var selectedDate: Date = Date()
    @State private var selectedCurrency: String = "INR"
    @State private var notes: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var location: String = ""
    @State private var referenceNumber: String = ""
    
    // UI State
    @State private var isSubmitting: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingDeleteConfirmation: Bool = false
    
    // MARK: - Initialization
    
    public init(transaction: Transaction? = nil) {
        self.transaction = transaction
        self.isEditing = transaction != nil
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            Form {
                // Amount Section
                amountSection
                
                // Basic Details Section
                basicDetailsSection
                
                // Category and Type Section
                categorySection
                
                // Additional Details Section
                additionalDetailsSection
                
                // Tags Section
                tagsSection
                
                // Delete Button (if editing)
                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "Add Transaction")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Update" : "Add") {
                        submitTransaction()
                    }
                    .disabled(isSubmitting || !isFormValid)
                }
            }
            .disabled(isSubmitting)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Delete Transaction",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteTransaction()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .onAppear {
            setupForm()
        }
    }
    
    // MARK: - Form Sections
    
    @ViewBuilder
    private var amountSection: some View {
        Section("Amount") {
            HStack {
                // Currency Picker
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(SupportedCurrency.allCases, id: \.self) { currency in
                        Text(currency.rawValue)
                            .tag(currency.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
                
                // Amount Field
                TextField("0.00", text: $amount)
                    #if !os(macOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    @ViewBuilder
    private var basicDetailsSection: some View {
        Section("Details") {
            // Description
            TextField("Description", text: $transactionDescription)
                .font(.body)
            
            // Date
            DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
            
            // Notes
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    @ViewBuilder
    private var categorySection: some View {
        Section("Category") {
            // Transaction Type
            Picker("Type", selection: $selectedType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.systemImageName)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Category
            Picker("Category", selection: $selectedCategory) {
                ForEach(availableCategories, id: \.self) { category in
                    Label(category.displayName, systemImage: category.systemImageName)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    @ViewBuilder
    private var additionalDetailsSection: some View {
        Section("Additional Information") {
            // Location
            TextField("Location (optional)", text: $location)
                .textContentType(.location)
            
            // Reference Number
            TextField("Reference Number (optional)", text: $referenceNumber)
        }
    }
    
    @ViewBuilder
    private var tagsSection: some View {
        Section("Tags") {
            // Existing Tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                withAnimation {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Add New Tag
            HStack {
                TextField("Add tag", text: $newTag)
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add", action: addTag)
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    @ViewBuilder
    private var deleteSection: some View {
        Section {
            Button("Delete Transaction") {
                showingDeleteConfirmation = true
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !amount.isEmpty &&
        !transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Decimal(string: amount) != nil &&
        Decimal(string: amount)! > 0
    }
    
    private var availableCategories: [TransactionCategory] {
        switch selectedType {
        case .income, .refund, .dividend, .interest, .capital_gain:
            return [.salary, .business_income, .dividend_income, .rental_income, .bonus]
        case .expense, .capital_loss:
            return [.food_dining, .transportation, .medical, .entertainment, .shopping, 
                   .utilities, .education, .travel, .other_expense]
        case .investment:
            return [.mutual_funds, .stocks, .bonds, .real_estate, .crypto]
        case .transfer:
            return [.bank_transfer, .cash_withdrawal, .fee_charges, .tax_payment]
        }
    }
    
    // MARK: - Form Actions
    
    private func setupForm() {
        transactionService = TransactionService(modelContext: modelContext)
        
        if let transaction = transaction {
            // Pre-populate form for editing
            amount = String(describing: transaction.amount)
            transactionDescription = transaction.transactionDescription
            selectedType = transaction.transactionType
            selectedCategory = transaction.category
            selectedDate = transaction.date
            selectedCurrency = transaction.currency
            notes = transaction.notes ?? ""
            tags = transaction.tags
            location = transaction.location?.address ?? ""
            referenceNumber = transaction.referenceNumber ?? ""
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        
        withAnimation {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func submitTransaction() {
        guard isFormValid,
              let decimalAmount = Decimal(string: amount) else {
            showError("Please enter a valid amount")
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                if let existingTransaction = transaction {
                    // Update existing transaction
                    existingTransaction.amount = decimalAmount
                    existingTransaction.transactionDescription = transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    existingTransaction.transactionType = selectedType
                    existingTransaction.category = selectedCategory
                    existingTransaction.date = selectedDate
                    existingTransaction.currency = selectedCurrency
                    existingTransaction.notes = notes.isEmpty ? nil : notes
                    existingTransaction.tags = tags
                    existingTransaction.location = location.isEmpty ? nil : TransactionLocation(address: location)
                    existingTransaction.referenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
                    
                    try await transactionService?.updateTransaction(existingTransaction)
                    
                } else {
                    // Create new transaction
                    let newTransaction = Transaction(
                        amount: decimalAmount,
                        currency: selectedCurrency,
                        transactionDescription: transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                        notes: notes.isEmpty ? nil : notes,
                        date: selectedDate,
                        transactionType: selectedType,
                        category: selectedCategory,
                        source: .manual
                    )
                    
                    newTransaction.tags = tags
                    newTransaction.location = location.isEmpty ? nil : TransactionLocation(address: location)
                    newTransaction.referenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
                    
                    try await transactionService?.createTransaction(newTransaction)
                }
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
    
    private func deleteTransaction() {
        guard let transaction = transaction else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await transactionService?.deleteTransaction(transaction)
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Supporting Views

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .lineLimit(1)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.2))
        )
        .foregroundColor(.accentColor)
    }
}

// MARK: - Preview

@available(iOS 18.6, macOS 15.6, *)
#Preview {
    AddTransactionView()
}