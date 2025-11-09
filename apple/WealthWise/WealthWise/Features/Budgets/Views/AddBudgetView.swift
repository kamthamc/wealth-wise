//
//  AddBudgetView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Add new budget form with period selection and category multi-select
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: BudgetsViewModel
    
    // Form fields
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedPeriod: Budget.BudgetPeriod = .monthly
    @State private var selectedCategories: Set<String> = []
    @State private var startDate: Date = Date()
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showCategorySheet = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: BudgetsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Budget Details Section
                Section {
                    TextField(
                        NSLocalizedString("budget_name", comment: "Budget name"),
                        text: $name
                    )
                    .textInputAutocapitalization(.words)
                    
                    Picker(
                        NSLocalizedString("period", comment: "Period"),
                        selection: $selectedPeriod
                    ) {
                        ForEach(Budget.BudgetPeriod.allCases, id: \.self) { period in
                            Text(displayNameForPeriod(period))
                                .tag(period)
                        }
                    }
                    
                    DatePicker(
                        NSLocalizedString("start_date", comment: "Start date"),
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    
                } header: {
                    Text(NSLocalizedString("budget_details", comment: "Budget Details"))
                }
                
                // Amount Section
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            NSLocalizedString("budget_amount", comment: "Budget amount"),
                            text: $amount
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title2.bold())
                    }
                    
                    if let amountValue = Decimal(string: amount) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatCurrency(amountValue))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(periodBreakdown(amount: amountValue))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("budget_amount", comment: "Budget Amount"))
                } footer: {
                    Text(NSLocalizedString("budget_amount_hint", comment: "Total amount you want to spend in this budget"))
                }
                
                // Categories Section
                Section {
                    Button {
                        showCategorySheet = true
                    } label: {
                        HStack {
                            Text(NSLocalizedString("select_categories", comment: "Select Categories"))
                            Spacer()
                            Text("\(selectedCategories.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    if !selectedCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(selectedCategories).sorted(), id: \.self) { category in
                                    categoryChip(category)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("categories", comment: "Categories"))
                } footer: {
                    Text(NSLocalizedString("budget_categories_hint", comment: "Select expense categories to track in this budget"))
                }
                
                // Budget Preview Section
                if !selectedCategories.isEmpty && Decimal(string: amount) != nil {
                    Section {
                        budgetPreview
                    } header: {
                        Text(NSLocalizedString("budget_preview", comment: "Budget Preview"))
                    }
                }
            }
            .navigationTitle(NSLocalizedString("add_budget", comment: "Add Budget"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("create", comment: "Create")) {
                        Task {
                            await createBudget()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .sheet(isPresented: $showCategorySheet) {
                categorySelectionSheet
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
                Text(NSLocalizedString("budget_created", comment: "Budget created successfully"))
            }
        }
    }
    
    // MARK: - Category Chip
    
    @ViewBuilder
    private func categoryChip(_ category: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconForCategory(category))
                .font(.caption2)
            Text(category)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Budget Preview
    
    @ViewBuilder
    private var budgetPreview: some View {
        if let amountValue = Decimal(string: amount) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("total_budget", comment: "Total Budget"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(amountValue))
                            .font(.title3.bold())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(displayNameForPeriod(selectedPeriod))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(selectedCategories.count) categories")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("tracking", comment: "Tracking"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    ForEach(Array(selectedCategories).sorted().prefix(5), id: \.self) { category in
                        HStack {
                            Image(systemName: iconForCategory(category))
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text(category)
                                .font(.caption)
                        }
                    }
                    
                    if selectedCategories.count > 5 {
                        Text("+\(selectedCategories.count - 5) more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Category Selection Sheet
    
    @ViewBuilder
    private var categorySelectionSheet: some View {
        NavigationStack {
            List {
                ForEach(expenseCategories.sorted(), id: \.self) { category in
                    Button {
                        toggleCategory(category)
                    } label: {
                        HStack {
                            Image(systemName: iconForCategory(category))
                                .foregroundStyle(.red)
                            Text(category)
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("select_categories", comment: "Select Categories"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("done", comment: "Done")) {
                        showCategorySheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Decimal(string: amount) != nil &&
        !selectedCategories.isEmpty
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func createBudget() async {
        guard isFormValid,
              let amountValue = Decimal(string: amount) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await viewModel.createBudget(
                name: trimmedName,
                amount: amountValue,
                period: selectedPeriod,
                categories: Array(selectedCategories),
                startDate: startDate
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
    
    private var expenseCategories: [String] {
        WebAppTransaction.defaultCategories
            .filter { $0.value == .expense || $0.value == .investment }
            .map { $0.key }
    }
    
    private func displayNameForPeriod(_ period: Budget.BudgetPeriod) -> String {
        switch period {
        case .monthly:
            return NSLocalizedString("budget_period_monthly", comment: "Monthly")
        case .quarterly:
            return NSLocalizedString("budget_period_quarterly", comment: "Quarterly")
        case .yearly:
            return NSLocalizedString("budget_period_yearly", comment: "Yearly")
        }
    }
    
    private func periodBreakdown(amount: Decimal) -> String {
        let daily = amount / 30
        let weekly = amount / 4
        
        switch selectedPeriod {
        case .monthly:
            return "≈ \(formatCurrency(weekly))/week · \(formatCurrency(daily))/day"
        case .quarterly:
            let monthly = amount / 3
            return "≈ \(formatCurrency(monthly))/month"
        case .yearly:
            let monthly = amount / 12
            return "≈ \(formatCurrency(monthly))/month"
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
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
#Preview("Add Budget") {
    AddBudgetView(modelContext: ModelContext(
        try! ModelContainer(
            for: Budget.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    ))
}
#endif
