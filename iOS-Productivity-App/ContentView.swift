//
//  ContentView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-05.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataRepository: DataRepository
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
            
            TaskInboxView(dataRepository: dataRepository)
                .tabItem {
                    Label("Tasks", systemImage: "tray.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.green)
                    .font(.system(size: 60))
                
                Text("Welcome to Productivity App!")
                    .font(.headline)
                
                if let user = authManager.currentUser {
                    Text("Logged in as:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .navigationTitle("Today")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataRepository: DataRepository
    
    var body: some View {
        NavigationStack {
            List {
                Section("Schedule Management") {
                    NavigationLink {
                        ManageCommitmentsView(repository: dataRepository)
                    } label: {
                        Label("Manage Fixed Commitments", systemImage: "calendar.badge.clock")
                    }
                }
                
                Section("Account") {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        _Concurrency.Task {
                            do {
                                try authManager.signOut()
                            } catch {
                                // Error is already handled by AuthManager
                                // and will update auth state appropriately
                            }
                        }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(DataRepository(authManager: AuthManager()))
}
