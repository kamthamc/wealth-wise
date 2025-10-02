//
//  WealthWiseApp.swift
//  WealthWise
//
//  Created by Chaitanya K Kamatham on 21/09/2025.
//

import SwiftUI
import SwiftData

@main
struct WealthWiseApp: App {
    // MARK: - Service Container
    
    /// Dependency injection container for the application
    private let serviceContainer = ServiceContainer.shared
    
    // MARK: - Model Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Initialization
    
    init() {
        // Configure dependency injection container with default services
        Task { @MainActor in
            ServiceContainerConfiguration.configureDefaultServices(container: serviceContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Service Container Environment

/// Environment key for accessing service container
struct ServiceContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = .shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerEnvironmentKey.self] }
        set { self[ServiceContainerEnvironmentKey.self] = newValue }
    }
}

// MARK: - Example Usage View

/// Example view demonstrating service container usage
@available(iOS 18.6, macOS 15.6, *)
struct ServiceContainerExampleView: View {
    @Environment(\.serviceContainer) private var container
    
    @State private var persistenceStatus: String = NSLocalizedString("not_checked", comment: "Status not checked")
    @State private var securityStatus: String = NSLocalizedString("not_checked", comment: "Status not checked")
    @State private var marketStatus: String = NSLocalizedString("not_checked", comment: "Status not checked")
    
    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("service_container_demo", comment: "Service Container Demo"))
                .font(.largeTitle)
                .padding()
            
            GroupBox(NSLocalizedString("persistence_service", comment: "Persistence Service")) {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("status", comment: "Status: ") + persistenceStatus)
                    Button(NSLocalizedString("check_service", comment: "Check Service")) {
                        checkPersistenceService()
                    }
                }
            }
            
            GroupBox(NSLocalizedString("security_service", comment: "Security Service")) {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("status", comment: "Status: ") + securityStatus)
                    Button(NSLocalizedString("check_service", comment: "Check Service")) {
                        Task {
                            await checkSecurityService()
                        }
                    }
                }
            }
            
            GroupBox(NSLocalizedString("market_data_service", comment: "Market Data Service")) {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("status", comment: "Status: ") + marketStatus)
                    Button(NSLocalizedString("check_service", comment: "Check Service")) {
                        checkMarketDataService()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func checkPersistenceService() {
        do {
            let service = try container.resolve(PersistenceServiceProtocol.self)
            persistenceStatus = service.isLoaded ? 
                NSLocalizedString("loaded", comment: "Loaded") : 
                NSLocalizedString("not_loaded", comment: "Not Loaded")
        } catch {
            persistenceStatus = NSLocalizedString("error", comment: "Error: ") + error.localizedDescription
        }
    }
    
    private func checkSecurityService() async {
        do {
            let service = try container.resolve(SecurityServiceProtocol.self)
            let isValid = await service.validateDeviceSecurity()
            await MainActor.run {
                securityStatus = isValid ? 
                    NSLocalizedString("valid", comment: "Valid") : 
                    NSLocalizedString("invalid", comment: "Invalid")
            }
        } catch {
            await MainActor.run {
                securityStatus = NSLocalizedString("error", comment: "Error: ") + error.localizedDescription
            }
        }
    }
    
    private func checkMarketDataService() {
        do {
            let service = try container.resolve(MarketDataServiceProtocol.self)
            let currencies = service.getSupportedCurrencies()
            marketStatus = "\(currencies.count) " + NSLocalizedString("currencies_supported", comment: "currencies supported")
        } catch {
            marketStatus = NSLocalizedString("error", comment: "Error: ") + error.localizedDescription
        }
    }
}
