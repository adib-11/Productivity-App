//
//  CommitmentFormView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

struct CommitmentFormView: View {
    @ObservedObject var viewModel: CommitmentViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Commitment Details")) {
                    TextField("Title", text: $viewModel.title)
                        .textInputAutocapitalization(.words)
                }
                
                Section(header: Text("Start Time")) {
                    DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.automatic)
                }
                
                Section(header: Text("End Time")) {
                    DatePicker("End Time", selection: $viewModel.endTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.automatic)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Commitment" : "Add Commitment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        isPresented = false
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        _Concurrency.Task {
                            await viewModel.saveCommitment()
                            if viewModel.errorMessage == nil {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.title.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
}

#Preview {
    CommitmentFormView(
        viewModel: CommitmentViewModel(repository: DataRepository(authManager: AuthManager())),
        isPresented: .constant(true)
    )
}
