//
//  TestMocks.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import Foundation
@testable import iOS_Productivity_App

// MARK: - Mock AuthManager

/// Mock AuthManager for testing authentication flows
class MockAuthManager: AuthManager {
    var signUpCalled = false
    var signInCalled = false
    var signOutCalled = false
    var shouldSucceed = true
    var errorToThrow: Error?
    var lastEmail: String?
    var lastPassword: String?
    private var _mockCurrentUser: iOS_Productivity_App.User?
    
    override init() {
        super.init()
        _mockCurrentUser = nil
    }
    
    // Override to prevent Firebase state listener from being registered
    override func registerAuthStateHandler() {
        // Do nothing - we don't want Firebase listeners in tests
    }
    
    override var currentUser: iOS_Productivity_App.User? {
        get { return _mockCurrentUser }
        set { _mockCurrentUser = newValue }
    }
    
    override func signUp(email: String, password: String) async throws -> iOS_Productivity_App.User {
        signUpCalled = true
        lastEmail = email
        lastPassword = password
        
        if !shouldSucceed {
            throw errorToThrow ?? NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        
        let user = iOS_Productivity_App.User(id: "mock-user-id", email: email)
        _mockCurrentUser = user
        return user
    }
    
    override func signIn(email: String, password: String) async throws -> iOS_Productivity_App.User {
        signInCalled = true
        lastEmail = email
        lastPassword = password
        
        if !shouldSucceed {
            throw errorToThrow ?? NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        
        let user = iOS_Productivity_App.User(id: "mock-user-id", email: email)
        _mockCurrentUser = user
        return user
    }
    
    override func signOut() throws {
        signOutCalled = true
        
        if !shouldSucceed {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        
        _mockCurrentUser = nil
    }
}

// MARK: - Mock DataRepository

/// Mock DataRepository for testing ViewModels
@MainActor
class MockDataRepository: DataRepository {
    // Control flags
    var shouldSucceed = true
    var shouldThrowError = false
    var errorToThrow: Error?
    
    // Call tracking
    var createTaskCalled = false
    var fetchTasksCalled = false
    var updateTaskCalled = false
    var deleteTaskCalled = false
    var createCommitmentCalled = false
    var updateCommitmentCalled = false
    var deleteCommitmentCalled = false
    var updateScheduledTaskCalled = false
    
    // Captured values
    var capturedTask: Task?
    var capturedUpdatedTask: Task?
    var capturedTaskId: String?
    var tasksToReturn: [Task] = []
    var mockCommitments: [FixedCommitment] = []
    var mockTasks: [Task] = []
    var mockScheduledTasks: [ScheduledTask] = []
    
    // Story 2.5: Track operations for completion tests
    var updatedTasks: [Task] = []
    var deletedScheduledTaskIds: [String] = []
    
    init() {
        let mockAuthManager = MockAuthManager()
        // Set a default mock user to prevent authentication errors
        mockAuthManager.currentUser = iOS_Productivity_App.User(id: "test-user", email: "test@example.com")
        super.init(authManager: mockAuthManager)
    }
    
    // MARK: - Task Methods
    
    override func createTask(_ task: Task) async throws {
        createTaskCalled = true
        capturedTask = task
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.saveFailed
        }
    }
    
    override func fetchTasks() async throws -> [Task] {
        fetchTasksCalled = true
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.fetchFailed
        }
        
        return mockTasks.isEmpty ? tasksToReturn : mockTasks
    }
    
    override func updateTask(_ task: Task) async throws {
        updateTaskCalled = true
        capturedUpdatedTask = task
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.updateFailed
        }
        
        // Story 2.5: Track updated tasks
        updatedTasks.append(task)
        
        // Update in mockTasks array if exists
        if let index = mockTasks.firstIndex(where: { $0.id == task.id }) {
            mockTasks[index] = task
        }
    }
    
    override func deleteTask(_ taskId: String) async throws {
        deleteTaskCalled = true
        capturedTaskId = taskId
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.deleteFailed
        }
    }
    
    // MARK: - Commitment Methods
    
    override func createCommitment(_ commitment: FixedCommitment) async throws {
        createCommitmentCalled = true
        if shouldThrowError {
            throw DataRepositoryError.saveFailed
        }
        var newCommitment = commitment
        newCommitment.id = UUID().uuidString
        mockCommitments.append(newCommitment)
    }
    
    override func fetchCommitments() async throws -> [FixedCommitment] {
        if shouldThrowError {
            throw DataRepositoryError.fetchFailed
        }
        return mockCommitments
    }
    
    override func updateCommitment(_ commitment: FixedCommitment) async throws {
        updateCommitmentCalled = true
        if shouldThrowError {
            throw DataRepositoryError.updateFailed
        }
        if let index = mockCommitments.firstIndex(where: { $0.id == commitment.id }) {
            mockCommitments[index] = commitment
        }
    }
    
    override func deleteCommitment(_ commitmentId: String) async throws {
        deleteCommitmentCalled = true
        if shouldThrowError {
            throw DataRepositoryError.deleteFailed
        }
        mockCommitments.removeAll { $0.id == commitmentId }
    }
    
    override func fetchCommitments(for date: Date) async throws -> [FixedCommitment] {
        if shouldThrowError {
            throw DataRepositoryError.fetchFailed
        }
        
        // Filter commitments by date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        return mockCommitments.filter { commitment in
            commitment.startTime >= startOfDay && commitment.startTime < endOfDay
        }.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - ScheduledTask Methods (Story 2.3)
    
    override func saveScheduledTask(_ scheduledTask: ScheduledTask) async throws {
        if shouldThrowError {
            throw DataRepositoryError.saveFailed
        }
        var newTask = scheduledTask
        newTask.id = newTask.id ?? UUID().uuidString
        mockScheduledTasks.append(newTask)
    }
    
    override func fetchScheduledTasks(for date: Date) async throws -> [ScheduledTask] {
        if shouldThrowError {
            throw DataRepositoryError.fetchFailed
        }
        
        // Filter scheduled tasks by date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        return mockScheduledTasks.filter { task in
            task.date >= startOfDay && task.date < endOfDay
        }.sorted { $0.startTime < $1.startTime }
    }
    
    override func deleteScheduledTask(id: String) async throws {
        if shouldThrowError {
            throw DataRepositoryError.deleteFailed
        }
        
        // Story 2.5: Track deleted scheduled task IDs
        deletedScheduledTaskIds.append(id)
        
        mockScheduledTasks.removeAll { $0.id == id }
    }
    
    override func deleteAllScheduledTasks(for date: Date) async throws {
        if shouldThrowError {
            throw DataRepositoryError.deleteFailed
        }
        
        // Filter and delete scheduled tasks for the given date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }
        
        mockScheduledTasks.removeAll { task in
            task.date >= startOfDay && task.date < endOfDay
        }
    }
    
    override func updateScheduledTask(_ scheduledTask: ScheduledTask) async throws {
        updateScheduledTaskCalled = true
        
        if shouldThrowError {
            throw DataRepositoryError.updateFailed
        }
        
        // Update the task in the mock array
        if let index = mockScheduledTasks.firstIndex(where: { $0.id == scheduledTask.id }) {
            mockScheduledTasks[index] = scheduledTask
        }
    }
    
    // MARK: - MoodEnergyState Methods
    
    var saveMoodEnergyStateCalled = false
    var getCurrentMoodEnergyStateCalled = false
    var capturedMoodState: MoodEnergyState?
    var mockCurrentMoodState: MoodEnergyState?
    
    override func saveMoodEnergyState(_ state: MoodEnergyState) async throws {
        saveMoodEnergyStateCalled = true
        capturedMoodState = state
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.saveFailed
        }
        
        mockCurrentMoodState = state
    }
    
    override func getCurrentMoodEnergyState() async throws -> MoodEnergyState? {
        getCurrentMoodEnergyStateCalled = true
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.fetchFailed
        }
        
        return mockCurrentMoodState
    }
    
    // MARK: - Story 3.3: Task Suggestion Methods
    
    var getFlexibleTasksCalled = false
    var mockFlexibleTasks: [Task] = []
    
    override func getFlexibleTasks() async throws -> [Task] {
        getFlexibleTasksCalled = true
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.fetchFailed
        }
        
        return mockFlexibleTasks
    }
}

// MARK: - Mock TaskSuggestionEngine

class MockTaskSuggestionEngine: TaskSuggestionEngine {
    var suggestTasksCalled = false
    var capturedTasks: [Task]?
    var capturedMoodEnergyLevel: String?
    var capturedScheduledTaskIds: Set<String>?
    var mockSuggestedTasks: [SuggestedTask] = []
    
    override func suggestTasks(
        tasks: [Task],
        moodEnergyLevel: String,
        scheduledTaskIds: Set<String>
    ) -> [SuggestedTask] {
        suggestTasksCalled = true
        capturedTasks = tasks
        capturedMoodEnergyLevel = moodEnergyLevel
        capturedScheduledTaskIds = scheduledTaskIds
        
        return mockSuggestedTasks
    }
}

// MARK: - Mock Extensions

extension MockAuthManager {
    func setMockUser(_ user: iOS_Productivity_App.User?) {
        _mockCurrentUser = user
    }
}
