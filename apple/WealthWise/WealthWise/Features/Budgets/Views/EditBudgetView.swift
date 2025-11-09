//
//  EditBudgetView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Edit existing budget with category management and delete functionality
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: BudgetsViewModel
    
    let budget: Budget
    
    // Form fields
    @State private var name: String
    @State private var amount: String
    @State private var selectedPeriod: Budget.BudgetPeriod
    @State private var selectedCategories: Set<String>
    @State private var startDate: Date
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var showCategorySheet = false
    
    init(budget: Budget, modelContext: ModelContext) {
        self.budget = budget
        _viewModel = StateObject(wrappedValue: BudgetsViewModel(modelContext: modelContext))
        
        // Initialize state from budget
        _name = State(initialValue: budget.name)
        _amount = State(initialValue: budget.amount.description)
        _selectedPeriod = State(initialValue: budget.period)
        _selectedCategories = State(initialValue: Set(budget.categories))
        _startDate = State(initialValue: budget.startDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Budget Details Section
                Section {
                    TextField("Budget name", text: $name)
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(Budget.BudgetPeriod.allCases, id: \.self) { period in
                            Text(displayNameForPeriod(period))
                                .tag(period)
                        }
                    }
                    
                    DatePicker(
                        "Start date",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    
                } header: {
                    Text("Budget Details")
                }
                
                // Amount Section
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        TextField("Budget amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2.bold())
                    }
                    
                    if let amountValue = Decimal(string: amount) {
                        Text(formatCurrency(amountValue))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                } header: {
                    Text("Budget Amount")
                }
                
                // Current Spending Section
                Section {
                    HStack {
                        Text("Spent")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatCurrency(budget.currentSpent))
                            .font(.headline)
                            .foregroundStyle(budget.isOverBudget ? .red : .primary)
                    }
                    
                    HStack {
                        Text("Remaining")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatCurrency(budget.remaining))
                            .font(.headline)
                            .foregroundStyle(budget.remaining >= 0 ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(budget.progressPercentage))%")
                                .font(.caption.bold())
                                .foregroundStyle(budget.isOverBudget ? .red : .blue)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 8)
                                    .clipShape(Capsule())
                                
                                Rectangle()
                                    .fill(budget.isOverBudget ? Color.red : Color.blue)
                                    .frame(
                                        width: geometry.size.width * CGFloat(min(budget.progressPercentage / 100, 1.0)),
                                        height: 8
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 8)
                    }
                    
                } header: {
                    Text("Current Status")
                }
                
                // Categories Section
                Section {
                    Button {
                        showCategorySheet = true
                    } label: {
                        HStack {
                            Text("Select Categories")
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
                    Text("Categories")
                }
                
                // Budget Info
                Section {
                    LabeledContent {
                        Text(budget.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Created", systemImage: "calendar.badge.plus")
                    }
                    
                    LabeledContent {
                        Text(budget.updatedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Last Updated", systemImage: "clock")
                    }
                    
                    LabeledContent {
                        Text(budget.endDate, style: .date)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("End Date", systemImage: "calendar.badge.clock")
                    }
                } header: {
                    Text("Information")
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Budget", systemImage: "trash")
                    }
                } footer: {
                    Text("Deleting this budget will permanently remove it from your records. This action cannot be undone.")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Edit Budget")
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
                            await updateBudget()
                        }
                    }
                    .disabled(!isFormValid || isLoading || !hasChanges)
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
            .confirmationDialog(
                "Delete Budget",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteBudget()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this budget? This action cannot be undone.")
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
                Text("Budget updated successfully")
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
            .navigationTitle("Select Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
    
    private var hasChanges: Bool {
        guard let amountValue = Decimal(string: amount) else { return false }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedName != budget.name ||
               amountValue != budget.amount ||
               selectedPeriod != budget.period ||
               selectedCategories != Set(budget.categories) ||
               startDate != budget.startDate
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func updateBudget() async {
        guard isFormValid, hasChanges,
              let amountValue = Decimal(string: amount) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Update budget properties
            budget.name = trimmedName
            budget.amount = amountValue
            budget.period = selectedPeriod
            budget.categories = Array(selectedCategories)
            budget.startDate = startDate
            
            // Recalculate end date based on new period and start date
            let calendar = Calendar.current
            switch selectedPeriod {
            case .monthly:
                budget.endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
            case .quarterly:
                budget.endDate = calendar.date(byAdding: .month, value: 3, to: startDate)!
            case .yearly:
                budget.endDate = calendar.date(byAdding: .year, value: 1, to: startDate)!
            }
            
            budget.updatedAt = Date()
            
            // Save through repository
            try await viewModel.updateBudget(budget)
            
            isLoading = false
            showSuccess = true
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteBudget() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await viewModel.deleteBudget(budget)
            isLoading = false
            dismiss()
            
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
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Groceries": return "cart"
        case "Rent": return "house"
        case "Transport": return "car"
        case "Healthcare": return "cross.case"
        case "Entertainment": return "tv"
        case "Shopping": return "bag"
        case "Food & Dining": return "fork.knife"
        default: return "tag"
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
#Preview("Edit Budget") {
    let container = try! ModelContainer(
        for: Budget.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let budget = Budget(
        userId: "preview",
        name: "Monthly Expenses",
        amount: 50000,
        period: .monthly,
        categories: ["Groceries", "Transport", "Food & Dining"]
    )
    container.mainContext.insert(budget)
    
    return EditBudgetView(
        budget: budget,
        modelContext: container.mainContext
    )
}
#endif
