//
//  AddGoalView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Add new goal form with type, priority, and progress tracking
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: GoalsViewModel
    
    // Form fields
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = "0"
    @State private var targetDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var selectedType: WebAppGoal.GoalType = .savings
    @State private var selectedPriority: WebAppGoal.GoalPriority = .medium
    @State private var goalDescription: String = ""
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: GoalsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Goal Details Section
                Section {
                    TextField(
                        NSLocalizedString("goal_name", comment: "Goal name"),
                        text: $name
                    )
                    .textInputAutocapitalization(.words)
                    
                    Picker(
                        NSLocalizedString("goal_type", comment: "Type"),
                        selection: $selectedType
                    ) {
                        ForEach(WebAppGoal.GoalType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: iconForType(type))
                                Text(displayNameForType(type))
                            }
                            .tag(type)
                        }
                    }
                    
                    Picker(
                        NSLocalizedString("priority", comment: "Priority"),
                        selection: $selectedPriority
                    ) {
                        ForEach(WebAppGoal.GoalPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(colorForPriority(priority))
                                    .frame(width: 8, height: 8)
                                Text(displayNameForPriority(priority))
                            }
                            .tag(priority)
                        }
                    }
                    
                } header: {
                    Text(NSLocalizedString("goal_details", comment: "Goal Details"))
                }
                
                // Target Amount Section
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            NSLocalizedString("target_amount", comment: "Target amount"),
                            text: $targetAmount
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title2.bold())
                    }
                    
                    if let target = Decimal(string: targetAmount) {
                        Text(formatCurrency(target))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    DatePicker(
                        NSLocalizedString("target_date", comment: "Target date"),
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    
                    if let target = Decimal(string: targetAmount) {
                        targetBreakdown(amount: target)
                    }
                    
                } header: {
                    Text(NSLocalizedString("target", comment: "Target"))
                }
                
                // Current Progress Section
                Section {
                    HStack {
                        Text("₹")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            NSLocalizedString("current_amount", comment: "Current amount"),
                            text: $currentAmount
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    if let current = Decimal(string: currentAmount),
                       let target = Decimal(string: targetAmount),
                       target > 0 {
                        progressView(current: current, target: target)
                    }
                    
                } header: {
                    Text(NSLocalizedString("current_progress", comment: "Current Progress"))
                } footer: {
                    Text(NSLocalizedString("current_progress_hint", comment: "How much have you already saved towards this goal?"))
                }
                
                // Description Section
                Section {
                    TextField(
                        NSLocalizedString("description_optional", comment: "Description (optional)"),
                        text: $goalDescription,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    
                } header: {
                    Text(NSLocalizedString("description", comment: "Description"))
                }
                
                // Goal Type Info
                Section {
                    goalTypeInfo
                } header: {
                    Text(NSLocalizedString("about_goal_type", comment: "About this goal type"))
                }
            }
            .navigationTitle(NSLocalizedString("add_goal", comment: "Add Goal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("create", comment: "Create")) {
                        Task {
                            await createGoal()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert(
                NSLocalizedString("error", comment: "Error"),
                isPresented: $showError
            ) {
                Button(NSLocalizedString("ok", comment: "OK"), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert(
                NSLocalizedString("success", comment: "Success"),
                isPresented: $showSuccess
            ) {
                Button(NSLocalizedString("ok", comment: "OK"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(NSLocalizedString("goal_created", comment: "Goal created successfully"))
            }
        }
    }
    
    // MARK: - Progress View
    
    @ViewBuilder
    private func progressView(current: Decimal, target: Decimal) -> some View {
        let percentage = Double(truncating: (current / target) as NSNumber) * 100
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(Int(min(percentage, 100)))%")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Text("Remaining: \(formatCurrency(max(target - current, 0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(min(percentage / 100, 1.0)), height: 8)
                        .clipShape(Capsule())
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Target Breakdown
    
    @ViewBuilder
    private func targetBreakdown(amount: Decimal) -> some View {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        let monthsRemaining = max(Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 0, 1)
        
        if daysRemaining > 0 {
            let current = Decimal(string: currentAmount) ?? 0
            let remaining = amount - current
            let perMonth = remaining / Decimal(monthsRemaining)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("to_reach_goal", comment: "To reach your goal:"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Label {
                    Text("\(formatCurrency(perMonth))/month for \(monthsRemaining) months")
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Goal Type Info
    
    @ViewBuilder
    private var goalTypeInfo: some View {
        switch selectedType {
        case .savings:
            Label {
                Text(NSLocalizedString("savings_goal_info", comment: "General savings for any purpose"))
            } icon: {
                Image(systemName: "banknote")
                    .foregroundStyle(.green)
            }
            
        case .investment:
            Label {
                Text(NSLocalizedString("investment_goal_info", comment: "Investment targets for wealth building"))
            } icon: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue)
            }
            
        case .debtPayment:
            Label {
                Text(NSLocalizedString("debt_payment_goal_info", comment: "Paying off loans or credit cards"))
            } icon: {
                Image(systemName: "creditcard")
                    .foregroundStyle(.red)
            }
            
        case .emergency:
            Label {
                Text(NSLocalizedString("emergency_goal_info", comment: "Emergency fund for unexpected expenses"))
            } icon: {
                Image(systemName: "exclamationmark.shield")
                    .foregroundStyle(.orange)
            }
            
        case .retirement:
            Label {
                Text(NSLocalizedString("retirement_goal_info", comment: "Long-term retirement planning"))
            } icon: {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.purple)
            }
            
        case .purchase:
            Label {
                Text(NSLocalizedString("purchase_goal_info", comment: "Saving for a specific purchase"))
            } icon: {
                Image(systemName: "cart")
                    .foregroundStyle(.indigo)
            }
            
        case .education:
            Label {
                Text(NSLocalizedString("education_goal_info", comment: "Education expenses and tuition"))
            } icon: {
                Image(systemName: "book")
                    .foregroundStyle(.teal)
            }
            
        case .travel:
            Label {
                Text(NSLocalizedString("travel_goal_info", comment: "Vacation and travel expenses"))
            } icon: {
                Image(systemName: "airplane")
                    .foregroundStyle(.cyan)
            }
            
        case .other:
            Label {
                Text(NSLocalizedString("other_goal_info", comment: "Any other financial goal"))
            } icon: {
                Image(systemName: "star")
                    .foregroundStyle(.yellow)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Decimal(string: targetAmount) != nil &&
        Decimal(string: currentAmount) != nil &&
        targetDate > Date()
    }
    
    // MARK: - Actions
    
    private func createGoal() async {
        guard isFormValid,
              let target = Decimal(string: targetAmount),
              let current = Decimal(string: currentAmount) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await viewModel.createGoal(
                name: trimmedName,
                targetAmount: target,
                currentAmount: current,
                targetDate: targetDate,
                type: selectedType,
                priority: selectedPriority,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            
            isLoading = false
            showSuccess = true
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func iconForType(_ type: WebAppGoal.GoalType) -> String {
        switch type {
        case .savings: return "banknote"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .debtPayment: return "creditcard"
        case .emergency: return "exclamationmark.shield"
        case .retirement: return "figure.walk"
        case .purchase: return "cart"
        case .education: return "book"
        case .travel: return "airplane"
        case .other: return "star"
        }
    }
    
    private func displayNameForType(_ type: WebAppGoal.GoalType) -> String {
        switch type {
        case .savings:
            return NSLocalizedString("goal_type_savings", comment: "Savings")
        case .investment:
            return NSLocalizedString("goal_type_investment", comment: "Investment")
        case .debtPayment:
            return NSLocalizedString("goal_type_debt", comment: "Debt Payment")
        case .emergency:
            return NSLocalizedString("goal_type_emergency", comment: "Emergency Fund")
        case .retirement:
            return NSLocalizedString("goal_type_retirement", comment: "Retirement")
        case .purchase:
            return NSLocalizedString("goal_type_purchase", comment: "Purchase")
        case .education:
            return NSLocalizedString("goal_type_education", comment: "Education")
        case .travel:
            return NSLocalizedString("goal_type_travel", comment: "Travel")
        case .other:
            return NSLocalizedString("goal_type_other", comment: "Other")
        }
    }
    
    private func displayNameForPriority(_ priority: WebAppGoal.GoalPriority) -> String {
        switch priority {
        case .low:
            return NSLocalizedString("priority_low", comment: "Low")
        case .medium:
            return NSLocalizedString("priority_medium", comment: "Medium")
        case .high:
            return NSLocalizedString("priority_high", comment: "High")
        case .critical:
            return NSLocalizedString("priority_critical", comment: "Critical")
        }
    }
    
    private func colorForPriority(_ priority: WebAppGoal.GoalPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
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
#Preview("Add Goal") {
    AddGoalView(modelContext: ModelContext(
        try! ModelContainer(
            for: WebAppGoal.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    ))
}
#endif
