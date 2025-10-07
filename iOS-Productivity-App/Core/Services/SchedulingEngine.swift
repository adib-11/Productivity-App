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
        let now = Date()
        
        // Step 1: Calculate work day boundaries
        guard let workStart = calendar.date(
            bySettingHour: configuration.workDayStart,
            minute: 0,
            second: 0,
            of: date
        ) else {
            return []
        }
        
        // Use current time as start if we're scheduling for today and it's after work start
        let effectiveWorkStart = calendar.isDateInToday(date) ? max(workStart, now) : workStart
        
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
        let filteredCommitments = filterCommitmentsToWorkHours(commitments, workStart: effectiveWorkStart, workEnd: workEnd)
        let sortedCommitments = filteredCommitments.sorted { $0.startTime < $1.startTime }
        
        // Step 3: Merge overlapping commitments
        let mergedCommitments = mergeOverlappingCommitments(sortedCommitments)
        
        // Step 4: Handle empty commitments case
        if mergedCommitments.isEmpty {
            return [FreeTimeSlot(startTime: effectiveWorkStart, endTime: workEnd)]
        }
        
        // Step 5: Find gaps
        var freeSlots: [FreeTimeSlot] = []
        
        // Gap before first commitment
        if let firstCommitment = mergedCommitments.first,
           firstCommitment.startTime > effectiveWorkStart {
            let slotEnd = firstCommitment.startTime
            let slotDuration = slotEnd.timeIntervalSince(effectiveWorkStart)
            
            if slotDuration >= configuration.minimumTaskDuration {
                freeSlots.append(FreeTimeSlot(startTime: effectiveWorkStart, endTime: slotEnd))
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
    
    // MARK: - Task Scheduling
    
    func scheduleMustDoTasks(
        tasks: [Task],
        freeSlots: [FreeTimeSlot],
        for date: Date
    ) -> (scheduled: [ScheduledTask], unscheduled: [Task]) {
        // Step 1: Filter and sort tasks by priority level (1 = highest priority)
        let mustDoTasks = tasks
            .filter { $0.priority == "must-do" && !$0.isCompleted }
            .sorted { task1, task2 in
                // Sort by priorityLevel first (lower number = higher priority)
                if task1.priorityLevel != task2.priorityLevel {
                    return task1.priorityLevel < task2.priorityLevel
                }
                // If same priority level, sort by creation time (FIFO)
                return task1.createdAt < task2.createdAt
            }
        
        // Step 2: Sort free slots by start time
        let sortedSlots = freeSlots.sorted { $0.startTime < $1.startTime }
        
        // Step 3: Initialize results
        var scheduledTasks: [ScheduledTask] = []
        var remainingTasks: [Task] = []
        
        // Step 4: Track available slots (mutable copy)
        var availableSlots = sortedSlots.map { slot in
            (startTime: slot.startTime, endTime: slot.endTime)
        }
        
        // Step 5: Iterate through must-do tasks
        for task in mustDoTasks {
            var taskScheduled = false
            let taskDuration = task.estimatedDuration // Use task's estimated duration
            
            // Try to find a slot that fits the task duration
            for (index, slot) in availableSlots.enumerated() {
                let slotDuration = slot.endTime.timeIntervalSince(slot.startTime)
                
                if slotDuration >= taskDuration {
                    // Schedule with task's estimated duration
                    let startTime = slot.startTime
                    let endTime = startTime.addingTimeInterval(taskDuration)
                    
                    let scheduledTask = ScheduledTask(
                        taskId: task.id ?? "",
                        date: date,
                        startTime: startTime,
                        endTime: endTime
                    )
                    
                    scheduledTasks.append(scheduledTask)
                    
                    // Update available slot (consume the scheduled time + add gap for next task)
                    let nextAvailableTime = endTime.addingTimeInterval(configuration.minimumGapBetweenEvents)
                    availableSlots[index] = (startTime: nextAvailableTime, endTime: slot.endTime)
                    
                    taskScheduled = true
                    break
                }
            }
            
            // If not scheduled, add to unscheduled list
            if !taskScheduled {
                remainingTasks.append(task)
            }
        }
        
        return (scheduledTasks, remainingTasks)
    }
    
    // MARK: - Helper Methods for Task Scheduling
    
    private func canFitTask(in slot: FreeTimeSlot, taskDuration: TimeInterval) -> Bool {
        return slot.duration >= taskDuration
    }
}
