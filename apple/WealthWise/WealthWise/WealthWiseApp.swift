//
//  WealthWiseApp.swift
//  WealthWise
//
//  Created by Chaitanya K Kamatham on 21/09/2025.
//

import SwiftUI
import SwiftData

@available(iOS 18.6, macOS 15.6, *)
@main
struct WealthWiseApp: App {
    
    // MARK: - Service Container
    
    @StateObject private var serviceContainer = ServiceContainer.shared
    
    // MARK: - SwiftData Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Asset.self,
            Portfolio.self,
            Transaction.self,
            Goal.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            MenuCommands()
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

// MARK: - Menu Commands

@available(iOS 18.6, macOS 15.6, *)
struct MenuCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Portfolio") {
                // Action will be implemented
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Button("New Asset") {
                // Action will be implemented
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New Transaction") {
                // Action will be implemented
            }
            .keyboardShortcut("t", modifiers: .command)
        }
        
        CommandMenu("Portfolio") {
            Button("View All Portfolios") {
                // Action will be implemented
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Import Data...") {
                // Action will be implemented
            }
            .keyboardShortcut("i", modifiers: .command)
            
            Button("Export Data...") {
                // Action will be implemented
            }
            .keyboardShortcut("e", modifiers: .command)
        }
        
        CommandMenu("View") {
            Button("Dashboard") {
                // Action will be implemented
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Assets") {
                // Action will be implemented
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Transactions") {
                // Action will be implemented
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Button("Reports") {
                // Action will be implemented
            }
            .keyboardShortcut("4", modifiers: .command)
        }
    }
}

// MARK: - Settings View

@available(iOS 18.6, macOS 15.6, *)
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            SecuritySettingsView()
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }
            
            DataSettingsView()
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }
        }
        .frame(width: 500, height: 400)
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Text("Theme settings will be here")
            }
            
            Section(header: Text("Localization")) {
                Text("Language and region settings")
            }
        }
        .padding()
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct SecuritySettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Authentication")) {
                Text("Biometric and password settings")
            }
            
            Section(header: Text("Encryption")) {
                Text("Data encryption settings")
            }
        }
        .padding()
    }
}

@available(iOS 18.6, macOS 15.6, *)
struct DataSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Backup")) {
                Text("Backup and restore options")
            }
            
            Section(header: Text("Import/Export")) {
                Text("Data import and export settings")
            }
        }
        .padding()
    }
}
