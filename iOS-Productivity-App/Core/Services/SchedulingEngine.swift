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
    
    // MARK: - Smart Time Slot Selection for Suggested Tasks
    
    /// Finds the best available time slot for a suggested task based on energy level and time of day preferences
    /// Returns nil if no suitable slot is available
    func findBestTimeSlotForTask(
        task: Task,
        energyLevel: String,
        scheduledTasks: [ScheduledTask],
        commitments: [FixedCommitment],
        date: Date
    ) -> (startTime: Date, endTime: Date)? {
        print("🔵 [findBestTimeSlotForTask] Starting for task: \(task.title), energy: \(energyLevel)")
        
        // Get task duration (use estimatedDuration from Task model)
        let taskDuration = task.estimatedDuration
        print("🔵 [findBestTimeSlotForTask] Task duration: \(taskDuration / 60) minutes")
        
        // Convert scheduled tasks to temporary commitments for free time calculation
        let scheduledTaskCommitments = scheduledTasks.map { scheduledTask in
            FixedCommitment(
                id: UUID().uuidString,
                userId: "temp",
                title: "Scheduled Task",
                startTime: scheduledTask.startTime,
                endTime: scheduledTask.endTime
            )
        }
        
        // Combine actual commitments with scheduled task commitments
        let allOccupiedTime = commitments + scheduledTaskCommitments
        
        // Find free time slots
        let freeSlots = findFreeTimeSlots(for: date, commitments: allOccupiedTime)
        print("🔵 [findBestTimeSlotForTask] Found \(freeSlots.count) free slots")
        
        // Filter slots that can fit the task
        let viableSlots = freeSlots.filter { slot in
            slot.duration >= taskDuration
        }
        
        if viableSlots.isEmpty {
            print("⚠️ [findBestTimeSlotForTask] No viable slots found")
            return nil
        }
        
        print("🔵 [findBestTimeSlotForTask] Found \(viableSlots.count) viable slots")
        
        // Score each slot, considering optimal placement within the slot
        let calendar = Calendar.current
        var scoredSlots: [(slot: FreeTimeSlot, score: Double, optimalStart: Date)] = []
        
        for slot in viableSlots {
            // Find the optimal start time within this slot
            let optimalStart = findOptimalStartTimeInSlot(
                slot: slot,
                taskDuration: taskDuration,
                taskEnergyLevel: task.energyLevel,
                currentEnergyLevel: energyLevel,
                priorityLevel: task.priorityLevel,
                calendar: calendar
            )
            
            let energyScore = calculateEnergyMatchScore(
                taskEnergy: task.energyLevel,
                currentEnergy: energyLevel,
                slotStart: optimalStart,
                calendar: calendar
            )
            
            let sizeScore = calculateBlockSizeScore(
                slotDuration: slot.duration,
                taskDuration: taskDuration
            )
            
            let timeScore = calculateTimeOfDayScore(
                priorityLevel: task.priorityLevel,
                slotStart: optimalStart,
                calendar: calendar
            )
            
            // Weighted total score
            let totalScore = (energyScore * 0.4) + (sizeScore * 0.3) + (timeScore * 0.3)
            
            print("🔵 [findBestTimeSlotForTask] Slot at \(optimalStart): energy=\(energyScore), size=\(sizeScore), time=\(timeScore), total=\(totalScore)")
            
            scoredSlots.append((slot: slot, score: totalScore, optimalStart: optimalStart))
        }
        
        // Sort by score descending, with tie-breaker for equal scores
        guard let bestSlot = scoredSlots.sorted(by: { slot1, slot2 in
            // Primary: Sort by score (higher is better)
            if abs(slot1.score - slot2.score) > 0.01 {  // Use tolerance for floating-point comparison
                return slot1.score > slot2.score
            }
            
            // Tie-breaker: For low-energy tasks, prefer later slots
            // For high-energy tasks, prefer earlier slots
            if energyLevel == "low" || task.energyLevel == "low" {
                return slot1.optimalStart > slot2.optimalStart  // Later is better
            } else if energyLevel == "high" || task.energyLevel == "high" {
                return slot1.optimalStart < slot2.optimalStart  // Earlier is better
            }
            
            // Default: Prefer later slots for flexibility
            return slot1.optimalStart > slot2.optimalStart
        }).first else {
            return nil
        }
        
        print("✅ [findBestTimeSlotForTask] Best slot selected with score: \(bestSlot.score)")
        
        // Return the time slot for the task using optimal start time
        let startTime = bestSlot.optimalStart
        let endTime = startTime.addingTimeInterval(taskDuration)
        
        return (startTime: startTime, endTime: endTime)
    }
    
    // MARK: - Helper: Find Optimal Start Time Within Slot
    
    private func findOptimalStartTimeInSlot(
        slot: FreeTimeSlot,
        taskDuration: TimeInterval,
        taskEnergyLevel: String,
        currentEnergyLevel: String,
        priorityLevel: Int,
        calendar: Calendar
    ) -> Date {
        // For slots that are exactly the task duration or only slightly larger, use slot start
        if slot.duration < taskDuration * 1.2 {
            return slot.startTime
        }
        
        // For larger slots, try to find a better start time based on energy preferences
        let slotStartHour = calendar.component(.hour, from: slot.startTime)
        let slotEndTime = slot.startTime.addingTimeInterval(slot.duration)
        let slotEndHour = calendar.component(.hour, from: slotEndTime)
        
        // Check if slot spans into afternoon (handles midnight wrap-around)
        // A slot spans into afternoon if it starts before noon AND (ends after noon OR extends to/past midnight)
        let slotSpansAfternoon = slotStartHour < 12 && (slotEndHour >= 12 || slotEndHour < slotStartHour)
        
        // High energy tasks prefer morning (6-12)
        if (taskEnergyLevel == "high" || currentEnergyLevel == "high") && priorityLevel <= 2 {
            // If slot starts before or in morning, use start
            if slotStartHour < 12 {
                return slot.startTime
            }
            // If slot is entirely after morning, use start
            return slot.startTime
        }
        
        // Low energy tasks prefer afternoon (12-18)
        if taskEnergyLevel == "low" || currentEnergyLevel == "low" {
            // If slot spans into afternoon, start at noon or later
            if slotSpansAfternoon {
                // Calculate time at noon
                let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: slot.startTime)!
                
                // Make sure there's enough room for the task after noon
                let remainingDuration = slotEndTime.timeIntervalSince(noon)
                if remainingDuration >= taskDuration {
                    return noon
                }
            }
            
            // If slot is entirely in afternoon, use start
            if slotStartHour >= 12 {
                return slot.startTime
            }
        }
        
        // Default: Use slot start time
        return slot.startTime
    }
    
    // MARK: - Scoring Helper Methods
    
    private func calculateEnergyMatchScore(
        taskEnergy: String,
        currentEnergy: String,
        slotStart: Date,
        calendar: Calendar
    ) -> Double {
        let hour = calendar.component(.hour, from: slotStart)
        let isMorning = hour >= 6 && hour < 12
        let isAfternoon = hour >= 12 && hour < 18
        
        // High energy task scoring
        if taskEnergy == "high" {
            if currentEnergy == "high" {
                return isMorning ? 1.0 : 0.6
            } else if currentEnergy == "low" {
                return isMorning ? 0.5 : 0.4
            } else { // medium
                return isMorning ? 0.8 : 0.6
            }
        }
        
        // Low energy task scoring
        if taskEnergy == "low" {
            if currentEnergy == "low" {
                return isAfternoon ? 1.0 : 0.6
            } else if currentEnergy == "high" {
                return isAfternoon ? 0.5 : 0.4
            } else { // medium
                return isAfternoon ? 0.8 : 0.6
            }
        }
        
        // "Any" energy task scoring
        if taskEnergy == "any" {
            return 0.7 // Neutral score regardless of time
        }
        
        return 0.5 // Default fallback
    }
    
    private func calculateBlockSizeScore(
        slotDuration: TimeInterval,
        taskDuration: TimeInterval
    ) -> Double {
        // Prefer larger blocks for flexibility
        // Use logarithmic scale to reward larger blocks without capping too early
        let ratio = slotDuration / taskDuration
        
        if ratio < 1.0 {
            // Slot too small - should be filtered out earlier, but score low
            return ratio * 0.5
        } else if ratio <= 1.5 {
            // Comfortable fit - linear scale 0.5 to 0.8
            return 0.5 + (ratio - 1.0) * 0.6
        } else {
            // Larger blocks - logarithmic bonus up to 1.0
            // log2(ratio) scaled so that 4x task duration = 1.0
            let logBonus = log2(ratio / 1.5) / log2(4.0 / 1.5)
            return min(1.0, 0.8 + (logBonus * 0.2))
        }
    }
    
    private func calculateTimeOfDayScore(
        priorityLevel: Int,
        slotStart: Date,
        calendar: Calendar
    ) -> Double {
        let hour = calendar.component(.hour, from: slotStart)
        
        // High priority tasks (Level 1-2) prefer morning
        if priorityLevel <= 2 {
            if hour >= 6 && hour < 12 {
                return 1.0
            } else if hour >= 12 && hour < 18 {
                return 0.6
            } else {
                return 0.4
            }
        }
        
        // Low priority tasks (Level 4-5) prefer later in day
        if priorityLevel >= 4 {
            if hour >= 14 && hour < 20 {
                return 1.0
            } else if hour >= 12 && hour < 14 {
                return 0.7
            } else {
                return 0.5
            }
        }
        
        // Medium priority (Level 3) - no strong preference
        return 0.7
    }
}
