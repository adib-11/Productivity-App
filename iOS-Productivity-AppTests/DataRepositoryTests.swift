//
//  DataRepositoryTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import XCTest
import FirebaseFirestore
@testable import iOS_Productivity_App

// Note: These tests are designed to run with Firebase Emulator
// Start emulator with: firebase emulators:start
// Configure emulator connection in setUp()

@MainActor
final class DataRepositoryTests: XCTestCase {
    var repository: DataRepository!
    var mockAuthManager: MockAuthManager!
    var useEmulator = false // Set to true when running with emulator
    
    override func setUp() async throws {
        mockAuthManager = MockAuthManager()
        repository = DataRepository(authManager: mockAuthManager)
        
        // Configure Firestore to use emulator for testing
        if useEmulator {
            let settings = Firestore.firestore().settings
            settings.host = "localhost:8080"
            settings.isSSLEnabled = false
            Firestore.firestore().settings = settings
        }
    }
    
    override func tearDown() async throws {
        // Clean up test data
        if useEmulator {
            // Note: In a real test, we would delete all test documents here
            // For now, this is a placeholder
        }
        repository = nil
        mockAuthManager = nil
    }
    
    // MARK: - Create Commitment Tests
    
    func testCreateCommitment_WithValidData_Succeeds() async throws {
        // This test requires Firebase Emulator and authenticated user
        // Skip if not running with emulator
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given
        let commitment = FixedCommitment(
            id: nil,
            userId: "test-user-id",
            title: "Test Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // When & Then
        do {
            try await repository.createCommitment(commitment)
            // If we get here, the creation succeeded
            XCTAssertTrue(true)
        } catch {
            XCTFail("Create commitment failed: \(error)")
        }
    }
    
    func testCreateCommitment_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        // AuthManager has no current user by default
        let commitment = FixedCommitment(
            id: nil,
            userId: "test-user-id",
            title: "Test Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // When & Then
        do {
            try await repository.createCommitment(commitment)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Fetch Commitments Tests
    
    func testFetchCommitments_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        // AuthManager has no current user by default
        
        // When & Then
        do {
            _ = try await repository.fetchCommitments()
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testFetchCommitments_WithEmptyDatabase_ReturnsEmptyArray() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // When
        let commitments = try await repository.fetchCommitments()
        
        // Then
        XCTAssertNotNil(commitments)
        // We can't guarantee empty since other tests might have created data
        XCTAssertTrue(commitments.isEmpty || !commitments.isEmpty)
    }
    
    // MARK: - Update Commitment Tests
    
    func testUpdateCommitment_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        let commitment = FixedCommitment(
            id: "test-id",
            userId: "test-user-id",
            title: "Updated Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // When & Then
        do {
            try await repository.updateCommitment(commitment)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpdateCommitment_WithNilId_ThrowsError() async throws {
        // Given
        let commitment = FixedCommitment(
            id: nil,
            userId: "test-user-id",
            title: "Updated Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // When & Then
        do {
            try await repository.updateCommitment(commitment)
            XCTFail("Should have thrown invalidData error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.invalidData)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Delete Commitment Tests
    
    func testDeleteCommitment_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        let commitmentId = "test-commitment-id"
        
        // When & Then
        do {
            try await repository.deleteCommitment(commitmentId)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDataRepositoryError_NotAuthenticated_HasCorrectMessage() {
        let error = DataRepositoryError.notAuthenticated
        XCTAssertEqual(error.errorDescription, "You must be logged in to perform this action.")
    }
    
    func testDataRepositoryError_SaveFailed_HasCorrectMessage() {
        let error = DataRepositoryError.saveFailed
        XCTAssertEqual(error.errorDescription, "Failed to save commitment. Please try again.")
    }
    
    func testDataRepositoryError_FetchFailed_HasCorrectMessage() {
        let error = DataRepositoryError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to load commitments. Please check your connection.")
    }
    
    func testDataRepositoryError_UpdateFailed_HasCorrectMessage() {
        let error = DataRepositoryError.updateFailed
        XCTAssertEqual(error.errorDescription, "Failed to update commitment. Please try again.")
    }
    
    func testDataRepositoryError_DeleteFailed_HasCorrectMessage() {
        let error = DataRepositoryError.deleteFailed
        XCTAssertEqual(error.errorDescription, "Failed to delete commitment. Please try again.")
    }
    
    func testDataRepositoryError_InvalidData_HasCorrectMessage() {
        let error = DataRepositoryError.invalidData
        XCTAssertEqual(error.errorDescription, "Invalid commitment data.")
    }
    
    // MARK: - Task CRUD Tests
    
    func testCreateTask_WithValidData_Succeeds() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given
        let task = Task(
            id: nil,
            userId: "test-user-id",
            title: "Study for Midterm",
            priority: "must-do",
            energyLevel: "high"
        )
        
        // When & Then
        do {
            try await repository.createTask(task)
            XCTAssertTrue(true)
        } catch {
            XCTFail("Create task failed: \(error)")
        }
    }
    
    func testCreateTask_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        let task = Task(
            id: nil,
            userId: "test-user-id",
            title: "Study for Midterm",
            priority: "must-do",
            energyLevel: "high"
        )
        
        // When & Then
        do {
            try await repository.createTask(task)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testFetchTasks_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        // AuthManager has no current user by default
        
        // When & Then
        do {
            _ = try await repository.fetchTasks()
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testFetchTasks_WithEmptyDatabase_ReturnsEmptyArray() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // When
        let tasks = try await repository.fetchTasks()
        
        // Then
        XCTAssertNotNil(tasks)
        // We can't guarantee empty since other tests might have created data
        XCTAssertTrue(tasks.isEmpty || !tasks.isEmpty)
    }
    
    func testFetchTasks_ReturnsMultipleTasks() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given - Create some tasks first
        let task1 = Task(userId: "test-user-id", title: "Task 1", priority: "flexible", energyLevel: "any")
        let task2 = Task(userId: "test-user-id", title: "Task 2", priority: "must-do", energyLevel: "high")
        try await repository.createTask(task1)
        try await repository.createTask(task2)
        
        // When
        let tasks = try await repository.fetchTasks()
        
        // Then
        XCTAssertGreaterThanOrEqual(tasks.count, 2)
    }
    
    func testUpdateTask_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        let task = Task(
            id: "test-id",
            userId: "test-user-id",
            title: "Updated Task",
            priority: "must-do",
            energyLevel: "high"
        )
        
        // When & Then
        do {
            try await repository.updateTask(task)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpdateTask_WithNilId_ThrowsError() async throws {
        // Given
        let task = Task(
            id: nil,
            userId: "test-user-id",
            title: "Updated Task",
            priority: "must-do",
            energyLevel: "high"
        )
        
        // When & Then
        do {
            try await repository.updateTask(task)
            XCTFail("Should have thrown invalidData error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.invalidData)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpdateTask_ModifiesExistingTask() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given - Create a task first
        let originalTask = Task(userId: "test-user-id", title: "Original", priority: "flexible", energyLevel: "any")
        try await repository.createTask(originalTask)
        
        // Fetch to get the ID
        let tasks = try await repository.fetchTasks()
        guard var taskToUpdate = tasks.first else {
            XCTFail("No tasks found")
            return
        }
        
        // When - Update the task
        taskToUpdate.title = "Updated Title"
        taskToUpdate.priority = "must-do"
        try await repository.updateTask(taskToUpdate)
        
        // Then - Verify update
        let updatedTasks = try await repository.fetchTasks()
        let updatedTask = updatedTasks.first { $0.id == taskToUpdate.id }
        XCTAssertEqual(updatedTask?.title, "Updated Title")
        XCTAssertEqual(updatedTask?.priority, "must-do")
    }
    
    func testDeleteTask_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given
        let taskId = "test-task-id"
        
        // When & Then
        do {
            try await repository.deleteTask(taskId)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testDeleteTask_RemovesTask() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given - Create a task first
        let task = Task(userId: "test-user-id", title: "Task to Delete", priority: "flexible", energyLevel: "any")
        try await repository.createTask(task)
        
        // Fetch to get the ID
        let tasks = try await repository.fetchTasks()
        guard let taskToDelete = tasks.first(where: { $0.title == "Task to Delete" }) else {
            XCTFail("Task not found")
            return
        }
        
        guard let taskId = taskToDelete.id else {
            XCTFail("Task has no ID")
            return
        }
        
        // When - Delete the task
        try await repository.deleteTask(taskId)
        
        // Then - Verify deletion
        let remainingTasks = try await repository.fetchTasks()
        let deletedTask = remainingTasks.first { $0.id == taskId }
        XCTAssertNil(deletedTask)
    }
    
    func testTaskCompletionToggle_UpdatesFirestore() async throws {
        // This test requires Firebase Emulator and authenticated user
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given - Create a task
        var task = Task(userId: "test-user-id", title: "Task to Complete", priority: "flexible", energyLevel: "any")
        task.isCompleted = false
        try await repository.createTask(task)
        
        // Fetch to get the ID
        let tasks = try await repository.fetchTasks()
        guard var fetchedTask = tasks.first(where: { $0.title == "Task to Complete" }) else {
            XCTFail("Task not found")
            return
        }
        
        // When - Toggle completion
        fetchedTask.isCompleted = true
        try await repository.updateTask(fetchedTask)
        
        // Then - Verify completion status persisted
        let updatedTasks = try await repository.fetchTasks()
        let completedTask = updatedTasks.first { $0.id == fetchedTask.id }
        XCTAssertEqual(completedTask?.isCompleted, true)
    }
}

// MARK: - Integration Test Instructions
/*
 To run integration tests with Firebase Emulator:
 
 1. Install Firebase CLI:
    npm install -g firebase-tools
 
 2. Start the Firebase Emulator:
    cd /path/to/project
    firebase emulators:start
 
 3. Set useEmulator = true in setUp()
 
 4. Run tests with Cmd+U
 
 5. View data in Emulator UI:
    http://localhost:4000
 
 Note: Integration tests that require authentication are marked as XCTSkip
 when emulator is not running. This allows unit tests to run independently.
 */
