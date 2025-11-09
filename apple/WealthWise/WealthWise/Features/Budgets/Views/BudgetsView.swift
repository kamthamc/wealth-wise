//
//  BudgetsView.swift
//  WealthWise
//
//  Budgets overview and management
//

import SwiftUI
import SwiftData

struct BudgetsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: BudgetsViewModel
    @State private var showCreateBudget = false
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _viewModel = StateObject(wrappedValue: BudgetsViewModel(modelContext: context))
    }
    
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
                        showCreateBudget = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadBudgets()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.hasBudgets {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showCreateBudget) {
                Text("Create Budget Form")
            }
            .alert(
                NSLocalizedString("error", comment: "Error"),
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button(NSLocalizedString("ok", comment: "OK")) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? NSLocalizedString("unknown_error", comment: "An unknown error occurred"))
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
                    Text(viewModel.formatCurrency(viewModel.totalBudgeted))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("spent", comment: "Spent"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(viewModel.totalSpent))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(viewModel.totalSpentPercentage > 1.0 ? .red : .orange)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.totalSpentPercentage > 1.0 ? Color.red.gradient : Color.orange.gradient)
                        .frame(
                            width: geometry.size.width * min(viewModel.totalSpentPercentage, 1.0),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            
            if viewModel.hasBudgets {
                HStack {
                    Text(viewModel.formatPercentage(viewModel.totalSpentPercentage))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if viewModel.overBudgetCount > 0 {
                        Label("\(viewModel.overBudgetCount) over budget", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var budgetsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("your_budgets", comment: "Your Budgets"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.hasBudgets {
                VStack(spacing: 12) {
                    ForEach(viewModel.budgets) { budget in
                        BudgetCard(budget: budget, viewModel: viewModel)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: NSLocalizedString("no_budgets_yet", comment: "No Budgets Yet"),
                    message: NSLocalizedString("create_budget_message", comment: "Create your first budget to manage spending")
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct BudgetCard: View {
    let budget: Budget
    let viewModel: BudgetsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.headline)
                    
                    Text(viewModel.budgetPeriodText(budget.period))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: viewModel.budgetStatus(budget).icon)
                    .foregroundStyle(viewModel.budgetStatus(budget).color)
            }
            
            // Amount Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(budget.currentSpent))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Budget")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(budget.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(viewModel.budgetStatus(budget).color.gradient)
                        .frame(
                            width: geometry.size.width * min(viewModel.spentPercentage(for: budget), 1.0),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            
            Text(viewModel.formatPercentage(viewModel.spentPercentage(for: budget)))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(viewModel.budgetStatus(budget).color)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    BudgetsView()
}
