//
//  SchedulingEngineTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import XCTest
@testable import iOS_Productivity_App

final class SchedulingEngineTests: XCTestCase {
    
    var schedulingEngine: SchedulingEngine!
    var calendar: Calendar!
    var testDate: Date!
    
    override func setUp() {
        super.setUp()
        // Use test configuration with 6 AM start (original behavior for tests)
        let testConfig = SchedulingConfiguration(
            minimumGapBetweenEvents: 15 * 60,
            workDayStart: 6,  // 6 AM for tests
            workDayEnd: 24,
            minimumTaskDuration: 15 * 60,
            defaultTaskDuration: 30 * 60
        )
        schedulingEngine = SchedulingEngine(configuration: testConfig)
        calendar = Calendar.current
        // Use October 6, 2025 as test date
        testDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 6))!
    }
    
    override func tearDown() {
        schedulingEngine = nil
        calendar = nil
        testDate = nil
        super.tearDown()
    }
    
    // Helper method to create date with specific hour and minute
    func createDate(hour: Int, minute: Int = 0) -> Date {
        // Handle hours >= 24 by adding days
        if hour >= 24 {
            let daysToAdd = hour / 24
            let adjustedHour = hour % 24
            let baseDate = calendar.date(bySettingHour: adjustedHour, minute: minute, second: 0, of: testDate)!
            return calendar.date(byAdding: .day, value: daysToAdd, to: baseDate)!
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: testDate)!
    }
    
    // Helper method to create commitment
    func createCommitment(title: String, startHour: Int, startMinute: Int = 0, endHour: Int, endMinute: Int = 0) -> FixedCommitment {
        return FixedCommitment(
            id: UUID().uuidString,
            userId: "testUser",
            title: title,
            startTime: createDate(hour: startHour, minute: startMinute),
            endTime: createDate(hour: endHour, minute: endMinute)
        )
    }
    
    // MARK: - Test Cases
    
    func testFindFreeTimeSlots_NoCommitments() {
        // Given: No commitments
        let commitments: [FixedCommitment] = []
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should return single full-day slot (6 AM - 12 AM)
        XCTAssertEqual(freeSlots.count, 1)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 6)
        // Midnight is hour 0 of the next day
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 0)
        XCTAssertEqual(freeSlots[0].durationInMinutes, 18 * 60) // 18 hours
    }
    
    func testFindFreeTimeSlots_OneCommitment() {
        // Given: One commitment from 10 AM - 11 AM
        let commitments = [
            createCommitment(title: "Meeting", startHour: 10, endHour: 11)
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should return 2 slots (before and after, with 15-min gap)
        XCTAssertEqual(freeSlots.count, 2)
        
        // Slot 1: 6 AM - 10 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 6)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 10)
        
        // Slot 2: 11:15 AM - 12 AM (15-minute gap after commitment)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].startTime), 11)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[1].startTime), 15)
        // Midnight is hour 0 of the next day
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].endTime), 0)
    }
    
    func testFindFreeTimeSlots_MultipleCommitments() {
        // Given: Multiple commitments with gaps
        let commitments = [
            createCommitment(title: "Morning Meeting", startHour: 9, endHour: 10),
            createCommitment(title: "Lunch", startHour: 12, endHour: 13),
            createCommitment(title: "Afternoon Meeting", startHour: 15, endHour: 16)
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should return 4 slots (before first, between gaps, after last)
        XCTAssertEqual(freeSlots.count, 4)
        
        // Slot 1: 6 AM - 9 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 6)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 9)
        
        // Slot 2: 10:15 AM - 12 PM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].startTime), 10)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[1].startTime), 15)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].endTime), 12)
        
        // Slot 3: 1:15 PM - 3 PM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[2].startTime), 13)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[2].startTime), 15)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[2].endTime), 15)
        
        // Slot 4: 4:15 PM - 12 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[3].startTime), 16)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[3].startTime), 15)
        // Midnight is hour 0 of the next day
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[3].endTime), 0)
    }
    
    func testFindFreeTimeSlots_NoFreeTime() {
        // Given: Commitment filling entire work day (6 AM - 12 AM)
        let commitments = [
            createCommitment(title: "All Day Event", startHour: 6, endHour: 24)
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should return empty array
        XCTAssertEqual(freeSlots.count, 0)
    }
    
    func testFindFreeTimeSlots_WithMinimumGap() {
        // Given: Custom configuration with 30-minute gap
        let config = SchedulingConfiguration(
            minimumGapBetweenEvents: 30 * 60,
            minimumTaskDuration: 30 * 60
        )
        let engine = SchedulingEngine(configuration: config)
        
        let commitments = [
            createCommitment(title: "Meeting A", startHour: 10, endHour: 11),
            createCommitment(title: "Meeting B", startHour: 11, startMinute: 40, endHour: 12, endMinute: 40)
        ]
        
        // When: Find free time slots
        let freeSlots = engine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Gap between meetings is only 40 minutes, but after 30-min gap, only 10 minutes remain
        // This is less than minimumTaskDuration (30 min), so no slot should be created between them
        XCTAssertEqual(freeSlots.count, 2) // Only before first and after last
    }
    
    func testFindFreeTimeSlots_FilterShortSlots() {
        // Given: Commitments with very short gaps (less than 15 minutes)
        let commitments = [
            createCommitment(title: "Meeting A", startHour: 10, endHour: 11),
            createCommitment(title: "Meeting B", startHour: 11, startMinute: 20, endHour: 12) // Only 20-min gap, but 15-min buffer = 5-min slot
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Gap between meetings is 20 minutes, but after 15-min gap, only 5 minutes remain
        // This is less than minimumTaskDuration (15 min), so no slot between them
        XCTAssertEqual(freeSlots.count, 2) // Only before first and after last
    }
    
    func testFindFreeTimeSlots_OverlappingCommitments() {
        // Given: Overlapping commitments (9-11 AM and 10 AM-12 PM)
        let commitments = [
            createCommitment(title: "Meeting A", startHour: 9, endHour: 11),
            createCommitment(title: "Meeting B", startHour: 10, endHour: 12)
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should merge overlaps into single 9 AM - 12 PM block, return 2 slots
        XCTAssertEqual(freeSlots.count, 2)
        
        // Slot 1: 6 AM - 9 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 9)
        
        // Slot 2: 12:15 PM - 12 AM (15-minute gap after merged commitment)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].startTime), 12)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[1].startTime), 15)
    }
    
    func testFindFreeTimeSlots_CommitmentsOutsideWorkHours() {
        // Given: Commitments outside work hours (5-7 AM and 11 PM-1 AM)
        let commitments = [
            createCommitment(title: "Early Morning", startHour: 5, endHour: 7),
            createCommitment(title: "Late Night", startHour: 23, endHour: 25) // 25 = 1 AM next day
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Early commitment should be adjusted to 6-7 AM, late commitment to 11 PM-12 AM
        // Since late commitment extends past midnight, it consumes the end of the day
        // So we get one free slot: 7:15 AM - 11 PM
        XCTAssertEqual(freeSlots.count, 1)
        
        // Slot 1: 7:15 AM - 11 PM (adjusted from early commitment end)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 7)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[0].startTime), 15)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 23)
    }
    
    func testFindFreeTimeSlots_EdgeOfWorkHours() {
        // Given: Commitments at exact work hour boundaries
        let commitments = [
            createCommitment(title: "Morning", startHour: 6, endHour: 7),
            createCommitment(title: "Evening", startHour: 23, endHour: 24)
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should return 1 slot between them (7:15 AM - 11 PM)
        XCTAssertEqual(freeSlots.count, 1)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 7)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[0].startTime), 15)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 23)
    }
    
    func testMergeOverlappingCommitments() {
        // Given: Multiple overlapping and non-overlapping commitments
        let commitments = [
            createCommitment(title: "Meeting A", startHour: 9, endHour: 11),
            createCommitment(title: "Meeting B", startHour: 10, endHour: 12), // Overlaps with A
            createCommitment(title: "Meeting C", startHour: 14, endHour: 15), // Separate
            createCommitment(title: "Meeting D", startHour: 14, startMinute: 30, endHour: 16) // Overlaps with C
        ]
        
        // When: Find free time slots (which internally merges)
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should have 3 free slots (before first merged, between merged blocks, after last merged)
        XCTAssertEqual(freeSlots.count, 3)
        
        // Verify the gaps indicate proper merging occurred
        // Gap 1: 6 AM - 9 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 6)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 9)
        
        // Gap 2: 12:15 PM - 2 PM (proves A and B were merged to end at 12 PM)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].startTime), 12)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[1].startTime), 15)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].endTime), 14)
        
        // Gap 3: 4:15 PM - 12 AM (proves C and D were merged to end at 4 PM)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[2].startTime), 16)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[2].startTime), 15)
    }
    
    func testFindFreeTimeSlots_BackToBackCommitments() {
        // Given: Adjacent commitments with no gap
        let commitments = [
            createCommitment(title: "Meeting A", startHour: 9, endHour: 10),
            createCommitment(title: "Meeting B", startHour: 10, endHour: 11)
        ]
        
        // When: Find free time slots
        let freeSlots = schedulingEngine.findFreeTimeSlots(for: testDate, commitments: commitments)
        
        // Then: Should return 2 slots (before and after), no slot between back-to-back meetings
        XCTAssertEqual(freeSlots.count, 2)
        
        // Slot 1: 6 AM - 9 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].startTime), 6)
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[0].endTime), 9)
        
        // Slot 2: 11:15 AM - 12 AM
        XCTAssertEqual(calendar.component(.hour, from: freeSlots[1].startTime), 11)
        XCTAssertEqual(calendar.component(.minute, from: freeSlots[1].startTime), 15)
    }
    
    // MARK: - Task Scheduling Tests (Story 2.3)
    
    // Helper method to create task
    func createTask(title: String, priority: String, isCompleted: Bool = false, createdAt: Date? = nil) -> Task {
        return Task(
            id: UUID().uuidString,
            userId: "testUser",
            title: title,
            priority: priority,
            energyLevel: "any",
            isCompleted: isCompleted,
            createdAt: createdAt ?? Date()
        )
    }
    
    // Helper method to create free time slot
    func createFreeSlot(startHour: Int, startMinute: Int = 0, endHour: Int, endMinute: Int = 0) -> FreeTimeSlot {
        return FreeTimeSlot(
            startTime: createDate(hour: startHour, minute: startMinute),
            endTime: createDate(hour: endHour, minute: endMinute)
        )
    }
    
    func testScheduleMustDoTasks_EmptySlots() {
        // Given: Must-do tasks but no free slots
        let tasks = [
            createTask(title: "Task 1", priority: "must-do"),
            createTask(title: "Task 2", priority: "must-do")
        ]
        let freeSlots: [FreeTimeSlot] = []
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: All tasks should be unscheduled
        XCTAssertEqual(result.scheduled.count, 0)
        XCTAssertEqual(result.unscheduled.count, 2)
    }
    
    func testScheduleMustDoTasks_OneFreeSlot() {
        // Given: 3 tasks and one 30-minute slot (fits only one task)
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8)),
            createTask(title: "Task 2", priority: "must-do", createdAt: createDate(hour: 9)),
            createTask(title: "Task 3", priority: "must-do", createdAt: createDate(hour: 10))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 14, endHour: 14, endMinute: 30)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: One task scheduled, two unscheduled
        XCTAssertEqual(result.scheduled.count, 1)
        XCTAssertEqual(result.unscheduled.count, 2)
        XCTAssertEqual(result.scheduled[0].taskId, tasks[0].id) // Oldest task scheduled first
    }
    
    func testScheduleMustDoTasks_MultipleFreeSlots() {
        // Given: 3 tasks and multiple free slots
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8)),
            createTask(title: "Task 2", priority: "must-do", createdAt: createDate(hour: 9)),
            createTask(title: "Task 3", priority: "must-do", createdAt: createDate(hour: 10))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 9, endHour: 10),
            createFreeSlot(startHour: 14, endHour: 15, endMinute: 30),
            createFreeSlot(startHour: 17, endHour: 18)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: All tasks should be scheduled
        XCTAssertEqual(result.scheduled.count, 3)
        XCTAssertEqual(result.unscheduled.count, 0)
    }
    
    func testScheduleMustDoTasks_OnlyMustDoTasks() {
        // Given: Mix of must-do and flexible tasks
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8)),
            createTask(title: "Task 2", priority: "flexible", createdAt: createDate(hour: 9)),
            createTask(title: "Task 3", priority: "must-do", createdAt: createDate(hour: 10))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 9, endHour: 11)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: Only must-do tasks scheduled
        XCTAssertEqual(result.scheduled.count, 2)
        XCTAssertEqual(result.unscheduled.count, 0)
        XCTAssertEqual(result.scheduled[0].taskId, tasks[0].id)
        XCTAssertEqual(result.scheduled[1].taskId, tasks[2].id)
    }
    
    func testScheduleMustDoTasks_CompletedTasksIgnored() {
        // Given: Must-do tasks, some completed
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", isCompleted: true, createdAt: createDate(hour: 8)),
            createTask(title: "Task 2", priority: "must-do", isCompleted: false, createdAt: createDate(hour: 9))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 9, endHour: 11)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: Only incomplete task scheduled
        XCTAssertEqual(result.scheduled.count, 1)
        XCTAssertEqual(result.scheduled[0].taskId, tasks[1].id)
    }
    
    func testScheduleMustDoTasks_DefaultDuration() {
        // Given: Task and free slot
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 9, endHour: 11)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: Task assigned 30-minute default duration
        XCTAssertEqual(result.scheduled.count, 1)
        XCTAssertEqual(result.scheduled[0].duration, 30 * 60) // 30 minutes
        XCTAssertEqual(calendar.component(.hour, from: result.scheduled[0].startTime), 9)
        XCTAssertEqual(calendar.component(.minute, from: result.scheduled[0].startTime), 0)
        XCTAssertEqual(calendar.component(.hour, from: result.scheduled[0].endTime), 9)
        XCTAssertEqual(calendar.component(.minute, from: result.scheduled[0].endTime), 30)
    }
    
    func testScheduleMustDoTasks_SlotSmallerThanDefault() {
        // Given: Task (30-min default) and 35-minute slot
        // The 35-min slot can fit the 30-min task (slot >= task duration)
        // The 15-min gap is added AFTER the task, reducing space for subsequent tasks
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 9, endHour: 9, endMinute: 35)  // 35 minutes total
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: Task scheduled with full duration (30 minutes) since slot is large enough
        XCTAssertEqual(result.scheduled.count, 1)
        XCTAssertEqual(result.scheduled[0].duration, 30 * 60) // 30 minutes (full task duration)
    }
    
    func testScheduleMustDoTasks_SlotTooSmall() {
        // Given: Task and 10-minute slot (smaller than 15-min minimum)
        let tasks = [
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 9, endHour: 9, endMinute: 10)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: Task not scheduled
        XCTAssertEqual(result.scheduled.count, 0)
        XCTAssertEqual(result.unscheduled.count, 1)
    }
    
    func testScheduleMustDoTasks_FIFOOrder() {
        // Given: 3 tasks with different creation times
        let tasks = [
            createTask(title: "Task 3", priority: "must-do", createdAt: createDate(hour: 10)),
            createTask(title: "Task 1", priority: "must-do", createdAt: createDate(hour: 8)),
            createTask(title: "Task 2", priority: "must-do", createdAt: createDate(hour: 9))
        ]
        let freeSlots = [
            createFreeSlot(startHour: 14, endHour: 16)
        ]
        
        // When: Schedule tasks
        let result = schedulingEngine.scheduleMustDoTasks(tasks: tasks, freeSlots: freeSlots, for: testDate)
        
        // Then: Tasks scheduled in order of creation (oldest first)
        XCTAssertEqual(result.scheduled.count, 3)
        XCTAssertEqual(result.scheduled[0].taskId, tasks[1].id) // Task 1 (created at 8)
        XCTAssertEqual(result.scheduled[1].taskId, tasks[2].id) // Task 2 (created at 9)
        XCTAssertEqual(result.scheduled[2].taskId, tasks[0].id) // Task 3 (created at 10)
    }
}
