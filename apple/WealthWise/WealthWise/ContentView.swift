//
//  ContentView.swift
//  WealthWise
//
//  Main content view with authentication flow
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    ContentView()
}
