//
//  FilterSheetView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Transaction Management System: Filter sheet for transaction list
//

import SwiftUI

/// Filter sheet for filtering transactions by various criteria
@available(iOS 18.6, macOS 15.6, *)
public struct FilterSheetView: View {
    
    // MARK: - Bindings
    
    @Binding var selectedType: TransactionType?
    @Binding var selectedCategory: TransactionCategory?
    @Binding var dateRange: DateInterval?
    @Binding var amountRange: ClosedRange<Decimal>?
    @Binding var selectedCurrency: String?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var enableDateFilter: Bool = false
    @State private var enableAmountFilter: Bool = false
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            Form {
                // Transaction Type Filter
                typeFilterSection
                
                // Category Filter
                categoryFilterSection
                
                // Date Range Filter
                dateFilterSection
                
                // Amount Range Filter
                amountFilterSection
                
                // Currency Filter
                currencyFilterSection
                
                // Reset Section
                resetSection
            }
            .navigationTitle("Filter Transactions")
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
                    Button("Apply") {
                        applyFilters()
                    }
                }
            }
        }
        .onAppear {
            setupFilters()
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var typeFilterSection: some View {
        Section("Transaction Type") {
            Picker("Type", selection: $selectedType) {
                Text("All Types")
                    .tag(nil as TransactionType?)
                
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.systemImageName)
                        .tag(type as TransactionType?)
                }
            }
            #if os(macOS)
            .pickerStyle(.menu)
            #else
            .pickerStyle(.wheel)
            .frame(height: 120)
            #endif
        }
    }
    
    @ViewBuilder
    private var categoryFilterSection: some View {
        Section("Category") {
            Picker("Category", selection: $selectedCategory) {
                Text("All Categories")
                    .tag(nil as TransactionCategory?)
                
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.systemImageName)
                        .tag(category as TransactionCategory?)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    @ViewBuilder
    private var dateFilterSection: some View {
        Section("Date Range") {
            Toggle("Enable date filter", isOn: $enableDateFilter)
            
            if enableDateFilter {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, displayedComponents: .date)
                
                // Quick date range buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Ranges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        quickDateButton("Last Week") {
                            setDateRange(days: -7)
                        }
                        
                        quickDateButton("Last Month") {
                            setDateRange(months: -1)
                        }
                        
                        quickDateButton("Last 3 Months") {
                            setDateRange(months: -3)
                        }
                        
                        quickDateButton("This Year") {
                            setDateRangeToCurrentYear()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var amountFilterSection: some View {
        Section("Amount Range") {
            Toggle("Enable amount filter", isOn: $enableAmountFilter)
            
            if enableAmountFilter {
                HStack {
                    TextField("Min", text: $minAmount)
                        #if !os(macOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .textFieldStyle(.roundedBorder)
                    
                    Text("to")
                        .foregroundColor(.secondary)
                    
                    TextField("Max", text: $maxAmount)
                        #if !os(macOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .textFieldStyle(.roundedBorder)
                }
                
                // Quick amount buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Ranges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        quickAmountButton("< ₹1,000") {
                            setAmountRange(min: 0, max: 1000)
                        }
                        
                        quickAmountButton("₹1K - ₹10K") {
                            setAmountRange(min: 1000, max: 10000)
                        }
                        
                        quickAmountButton("₹10K - ₹50K") {
                            setAmountRange(min: 10000, max: 50000)
                        }
                        
                        quickAmountButton("> ₹50K") {
                            setAmountRange(min: 50000, max: nil)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var currencyFilterSection: some View {
        Section("Currency") {
            Picker("Currency", selection: $selectedCurrency) {
                Text("All Currencies")
                    .tag(nil as String?)
                
                ForEach(SupportedCurrency.allCases, id: \.self) { currency in
                    Text("\(currency.rawValue) - \(currency.displayName)")
                        .tag(currency.rawValue as String?)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button("Reset All Filters") {
                resetFilters()
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func quickDateButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(8)
    }
    
    private func quickAmountButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(8)
    }
    
    private func setDateRange(days: Int = 0, months: Int = 0) {
        let calendar = Calendar.current
        let now = Date()
        
        if days != 0 {
            startDate = calendar.date(byAdding: .day, value: days, to: now) ?? now
        } else if months != 0 {
            startDate = calendar.date(byAdding: .month, value: months, to: now) ?? now
        }
        
        endDate = now
        enableDateFilter = true
    }
    
    private func setDateRangeToCurrentYear() {
        let calendar = Calendar.current
        let now = Date()
        
        startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        endDate = now
        enableDateFilter = true
    }
    
    private func setAmountRange(min: Decimal, max: Decimal?) {
        minAmount = String(describing: min)
        maxAmount = max != nil ? String(describing: max!) : ""
        enableAmountFilter = true
    }
    
    private func setupFilters() {
        // Initialize filter states based on current selections
        enableDateFilter = dateRange != nil
        enableAmountFilter = amountRange != nil
        
        if let range = dateRange {
            startDate = range.start
            endDate = range.end
        }
        
        if let range = amountRange {
            minAmount = String(describing: range.lowerBound)
            maxAmount = String(describing: range.upperBound)
        }
    }
    
    private func applyFilters() {
        // Apply date filter
        if enableDateFilter {
            dateRange = DateInterval(start: startDate, end: endDate)
        } else {
            dateRange = nil
        }
        
        // Apply amount filter
        if enableAmountFilter {
            let min = Decimal(string: minAmount) ?? 0
            let max = Decimal(string: maxAmount) ?? Decimal.greatestFiniteMagnitude
            amountRange = min...max
        } else {
            amountRange = nil
        }
        
        dismiss()
    }
    
    private func resetFilters() {
        selectedType = nil
        selectedCategory = nil
        dateRange = nil
        amountRange = nil
        selectedCurrency = nil
        
        enableDateFilter = false
        enableAmountFilter = false
        minAmount = ""
        maxAmount = ""
        
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
    }
}