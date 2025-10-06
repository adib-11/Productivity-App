//
//  iOS_Productivity_AppApp.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-05.
//

import SwiftUI
import FirebaseCore

@main
struct iOS_Productivity_AppApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataRepository: DataRepository
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize DataRepository with AuthManager
        let tempAuthManager = AuthManager()
        _authManager = StateObject(wrappedValue: tempAuthManager)
        _dataRepository = StateObject(wrappedValue: DataRepository(authManager: tempAuthManager))
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(dataRepository)
            } else {
                AuthenticationView(authManager: authManager)
                    .environmentObject(authManager)
            }
        }
    }
}
