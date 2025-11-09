//
//  AdvancedFilterView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Advanced transaction filtering interface
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AdvancedFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Binding var filter: TransactionFilter
    @StateObject private var accountsViewModel: AccountsViewModel
    
    @State private var showingSaveFilterSheet = false
    @State private var showingLoadFilterSheet = false
    @State private var filterName = ""
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var minAmount: Decimal = 0
    @State private var maxAmount: Decimal = 100000
    @State private var useAmountFilter = false
    
    @Query private var savedFilters: [SavedFilter]
    
    // Computed property for adaptive layout
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
    
    private var gridColumns: [GridItem] {
        if isCompactLayout {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else {
            // iPad: 3-4 columns for better space usage
            return Array(repeating: GridItem(.flexible()), count: 4)
        }
    }
    
    private let allCategories: [String] = [
        "Food & Dining", "Transportation", "Shopping", "Entertainment",
        "Bills & Utilities", "Healthcare", "Education", "Travel",
        "Personal Care", "Insurance", "Investments", "Savings",
        "Gifts & Donations", "Home & Garden", "Pets", "Subscriptions",
        "Groceries", "Fuel", "Parking", "Public Transport",
        "Clothing", "Electronics", "Books", "Sports",
        "Movies & Shows", "Gaming", "Internet", "Phone",
        "Rent", "Maintenance", "Other"
    ]
    
    init(filter: Binding<TransactionFilter>) {
        self._filter = filter
        let context = ModelContext(ModelContainer.shared)
        self._accountsViewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Date Range
                dateRangeSection
                
                // Amount Range
                amountRangeSection
                
                // Categories
                categoriesSection
                
                // Accounts
                accountsSection
                
                // Transaction Types
                transactionTypesSection
                
                // Search
                searchSection
                
                // Saved Filters
                savedFiltersSection
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            resetFilter()
                        } label: {
                            Label("Reset All", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button {
                            showingSaveFilterSheet = true
                        } label: {
                            Label("Save Filter", systemImage: "bookmark")
                        }
                        .disabled(!filter.isActive)
                        
                        Button {
                            showingLoadFilterSheet = true
                        } label: {
                            Label("Load Filter", systemImage: "folder")
                        }
                        .disabled(savedFilters.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSaveFilterSheet) {
                saveFilterSheet
            }
            .sheet(isPresented: $showingLoadFilterSheet) {
                loadFilterSheet
            }
            .task {
                await accountsViewModel.loadAccounts()
            }
        }
    }
    
    // MARK: - Date Range Section
    
    @ViewBuilder
    private var dateRangeSection: some View {
        Section {
            Picker("Date Range", selection: $filter.dateRange) {
                ForEach(TransactionFilter.DateRangeFilter.allCases, id: \.displayName) { range in
                    Text(range.displayName).tag(range)
                }
            }
            
            if case .custom = filter.dateRange {
                DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                    .onChange(of: customStartDate) { _, newValue in
                        filter.dateRange = .custom(start: newValue, end: customEndDate)
                    }
                    .onChange(of: customEndDate) { _, newValue in
                        filter.dateRange = .custom(start: customStartDate, end: newValue)
                    }
            }
        } header: {
            HStack {
                Image(systemName: "calendar")
                Text("Date Range")
            }
        }
    }
    
    // MARK: - Amount Range Section
    
    @ViewBuilder
    private var amountRangeSection: some View {
        Section {
            Toggle("Filter by Amount", isOn: $useAmountFilter)
                .onChange(of: useAmountFilter) { _, newValue in
                    if newValue {
                        filter.amountRange = TransactionFilter.AmountRangeFilter(
                            minimum: minAmount,
                            maximum: maxAmount
                        )
                    } else {
                        filter.amountRange = nil
                    }
                }
            
            if useAmountFilter {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Min: \(formatCurrency(minAmount))")
                            .font(.subheadline)
                        Spacer()
                        Text("Max: \(formatCurrency(maxAmount))")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { Double(truncating: minAmount as NSNumber) },
                                set: { minAmount = Decimal($0) }
                            ),
                            in: 0...Double(truncating: maxAmount as NSNumber),
                            step: 100
                        )
                        .onChange(of: minAmount) { _, _ in
                            updateAmountFilter()
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(truncating: maxAmount as NSNumber) },
                                set: { maxAmount = Decimal($0) }
                            ),
                            in: Double(truncating: minAmount as NSNumber)...1000000,
                            step: 100
                        )
                        .onChange(of: maxAmount) { _, _ in
                            updateAmountFilter()
                        }
                    }
                }
            }
        } header: {
            HStack {
                Image(systemName: "indianrupeesign.circle")
                Text("Amount Range")
            }
        } footer: {
            if useAmountFilter {
                Text("Show transactions between \(formatCurrency(minAmount)) and \(formatCurrency(maxAmount))")
            }
        }
    }
    
    // MARK: - Categories Section
    
    @ViewBuilder
    private var categoriesSection: some View {
        Section {
            if filter.categories.isEmpty {
                Text("All Categories")
                    .foregroundStyle(.secondary)
            } else {
                Text("\(filter.categories.count) categories selected")
                    .foregroundStyle(.secondary)
            }
            
            ForEach(allCategories, id: \.self) { category in
                Button {
                    toggleCategory(category)
                } label: {
                    HStack {
                        Image(systemName: categoryIcon(for: category))
                            .foregroundStyle(categoryColor(for: category))
                            .frame(width: 30)
                        
                        Text(category)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if filter.categories.contains(category) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            if !filter.categories.isEmpty {
                Button("Clear Selection", role: .destructive) {
                    filter.categories.removeAll()
                }
            }
        } header: {
            HStack {
                Image(systemName: "tag")
                Text("Categories")
            }
        }
    }
    
    // MARK: - Accounts Section
    
    @ViewBuilder
    private var accountsSection: some View {
        Section {
            if accountsViewModel.accounts.isEmpty {
                Text("No accounts available")
                    .foregroundStyle(.secondary)
            } else if filter.accountIds.isEmpty {
                Text("All Accounts")
                    .foregroundStyle(.secondary)
            } else {
                Text("\(filter.accountIds.count) accounts selected")
                    .foregroundStyle(.secondary)
            }
            
            ForEach(accountsViewModel.accounts) { account in
                Button {
                    toggleAccount(account.id)
                } label: {
                    HStack {
                        Circle()
                            .fill(accountGradient(for: account.type))
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image(systemName: accountIcon(for: account.type))
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .foregroundStyle(.primary)
                            if let institution = account.institution {
                                Text(institution)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if filter.accountIds.contains(account.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            if !filter.accountIds.isEmpty {
                Button("Clear Selection", role: .destructive) {
                    filter.accountIds.removeAll()
                }
            }
        } header: {
            HStack {
                Image(systemName: "building.columns")
                Text("Accounts")
            }
        }
    }
    
    // MARK: - Transaction Types Section
    
    @ViewBuilder
    private var transactionTypesSection: some View {
        Section {
            if filter.transactionTypes.isEmpty {
                Text("All Types")
                    .foregroundStyle(.secondary)
            } else {
                Text("\(filter.transactionTypes.count) types selected")
                    .foregroundStyle(.secondary)
            }
            
            ForEach([WebAppTransaction.TransactionType.debit, .credit], id: \.self) { type in
                Button {
                    toggleTransactionType(type)
                } label: {
                    HStack {
                        Image(systemName: type == .debit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundStyle(type == .debit ? .red : .green)
                            .frame(width: 30)
                        
                        Text(type == .debit ? "Expense" : "Income")
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if filter.transactionTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            if !filter.transactionTypes.isEmpty {
                Button("Clear Selection", role: .destructive) {
                    filter.transactionTypes.removeAll()
                }
            }
        } header: {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                Text("Transaction Type")
            }
        }
    }
    
    // MARK: - Search Section
    
    @ViewBuilder
    private var searchSection: some View {
        Section {
            TextField("Search description, category, notes...", text: $filter.searchText)
                .autocorrectionDisabled()
        } header: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
        }
    }
    
    // MARK: - Saved Filters Section
    
    @ViewBuilder
    private var savedFiltersSection: some View {
        Section {
            if savedFilters.isEmpty {
                Text("No saved filters")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(savedFilters) { savedFilter in
                    Button {
                        loadSavedFilter(savedFilter)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(savedFilter.name)
                                    .foregroundStyle(.primary)
                                Text("Updated \(savedFilter.updatedAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteSavedFilters)
            }
        } header: {
            HStack {
                Image(systemName: "bookmark.fill")
                Text("Saved Filters")
            }
        }
    }
    
    // MARK: - Save Filter Sheet
    
    @ViewBuilder
    private var saveFilterSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Filter Name", text: $filterName)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give this filter a memorable name")
                }
            }
            .navigationTitle("Save Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSaveFilterSheet = false
                        filterName = ""
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveCurrentFilter()
                    }
                    .disabled(filterName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Load Filter Sheet
    
    @ViewBuilder
    private var loadFilterSheet: some View {
        NavigationStack {
            List {
                ForEach(savedFilters) { savedFilter in
                    Button {
                        loadSavedFilter(savedFilter)
                        showingLoadFilterSheet = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(savedFilter.name)
                                .font(.headline)
                            
                            if let filter = savedFilter.filter {
                                Text(filterSummary(filter))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Updated \(savedFilter.updatedAt, style: .relative)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteSavedFilters)
            }
            .navigationTitle("Load Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingLoadFilterSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleCategory(_ category: String) {
        if filter.categories.contains(category) {
            filter.categories.remove(category)
        } else {
            filter.categories.insert(category)
        }
    }
    
    private func toggleAccount(_ accountId: UUID) {
        if filter.accountIds.contains(accountId) {
            filter.accountIds.remove(accountId)
        } else {
            filter.accountIds.insert(accountId)
        }
    }
    
    private func toggleTransactionType(_ type: WebAppTransaction.TransactionType) {
        if filter.transactionTypes.contains(type) {
            filter.transactionTypes.remove(type)
        } else {
            filter.transactionTypes.insert(type)
        }
    }
    
    private func updateAmountFilter() {
        guard useAmountFilter else { return }
        filter.amountRange = TransactionFilter.AmountRangeFilter(
            minimum: minAmount,
            maximum: maxAmount
        )
    }
    
    private func resetFilter() {
        filter.reset()
        useAmountFilter = false
        minAmount = 0
        maxAmount = 100000
        customStartDate = Date()
        customEndDate = Date()
    }
    
    private func saveCurrentFilter() {
        let savedFilter = SavedFilter(name: filterName, filter: filter)
        modelContext.insert(savedFilter)
        try? modelContext.save()
        
        showingSaveFilterSheet = false
        filterName = ""
    }
    
    private func loadSavedFilter(_ savedFilter: SavedFilter) {
        guard let loadedFilter = savedFilter.filter else { return }
        filter = loadedFilter
        
        // Update UI state
        if let amountRange = loadedFilter.amountRange {
            useAmountFilter = true
            minAmount = amountRange.minimum
            maxAmount = amountRange.maximum
        }
        
        if case .custom(let start, let end) = loadedFilter.dateRange {
            customStartDate = start
            customEndDate = end
        }
    }
    
    private func deleteSavedFilters(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedFilters[index])
        }
        try? modelContext.save()
    }
    
    private func filterSummary(_ filter: TransactionFilter) -> String {
        var parts: [String] = []
        
        if filter.dateRange != .all {
            parts.append(filter.dateRange.displayName)
        }
        
        if !filter.categories.isEmpty {
            parts.append("\(filter.categories.count) categories")
        }
        
        if !filter.accountIds.isEmpty {
            parts.append("\(filter.accountIds.count) accounts")
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Food & Dining", "Groceries": return "fork.knife"
        case "Transportation", "Fuel", "Parking": return "car.fill"
        case "Shopping", "Clothing": return "bag.fill"
        case "Entertainment", "Movies & Shows": return "tv.fill"
        case "Bills & Utilities", "Internet", "Phone": return "doc.text.fill"
        case "Healthcare": return "cross.fill"
        case "Education", "Books": return "book.fill"
        case "Travel": return "airplane"
        case "Insurance": return "shield.fill"
        case "Investments", "Savings": return "chart.line.uptrend.xyaxis"
        case "Gifts & Donations": return "gift.fill"
        default: return "tag.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Food & Dining", "Groceries": return .orange
        case "Transportation", "Fuel": return .blue
        case "Shopping", "Clothing": return .purple
        case "Entertainment": return .pink
        case "Bills & Utilities": return .red
        case "Healthcare": return .green
        case "Education": return .indigo
        case "Travel": return .cyan
        default: return .gray
        }
    }
    
    private func accountIcon(for type: String) -> String {
        switch type.lowercased() {
        case "bank": return "building.columns.fill"
        case "credit card": return "creditcard.fill"
        case "upi": return "indianrupeesign.circle.fill"
        case "brokerage": return "chart.line.uptrend.xyaxis"
        default: return "wallet.pass.fill"
        }
    }
    
    private func accountGradient(for type: String) -> LinearGradient {
        switch type.lowercased() {
        case "bank":
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "credit card":
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "upi":
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "brokerage":
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
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
#Preview("Advanced Filter") {
    AdvancedFilterView(filter: .constant(TransactionFilter()))
}
#endif
