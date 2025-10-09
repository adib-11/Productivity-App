//
//  MoodEnergySelector.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-08.
//

import SwiftUI

struct MoodEnergySelector: View {
    @StateObject private var viewModel: MoodEnergyViewModel
    @Binding var isPresented: Bool
    let onSelectionComplete: (String) -> Void
    
    private let energyOptions = [
        ("high", "⚡️ High Energy", "for focused, demanding tasks"),
        ("medium", "🔋 Medium Energy", "for moderate tasks"),
        ("low", "😴 Low Energy", "for light, easy tasks")
    ]
    
    init(repository: DataRepository, isPresented: Binding<Bool>, onSelectionComplete: @escaping (String) -> Void) {
        self._viewModel = StateObject(wrappedValue: MoodEnergyViewModel(repository: repository))
        self._isPresented = isPresented
        self.onSelectionComplete = onSelectionComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("How's your energy level?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("This helps us suggest the right tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Energy Level Options
                VStack(spacing: 16) {
                    ForEach(energyOptions, id: \.0) { option in
                        EnergyOptionButton(
                            energyLevel: option.0,
                            title: option.1,
                            description: option.2,
                            isSelected: viewModel.selectedEnergyLevel == option.0,
                            onTap: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                viewModel.selectedEnergyLevel = option.0
                            }
                        )
                    }
                }
                
                Spacer()
                
                // Done Button
                Button(action: {
                    if let selectedLevel = viewModel.selectedEnergyLevel {
                        _Concurrency.Task {
                            await viewModel.saveMoodEnergyState()
                            onSelectionComplete(selectedLevel)
                            isPresented = false
                        }
                    }
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.selectedEnergyLevel != nil ? Color.accentColor : Color.gray
                        )
                        .cornerRadius(12)
                }
                .disabled(viewModel.selectedEnergyLevel == nil || viewModel.isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Energy Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .task {
            await viewModel.loadCurrentMoodState()
        }
    }
}

struct EnergyOptionButton: View {
    let energyLevel: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct MoodEnergySelector_Previews: PreviewProvider {
    static var previews: some View {
        MoodEnergySelector(
            repository: DataRepository(authManager: AuthManager()),
            isPresented: .constant(true)
        ) { _ in
            // Preview callback
        }
    }
}
#endif