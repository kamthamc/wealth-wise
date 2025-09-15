import Foundation
import SwiftUI
import Combine
import SwiftData

/// Example view model demonstrating dependency injection usage
@available(macOS 15.0, iOS 18.0, *)
@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Dependencies (Injected)
    
    @Injected private var dataService: DataServiceProtocol
    @Injected private var calculationService: CalculationServiceProtocol
    @Injected private var marketDataService: MarketDataServiceProtocol
    @Injected private var securityService: SecurityServiceProtocol
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    @Published var totalNetWorth: Decimal = 0
    @Published var portfolioValue: Decimal = 0
    @Published var realEstateValue: Decimal = 0
    @Published var cashAndDeposits: Decimal = 0
    
    @Published var recentTransactions: [Transaction] = []
    @Published var portfolios: [Portfolio] = []
    @Published var topPerformers: [Asset] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupDataSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Authenticate user and load dashboard data
    func authenticateAndLoad() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Authenticate user
            let authResult = try await securityService.authenticate()
            isAuthenticated = authResult.isSuccessful
            
            if isAuthenticated {
                await loadDashboardData()
            }
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    /// Refresh dashboard data
    func refreshData() async {
        guard isAuthenticated else { return }
        
        isLoading = true
        errorMessage = nil
        
        await loadDashboardData()
        
        isLoading = false
    }
    
    /// Add a new asset
    func addAsset(_ asset: Asset) async {
        do {
            try await dataService.save(asset)
            await refreshData()
        } catch {
            errorMessage = "Failed to add asset: \(error.localizedDescription)"
        }
    }
    
    /// Get market price for a symbol
    func getMarketPrice(for symbol: String) async -> Decimal? {
        do {
            let price = try await marketDataService.getCurrentPrice(for: symbol)
            return price?.value
        } catch {
            print("Failed to get price for \(symbol): \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func loadDashboardData() async {
        await withTaskGroup(of: Void.self) { group in
            // Load portfolios
            group.addTask { [weak self] in
                await self?.loadPortfolios()
            }
            
            // Load recent transactions
            group.addTask { [weak self] in
                await self?.loadRecentTransactions()
            }
            
            // Calculate portfolio values
            group.addTask { [weak self] in
                await self?.calculatePortfolioValues()
            }
            
            // Load top performers
            group.addTask { [weak self] in
                await self?.loadTopPerformers()
            }
        }
        
        // Calculate total net worth after all data is loaded
        calculateTotalNetWorth()
    }
    
    private func loadPortfolios() async {
        do {
            let portfolios = try await dataService.fetch(
                Portfolio.self,
                predicate: nil,
                sortBy: [SortDescriptor(\Portfolio.name)]
            )
            
            await MainActor.run {
                self.portfolios = portfolios
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load portfolios: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadRecentTransactions() async {
        do {
            let transactions = try await dataService.fetch(
                Transaction.self,
                predicate: nil,
                sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
            )
            
            await MainActor.run {
                self.recentTransactions = Array(transactions.prefix(5)) // Last 5 transactions
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load transactions: \(error.localizedDescription)"
            }
        }
    }
    
    private func calculatePortfolioValues() async {
        var totalPortfolioValue: Decimal = 0
        
        for portfolio in portfolios {
            do {
                let valuation = try await calculationService.calculatePortfolioValue(portfolio.id)
                totalPortfolioValue += valuation.totalValue
            } catch {
                print("Failed to calculate value for portfolio \(portfolio.id): \(error)")
            }
        }
        
        await MainActor.run {
            self.portfolioValue = totalPortfolioValue
        }
    }
    
    private func loadTopPerformers() async {
        do {
            let assets = try await dataService.fetch(
                Asset.self,
                predicate: nil,
                sortBy: [SortDescriptor(\Asset.currentValue, order: .reverse)]
            )
            
            await MainActor.run {
                self.topPerformers = Array(assets.prefix(3)) // Top 3 performers
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load top performers: \(error.localizedDescription)"
            }
        }
    }
    
    private func calculateTotalNetWorth() {
        // This would include all asset types: portfolios, real estate, cash, etc.
        totalNetWorth = portfolioValue + realEstateValue + cashAndDeposits
    }
    
    private func setupDataSubscriptions() {
        // Subscribe to data changes
        dataService.dataChangedPublisher
            .sink { [weak self] notification in
                Task { @MainActor in
                    // Refresh relevant data based on the change
                    switch notification.entityType {
                    case "Asset", "Portfolio", "Transaction":
                        await self?.refreshData()
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
}

/// Example usage in a SwiftUI view
@available(macOS 15.0, iOS 18.0, *)
struct EnhancedDashboardView: View {
    
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                if viewModel.isAuthenticated {
                    metricsSection
                    recentTransactionsSection
                    topPerformersSection
                } else {
                    authenticationSection
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .task {
            await viewModel.authenticateAndLoad()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var headerSection: some View {
        VStack {
            Text(L10n.Dashboard.title)
                .font(.largeTitle)
                .bold()
            
            if viewModel.isLoading {
                ProgressView("Loading...")
            }
        }
    }
    
    private var authenticationSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Authentication Required")
                .font(.title2)
                .bold()
            
            Text("Please authenticate to access your financial data")
                .foregroundColor(.secondary)
            
            Button("Authenticate") {
                Task {
                    await viewModel.authenticateAndLoad()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .cardGlassEffect()
    }
    
    private var metricsSection: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: L10n.Dashboard.netWorth,
                value: viewModel.totalNetWorth,
                color: .blue,
                systemImage: "chart.pie.fill"
            )
            
            MetricCard(
                title: L10n.Dashboard.portfolioValue,
                value: viewModel.portfolioValue,
                color: .green,
                systemImage: "chart.line.uptrend.xyaxis"
            )
            
            MetricCard(
                title: L10n.Dashboard.realEstate,
                value: viewModel.realEstateValue,
                color: .orange,
                systemImage: "house.fill"
            )
            
            MetricCard(
                title: L10n.Dashboard.cashDeposits,
                value: viewModel.cashAndDeposits,
                color: .purple,
                systemImage: "banknote.fill"
            )
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
            
            ForEach(viewModel.recentTransactions, id: \.id) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .cardGlassEffect()
    }
    
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
            
            ForEach(viewModel.topPerformers, id: \.id) { asset in
                AssetRow(asset: asset)
            }
        }
        .cardGlassEffect()
    }
}

struct MetricCard: View {
    let title: String
    let value: Decimal
    let color: Color
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("₹\(NSDecimalNumber(decimal: value).intValue)")
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .padding()
        .cardGlassEffect()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Transaction")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("₹\(NSDecimalNumber(decimal: transaction.amount).intValue)")
                    .font(.subheadline)
                    .bold()
            }
            
            Spacer()
            
            Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AssetRow: View {
    let asset: Asset
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(asset.name)
                    .font(.subheadline)
                    .bold()
                
                Text(asset.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("₹\(NSDecimalNumber(decimal: asset.currentValue).intValue)")
                .font(.subheadline)
                .bold()
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
@available(macOS 15.0, iOS 18.0, *)
#Preview("Enhanced Dashboard") {
    EnhancedDashboardView()
        .withServiceContainer()
}
#endif