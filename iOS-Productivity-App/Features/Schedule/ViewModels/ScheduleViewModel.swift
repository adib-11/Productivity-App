//
//  ScheduleViewModel.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation
import SwiftUI

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var commitments: [FixedCommitment] = []
    @Published var timeBlocks: [TimeBlock] = []
    @Published var currentDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: DataRepository
    
    init(repository: DataRepository) {
        self.repository = repository
    }
    
    func loadCommitments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            commitments = try await repository.fetchCommitments(for: currentDate)
            generateTimeBlocks()
        } catch {
            errorMessage = "Unable to load your schedule. Please check your connection and try again."
        }
        
        isLoading = false
    }
    
    func generateTimeBlocks() {
        timeBlocks = commitments.map { commitment in
            TimeBlock(
                title: commitment.title,
                startTime: commitment.startTime,
                endTime: commitment.endTime,
                type: .commitment
            )
        }
    }
    
    func getCurrentTimeOffset() -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        
        let startHour = 6
        let hourHeight: CGFloat = 60
        
        let hoursSinceStart = hour - startHour
        let minuteOffset = CGFloat(minute)
        
        return CGFloat(hoursSinceStart) * hourHeight + minuteOffset
    }
    
    var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
