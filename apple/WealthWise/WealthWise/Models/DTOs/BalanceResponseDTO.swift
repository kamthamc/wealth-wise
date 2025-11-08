//
//  BalanceResponseDTO.swift
//  WealthWise
//
//  Data Transfer Object for balance calculation response from Cloud Functions
//

import Foundation

/// Response from calculateBalances Cloud Function
struct BalanceResponseDTO: Codable {
    let totalBalance: Double
    let accountBalances: [AccountBalance]
    let lastUpdated: String
    
    struct AccountBalance: Codable {
        let accountId: String
        let accountName: String
        let balance: Double
        let currency: String
    }
}
