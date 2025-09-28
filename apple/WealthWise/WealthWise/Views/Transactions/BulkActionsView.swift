//
//  BulkActionsView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Transaction Management System: Bulk actions for multiple transactions
//

import SwiftUI

/// Bulk actions sheet for performing operations on multiple transactions
@available(iOS 18.6, macOS 15.6, *)
public struct BulkActionsView: View {
    
    // MARK: - Properties
    
    let selectedTransactions: [Transaction]
    let transactionService: TransactionService?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var showingCategoryPicker = false
    @State private var showingTagsEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Bulk edit states
    @State private var newCategory: TransactionCategory = .other_expense
    @State private var tagsToAdd: String = ""
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            List {
                // Summary Section
                summarySection
                
                // Category Actions
                categoryActionsSection
                
                // Tag Actions
                tagActionsSection
                
                // Delete Actions
                deleteActionsSection
            }
            .navigationTitle("Bulk Actions")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isProcessing)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .confirmationDialog(
                "Delete Transactions",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(selectedTransactions.count) Transactions", role: .destructive) {
                    deleteTransactions()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All selected transactions will be permanently deleted.")
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $newCategory) {
                    updateCategory()
                }
            }
            .sheet(isPresented: $showingTagsEditor) {
                TagsEditorView(tagsToAdd: $tagsToAdd) {
                    addTags()
                }
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    
                    Text("\(selectedTransactions.count) transactions selected")
                        .font(.headline)
                }
                
                // Total amount summary
                let totalAmount = selectedTransactions.reduce(Decimal(0)) { $0 + $1.amount }
                
                Text("Total Amount: \(CurrencyFormatter.shared.format(totalAmount, currency: .INR))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Transaction type breakdown
                let typeBreakdown = Dictionary(grouping: selectedTransactions) { $0.transactionType }
                
                HStack {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        if let count = typeBreakdown[type]?.count, count > 0 {
                            Label("\(count)", systemImage: type.systemImageName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var categoryActionsSection: some View {
        Section("Category Actions") {
            Button {
                showingCategoryPicker = true
            } label: {
                Label("Change Category", systemImage: "folder")
            }
            .disabled(selectedTransactions.isEmpty)
        }
    }
    
    @ViewBuilder
    private var tagActionsSection: some View {
        Section("Tag Actions") {
            Button {
                showingTagsEditor = true
            } label: {
                Label("Add Tags", systemImage: "tag")
            }
            .disabled(selectedTransactions.isEmpty)
        }
    }
    
    @ViewBuilder
    private var deleteActionsSection: some View {
        Section("Delete Actions") {
            Button {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Selected", systemImage: "trash")
            }
            .foregroundColor(.red)
            .disabled(selectedTransactions.isEmpty)
        }
    }
    
    // MARK: - Actions
    
    private func updateCategory() {
        guard !selectedTransactions.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                try await transactionService?.updateCategoryForTransactions(
                    selectedTransactions,
                    category: newCategory
                )
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func addTags() {
        guard !selectedTransactions.isEmpty, !tagsToAdd.isEmpty else { return }
        
        let tags = tagsToAdd
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !tags.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                try await transactionService?.addTagsToTransactions(
                    selectedTransactions,
                    tags: tags
                )
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func deleteTransactions() {
        guard !selectedTransactions.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                try await transactionService?.deleteTransactions(selectedTransactions)
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Supporting Views

@available(iOS 18.6, macOS 15.6, *)
private struct CategoryPickerView: View {
    @Binding var selectedCategory: TransactionCategory
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Label(category.displayName, systemImage: category.systemImageName)
                            
                            Spacer()
                            
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Category")
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
                    Button("Update") {
                        onConfirm()
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 18.6, macOS 15.6, *)
private struct TagsEditorView: View {
    @Binding var tagsToAdd: String
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter tags separated by commas", text: $tagsToAdd, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Add Tags")
                } footer: {
                    Text("Enter multiple tags separated by commas. Example: business, tax-deductible, quarterly")
                }
                
                if !tagsToAdd.isEmpty {
                    Section("Preview") {
                        let tags = tagsToAdd
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.accentColor.opacity(0.2))
                                        )
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Add Tags")
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
                    Button("Add") {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(tagsToAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}