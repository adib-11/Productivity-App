//
//  AuthManager.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation
import FirebaseAuth

/// Manages user authentication state and wraps all Firebase Auth SDK calls.
/// This service layer abstracts Firebase Auth from the rest of the app.
class AuthManager: ObservableObject {
    /// Currently authenticated user (nil if not authenticated)
    @Published var currentUser: User?
    
    /// Whether a user is currently authenticated
    @Published var isAuthenticated = false
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
    }
    
    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    /// Registers an auth state listener to persist login across app launches
    func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user.flatMap { self?.mapFirebaseUser($0) }
            self?.isAuthenticated = user != nil
        }
    }
    
    /// Creates a new user account with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (minimum 6 characters)
    /// - Returns: The created User object
    /// - Throws: Firebase Auth errors
    func signUp(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return mapFirebaseUser(result.user)
    }
    
    /// Authenticates an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated User object
    /// - Throws: Firebase Auth errors
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return mapFirebaseUser(result.user)
    }
    
    /// Signs out the current user
    /// - Throws: Firebase Auth errors
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    /// Maps a Firebase User to the app's User model
    /// - Parameter firebaseUser: Firebase Auth User object
    /// - Returns: App's User model
    private func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> User {
        User(id: firebaseUser.uid, email: firebaseUser.email ?? "")
    }
}
