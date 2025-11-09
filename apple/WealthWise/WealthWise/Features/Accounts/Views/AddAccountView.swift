//
//  AddAccountView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Add new account form with validation
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: AccountsViewModel
    
    // Form fields
    @State private var name: String = ""
    @State private var selectedType: Account.AccountType = .bank
    @State private var institution: String = ""
    @State private var initialBalance: String = "0"
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Account Details Section
                Section {
                    TextField(
                        NSLocalizedString("account_name", comment: "Account name"),
                        text: $name
                    )
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    
                    Picker(
                        NSLocalizedString("account_type", comment: "Account type"),
                        selection: $selectedType
                    ) {
                        ForEach(Account.AccountType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: iconForType(type))
                                Text(displayNameForType(type))
                            }
                            .tag(type)
                        }
                    }
                    
                    TextField(
                        NSLocalizedString("institution_name", comment: "Institution name (optional)"),
                        text: $institution
                    )
                    .textContentType(.organizationName)
                    
                } header: {
                    Text(NSLocalizedString("account_details", comment: "Account details"))
                }
                
                // Initial Balance Section
                Section {
                    HStack {
                        Text("₹")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            NSLocalizedString("initial_balance", comment: "Initial balance"),
                            text: $initialBalance
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title3.bold())
                    }
                    
                    if let balance = Decimal(string: initialBalance) {
                        Text(formatCurrency(balance))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                } header: {
                    Text(NSLocalizedString("initial_balance", comment: "Initial balance"))
                } footer: {
                    Text(NSLocalizedString("initial_balance_hint", comment: "Enter the current balance of this account"))
                }
                
                // Account Type Info
                Section {
                    accountTypeInfo
                } header: {
                    Text(NSLocalizedString("about_account_type", comment: "About this account type"))
                }
            }
            .navigationTitle(NSLocalizedString("add_account", comment: "Add Account"))
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
                            await createAccount()
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
                Text(NSLocalizedString("account_created", comment: "Account created successfully"))
            }
        }
    }
    
    // MARK: - Account Type Info View
    
    @ViewBuilder
    private var accountTypeInfo: some View {
        switch selectedType {
        case .bank:
            Label {
                Text(NSLocalizedString("bank_account_info", comment: "Regular savings or current accounts"))
            } icon: {
                Image(systemName: "banknote")
                    .foregroundStyle(.green)
            }
            
        case .creditCard:
            Label {
                Text(NSLocalizedString("credit_card_info", comment: "Credit cards show negative balance for amounts owed"))
            } icon: {
                Image(systemName: "creditcard")
                    .foregroundStyle(.orange)
            }
            
        case .upi:
            Label {
                Text(NSLocalizedString("upi_account_info", comment: "UPI wallets like Google Pay, PhonePe, Paytm"))
            } icon: {
                Image(systemName: "indianrupeesign.circle")
                    .foregroundStyle(.blue)
            }
            
        case .brokerage:
            Label {
                Text(NSLocalizedString("brokerage_account_info", comment: "Investment accounts for stocks, mutual funds"))
            } icon: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.purple)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Decimal(string: initialBalance) != nil
    }
    
    // MARK: - Actions
    
    private func createAccount() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedInstitution = institution.trimmingCharacters(in: .whitespacesAndNewlines)
            let balance = Decimal(string: initialBalance) ?? 0
            
            // Create account through view model
            try await viewModel.createAccount(
                name: trimmedName,
                type: selectedType,
                institution: trimmedInstitution.isEmpty ? nil : trimmedInstitution,
                initialBalance: balance
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
    
    private func iconForType(_ type: Account.AccountType) -> String {
        switch type {
        case .bank: return "banknote"
        case .creditCard: return "creditcard"
        case .upi: return "indianrupeesign.circle"
        case .brokerage: return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func displayNameForType(_ type: Account.AccountType) -> String {
        switch type {
        case .bank:
            return NSLocalizedString("account_type_bank", comment: "Bank Account")
        case .creditCard:
            return NSLocalizedString("account_type_credit_card", comment: "Credit Card")
        case .upi:
            return NSLocalizedString("account_type_upi", comment: "UPI Wallet")
        case .brokerage:
            return NSLocalizedString("account_type_brokerage", comment: "Brokerage Account")
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
#Preview("Add Account") {
    AddAccountView(modelContext: ModelContext(
        try! ModelContainer(
            for: Account.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    ))
}
#endif
