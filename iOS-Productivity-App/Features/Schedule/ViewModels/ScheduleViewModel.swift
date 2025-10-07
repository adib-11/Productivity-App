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
    @Published var freeTimeSlots: [FreeTimeSlot] = []
    @Published var currentDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var scheduledTasks: [ScheduledTask] = []
    @Published var unscheduledMustDoTasks: [Task] = []
    @Published var showInsufficientTimeAlert: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var tasks: [Task] = []
    
    private let repository: DataRepository
    private let schedulingEngine: SchedulingEngine
    
    init(repository: DataRepository, schedulingEngine: SchedulingEngine = SchedulingEngine()) {
        self.repository = repository
        self.schedulingEngine = schedulingEngine
    }
    
    func loadCommitments() async {
        print("🔵 ScheduleViewModel: loadCommitments() called")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔵 ScheduleViewModel: Fetching commitments for date: \(currentDate)")
            commitments = try await repository.fetchCommitments(for: currentDate)
            print("🔵 ScheduleViewModel: Fetched \(commitments.count) commitments")
            
            await loadScheduledTasks()
            await loadTasks()
            
            print("🔵 ScheduleViewModel: Generating time blocks...")
            generateTimeBlocks()
            print("🔵 ScheduleViewModel: Generated \(timeBlocks.count) time blocks")
        } catch {
            print("🔴 ScheduleViewModel: Error loading commitments: \(error)")
            errorMessage = "Unable to load your schedule. Please check your connection and try again."
        }
        
        isLoading = false
        print("🔵 ScheduleViewModel: loadCommitments() completed")
    }
    
    func generateTimeBlocks() {
        print("🟡 generateTimeBlocks: Starting...")
        print("🟡 generateTimeBlocks: Commitments count: \(commitments.count)")
        print("🟡 generateTimeBlocks: Scheduled tasks count: \(scheduledTasks.count)")
        print("🟡 generateTimeBlocks: Tasks count: \(tasks.count)")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }
        
        // Step 1: Filter commitments to current day only
        let todayCommitments = commitments.filter { commitment in
            commitment.startTime >= startOfDay && commitment.startTime < endOfDay
        }
        
        // Create commitment blocks
        var blocks: [TimeBlock] = todayCommitments.map { commitment in
            TimeBlock(
                title: commitment.title,
                startTime: commitment.startTime,
                endTime: commitment.endTime,
                type: .commitment
            )
        }
        
        print("🟡 generateTimeBlocks: Created \(blocks.count) commitment blocks (filtered to today)")
        
        // Step 2: Calculate free time
        calculateFreeTime()
        
        print("🟡 generateTimeBlocks: Free time slots: \(freeTimeSlots.count)")
        
        // Step 3: Create empty blocks from free time slots
        let emptyBlocks = freeTimeSlots.map { slot in
            TimeBlock(from: slot)
        }
        
        print("🟡 generateTimeBlocks: Created \(emptyBlocks.count) empty blocks")
        
        // Step 4: Filter and create scheduled task blocks (only for today)
        let todayScheduledTasks = scheduledTasks.filter { scheduledTask in
            scheduledTask.startTime >= startOfDay && scheduledTask.startTime < endOfDay
        }
        
        for scheduledTask in todayScheduledTasks {
            if let task = tasks.first(where: { $0.id == scheduledTask.taskId }) {
                blocks.append(TimeBlock(from: scheduledTask, taskTitle: task.title))
            }
        }
        
        let taskBlockCount = todayScheduledTasks.count
        print("🟡 generateTimeBlocks: Created \(taskBlockCount) task blocks (filtered to today)")
        
        // Step 5: Combine and sort
        blocks.append(contentsOf: emptyBlocks)
        timeBlocks = blocks.sorted { $0.startTime < $1.startTime }
        
        print("🟡 generateTimeBlocks: Final time blocks count: \(timeBlocks.count)")
        print("🟡 generateTimeBlocks: Completed")
    }
    
    func calculateFreeTime() {
        freeTimeSlots = schedulingEngine.findFreeTimeSlots(
            for: currentDate,
            commitments: commitments
        )
    }
    
    func getCurrentTimeOffset() -> CGFloat {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        let configuration = schedulingEngine.configuration
        let startHour = configuration.workDayStart
        let endHour = configuration.workDayEnd
        let hourHeight: CGFloat = 60
        
        let hoursSinceStart = hour - startHour
        let minuteOffset = CGFloat(minute)
        let rawOffset = CGFloat(hoursSinceStart) * hourHeight + minuteOffset
        let maxOffset = CGFloat(max(0, (endHour - startHour) * 60))
        
        return min(max(rawOffset, 0), maxOffset)
    }
    
    var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    // MARK: - Task Scheduling
    
    func loadTasks() async {
        do {
            tasks = try await repository.fetchTasks()
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
    }
    
    func loadScheduledTasks() async {
        do {
            scheduledTasks = try await repository.fetchScheduledTasks(for: currentDate)
        } catch {
            errorMessage = "Failed to load scheduled tasks: \(error.localizedDescription)"
        }
    }
    
    func scheduleAutomaticTasks() async {
        print("🟣 scheduleAutomaticTasks: Starting...")
        isLoading = true
        errorMessage = nil
        showInsufficientTimeAlert = false
        
        do {
            // Step 1: Fetch all tasks from repository
            let allTasks = try await repository.fetchTasks()
            print("🟣 scheduleAutomaticTasks: Fetched \(allTasks.count) total tasks")
            
            let mustDoTasks = allTasks.filter { $0.priority == "must-do" && !$0.isCompleted }
            print("🟣 scheduleAutomaticTasks: Found \(mustDoTasks.count) must-do tasks")
            
            // Step 2: Recalculate free time based on current commitments
            calculateFreeTime()
            print("🟣 scheduleAutomaticTasks: Found \(freeTimeSlots.count) free slots")
            
            // Step 3: Call scheduling engine
            let result = schedulingEngine.scheduleMustDoTasks(
                tasks: allTasks,
                freeSlots: freeTimeSlots,
                for: currentDate
            )
            
            print("🟣 scheduleAutomaticTasks: Scheduled \(result.scheduled.count), Unscheduled \(result.unscheduled.count)")
            
            // Step 3.5: Delete existing scheduled tasks for today to prevent duplicates
            print("🟣 scheduleAutomaticTasks: Cleaning up existing scheduled tasks...")
            try await repository.deleteAllScheduledTasks(for: currentDate)
            print("🟣 scheduleAutomaticTasks: Cleanup completed")
            
            // Step 4: Save scheduled tasks to Firestore
            for scheduledTask in result.scheduled {
                try await repository.saveScheduledTask(scheduledTask)
            }
            
            // Step 5: Reload scheduled tasks from Firestore
            await loadScheduledTasks()
            
            // Step 6: Update unscheduled tasks list
            unscheduledMustDoTasks = result.unscheduled
            
            // Step 7: Show appropriate feedback
            if !result.unscheduled.isEmpty {
                showInsufficientTimeAlert = true
            } else if result.scheduled.count > 0 {
                // Show success message only if tasks were scheduled
                successMessage = "✅ Successfully scheduled \(result.scheduled.count) task(s)!"
                showSuccessMessage = true
                
                // Auto-hide success message after 3 seconds
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        showSuccessMessage = false
                    }
                }
            }
            
            // Step 8: Refresh timeline
            await loadTasks()
            generateTimeBlocks()
            
            print("🟣 scheduleAutomaticTasks: Completed successfully")
            
        } catch {
            print("🔴 scheduleAutomaticTasks: Error - \(error)")
            errorMessage = "Failed to schedule tasks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Drag and Drop Operations
    
    func moveScheduledTask(_ block: TimeBlock, to newStartTime: Date) async -> Bool {
        guard let scheduledTaskId = block.scheduledTaskId else {
            // print("❌ [moveScheduledTask] No scheduledTaskId found in block")
            return false
        }
        
        guard let scheduledTask = scheduledTasks.first(where: { $0.id == scheduledTaskId }) else {
            // print("❌ [moveScheduledTask] ScheduledTask not found with id: \(scheduledTaskId)")
            return false
        }
        
        // Calculate new end time based on current duration
        let duration = scheduledTask.duration
        let newEndTime = newStartTime.addingTimeInterval(duration)
        
        // print("🔵 [moveScheduledTask] Attempting to move task from \(scheduledTask.startTime) to \(newStartTime)")
        
        // Validate new time slot
        guard isTimeSlotAvailable(startTime: newStartTime, endTime: newEndTime, excluding: scheduledTaskId) else {
            // print("❌ [moveScheduledTask] Time slot not available")
            return false
        }
        
        // Create updated scheduled task
        var updatedTask = scheduledTask
        updatedTask.startTime = newStartTime
        updatedTask.endTime = newEndTime
        
        do {
            // Update in Firestore
            try await repository.updateScheduledTask(updatedTask)
            
            // Update local array
            if let index = scheduledTasks.firstIndex(where: { $0.id == scheduledTaskId }) {
                scheduledTasks[index] = updatedTask
            }
            
            // Refresh timeline
            generateTimeBlocks()
            
            // print("✅ [moveScheduledTask] Task moved successfully")
            return true
        } catch {
            // print("❌ [moveScheduledTask] Firestore update failed: \(error)")
            errorMessage = "Failed to move task: \(error.localizedDescription)"
            return false
        }
    }
    
    func resizeScheduledTask(_ block: TimeBlock, newDuration: TimeInterval) async -> Bool {
        guard let scheduledTaskId = block.scheduledTaskId else {
            // print("❌ [resizeScheduledTask] No scheduledTaskId found in block")
            return false
        }
        
        guard let scheduledTask = scheduledTasks.first(where: { $0.id == scheduledTaskId }) else {
            // print("❌ [resizeScheduledTask] ScheduledTask not found with id: \(scheduledTaskId)")
            return false
        }
        
        // Validate minimum duration (15 minutes)
        let minimumDuration: TimeInterval = 15 * 60
        guard newDuration >= minimumDuration else {
            // print("❌ [resizeScheduledTask] Duration below minimum (15 minutes)")
            return false
        }
        
        // Calculate new end time
        let newEndTime = scheduledTask.startTime.addingTimeInterval(newDuration)
        
        // print("🔵 [resizeScheduledTask] Attempting to resize task to duration: \(newDuration/60) minutes")
        
        // Validate new end time doesn't overlap
        guard isTimeSlotAvailable(startTime: scheduledTask.startTime, endTime: newEndTime, excluding: scheduledTaskId) else {
            // print("❌ [resizeScheduledTask] New end time overlaps with another block")
            return false
        }
        
        // Validate end time is within day bounds
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay),
              newEndTime <= endOfDay else {
            // print("❌ [resizeScheduledTask] New end time exceeds day bounds")
            return false
        }
        
        // Create updated scheduled task
        var updatedTask = scheduledTask
        updatedTask.endTime = newEndTime
        
        do {
            // Update in Firestore
            try await repository.updateScheduledTask(updatedTask)
            
            // Update local array
            if let index = scheduledTasks.firstIndex(where: { $0.id == scheduledTaskId }) {
                scheduledTasks[index] = updatedTask
            }
            
            // Refresh timeline
            generateTimeBlocks()
            
            // print("✅ [resizeScheduledTask] Task resized successfully")
            return true
        } catch {
            // print("❌ [resizeScheduledTask] Firestore update failed: \(error)")
            errorMessage = "Failed to resize task: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Validation Helpers
    
    private func isTimeSlotAvailable(startTime: Date, endTime: Date, excluding taskId: String?) -> Bool {
        // Check no overlap with commitments
        for commitment in commitments {
            if timeSlotsOverlap(start1: startTime, end1: endTime, start2: commitment.startTime, end2: commitment.endTime) {
                // print("❌ [isTimeSlotAvailable] Overlaps with commitment: \(commitment.title)")
                return false
            }
        }
        
        // Check no overlap with other scheduled tasks (excluding the one being moved/resized)
        for scheduledTask in scheduledTasks {
            if scheduledTask.id != taskId {
                if timeSlotsOverlap(start1: startTime, end1: endTime, start2: scheduledTask.startTime, end2: scheduledTask.endTime) {
                    // print("❌ [isTimeSlotAvailable] Overlaps with scheduled task")
                    return false
                }
            }
        }
        
        // Check if within a free time slot
        let isWithinFreeSlot = freeTimeSlots.contains { slot in
            startTime >= slot.startTime && endTime <= slot.endTime
        }
        
        if !isWithinFreeSlot {
            // print("❌ [isTimeSlotAvailable] Not within any free time slot")
        }
        
        return isWithinFreeSlot
    }
    
    private func timeSlotsOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        return start1 < end2 && end1 > start2
    }
}
