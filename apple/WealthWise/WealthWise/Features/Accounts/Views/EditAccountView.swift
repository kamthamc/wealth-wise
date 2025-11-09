//
//  EditAccountView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Edit existing account form with archive functionality
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: AccountsViewModel
    
    let account: Account
    
    // Form fields
    @State private var name: String
    @State private var selectedType: Account.AccountType
    @State private var institution: String
    @State private var isArchived: Bool
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var showArchiveConfirmation = false
    
    init(account: Account, modelContext: ModelContext) {
        self.account = account
        _viewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: modelContext))
        
        // Initialize state from account
        _name = State(initialValue: account.name)
        _selectedType = State(initialValue: account.type)
        _institution = State(initialValue: account.institution ?? "")
        _isArchived = State(initialValue: account.isArchived)
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
                
                // Current Balance Section (Read-only)
                Section {
                    HStack {
                        Text(NSLocalizedString("current_balance", comment: "Current Balance"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatCurrency(account.currentBalance))
                            .font(.title3.bold())
                            .foregroundStyle(account.currentBalance >= 0 ? .primary : .red)
                    }
                    
                    Text(NSLocalizedString("balance_calculated_hint", comment: "Balance is calculated from transactions"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                } header: {
                    Text(NSLocalizedString("balance", comment: "Balance"))
                }
                
                // Account Status Section
                Section {
                    Toggle(isOn: $isArchived) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("archived", comment: "Archived"))
                                Text(NSLocalizedString("archived_hint", comment: "Archived accounts are hidden from main views"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: isArchived ? "archivebox.fill" : "archivebox")
                                .foregroundStyle(isArchived ? .orange : .secondary)
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("status", comment: "Status"))
                }
                
                // Account Info Section
                Section {
                    LabeledContent {
                        Text(account.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label {
                            Text(NSLocalizedString("created_date", comment: "Created"))
                        } icon: {
                            Image(systemName: "calendar.badge.plus")
                        }
                    }
                    
                    LabeledContent {
                        Text(account.updatedAt, style: .date)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label {
                            Text(NSLocalizedString("last_updated", comment: "Last Updated"))
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("information", comment: "Information"))
                }
                
                // Danger Zone Section
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label {
                            Text(NSLocalizedString("delete_account", comment: "Delete Account"))
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("danger_zone", comment: "Danger Zone"))
                } footer: {
                    Text(NSLocalizedString("delete_account_warning", comment: "Deleting this account will also delete all associated transactions. This action cannot be undone."))
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(NSLocalizedString("edit_account", comment: "Edit Account"))
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
                            await updateAccount()
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
                NSLocalizedString("delete_account", comment: "Delete Account"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(NSLocalizedString("delete", comment: "Delete"), role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("delete_account_confirmation", comment: "Are you sure you want to delete this account and all its transactions? This action cannot be undone."))
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
                Text(NSLocalizedString("account_updated", comment: "Account updated successfully"))
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasChanges: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstitution = institution.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedName != account.name ||
               selectedType != account.type ||
               trimmedInstitution != (account.institution ?? "") ||
               isArchived != account.isArchived
    }
    
    // MARK: - Actions
    
    private func updateAccount() async {
        guard isFormValid && hasChanges else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedInstitution = institution.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Update account properties
            account.name = trimmedName
            account.type = selectedType
            account.institution = trimmedInstitution.isEmpty ? nil : trimmedInstitution
            account.isArchived = isArchived
            account.updatedAt = Date()
            
            // Save through repository
            try await viewModel.updateAccount(account)
            
            isLoading = false
            showSuccess = true
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteAccount() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await viewModel.deleteAccount(account)
            isLoading = false
            dismiss()
            
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
#Preview("Edit Account") {
    let container = try! ModelContainer(
        for: Account.self,
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
    
    return EditAccountView(
        account: account,
        modelContext: container.mainContext
    )
}
#endif
