//
//  ManageCommitmentsView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

struct ManageCommitmentsView: View {
    @StateObject private var viewModel: CommitmentViewModel
    @State private var showingAddCommitment = false
    @State private var showingEditCommitment = false
    
    init(repository: DataRepository) {
        _viewModel = StateObject(wrappedValue: CommitmentViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.commitments.isEmpty {
                    ProgressView("Loading commitments...")
                } else if viewModel.commitments.isEmpty {
                    emptyStateView
                } else {
                    commitmentsList
                }
            }
            .navigationTitle("Fixed Commitments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCommitment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCommitment) {
                CommitmentFormView(viewModel: viewModel, isPresented: $showingAddCommitment)
            }
            .sheet(isPresented: $showingEditCommitment) {
                CommitmentFormView(viewModel: viewModel, isPresented: $showingEditCommitment)
            }
            .task {
                await viewModel.loadCommitments()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No commitments yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to add your first fixed commitment")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var commitmentsList: some View {
        List {
            ForEach(viewModel.commitments) { commitment in
                CommitmentRow(commitment: commitment)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.loadCommitmentForEditing(commitment)
                        showingEditCommitment = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            _Concurrency.Task {
                                await viewModel.deleteCommitment(commitment)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct CommitmentRow: View {
    let commitment: FixedCommitment
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(commitment.title)
                .font(.headline)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(commitment.startTime, formatter: dateFormatter) - \(commitment.endTime, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ManageCommitmentsView(repository: DataRepository(authManager: AuthManager()))
}
