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
    var priorityLevel: Int     // 1 (highest) to 5 (lowest) - for ordering within must-do tasks
    var energyLevel: String    // "high", "low", "any"
    var estimatedDuration: TimeInterval  // Duration in seconds (e.g., 1800 for 30 min)
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: String? = nil, userId: String, title: String, 
         priority: String = "flexible", priorityLevel: Int = 3,
         energyLevel: String = "any",
         estimatedDuration: TimeInterval = 1800, // Default 30 minutes
         isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.priority = priority
        self.priorityLevel = priorityLevel
        self.energyLevel = energyLevel
        self.estimatedDuration = estimatedDuration
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
