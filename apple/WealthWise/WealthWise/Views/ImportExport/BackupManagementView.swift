//
//  BackupManagementView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Backup Management View
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Backup management view for creating and restoring encrypted backups
@available(iOS 18.6, macOS 15.6, *)
struct BackupManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var includeAttachments = false
    @State private var isCreatingBackup = false
    @State private var isRestoringBackup = false
    @State private var showingFilePicker = false
    @State private var showingPasswordSheet = false
    @State private var selectedBackupURL: URL?
    @State private var backupResult: Result<URL, Error>?
    @State private var restoreResult: Result<BackupMetadata, Error>?
    @State private var errorMessage: String?
    
    private var encryptionService: EncryptionService {
        EncryptionService(keyManager: SecureKeyManager())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Backup Section
                    createBackupSection
                    
                    Divider()
                    
                    // Restore Section
                    restoreBackupSection
                    
                    // Result Section
                    if let result = backupResult {
                        backupResultSection(result)
                    }
                    
                    if let result = restoreResult {
                        restoreResultSection(result)
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("backup_management_title", comment: "Backup Management"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPasswordSheet) {
                BackupPasswordSheet(
                    password: $password,
                    confirmPassword: $confirmPassword,
                    isCreatingBackup: true
                ) {
                    performBackup()
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "wealthwise") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                handleBackupFileSelection(result)
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
    
    private var createBackupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    NSLocalizedString("backup_button_title", comment: "Create Backup"),
                    systemImage: "lock.shield"
                )
                .font(.headline)
                
                Text(NSLocalizedString("backup_help_text", comment: "Backup help"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Toggle(NSLocalizedString("backup_include_attachments", comment: "Include attachments"), isOn: $includeAttachments)
                .padding(.horizontal)
            
            Button(action: { showingPasswordSheet = true }) {
                HStack {
                    if isCreatingBackup {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(NSLocalizedString("backup_button_title", comment: "Create Backup"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCreatingBackup)
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemGray6))
        #endif
        .cornerRadius(12)
    }
    
    private var restoreBackupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    NSLocalizedString("restore_button_title", comment: "Restore Backup"),
                    systemImage: "arrow.clockwise.circle"
                )
                .font(.headline)
                
                Text(NSLocalizedString("restore_help_text", comment: "Restore help"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let backupURL = selectedBackupURL {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(backupURL.lastPathComponent)
                            .font(.subheadline)
                        Text(backupURL.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding()
                #if os(macOS)
                .background(Color(nsColor: .windowBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .cornerRadius(8)
            }
            
            Button(action: { showingFilePicker = true }) {
                Label(
                    NSLocalizedString("backup_select_file", comment: "Select Backup File"),
                    systemImage: "folder"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if selectedBackupURL != nil {
                Button(action: { showingPasswordSheet = true }) {
                    HStack {
                        if isRestoringBackup {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text(NSLocalizedString("restore_button_title", comment: "Restore Backup"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRestoringBackup)
            }
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemGray6))
        #endif
        .cornerRadius(12)
    }
    
    private func backupResultSection(_ result: Result<URL, Error>) -> some View {
        Group {
            switch result {
            case .success(let url):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text(NSLocalizedString("backup_success_title", comment: "Backup Created Successfully"))
                        .font(.headline)
                    
                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ShareLink(item: url) {
                        Label(
                            NSLocalizedString("backup_share", comment: "Share Backup"),
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
            case .failure(let error):
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text(NSLocalizedString("backup_failed_title", comment: "Backup Failed"))
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func restoreResultSection(_ result: Result<BackupMetadata, Error>) -> some View {
        Group {
            switch result {
            case .success(let metadata):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text(NSLocalizedString("restore_success_title", comment: "Backup Restored Successfully"))
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: NSLocalizedString("restore_transactions_count", comment: "%d transactions"), metadata.transactionCount))
                        Text(String(format: NSLocalizedString("restore_goals_count", comment: "%d goals"), metadata.goalCount))
                        Text(String(format: NSLocalizedString("restore_backup_date", comment: "Backup from %@"), metadata.createdAt.formatted(date: .abbreviated, time: .omitted)))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
            case .failure(let error):
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text(NSLocalizedString("restore_failed_title", comment: "Restore Failed"))
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Actions
    
    private func performBackup() {
        guard !password.isEmpty else {
            errorMessage = NSLocalizedString("backup_error_password_required", comment: "Password is required")
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = NSLocalizedString("backup_error_password_mismatch", comment: "Passwords don't match")
            return
        }
        
        isCreatingBackup = true
        Task {
            defer { isCreatingBackup = false }
            
            do {
                let backupService = BackupService(
                    modelContext: modelContext,
                    encryptionService: encryptionService
                )
                let url = try await backupService.createBackup(
                    password: password,
                    includeAttachments: includeAttachments
                )
                backupResult = .success(url)
            } catch {
                backupResult = .failure(error)
            }
            
            // Clear passwords
            password = ""
            confirmPassword = ""
        }
    }
    
    private func performRestore() {
        guard let backupURL = selectedBackupURL else { return }
        guard !password.isEmpty else {
            errorMessage = NSLocalizedString("backup_error_password_required", comment: "Password is required")
            return
        }
        
        isRestoringBackup = true
        Task {
            defer { isRestoringBackup = false }
            
            do {
                let backupService = BackupService(
                    modelContext: modelContext,
                    encryptionService: encryptionService
                )
                let metadata = try await backupService.restoreBackup(from: backupURL, password: password)
                restoreResult = .success(metadata)
            } catch {
                restoreResult = .failure(error)
            }
            
            // Clear password
            password = ""
        }
    }
    
    private func handleBackupFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            selectedBackupURL = urls.first
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Backup Password Sheet

struct BackupPasswordSheet: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    let isCreatingBackup: Bool
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(NSLocalizedString("backup_password_help", comment: "Enter a strong password to encrypt your backup"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section(NSLocalizedString("backup_password", comment: "Password")) {
                    SecureField(NSLocalizedString("backup_password_placeholder", comment: "Enter password"), text: $password)
                    
                    if isCreatingBackup {
                        SecureField(NSLocalizedString("backup_password_confirm", comment: "Confirm password"), text: $confirmPassword)
                    }
                }
                
                Section {
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }) {
                        Text(NSLocalizedString("general.continue", comment: "Continue"))
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(password.isEmpty || (isCreatingBackup && password != confirmPassword))
                }
            }
            .navigationTitle(NSLocalizedString("backup_password", comment: "Password"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BackupManagementView()
        .modelContainer(for: [Transaction.self, Goal.self])
}
