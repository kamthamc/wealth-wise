//
//  NavigationCoordinator.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Navigation Coordinator - App Navigation Infrastructure
//

import Foundation
import SwiftUI
import Combine

/// Navigation coordinator for managing app navigation state
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var selectedTab: NavigationTab = .dashboard
    @Published public var navigationPath = NavigationPath()
    @Published public var showingSettings = false
    @Published public var showingNewPortfolio = false
    @Published public var showingNewAsset = false
    @Published public var showingNewTransaction = false
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific tab
    public func navigateTo(_ tab: NavigationTab) {
        selectedTab = tab
    }
    
    /// Push a new destination onto the navigation stack
    public func push(_ destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    /// Pop the current view from the navigation stack
    public func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// Pop to root view
    public func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    /// Show settings
    public func showSettings() {
        showingSettings = true
    }
    
    /// Show new portfolio sheet
    public func showNewPortfolio() {
        showingNewPortfolio = true
    }
    
    /// Show new asset sheet
    public func showNewAsset() {
        showingNewAsset = true
    }
    
    /// Show new transaction sheet
    public func showNewTransaction() {
        showingNewTransaction = true
    }
}

// MARK: - Navigation Tab

@available(iOS 18.6, macOS 15.6, *)
public enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard
    case portfolios
    case assets
    case transactions
    case reports
    case settings
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .portfolios: return "Portfolios"
        case .assets: return "Assets"
        case .transactions: return "Transactions"
        case .reports: return "Reports"
        case .settings: return "Settings"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .portfolios: return "folder.fill"
        case .assets: return "dollarsign.circle.fill"
        case .transactions: return "list.bullet.rectangle"
        case .reports: return "chart.bar.doc.horizontal"
        case .settings: return "gear"
        }
    }
}

// MARK: - Navigation Destination

@available(iOS 18.6, macOS 15.6, *)
public enum NavigationDestination: Hashable {
    case portfolioDetail(UUID)
    case assetDetail(UUID)
    case transactionDetail(UUID)
    case addPortfolio
    case addAsset
    case addTransaction
    case settings
}
