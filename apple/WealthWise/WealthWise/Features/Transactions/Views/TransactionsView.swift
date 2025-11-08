//
//  TransactionsView.swift
//  WealthWise
//
//  Transactions list and filtering
//

import SwiftUI

struct TransactionsView: View {
    
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    
    enum TransactionFilter: String, CaseIterable {
        case all, income, expense
        
        var localizedName: String {
            switch self {
            case .all:
                return NSLocalizedString("all", comment: "All")
            case .income:
                return NSLocalizedString("income", comment: "Income")
            case .expense:
                return NSLocalizedString("expense", comment: "Expense")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        Text(filter.localizedName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Transactions List
                ScrollView {
                    VStack(spacing: 16) {
                        EmptyStateView(
                            icon: "list.bullet.rectangle.fill",
                            title: NSLocalizedString("no_transactions", comment: "No Transactions"),
                            message: NSLocalizedString("add_transaction_message", comment: "Add your first transaction to see it here")
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("transactions", comment: "Transactions"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Add transaction
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: NSLocalizedString("search_transactions", comment: "Search transactions"))
        }
    }
}

#Preview {
    TransactionsView()
}
