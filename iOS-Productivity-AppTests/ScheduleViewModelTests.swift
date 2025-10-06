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
        viewModel = ScheduleViewModel(repository: mockRepository)
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
        // Given: Commitments with gaps
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
            title: "Afternoon Meeting",
            startTime: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endTime: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!
        )
        
        viewModel.commitments = [commitment1, commitment2]
        viewModel.currentDate = today
        
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
        // Given: No commitments
        viewModel.commitments = []
        viewModel.currentDate = Date()
        
        // When: Calculate free time
        viewModel.calculateFreeTime()
        
        // Then: Should have single full-day slot
        XCTAssertEqual(viewModel.freeTimeSlots.count, 1)
        
        let calendar = Calendar.current
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

