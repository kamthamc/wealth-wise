//
//  EmptyStateView.swift
//  WealthWise
//
//  Reusable empty state component
//

import SwiftUI

struct EmptyStateView: View {
    
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon: "wallet.pass.fill",
        title: "No Accounts Yet",
        message: "Add your first account to start tracking your finances",
        actionTitle: "Add Account",
        action: {}
    )
}
