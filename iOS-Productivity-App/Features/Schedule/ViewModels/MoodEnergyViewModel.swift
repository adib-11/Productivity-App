//
//  MoodEnergyViewModel.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-08.
//

import Foundation
import SwiftUI

@MainActor
class MoodEnergyViewModel: ObservableObject {
    @Published var selectedEnergyLevel: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: DataRepository
    
    var energyLevelOptions: [String] {
        return ["high", "medium", "low"]
    }
    
    init(repository: DataRepository) {
        self.repository = repository
    }
    
    func saveMoodEnergyState() async {
        guard let energyLevel = selectedEnergyLevel else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let moodState = MoodEnergyState(
                userId: "", // Will be set by repository
                energyLevel: energyLevel
            )
            
            try await repository.saveMoodEnergyState(moodState)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadCurrentMoodState() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let currentState = try await repository.getCurrentMoodEnergyState() {
                selectedEnergyLevel = currentState.energyLevel
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}