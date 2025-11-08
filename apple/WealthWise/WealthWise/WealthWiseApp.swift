//
//  WealthWiseApp.swift
//  WealthWise
//
//  Created by Chaitanya K Kamatham on 21/09/2025.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct WealthWiseApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            WebAppTransaction.self,
            Budget.self,
            WebAppGoal.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - ModelContainer Extension

extension ModelContainer {
    /// Shared ModelContainer instance for app-wide use
    /// Used by view models that need to create their own ModelContext
    static let shared: ModelContainer = {
        let schema = Schema([
            Account.self,
            WebAppTransaction.self,
            Budget.self,
            WebAppGoal.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()
}
