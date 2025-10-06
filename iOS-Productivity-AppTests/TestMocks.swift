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
    
    // Captured values
    var capturedTask: Task?
    var capturedUpdatedTask: Task?
    var capturedTaskId: String?
    var tasksToReturn: [Task] = []
    var mockCommitments: [FixedCommitment] = []
    
    init() {
        let mockAuthManager = MockAuthManager()
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
        
        return tasksToReturn
    }
    
    override func updateTask(_ task: Task) async throws {
        updateTaskCalled = true
        capturedUpdatedTask = task
        
        if !shouldSucceed || shouldThrowError {
            throw errorToThrow ?? DataRepositoryError.updateFailed
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
}
