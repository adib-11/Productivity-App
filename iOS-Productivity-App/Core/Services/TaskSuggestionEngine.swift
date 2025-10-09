//
//  TaskSuggestionEngine.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-09.
//

import Foundation

class TaskSuggestionEngine {
    
    func suggestTasks(
        tasks: [Task],
        moodEnergyLevel: String,
        scheduledTaskIds: Set<String>
    ) -> [SuggestedTask] {
        
        // Step 1: Filter for flexible priority tasks only
        let flexibleTasks = tasks.filter { $0.priority == "flexible" }
        
        // Step 2: Filter out completed tasks
        let incompleteTasks = flexibleTasks.filter { !$0.isCompleted }
        
        // Step 3: Filter out already scheduled tasks
        let unscheduledTasks = incompleteTasks.filter { task in
            guard let taskId = task.id else { return false }
            return !scheduledTaskIds.contains(taskId)
        }
        
        // Step 4: Filter and score by energy level match
        let matchedTasks = unscheduledTasks.compactMap { task -> SuggestedTask? in
            guard let energyMatchScore = calculateEnergyMatchScore(
                taskEnergyLevel: task.energyLevel,
                moodEnergyLevel: moodEnergyLevel
            ) else {
                return nil // Task doesn't match mood
            }
            
            let matchReason = determineMatchReason(
                taskEnergyLevel: task.energyLevel,
                moodEnergyLevel: moodEnergyLevel
            )
            
            let priorityScore = calculatePriorityScore(
                task: task,
                energyMatchScore: energyMatchScore
            )
            
            return SuggestedTask(
                task: task,
                matchReason: matchReason,
                priorityScore: priorityScore
            )
        }
        
        // Step 5: Sort by priority score descending
        let sortedTasks = matchedTasks.sorted { $0.priorityScore > $1.priorityScore }
        
        // Step 6: Limit to top 3
        return Array(sortedTasks.prefix(3))
    }
    
    private func calculateEnergyMatchScore(
        taskEnergyLevel: String,
        moodEnergyLevel: String
    ) -> Double? {
        switch moodEnergyLevel {
        case "high":
            switch taskEnergyLevel {
            case "high": return 1.0
            case "any": return 0.7
            default: return nil
            }
        case "medium":
            switch taskEnergyLevel {
            case "any": return 1.0
            case "high": return 0.8
            case "low": return 0.6
            default: return nil
            }
        case "low":
            switch taskEnergyLevel {
            case "low": return 1.0
            case "any": return 0.7
            default: return nil
            }
        default:
            return nil
        }
    }
    
    private func determineMatchReason(
        taskEnergyLevel: String,
        moodEnergyLevel: String
    ) -> String {
        if taskEnergyLevel == "any" {
            return "any-energy"
        }
        
        switch moodEnergyLevel {
        case "high":
            return taskEnergyLevel == "high" ? "high-energy-match" : "any-energy"
        case "medium":
            if taskEnergyLevel == "high" {
                return "medium-high-match"
            } else if taskEnergyLevel == "low" {
                return "medium-low-match"
            }
            return "any-energy"
        case "low":
            return taskEnergyLevel == "low" ? "low-energy-match" : "any-energy"
        default:
            return "any-energy"
        }
    }
    
    private func calculatePriorityScore(
        task: Task,
        energyMatchScore: Double
    ) -> Double {
        // Energy match score weighted by 2
        let energyComponent = energyMatchScore * 2.0
        
        // Priority level: Level 1 = 2.5, Level 2 = 2.0, Level 3 = 1.5, Level 4 = 1.0, Level 5 = 0.5
        let priorityWeight = 3.0 - (Double(task.priorityLevel) / 2.0)
        
        // Age bonus: max 0.5 for tasks 30+ days old
        let daysSinceCreation = Date().timeIntervalSince(task.createdAt) / 86400.0 // Convert to days
        let ageBonus = min(0.5, daysSinceCreation / 30.0)
        
        return energyComponent + priorityWeight + ageBonus
    }
}
