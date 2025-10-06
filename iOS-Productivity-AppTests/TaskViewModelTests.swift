//
//  TaskViewModelTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import XCTest
@testable import iOS_Productivity_App

@MainActor
final class TaskViewModelTests: XCTestCase {
    
    var viewModel: TaskViewModel!
    var mockRepository: MockDataRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockDataRepository()
        viewModel = TaskViewModel(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Validation Tests
    
    func testValidateInput_WithEmptyTitle_ReturnsFalse() {
        // Given
        viewModel.title = ""
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testValidateInput_WithWhitespaceOnlyTitle_ReturnsFalse() {
        // Given
        viewModel.title = "   "
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testValidateInput_WithValidTitle_ReturnsTrue() {
        // Given
        viewModel.title = "Study for Midterm"
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Create Task Tests
    
    func testCreateTask_WithValidInput_Success() async {
        // Given
        viewModel.title = "Study for Midterm"
        viewModel.priority = "must-do"
        viewModel.energyLevel = "high"
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.createTask()
        
        // Then
        XCTAssertTrue(mockRepository.createTaskCalled)
        XCTAssertEqual(mockRepository.capturedTask?.title, "Study for Midterm")
        XCTAssertEqual(mockRepository.capturedTask?.priority, "must-do")
        XCTAssertEqual(mockRepository.capturedTask?.energyLevel, "high")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCreateTask_WithEmptyTitle_ValidationFails() async {
        // Given
        viewModel.title = ""
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.createTask()
        
        // Then
        XCTAssertFalse(mockRepository.createTaskCalled)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testCreateTask_WithRepositoryError_ShowsError() async {
        // Given
        viewModel.title = "Study for Midterm"
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.saveFailed
        
        // When
        await viewModel.createTask()
        
        // Then
        XCTAssertTrue(mockRepository.createTaskCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCreateTask_ResetsFormOnSuccess() async {
        // Given
        viewModel.title = "Study for Midterm"
        viewModel.priority = "must-do"
        viewModel.energyLevel = "high"
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.createTask()
        
        // Then
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.priority, "flexible")
        XCTAssertEqual(viewModel.energyLevel, "any")
        XCTAssertNil(viewModel.editingTask)
    }
    
    // MARK: - Load Tasks Tests
    
    func testLoadTasks_Success_PopulatesTasks() async {
        // Given
        let task1 = Task(userId: "user1", title: "Task 1", priority: "flexible", energyLevel: "any")
        let task2 = Task(userId: "user1", title: "Task 2", priority: "must-do", energyLevel: "high")
        mockRepository.tasksToReturn = [task1, task2]
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.loadTasks()
        
        // Then
        XCTAssertTrue(mockRepository.fetchTasksCalled)
        XCTAssertEqual(viewModel.tasks.count, 2)
        XCTAssertEqual(viewModel.tasks[0].title, "Task 1")
        XCTAssertEqual(viewModel.tasks[1].title, "Task 2")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadTasks_WithError_ShowsError() async {
        // Given
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.fetchFailed
        
        // When
        await viewModel.loadTasks()
        
        // Then
        XCTAssertTrue(mockRepository.fetchTasksCalled)
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadTasks_SetsLoadingState() async {
        // Given
        mockRepository.shouldSucceed = true
        mockRepository.tasksToReturn = []
        
        // Track loading state during execution
        var loadingStates: [Bool] = []
        let expectation = expectation(description: "Loading states tracked")
        
        // When
        _Concurrency.Task {
            loadingStates.append(viewModel.isLoading) // Should be false initially
            await viewModel.loadTasks()
            loadingStates.append(viewModel.isLoading) // Should be false after completion
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertEqual(loadingStates.first, false)
        XCTAssertEqual(loadingStates.last, false)
    }
    
    // MARK: - Delete Task Tests
    
    func testDeleteTask_Success_RemovesTask() async {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Task to Delete", priority: "flexible", energyLevel: "any")
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.deleteTask(task)
        
        // Then
        XCTAssertTrue(mockRepository.deleteTaskCalled)
        XCTAssertEqual(mockRepository.capturedTaskId, "task1")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteTask_WithoutID_ShowsError() async {
        // Given
        let task = Task(id: nil, userId: "user1", title: "Task without ID", priority: "flexible", energyLevel: "any")
        
        // When
        await viewModel.deleteTask(task)
        
        // Then
        XCTAssertFalse(mockRepository.deleteTaskCalled)
        XCTAssertEqual(viewModel.errorMessage, "Cannot delete task without ID.")
    }
    
    func testDeleteTask_WithRepositoryError_ShowsError() async {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Task to Delete", priority: "flexible", energyLevel: "any")
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.deleteFailed
        
        // When
        await viewModel.deleteTask(task)
        
        // Then
        XCTAssertTrue(mockRepository.deleteTaskCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Toggle Task Completion Tests
    
    func testToggleTaskCompletion_TogglesState() async {
        // Given
        var task = Task(id: "task1", userId: "user1", title: "Task", priority: "flexible", energyLevel: "any")
        task.isCompleted = false
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.toggleTaskCompletion(task)
        
        // Then
        XCTAssertTrue(mockRepository.updateTaskCalled)
        XCTAssertEqual(mockRepository.capturedUpdatedTask?.isCompleted, true)
    }
    
    func testToggleTaskCompletion_FromTrueToFalse() async {
        // Given
        var task = Task(id: "task1", userId: "user1", title: "Task", priority: "flexible", energyLevel: "any")
        task.isCompleted = true
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.toggleTaskCompletion(task)
        
        // Then
        XCTAssertTrue(mockRepository.updateTaskCalled)
        XCTAssertEqual(mockRepository.capturedUpdatedTask?.isCompleted, false)
    }
    
    func testToggleTaskCompletion_WithError_ShowsError() async {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Task", priority: "flexible", energyLevel: "any")
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.updateFailed
        
        // When
        await viewModel.toggleTaskCompletion(task)
        
        // Then
        XCTAssertTrue(mockRepository.updateTaskCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Update Task Tests
    
    func testUpdateTask_WithValidInput_Success() async {
        // Given
        let originalTask = Task(id: "task1", userId: "user1", title: "Original Title", priority: "flexible", energyLevel: "any")
        viewModel.title = "Updated Title"
        viewModel.priority = "must-do"
        viewModel.energyLevel = "high"
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.updateTask(originalTask)
        
        // Then
        XCTAssertTrue(mockRepository.updateTaskCalled)
        XCTAssertEqual(mockRepository.capturedUpdatedTask?.title, "Updated Title")
        XCTAssertEqual(mockRepository.capturedUpdatedTask?.priority, "must-do")
        XCTAssertEqual(mockRepository.capturedUpdatedTask?.energyLevel, "high")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUpdateTask_WithEmptyTitle_ValidationFails() async {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Original", priority: "flexible", energyLevel: "any")
        viewModel.title = ""
        
        // When
        await viewModel.updateTask(task)
        
        // Then
        XCTAssertFalse(mockRepository.updateTaskCalled)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testUpdateTask_WithError_ShowsError() async {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Original", priority: "flexible", energyLevel: "any")
        viewModel.title = "Updated Title"
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.updateFailed
        
        // When
        await viewModel.updateTask(task)
        
        // Then
        XCTAssertTrue(mockRepository.updateTaskCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Reset Form Tests
    
    func testResetForm_ClearsAllFields() {
        // Given
        viewModel.title = "Some Task"
        viewModel.priority = "must-do"
        viewModel.energyLevel = "high"
        viewModel.editingTask = Task(userId: "user1", title: "Task", priority: "flexible", energyLevel: "any")
        viewModel.errorMessage = "Some error"
        
        // When
        viewModel.resetForm()
        
        // Then
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.priority, "flexible")
        XCTAssertEqual(viewModel.energyLevel, "any")
        XCTAssertNil(viewModel.editingTask)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Edit Mode Tests
    
    func testLoadTaskForEditing_PopulatesFormFields() {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Task to Edit", priority: "must-do", energyLevel: "high")
        
        // When
        viewModel.loadTaskForEditing(task)
        
        // Then
        XCTAssertEqual(viewModel.title, "Task to Edit")
        XCTAssertEqual(viewModel.priority, "must-do")
        XCTAssertEqual(viewModel.energyLevel, "high")
        XCTAssertNotNil(viewModel.editingTask)
        XCTAssertEqual(viewModel.editingTask?.id, "task1")
    }
    
    func testIsEditMode_WithEditingTask_ReturnsTrue() {
        // Given
        let task = Task(userId: "user1", title: "Task", priority: "flexible", energyLevel: "any")
        viewModel.editingTask = task
        
        // When
        let isEditMode = viewModel.isEditMode
        
        // Then
        XCTAssertTrue(isEditMode)
    }
    
    func testIsEditMode_WithoutEditingTask_ReturnsFalse() {
        // Given
        viewModel.editingTask = nil
        
        // When
        let isEditMode = viewModel.isEditMode
        
        // Then
        XCTAssertFalse(isEditMode)
    }
    
    func testEditMode_ValidationWithValidInput_ReturnsTrue() {
        // Given
        let task = Task(userId: "user1", title: "Original", priority: "flexible", energyLevel: "any")
        viewModel.loadTaskForEditing(task)
        viewModel.title = "Updated Title"
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testEditMode_WithRepositoryError_HandlesError() async {
        // Given
        let task = Task(id: "task1", userId: "user1", title: "Original", priority: "flexible", energyLevel: "any")
        viewModel.loadTaskForEditing(task)
        viewModel.title = "Updated"
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.updateFailed
        
        // When
        await viewModel.updateTask(task)
        
        // Then
        XCTAssertTrue(mockRepository.updateTaskCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
}
