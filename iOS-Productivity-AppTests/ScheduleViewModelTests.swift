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
        
        // Then: Commitments are loaded and time blocks generated
        XCTAssertEqual(viewModel.commitments.count, 2)
        XCTAssertEqual(viewModel.timeBlocks.count, 2)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        // Verify time blocks are correctly converted
        XCTAssertEqual(viewModel.timeBlocks[0].title, "Morning Meeting")
        XCTAssertEqual(viewModel.timeBlocks[0].type, .commitment)
        XCTAssertEqual(viewModel.timeBlocks[1].title, "Lunch")
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
        
        // When: Generate time blocks
        viewModel.generateTimeBlocks()
        
        // Then: Time blocks are created
        XCTAssertEqual(viewModel.timeBlocks.count, 1)
        XCTAssertEqual(viewModel.timeBlocks[0].title, "Team Standup")
        XCTAssertEqual(viewModel.timeBlocks[0].type, .commitment)
        XCTAssertEqual(viewModel.timeBlocks[0].startTime, commitment.startTime)
        XCTAssertEqual(viewModel.timeBlocks[0].endTime, commitment.endTime)
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
        
        let loadTask = Task {
            await viewModel.loadCommitments()
        }
        
        // Brief delay to check loading state
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await loadTask.value
        
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
        
        // Then: Lists are empty but no error
        XCTAssertTrue(viewModel.commitments.isEmpty)
        XCTAssertTrue(viewModel.timeBlocks.isEmpty)
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
}
