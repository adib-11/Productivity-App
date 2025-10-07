//
//  ScheduledTask.swift
//  iOS-Productivity-App
//
//  Created by Dev Agent on 2025-10-07.
//  Story 2.3: Schedule "Must-Do" Tasks
//

import Foundation
import FirebaseFirestoreSwift

struct ScheduledTask: Codable, Identifiable {
    @DocumentID var id: String?
    var taskId: String
    var date: Date
    var startTime: Date
    var endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    init(id: String? = nil, taskId: String, date: Date, startTime: Date, endTime: Date) {
        self.id = id
        self.taskId = taskId
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
    }
}
