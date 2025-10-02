//
//  ColumnMappingView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Column Mapping Configuration View
//

import SwiftUI

/// Column mapping configuration view
@available(iOS 18.6, macOS 15.6, *)
struct ColumnMappingView: View {
    let headers: [String]
    @Binding var configuration: ImportConfiguration
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(NSLocalizedString("column_mapping_help", comment: "Column mapping help"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section(NSLocalizedString("column_mapping_title", comment: "Column Mappings")) {
                    ForEach($configuration.mappings) { $mapping in
                        ColumnMappingRow(
                            mapping: $mapping,
                            allHeaders: headers
                        )
                    }
                }
                
                Section(NSLocalizedString("import_settings", comment: "Import Settings")) {
                    Toggle(NSLocalizedString("import_skip_first_row", comment: "Skip first row (header)"), isToggled: $configuration.skipFirstRow)
                    
                    Toggle(NSLocalizedString("duplicate_detection_title", comment: "Detect duplicates"), isToggled: $configuration.detectDuplicates)
                    
                    if configuration.detectDuplicates {
                        Stepper(
                            value: $configuration.duplicateThresholdDays,
                            in: 1...30
                        ) {
                            Text(String(format: NSLocalizedString("import_duplicate_threshold", comment: "Duplicate threshold: %d days"), configuration.duplicateThresholdDays))
                        }
                    }
                    
                    Picker(NSLocalizedString("import_default_currency", comment: "Default currency"), selection: $configuration.defaultCurrency) {
                        Text("INR").tag("INR")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                    }
                }
            }
            .navigationTitle(NSLocalizedString("column_mapping_title", comment: "Column Mapping"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("general.done", comment: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Column Mapping Row

struct ColumnMappingRow: View {
    @Binding var mapping: ColumnMapping
    let allHeaders: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mapping.sourceColumn)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Picker(NSLocalizedString("import_field_target", comment: "Target Field"), selection: $mapping.targetField) {
                ForEach(ImportTargetField.allCases, id: \.self) { field in
                    HStack {
                        Text(field.displayName)
                        if field.isRequired {
                            Text("*")
                                .foregroundColor(.red)
                        }
                    }
                    .tag(field)
                }
            }
            .pickerStyle(.menu)
            
            if mapping.targetField == .date {
                Picker(NSLocalizedString("import_date_format", comment: "Date Format"), selection: Binding(
                    get: { mapping.dateFormat ?? "yyyy-MM-dd" },
                    set: { mapping.dateFormat = $0 }
                )) {
                    Text("yyyy-MM-dd (2024-01-15)").tag("yyyy-MM-dd")
                    Text("dd/MM/yyyy (15/01/2024)").tag("dd/MM/yyyy")
                    Text("MM/dd/yyyy (01/15/2024)").tag("MM/dd/yyyy")
                    Text("dd-MMM-yyyy (15-Jan-2024)").tag("dd-MMM-yyyy")
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ColumnMappingView(
        headers: ["Date", "Amount", "Description", "Category"],
        configuration: .constant(ImportConfiguration())
    )
}
