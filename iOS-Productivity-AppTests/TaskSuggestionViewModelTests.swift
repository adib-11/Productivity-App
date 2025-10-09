//
//  TaskSuggestionViewModelTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import iOS_Productivity_App

@MainActor
class TaskSuggestionViewModelTests: XCTestCase {
    
    var viewModel: TaskSuggestionViewModel!
    var mockRepository: MockDataRepository!
    var mockEngine: MockTaskSuggestionEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockDataRepository()
        mockEngine = MockTaskSuggestionEngine()
        viewModel = TaskSuggestionViewModel(repository: mockRepository, suggestionEngine: mockEngine)
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockEngine = nil
        super.tearDown()
    }
    
    // MARK: - Test: Generate Suggestions with Matching Tasks
    
    func testGenerateSuggestions_WithMatchingTasks_PopulatesSuggestions() async {
        // Given
        let sampleTask = Task(
            id: "task1",
            userId: "user1",
            title: "High Energy Task",
            priority: "flexible",
            priorityLevel: 1,
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        let suggestedTask = SuggestedTask(
            task: sampleTask,
            matchReason: "high-energy-match",
            priorityScore: 3.5
        )
        
        mockRepository.mockFlexibleTasks = [sampleTask]
        mockEngine.mockSuggestedTasks = [suggestedTask]
        
        // When
        await viewModel.generateSuggestions(for: "high", scheduledTaskIds: [])
        
        // Then
        XCTAssertTrue(mockRepository.getFlexibleTasksCalled, "Should call getFlexibleTasks")
        XCTAssertTrue(mockEngine.suggestTasksCalled, "Should call suggestion engine")
        XCTAssertEqual(viewModel.suggestedTasks.count, 1, "Should populate suggested tasks")
        XCTAssertEqual(viewModel.suggestedTasks.first?.task.title, "High Energy Task")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertFalse(viewModel.showNoMatchMessage, "Should not show no match message")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message")
    }
    
    // MARK: - Test: No Matching Tasks Shows Message
    
    func testGenerateSuggestions_NoMatchingTasks_ShowsNoMatchMessage() async {
        // Given
        mockRepository.mockFlexibleTasks = []
        mockEngine.mockSuggestedTasks = []
        
        // When
        await viewModel.generateSuggestions(for: "low", scheduledTaskIds: [])
        
        // Then
        XCTAssertTrue(mockRepository.getFlexibleTasksCalled, "Should call getFlexibleTasks")
        XCTAssertTrue(mockEngine.suggestTasksCalled, "Should call suggestion engine")
        XCTAssertTrue(viewModel.showNoMatchMessage, "Should show no match message")
        XCTAssertTrue(viewModel.suggestedTasks.isEmpty, "Should have empty suggestions")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message")
    }
    
    // MARK: - Test: Error Handling
    
    func testGenerateSuggestions_HandlesError() async {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = DataRepositoryError.fetchFailed
        
        // When
        await viewModel.generateSuggestions(for: "medium", scheduledTaskIds: [])
        
        // Then
        XCTAssertTrue(mockRepository.getFlexibleTasksCalled, "Should call getFlexibleTasks")
        XCTAssertFalse(mockEngine.suggestTasksCalled, "Should not call engine if fetch fails")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        XCTAssertTrue(viewModel.suggestedTasks.isEmpty, "Should have empty suggestions on error")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
        XCTAssertFalse(viewModel.showNoMatchMessage, "Should not show no match message on error")
    }
    
    // MARK: - Test: Loading State Management
    
    func testGenerateSuggestions_LoadingState() async {
        // Given
        let sampleTask = Task(
            id: "task1",
            userId: "user1",
            title: "Sample Task",
            priority: "flexible",
            priorityLevel: 3,
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        mockRepository.mockFlexibleTasks = [sampleTask]
        mockEngine.mockSuggestedTasks = []
        
        // When - capture initial state before call
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        
        // Then - verify loading state is false after completion
        await viewModel.generateSuggestions(for: "high", scheduledTaskIds: [])
        
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }
    
    // MARK: - Test: Scheduled Task IDs Passed to Engine
    
    func testGenerateSuggestions_PassesScheduledTaskIds() async {
        // Given
        let scheduledIds: Set<String> = ["task1", "task2", "task3"]
        mockRepository.mockFlexibleTasks = []
        mockEngine.mockSuggestedTasks = []
        
        // When
        await viewModel.generateSuggestions(for: "medium", scheduledTaskIds: scheduledIds)
        
        // Then
        XCTAssertEqual(mockEngine.capturedScheduledTaskIds, scheduledIds, "Should pass scheduled task IDs to engine")
        XCTAssertEqual(mockEngine.capturedMoodEnergyLevel, "medium", "Should pass correct energy level to engine")
    }
    
    // MARK: - Test: Multiple Suggestions Populated
    
    func testGenerateSuggestions_MultipleSuggestions() async {
        // Given
        let task1 = Task(id: "1", userId: "user1", title: "Task 1", priority: "flexible", priorityLevel: 1, energyLevel: "high", isCompleted: false, createdAt: Date())
        let task2 = Task(id: "2", userId: "user1", title: "Task 2", priority: "flexible", priorityLevel: 2, energyLevel: "high", isCompleted: false, createdAt: Date())
        let task3 = Task(id: "3", userId: "user1", title: "Task 3", priority: "flexible", priorityLevel: 3, energyLevel: "any", isCompleted: false, createdAt: Date())
        
        let suggestions = [
            SuggestedTask(task: task1, matchReason: "high-energy-match", priorityScore: 4.0),
            SuggestedTask(task: task2, matchReason: "high-energy-match", priorityScore: 3.5),
            SuggestedTask(task: task3, matchReason: "any-energy", priorityScore: 3.0)
        ]
        
        mockRepository.mockFlexibleTasks = [task1, task2, task3]
        mockEngine.mockSuggestedTasks = suggestions
        
        // When
        await viewModel.generateSuggestions(for: "high", scheduledTaskIds: [])
        
        // Then
        XCTAssertEqual(viewModel.suggestedTasks.count, 3, "Should have all 3 suggestions")
        XCTAssertEqual(viewModel.suggestedTasks[0].task.title, "Task 1")
        XCTAssertEqual(viewModel.suggestedTasks[1].task.title, "Task 2")
        XCTAssertEqual(viewModel.suggestedTasks[2].task.title, "Task 3")
    }
}
