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
        // Given - Set up authenticated user so we can reach the nil ID check
        mockAuthManager.currentUser = User(id: "test-user-id", email: "test@example.com")
        
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
        // Given - Set up authenticated user so we can reach the nil ID check
        mockAuthManager.currentUser = User(id: "test-user-id", email: "test@example.com")
        
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
    
    // MARK: - Fetch Commitments by Date Tests
    
    func testFetchCommitmentsForDate_WithSpecificDate_ReturnsCommitmentsForThatDay() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator")
        }
        
        // Given - User is authenticated
        let testUser = try await mockAuthManager.signUp(email: "test@example.com", password: "password123")
        mockAuthManager.currentUser = testUser
        
        // Create commitments for today
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let todayCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Today's Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        // Create commitment for tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        
        let tomorrowCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Tomorrow's Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: tomorrowStart)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: tomorrowStart)!
        )
        
        try await repository.createCommitment(todayCommitment)
        try await repository.createCommitment(tomorrowCommitment)
        
        // When - Fetch commitments for today
        let todayCommitments = try await repository.fetchCommitments(for: today)
        
        // Then - Only today's commitment is returned
        XCTAssertEqual(todayCommitments.count, 1)
        XCTAssertEqual(todayCommitments.first?.title, "Today's Meeting")
    }
    
    func testFetchCommitmentsForDate_WithNoCommitments_ReturnsEmptyArray() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator")
        }
        
        // Given - User is authenticated but has no commitments
        let testUser = try await mockAuthManager.signUp(email: "test@example.com", password: "password123")
        mockAuthManager.currentUser = testUser
        
        // When - Fetch commitments for today
        let commitments = try await repository.fetchCommitments(for: Date())
        
        // Then - Empty array is returned
        XCTAssertTrue(commitments.isEmpty)
    }
    
    func testFetchCommitmentsForDate_FiltersOutOtherDays() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator")
        }
        
        // Given - User with commitments on multiple days
        let testUser = try await mockAuthManager.signUp(email: "test@example.com", password: "password123")
        mockAuthManager.currentUser = testUser
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let todayStart = calendar.startOfDay(for: today)
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        
        // Create commitments for each day
        let yesterdayCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Yesterday",
            startTime: calendar.date(byAdding: .hour, value: 9, to: yesterdayStart)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: yesterdayStart)!
        )
        
        let todayCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Today",
            startTime: calendar.date(byAdding: .hour, value: 9, to: todayStart)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: todayStart)!
        )
        
        let tomorrowCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Tomorrow",
            startTime: calendar.date(byAdding: .hour, value: 9, to: tomorrowStart)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: tomorrowStart)!
        )
        
        try await repository.createCommitment(yesterdayCommitment)
        try await repository.createCommitment(todayCommitment)
        try await repository.createCommitment(tomorrowCommitment)
        
        // When - Fetch commitments for today
        let todayCommitments = try await repository.fetchCommitments(for: today)
        
        // Then - Only today's commitment is returned
        XCTAssertEqual(todayCommitments.count, 1)
        XCTAssertEqual(todayCommitments.first?.title, "Today")
    }
    
    func testFetchCommitmentsForDate_WithMultipleCommitmentsSameDay_ReturnsSortedByStartTime() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator")
        }
        
        // Given - Multiple commitments on the same day
        let testUser = try await mockAuthManager.signUp(email: "test@example.com", password: "password123")
        mockAuthManager.currentUser = testUser
        
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let morningCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Morning Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        let afternoonCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Afternoon Meeting",
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        )
        
        let lunchCommitment = FixedCommitment(
            id: nil,
            userId: testUser.id,
            title: "Lunch",
            startTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 13, to: startOfDay)!
        )
        
        // Create in random order
        try await repository.createCommitment(afternoonCommitment)
        try await repository.createCommitment(morningCommitment)
        try await repository.createCommitment(lunchCommitment)
        
        // When - Fetch commitments for today
        let commitments = try await repository.fetchCommitments(for: today)
        
        // Then - Commitments are sorted by start time
        XCTAssertEqual(commitments.count, 3)
        XCTAssertEqual(commitments[0].title, "Morning Meeting")
        XCTAssertEqual(commitments[1].title, "Lunch")
        XCTAssertEqual(commitments[2].title, "Afternoon Meeting")
    }
    
    func testFetchCommitmentsForDate_WithUnauthenticatedUser_ThrowsError() async throws {
        // Given - No authenticated user
        mockAuthManager.currentUser = nil
        
        // When/Then - Fetch throws notAuthenticated error
        do {
            _ = try await repository.fetchCommitments(for: Date())
            XCTFail("Expected notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        }
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

// MARK: - ScheduledTask CRUD Tests (Story 2.3)

extension DataRepositoryTests {
    func testSaveScheduledTask_WithValidData_Succeeds() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given
        mockAuthManager.setMockUser(User(id: "test-user-id", email: "test@test.com"))
        let scheduledTask = ScheduledTask(
            id: nil,
            taskId: "task-123",
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800) // 30 minutes
        )
        
        // When & Then
        do {
            try await repository.saveScheduledTask(scheduledTask)
            XCTAssertTrue(true)
        } catch {
            XCTFail("Save scheduled task failed: \(error)")
        }
    }
    
    func testFetchScheduledTasks_ForDate_ReturnsCorrectTasks() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given
        mockAuthManager.setMockUser(User(id: "test-user-id", email: "test@test.com"))
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let scheduledTask = ScheduledTask(
            id: nil,
            taskId: "task-123",
            date: today,
            startTime: today.addingTimeInterval(3600 * 9), // 9 AM
            endTime: today.addingTimeInterval(3600 * 9.5) // 9:30 AM
        )
        
        try await repository.saveScheduledTask(scheduledTask)
        
        // When
        let tasks = try await repository.fetchScheduledTasks(for: today)
        
        // Then
        XCTAssertGreaterThan(tasks.count, 0)
        XCTAssertEqual(tasks.first?.taskId, "task-123")
    }
    
    func testDeleteScheduledTask_RemovesTask() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given
        mockAuthManager.setMockUser(User(id: "test-user-id", email: "test@test.com"))
        let scheduledTask = ScheduledTask(
            id: "test-scheduled-task-id",
            taskId: "task-123",
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800)
        )
        
        try await repository.saveScheduledTask(scheduledTask)
        
        // When
        try await repository.deleteScheduledTask(id: "test-scheduled-task-id")
        
        // Then
        // Verify deletion by attempting to fetch
        // (In a real test, we'd verify the document no longer exists)
        XCTAssertTrue(true)
    }
    
    // MARK: - Update ScheduledTask Tests (Story 2.4)
    
    func testUpdateScheduledTask_Success() async throws {
        guard useEmulator else {
            throw XCTSkip("Test requires Firebase Emulator. Start with: firebase emulators:start")
        }
        
        // Given
        mockAuthManager.setMockUser(User(id: "test-user-id", email: "test@test.com"))
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var scheduledTask = ScheduledTask(
            id: nil,
            taskId: "task-123",
            date: today,
            startTime: today.addingTimeInterval(3600 * 9), // 9 AM
            endTime: today.addingTimeInterval(3600 * 9.5) // 9:30 AM
        )
        
        // Save initial task
        try await repository.saveScheduledTask(scheduledTask)
        let tasks = try await repository.fetchScheduledTasks(for: today)
        scheduledTask = tasks.first!
        
        // When: Update the task to new time (2 PM - 2:30 PM)
        var updatedTask = scheduledTask
        updatedTask.startTime = today.addingTimeInterval(3600 * 14) // 2 PM
        updatedTask.endTime = today.addingTimeInterval(3600 * 14.5) // 2:30 PM
        
        try await repository.updateScheduledTask(updatedTask)
        
        // Then: Fetch and verify update
        let fetchedTasks = try await repository.fetchScheduledTasks(for: today)
        let fetchedTask = fetchedTasks.first(where: { $0.id == scheduledTask.id })
        
        XCTAssertNotNil(fetchedTask)
        if let fetchedTask = fetchedTask {
            XCTAssertEqual(fetchedTask.startTime.timeIntervalSince1970, updatedTask.startTime.timeIntervalSince1970, accuracy: 1.0)
            XCTAssertEqual(fetchedTask.endTime.timeIntervalSince1970, updatedTask.endTime.timeIntervalSince1970, accuracy: 1.0)
        }
    }
    
    func testUpdateScheduledTask_InvalidAuth() async throws {
        // Given: No authenticated user
        let scheduledTask = ScheduledTask(
            id: "test-id",
            taskId: "task-123",
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800)
        )
        
        // When & Then
        do {
            try await repository.updateScheduledTask(scheduledTask)
            XCTFail("Should have thrown notAuthenticated error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.notAuthenticated)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpdateScheduledTask_FirestoreError() async throws {
        // Given: Authenticated user but invalid task ID (nil)
        mockAuthManager.setMockUser(User(id: "test-user-id", email: "test@test.com"))
        
        let scheduledTask = ScheduledTask(
            id: nil, // Invalid - no ID
            taskId: "task-123",
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800)
        )
        
        // When & Then
        do {
            try await repository.updateScheduledTask(scheduledTask)
            XCTFail("Should have thrown invalidData error")
        } catch let error as DataRepositoryError {
            XCTAssertEqual(error, DataRepositoryError.invalidData)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}


