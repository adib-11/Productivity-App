//
//  TaskInboxView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

struct TaskInboxView: View {
    @EnvironmentObject private var dataRepository: DataRepository
    @StateObject private var viewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var showingEditTask = false
    
    init(dataRepository: DataRepository) {
        _viewModel = StateObject(wrappedValue: TaskViewModel(repository: dataRepository))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView("Loading tasks...")
                } else if viewModel.tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Task Inbox")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.resetForm()
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                TaskFormView(viewModel: viewModel, isPresented: $showingAddTask)
            }
            .sheet(isPresented: $showingEditTask) {
                if let task = viewModel.editingTask {
                    TaskFormView(viewModel: viewModel, isPresented: $showingEditTask, taskToEdit: task)
                }
            }
            .task {
                await viewModel.loadTasks()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private var taskListView: some View {
        List {
            ForEach(viewModel.tasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.loadTaskForEditing(task)
                        showingEditTask = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            _Concurrency.Task {
                                await viewModel.deleteTask(task)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadTasks()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to add your first task")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct TaskRowView: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button {
                _Concurrency.Task {
                    await viewModel.toggleTaskCompletion(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Task title
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    // Priority badge
                    Text(task.priority.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(for: task.priority))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    // Energy level indicator
                    HStack(spacing: 2) {
                        Text(energyIcon(for: task.energyLevel))
                            .font(.caption)
                        Text(task.energyLevel.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "must-do":
            return Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
        case "flexible":
            return Color(red: 0.0, green: 0.48, blue: 1.0)  // #007AFF
        default:
            return .blue
        }
    }
    
    private func energyIcon(for energyLevel: String) -> String {
        switch energyLevel.lowercased() {
        case "high":
            return "⚡️"
        case "low":
            return "🌙"
        case "any":
            return "⭐️"
        default:
            return "⭐️"
        }
    }
}
