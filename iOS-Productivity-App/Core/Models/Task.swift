//
//  Task.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation
import FirebaseFirestoreSwift

struct Task: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var priority: String       // "must-do" or "flexible"
    var energyLevel: String    // "high", "low", "any"
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: String? = nil, userId: String, title: String, 
         priority: String = "flexible", energyLevel: String = "any", 
         isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.priority = priority
        self.energyLevel = energyLevel
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
