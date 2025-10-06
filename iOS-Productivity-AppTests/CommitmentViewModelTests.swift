//
//  CommitmentViewModelTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import XCTest
@testable import iOS_Productivity_App

@MainActor
final class CommitmentViewModelTests: XCTestCase {
    var viewModel: CommitmentViewModel!
    var mockRepository: MockDataRepository!
    
    override func setUp() async throws {
        mockRepository = MockDataRepository()
        viewModel = CommitmentViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
    }
    
    // MARK: - Validation Tests
    
    func testValidateInput_EmptyTitle_ReturnsFalse() {
        // Given
        viewModel.title = ""
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testValidateInput_WhitespaceOnlyTitle_ReturnsFalse() {
        // Given
        viewModel.title = "   "
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testValidateInput_EndTimeBeforeStartTime_ReturnsFalse() {
        // Given
        viewModel.title = "Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(-3600) // 1 hour before
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "End time must be after start time.")
    }
    
    func testValidateInput_EndTimeEqualsStartTime_ReturnsFalse() {
        // Given
        let now = Date()
        viewModel.title = "Meeting"
        viewModel.startTime = now
        viewModel.endTime = now
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "End time must be after start time.")
    }
    
    func testValidateInput_ValidInput_ReturnsTrue() {
        // Given
        viewModel.title = "Team Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        let result = viewModel.validateInput()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Create Commitment Tests
    
    func testCreateCommitment_ValidInput_Success() async {
        // Given
        viewModel.title = "CS 101 Lecture"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        await viewModel.createCommitment()
        
        // Then
        XCTAssertTrue(mockRepository.createCommitmentCalled)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.mockCommitments.count, 1)
        XCTAssertEqual(mockRepository.mockCommitments.first?.title, "CS 101 Lecture")
    }
    
    func testCreateCommitment_EmptyTitle_ValidationFails() async {
        // Given
        viewModel.title = ""
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        await viewModel.createCommitment()
        
        // Then
        XCTAssertFalse(mockRepository.createCommitmentCalled)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testCreateCommitment_InvalidTimeRange_ValidationFails() async {
        // Given
        viewModel.title = "Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(-3600)
        
        // When
        await viewModel.createCommitment()
        
        // Then
        XCTAssertFalse(mockRepository.createCommitmentCalled)
        XCTAssertEqual(viewModel.errorMessage, "End time must be after start time.")
    }
    
    func testCreateCommitment_RepositoryError_HandlesError() async {
        // Given
        viewModel.title = "Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.createCommitment()
        
        // Then
        XCTAssertTrue(mockRepository.createCommitmentCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to save") ?? false)
    }
    
    func testCreateCommitment_ResetsFormOnSuccess() async {
        // Given
        viewModel.title = "Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        await viewModel.createCommitment()
        
        // Then
        XCTAssertEqual(viewModel.title, "")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Load Commitments Tests
    
    func testLoadCommitments_Success_UpdatesCommitments() async {
        // Given
        let commitment1 = FixedCommitment(id: "1", userId: "user1", title: "Meeting 1", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        let commitment2 = FixedCommitment(id: "2", userId: "user1", title: "Meeting 2", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        mockRepository.mockCommitments = [commitment1, commitment2]
        
        // When
        await viewModel.loadCommitments()
        
        // Then
        XCTAssertEqual(viewModel.commitments.count, 2)
        XCTAssertEqual(viewModel.commitments.first?.title, "Meeting 1")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadCommitments_EmptyList_UpdatesCommitments() async {
        // Given
        mockRepository.mockCommitments = []
        
        // When
        await viewModel.loadCommitments()
        
        // Then
        XCTAssertEqual(viewModel.commitments.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadCommitments_RepositoryError_HandlesError() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.loadCommitments()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to load") ?? false)
    }
    
    // MARK: - Delete Commitment Tests
    
    func testDeleteCommitment_Success_RemovesCommitment() async {
        // Given
        let commitment = FixedCommitment(id: "1", userId: "user1", title: "Meeting", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        mockRepository.mockCommitments = [commitment]
        
        // When
        await viewModel.deleteCommitment(commitment)
        
        // Then
        XCTAssertTrue(mockRepository.deleteCommitmentCalled)
        XCTAssertEqual(mockRepository.mockCommitments.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteCommitment_RepositoryError_HandlesError() async {
        // Given
        let commitment = FixedCommitment(id: "1", userId: "user1", title: "Meeting", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.deleteCommitment(commitment)
        
        // Then
        XCTAssertTrue(mockRepository.deleteCommitmentCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to delete") ?? false)
    }
    
    func testDeleteCommitment_NoId_HandlesError() async {
        // Given
        let commitment = FixedCommitment(id: nil, userId: "user1", title: "Meeting", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        
        // When
        await viewModel.deleteCommitment(commitment)
        
        // Then
        XCTAssertFalse(mockRepository.deleteCommitmentCalled)
        XCTAssertEqual(viewModel.errorMessage, "Invalid commitment ID.")
    }
    
    // MARK: - Reset Form Tests
    
    func testResetForm_ClearsAllFormFields() {
        // Given
        viewModel.title = "Meeting"
        viewModel.startTime = Date().addingTimeInterval(7200)
        viewModel.endTime = Date().addingTimeInterval(10800)
        viewModel.errorMessage = "Some error"
        
        // When
        viewModel.resetForm()
        
        // Then
        XCTAssertEqual(viewModel.title, "")
        XCTAssertNil(viewModel.errorMessage)
        // Start time should be close to now
        XCTAssertLessThan(abs(viewModel.startTime.timeIntervalSinceNow), 5)
        // End time should be about 1 hour after start time
        XCTAssertEqual(viewModel.endTime.timeIntervalSince(viewModel.startTime), 3600, accuracy: 5)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadCommitments_SetsLoadingState() async {
        // Given
        var loadingStates: [Bool] = []
        
        // Capture loading states
        let expectation = expectation(description: "Loading state changes")
        expectation.expectedFulfillmentCount = 2
        
        // When
        _Concurrency.Task {
            await viewModel.loadCommitments()
            loadingStates.append(viewModel.isLoading)
            expectation.fulfill()
        }
        
        loadingStates.append(viewModel.isLoading)
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 2)
        
        // Then - At some point loading should have been true, and end as false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCreateCommitment_SetsLoadingState() async {
        // Given
        viewModel.title = "Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        await viewModel.createCommitment()
        
        // Then - Loading should be false after completion
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Edit Mode Tests
    
    func testLoadCommitmentForEditing_PopulatesFormFields() {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "CS 101 Lecture",
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200)
        )
        
        // When
        viewModel.loadCommitmentForEditing(commitment)
        
        // Then
        XCTAssertEqual(viewModel.title, "CS 101 Lecture")
        XCTAssertEqual(viewModel.startTime, commitment.startTime)
        XCTAssertEqual(viewModel.endTime, commitment.endTime)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadCommitmentForEditing_SetsEditingCommitment() {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "CS 101 Lecture",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // When
        viewModel.loadCommitmentForEditing(commitment)
        
        // Then
        XCTAssertNotNil(viewModel.editingCommitment)
        XCTAssertEqual(viewModel.editingCommitment?.id, "1")
        XCTAssertEqual(viewModel.editingCommitment?.title, "CS 101 Lecture")
    }
    
    func testIsEditMode_WhenEditingCommitmentIsSet_ReturnsTrue() {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // When
        viewModel.loadCommitmentForEditing(commitment)
        
        // Then
        XCTAssertTrue(viewModel.isEditMode)
    }
    
    func testIsEditMode_WhenEditingCommitmentIsNil_ReturnsFalse() {
        // Given
        viewModel.editingCommitment = nil
        
        // Then
        XCTAssertFalse(viewModel.isEditMode)
    }
    
    func testSaveEditedCommitment_ValidInput_Success() async {
        // Given
        let originalCommitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Original Title",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        mockRepository.mockCommitments = [originalCommitment]
        
        viewModel.loadCommitmentForEditing(originalCommitment)
        viewModel.title = "Updated Title"
        viewModel.startTime = Date().addingTimeInterval(7200)
        viewModel.endTime = Date().addingTimeInterval(10800)
        
        // When
        await viewModel.saveEditedCommitment()
        
        // Then
        XCTAssertTrue(mockRepository.updateCommitmentCalled)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.mockCommitments.first?.title, "Updated Title")
    }
    
    func testSaveEditedCommitment_ValidationFailure_DoesNotUpdate() async {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Original Title",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        viewModel.loadCommitmentForEditing(commitment)
        viewModel.title = "" // Invalid title
        
        // When
        await viewModel.saveEditedCommitment()
        
        // Then
        XCTAssertFalse(mockRepository.updateCommitmentCalled)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
    }
    
    func testSaveEditedCommitment_RepositoryError_HandlesError() async {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Original Title",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        viewModel.loadCommitmentForEditing(commitment)
        viewModel.title = "Updated Title"
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.saveEditedCommitment()
        
        // Then
        XCTAssertTrue(mockRepository.updateCommitmentCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to update") ?? false)
    }
    
    func testSaveEditedCommitment_CallsUpdateCommitmentOnRepository() async {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        mockRepository.mockCommitments = [commitment]
        viewModel.loadCommitmentForEditing(commitment)
        viewModel.title = "Updated Meeting"
        
        // When
        await viewModel.saveEditedCommitment()
        
        // Then
        XCTAssertTrue(mockRepository.updateCommitmentCalled)
    }
    
    func testSaveCommitment_RoutesToCreate_WhenNotInEditMode() async {
        // Given
        viewModel.editingCommitment = nil
        viewModel.title = "New Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(3600)
        
        // When
        await viewModel.saveCommitment()
        
        // Then
        XCTAssertTrue(mockRepository.createCommitmentCalled)
        XCTAssertFalse(mockRepository.updateCommitmentCalled)
    }
    
    func testSaveCommitment_RoutesToEdit_WhenInEditMode() async {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Original",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        mockRepository.mockCommitments = [commitment]
        viewModel.loadCommitmentForEditing(commitment)
        viewModel.title = "Updated"
        
        // When
        await viewModel.saveCommitment()
        
        // Then
        XCTAssertFalse(mockRepository.createCommitmentCalled)
        XCTAssertTrue(mockRepository.updateCommitmentCalled)
    }
    
    func testResetForm_ClearsEditingCommitment() {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        viewModel.loadCommitmentForEditing(commitment)
        
        // When
        viewModel.resetForm()
        
        // Then
        XCTAssertNil(viewModel.editingCommitment)
        XCTAssertFalse(viewModel.isEditMode)
        XCTAssertEqual(viewModel.title, "")
    }
    
    func testSaveEditedCommitment_InvalidTimeRange_ValidationFails() async {
        // Given
        let commitment = FixedCommitment(
            id: "1",
            userId: "user1",
            title: "Meeting",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        viewModel.loadCommitmentForEditing(commitment)
        viewModel.title = "Updated Meeting"
        viewModel.startTime = Date()
        viewModel.endTime = Date().addingTimeInterval(-3600) // Invalid: end before start
        
        // When
        await viewModel.saveEditedCommitment()
        
        // Then
        XCTAssertFalse(mockRepository.updateCommitmentCalled)
        XCTAssertEqual(viewModel.errorMessage, "End time must be after start time.")
    }
}
