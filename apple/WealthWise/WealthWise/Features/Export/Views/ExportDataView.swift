//
//  ExportDataView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  UI for exporting transaction data to CSV and PDF
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var transactionsViewModel: TransactionsViewModel
    @StateObject private var accountsViewModel: AccountsViewModel
    
    @State private var exportFormat: ExportFormat = .csv
    @State private var reportType: DataExportService.ReportType = .monthly(Date())
    @State private var selectedColumns: Set<DataExportService.CSVColumn> = Set(DataExportService.CSVColumn.allCases)
    @State private var includeHeaders = true
    @State private var dateFormat = "dd/MM/yyyy"
    
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
        
        var icon: String {
            switch self {
            case .csv: return "doc.text"
            case .pdf: return "doc.richtext"
            }
        }
    }
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: context))
        _accountsViewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Format selection
                formatSection
                
                // Report type (for PDF)
                if exportFormat == .pdf {
                    reportTypeSection
                }
                
                // CSV options
                if exportFormat == .csv {
                    csvOptionsSection
                }
                
                // Preview
                previewSection
                
                // Export button
                exportSection
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Exporting...")
                                .font(.headline)
                        }
                        .padding(30)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }
    
    // MARK: - Format Section
    
    @ViewBuilder
    private var formatSection: some View {
        Section {
            Picker("Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Label(format.rawValue, systemImage: format.icon)
                        .tag(format)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Export Format")
        } footer: {
            Text(exportFormat == .csv ? 
                 "CSV format for spreadsheet applications" : 
                 "PDF format for reports and sharing")
        }
    }
    
    // MARK: - Report Type Section
    
    @ViewBuilder
    private var reportTypeSection: some View {
        Section {
            Button {
                reportType = .monthly(Date())
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("This Month")
                    Spacer()
                    if case .monthly = reportType {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Button {
                reportType = .quarterly(Date())
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.orange)
                    Text("This Quarter")
                    Spacer()
                    if case .quarterly = reportType {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Button {
                reportType = .annual(Date())
            } label: {
                HStack {
                    Image(systemName: "calendar.circle")
                        .foregroundStyle(.purple)
                    Text("This Year")
                    Spacer()
                    if case .annual = reportType {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
        } header: {
            Text("Report Period")
        }
    }
    
    // MARK: - CSV Options Section
    
    @ViewBuilder
    private var csvOptionsSection: some View {
        Section {
            Toggle("Include Headers", isOn: $includeHeaders)
            
            Picker("Date Format", selection: $dateFormat) {
                Text("DD/MM/YYYY").tag("dd/MM/yyyy")
                Text("MM/DD/YYYY").tag("MM/dd/yyyy")
                Text("YYYY-MM-DD").tag("yyyy-MM-dd")
            }
        } header: {
            Text("CSV Options")
        }
        
        Section {
            ForEach(DataExportService.CSVColumn.allCases, id: \.self) { column in
                Toggle(column.rawValue, isOn: Binding(
                    get: { selectedColumns.contains(column) },
                    set: { isSelected in
                        if isSelected {
                            selectedColumns.insert(column)
                        } else {
                            selectedColumns.remove(column)
                        }
                    }
                ))
            }
        } header: {
            Text("Columns to Export")
        } footer: {
            Text("\(selectedColumns.count) of \(DataExportService.CSVColumn.allCases.count) columns selected")
        }
    }
    
    // MARK: - Preview Section
    
    @ViewBuilder
    private var previewSection: some View {
        Section {
            HStack {
                Text("Transactions")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(filteredTransactions.count)")
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Total Income")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(totalIncome))
                    .foregroundStyle(.green)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Total Expenses")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(totalExpenses))
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Net Income")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(netIncome))
                    .foregroundStyle(netIncome >= 0 ? .green : .red)
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Preview")
        }
    }
    
    // MARK: - Export Section
    
    @ViewBuilder
    private var exportSection: some View {
        Section {
            Button {
                Task {
                    await performExport()
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                    Text("Export \(exportFormat.rawValue)")
                    Spacer()
                }
                .fontWeight(.semibold)
            }
            .disabled(filteredTransactions.isEmpty || (exportFormat == .csv && selectedColumns.isEmpty))
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        await transactionsViewModel.loadTransactions()
        await accountsViewModel.loadAccounts()
    }
    
    // MARK: - Export Logic
    
    private func performExport() async {
        isExporting = true
        
        do {
            let exportService = DataExportService()
            
            let fileURL: URL
            
            switch exportFormat {
            case .csv:
                let options = DataExportService.CSVExportOptions(
                    columns: selectedColumns,
                    dateFormat: dateFormat,
                    includeHeaders: includeHeaders
                )
                fileURL = try exportService.exportToCSV(
                    transactions: filteredTransactions,
                    accounts: accountsViewModel.accounts,
                    options: options
                )
                
            case .pdf:
                fileURL = try exportService.exportToPDF(
                    reportType: reportType,
                    transactions: transactionsViewModel.transactions,
                    accounts: accountsViewModel.accounts
                )
            }
            
            exportedFileURL = fileURL
            showShareSheet = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isExporting = false
    }
    
    // MARK: - Computed Properties
    
    private var filteredTransactions: [WebAppTransaction] {
        if exportFormat == .pdf {
            let range = reportType.dateRange
            return transactionsViewModel.transactions.filter {
                $0.date >= range.start && $0.date < range.end
            }
        } else {
            return transactionsViewModel.transactions
        }
    }
    
    private var totalIncome: Decimal {
        filteredTransactions
            .filter { $0.type == .credit }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private var totalExpenses: Decimal {
        filteredTransactions
            .filter { $0.type == .debit }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private var netIncome: Decimal {
        totalIncome - totalExpenses
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "₹0"
    }
}

// MARK: - Share Sheet

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

// MARK: - Preview

#if DEBUG
#Preview("Export Data") {
    ExportDataView()
}
#endif
