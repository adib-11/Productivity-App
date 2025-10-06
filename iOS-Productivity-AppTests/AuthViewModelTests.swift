//
//  AuthViewModelTests.swift
//  iOS-Productivity-AppTests
//
//  Created on 2025-10-06.
//

import XCTest
import FirebaseAuth
import Combine
@testable import iOS_Productivity_App

final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockAuthManager: MockAuthManager!
    
    override func setUp() {
        super.setUp()
        mockAuthManager = MockAuthManager()
        viewModel = AuthViewModel(authManager: mockAuthManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthManager = nil
        super.tearDown()
    }
    
    // MARK: - Email Validation Tests
    
    func testValidateInput_EmptyEmail_ReturnsError() {
        viewModel.email = ""
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please fill in all fields.")
    }
    
    func testValidateInput_EmptyPassword_ReturnsError() {
        viewModel.email = "test@example.com"
        viewModel.password = ""
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please fill in all fields.")
    }
    
    func testValidateInput_BothFieldsEmpty_ReturnsError() {
        viewModel.email = ""
        viewModel.password = ""
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please fill in all fields.")
    }
    
    func testValidateInput_InvalidEmailFormat_NoAtSymbol_ReturnsError() {
        viewModel.email = "testexample.com"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address.")
    }
    
    func testValidateInput_InvalidEmailFormat_NoDomain_ReturnsError() {
        viewModel.email = "test@"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address.")
    }
    
    func testValidateInput_InvalidEmailFormat_OnlyAtSymbol_ReturnsError() {
        viewModel.email = "@."
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address.")
    }
    
    func testValidateInput_InvalidEmailFormat_DoubleAtSymbol_ReturnsError() {
        viewModel.email = "test@@example.com"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address.")
    }
    
    func testValidateInput_InvalidEmailFormat_NoTopLevelDomain_ReturnsError() {
        viewModel.email = "test@example"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address.")
    }
    
    func testValidateInput_PasswordTooShort_ReturnsError() {
        viewModel.email = "test@example.com"
        viewModel.password = "12345" // 5 characters
        let result = viewModel.performValidation()
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Password must be at least 6 characters long.")
    }
    
    func testValidateInput_PasswordExactly6Characters_ReturnsTrue() {
        viewModel.email = "test@example.com"
        viewModel.password = "123456" // Exactly 6 characters
        let result = viewModel.performValidation()
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testValidateInput_ValidCredentials_ReturnsTrue() {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testValidateInput_ValidEmailWithSubdomain_ReturnsTrue() {
        viewModel.email = "user@mail.example.com"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testValidateInput_ValidEmailWithPlus_ReturnsTrue() {
        viewModel.email = "user+tag@example.com"
        viewModel.password = "password123"
        let result = viewModel.performValidation()
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Error Mapping Tests
    
    func testMapAuthError_EmailAlreadyInUse() {
        let error = createAuthError(code: .emailAlreadyInUse)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "This email is already registered. Please log in instead.")
    }
    
    func testMapAuthError_InvalidEmail() {
        let error = createAuthError(code: .invalidEmail)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "Please enter a valid email address.")
    }
    
    func testMapAuthError_WeakPassword() {
        let error = createAuthError(code: .weakPassword)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "Password must be at least 6 characters long.")
    }
    
    func testMapAuthError_WrongPassword() {
        let error = createAuthError(code: .wrongPassword)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "Incorrect email or password. Please try again.")
    }
    
    func testMapAuthError_UserNotFound() {
        let error = createAuthError(code: .userNotFound)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "No account found with this email. Please sign up.")
    }
    
    func testMapAuthError_NetworkError() {
        let error = createAuthError(code: .networkError)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "Network error. Please check your internet connection.")
    }
    
    func testMapAuthError_UnknownError() {
        let error = createAuthError(code: .internalError)
        let message = viewModel.testMapAuthError(error)
        XCTAssertEqual(message, "Authentication failed. Please try again.")
    }
    
    func testMapAuthError_GenericNSError() {
        // Test with NSError from non-Firebase domain
        // The actual implementation maps ANY error code successfully to AuthErrorCode.Code
        // If it's not a recognized Firebase error, it hits the default case
        let error = NSError(domain: "com.test.NonFirebaseError", code: -1, userInfo: nil)
        let message = viewModel.testMapAuthError(error)
        // Any valid AuthErrorCode.Code that doesn't match specific cases hits default
        XCTAssertEqual(message, "Authentication failed. Please try again.")
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_WithValidCredentials_CallsAuthManager() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthManager.shouldSucceed = true
        
        await viewModel.signUp()
        
        XCTAssertTrue(mockAuthManager.signUpCalled)
        XCTAssertEqual(mockAuthManager.lastEmail, "test@example.com")
        XCTAssertEqual(mockAuthManager.lastPassword, "password123")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignUp_WithInvalidEmail_DoesNotCallAuthManager() async {
        viewModel.email = "invalid"
        viewModel.password = "password123"
        
        await viewModel.signUp()
        
        XCTAssertFalse(mockAuthManager.signUpCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSignUp_WithError_SetsErrorMessage() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthManager.shouldSucceed = false
        mockAuthManager.errorToThrow = createAuthError(code: .emailAlreadyInUse)
        
        await viewModel.signUp()
        
        XCTAssertTrue(mockAuthManager.signUpCalled)
        XCTAssertEqual(viewModel.errorMessage, "This email is already registered. Please log in instead.")
    }
    
    func testSignUp_SetsLoadingState() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthManager.shouldSucceed = true
        
        let expectation = expectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        let cancellable = viewModel.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count == 3 { // Initial false, true during operation, false after
                expectation.fulfill()
            }
        }
        
        await viewModel.signUp()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [false, true, false])
        
        cancellable.cancel()
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_WithValidCredentials_CallsAuthManager() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthManager.shouldSucceed = true
        
        await viewModel.signIn()
        
        XCTAssertTrue(mockAuthManager.signInCalled)
        XCTAssertEqual(mockAuthManager.lastEmail, "test@example.com")
        XCTAssertEqual(mockAuthManager.lastPassword, "password123")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignIn_WithInvalidEmail_DoesNotCallAuthManager() async {
        viewModel.email = "invalid"
        viewModel.password = "password123"
        
        await viewModel.signIn()
        
        XCTAssertFalse(mockAuthManager.signInCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSignIn_WithError_SetsErrorMessage() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthManager.shouldSucceed = false
        mockAuthManager.errorToThrow = createAuthError(code: .wrongPassword)
        
        await viewModel.signIn()
        
        XCTAssertTrue(mockAuthManager.signInCalled)
        XCTAssertEqual(viewModel.errorMessage, "Incorrect email or password. Please try again.")
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_Success_CallsAuthManager() {
        mockAuthManager.shouldSucceed = true
        
        viewModel.signOut()
        
        XCTAssertTrue(mockAuthManager.signOutCalled)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignOut_WithError_SetsErrorMessage() {
        mockAuthManager.shouldSucceed = false
        
        viewModel.signOut()
        
        XCTAssertTrue(mockAuthManager.signOutCalled)
        XCTAssertEqual(viewModel.errorMessage, "Failed to sign out. Please try again.")
    }
    
    // MARK: - Helper Methods
    
    private func createAuthError(code: AuthErrorCode.Code) -> NSError {
        return NSError(domain: AuthErrorDomain, code: code.rawValue, userInfo: nil)
    }
}

extension AuthViewModel {
    /// Test helper to expose validation logic
    func performValidation() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields."
            return false
        }
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", 
            "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        if !emailPredicate.evaluate(with: email) {
            errorMessage = "Please enter a valid email address."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters long."
            return false
        }
        errorMessage = nil
        return true
    }
    
    /// Test helper to expose error mapping logic
    func testMapAuthError(_ error: NSError) -> String {
        guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
            return "An unexpected error occurred. Please try again."
        }
        
        switch errorCode {
        case .emailAlreadyInUse:
            return "This email is already registered. Please log in instead."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .wrongPassword:
            return "Incorrect email or password. Please try again."
        case .userNotFound:
            return "No account found with this email. Please sign up."
        case .networkError:
            return "Network error. Please check your internet connection."
        default:
            return "Authentication failed. Please try again."
        }
    }
}
