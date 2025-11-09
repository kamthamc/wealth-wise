//
//  GoalsView.swift
//  WealthWise
//
//  Financial goals tracking
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: GoalsViewModel
    @State private var selectedTab: GoalTab = .active
    @State private var showCreateGoal = false
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _viewModel = StateObject(wrappedValue: GoalsViewModel(modelContext: context))
    }
    
    enum GoalTab: String, CaseIterable {
        case active, completed
        
        var localizedName: String {
            switch self {
            case .active:
                return NSLocalizedString("active", comment: "Active")
            case .completed:
                return NSLocalizedString("completed", comment: "Completed")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Goals", selection: $selectedTab) {
                    ForEach(GoalTab.allCases, id: \.self) { tab in
                        Text(tab.localizedName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Goals Content
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == .active {
                            activeGoalsSection
                        } else {
                            completedGoalsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("goals", comment: "Goals"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadGoals()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.hasGoals {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showCreateGoal) {
                Text("Create Goal Form")
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
    
    private var activeGoalsSection: some View {
        VStack(spacing: 12) {
            if viewModel.hasActiveGoals {
                ForEach(viewModel.activeGoals) { goal in
                    GoalCard(goal: goal, viewModel: viewModel)
                }
            } else {
                EmptyStateView(
                    icon: "target",
                    title: NSLocalizedString("no_active_goals", comment: "No Active Goals"),
                    message: NSLocalizedString("set_goal_message", comment: "Set your first financial goal to start saving")
                )
            }
        }
    }
    
    private var completedGoalsSection: some View {
        VStack(spacing: 12) {
            if viewModel.hasCompletedGoals {
                ForEach(viewModel.completedGoals) { goal in
                    GoalCard(goal: goal, viewModel: viewModel)
                }
            } else {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("no_completed_goals", comment: "No Completed Goals"),
                    message: NSLocalizedString("completed_goals_message", comment: "Your completed goals will appear here")
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct GoalCard: View {
    let goal: WebAppGoal
    let viewModel: GoalsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.headline)
                    
                    Text(viewModel.goalTypeText(goal.type))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(viewModel.goalPriorityColor(goal.priority).opacity(0.2))
                        .foregroundStyle(viewModel.goalPriorityColor(goal.priority))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Circle()
                    .fill(viewModel.goalStatusColor(goal).opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            
            // Progress Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(goal.currentAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(goal.targetAmount))
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
                        .fill(viewModel.goalStatusColor(goal).gradient)
                        .frame(
                            width: geometry.size.width * min(viewModel.progressPercentage(for: goal), 1.0),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(viewModel.formatPercentage(viewModel.progressPercentage(for: goal)))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.goalStatusColor(goal))
                
                Spacer()
                
                if let days = viewModel.daysRemaining(for: goal) {
                    Text("\(days) days left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if viewModel.isOverdue(goal) {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    GoalsView()
}
