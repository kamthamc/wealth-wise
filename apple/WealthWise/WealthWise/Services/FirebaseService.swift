//
//  FirebaseService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Firebase integration wrapper for authentication and Firestore
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Central Firebase service managing authentication and Firestore operations
/// Provides a clean interface for Firebase operations matching webapp implementation
@MainActor
final class FirebaseService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FirebaseService()
    
    // MARK: - Properties
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isInitialized = false
    
    private let auth: Auth
    private let firestore: Firestore
    
    // MARK: - Collections
    
    private var accountsCollection: CollectionReference {
        firestore.collection("accounts")
    }
    
    private var transactionsCollection: CollectionReference {
        firestore.collection("transactions")
    }
    
    private var budgetsCollection: CollectionReference {
        firestore.collection("budgets")
    }
    
    private var goalsCollection: CollectionReference {
        firestore.collection("goals")
    }
    
    private var usersCollection: CollectionReference {
        firestore.collection("users")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        firestore.settings = settings
        
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
        
        // Create user document in Firestore
        try await createUserDocument(userId: result.user.uid, email: email, displayName: displayName)
        
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
    
    /// Create user document in Firestore
    private func createUserDocument(userId: String, email: String, displayName: String?) async throws {
        let userData: [String: Any] = [
            "email": email,
            "displayName": displayName ?? "",
            "locale": Locale.current.identifier,
            "currency": "INR",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await usersCollection.document(userId).setData(userData)
    }
    
    // MARK: - Account Operations
    
    /// Fetch all accounts for current user
    func fetchAccounts() async throws -> [Account] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notAuthenticated
        }
        
        let snapshot = try await accountsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try Account(from: doc.data(), id: doc.documentID)
        }
    }
    
    /// Create or update account
    func saveAccount(_ account: Account) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = accountsCollection.document(account.id.uuidString)
        try await docRef.setData(account.toFirestore(), merge: true)
    }
    
    /// Delete account
    func deleteAccount(_ accountId: UUID) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        try await accountsCollection.document(accountId.uuidString).delete()
    }
    
    // MARK: - Transaction Operations
    
    /// Fetch transactions for user with optional filters
    func fetchTransactions(
        accountId: UUID? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: String? = nil
    ) async throws -> [WebAppTransaction] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notAuthenticated
        }
        
        var query: Query = transactionsCollection
            .whereField("userId", isEqualTo: userId)
        
        if let accountId = accountId {
            query = query.whereField("accountId", isEqualTo: accountId.uuidString)
        }
        
        if let category = category {
            query = query.whereField("category", isEqualTo: category)
        }
        
        query = query.order(by: "date", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        var transactions = try snapshot.documents.compactMap { doc in
            try WebAppTransaction(from: doc.data(), id: doc.documentID)
        }
        
        // Filter by date range if specified
        if let startDate = startDate {
            transactions = transactions.filter { $0.date >= startDate }
        }
        if let endDate = endDate {
            transactions = transactions.filter { $0.date <= endDate }
        }
        
        return transactions
    }
    
    /// Save transaction
    func saveTransaction(_ transaction: WebAppTransaction) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = transactionsCollection.document(transaction.id.uuidString)
        try await docRef.setData(transaction.toFirestore(), merge: true)
    }
    
    /// Delete transaction
    func deleteTransaction(_ transactionId: UUID) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        try await transactionsCollection.document(transactionId.uuidString).delete()
    }
    
    /// Bulk delete transactions
    func bulkDeleteTransactions(_ transactionIds: [UUID]) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        let batch = firestore.batch()
        
        for id in transactionIds {
            let docRef = transactionsCollection.document(id.uuidString)
            batch.deleteDocument(docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Budget Operations
    
    /// Fetch budgets for current user
    func fetchBudgets() async throws -> [Budget] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notAuthenticated
        }
        
        let snapshot = try await budgetsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try Budget(from: doc.data(), id: doc.documentID)
        }
    }
    
    /// Save budget
    func saveBudget(_ budget: Budget) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = budgetsCollection.document(budget.id.uuidString)
        try await docRef.setData(budget.toFirestore(), merge: true)
    }
    
    /// Delete budget
    func deleteBudget(_ budgetId: UUID) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        try await budgetsCollection.document(budgetId.uuidString).delete()
    }
    
    // MARK: - Goal Operations
    
    /// Fetch goals for current user
    func fetchGoals() async throws -> [WebAppGoal] {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notAuthenticated
        }
        
        let snapshot = try await goalsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try WebAppGoal(from: doc.data(), id: doc.documentID)
        }
    }
    
    /// Save goal
    func saveGoal(_ goal: WebAppGoal) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        let docRef = goalsCollection.document(goal.id.uuidString)
        try await docRef.setData(goal.toFirestore(), merge: true)
    }
    
    /// Delete goal
    func deleteGoal(_ goalId: UUID) async throws {
        guard currentUser != nil else {
            throw FirebaseError.notAuthenticated
        }
        
        try await goalsCollection.document(goalId.uuidString).delete()
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
