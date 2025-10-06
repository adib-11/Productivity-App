//
//  TimelineView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

extension Color {
    // Adaptive colors for dark mode support
    static let timelineBackground = Color(UIColor.systemGroupedBackground)
    static let timelineGridLine = Color(UIColor.separator)
    static let timelineHalfHourLine = Color(UIColor.systemGray5)
    static let timelineHourLabel = Color(UIColor.secondaryLabel)
    static let commitmentBlock = Color.blue // System blue adapts to dark mode
    static let currentTimeIndicator = Color.red // System red adapts to dark mode
}

struct TimelineView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    
    private let hourHeight: CGFloat = 60
    private let startHour: Int = 6
    private let endHour: Int = 24
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Layer 1: Timeline grid (hour markers and labels)
                        timelineGridView()
                        
                        // Layer 2: Commitment blocks
                        commitmentBlocksView()
                        
                        // Layer 3: Current time indicator (highest z-index)
                        currentTimeIndicatorView()
                    }
                    .frame(height: CGFloat(endHour - startHour) * hourHeight)
                }
                .background(Color.timelineBackground)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func timelineGridView() -> some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.system(size: 14))
                        .foregroundColor(Color.timelineHourLabel)
                        .frame(width: 60, alignment: .trailing)
                        .padding(.trailing, 8)
                    
                    VStack(spacing: 0) {
                        // Full hour line
                        Rectangle()
                            .fill(Color.timelineGridLine)
                            .frame(height: 1)
                        
                        Spacer()
                            .frame(height: 29)
                        
                        // Half-hour line
                        Rectangle()
                            .fill(Color.timelineHalfHourLine)
                            .frame(height: 0.5)
                        
                        Spacer()
                            .frame(height: 29.5)
                    }
                    .frame(height: hourHeight)
                }
                .frame(height: hourHeight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func commitmentBlocksView() -> some View {
        ForEach(viewModel.timeBlocks) { block in
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(block.formattedTimeRange)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(8)
            .frame(width: 250, height: max(30, calculateBlockHeight(from: block.startTime, to: block.endTime)), alignment: .topLeading)
            .background(Color.commitmentBlock)
            .cornerRadius(8)
            .shadow(radius: 2, x: 0, y: 1)
            .offset(
                x: 80,
                y: calculateVerticalPosition(for: block.startTime) + 8
            )
        }
    }
    
    private func currentTimeIndicatorView() -> some View {
        let currentTime = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        
        // Only show indicator if current time is within timeline hours
        if hour >= startHour && hour < endHour {
            return AnyView(
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.currentTimeIndicator)
                        .frame(width: 8, height: 8)
                        .padding(.leading, 16)
                    
                    Rectangle()
                        .fill(Color.currentTimeIndicator)
                        .frame(height: 2)
                    
                    Text("Now")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.currentTimeIndicator)
                        .cornerRadius(4)
                        .padding(.trailing, 16)
                }
                .offset(x: 0, y: viewModel.getCurrentTimeOffset() + 8)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private func calculateVerticalPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        let hoursSinceStart = hour - startHour
        let minuteOffset = CGFloat(minute)
        
        return CGFloat(hoursSinceStart) * hourHeight + minuteOffset
    }
    
    private func calculateBlockHeight(from start: Date, to end: Date) -> CGFloat {
        let durationMinutes = end.timeIntervalSince(start) / 60
        return CGFloat(durationMinutes)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}
