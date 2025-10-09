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
    @Published var currentMoodState: MoodEnergyState?
    
    private let repository: DataRepository
    private let schedulingEngine: SchedulingEngine
    
    // Expose repository for mood selector access
    var dataRepository: DataRepository {
        return repository
    }
    
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
            await loadCurrentMoodState()
            
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
        
        // Step 4: Filter and create scheduled task blocks (only for today, exclude completed tasks)
        let todayScheduledTasks = scheduledTasks.filter { scheduledTask in
            scheduledTask.startTime >= startOfDay && scheduledTask.startTime < endOfDay
        }
        
        for scheduledTask in todayScheduledTasks {
            if let task = tasks.first(where: { $0.id == scheduledTask.taskId }) {
                // Only create TimeBlock if task is not completed
                if !task.isCompleted {
                    blocks.append(TimeBlock(from: scheduledTask, taskTitle: task.title, isCompleted: false))
                } else {
                    print("🟡 generateTimeBlocks: Skipping completed task: \(task.title)")
                }
            }
        }
        
        let taskBlockCount = todayScheduledTasks.filter { scheduledTask in
            if let task = tasks.first(where: { $0.id == scheduledTask.taskId }) {
                return !task.isCompleted
            }
            return true
        }.count
        print("🟡 generateTimeBlocks: Created \(taskBlockCount) active task blocks (filtered completed tasks)")
        
        // Step 5: Combine and sort
        blocks.append(contentsOf: emptyBlocks)
        timeBlocks = blocks.sorted { $0.startTime < $1.startTime }
        
        print("🟡 generateTimeBlocks: Final time blocks count: \(timeBlocks.count)")
        print("🟡 generateTimeBlocks: Completed")
    }
    
    func calculateFreeTime() {
        // Convert scheduled tasks to temporary commitments for free time calculation
        // This ensures scheduled tasks occupy time and reduce available free time
        let scheduledTaskCommitments = scheduledTasks.compactMap { scheduledTask -> FixedCommitment? in
            // Only include non-completed tasks
            if let task = tasks.first(where: { $0.id == scheduledTask.taskId }), task.isCompleted {
                return nil
            }
            // Create a temporary commitment from the scheduled task
            return FixedCommitment(
                id: UUID().uuidString,  // Temporary ID
                userId: "temp",  // Placeholder userId for calculation purposes
                title: "Scheduled Task",  // Placeholder title
                startTime: scheduledTask.startTime,
                endTime: scheduledTask.endTime
            )
        }
        
        // Combine actual commitments with scheduled task commitments
        let allOccupiedTime = commitments + scheduledTaskCommitments
        
        freeTimeSlots = schedulingEngine.findFreeTimeSlots(
            for: currentDate,
            commitments: allOccupiedTime
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
            
            // Step 1.5: Delete existing scheduled tasks for today FIRST (before calculating free time)
            // This ensures free time calculation doesn't treat old scheduled tasks as commitments
            print("🟣 scheduleAutomaticTasks: Cleaning up existing scheduled tasks...")
            try await repository.deleteAllScheduledTasks(for: currentDate)
            scheduledTasks = [] // Clear local array immediately
            print("🟣 scheduleAutomaticTasks: Cleanup completed")
            
            // Step 2: Recalculate free time based on current commitments (without old scheduled tasks)
            calculateFreeTime()
            print("🟣 scheduleAutomaticTasks: Found \(freeTimeSlots.count) free slots")
            
            // Step 2.5: Adjust free slots to start from current time (for today only)
            let now = Date()
            let calendar = Calendar.current
            let adjustedSlots: [FreeTimeSlot]
            if calendar.isDateInToday(currentDate) {
                adjustedSlots = freeTimeSlots.compactMap { slot in
                    // Skip slots that have already passed
                    guard slot.endTime > now else { return nil }
                    
                    // If slot started in the past, adjust start time to now
                    if slot.startTime < now {
                        return FreeTimeSlot(startTime: now, endTime: slot.endTime)
                    }
                    
                    // Slot is entirely in the future
                    return slot
                }
            } else {
                adjustedSlots = freeTimeSlots
            }
            print("🟣 scheduleAutomaticTasks: Adjusted to \(adjustedSlots.count) future slots")
            
            // Step 3: Call scheduling engine
            let result = schedulingEngine.scheduleMustDoTasks(
                tasks: allTasks,
                freeSlots: adjustedSlots,
                for: currentDate
            )
            
            print("🟣 scheduleAutomaticTasks: Scheduled \(result.scheduled.count), Unscheduled \(result.unscheduled.count)")
            
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
        
        // Check if within workday bounds (using scheduling configuration)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        
        // Get workday start and end times from configuration
        let config = schedulingEngine.configuration
        guard let workDayStartTime = calendar.date(
            bySettingHour: config.workDayStart,
            minute: 0,
            second: 0,
            of: startOfDay
        ) else {
            return false
        }
        
        let workDayEndTime: Date
        if config.workDayEnd == 24 {
            // If workday ends at midnight, use start of next day
            guard let endTime = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return false
            }
            workDayEndTime = endTime
        } else {
            // Otherwise use the specified end hour
            guard let endTime = calendar.date(
                bySettingHour: config.workDayEnd,
                minute: 0,
                second: 0,
                of: startOfDay
            ) else {
                return false
            }
            workDayEndTime = endTime
        }
        
        // Verify the time slot is within the workday bounds
        guard startTime >= workDayStartTime && endTime <= workDayEndTime else {
            // print("❌ [isTimeSlotAvailable] Time slot outside workday bounds")
            return false
        }
        
        // If no overlaps and within workday bounds, the slot is available
        // Note: We don't check freeTimeSlots because they only account for commitments,
        // not scheduled tasks. Manual drag/drop allows placing tasks anywhere that doesn't
        // overlap with commitments or other scheduled tasks.
        return true
    }
    
    private func timeSlotsOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        return start1 < end2 && end1 > start2
    }
    
    // MARK: - Task Completion
    
    func markScheduledTaskComplete(_ taskBlock: TimeBlock) async {
        print("🟢 [markScheduledTaskComplete] Starting completion flow for task: \(taskBlock.title)")
        
        guard let scheduledTaskId = taskBlock.scheduledTaskId else {
            print("❌ [markScheduledTaskComplete] No scheduledTaskId found in block")
            errorMessage = "Unable to complete task. Please try again."
            return
        }
        
        guard let scheduledTask = scheduledTasks.first(where: { $0.id == scheduledTaskId }) else {
            print("❌ [markScheduledTaskComplete] ScheduledTask not found with id: \(scheduledTaskId)")
            errorMessage = "Task not found. Please refresh and try again."
            return
        }
        
        do {
            // Step 1: Fetch the original Task from repository
            let taskId = scheduledTask.taskId
            guard let task = tasks.first(where: { $0.id == taskId }) else {
                print("❌ [markScheduledTaskComplete] Task not found with id: \(taskId)")
                errorMessage = "Task not found. Please refresh and try again."
                return
            }
            
            print("🟢 [markScheduledTaskComplete] Found task: \(task.title)")
            
            // Step 2: Update task's isCompleted property
            var updatedTask = task
            updatedTask.isCompleted = true
            
            // Step 3: Save completion status to Firestore
            try await repository.updateTask(updatedTask)
            print("✅ [markScheduledTaskComplete] Task marked as complete in Firestore")
            
            // Step 4: Delete the ScheduledTask from Firestore
            try await repository.deleteScheduledTask(id: scheduledTaskId)
            print("✅ [markScheduledTaskComplete] ScheduledTask deleted from Firestore")
            
            // Step 5: Update local scheduledTasks array
            scheduledTasks.removeAll { $0.id == scheduledTaskId }
            
            // Step 6: Update local tasks array
            if let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[taskIndex] = updatedTask
            }
            
            // Step 7: Refresh timeline (completed task disappears, free time expands)
            generateTimeBlocks()
            print("✅ [markScheduledTaskComplete] Timeline refreshed")
            
            // Step 8: Show reward message
            successMessage = generateRewardMessage()
            showSuccessMessage = true
            
            // Auto-hide success message after 2 seconds
            _Concurrency.Task {
                try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showSuccessMessage = false
                }
            }
            
            print("🎉 [markScheduledTaskComplete] Task completion flow successful!")
            
            // Haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            print("🔴 [markScheduledTaskComplete] Error: \(error)")
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
            
            // Haptic feedback for error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func generateRewardMessage() -> String {
        let messages = [
            "🎉 Great work! Task complete!",
            "✅ Awesome! Keep it up!",
            "🌟 Fantastic job!",
            "💪 You're on fire!",
            "🚀 Task crushed! Nice!",
            "👏 Well done! Progress made!"
        ]
        
        return messages.randomElement() ?? "✅ Task complete!"
    }
    
    // MARK: - Mood-Based Task Suggestions (for future stories)
    
    func loadCurrentMoodState() async {
        do {
            currentMoodState = try await repository.getCurrentMoodEnergyState()
        } catch {
            print("🔴 ScheduleViewModel: Failed to load current mood state: \(error)")
            currentMoodState = nil
        }
    }
    
    func getCurrentMoodState() async -> MoodEnergyState? {
        do {
            return try await repository.getCurrentMoodEnergyState()
        } catch {
            print("🔴 ScheduleViewModel: Failed to load current mood state: \(error)")
            return nil
        }
    }
    
    // MARK: - Add Suggested Task to Schedule
    
    func addSuggestedTaskToSchedule(_ task: Task, currentMoodEnergy: String) async {
        print("🟢 [addSuggestedTaskToSchedule] Starting for task: \(task.title)")
        
        // Ensure task has a valid ID
        guard let taskId = task.id else {
            print("🔴 [addSuggestedTaskToSchedule] Task has no ID")
            errorMessage = "❌ Invalid task data. Please try again."
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // Check if task is already scheduled today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            errorMessage = "⚠️ Unable to process date. Please try again."
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        let alreadyScheduled = scheduledTasks.contains { scheduledTask in
            scheduledTask.taskId == taskId &&
            scheduledTask.startTime >= startOfDay &&
            scheduledTask.startTime < endOfDay
        }
        
        if alreadyScheduled {
            print("ℹ️ [addSuggestedTaskToSchedule] Task already scheduled today")
            errorMessage = "ℹ️ This task is already on your schedule for today."
            return
        }
        
        // Find best time slot using SchedulingEngine
        guard let timeSlot = schedulingEngine.findBestTimeSlotForTask(
            task: task,
            energyLevel: currentMoodEnergy,
            scheduledTasks: scheduledTasks,
            commitments: commitments,
            date: currentDate
        ) else {
            print("⚠️ [addSuggestedTaskToSchedule] No available time slots")
            errorMessage = "⚠️ No available time slots for this task today. Try removing a task or rescheduling."
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        print("🟢 [addSuggestedTaskToSchedule] Found time slot: \(timeSlot.startTime) - \(timeSlot.endTime)")
        
        // Ensure task has a valid ID
        guard let taskId = task.id else {
            print("🔴 [addSuggestedTaskToSchedule] Task has no ID")
            errorMessage = "❌ Invalid task data. Please try again."
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // Create new ScheduledTask
        let newScheduledTask = ScheduledTask(
            id: UUID().uuidString,
            taskId: taskId,
            date: currentDate,
            startTime: timeSlot.startTime,
            endTime: timeSlot.endTime
        )
        
        do {
            // Save to Firestore
            try await repository.saveScheduledTask(newScheduledTask)
            print("✅ [addSuggestedTaskToSchedule] Saved to Firestore")
            
            // Update local state
            scheduledTasks.append(newScheduledTask)
            
            // Refresh timeline
            generateTimeBlocks()
            
            // Show success message
            successMessage = "✅ Task added to your schedule!"
            showSuccessMessage = true
            
            // Haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Auto-dismiss success message after 2 seconds
            _Concurrency.Task {
                try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showSuccessMessage = false
                }
            }
            
            print("✅ [addSuggestedTaskToSchedule] Complete")
            
        } catch {
            print("🔴 [addSuggestedTaskToSchedule] Error: \(error)")
            errorMessage = "❌ Failed to add task to schedule. Please try again."
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}
