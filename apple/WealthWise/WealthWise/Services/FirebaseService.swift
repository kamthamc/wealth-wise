//
//  FirebaseService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Firebase integration using Cloud Functions (matching webapp architecture)
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFunctions

/// Central Firebase service managing authentication and Cloud Functions
/// All database operations go through Cloud Functions, not direct Firestore access
/// Matches webapp architecture exactly
@MainActor
final class FirebaseService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FirebaseService()
    
    // MARK: - Properties
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isInitialized = false
    
    private let auth: Auth
    private let functions: Functions
    
    // MARK: - Initialization
    
    private init() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        self.auth = Auth.auth()
        self.functions = Functions.functions(region: "asia-south1") // Same region as webapp
        
        // Setup auth state listener
        setupAuthStateListener()
        
        isInitialized = true
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String? = nil) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Update profile with display name
        if let displayName = displayName {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
        }
        
        return result.user
    }
    
    /// Sign out current user
    func signOut() throws {
        try auth.signOut()
    }
    
    /// Reset password
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Cloud Functions Helper
    
    /// Call a Cloud Function with typed request/response
    private func callFunction<Request: Encodable, Response: Decodable>(
        name: String,
        data: Request
    ) async throws -> Response {
        let callable = functions.httpsCallable(name)
        let result = try await callable.call(data)
        
        guard let resultData = result.data as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        return try JSONDecoder().decode(Response.self, from: jsonData)
    }
    
    // MARK: - Account Operations (via Cloud Functions)
    
    /// Fetch all accounts for current user
    func fetchAccounts() async throws -> [AccountDTO] {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        struct Response: Codable {
            let accounts: [AccountDTO]
        }
        
        // Note: If there's a dedicated getAccounts function, use it
        // Otherwise, this might need to be implemented in Cloud Functions
        let response: Response = try await callFunction(name: "getAccounts", data: [:])
        return response.accounts
    }
    
    /// Create account via Cloud Function
    func createAccount(name: String, type: String, institution: String?, initialBalance: Double) async throws -> AccountDTO {
        struct Request: Codable {
            let name: String
            let type: String
            let institution: String?
            let balance: Double
        }
        
        struct Response: Codable {
            let account: AccountDTO
        }
        
        let request = Request(
            name: name,
            type: type,
            institution: institution,
            balance: initialBalance
        )
        
        let response: Response = try await callFunction(name: "createAccount", data: request)
        return response.account
    }
    
    /// Update account via Cloud Function
    func updateAccount(accountId: String, updates: [String: Any]) async throws -> AccountDTO {
        struct Response: Codable {
            let account: AccountDTO
        }
        
        var request: [String: Any] = ["accountId": accountId]
        request.merge(updates) { _, new in new }
        
        let callable = functions.httpsCallable("updateAccount")
        let result = try await callable.call(request)
        
        guard let resultData = result.data as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        let response = try JSONDecoder().decode(Response.self, from: jsonData)
        return response.account
    }
    
    /// Delete account via Cloud Function
    func deleteAccount(_ accountId: String) async throws {
        struct Request: Codable {
            let accountId: String
        }
        
        struct Response: Codable {
            let success: Bool
        }
        
        let _: Response = try await callFunction(
            name: "deleteAccount",
            data: Request(accountId: accountId)
        )
    }
    
    // MARK: - Transaction Operations (via Cloud Functions)
    
    /// Fetch transactions with optional filters
    func fetchTransactions(
        accountId: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: String? = nil
    ) async throws -> [TransactionDTO] {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        struct Request: Codable {
            let accountId: String?
            let startDate: String?
            let endDate: String?
            let category: String?
        }
        
        struct Response: Codable {
            let transactions: [TransactionDTO]
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let request = Request(
            accountId: accountId,
            startDate: startDate.map { dateFormatter.string(from: $0) },
            endDate: endDate.map { dateFormatter.string(from: $0) },
            category: category
        )
        
        let response: Response = try await callFunction(name: "getTransactions", data: request)
        return response.transactions
    }
    
    /// Create transaction via Cloud Function
    func createTransaction(
        accountId: String,
        date: Date,
        amount: Double,
        type: String,
        category: String,
        description: String,
        notes: String?
    ) async throws -> TransactionDTO {
        struct Request: Codable {
            let accountId: String
            let date: String
            let amount: Double
            let type: String
            let category: String
            let description: String
            let notes: String?
        }
        
        struct Response: Codable {
            let transaction: TransactionDTO
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let request = Request(
            accountId: accountId,
            date: dateFormatter.string(from: date),
            amount: amount,
            type: type,
            category: category,
            description: description,
            notes: notes
        )
        
        let response: Response = try await callFunction(name: "createTransaction", data: request)
        return response.transaction
    }
    
    /// Update transaction via Cloud Function
    func updateTransaction(transactionId: String, updates: [String: Any]) async throws -> TransactionDTO {
        struct Response: Codable {
            let transaction: TransactionDTO
        }
        
        var request: [String: Any] = ["transactionId": transactionId]
        request.merge(updates) { _, new in new }
        
        let callable = functions.httpsCallable("updateTransaction")
        let result = try await callable.call(request)
        
        guard let resultData = result.data as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        let response = try JSONDecoder().decode(Response.self, from: jsonData)
        return response.transaction
    }
    
    /// Delete transaction via Cloud Function
    func deleteTransaction(_ transactionId: String) async throws {
        struct Request: Codable {
            let transactionId: String
        }
        
        struct Response: Codable {
            let success: Bool
        }
        
        let _: Response = try await callFunction(
            name: "deleteTransaction",
            data: Request(transactionId: transactionId)
        )
    }
    
    /// Bulk delete transactions via Cloud Function
    func bulkDeleteTransactions(_ transactionIds: [String]) async throws {
        struct Request: Codable {
            let transactionIds: [String]
        }
        
        struct Response: Codable {
            let success: Bool
            let deletedCount: Int
        }
        
        let _: Response = try await callFunction(
            name: "bulkDeleteTransactions",
            data: Request(transactionIds: transactionIds)
        )
    }
    
    // MARK: - Budget Operations (via Cloud Functions)
    
    /// Fetch budgets for current user
    func fetchBudgets() async throws -> [BudgetDTO] {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        struct Response: Codable {
            let budgets: [BudgetDTO]
        }
        
        let response: Response = try await callFunction(name: "getBudgets", data: [:])
        return response.budgets
    }
    
    /// Create or update budget via Cloud Function (matches webapp createOrUpdateBudget)
    func createOrUpdateBudget(
        budgetId: String?,
        name: String,
        amount: Double,
        period: String,
        categories: [String],
        startDate: Date
    ) async throws -> BudgetDTO {
        struct Request: Codable {
            let budgetId: String?
            let name: String
            let amount: Double
            let period: String
            let categories: [String]
            let startDate: String
        }
        
        struct Response: Codable {
            let budget: BudgetDTO
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let request = Request(
            budgetId: budgetId,
            name: name,
            amount: amount,
            period: period,
            categories: categories,
            startDate: dateFormatter.string(from: startDate)
        )
        
        let response: Response = try await callFunction(name: "createOrUpdateBudget", data: request)
        return response.budget
    }
    
    /// Generate budget report via Cloud Function
    func generateBudgetReport(budgetId: String) async throws -> BudgetReportDTO {
        struct Request: Codable {
            let budgetId: String
        }
        
        let response: BudgetReportDTO = try await callFunction(
            name: "generateBudgetReport",
            data: Request(budgetId: budgetId)
        )
        return response
    }
    
    /// Delete budget via Cloud Function
    func deleteBudget(_ budgetId: String) async throws {
        struct Request: Codable {
            let budgetId: String
        }
        
        struct Response: Codable {
            let success: Bool
        }
        
        let _: Response = try await callFunction(
            name: "deleteBudget",
            data: Request(budgetId: budgetId)
        )
    }
    
    // MARK: - Goal Operations (via Cloud Functions)
    
    /// Fetch goals for current user
    func fetchGoals() async throws -> [GoalDTO] {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        struct Response: Codable {
            let goals: [GoalDTO]
        }
        
        let response: Response = try await callFunction(name: "getGoals", data: [:])
        return response.goals
    }
    
    /// Create or update goal via Cloud Function (matches webapp createOrUpdateGoal)
    func createOrUpdateGoal(
        goalId: String?,
        name: String,
        targetAmount: Double,
        targetDate: Date,
        type: String,
        priority: String
    ) async throws -> GoalDTO {
        struct Request: Codable {
            let goalId: String?
            let name: String
            let targetAmount: Double
            let targetDate: String
            let type: String
            let priority: String
        }
        
        struct Response: Codable {
            let goal: GoalDTO
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let request = Request(
            goalId: goalId,
            name: name,
            targetAmount: targetAmount,
            targetDate: dateFormatter.string(from: targetDate),
            type: type,
            priority: priority
        )
        
        let response: Response = try await callFunction(name: "createOrUpdateGoal", data: request)
        return response.goal
    }
    
    /// Add contribution to goal via Cloud Function
    func addGoalContribution(
        goalId: String,
        amount: Double,
        date: Date,
        note: String?
    ) async throws -> GoalDTO {
        struct Request: Codable {
            let goalId: String
            let amount: Double
            let date: String
            let note: String?
        }
        
        struct Response: Codable {
            let goal: GoalDTO
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let request = Request(
            goalId: goalId,
            amount: amount,
            date: dateFormatter.string(from: date),
            note: note
        )
        
        let response: Response = try await callFunction(name: "addGoalContribution", data: request)
        return response.goal
    }
    
    /// Delete goal via Cloud Function
    func deleteGoal(_ goalId: String) async throws {
        struct Request: Codable {
            let goalId: String
        }
        
        struct Response: Codable {
            let success: Bool
        }
        
        let _: Response = try await callFunction(
            name: "deleteGoal",
            data: Request(goalId: goalId)
        )
    }
    
    // MARK: - Balance Calculation (via Cloud Functions)
    
    /// Calculate balances via Cloud Function
    func calculateBalances() async throws -> BalanceResponseDTO {
        struct Response: Codable {
            let balances: BalanceResponseDTO
        }
        
        let response: Response = try await callFunction(name: "calculateBalances", data: [:])
        return response.balances
    }
}

// MARK: - Firebase Error

enum FirebaseError: LocalizedError {
    case notAuthenticated
    case invalidData
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return NSLocalizedString("error_not_authenticated", comment: "User not authenticated")
        case .invalidData:
            return NSLocalizedString("error_invalid_data", comment: "Invalid data format")
        case .networkError:
            return NSLocalizedString("error_network", comment: "Network connection failed")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Model Extensions for Firestore

extension Account {
    convenience init(from data: [String: Any], id: String) throws {
        guard
            let userId = data["userId"] as? String,
            let name = data["name"] as? String,
            let typeString = data["type"] as? String,
            let type = AccountType(rawValue: typeString),
            let balanceDouble = data["balance"] as? Double,
            let currency = data["currency"] as? String,
            let isArchived = data["isArchived"] as? Bool,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            throw FirebaseError.invalidData
        }
        
        self.init(
            id: UUID(uuidString: id) ?? UUID(),
            userId: userId,
            name: name,
            type: type,
            institution: data["institution"] as? String,
            currentBalance: Decimal(balanceDouble),
            currency: currency,
            isArchived: isArchived,
            createdAt: createdAt
        )
    }
}

extension WebAppTransaction {
    convenience init(from data: [String: Any], id: String) throws {
        guard
            let userId = data["userId"] as? String,
            let accountIdString = data["accountId"] as? String,
            let accountId = UUID(uuidString: accountIdString),
            let date = (data["date"] as? Timestamp)?.dateValue(),
            let amountDouble = data["amount"] as? Double,
            let typeString = data["type"] as? String,
            let type = TransactionType(rawValue: typeString),
            let category = data["category"] as? String,
            let description = data["description"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            throw FirebaseError.invalidData
        }
        
        self.init(
            id: UUID(uuidString: id) ?? UUID(),
            userId: userId,
            accountId: accountId,
            date: date,
            amount: Decimal(amountDouble),
            type: type,
            category: category,
            description: description,
            notes: data["notes"] as? String,
            createdAt: createdAt
        )
    }
}

extension Budget {
    convenience init(from data: [String: Any], id: String) throws {
        guard
            let userId = data["userId"] as? String,
            let name = data["name"] as? String,
            let amountDouble = data["amount"] as? Double,
            let periodString = data["period"] as? String,
            let period = BudgetPeriod(rawValue: periodString),
            let categories = data["categories"] as? [String],
            let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            throw FirebaseError.invalidData
        }
        
        self.init(
            id: UUID(uuidString: id) ?? UUID(),
            userId: userId,
            name: name,
            amount: Decimal(amountDouble),
            period: period,
            categories: categories,
            startDate: startDate,
            createdAt: createdAt
        )
    }
}

extension WebAppGoal {
    convenience init(from data: [String: Any], id: String) throws {
        guard
            let userId = data["userId"] as? String,
            let name = data["name"] as? String,
            let targetAmountDouble = data["targetAmount"] as? Double,
            let currentAmountDouble = data["currentAmount"] as? Double,
            let targetDate = (data["targetDate"] as? Timestamp)?.dateValue(),
            let typeString = data["type"] as? String,
            let type = GoalType(rawValue: typeString),
            let priorityString = data["priority"] as? String,
            let priority = GoalPriority(rawValue: priorityString),
            let statusString = data["status"] as? String,
            let status = GoalStatus(rawValue: statusString),
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            throw FirebaseError.invalidData
        }
        
        let goal = self.init(
            id: UUID(uuidString: id) ?? UUID(),
            userId: userId,
            name: name,
            targetAmount: Decimal(targetAmountDouble),
            currentAmount: Decimal(currentAmountDouble),
            targetDate: targetDate,
            type: type,
            priority: priority,
            status: status,
            createdAt: createdAt
        )
        
        // Parse contributions
        if let contributionsData = data["contributions"] as? [[String: Any]] {
            for contribData in contributionsData {
                if let idString = contribData["id"] as? String,
                   let amount = contribData["amount"] as? Double,
                   let date = (contribData["date"] as? Timestamp)?.dateValue() {
                    let contribution = Contribution(
                        id: UUID(uuidString: idString) ?? UUID(),
                        amount: Decimal(amount),
                        date: date,
                        note: contribData["note"] as? String
                    )
                    goal.contributions.append(contribution)
                }
            }
        }
        
        return goal
    }
}
