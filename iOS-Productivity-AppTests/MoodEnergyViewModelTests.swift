//
//  MoodEnergyViewModelTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-08.
//

import XCTest
import Combine
@testable import iOS_Productivity_App

@MainActor
final class MoodEnergyViewModelTests: XCTestCase {
    
    var viewModel: MoodEnergyViewModel!
    var mockRepository: MockDataRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockDataRepository()
        viewModel = MoodEnergyViewModel(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Energy Level Options Tests
    
    func testEnergyLevelOptions_ReturnsValidOptions() {
        // When
        let options = viewModel.energyLevelOptions
        
        // Then
        XCTAssertEqual(options.count, 3)
        XCTAssertTrue(options.contains("high"))
        XCTAssertTrue(options.contains("medium"))
        XCTAssertTrue(options.contains("low"))
    }
    
    // MARK: - Save Mood Energy State Tests
    
    func testSaveMoodEnergyState_Success() async {
        // Given
        viewModel.selectedEnergyLevel = "high"
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.saveMoodEnergyState()
        
        // Then
        XCTAssertTrue(mockRepository.saveMoodEnergyStateCalled)
        XCTAssertNotNil(mockRepository.capturedMoodState)
        XCTAssertEqual(mockRepository.capturedMoodState?.energyLevel, "high")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSaveMoodEnergyState_WithNoSelection_DoesNotSave() async {
        // Given
        viewModel.selectedEnergyLevel = nil
        
        // When
        await viewModel.saveMoodEnergyState()
        
        // Then
        XCTAssertFalse(mockRepository.saveMoodEnergyStateCalled)
    }
    
    func testSaveMoodEnergyState_HandlesError() async {
        // Given
        viewModel.selectedEnergyLevel = "medium"
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.saveFailed
        
        // When
        await viewModel.saveMoodEnergyState()
        
        // Then
        XCTAssertTrue(mockRepository.saveMoodEnergyStateCalled)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, DataRepositoryError.saveFailed.localizedDescription)
    }
    
    // MARK: - Load Current Mood State Tests
    
    func testLoadCurrentMoodState_Success() async {
        // Given
        let mockMoodState = MoodEnergyState(userId: "test-user", energyLevel: "low")
        mockRepository.mockCurrentMoodState = mockMoodState
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.loadCurrentMoodState()
        
        // Then
        XCTAssertTrue(mockRepository.getCurrentMoodEnergyStateCalled)
        XCTAssertEqual(viewModel.selectedEnergyLevel, "low")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadCurrentMoodState_NoExistingState() async {
        // Given
        mockRepository.mockCurrentMoodState = nil
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.loadCurrentMoodState()
        
        // Then
        XCTAssertTrue(mockRepository.getCurrentMoodEnergyStateCalled)
        XCTAssertNil(viewModel.selectedEnergyLevel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadCurrentMoodState_HandlesError() async {
        // Given
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = DataRepositoryError.fetchFailed
        
        // When
        await viewModel.loadCurrentMoodState()
        
        // Then
        XCTAssertTrue(mockRepository.getCurrentMoodEnergyStateCalled)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, DataRepositoryError.fetchFailed.localizedDescription)
    }
    
    // MARK: - Loading State Tests
    
    func testSaveMoodEnergyState_SetsLoadingState() async {
        // Given
        viewModel.selectedEnergyLevel = "high"
        mockRepository.shouldSucceed = true
        
        // Track loading state changes
        var loadingStates: [Bool] = []
        let expectation = expectation(description: "Loading state changes")
        
        // Monitor isLoading changes
        let cancellable = viewModel.$isLoading
            .dropFirst() // Skip initial value
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 2 { // true, then false
                    expectation.fulfill()
                }
            }
        
        // When
        await viewModel.saveMoodEnergyState()
        
        // Wait for loading state changes
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertFalse(viewModel.isLoading)
        
        cancellable.cancel()
    }
}