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
    
    init(
        minimumGapBetweenEvents: TimeInterval = 15 * 60,
        workDayStart: Int = 6,
        workDayEnd: Int = 24,
        minimumTaskDuration: TimeInterval = 15 * 60
    ) {
        self.minimumGapBetweenEvents = minimumGapBetweenEvents
        self.workDayStart = workDayStart
        self.workDayEnd = workDayEnd
        self.minimumTaskDuration = minimumTaskDuration
    }
}
