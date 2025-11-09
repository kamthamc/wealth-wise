//
//  CSVImportView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  CSV import interface with file picker, column mapping, and preview
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@available(iOS 18, macOS 15, *)
struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @StateObject private var transactionsViewModel: TransactionsViewModel
    @StateObject private var accountsViewModel: AccountsViewModel
    
    // Import state
    @State private var importService = CSVImportService()
    @State private var currentStep: ImportStep = .selectFile
    @State private var selectedAccount: Account?
    
    // File data
    @State private var showFilePicker = false
    @State private var fileURL: URL?
    @State private var headers: [String] = []
    @State private var rows: [CSVImportService.CSVRow] = []
    
    // Format and mapping
    @State private var detectedFormat: CSVImportService.BankFormat = .generic
    @State private var columnMapping = CSVImportService.ColumnMapping()
    @State private var parsedTransactions: [CSVImportService.ParsedTransaction] = []
    
    // UI state
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var importCount = 0
    
    // Computed property for adaptive layout
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
    
    enum ImportStep {
        case selectFile
        case selectAccount
        case mapColumns
        case preview
        case importing
        case complete
    }
    
    init(modelContext: ModelContext) {
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: modelContext))
        _accountsViewModel = StateObject(wrappedValue: AccountsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressView
                
                Divider()
                
                // Step content
                ScrollView {
                    stepContent
                        .padding()
                }
                
                Divider()
                
                // Action buttons
                actionButtons
                    .padding()
            }
            .navigationTitle("Import Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("Done", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Successfully imported \(importCount) transactions")
            }
            .task {
                await accountsViewModel.loadAccounts()
            }
        }
    }
    
    // MARK: - Progress View
    
    @ViewBuilder
    private var progressView: some View {
        HStack(spacing: 16) {
            ForEach([
                ("Select File", ImportStep.selectFile),
                ("Choose Account", ImportStep.selectAccount),
                ("Map Columns", ImportStep.mapColumns),
                ("Preview", ImportStep.preview)
            ], id: \.1) { title, step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isStepComplete(step) {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(stepNumber(for: step))")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                    
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(stepColor(for: step))
                }
                
                if step != .preview {
                    Rectangle()
                        .fill(isStepComplete(step) ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .selectFile:
            selectFileStep
        case .selectAccount:
            selectAccountStep
        case .mapColumns:
            mapColumnsStep
        case .preview:
            previewStep
        case .importing:
            importingStep
        case .complete:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var selectFileStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Select CSV File")
                    .font(.title2.bold())
                
                Text("Choose a CSV file containing your transactions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let url = fileURL {
                WealthCardView.colored(color: .green) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected File")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(url.lastPathComponent)
                                .font(.subheadline.bold())
                        }
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Detected Format", systemImage: "doc.badge.gearshape")
                        .font(.caption.bold())
                    Text(detectedFormat.displayName)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button {
                showFilePicker = true
            } label: {
                Label(fileURL == nil ? "Choose File" : "Choose Different File", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    @ViewBuilder
    private var selectAccountStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Account")
                    .font(.title2.bold())
                
                Text("Choose which account these transactions belong to")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if accountsViewModel.accounts.isEmpty {
                WealthCardView.colored(color: .orange) {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("No accounts found")
                            .font(.headline)
                        Text("Please create an account first")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(accountsViewModel.accounts.filter { !$0.isArchived }) { account in
                    Button {
                        selectedAccount = account
                    } label: {
                        HStack {
                            Image(systemName: iconForAccountType(account.type))
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    LinearGradient(
                                        colors: gradientForAccountType(account.type),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.headline)
                                if let institution = account.institution {
                                    Text(institution)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedAccount?.id == account.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            selectedAccount?.id == account.id ?
                            Color.blue.opacity(0.1) : Color(.systemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedAccount?.id == account.id ? Color.blue : Color.clear,
                                    lineWidth: 2
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private var mapColumnsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Map Columns")
                    .font(.title2.bold())
                
                Text("Match CSV columns to transaction fields")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !columnMapping.isValid {
                WealthCardView.colored(color: .orange) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Missing Required Fields")
                                .font(.subheadline.bold())
                            Text(columnMapping.missingColumns.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Column mapping pickers
            VStack(spacing: 12) {
                columnPicker(
                    label: "Date",
                    icon: "calendar",
                    required: true,
                    selection: $columnMapping.dateColumn
                )
                
                columnPicker(
                    label: "Description",
                    icon: "text.alignleft",
                    required: true,
                    selection: $columnMapping.descriptionColumn
                )
                
                columnPicker(
                    label: "Amount",
                    icon: "indianrupeesign.circle",
                    required: true,
                    selection: $columnMapping.amountColumn
                )
                
                columnPicker(
                    label: "Type (Optional)",
                    icon: "arrow.left.arrow.right",
                    required: false,
                    selection: $columnMapping.typeColumn
                )
                
                columnPicker(
                    label: "Category (Optional)",
                    icon: "tag",
                    required: false,
                    selection: $columnMapping.categoryColumn
                )
                
                columnPicker(
                    label: "Notes (Optional)",
                    icon: "note.text",
                    required: false,
                    selection: $columnMapping.notesColumn
                )
            }
        }
    }
    
    @ViewBuilder
    private var previewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview Import")
                    .font(.title2.bold())
                
                HStack {
                    Text("\(validTransactionCount) of \(parsedTransactions.count) transactions are valid")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if invalidTransactionCount > 0 {
                        Text("\(invalidTransactionCount) invalid")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Preview list
            ForEach(Array(parsedTransactions.prefix(10).enumerated()), id: \.offset) { index, transaction in
                previewRow(transaction, index: index)
            }
            
            if parsedTransactions.count > 10 {
                Text("... and \(parsedTransactions.count - 10) more transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    private var importingStep: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Importing transactions...")
                .font(.headline)
            
            Text("Please wait while we import your transactions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func columnPicker(
        label: String,
        icon: String,
        required: Bool,
        selection: Binding<Int?>
    ) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .frame(width: 150, alignment: .leading)
            
            if required {
                Text("*")
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            Picker("", selection: selection) {
                Text("Not Mapped").tag(nil as Int?)
                ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                    Text(header).tag(index as Int?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func previewRow(_ transaction: CSVImportService.ParsedTransaction, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if transaction.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.subheadline.bold())
                    
                    if let date = transaction.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let amount = transaction.amount {
                    Text(formatCurrency(amount))
                        .font(.subheadline.bold())
                        .foregroundStyle(transaction.type == .credit ? .green : .red)
                }
            }
            
            if !transaction.isValid {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(transaction.validationErrors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .background(transaction.isValid ? Color.clear : Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(transaction.isValid ? Color.clear : Color.red.opacity(0.3), lineWidth: 1)
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .selectFile {
                Button("Back") {
                    goToPreviousStep()
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
            }
            
            Button(nextButtonTitle) {
                Task {
                    await goToNextStep()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed)
        }
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .selectFile: return "Next"
        case .selectAccount: return "Next"
        case .mapColumns: return "Preview"
        case .preview: return "Import \(validTransactionCount) Transactions"
        case .importing: return "Importing..."
        case .complete: return "Done"
        }
    }
    
    private var canProceed: Bool {
        if isProcessing { return false }
        
        switch currentStep {
        case .selectFile: return fileURL != nil
        case .selectAccount: return selectedAccount != nil
        case .mapColumns: return columnMapping.isValid
        case .preview: return validTransactionCount > 0
        case .importing: return false
        case .complete: return false
        }
    }
    
    // MARK: - Navigation
    
    private func goToPreviousStep() {
        switch currentStep {
        case .selectAccount:
            currentStep = .selectFile
        case .mapColumns:
            currentStep = .selectAccount
        case .preview:
            currentStep = .mapColumns
        default:
            break
        }
    }
    
    private func goToNextStep() async {
        switch currentStep {
        case .selectFile:
            currentStep = .selectAccount
            
        case .selectAccount:
            currentStep = .mapColumns
            
        case .mapColumns:
            // Parse transactions for preview
            parsedTransactions = importService.parseTransactions(
                rows: rows,
                mapping: columnMapping,
                defaultAccount: selectedAccount!.id
            )
            currentStep = .preview
            
        case .preview:
            await performImport()
            
        default:
            break
        }
    }
    
    // MARK: - Import Logic
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            fileURL = url
            
            do {
                let (parsedHeaders, parsedRows) = try importService.parseCSV(from: url)
                headers = parsedHeaders
                rows = parsedRows
                
                detectedFormat = importService.detectBankFormat(headers: headers)
                columnMapping = importService.suggestColumnMapping(for: headers, format: detectedFormat)
                
            } catch let error as CSVImportService.ImportError {
                errorMessage = error.localizedDescription
                showError = true
                fileURL = nil
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                fileURL = nil
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func performImport() async {
        guard let account = selectedAccount else { return }
        
        currentStep = .importing
        isProcessing = true
        
        do {
            let validTransactions = parsedTransactions.filter { $0.isValid }
            importCount = try await importService.importTransactions(
                validTransactions,
                to: account.id,
                modelContext: modelContext
            )
            
            await transactionsViewModel.loadTransactions()
            
            isProcessing = false
            showSuccess = true
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
            currentStep = .preview
        }
    }
    
    // MARK: - Helper Methods
    
    private func stepNumber(for step: ImportStep) -> Int {
        switch step {
        case .selectFile: return 1
        case .selectAccount: return 2
        case .mapColumns: return 3
        case .preview: return 4
        default: return 0
        }
    }
    
    private func stepColor(for step: ImportStep) -> Color {
        let stepNum = stepNumber(for: step)
        let currentNum = stepNumber(for: currentStep)
        
        if stepNum < currentNum {
            return .blue
        } else if stepNum == currentNum {
            return .blue
        } else {
            return .secondary.opacity(0.3)
        }
    }
    
    private func isStepComplete(_ step: ImportStep) -> Bool {
        stepNumber(for: step) < stepNumber(for: currentStep)
    }
    
    private var validTransactionCount: Int {
        parsedTransactions.filter { $0.isValid }.count
    }
    
    private var invalidTransactionCount: Int {
        parsedTransactions.filter { !$0.isValid }.count
    }
    
    private func iconForAccountType(_ type: Account.AccountType) -> String {
        switch type {
        case .bank: return "banknote"
        case .creditCard: return "creditcard"
        case .upi: return "indianrupeesign.circle"
        case .brokerage: return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func gradientForAccountType(_ type: Account.AccountType) -> [Color] {
        switch type {
        case .bank: return [.blue, .cyan]
        case .creditCard: return [.orange, .pink]
        case .upi: return [.purple, .indigo]
        case .brokerage: return [.green, .mint]
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
#Preview("CSV Import") {
    let container = try! ModelContainer(
        for: Account.self, WebAppTransaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let account = Account(
        userId: "preview",
        name: "HDFC Bank",
        type: .bank,
        institution: "HDFC",
        currency: "INR"
    )
    container.mainContext.insert(account)
    
    return CSVImportView(modelContext: container.mainContext)
}
#endif
