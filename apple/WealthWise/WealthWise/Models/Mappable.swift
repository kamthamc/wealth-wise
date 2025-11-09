//
//  Mappable.swift
//  WealthWise
//
//  Created by GitHub Copilot on 2025-11-09.
//

import Foundation

/// A protocol for objects that can be initialized from a Data Transfer Object (DTO).
protocol Mappable {
    associatedtype DTO
    
    /// Initializes the model object from a DTO.
    /// - Parameter dto: The Data Transfer Object.
    init(from dto: DTO)
}

// Example Usage:
// Let's assume you have a `BudgetDTO` and a `Budget` model.

/*
// In BudgetDTO.swift
struct BudgetDTO: Codable {
    let id: String
    let category: String
    let amount: Double
    // ... other properties from Firestore
}

// In Budget.swift (your Core Data model or internal app model)
class Budget: Mappable {
    typealias DTO = BudgetDTO
    
    var id: String
    var category: String
    var amount: Double
    
    required init(from dto: BudgetDTO) {
        self.id = dto.id
        self.category = dto.category
        self.amount = dto.amount
    }
}
*/
