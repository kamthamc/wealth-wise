//
//  CSVImportView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - CSV Import View with Column Mapping
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// CSV import view with column mapping and preview
@available(iOS 18.6, macOS 15.6, *)
struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFileURL: URL?
    @State private var csvData: CSVData?
    @State private var configuration = ImportConfiguration()
    @State private var previews: [ImportedTransactionPreview] = []
    @State private var importJob: ImportJob?
    
    @State private var isLoading = false
    @State private var showingFilePicker = false
    @State private var showingColumnMapping = false
    @State private var showingPreview = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // File Selection Section
                    fileSelectionSection
                    
                    // Column Mapping Section
                    if csvData != nil {
                        columnMappingSection
                    }
                    
                    // Preview Section
                    if !previews.isEmpty {
                        previewSection
                    }
                    
                    // Import Button
                    if !previews.isEmpty {
                        importButtonSection
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("import_button_title", comment: "Import"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .sheet(isPresented: $showingColumnMapping) {
                if let csvData = csvData {
                    ColumnMappingView(
                        headers: csvData.headers,
                        configuration: $configuration
                    )
                }
            }
            .alert(
                NSLocalizedString("general.error", comment: "Error"),
                isPresented: .constant(errorMessage != nil),
                presenting: errorMessage
            ) { _ in
                Button(NSLocalizedString("general.ok", comment: "OK")) {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
        }
    }
    
    // MARK: - View Components
    
    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("import_help_text", comment: "Import help"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(selectedFileURL?.lastPathComponent ?? NSLocalizedString("import_select_file", comment: "Select CSV File"))
                            .font(.headline)
                        if let fileURL = selectedFileURL {
                            Text(fileURL.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var columnMappingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("column_mapping_title", comment: "Column Mapping"))
                    .font(.headline)
                Spacer()
                Button(action: { showingColumnMapping = true }) {
                    Text(NSLocalizedString("general.edit", comment: "Edit"))
                        .font(.subheadline)
                }
            }
            
            Text(NSLocalizedString("column_mapping_help", comment: "Column mapping help"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Show current mappings
            VStack(spacing: 8) {
                ForEach(configuration.mappings.prefix(5)) { mapping in
                    HStack {
                        Text(mapping.sourceColumn)
                            .font(.subheadline)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(mapping.targetField.displayName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button(action: loadPreview) {
                Label(
                    NSLocalizedString("preview_button_title", comment: "Preview"),
                    systemImage: "eye"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("import_preview_title", comment: "Import Preview"))
                .font(.headline)
            
            // Summary
            HStack(spacing: 20) {
                VStack {
                    Text("\(previews.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(NSLocalizedString("import_total_records", comment: "Total"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(previews.filter { $0.validationResult.isValid && !$0.validationResult.isDuplicate }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text(NSLocalizedString("import_valid_records", comment: "Valid"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(previews.filter { $0.validationResult.isDuplicate }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text(NSLocalizedString("import_duplicate_records", comment: "Duplicates"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(previews.filter { !$0.validationResult.isValid }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text(NSLocalizedString("import_invalid_records", comment: "Errors"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Preview list
            VStack(spacing: 8) {
                ForEach(previews.prefix(10)) { preview in
                    TransactionPreviewRow(preview: preview)
                }
            }
        }
    }
    
    private var importButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: performImport) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(NSLocalizedString("import_button_title", comment: "Import"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || previews.filter { $0.validationResult.isValid && !$0.validationResult.isDuplicate }.isEmpty)
            
            if let job = importJob, job.isComplete {
                ImportResultView(job: job)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url
            Task {
                await parseCSVFile(url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func parseCSVFile(_ url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let parser = CSVParser()
            csvData = try await parser.parse(fileURL: url)
            
            // Auto-detect column mappings
            if let csvData = csvData {
                configuration.mappings = csvData.headers.compactMap { header in
                    ColumnMapping.detectMapping(for: header)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadPreview() {
        guard let csvData = csvData else { return }
        
        isLoading = true
        Task {
            defer { isLoading = false }
            
            do {
                let importer = TransactionImporter(modelContext: modelContext, configuration: configuration)
                previews = try await importer.preview(csvData: csvData)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func performImport() {
        guard let csvData = csvData else { return }
        
        isLoading = true
        Task {
            defer { isLoading = false }
            
            do {
                let job = ImportJob(
                    filename: selectedFileURL?.lastPathComponent ?? "import.csv",
                    sourceType: .csv,
                    totalRecords: csvData.rowCount
                )
                modelContext.insert(job)
                importJob = job
                
                let importer = TransactionImporter(modelContext: modelContext, configuration: configuration)
                _ = try await importer.importTransactions(csvData: csvData, importJob: job)
                
                // Dismiss after successful import
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Transaction Preview Row

struct TransactionPreviewRow: View {
    let preview: ImportedTransactionPreview
    
    var body: some View {
        HStack {
            // Status indicator
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(preview.description)
                    .font(.subheadline)
                HStack {
                    Text(preview.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let category = preview.category {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(preview.amount, format: .currency(code: "INR"))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        if preview.validationResult.isDuplicate {
            return "doc.on.doc.fill"
        } else if !preview.validationResult.isValid {
            return "exclamationmark.triangle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if preview.validationResult.isDuplicate {
            return .orange
        } else if !preview.validationResult.isValid {
            return .red
        } else {
            return .green
        }
    }
    
    private var backgroundColor: Color {
        if preview.validationResult.isDuplicate {
            return Color.orange.opacity(0.1)
        } else if !preview.validationResult.isValid {
            return Color.red.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
}

// MARK: - Import Result View

struct ImportResultView: View {
    let job: ImportJob
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: job.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(job.status == .completed ? .green : .red)
                Text(job.status.displayName)
                    .fontWeight(.medium)
            }
            
            if job.status == .completed {
                Text(String(format: NSLocalizedString("import_success_message", comment: "Successfully imported %d transactions"), job.successfulRecords))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    CSVImportView()
        .modelContainer(for: [Transaction.self, ImportJob.self])
}
