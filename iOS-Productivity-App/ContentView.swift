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
            TodayView(dataRepository: dataRepository)
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
    @EnvironmentObject var dataRepository: DataRepository
    @StateObject private var scheduleViewModel: ScheduleViewModel
    
    init(dataRepository: DataRepository) {
        _scheduleViewModel = StateObject(wrappedValue: ScheduleViewModel(repository: dataRepository))
    }
    
    var body: some View {
        NavigationStack {
            TimelineView(viewModel: scheduleViewModel)
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(formatDate(scheduleViewModel.currentDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .task {
                    await scheduleViewModel.loadCommitments()
                }
                .onAppear {
                    // Reload timeline whenever tab becomes visible (e.g., after marking task complete)
                    _Concurrency.Task {
                        await scheduleViewModel.loadTasks()
                        await scheduleViewModel.loadScheduledTasks()
                        scheduleViewModel.generateTimeBlocks()
                    }
                }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
