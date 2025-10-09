//
//  TaskSuggestionView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-09.
//

import SwiftUI

struct TaskSuggestionView: View {
    @Binding var isPresented: Bool
    let currentEnergyLevel: String
    let scheduledTaskIds: Set<String>
    let onTaskSelected: (Task) -> Void
    
    @ObservedObject var viewModel: TaskSuggestionViewModel
    
    init(isPresented: Binding<Bool>, currentEnergyLevel: String, scheduledTaskIds: Set<String>, repository: DataRepository, onTaskSelected: @escaping (Task) -> Void) {
        self._isPresented = isPresented
        self.currentEnergyLevel = currentEnergyLevel
        self.scheduledTaskIds = scheduledTaskIds
        self.onTaskSelected = onTaskSelected
        self.viewModel = TaskSuggestionViewModel(repository: repository)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with mood indicator
                    headerView
                        .padding()
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if viewModel.showNoMatchMessage {
                        emptyStateView
                    } else if !viewModel.suggestedTasks.isEmpty {
                        suggestionsListView
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            _Concurrency.Task {
                await viewModel.generateSuggestions(
                    for: currentEnergyLevel,
                    scheduledTaskIds: scheduledTaskIds
                )
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(energyIcon)
                .font(.system(size: 48))
            
            Text("\(energyLabel) Suggestions")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Based on your current energy level")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var energyIcon: String {
        switch currentEnergyLevel {
        case "high": return "⚡️"
        case "medium": return "🔋"
        case "low": return "😴"
        default: return "✨"
        }
    }
    
    private var energyLabel: String {
        switch currentEnergyLevel {
        case "high": return "High Energy"
        case "medium": return "Medium Energy"
        case "low": return "Low Energy"
        default: return "Energy"
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Finding perfect tasks for you...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No matching tasks right now")
                .font(.headline)
            
            Text("Try adding more flexible tasks with this energy level!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Suggestions List View
    
    private var suggestionsListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.suggestedTasks) { suggestedTask in
                    suggestionCard(for: suggestedTask)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
        }
    }
    
    private func suggestionCard(for suggestedTask: SuggestedTask) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task title
            Text(suggestedTask.task.title)
                .font(.headline)
            
            // Match reason with badge
            HStack(spacing: 8) {
                matchQualityBadge(for: suggestedTask)
                
                Text(suggestedTask.displayReason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Task details
            HStack(spacing: 16) {
                Label(
                    "\(Int(suggestedTask.task.estimatedDuration / 60)) min",
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                
                Label(
                    "Priority \(suggestedTask.task.priorityLevel)",
                    systemImage: "flag"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Action button placeholder (will be implemented in Story 3.4)
            Button(action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Call the callback with the selected task
                onTaskSelected(suggestedTask.task)
                
                // Dismiss the sheet
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add to Schedule")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func matchQualityBadge(for suggestedTask: SuggestedTask) -> some View {
        let (emoji, label) = matchQualityInfo(for: suggestedTask.matchReason)
        
        return HStack(spacing: 4) {
            Text(emoji)
                .font(.caption)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(matchQualityColor(for: suggestedTask.matchReason).opacity(0.2))
        .foregroundColor(matchQualityColor(for: suggestedTask.matchReason))
        .cornerRadius(6)
    }
    
    private func matchQualityInfo(for matchReason: String) -> (String, String) {
        switch matchReason {
        case "high-energy-match", "low-energy-match":
            return ("✨", "Perfect Match")
        case "any-energy":
            return ("👍", "Good Fit")
        case "medium-high-match", "medium-low-match":
            return ("💡", "Worth Trying")
        default:
            return ("⭐️", "Recommended")
        }
    }
    
    private func matchQualityColor(for matchReason: String) -> Color {
        switch matchReason {
        case "high-energy-match", "low-energy-match":
            return .green
        case "any-energy":
            return .blue
        case "medium-high-match", "medium-low-match":
            return .orange
        default:
            return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    TaskSuggestionView(
        isPresented: .constant(true),
        currentEnergyLevel: "high",
        scheduledTaskIds: [],
        repository: DataRepository(authManager: AuthManager()),
        onTaskSelected: { task in
            print("Selected task: \(task.title)")
        }
    )
}
