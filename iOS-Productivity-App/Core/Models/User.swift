//
//  User.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation

/// Lightweight user model representing an authenticated user in the app.
/// The primary user record (UID, email, authentication tokens) is managed by Firebase Authentication.
/// This model is used for app-level user representation only.
struct User: Identifiable {
    /// Unique identifier (Firebase UID)
    let id: String
    
    /// User's email address
    let email: String
}
