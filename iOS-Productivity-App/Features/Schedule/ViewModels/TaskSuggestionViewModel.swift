//
//  TaskSuggestionViewModel.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-09.
//

import Foundation

@MainActor
class TaskSuggestionViewModel: ObservableObject {
    @Published var suggestedTasks: [SuggestedTask] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showNoMatchMessage: Bool = false
    
    private let repository: DataRepository
    private let suggestionEngine: TaskSuggestionEngine
    
    init(repository: DataRepository, suggestionEngine: TaskSuggestionEngine = TaskSuggestionEngine()) {
        self.repository = repository
        self.suggestionEngine = suggestionEngine
    }
    
    func generateSuggestions(for energyLevel: String, scheduledTaskIds: Set<String>) async {
        isLoading = true
        errorMessage = nil
        showNoMatchMessage = false
        suggestedTasks = []
        
        do {
            // Fetch flexible tasks from repository
            let flexibleTasks = try await repository.getFlexibleTasks()
            
            // Generate suggestions using the engine
            let suggestions = suggestionEngine.suggestTasks(
                tasks: flexibleTasks,
                moodEnergyLevel: energyLevel,
                scheduledTaskIds: scheduledTaskIds
            )
            
            // Update UI state based on results
            if suggestions.isEmpty {
                showNoMatchMessage = true
            } else {
                suggestedTasks = suggestions
            }
            
        } catch {
            // Handle errors gracefully with user-friendly messages
            if let repoError = error as? DataRepositoryError {
                errorMessage = repoError.errorDescription
            } else {
                errorMessage = "Failed to load task suggestions. Please try again."
            }
        }
        
        isLoading = false
    }
}
