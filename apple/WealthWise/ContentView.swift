import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("WealthWise")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("macOS Personal Finance App")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Project status
            VStack(alignment: .leading, spacing: 10) {
                Text("✅ macOS Project: Configured")
                
                Text("✅ SwiftUI Interface: Ready") 
                
                Text("✅ Currency System: Implemented")
                
                Text("⚙️ Project Build: In Progress")
                
                Text("📱 Ready for Development")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
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