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
        guard let userId = authManager.currentUser?.id else {
            throw DataRepositoryError.notAuthenticated
        }
        
        // Calculate date range (start of day to start of next day)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DataRepositoryError.fetchFailed
        }
        
        do {
            let snapshot = try await db.collection("users/\(userId)/fixedCommitments")
                .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
                .whereField("startTime", isLessThan: endOfDay)
                .order(by: "startTime", descending: false)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: FixedCommitment.self)
            }
        } catch {
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
}
