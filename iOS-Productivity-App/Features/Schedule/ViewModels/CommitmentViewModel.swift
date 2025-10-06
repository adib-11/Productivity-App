//
//  CommitmentViewModel.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation

@MainActor
class CommitmentViewModel: ObservableObject {
    @Published var commitments: [FixedCommitment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Form properties
    @Published var title = ""
    @Published var startTime = Date()
    @Published var endTime = Date().addingTimeInterval(3600) // +1 hour default
    
    // Edit mode tracking
    @Published var editingCommitment: FixedCommitment?
    var isEditMode: Bool { editingCommitment != nil }
    
    private let repository: DataRepository
    
    init(repository: DataRepository) {
        self.repository = repository
    }
    
    func loadCommitments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            commitments = try await repository.fetchCommitments()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createCommitment() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let commitment = FixedCommitment(
            id: nil,
            userId: "", // Will be set by repository
            title: title,
            startTime: startTime,
            endTime: endTime
        )
        
        do {
            try await repository.createCommitment(commitment)
            await loadCommitments() // Refresh list
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func saveCommitment() async {
        if isEditMode {
            await saveEditedCommitment()
        } else {
            await createCommitment()
        }
    }
    
    func saveEditedCommitment() async {
        guard validateInput() else { return }
        guard var commitment = editingCommitment else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Update commitment with new values
        commitment.title = title
        commitment.startTime = startTime
        commitment.endTime = endTime
        
        do {
            try await repository.updateCommitment(commitment)
            await loadCommitments() // Refresh list
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadCommitmentForEditing(_ commitment: FixedCommitment) {
        editingCommitment = commitment
        title = commitment.title
        startTime = commitment.startTime
        endTime = commitment.endTime
        errorMessage = nil
    }
    
    func updateCommitment(_ commitment: FixedCommitment) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await repository.updateCommitment(commitment)
            await loadCommitments() // Refresh list
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteCommitment(_ commitment: FixedCommitment) async {
        guard let commitmentId = commitment.id else {
            errorMessage = "Invalid commitment ID."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await repository.deleteCommitment(commitmentId)
            await loadCommitments() // Refresh list
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func validateInput() -> Bool {
        // Trim whitespace from title
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            errorMessage = "Title cannot be empty."
            return false
        }
        
        if endTime <= startTime {
            errorMessage = "End time must be after start time."
            return false
        }
        
        return true
    }
    
    func resetForm() {
        title = ""
        startTime = Date()
        endTime = Date().addingTimeInterval(3600)
        errorMessage = nil
        editingCommitment = nil
    }
}
