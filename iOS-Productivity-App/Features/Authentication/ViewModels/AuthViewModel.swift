//
//  AuthViewModel.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation
import FirebaseAuth

/// Manages UI state and user input for authentication views.
/// This ViewModel layer sits between Views and AuthManager service (MVVM pattern).
class AuthViewModel: ObservableObject {
    /// User's email input
    @Published var email = ""
    
    /// User's password input
    @Published var password = ""
    
    /// Error message to display to the user (nil if no error)
    @Published var errorMessage: String?
    
    /// Whether an authentication operation is in progress
    @Published var isLoading = false
    
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    /// Attempts to create a new user account
    @MainActor
    func signUp() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authManager.signUp(email: email, password: password)
            // Success - auth state listener will update UI automatically
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Attempts to sign in an existing user
    @MainActor
    func signIn() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authManager.signIn(email: email, password: password)
            // Success - auth state listener will update UI automatically
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Signs out the current user
    func signOut() {
        do {
            try authManager.signOut()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to sign out. Please try again."
        }
    }
    
    /// Validates user input before attempting authentication
    /// - Returns: true if input is valid, false otherwise (sets errorMessage)
    private func validateInput() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields."
            return false
        }
        
        // Enhanced email validation using NSPredicate with RFC-compliant regex
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
        
        return true
    }
    
    /// Maps Firebase Auth error codes to user-friendly error messages
    /// - Parameter error: NSError from Firebase Auth
    /// - Returns: User-friendly error message
    private func mapAuthError(_ error: NSError) -> String {
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
