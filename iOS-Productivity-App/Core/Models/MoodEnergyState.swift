//
//  MoodEnergyState.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-08.
//

import Foundation
import FirebaseFirestoreSwift

struct MoodEnergyState: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var energyLevel: String        // "high", "medium", "low"
    var moodDescription: String?   // Optional text description (future enhancement)
    var timestamp: Date
    
    var displayText: String {
        switch energyLevel.lowercased() {
        case "high": return "⚡️ High Energy"
        case "medium": return "🔋 Medium Energy"
        case "low": return "😴 Low Energy"
        default: return "🔋 Medium Energy"
        }
    }
    
    init(id: String? = nil, userId: String, energyLevel: String, 
         moodDescription: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.energyLevel = energyLevel
        self.moodDescription = moodDescription
        self.timestamp = timestamp
    }
}