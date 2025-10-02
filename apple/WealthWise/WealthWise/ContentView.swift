import SwiftUI

struct ContentView: View {
    var body: some View {
        if #available(iOS 18.6, macOS 15.6, *) {
            DashboardView()
        } else {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                Text(.generalAppName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Dashboard requires iOS 18.6+ or macOS 15.6+")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}