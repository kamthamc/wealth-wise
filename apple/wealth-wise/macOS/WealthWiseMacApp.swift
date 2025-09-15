import SwiftUI
import SwiftData

@main
struct WealthWiseMacApp: App {
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .withServiceContainer(serviceContainer)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            WealthWiseMenuCommands()
        }
        .modelContainer(sharedModelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

// MARK: - Menu Commands
struct WealthWiseMenuCommands: Commands {
    var body: some Commands {
        // File Menu
        CommandGroup(after: .newItem) {
            Button(L10n.Menu.File.import) {
                // TODO: Implement data import
                print("Import Data selected")
            }
            .keyboardShortcut("I", modifiers: [.command, .shift])
            
            Button(L10n.Menu.File.export) {
                // TODO: Implement data export
                print("Export Data selected")
            }
            .keyboardShortcut("E", modifiers: [.command, .shift])
        }
        
        // View Menu
        CommandMenu(L10n.Nav.dashboard) {
            Button(L10n.Menu.View.dashboard) {
                // TODO: Navigate to dashboard
                NavigationManager.shared.navigateTo(.dashboard)
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button(L10n.Menu.View.portfolio) {
                // TODO: Navigate to portfolio
                NavigationManager.shared.navigateTo(.portfolio)
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button(L10n.Menu.View.assets) {
                // TODO: Navigate to assets
                NavigationManager.shared.navigateTo(.assets)
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Divider()
            
            Button(L10n.Menu.View.reports) {
                // TODO: Navigate to reports
                NavigationManager.shared.navigateTo(.reports)
            }
            .keyboardShortcut("R", modifiers: .command)
        }
        
        // Tools Menu
        CommandMenu("Tools") {
            Button(L10n.Menu.Tools.security) {
                // TODO: Open security settings
                print("Security Settings selected")
            }
            
            Button(L10n.Menu.Tools.backup) {
                // TODO: Open backup/restore dialog
                print("Backup & Restore selected")
            }
        }
    }
}

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var currentView: AppView = .dashboard
    
    enum AppView {
        case dashboard
        case portfolio
        case assets
        case reports
        case settings
    }
    
    private init() {}
    
    func navigateTo(_ view: AppView) {
        currentView = view
    }
}