//
//  SchedulingEngine.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation

class SchedulingEngine {
    let configuration: SchedulingConfiguration
    
    init(configuration: SchedulingConfiguration = SchedulingConfiguration()) {
        self.configuration = configuration
    }
    
    func findFreeTimeSlots(
        for date: Date,
        commitments: [FixedCommitment]
    ) -> [FreeTimeSlot] {
        let calendar = Calendar.current
        
        // Step 1: Calculate work day boundaries
        guard let workStart = calendar.date(
            bySettingHour: configuration.workDayStart,
            minute: 0,
            second: 0,
            of: date
        ) else {
            return []
        }
        
        // Handle midnight (24:00) as start of next day
        let workEnd: Date
        if configuration.workDayEnd == 24 {
            // Midnight = start of next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) else {
                return []
            }
            workEnd = nextDay
        } else {
            guard let end = calendar.date(
                bySettingHour: configuration.workDayEnd,
                minute: 0,
                second: 0,
                of: date
            ) else {
                return []
            }
            workEnd = end
        }
        
        // Step 2: Filter commitments to work hours and sort
        let filteredCommitments = filterCommitmentsToWorkHours(commitments, workStart: workStart, workEnd: workEnd)
        let sortedCommitments = filteredCommitments.sorted { $0.startTime < $1.startTime }
        
        // Step 3: Merge overlapping commitments
        let mergedCommitments = mergeOverlappingCommitments(sortedCommitments)
        
        // Step 4: Handle empty commitments case
        if mergedCommitments.isEmpty {
            return [FreeTimeSlot(startTime: workStart, endTime: workEnd)]
        }
        
        // Step 5: Find gaps
        var freeSlots: [FreeTimeSlot] = []
        
        // Gap before first commitment
        if let firstCommitment = mergedCommitments.first,
           firstCommitment.startTime > workStart {
            let slotEnd = firstCommitment.startTime
            let slotDuration = slotEnd.timeIntervalSince(workStart)
            
            if slotDuration >= configuration.minimumTaskDuration {
                freeSlots.append(FreeTimeSlot(startTime: workStart, endTime: slotEnd))
            }
        }
        
        // Gaps between commitments
        for i in 0..<(mergedCommitments.count - 1) {
            let current = mergedCommitments[i]
            let next = mergedCommitments[i + 1]
            
            let slotStart = current.endTime.addingTimeInterval(configuration.minimumGapBetweenEvents)
            let slotEnd = next.startTime
            let slotDuration = slotEnd.timeIntervalSince(slotStart)
            
            if slotDuration >= configuration.minimumTaskDuration {
                freeSlots.append(FreeTimeSlot(startTime: slotStart, endTime: slotEnd))
            }
        }
        
        // Gap after last commitment
        if let lastCommitment = mergedCommitments.last,
           lastCommitment.endTime < workEnd {
            let slotStart = lastCommitment.endTime.addingTimeInterval(configuration.minimumGapBetweenEvents)
            let slotDuration = workEnd.timeIntervalSince(slotStart)
            
            if slotDuration >= configuration.minimumTaskDuration {
                freeSlots.append(FreeTimeSlot(startTime: slotStart, endTime: workEnd))
            }
        }
        
        return freeSlots
    }
    
    // MARK: - Helper Methods
    
    private func mergeOverlappingCommitments(_ commitments: [FixedCommitment]) -> [FixedCommitment] {
        guard !commitments.isEmpty else { return [] }
        
        var merged: [FixedCommitment] = []
        var current = commitments[0]
        
        for i in 1..<commitments.count {
            let next = commitments[i]
            
            if next.startTime <= current.endTime {
                // Overlapping: merge by extending endTime
                let mergedEnd = max(current.endTime, next.endTime)
                current = FixedCommitment(
                    id: current.id,
                    userId: current.userId,
                    title: current.title,
                    startTime: current.startTime,
                    endTime: mergedEnd
                )
            } else {
                // No overlap: save current and move to next
                merged.append(current)
                current = next
            }
        }
        
        merged.append(current)
        return merged
    }
    
    private func filterCommitmentsToWorkHours(_ commitments: [FixedCommitment], workStart: Date, workEnd: Date) -> [FixedCommitment] {
        return commitments.compactMap { commitment in
            // Filter out commitments completely outside work hours
            if commitment.endTime <= workStart || commitment.startTime >= workEnd {
                return nil
            }
            
            // Adjust commitments that partially overlap work hours
            let adjustedStart = max(commitment.startTime, workStart)
            let adjustedEnd = min(commitment.endTime, workEnd)
            
            if adjustedStart != commitment.startTime || adjustedEnd != commitment.endTime {
                return FixedCommitment(
                    id: commitment.id,
                    userId: commitment.userId,
                    title: commitment.title,
                    startTime: adjustedStart,
                    endTime: adjustedEnd
                )
            }
            
            return commitment
        }
    }
}
