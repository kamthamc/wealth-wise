//
//  wealth_wiseApp.swift
//  wealth-wise
//
//  Created by Chaitanya K Kamatham on 15/09/2025.
//

import SwiftUI
import SwiftData

@main
struct wealth_wiseApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Asset.self,
            Portfolio.self,
            Transaction.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Configure services for production
        #if DEBUG
        ServiceConfiguration.configureForTesting()
        #else
        ServiceConfiguration.configureForProduction()
        #endif
        
        // Configure dependency injection
        setupDependencyInjection()
    }

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MacContentView()
                .withServiceContainer(serviceContainer)
            #else
            ContentView()
                .withServiceContainer(serviceContainer)
            #endif
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Private Methods
    
    private func setupDependencyInjection() {
        // Production services are configured in ServiceConfiguration
        // This is called in init() above based on DEBUG flag
    }
}
