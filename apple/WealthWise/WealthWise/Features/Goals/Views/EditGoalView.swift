//
//  EditGoalView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Edit existing goal with contribution tracking and status management
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: GoalsViewModel
    
    let goal: WebAppGoal
    
    // Form fields
    @State private var name: String
    @State private var goalType: WebAppGoal.GoalType
    @State private var priority: WebAppGoal.GoalPriority
    @State private var targetAmount: String
    @State private var targetDate: Date
    @State private var currentAmount: String
    @State private var goalDescription: String
    @State private var status: WebAppGoal.GoalStatus
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var showAddContribution = false
    @State private var showContributionHistory = false
    
    // Contribution form
    @State private var contributionAmount: String = ""
    @State private var contributionDate: Date = Date()
    @State private var contributionNotes: String = ""
    
    init(goal: WebAppGoal, modelContext: ModelContext) {
        self.goal = goal
        _viewModel = StateObject(wrappedValue: GoalsViewModel(modelContext: modelContext))
        
        // Initialize state from goal
        _name = State(initialValue: goal.name)
        _goalType = State(initialValue: goal.goalType)
        _priority = State(initialValue: goal.priority)
        _targetAmount = State(initialValue: goal.targetAmount.description)
        _targetDate = State(initialValue: goal.targetDate)
        _currentAmount = State(initialValue: goal.currentAmount.description)
        _goalDescription = State(initialValue: goal.goalDescription ?? "")
        _status = State(initialValue: goal.status)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Goal Details Section
                Section {
                    TextField("Goal name", text: $name)
                    
                    Picker("Type", selection: $goalType) {
                        ForEach(WebAppGoal.GoalType.allCases, id: \.self) { type in
                            Text(displayNameForType(type))
                                .tag(type)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(WebAppGoal.GoalPriority.allCases, id: \.self) { priorityLevel in
                            HStack {
                                Circle()
                                    .fill(colorForPriority(priorityLevel))
                                    .frame(width: 12, height: 12)
                                Text(displayNameForPriority(priorityLevel))
                            }
                            .tag(priorityLevel)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(WebAppGoal.GoalStatus.allCases, id: \.self) { statusLevel in
                            Text(displayNameForStatus(statusLevel))
                                .tag(statusLevel)
                        }
                    }
                    
                } header: {
                    Text("Goal Details")
                }
                
                // Target Section
                Section {
                    HStack {
                        Text("Target")
                            .foregroundStyle(.secondary)
                        Text("₹")
                            .font(.title3)
                        TextField("Amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3.bold())
                    }
                    
                    DatePicker(
                        "Target date",
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    
                    HStack {
                        Text("Current")
                            .foregroundStyle(.secondary)
                        Text("₹")
                            .font(.title3)
                        TextField("Amount", text: $currentAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3.bold())
                    }
                    
                } header: {
                    Text("Target & Progress")
                }
                
                // Progress Visualization
                Section {
                    let progress = calculateProgress()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(progress))%")
                                .font(.title3.bold())
                                .foregroundStyle(progress >= 100 ? .green : .blue)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 12)
                                    .clipShape(Capsule())
                                
                                Rectangle()
                                    .fill(progress >= 100 ? Color.green : Color.blue)
                                    .frame(
                                        width: geometry.size.width * CGFloat(min(progress / 100, 1.0)),
                                        height: 12
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 12)
                        
                        if let target = Decimal(string: targetAmount),
                           let current = Decimal(string: currentAmount) {
                            let remaining = target - current
                            
                            if remaining > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Remaining: \(formatCurrency(remaining))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    if let monthlyRequired = calculateMonthlyRequired() {
                                        Text("Save \(formatCurrency(monthlyRequired))/month")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            } else {
                                Label("Goal achieved!", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                } header: {
                    Text("Progress Overview")
                }
                
                // Contributions Section
                Section {
                    Button {
                        showAddContribution = true
                    } label: {
                        Label("Add Contribution", systemImage: "plus.circle.fill")
                    }
                    
                    if !goal.contributions.isEmpty {
                        Button {
                            showContributionHistory = true
                        } label: {
                            HStack {
                                Label("Contribution History", systemImage: "list.bullet")
                                Spacer()
                                Text("\(goal.contributions.count)")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        // Recent contributions (last 3)
                        ForEach(goal.contributions.sorted(by: { $0.date > $1.date }).prefix(3)) { contribution in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatCurrency(contribution.amount))
                                        .font(.headline)
                                    if let notes = contribution.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(contribution.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No contributions yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                } header: {
                    Text("Contributions")
                }
                
                // Description Section
                Section {
                    TextField(
                        "Add description (optional)",
                        text: $goalDescription,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                } header: {
                    Text("Description")
                }
                
                // Goal Info
                Section {
                    LabeledContent {
                        Text(goal.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Created", systemImage: "calendar.badge.plus")
                    }
                    
                    LabeledContent {
                        Text(goal.updatedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Last Updated", systemImage: "clock")
                    }
                    
                } header: {
                    Text("Information")
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Goal", systemImage: "trash")
                    }
                } footer: {
                    Text("Deleting this goal will permanently remove it and all contribution history. This action cannot be undone.")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateGoal()
                        }
                    }
                    .disabled(!isFormValid || isLoading || !hasChanges)
                }
            }
            .sheet(isPresented: $showAddContribution) {
                addContributionSheet
            }
            .sheet(isPresented: $showContributionHistory) {
                contributionHistorySheet
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
            .confirmationDialog(
                "Delete Goal",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteGoal()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this goal and all contribution history? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Goal updated successfully")
            }
        }
    }
    
    // MARK: - Add Contribution Sheet
    
    @ViewBuilder
    private var addContributionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $contributionAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2.bold())
                    }
                    
                    DatePicker(
                        "Date",
                        selection: $contributionDate,
                        displayedComponents: .date
                    )
                    
                } header: {
                    Text("Contribution Details")
                }
                
                Section {
                    TextField(
                        "Notes (optional)",
                        text: $contributionNotes,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Add Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetContributionForm()
                        showAddContribution = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await addContribution()
                        }
                    }
                    .disabled(contributionAmount.isEmpty || Decimal(string: contributionAmount) == nil)
                }
            }
        }
    }
    
    // MARK: - Contribution History Sheet
    
    @ViewBuilder
    private var contributionHistorySheet: some View {
        NavigationStack {
            List {
                ForEach(goal.contributions.sorted(by: { $0.date > $1.date })) { contribution in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(formatCurrency(contribution.amount))
                                .font(.headline)
                            Spacer()
                            Text(contribution.date, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let notes = contribution.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Contribution History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showContributionHistory = false
                    }
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Decimal(string: targetAmount) != nil &&
        Decimal(string: currentAmount) != nil
    }
    
    private var hasChanges: Bool {
        guard let targetValue = Decimal(string: targetAmount),
              let currentValue = Decimal(string: currentAmount) else {
            return false
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalDescription = goal.goalDescription ?? ""
        
        return trimmedName != goal.name ||
               goalType != goal.goalType ||
               priority != goal.priority ||
               targetValue != goal.targetAmount ||
               targetDate != goal.targetDate ||
               currentValue != goal.currentAmount ||
               trimmedDescription != originalDescription ||
               status != goal.status
    }
    
    // MARK: - Actions
    
    private func updateGoal() async {
        guard isFormValid, hasChanges,
              let targetValue = Decimal(string: targetAmount),
              let currentValue = Decimal(string: currentAmount) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Update goal properties
            goal.name = trimmedName
            goal.goalType = goalType
            goal.priority = priority
            goal.targetAmount = targetValue
            goal.targetDate = targetDate
            goal.currentAmount = currentValue
            goal.goalDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
            goal.status = status
            goal.updatedAt = Date()
            
            // Save through repository
            try await viewModel.updateGoal(goal)
            
            isLoading = false
            showSuccess = true
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func addContribution() async {
        guard let amount = Decimal(string: contributionAmount) else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let notes = contributionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await viewModel.addContribution(
                to: goal,
                amount: amount,
                date: contributionDate,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Update current amount display
            currentAmount = goal.currentAmount.description
            
            isLoading = false
            resetContributionForm()
            showAddContribution = false
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteGoal() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await viewModel.deleteGoal(goal)
            isLoading = false
            dismiss()
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func resetContributionForm() {
        contributionAmount = ""
        contributionDate = Date()
        contributionNotes = ""
    }
    
    // MARK: - Helper Methods
    
    private func calculateProgress() -> Double {
        guard let target = Decimal(string: targetAmount),
              let current = Decimal(string: currentAmount),
              target > 0 else {
            return 0
        }
        
        let progress = (current / target) * 100
        return min(Double(truncating: progress as NSNumber), 100)
    }
    
    private func calculateMonthlyRequired() -> Decimal? {
        guard let target = Decimal(string: targetAmount),
              let current = Decimal(string: currentAmount) else {
            return nil
        }
        
        let remaining = target - current
        guard remaining > 0 else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: targetDate)
        guard let months = components.month, months > 0 else { return nil }
        
        return remaining / Decimal(months)
    }
    
    private func displayNameForType(_ type: WebAppGoal.GoalType) -> String {
        switch type {
        case .savings: return "Savings"
        case .investment: return "Investment"
        case .debtPayment: return "Debt Payment"
        case .emergency: return "Emergency Fund"
        case .retirement: return "Retirement"
        case .purchase: return "Purchase"
        case .education: return "Education"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }
    
    private func displayNameForPriority(_ priority: WebAppGoal.GoalPriority) -> String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    private func displayNameForStatus(_ status: WebAppGoal.GoalStatus) -> String {
        switch status {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
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
#Preview("Edit Goal") {
    let container = try! ModelContainer(
        for: WebAppGoal.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let goal = WebAppGoal(
        userId: "preview",
        name: "Emergency Fund",
        goalType: .emergency,
        targetAmount: 500000,
        targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
        currentAmount: 150000
    )
    goal.priority = .critical
    container.mainContext.insert(goal)
    
    return EditGoalView(
        goal: goal,
        modelContext: container.mainContext
    )
}
#endif
