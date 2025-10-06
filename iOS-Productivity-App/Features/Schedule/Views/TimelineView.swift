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
            let blockHeight = max(20, calculateBlockHeight(from: block.startTime, to: block.endTime))
            let isSmallBlock = blockHeight < 50
            let isVerySmallBlock = blockHeight < 35
            
            // Make empty blocks more compact
            let horizontalPadding: CGFloat = block.type == .empty ? 4 : 6
            let verticalPadding: CGFloat = block.type == .empty ? 2 : 3
            
            Group {
                if isVerySmallBlock {
                    // Horizontal layout for very small blocks
                    HStack(spacing: 3) {
                        Text(block.title)
                            .font(.system(size: 9, weight: block.type == .commitment ? .semibold : .medium))
                            .foregroundColor(textColorForBlock(block.type))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()
                        
                        Text(block.formattedTimeRange)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(subtextColorForBlock(block.type))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                } else {
                    // Vertical layout for normal blocks
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.title)
                            .font(.system(size: isSmallBlock ? 10 : 15, weight: block.type == .commitment ? .semibold : .regular))
                            .foregroundColor(textColorForBlock(block.type))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        
                        Text(block.formattedTimeRange)
                            .font(.system(size: isSmallBlock ? 9 : 12, weight: .medium))
                            .foregroundColor(subtextColorForBlock(block.type))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(horizontalPadding)
                }
            }
            .frame(width: 320, height: blockHeight, alignment: isVerySmallBlock ? .leading : .topLeading)
            .background(backgroundColorForBlock(block.type))
            .overlay(
                RoundedRectangle(cornerRadius: block.type == .empty ? 6 : 8)
                    .strokeBorder(
                        borderColorForBlock(block.type),
                        style: StrokeStyle(
                            lineWidth: block.type == .empty ? 1.5 : 0,
                            dash: block.type == .empty ? [4, 2] : []
                        )
                    )
            )
            .cornerRadius(block.type == .empty ? 6 : 8)
            .shadow(radius: block.type == .commitment ? 2 : 0, x: 0, y: 1)
            .clipped()
            .offset(
                x: 80,
                y: calculateVerticalPosition(for: block.startTime) + 10
            )
            .zIndex(block.type == .empty ? 1 : 0)
            .accessibilityLabel(accessibilityLabelForBlock(block))
        }
    }
    
    private func backgroundColorForBlock(_ type: TimeBlock.TimeBlockType) -> Color {
        switch type {
        case .commitment:
            return Color.commitmentBlock
        case .empty:
            // More distinct gray with better contrast
            return Color(UIColor.tertiarySystemGroupedBackground)
        case .task:
            return Color.green // Reserved for Story 2.3+
        }
    }
    
    private func borderColorForBlock(_ type: TimeBlock.TimeBlockType) -> Color {
        switch type {
        case .empty:
            // Darker, more visible border for empty blocks
            return Color(UIColor.systemGray)
        default:
            return Color.clear
        }
    }
    
    private func textColorForBlock(_ type: TimeBlock.TimeBlockType) -> Color {
        switch type {
        case .commitment:
            return .white
        case .empty:
            // Darker text for better readability on gray background
            return Color(UIColor.label)
        case .task:
            return .white
        }
    }
    
    private func subtextColorForBlock(_ type: TimeBlock.TimeBlockType) -> Color {
        switch type {
        case .commitment:
            return .white.opacity(0.95)
        case .empty:
            // High contrast text for better readability
            return Color(UIColor.label)
        case .task:
            return .white.opacity(0.95)
        }
    }
    
    private func accessibilityLabelForBlock(_ block: TimeBlock) -> String {
        switch block.type {
        case .commitment:
            return "\(block.title) from \(block.formattedTimeRange)"
        case .empty:
            let duration = Int(block.duration / 60)
            return "Available time slot from \(block.formattedTimeRange), duration \(duration) minutes"
        case .task:
            return "\(block.title) scheduled from \(block.formattedTimeRange)"
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
