//
//  SettingsView.swift
//  WealthWise
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Text(authManager.currentUser?.displayName?.prefix(1).uppercased() ?? "W")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.displayName ?? NSLocalizedString("user", comment: "User"))
                                .font(.headline)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // General Settings
                Section(NSLocalizedString("general", comment: "General")) {
                    NavigationLink {
                        Text("Profile Settings")
                    } label: {
                        Label(NSLocalizedString("profile", comment: "Profile"), systemImage: "person.fill")
                    }
                    
                    NavigationLink {
                        Text("Currency Settings")
                    } label: {
                        Label(NSLocalizedString("currency", comment: "Currency"), systemImage: "indianrupeesign.circle.fill")
                    }
                    
                    NavigationLink {
                        Text("Language Settings")
                    } label: {
                        Label(NSLocalizedString("language", comment: "Language"), systemImage: "globe")
                    }
                }
                
                // Preferences
                Section(NSLocalizedString("preferences", comment: "Preferences")) {
                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label(NSLocalizedString("notifications", comment: "Notifications"), systemImage: "bell.fill")
                    }
                    
                    NavigationLink {
                        Text("Appearance")
                    } label: {
                        Label(NSLocalizedString("appearance", comment: "Appearance"), systemImage: "paintbrush.fill")
                    }
                }
                
                // Data & Privacy
                Section(NSLocalizedString("data_privacy", comment: "Data & Privacy")) {
                    NavigationLink {
                        Text("Export Data")
                    } label: {
                        Label(NSLocalizedString("export_data", comment: "Export Data"), systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink {
                        Text("Privacy Settings")
                    } label: {
                        Label(NSLocalizedString("privacy", comment: "Privacy"), systemImage: "lock.fill")
                    }
                }
                
                // About
                Section(NSLocalizedString("about", comment: "About")) {
                    HStack {
                        Text(NSLocalizedString("version", comment: "Version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink {
                        Text("Terms & Conditions")
                    } label: {
                        Label(NSLocalizedString("terms", comment: "Terms & Conditions"), systemImage: "doc.text.fill")
                    }
                    
                    NavigationLink {
                        Text("Privacy Policy")
                    } label: {
                        Label(NSLocalizedString("privacy_policy", comment: "Privacy Policy"), systemImage: "hand.raised.fill")
                    }
                }
                
                // Sign Out
                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label(NSLocalizedString("sign_out", comment: "Sign Out"), systemImage: "arrow.right.square.fill")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings", comment: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("done", comment: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
