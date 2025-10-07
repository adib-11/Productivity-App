//
//  DataRepository.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum DataRepositoryError: LocalizedError, Equatable {
    case notAuthenticated
    case saveFailed
    case fetchFailed
    case updateFailed
    case deleteFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action."
        case .saveFailed:
            return "Failed to save commitment. Please try again."
        case .fetchFailed:
            return "Failed to load commitments. Please check your connection."
        case .updateFailed:
            return "Failed to update commitment. Please try again."
        case .deleteFailed:
            return "Failed to delete commitment. Please try again."
        case .invalidData:
            return "Invalid commitment data."
        }
    }
}

class DataRepository: ObservableObject {
    private let db = Firestore.firestore()
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Fixed Commitments CRUD
    
    func createCommitment(_ commitment: FixedCommitment) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        var newCommitment = commitment
        newCommitment.userId = userId
        
        do {
            try db.collection("users/\(userId)/fixedCommitments")
                .addDocument(from: newCommitment)
        } catch {
            throw DataRepositoryError.saveFailed
        }
    }
    
    func fetchCommitments() async throws -> [FixedCommitment] {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        do {
            let snapshot = try await db.collection("users/\(userId)/fixedCommitments")
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: FixedCommitment.self)
            }
        } catch {
            throw DataRepositoryError.fetchFailed
        }
    }
    
    func fetchCommitments(for date: Date) async throws -> [FixedCommitment] {
        print("🟢 DataRepository: fetchCommitments(for:) called with date: \(date)")
        
        guard let userId = authManager.currentUser?.id else {
            print("🔴 DataRepository: Not authenticated")
            throw DataRepositoryError.notAuthenticated
        }
        
        print("🟢 DataRepository: User ID: \(userId)")
        
        // Calculate date range using local timezone to match Firestore timestamps
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("🔴 DataRepository: Failed to calculate endOfDay")
            throw DataRepositoryError.fetchFailed
        }
        
        print("🟢 DataRepository: Local timezone: \(TimeZone.current.identifier)")
        print("🟢 DataRepository: Querying commitments from \(startOfDay) to \(endOfDay)")
        
        do {
            let snapshot = try await db.collection("users/\(userId)/fixedCommitments")
                .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
                .whereField("startTime", isLessThan: endOfDay)
                .order(by: "startTime", descending: false)
                .getDocuments()
            
            print("🟢 DataRepository: Fetched \(snapshot.documents.count) commitment documents")
            
            let commitments = snapshot.documents.compactMap { doc in
                try? doc.data(as: FixedCommitment.self)
            }
            
            print("🟢 DataRepository: Successfully parsed \(commitments.count) commitments")
            return commitments
        } catch {
            print("🔴 DataRepository: Fetch error: \(error)")
            throw DataRepositoryError.fetchFailed
        }
    }
    
    func updateCommitment(_ commitment: FixedCommitment) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        guard let commitmentId = commitment.id else {
            throw DataRepositoryError.invalidData
        }
        
        do {
            try db.collection("users/\(userId)/fixedCommitments")
                .document(commitmentId)
                .setData(from: commitment)
        } catch {
            throw DataRepositoryError.updateFailed
        }
    }
    
    func deleteCommitment(_ commitmentId: String) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        do {
            try await db.collection("users/\(userId)/fixedCommitments")
                .document(commitmentId)
                .delete()
        } catch {
            throw DataRepositoryError.deleteFailed
        }
    }
    
    // MARK: - Task CRUD Operations
    
    func createTask(_ task: Task) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        var newTask = task
        newTask.userId = userId
        newTask.createdAt = Date()
        
        do {
            try db.collection("users/\(userId)/tasks")
                .addDocument(from: newTask)
        } catch {
            throw DataRepositoryError.saveFailed
        }
    }
    
    func fetchTasks() async throws -> [Task] {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        do {
            let snapshot = try await db.collection("users/\(userId)/tasks")
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Task.self)
            }
        } catch {
            throw DataRepositoryError.fetchFailed
        }
    }
    
    func updateTask(_ task: Task) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        guard let taskId = task.id else {
            throw DataRepositoryError.invalidData
        }
        
        do {
            try db.collection("users/\(userId)/tasks")
                .document(taskId)
                .setData(from: task)
        } catch {
            throw DataRepositoryError.updateFailed
        }
    }
    
    func deleteTask(_ taskId: String) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        do {
            try await db.collection("users/\(userId)/tasks")
                .document(taskId)
                .delete()
        } catch {
            throw DataRepositoryError.deleteFailed
        }
    }
    
    // MARK: - ScheduledTask CRUD Operations
    
    func saveScheduledTask(_ scheduledTask: ScheduledTask) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        do {
            try db.collection("users/\(userId)/scheduledTasks")
                .addDocument(from: scheduledTask)
        } catch {
            throw DataRepositoryError.saveFailed
        }
    }
    
    func fetchScheduledTasks(for date: Date) async throws -> [ScheduledTask] {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        // Calculate date range using local timezone to match Firestore timestamps
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DataRepositoryError.fetchFailed
        }
        
        print("🟢 DataRepository: fetchScheduledTasks for date range: \(startOfDay) to \(endOfDay)")
        
        do {
            // Use single range filter on startTime (most relevant for timeline display)
            // This avoids the need for a composite index
            let snapshot = try await db.collection("users/\(userId)/scheduledTasks")
                .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
                .whereField("startTime", isLessThan: endOfDay)
                .order(by: "startTime", descending: false)
                .getDocuments()
            
            print("🟢 DataRepository: Fetched \(snapshot.documents.count) scheduled task documents")
            
            let tasks = snapshot.documents.compactMap { doc -> ScheduledTask? in
                try? doc.data(as: ScheduledTask.self)
            }
            
            print("🟢 DataRepository: Successfully parsed \(tasks.count) scheduled tasks")
            return tasks
        } catch {
            print("🔴 DataRepository: fetchScheduledTasks error: \(error)")
            throw DataRepositoryError.fetchFailed
        }
    }
    
    func deleteScheduledTask(id: String) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        do {
            try await db.collection("users/\(userId)/scheduledTasks")
                .document(id)
                .delete()
        } catch {
            throw DataRepositoryError.deleteFailed
        }
    }
    
    func deleteAllScheduledTasks(for date: Date) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        // Calculate date range using local timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DataRepositoryError.deleteFailed
        }
        
        print("🟢 DataRepository: deleteAllScheduledTasks for date range: \(startOfDay) to \(endOfDay)")
        
        do {
            // Fetch all scheduled tasks for the date
            let snapshot = try await db.collection("users/\(userId)/scheduledTasks")
                .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
                .whereField("startTime", isLessThan: endOfDay)
                .getDocuments()
            
            print("🟢 DataRepository: Found \(snapshot.documents.count) scheduled tasks to delete")
            
            // Delete each document
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            print("🟢 DataRepository: Successfully deleted all scheduled tasks for date")
        } catch {
            print("🔴 DataRepository: deleteAllScheduledTasks error: \(error)")
            throw DataRepositoryError.deleteFailed
        }
    }
    
    func updateScheduledTask(_ scheduledTask: ScheduledTask) async throws {
        guard let userId = authManager.currentUser?.id else {
            print("🔴 DataRepository: updateScheduledTask - Not authenticated")
            throw DataRepositoryError.notAuthenticated
        }
        
        guard let taskId = scheduledTask.id else {
            print("🔴 DataRepository: updateScheduledTask - No task ID")
            throw DataRepositoryError.invalidData
        }
        
        do {
            try db.collection("users/\(userId)/scheduledTasks")
                .document(taskId)
                .setData(from: scheduledTask, merge: true)
            
            print("✅ DataRepository: Updated scheduled task: \(taskId)")
        } catch {
            print("🔴 DataRepository: updateScheduledTask error: \(error)")
            throw DataRepositoryError.updateFailed
        }
    }
}
