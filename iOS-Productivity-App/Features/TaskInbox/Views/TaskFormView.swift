//
//  TaskFormView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

struct TaskFormView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    let taskToEdit: Task?
    
    init(viewModel: TaskViewModel, isPresented: Binding<Bool>, taskToEdit: Task? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.taskToEdit = taskToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title...", text: $viewModel.title)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Title")
                }
                
                Section {
                    Picker("Priority", selection: $viewModel.priority) {
                        Text("Flexible").tag("flexible")
                        Text("Must-Do").tag("must-do")
                    }
                    .pickerStyle(.segmented)
                    
                    // Show priority level picker only for must-do tasks
                    if viewModel.priority == "must-do" {
                        Picker("Urgency", selection: $viewModel.priorityLevel) {
                            Text("🔴 Critical").tag(1)
                            Text("🟠 High").tag(2)
                            Text("🟡 Medium").tag(3)
                            Text("🟢 Low").tag(4)
                            Text("🔵 Minimal").tag(5)
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Priority")
                } footer: {
                    if viewModel.priority == "must-do" {
                        Text("Urgency determines the order tasks are scheduled. Critical tasks are scheduled first.")
                    }
                }
                
                Section {
                    Picker("Energy Level", selection: $viewModel.energyLevel) {
                        Text("⚡️ High").tag("high")
                        Text("🌙 Low").tag("low")
                        Text("⭐️ Any").tag("any")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Energy Level")
                }
                
                Section {
                    Picker("Estimated Duration", selection: $viewModel.estimatedDuration) {
                        Text("15 min").tag(TimeInterval(900))
                        Text("30 min").tag(TimeInterval(1800))
                        Text("45 min").tag(TimeInterval(2700))
                        Text("1 hour").tag(TimeInterval(3600))
                        Text("1.5 hours").tag(TimeInterval(5400))
                        Text("2 hours").tag(TimeInterval(7200))
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Estimated Duration")
                } footer: {
                    Text("How long do you think this task will take?")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Task" : "Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        _Concurrency.Task {
                            if let task = taskToEdit {
                                await viewModel.updateTask(task)
                            } else {
                                await viewModel.createTask()
                            }
                            
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}
