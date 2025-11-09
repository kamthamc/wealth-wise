//
//  TransactionFilter.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Data models for advanced transaction filtering
//

import Foundation
import SwiftData

/// Represents filter criteria for transactions
struct TransactionFilter: Codable, Equatable {
    var name: String = ""
    var dateRange: DateRangeFilter = .all
    var amountRange: AmountRangeFilter?
    var categories: Set<String> = []
    var accountIds: Set<UUID> = []
    var transactionTypes: Set<WebAppTransaction.TransactionType> = []
    var searchText: String = ""
    
    /// Date range filter options
    enum DateRangeFilter: Codable, Equatable, CaseIterable {
        case all
        case today
        case yesterday
        case last7Days
        case last30Days
        case thisMonth
        case lastMonth
        case thisQuarter
        case lastQuarter
        case thisYear
        case lastYear
        case custom(start: Date, end: Date)
        
        var displayName: String {
            switch self {
            case .all: return "All Time"
            case .today: return "Today"
            case .yesterday: return "Yesterday"
            case .last7Days: return "Last 7 Days"
            case .last30Days: return "Last 30 Days"
            case .thisMonth: return "This Month"
            case .lastMonth: return "Last Month"
            case .thisQuarter: return "This Quarter"
            case .lastQuarter: return "Last Quarter"
            case .thisYear: return "This Year"
            case .lastYear: return "Last Year"
            case .custom: return "Custom Range"
            }
        }
        
        var dateRange: (start: Date, end: Date)? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .all:
                return nil
                
            case .today:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                return (start, end)
                
            case .yesterday:
                let start = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
                let end = calendar.startOfDay(for: now)
                return (start, end)
                
            case .last7Days:
                let start = calendar.date(byAdding: .day, value: -7, to: now)!
                return (start, now)
                
            case .last30Days:
                let start = calendar.date(byAdding: .day, value: -30, to: now)!
                return (start, now)
                
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                return (start, end)
                
            case .lastMonth:
                let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
                return (lastMonthStart, thisMonthStart)
                
            case .thisQuarter:
                let month = calendar.component(.month, from: now)
                let quarterStartMonth = ((month - 1) / 3) * 3 + 1
                var components = calendar.dateComponents([.year], from: now)
                components.month = quarterStartMonth
                components.day = 1
                let start = calendar.date(from: components)!
                let end = calendar.date(byAdding: .month, value: 3, to: start)!
                return (start, end)
                
            case .lastQuarter:
                let month = calendar.component(.month, from: now)
                let thisQuarterStartMonth = ((month - 1) / 3) * 3 + 1
                let lastQuarterStartMonth = thisQuarterStartMonth - 3
                var components = calendar.dateComponents([.year], from: now)
                components.month = lastQuarterStartMonth
                components.day = 1
                if lastQuarterStartMonth <= 0 {
                    components.year! -= 1
                    components.month = lastQuarterStartMonth + 12
                }
                let start = calendar.date(from: components)!
                let end = calendar.date(byAdding: .month, value: 3, to: start)!
                return (start, end)
                
            case .thisYear:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                let end = calendar.date(byAdding: .year, value: 1, to: start)!
                return (start, end)
                
            case .lastYear:
                let thisYearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
                let lastYearStart = calendar.date(byAdding: .year, value: -1, to: thisYearStart)!
                return (lastYearStart, thisYearStart)
                
            case .custom(let start, let end):
                return (start, end)
            }
        }
        
        static var allCases: [DateRangeFilter] {
            [.all, .today, .yesterday, .last7Days, .last30Days, .thisMonth, .lastMonth,
             .thisQuarter, .lastQuarter, .thisYear, .lastYear]
        }
    }
    
    /// Amount range filter
    struct AmountRangeFilter: Codable, Equatable {
        var minimum: Decimal
        var maximum: Decimal
        
        func matches(_ amount: Decimal) -> Bool {
            amount >= minimum && amount <= maximum
        }
    }
    
    /// Check if filter is active (has any criteria)
    var isActive: Bool {
        dateRange != .all ||
        amountRange != nil ||
        !categories.isEmpty ||
        !accountIds.isEmpty ||
        !transactionTypes.isEmpty ||
        !searchText.isEmpty
    }
    
    /// Check if transaction matches filter criteria
    func matches(_ transaction: WebAppTransaction) -> Bool {
        // Date range
        if let range = dateRange.dateRange {
            if transaction.date < range.start || transaction.date >= range.end {
                return false
            }
        }
        
        // Amount range
        if let amountRange = amountRange {
            if !amountRange.matches(transaction.amount) {
                return false
            }
        }
        
        // Categories
        if !categories.isEmpty && !categories.contains(transaction.category) {
            return false
        }
        
        // Accounts
        if !accountIds.isEmpty && !accountIds.contains(transaction.accountId) {
            return false
        }
        
        // Transaction types
        if !transactionTypes.isEmpty && !transactionTypes.contains(transaction.type) {
            return false
        }
        
        // Search text
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            let matchesDescription = transaction.description.lowercased().contains(lowercasedSearch)
            let matchesCategory = transaction.category.lowercased().contains(lowercasedSearch)
            let matchesNotes = transaction.notes?.lowercased().contains(lowercasedSearch) ?? false
            
            if !matchesDescription && !matchesCategory && !matchesNotes {
                return false
            }
        }
        
        return true
    }
    
    /// Reset filter to default state
    mutating func reset() {
        dateRange = .all
        amountRange = nil
        categories.removeAll()
        accountIds.removeAll()
        transactionTypes.removeAll()
        searchText = ""
    }
}

/// Saved filter preset
@Model
final class SavedFilter {
    var id: UUID
    var name: String
    var filterData: Data
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, filter: TransactionFilter) {
        self.id = UUID()
        self.name = name
        self.filterData = (try? JSONEncoder().encode(filter)) ?? Data()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var filter: TransactionFilter? {
        try? JSONDecoder().decode(TransactionFilter.self, from: filterData)
    }
    
    func updateFilter(_ filter: TransactionFilter) {
        self.filterData = (try? JSONEncoder().encode(filter)) ?? Data()
        self.updatedAt = Date()
    }
}

// MARK: - Codable Implementations

extension TransactionFilter.DateRangeFilter {
    enum CodingKeys: String, CodingKey {
        case type, startDate, endDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "all": self = .all
        case "today": self = .today
        case "yesterday": self = .yesterday
        case "last7Days": self = .last7Days
        case "last30Days": self = .last30Days
        case "thisMonth": self = .thisMonth
        case "lastMonth": self = .lastMonth
        case "thisQuarter": self = .thisQuarter
        case "lastQuarter": self = .lastQuarter
        case "thisYear": self = .thisYear
        case "lastYear": self = .lastYear
        case "custom":
            let start = try container.decode(Date.self, forKey: .startDate)
            let end = try container.decode(Date.self, forKey: .endDate)
            self = .custom(start: start, end: end)
        default:
            self = .all
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .all: try container.encode("all", forKey: .type)
        case .today: try container.encode("today", forKey: .type)
        case .yesterday: try container.encode("yesterday", forKey: .type)
        case .last7Days: try container.encode("last7Days", forKey: .type)
        case .last30Days: try container.encode("last30Days", forKey: .type)
        case .thisMonth: try container.encode("thisMonth", forKey: .type)
        case .lastMonth: try container.encode("lastMonth", forKey: .type)
        case .thisQuarter: try container.encode("thisQuarter", forKey: .type)
        case .lastQuarter: try container.encode("lastQuarter", forKey: .type)
        case .thisYear: try container.encode("thisYear", forKey: .type)
        case .lastYear: try container.encode("lastYear", forKey: .type)
        case .custom(let start, let end):
            try container.encode("custom", forKey: .type)
            try container.encode(start, forKey: .startDate)
            try container.encode(end, forKey: .endDate)
        }
    }
    
    static var allCases: [DateRangeFilter] {
        [.all, .today, .yesterday, .last7Days, .last30Days, .thisMonth, .lastMonth,
         .thisQuarter, .lastQuarter, .thisYear, .lastYear]
    }
}
