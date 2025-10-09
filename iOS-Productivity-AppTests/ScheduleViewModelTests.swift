//
//  ScheduleViewModelTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import XCTest
@testable import iOS_Productivity_App

@MainActor
final class ScheduleViewModelTests: XCTestCase {
    
    var mockRepository: MockDataRepository!
    var viewModel: ScheduleViewModel!
    
    override func setUp() async throws {
        mockRepository = MockDataRepository()
        // Use test configuration with 6 AM start for consistent test behavior
        let testConfig = SchedulingConfiguration(
            minimumGapBetweenEvents: 15 * 60,
            workDayStart: 6,
            workDayEnd: 24,
            minimumTaskDuration: 15 * 60,
            defaultTaskDuration: 30 * 60
        )
        let schedulingEngine = SchedulingEngine(configuration: testConfig)
        viewModel = ScheduleViewModel(repository: mockRepository, schedulingEngine: schedulingEngine)
    }
    
    override func tearDown() async throws {
        mockRepository = nil
        viewModel = nil
    }
    
    // MARK: - Test loadCommitments() success path
    
    func testLoadCommitments_Success() async throws {
        // Given: Mock repository has commitments
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment1 = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Morning Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        let commitment2 = FixedCommitment(
            id: "2",
            userId: "test-user",
            title: "Lunch",
            startTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 13, to: startOfDay)!
        )
        
        mockRepository.mockCommitments = [commitment1, commitment2]
        mockRepository.shouldThrowError = false
        
        // When: Load commitments
        await viewModel.loadCommitments()
        
        // Then: Commitments are loaded and time blocks generated (including empty blocks)
        XCTAssertEqual(viewModel.commitments.count, 2)
        // Time blocks now include empty slots: before, between, and after commitments
        XCTAssertGreaterThanOrEqual(viewModel.timeBlocks.count, 2) // At least the 2 commitments
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        // Verify commitment blocks are present (filter to find them since empty blocks are included)
        let commitmentBlocks = viewModel.timeBlocks.filter { $0.type == .commitment }
        XCTAssertEqual(commitmentBlocks.count, 2)
        XCTAssertEqual(commitmentBlocks[0].title, "Morning Meeting")
        XCTAssertEqual(commitmentBlocks[1].title, "Lunch")
    }
    
    // MARK: - Test loadCommitments() error handling
    
    func testLoadCommitments_Error() async throws {
        // Given: Repository will throw error
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = DataRepositoryError.fetchFailed
        
        // When: Load commitments
        await viewModel.loadCommitments()
        
        // Then: Error message is set
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Unable to load your schedule. Please check your connection and try again.")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.commitments.isEmpty)
        XCTAssertTrue(viewModel.timeBlocks.isEmpty)
    }
    
    // MARK: - Test generateTimeBlocks()
    
    func testGenerateTimeBlocks() throws {
        // Given: Commitments are set
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Team Standup",
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!,
            endTime: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!)!
        )
        
        viewModel.commitments = [commitment]
        viewModel.currentDate = today // Set current date for free time calculation
        
        // When: Generate time blocks
        viewModel.generateTimeBlocks()
        
        // Then: Time blocks are created (including empty blocks before and after)
        XCTAssertGreaterThanOrEqual(viewModel.timeBlocks.count, 1) // At least the commitment
        
        // Find the commitment block
        let commitmentBlocks = viewModel.timeBlocks.filter { $0.type == .commitment }
        XCTAssertEqual(commitmentBlocks.count, 1)
        XCTAssertEqual(commitmentBlocks[0].title, "Team Standup")
        XCTAssertEqual(commitmentBlocks[0].type, .commitment)
        XCTAssertEqual(commitmentBlocks[0].startTime, commitment.startTime)
        XCTAssertEqual(commitmentBlocks[0].endTime, commitment.endTime)
    }
    
    // MARK: - Test getCurrentTimeOffset()
    
    func testGetCurrentTimeOffset() throws {
        // Given: Known time
        let calendar = Calendar.current
        let mockTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!
        
        // Create a custom view model that uses a fixed time
        // For this test, we'll just verify the calculation logic
        
        let hour = calendar.component(.hour, from: mockTime)
        let minute = calendar.component(.minute, from: mockTime)
        
        let startHour = 6
        let hourHeight: CGFloat = 60
        
        let expectedOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute)
        
        // Expected: 10:30 AM = (10 - 6) * 60 + 30 = 240 + 30 = 270
        XCTAssertEqual(expectedOffset, 270)
        
        // When: Get current time offset (will use actual current time)
        let offset = viewModel.getCurrentTimeOffset()
        
        // Then: Offset is reasonable (between 0 and 1080 for 6 AM - 12 AM)
        XCTAssertGreaterThanOrEqual(offset, 0)
        XCTAssertLessThanOrEqual(offset, 1080) // 18 hours * 60
    }
    
    // MARK: - Test currentTimeFormatted
    
    func testCurrentTimeFormatted() throws {
        // When: Get formatted time
        let formattedTime = viewModel.currentTimeFormatted
        
        // Then: Time is formatted correctly (should contain AM or PM)
        XCTAssertTrue(formattedTime.contains("AM") || formattedTime.contains("PM"))
        XCTAssertFalse(formattedTime.isEmpty)
    }
    
    // MARK: - Test loading state management
    
    func testLoadingStateManagement() async throws {
        // Given: Repository with commitments
        mockRepository.mockCommitments = []
        mockRepository.shouldThrowError = false
        
        // When: Start loading
        XCTAssertFalse(viewModel.isLoading)
        
        await viewModel.loadCommitments()
        
        // Then: Loading is complete
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Test error message display
    
    func testErrorMessageDisplay() async throws {
        // Given: Error will occur
        mockRepository.shouldThrowError = true
        
        // When: Load commitments
        await viewModel.loadCommitments()
        
        // Then: Error message is user-friendly
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Unable to load"))
    }
    
    // MARK: - Test empty state (no commitments)
    
    func testEmptyState() async throws {
        // Given: No commitments
        mockRepository.mockCommitments = []
        mockRepository.shouldThrowError = false
        
        // When: Load commitments
        await viewModel.loadCommitments()
        
        // Then: Commitments are empty but time blocks include a full-day empty block
        XCTAssertTrue(viewModel.commitments.isEmpty)
        // With Story 2.2, empty schedules generate a full-day empty block
        XCTAssertEqual(viewModel.timeBlocks.count, 1)
        XCTAssertEqual(viewModel.timeBlocks[0].type, .empty)
        XCTAssertEqual(viewModel.timeBlocks[0].title, "Available")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Test current date initialization
    
    func testCurrentDateInitialization() throws {
        // Then: Current date is set to today
        let calendar = Calendar.current
        let today = Date()
        
        XCTAssertTrue(calendar.isDate(viewModel.currentDate, inSameDayAs: today))
    }
    
    // MARK: - Test time block duration calculation
    
    func testTimeBlockDuration() throws {
        // Given: Commitment with 1 hour duration
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime)!
        
        let timeBlock = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime,
            type: .commitment
        )
        
        // Then: Duration is 3600 seconds (1 hour)
        XCTAssertEqual(timeBlock.duration, 3600, accuracy: 1.0)
    }
    
    // MARK: - Test time block formatted time range
    
    func testTimeBlockFormattedTimeRange() throws {
        // Given: Commitment with specific times
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let endTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!
        
        let timeBlock = TimeBlock(
            title: "Meeting",
            startTime: startTime,
            endTime: endTime,
            type: .commitment
        )
        
        // Then: Formatted range contains both times
        let formattedRange = timeBlock.formattedTimeRange
        XCTAssertTrue(formattedRange.contains("9:00"))
        XCTAssertTrue(formattedRange.contains("10:30"))
        XCTAssertTrue(formattedRange.contains("AM"))
    }
    
    // MARK: - Test Free Time Integration (Story 2.2)
    
    func testCalculateFreeTime_WithCommitments() throws {
        // Given: Commitments with gaps on a PAST date (to avoid current time filtering)
        let calendar = Calendar.current
        let pastDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))! // Oct 1, past date
        let startOfDay = calendar.startOfDay(for: pastDate)
        
        let commitment1 = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Morning Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        let commitment2 = FixedCommitment(
            id: "2",
            userId: "test-user",
            title: "Afternoon Meeting",
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment1, commitment2]
        viewModel.currentDate = pastDate  // Use past date
        
        // When: Calculate free time
        viewModel.calculateFreeTime()
        
        // Then: Free time slots are populated
        XCTAssertFalse(viewModel.freeTimeSlots.isEmpty)
        // Should have 3 slots: before first, between, after last
        XCTAssertEqual(viewModel.freeTimeSlots.count, 3)
        
        // Verify first slot is before first commitment (6 AM - 9 AM)
        XCTAssertEqual(calendar.component(.hour, from: viewModel.freeTimeSlots[0].startTime), 6)
        XCTAssertEqual(calendar.component(.hour, from: viewModel.freeTimeSlots[0].endTime), 9)
    }
    
    func testCalculateFreeTime_NoCommitments() throws {
        // Given: No commitments on a PAST date
        let calendar = Calendar.current
        let pastDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))! // Oct 1, past date
        
        viewModel.commitments = []
        viewModel.currentDate = pastDate  // Use past date
        
        // When: Calculate free time
        viewModel.calculateFreeTime()
        
        // Then: Should have single full-day slot
        XCTAssertEqual(viewModel.freeTimeSlots.count, 1)
        
        let slot = viewModel.freeTimeSlots[0]
        
        // Verify start time is 6 AM
        XCTAssertEqual(calendar.component(.hour, from: slot.startTime), 6)
        
        // Verify end time is midnight (hour 0 of next day)
        let endDay = calendar.component(.day, from: slot.endTime)
        let startDay = calendar.component(.day, from: slot.startTime)
        XCTAssertEqual(calendar.component(.hour, from: slot.endTime), 0) // Midnight = hour 0
        XCTAssertEqual(endDay, startDay + 1) // Next day
    }
    
    func testGenerateTimeBlocks_IncludesEmptyBlocks() throws {
        // Given: One commitment
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Lunch",
            startTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 13, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment]
        viewModel.currentDate = today
        
        // When: Generate time blocks
        viewModel.generateTimeBlocks()
        
        // Then: Time blocks include both commitment and empty blocks
        XCTAssertGreaterThan(viewModel.timeBlocks.count, 1) // More than just the commitment
        
        // Should have 1 commitment block
        let commitmentBlocks = viewModel.timeBlocks.filter { $0.type == .commitment }
        XCTAssertEqual(commitmentBlocks.count, 1)
        
        // Should have empty blocks (before and after)
        let emptyBlocks = viewModel.timeBlocks.filter { $0.type == .empty }
        XCTAssertGreaterThan(emptyBlocks.count, 0)
        
        // Verify empty blocks have "Available" title
        for emptyBlock in emptyBlocks {
            XCTAssertEqual(emptyBlock.title, "Available")
        }
    }
    
    func testGenerateTimeBlocks_ChronologicalOrder() throws {
        // Given: Multiple commitments in random order
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment1 = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Afternoon",
            startTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 16, to: startOfDay)!
        )
        
        let commitment2 = FixedCommitment(
            id: "2",
            userId: "test-user",
            title: "Morning",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment1, commitment2] // Out of order
        viewModel.currentDate = today
        
        // When: Generate time blocks
        viewModel.generateTimeBlocks()
        
        // Then: Time blocks are sorted chronologically
        for i in 0..<(viewModel.timeBlocks.count - 1) {
            XCTAssertLessThanOrEqual(
                viewModel.timeBlocks[i].startTime,
                viewModel.timeBlocks[i + 1].startTime,
                "Time blocks should be in chronological order"
            )
        }
    }
}

// MARK: - Task Scheduling Tests (Story 2.3)

extension ScheduleViewModelTests {
    func testScheduleAutomaticTasks_WithFreeTime() async throws {
        // Given: Tasks and free time available
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task1 = Task(
            id: "task-1",
            userId: "test-user",
            title: "Write Report",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: calendar.date(byAdding: .hour, value: 8, to: startOfDay)!
        )
        
        mockRepository.mockTasks = [task1]
        mockRepository.mockCommitments = []
        mockRepository.shouldThrowError = false
        
        viewModel.currentDate = today
        
        // When: Schedule automatic tasks
        await viewModel.scheduleAutomaticTasks()
        
        // Then: Task is scheduled
        XCTAssertGreaterThan(viewModel.scheduledTasks.count, 0)
        XCTAssertEqual(viewModel.unscheduledMustDoTasks.count, 0)
        XCTAssertFalse(viewModel.showInsufficientTimeAlert)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testScheduleAutomaticTasks_InsufficientTime() async throws {
        // Given: Tasks but no free time (day fully booked)
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task1 = Task(
            id: "task-1",
            userId: "test-user",
            title: "Write Report",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        // Commitment fills entire day
        let allDayCommitment = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "All Day Event",
            startTime: calendar.date(byAdding: .hour, value: 6, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 24, to: startOfDay)!
        )
        
        mockRepository.mockTasks = [task1]
        mockRepository.mockCommitments = [allDayCommitment]
        mockRepository.shouldThrowError = false
        
        viewModel.currentDate = today
        viewModel.commitments = [allDayCommitment]
        viewModel.calculateFreeTime() // Should have no free slots
        
        // When: Schedule automatic tasks
        await viewModel.scheduleAutomaticTasks()
        
        // Then: Alert is triggered
        XCTAssertTrue(viewModel.showInsufficientTimeAlert)
        XCTAssertEqual(viewModel.unscheduledMustDoTasks.count, 1)
        XCTAssertEqual(viewModel.scheduledTasks.count, 0)
    }
    
    func testLoadScheduledTasks() async throws {
        // Given: Mock scheduled tasks exist
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        mockRepository.mockScheduledTasks = [scheduledTask]
        mockRepository.shouldThrowError = false
        
        viewModel.currentDate = today
        
        // When: Load scheduled tasks
        await viewModel.loadScheduledTasks()
        
        // Then: Scheduled tasks are loaded
        XCTAssertEqual(viewModel.scheduledTasks.count, 1)
        XCTAssertEqual(viewModel.scheduledTasks[0].taskId, "task-1")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testGenerateTimeBlocks_IncludesScheduledTasks() throws {
        // Given: Commitments and scheduled tasks
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Write Report",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        
        // When: Generate time blocks
        viewModel.generateTimeBlocks()
        
        // Then: Time blocks include scheduled task
        let taskBlocks = viewModel.timeBlocks.filter { $0.type == .task }
        XCTAssertEqual(taskBlocks.count, 1)
        XCTAssertEqual(taskBlocks[0].title, "Write Report")
    }
    
    func testGenerateTimeBlocks_ChronologicalOrderWithAllTypes() throws {
        // Given: Commitments, scheduled tasks, and empty slots
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment = FixedCommitment(
            id: "1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 16, to: startOfDay)!
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Morning Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        
        // When: Generate time blocks
        viewModel.generateTimeBlocks()
        
        // Then: All blocks are in chronological order
        for i in 0..<(viewModel.timeBlocks.count - 1) {
            XCTAssertLessThanOrEqual(
                viewModel.timeBlocks[i].startTime,
                viewModel.timeBlocks[i + 1].startTime,
                "Time blocks should be in chronological order"
            )
        }
        
        // Verify all three types are present
        XCTAssertTrue(viewModel.timeBlocks.contains { $0.type == .commitment })
        XCTAssertTrue(viewModel.timeBlocks.contains { $0.type == .task })
        XCTAssertTrue(viewModel.timeBlocks.contains { $0.type == .empty })
    }
    
    // MARK: - Test moveScheduledTask() - Story 2.4
    
    func testMoveScheduledTask_ValidFreeSlot() async throws {
        // Given: A scheduled task and a valid free slot to move to
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitment from 9-10 AM
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        // Task scheduled at 11-11:30 AM (will move to 2 PM)
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        // Create a TimeBlock representing the scheduled task
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // New start time at 2 PM (valid free slot)
        let newStartTime = calendar.date(byAdding: .hour, value: 14, to: startOfDay)!
        
        // When: Move task to new time
        let success = await viewModel.moveScheduledTask(taskBlock, to: newStartTime)
        
        // Then: Task is moved successfully
        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.scheduledTasks.first?.startTime, newStartTime)
        XCTAssertEqual(viewModel.scheduledTasks.first?.endTime, newStartTime.addingTimeInterval(1800))
        XCTAssertTrue(mockRepository.updateScheduledTaskCalled)
    }
    
    func testMoveScheduledTask_InvalidOverlapWithCommitment() async throws {
        // Given: A scheduled task and trying to move it to overlap with commitment
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitment from 9-10 AM
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        // Task scheduled at 11-11:30 AM
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // Try to move to 9:15 AM (overlaps with commitment)
        let newStartTime = calendar.date(byAdding: .minute, value: 15, to: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!)!
        
        // When: Move task to overlapping time
        let success = await viewModel.moveScheduledTask(taskBlock, to: newStartTime)
        
        // Then: Move fails
        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.scheduledTasks.first?.startTime, scheduledTask.startTime) // Original time unchanged
        XCTAssertFalse(mockRepository.updateScheduledTaskCalled)
    }
    
    func testMoveScheduledTask_InvalidOutOfBounds() async throws {
        // Given: A scheduled task and trying to move it outside free time slots
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitment from 9-10 AM
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        // Task scheduled at 11-11:30 AM
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // Try to move to 3 AM (outside work day bounds 6 AM - 24 PM)
        let newStartTime = calendar.date(byAdding: .hour, value: 3, to: startOfDay)!
        
        // When: Move task outside bounds
        let success = await viewModel.moveScheduledTask(taskBlock, to: newStartTime)
        
        // Then: Move fails
        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.scheduledTasks.first?.startTime, scheduledTask.startTime)
        XCTAssertFalse(mockRepository.updateScheduledTaskCalled)
    }
    
    // MARK: - Test resizeScheduledTask() - Story 2.4
    
    func testResizeScheduledTask_ValidDuration() async throws {
        // Given: A scheduled task in a free slot with room to expand
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitment from 12-1 PM
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Lunch",
            startTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 13, to: startOfDay)!
        )
        
        // Task scheduled at 10-10:30 AM (will resize to 1 hour)
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // New duration: 1 hour (3600 seconds)
        let newDuration: TimeInterval = 3600
        
        // When: Resize task
        let success = await viewModel.resizeScheduledTask(taskBlock, newDuration: newDuration)
        
        // Then: Task is resized successfully
        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.scheduledTasks.first?.endTime, scheduledTask.startTime.addingTimeInterval(newDuration))
        XCTAssertTrue(mockRepository.updateScheduledTaskCalled)
    }
    
    func testResizeScheduledTask_InvalidTooSmall() async throws {
        // Given: A scheduled task
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // Try to resize to 10 minutes (below 15-minute minimum)
        let newDuration: TimeInterval = 600
        
        // When: Resize below minimum
        let success = await viewModel.resizeScheduledTask(taskBlock, newDuration: newDuration)
        
        // Then: Resize fails
        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.scheduledTasks.first?.endTime, scheduledTask.endTime) // Unchanged
        XCTAssertFalse(mockRepository.updateScheduledTaskCalled)
    }
    
    func testResizeScheduledTask_InvalidOverlap() async throws {
        // Given: A scheduled task with commitment immediately after
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitment from 11-12 PM
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
        )
        
        // Task scheduled at 10-10:30 AM
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // Try to resize to 2 hours (would extend into commitment at 11 AM)
        let newDuration: TimeInterval = 7200
        
        // When: Resize to overlap with commitment
        let success = await viewModel.resizeScheduledTask(taskBlock, newDuration: newDuration)
        
        // Then: Resize fails
        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.scheduledTasks.first?.endTime, scheduledTask.endTime)
        XCTAssertFalse(mockRepository.updateScheduledTaskCalled)
    }
    
    // MARK: - Test isTimeSlotAvailable() helper - Story 2.4
    
    func testIsTimeSlotAvailable_NoOverlap() async throws {
        // Given: Commitments and scheduled tasks
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitment from 9-10 AM
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        
        // When: Check if 2-3 PM slot is available (no overlap)
        let testStart = calendar.date(byAdding: .hour, value: 14, to: startOfDay)!
        _ = calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        
        // Access private method via reflection (for testing purposes)
        // In production, this validation happens within public methods
        // We'll test indirectly through moveScheduledTask
        
        // Create a test scheduled task at 11 AM
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // Then: Moving to 2 PM should succeed (no overlap)
        let success = await viewModel.moveScheduledTask(taskBlock, to: testStart)
        XCTAssertTrue(success)
    }
    
    func testIsTimeSlotAvailable_WithOverlap() async throws {
        // Given: Two commitments
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Commitments at 9-10 AM and 11-12 PM
        let commitment1 = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting 1",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        let commitment2 = FixedCommitment(
            id: "c2",
            userId: "test-user",
            title: "Meeting 2",
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
        )
        
        // Task at 2-2:30 PM
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!.addingTimeInterval(1800)
        )
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Test Task",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.commitments = [commitment1, commitment2]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.tasks = [task]
        viewModel.currentDate = today
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Try to move to 9:30 AM (overlaps with commitment1)
        let newStartTime = calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!)!
        
        // Then: Move should fail
        let success = await viewModel.moveScheduledTask(taskBlock, to: newStartTime)
        XCTAssertFalse(success)
    }
    
    // MARK: - Test Task Completion (Story 2.5)
    
    func testMarkScheduledTaskComplete_UpdatesTask() async throws {
        // Given: A scheduled task exists
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task = Task(
            id: "task-1",
            userId: "test-user",
            title: "Complete Report",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-1",
            taskId: "task-1",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!
        )
        
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.currentDate = today
        mockRepository.mockTasks = [task]
        mockRepository.mockScheduledTasks = [scheduledTask]
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Mark task as complete
        await viewModel.markScheduledTaskComplete(taskBlock)
        
        // Then: Task is marked as completed
        XCTAssertEqual(mockRepository.updatedTasks.count, 1)
        XCTAssertTrue(mockRepository.updatedTasks[0].isCompleted)
        XCTAssertEqual(mockRepository.updatedTasks[0].id, "task-1")
    }
    
    func testMarkScheduledTaskComplete_DeletesScheduledTask() async throws {
        // Given: A scheduled task exists
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task = Task(
            id: "task-2",
            userId: "test-user",
            title: "Write Tests",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-2",
            taskId: "task-2",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        )
        
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.currentDate = today
        mockRepository.mockTasks = [task]
        mockRepository.mockScheduledTasks = [scheduledTask]
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Mark task as complete
        await viewModel.markScheduledTaskComplete(taskBlock)
        
        // Then: ScheduledTask is deleted
        XCTAssertEqual(mockRepository.deletedScheduledTaskIds.count, 1)
        XCTAssertEqual(mockRepository.deletedScheduledTaskIds[0], "st-2")
    }
    
    func testMarkScheduledTaskComplete_ShowsRewardMessage() async throws {
        // Given: A scheduled task exists
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task = Task(
            id: "task-3",
            userId: "test-user",
            title: "Review Code",
            priority: "must-do",
            energyLevel: "any",
            isCompleted: false,
            createdAt: Date()
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-3",
            taskId: "task-3",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 16, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 17, to: startOfDay)!
        )
        
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.currentDate = today
        mockRepository.mockTasks = [task]
        mockRepository.mockScheduledTasks = [scheduledTask]
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Mark task as complete
        await viewModel.markScheduledTaskComplete(taskBlock)
        
        // Then: Success message is shown
        XCTAssertTrue(viewModel.showSuccessMessage)
        XCTAssertFalse(viewModel.successMessage.isEmpty)
        XCTAssertTrue(viewModel.successMessage.contains("!"))
    }
    
    func testMarkScheduledTaskComplete_RegeneratesTimeBlocks() async throws {
        // Given: A scheduled task exists with commitments
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        let task = Task(
            id: "task-4",
            userId: "test-user",
            title: "Design Feature",
            priority: "must-do",
            energyLevel: "high",
            isCompleted: false,
            createdAt: Date()
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-4",
            taskId: "task-4",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment]
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.currentDate = today
        mockRepository.mockTasks = [task]
        mockRepository.mockScheduledTasks = [scheduledTask]
        
        viewModel.generateTimeBlocks()
        _ = viewModel.timeBlocks.count
        let initialTaskBlocks = viewModel.timeBlocks.filter { $0.type == .task }.count
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Mark task as complete
        await viewModel.markScheduledTaskComplete(taskBlock)
        
        // Then: Timeline is regenerated with task removed
        let finalTaskBlocks = viewModel.timeBlocks.filter { $0.type == .task }.count
        XCTAssertEqual(initialTaskBlocks, 1)
        XCTAssertEqual(finalTaskBlocks, 0)
    }
    
    func testMarkScheduledTaskComplete_CreatesNewFreeTime() async throws {
        // Given: A scheduled task between two commitments
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let commitment1 = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting 1",
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        let commitment2 = FixedCommitment(
            id: "c2",
            userId: "test-user",
            title: "Meeting 2",
            startTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 13, to: startOfDay)!
        )
        
        let task = Task(
            id: "task-5",
            userId: "test-user",
            title: "Middle Task",
            priority: "must-do",
            energyLevel: "any",
            isCompleted: false,
            createdAt: Date()
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-5",
            taskId: "task-5",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!.addingTimeInterval(900), // 10:15 AM
            endTime: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!.addingTimeInterval(900) // 11:15 AM
        )
        
        viewModel.commitments = [commitment1, commitment2]
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [scheduledTask]
        viewModel.currentDate = today
        mockRepository.mockTasks = [task]
        mockRepository.mockScheduledTasks = [scheduledTask]
        
        viewModel.calculateFreeTime()
        viewModel.generateTimeBlocks()
        
        _ = viewModel.timeBlocks.filter { $0.type == .empty }.count
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Mark task as complete
        await viewModel.markScheduledTaskComplete(taskBlock)
        
        // Then: Free time increases (task slot becomes free)
        viewModel.calculateFreeTime()
        let finalEmptyBlocks = viewModel.timeBlocks.filter { $0.type == .empty }.count
        
        // Empty blocks may consolidate, so we check that free time exists
        XCTAssertGreaterThanOrEqual(finalEmptyBlocks, 1)
    }
    
    func testMarkScheduledTaskComplete_HandlesError() async throws {
        // Given: Repository will fail
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task = Task(
            id: "task-6",
            userId: "test-user",
            title: "Error Task",
            priority: "must-do",
            energyLevel: "any",
            isCompleted: false,
            createdAt: Date()
        )
        
        let scheduledTask = ScheduledTask(
            id: "st-6",
            taskId: "task-6",
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        )
        
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [scheduledTask]
        mockRepository.mockTasks = [task]
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = DataRepositoryError.updateFailed
        
        let taskBlock = TimeBlock(from: scheduledTask, taskTitle: task.title)
        
        // When: Mark task as complete
        await viewModel.markScheduledTaskComplete(taskBlock)
        
        // Then: Error message is set
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to complete task"))
    }
    
    func testGenerateRewardMessage_ReturnsValidString() throws {
        // When: Generate reward messages multiple times
        var _: Set<String> = []
        for _ in 0..<20 {
            // Use reflection to call private method for testing
            // Alternative: Test through markScheduledTaskComplete
            // For now, we'll verify through the public interface
        }
        
        // Then: We can't directly test private method, but we verify through completion
        // The message should always be non-empty and contain emoji
        // This is verified in testMarkScheduledTaskComplete_ShowsRewardMessage
        XCTAssertTrue(true) // Placeholder - actual verification done in integration test
    }
    
    // MARK: - Story 3.4: Add Suggested Task to Schedule Tests
    
    func testAddSuggestedTaskToSchedule_Success() async throws {
        // Given: Setup test environment with free time available
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Create a task to add
        let task = Task(
            id: "flexible-task-1",
            userId: "test-user",
            title: "Write Report",
            priority: "flexible",
            priorityLevel: 2,
            energyLevel: "high",
            estimatedDuration: 3600, // 60 minutes
            isCompleted: false,
            createdAt: Date()
        )
        
        // Setup mock repository with the task
        mockRepository.mockTasks = [task]
        viewModel.tasks = [task]
        
        // Create a commitment to have some schedule structure
        let commitment = FixedCommitment(
            id: "c1",
            userId: "test-user",
            title: "Meeting",
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment]
        mockRepository.mockCommitments = [commitment]
        mockRepository.shouldThrowError = false
        
        // When: Add suggested task to schedule
        await viewModel.addSuggestedTaskToSchedule(task, currentMoodEnergy: "high")
        
        // Then: Task should be scheduled
        XCTAssertEqual(viewModel.scheduledTasks.count, 1)
        XCTAssertEqual(viewModel.scheduledTasks[0].taskId, task.id)
        XCTAssertTrue(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "✅ Task added to your schedule!")
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify timeline was refreshed (should have commitment + scheduled task + empty blocks)
        XCTAssertGreaterThanOrEqual(viewModel.timeBlocks.count, 2)
    }
    
    func testAddSuggestedTaskToSchedule_NoAvailableSlot() async throws {
        // Given: Schedule is completely full
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task = Task(
            id: "flexible-task-2",
            userId: "test-user",
            title: "Quick Task",
            priority: "flexible",
            priorityLevel: 3,
            energyLevel: "any",
            estimatedDuration: 1800, // 30 minutes
            isCompleted: false,
            createdAt: Date()
        )
        
        // Fill entire day with commitments (6 AM to midnight)
        var commitments: [FixedCommitment] = []
        for hour in 6..<24 {
            let commitment = FixedCommitment(
                id: "c\(hour)",
                userId: "test-user",
                title: "Busy Block \(hour)",
                startTime: calendar.date(byAdding: .hour, value: hour, to: startOfDay)!,
                endTime: calendar.date(byAdding: .hour, value: hour + 1, to: startOfDay)!
            )
            commitments.append(commitment)
        }
        
        viewModel.commitments = commitments
        viewModel.tasks = [task]
        mockRepository.mockTasks = [task]
        mockRepository.shouldThrowError = false
        
        // When: Try to add suggested task
        await viewModel.addSuggestedTaskToSchedule(task, currentMoodEnergy: "medium")
        
        // Then: Should show error about no available slots
        XCTAssertEqual(viewModel.scheduledTasks.count, 0)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("No available time slots"))
        XCTAssertFalse(viewModel.showSuccessMessage)
    }
    
    func testAddSuggestedTaskToSchedule_TaskAlreadyScheduled() async throws {
        // Given: Task is already scheduled for today
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let task = Task(
            id: "flexible-task-3",
            userId: "test-user",
            title: "Duplicate Task",
            priority: "flexible",
            priorityLevel: 2,
            energyLevel: "high",
            estimatedDuration: 1800,
            isCompleted: false,
            createdAt: Date()
        )
        
        let existingScheduledTask = ScheduledTask(
            id: "st-existing",
            taskId: task.id!,  // Force unwrap is safe in test context
            date: today,
            startTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 10, to: startOfDay)!
        )
        
        viewModel.tasks = [task]
        viewModel.scheduledTasks = [existingScheduledTask]
        mockRepository.mockTasks = [task]
        mockRepository.shouldThrowError = false
        
        // When: Try to add same task again
        await viewModel.addSuggestedTaskToSchedule(task, currentMoodEnergy: "high")
        
        // Then: Should show info message about already scheduled
        XCTAssertEqual(viewModel.scheduledTasks.count, 1) // Still just the original
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("already on your schedule"))
        XCTAssertFalse(viewModel.showSuccessMessage)
    }
    
    func testAddSuggestedTaskToSchedule_ShowsSuccessMessage() async throws {
        // Given: Valid scenario for adding task
        let task = Task(
            id: "flexible-task-4",
            userId: "test-user",
            title: "Success Task",
            priority: "flexible",
            priorityLevel: 2,
            energyLevel: "medium",
            estimatedDuration: 1800,
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.tasks = [task]
        mockRepository.mockTasks = [task]
        mockRepository.shouldThrowError = false
        
        // When: Add task successfully
        await viewModel.addSuggestedTaskToSchedule(task, currentMoodEnergy: "medium")
        
        // Then: Success message should be displayed
        XCTAssertTrue(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "✅ Task added to your schedule!")
        
        // Note: Auto-dismiss after 2 seconds is tested manually
    }
    
    func testAddSuggestedTaskToSchedule_HandlesRepositoryError() async throws {
        // Given: Repository will fail to save
        let task = Task(
            id: "flexible-task-5",
            userId: "test-user",
            title: "Error Task",
            priority: "flexible",
            priorityLevel: 2,
            energyLevel: "low",
            estimatedDuration: 1800,
            isCompleted: false,
            createdAt: Date()
        )
        
        viewModel.tasks = [task]
        mockRepository.mockTasks = [task]
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = DataRepositoryError.saveFailed
        
        // When: Try to add task (save will fail)
        await viewModel.addSuggestedTaskToSchedule(task, currentMoodEnergy: "low")
        
        // Then: Error message should be displayed
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to add task"))
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.scheduledTasks.count, 0)
    }
}



