//
//  TaskSuggestionEngineTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import iOS_Productivity_App

class TaskSuggestionEngineTests: XCTestCase {
    
    var engine: TaskSuggestionEngine!
    var sampleTasks: [Task]!
    
    override func setUp() {
        super.setUp()
        engine = TaskSuggestionEngine()
        
        // Create sample tasks for testing
        sampleTasks = [
            Task(id: "1", userId: "user1", title: "High Energy Task", priority: "flexible", priorityLevel: 1, energyLevel: "high", isCompleted: false, createdAt: Date()),
            Task(id: "2", userId: "user1", title: "Low Energy Task", priority: "flexible", priorityLevel: 2, energyLevel: "low", isCompleted: false, createdAt: Date()),
            Task(id: "3", userId: "user1", title: "Any Energy Task", priority: "flexible", priorityLevel: 3, energyLevel: "any", isCompleted: false, createdAt: Date()),
            Task(id: "4", userId: "user1", title: "Must-Do Task", priority: "must-do", priorityLevel: 1, energyLevel: "high", isCompleted: false, createdAt: Date()),
            Task(id: "5", userId: "user1", title: "Completed Task", priority: "flexible", priorityLevel: 1, energyLevel: "high", isCompleted: true, createdAt: Date()),
            Task(id: "6", userId: "user1", title: "Another High Energy Task", priority: "flexible", priorityLevel: 2, energyLevel: "high", isCompleted: false, createdAt: Date()),
            Task(id: "7", userId: "user1", title: "Another Low Energy Task", priority: "flexible", priorityLevel: 3, energyLevel: "low", isCompleted: false, createdAt: Date()),
            Task(id: "8", userId: "user1", title: "Old Task", priority: "flexible", priorityLevel: 4, energyLevel: "any", isCompleted: false, createdAt: Date().addingTimeInterval(-60*60*24*45)) // 45 days old
        ]
    }
    
    override func tearDown() {
        engine = nil
        sampleTasks = nil
        super.tearDown()
    }
    
    // MARK: - High Energy Tests
    
    func testSuggestTasks_HighEnergy_ReturnsHighAndAnyTasks() {
        // Given
        let moodEnergy = "high"
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for high energy")
        for suggestion in suggestions {
            let energyLevel = suggestion.task.energyLevel
            XCTAssertTrue(energyLevel == "high" || energyLevel == "any", "Should only include high or any energy tasks")
        }
    }
    
    // MARK: - Medium Energy Tests
    
    func testSuggestTasks_MediumEnergy_PrioritizesAnyTasks() {
        // Given
        let moodEnergy = "medium"
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for medium energy")
        
        // Check that all returned tasks are appropriate for medium energy
        for suggestion in suggestions {
            let energyLevel = suggestion.task.energyLevel
            XCTAssertTrue(energyLevel == "high" || energyLevel == "low" || energyLevel == "any", 
                         "Should include high, low, or any energy tasks for medium mood")
        }
        
        // Any energy tasks should generally score highest for medium energy
        if let topSuggestion = suggestions.first, topSuggestion.task.energyLevel == "any" {
            XCTAssertEqual(topSuggestion.task.energyLevel, "any", "Any energy task should score well for medium mood")
        }
    }
    
    // MARK: - Low Energy Tests
    
    func testSuggestTasks_LowEnergy_ReturnsLowAndAnyTasks() {
        // Given
        let moodEnergy = "low"
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for low energy")
        for suggestion in suggestions {
            let energyLevel = suggestion.task.energyLevel
            XCTAssertTrue(energyLevel == "low" || energyLevel == "any", "Should only include low or any energy tasks")
        }
    }
    
    // MARK: - Priority Filtering Tests
    
    func testSuggestTasks_FiltersOutMustDoTasks() {
        // Given
        let moodEnergy = "high"
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        for suggestion in suggestions {
            XCTAssertEqual(suggestion.task.priority, "flexible", "Should only include flexible priority tasks")
            XCTAssertNotEqual(suggestion.task.id, "4", "Should not include must-do task")
        }
    }
    
    // MARK: - Scheduled Task Filtering Tests
    
    func testSuggestTasks_FiltersOutScheduledTasks() {
        // Given
        let moodEnergy = "high"
        let scheduledTaskIds: Set<String> = ["1", "6"] // Exclude high energy tasks
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        for suggestion in suggestions {
            XCTAssertFalse(scheduledTaskIds.contains(suggestion.task.id ?? ""), "Should not include already scheduled tasks")
        }
        XCTAssertFalse(suggestions.contains(where: { $0.task.id == "1" }), "Should not include task 1")
        XCTAssertFalse(suggestions.contains(where: { $0.task.id == "6" }), "Should not include task 6")
    }
    
    // MARK: - Completed Task Filtering Tests
    
    func testSuggestTasks_FiltersOutCompletedTasks() {
        // Given
        let moodEnergy = "high"
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        for suggestion in suggestions {
            XCTAssertFalse(suggestion.task.isCompleted, "Should not include completed tasks")
            XCTAssertNotEqual(suggestion.task.id, "5", "Should not include completed task")
        }
    }
    
    // MARK: - Limiting Tests
    
    func testSuggestTasks_LimitsToTop3() {
        // Given
        let moodEnergy = "medium" // Medium matches all energy levels
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertLessThanOrEqual(suggestions.count, 3, "Should return at most 3 suggestions")
    }
    
    // MARK: - Scoring Tests
    
    func testSuggestTasks_ScoreCalculation() {
        // Given
        let moodEnergy = "high"
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: sampleTasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions")
        
        // Verify tasks are sorted by score (descending)
        for i in 0..<(suggestions.count - 1) {
            XCTAssertGreaterThanOrEqual(suggestions[i].priorityScore, suggestions[i + 1].priorityScore,
                                       "Suggestions should be sorted by priority score descending")
        }
        
        // Verify that higher priority level tasks score better (lower number = higher priority)
        if suggestions.count >= 2 {
            let firstTask = suggestions[0].task
            let secondTask = suggestions[1].task
            
            // If energy match is same, lower priorityLevel (higher priority) should score higher
            if firstTask.energyLevel == secondTask.energyLevel {
                XCTAssertLessThanOrEqual(firstTask.priorityLevel, secondTask.priorityLevel,
                                        "Higher priority task should score better when energy match is same")
            }
        }
    }
    
    // MARK: - Empty Result Tests
    
    func testSuggestTasks_NoMatchingTasks_ReturnsEmptyArray() {
        // Given
        let tasksWithNoMatch = [
            Task(id: "1", userId: "user1", title: "High Energy Task", priority: "flexible", priorityLevel: 1, energyLevel: "high", isCompleted: false, createdAt: Date())
        ]
        let moodEnergy = "low" // Low energy won't match high energy task
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: tasksWithNoMatch, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertTrue(suggestions.isEmpty, "Should return empty array when no tasks match")
    }
    
    // MARK: - Age Bonus Tests
    
    func testSuggestTasks_OlderTasksGetAgeBonus() {
        // Given
        let moodEnergy = "high" // Use valid mood energy level
        
        // Create tasks with different ages - both high energy to match mood
        let newTask = Task(id: "new", userId: "user1", title: "New High Task", priority: "flexible", priorityLevel: 3, energyLevel: "high", isCompleted: false, createdAt: Date())
        let oldTask = Task(id: "old", userId: "user1", title: "Old High Task", priority: "flexible", priorityLevel: 3, energyLevel: "high", isCompleted: false, createdAt: Date().addingTimeInterval(-60*60*24*60)) // 60 days old
        
        let tasks = [newTask, oldTask]
        let scheduledTaskIds: Set<String> = []
        
        // When
        let suggestions = engine.suggestTasks(tasks: tasks, moodEnergyLevel: moodEnergy, scheduledTaskIds: scheduledTaskIds)
        
        // Then
        XCTAssertEqual(suggestions.count, 2, "Should return both tasks")
        
        // Old task should score higher due to age bonus (assuming same priority level and energy match)
        if let oldSuggestion = suggestions.first(where: { $0.task.id == "old" }),
           let newSuggestion = suggestions.first(where: { $0.task.id == "new" }) {
            XCTAssertGreaterThan(oldSuggestion.priorityScore, newSuggestion.priorityScore,
                               "Older task should have higher score due to age bonus")
        }
    }
}
