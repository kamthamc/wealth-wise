//
//  GoalsView.swift
//  WealthWise
//
//  Financial goals tracking
//

import SwiftUI

struct GoalsView: View {
    
    @State private var selectedTab: GoalTab = .active
    
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
                        // Create goal
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var activeGoalsSection: some View {
        VStack(spacing: 12) {
            EmptyStateView(
                icon: "target",
                title: NSLocalizedString("no_active_goals", comment: "No Active Goals"),
                message: NSLocalizedString("set_goal_message", comment: "Set your first financial goal to start saving")
            )
        }
    }
    
    private var completedGoalsSection: some View {
        VStack(spacing: 12) {
            EmptyStateView(
                icon: "checkmark.circle.fill",
                title: NSLocalizedString("no_completed_goals", comment: "No Completed Goals"),
                message: NSLocalizedString("completed_goals_message", comment: "Your completed goals will appear here")
            )
        }
    }
}

#Preview {
    GoalsView()
}
