//
//  SuggestedTask.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-09.
//

import Foundation

struct SuggestedTask: Identifiable {
    var id: String { task.id ?? UUID().uuidString }
    let task: Task
    let matchReason: String
    let priorityScore: Double
    
    var displayReason: String {
        switch matchReason {
        case "high-energy-match":
            return "Perfect for your high energy!"
        case "any-energy":
            return "Good fit for any energy level"
        case "low-energy-match":
            return "Great when you're feeling low energy"
        case "medium-high-match":
            return "Good match for your energy"
        case "medium-low-match":
            return "Worth trying now"
        default:
            return "Recommended for you"
        }
    }
}
