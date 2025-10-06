//
//  AuthenticationView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

/// Root authentication view that manages the authentication flow
struct AuthenticationView: View {
    let authManager: AuthManager
    
    var body: some View {
        NavigationView {
            LoginView(authManager: authManager)
        }
    }
}

#Preview {
    // Note: Using MockAuthManager to prevent Firebase initialization in previews
    class MockAuthManager: AuthManager {
        override init() {
            // Don't call super.init() to avoid Firebase initialization
        }
    }
    
    return AuthenticationView(authManager: MockAuthManager())
}
