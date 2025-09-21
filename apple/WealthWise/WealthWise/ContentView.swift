import SwiftUI

struct ContentView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            // App name using new localization system
            Text(.generalAppName)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Modern Localization System")
                .font(.headline)
            
            // Demonstrate localized financial terms
            VStack(alignment: .leading, spacing: 10) {
                Text(.financialPortfolio)
                Text(.financialAssets)
                Text(.financialInvestment)
                Text(.financialReturns)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            
            // Demonstrate currency formatting
            VStack(alignment: .leading, spacing: 8) {
                Text("Currency Formatting:")
                    .font(.headline)
                
                Text(localizationManager.formatCurrency(12500.75, currencyCode: "INR"))
                Text(localizationManager.formatLargeNumber(1500000))
                Text(localizationManager.formatLargeNumber(25000000))
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            // Demonstrate asset types
            VStack(alignment: .leading, spacing: 5) {
                Text("Asset Types:")
                    .font(.headline)
                
                Text(.assetTypeStocks)
                Text(.assetTypeMutualFunds) 
                Text(.assetTypeRealEstate)
                Text(.assetTypePPF)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            print("WealthWise macOS: Project loaded successfully")
        }
    }
}

#Preview {
    ContentView()
}