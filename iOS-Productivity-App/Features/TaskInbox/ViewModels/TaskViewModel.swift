//
//  TaskViewModel.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Form properties
    @Published var title = ""
    @Published var priority = "flexible"
    @Published var priorityLevel: Int = 3 // Default medium priority
    @Published var energyLevel = "any"
    @Published var estimatedDuration: TimeInterval = 1800 // Default 30 minutes
    
    // Edit mode
    @Published var editingTask: Task?
    
    private let repository: DataRepository
    
    var isEditMode: Bool {
        editingTask != nil
    }
    
    init(repository: DataRepository) {
        self.repository = repository
    }
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedTasks = try await repository.fetchTasks()
            // Sort tasks: unchecked (incomplete) first, then checked (completed)
            // Within each group, sort alphabetically by title
            tasks = fetchedTasks.sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted // False (uncompleted) comes before True (completed)
                }
                return task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createTask() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let task = Task(
            userId: "", // Will be set by repository
            title: title,
            priority: priority,
            priorityLevel: priorityLevel,
            energyLevel: energyLevel,
            estimatedDuration: estimatedDuration
        )
        
        do {
            try await repository.createTask(task)
            await loadTasks()
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateTask(_ task: Task) async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        var updatedTask = task
        updatedTask.title = title
        updatedTask.priority = priority
        updatedTask.priorityLevel = priorityLevel
        updatedTask.energyLevel = energyLevel
        updatedTask.estimatedDuration = estimatedDuration
        
        do {
            try await repository.updateTask(updatedTask)
            await loadTasks()
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleTaskCompletion(_ task: Task) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        
        do {
            try await repository.updateTask(updatedTask)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteTask(_ task: Task) async {
        guard let taskId = task.id else {
            errorMessage = "Cannot delete task without ID."
            return
        }
        
        do {
            try await repository.deleteTask(taskId)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func validateInput() -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            errorMessage = "Title cannot be empty."
            return false
        }
        
        return true
    }
    
    func resetForm() {
        title = ""
        priority = "flexible"
        priorityLevel = 3
        energyLevel = "any"
        estimatedDuration = 1800 // Reset to default 30 minutes
        editingTask = nil
        errorMessage = nil
    }
    
    func loadTaskForEditing(_ task: Task) {
        editingTask = task
        title = task.title
        priority = task.priority
        priorityLevel = task.priorityLevel
        energyLevel = task.energyLevel
        estimatedDuration = task.estimatedDuration
    }
}
