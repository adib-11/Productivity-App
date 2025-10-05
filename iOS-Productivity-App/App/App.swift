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
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
