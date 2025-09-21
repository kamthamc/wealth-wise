//
//  Item.swift
//  WealthWise
//
//  Created by Chaitanya K Kamatham on 21/09/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
