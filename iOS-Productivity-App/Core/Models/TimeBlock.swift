//
//  TimeBlock.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation

struct TimeBlock: Identifiable {
    let id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var type: TimeBlockType
    var scheduledTaskId: String? // Track the scheduled task ID for drag operations
    
    enum TimeBlockType {
        case commitment
        case task
        case empty
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    init(id: UUID = UUID(), title: String, startTime: Date, endTime: Date, type: TimeBlockType, scheduledTaskId: String? = nil) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.scheduledTaskId = scheduledTaskId
    }
    
    init(from freeTimeSlot: FreeTimeSlot) {
        self.init(
            id: freeTimeSlot.id,
            title: "Available",
            startTime: freeTimeSlot.startTime,
            endTime: freeTimeSlot.endTime,
            type: .empty,
            scheduledTaskId: nil
        )
    }
    
    init(from scheduledTask: ScheduledTask, taskTitle: String) {
        self.init(
            id: UUID(uuidString: scheduledTask.id ?? "") ?? UUID(),
            title: taskTitle,
            startTime: scheduledTask.startTime,
            endTime: scheduledTask.endTime,
            type: .task,
            scheduledTaskId: scheduledTask.id
        )
    }
}
