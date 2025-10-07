//
//  SchedulingConfiguration.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import Foundation

struct SchedulingConfiguration {
    var minimumGapBetweenEvents: TimeInterval
    var workDayStart: Int
    var workDayEnd: Int
    var minimumTaskDuration: TimeInterval
    var defaultTaskDuration: TimeInterval
    
    init(
        minimumGapBetweenEvents: TimeInterval = 15 * 60,
        workDayStart: Int = 0,  // Start at midnight (12 AM)
        workDayEnd: Int = 24,   // End at midnight (12 AM next day)
        minimumTaskDuration: TimeInterval = 15 * 60,
        defaultTaskDuration: TimeInterval = 30 * 60
    ) {
        self.minimumGapBetweenEvents = minimumGapBetweenEvents
        self.workDayStart = workDayStart
        self.workDayEnd = workDayEnd
        self.minimumTaskDuration = minimumTaskDuration
        self.defaultTaskDuration = defaultTaskDuration
    }
}
