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
                } header: {
                    Text("Priority")
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
