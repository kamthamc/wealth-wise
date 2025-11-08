//
//  BudgetsView.swift
//  WealthWise
//
//  Budgets overview and management
//

import SwiftUI

struct BudgetsView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Card
                    summaryCard
                    
                    // Budgets List
                    budgetsListSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("budgets", comment: "Budgets"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Create budget
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("total_budgeted", comment: "Total Budgeted"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("₹0.00")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("spent", comment: "Spent"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("₹0.00")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.gradient)
                        .frame(width: 0, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var budgetsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("your_budgets", comment: "Your Budgets"))
                .font(.headline)
                .fontWeight(.semibold)
            
            EmptyStateView(
                icon: "chart.pie.fill",
                title: NSLocalizedString("no_budgets_yet", comment: "No Budgets Yet"),
                message: NSLocalizedString("create_budget_message", comment: "Create your first budget to manage spending")
            )
        }
    }
}

#Preview {
    BudgetsView()
}
