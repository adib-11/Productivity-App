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
    private let startHour: Int = 0  // Start at midnight (12 AM)
    private let endHour: Int = 24   // End at midnight (12 AM next day)
    
    // Drag gesture state
    @State private var draggedBlock: TimeBlock? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var potentialDropSlot: FreeTimeSlot? = nil
    @State private var isDragging: Bool = false
    @State private var draggedTaskId: String? = nil
    
    // Resize gesture state
    @State private var resizingBlock: TimeBlock? = nil
    @State private var resizeOffset: CGFloat = 0
    @State private var isResizing: Bool = false
    
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
                    .padding(.top, 40)  // Increased padding for better separation from title
                }
                .background(Color.timelineBackground)
            }
            
            // Success message overlay
            if viewModel.showSuccessMessage {
                VStack {
                    Spacer()
                    Text(viewModel.successMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: viewModel.showSuccessMessage)
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: viewModel.errorMessage.map { Text($0) },
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $viewModel.showInsufficientTimeAlert) {
            let unscheduledCount = viewModel.unscheduledMustDoTasks.count
            let taskList = viewModel.unscheduledMustDoTasks.map { "• \($0.title)" }.joined(separator: "\n")
            
            return Alert(
                title: Text("⚠️ Insufficient Free Time"),
                message: Text("Could not schedule \(unscheduledCount) must-do task(s) today:\n\n\(taskList)\n\nThese tasks will remain in your inbox. You can schedule them for tomorrow, or free up time by removing commitments."),
                dismissButton: .default(Text("Keep for Later"))
            )
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    _Concurrency.Task {
                        await viewModel.scheduleAutomaticTasks()
                    }
                }) {
                    Label("Auto-Schedule", systemImage: "sparkles")
                }
                .disabled(viewModel.isLoading)
            }
        })
    }
    
    private func timelineGridView() -> some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { hour in
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
            let isBeingDragged = isDragging && draggedTaskId == block.scheduledTaskId
            
            // Make empty blocks more compact
            let horizontalPadding: CGFloat = block.type == .empty ? 4 : 6
            let verticalPadding: CGFloat = block.type == .empty ? 2 : 3
            
            Group {
                if isVerySmallBlock {
                    // Horizontal layout for very small blocks
                    HStack(spacing: 3) {
                        Text(block.title)
                            .font(.system(size: 9, weight: block.type == .empty ? .medium : .semibold))
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
                            .font(.system(size: isSmallBlock ? 10 : 15, weight: block.type == .empty ? .regular : .semibold))
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
                Group {
                    // Border overlay
                    RoundedRectangle(cornerRadius: block.type == .empty ? 6 : 8)
                        .strokeBorder(
                            borderColorForBlock(block.type),
                            style: StrokeStyle(
                                lineWidth: block.type == .empty ? 1.5 : 0,
                                dash: block.type == .empty ? [4, 2] : []
                            )
                        )
                    
                    // Resize handle for task blocks (always show for tasks, smaller for very small blocks)
                    if block.type == .task {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: isVerySmallBlock ? 8 : 10))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(isVerySmallBlock ? 4 : 6)
                                    .background(Color.clear)
                                Spacer()
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    isResizing = true
                                    resizeOffset = value.translation.height
                                    resizingBlock = block
                                    print("🟣 [ResizeGesture] onChanged: offset=\(value.translation.height)")
                                }
                                .onEnded { value in
                                    print("🟣 [ResizeGesture] onEnded: finalOffset=\(value.translation.height)")
                                    
                                    guard let resizingBlock = resizingBlock else {
                                        resetResizeState()
                                        return
                                    }
                                    
                                    // Calculate new duration based on vertical drag
                                    let minutesChanged = Int(value.translation.height / hourHeight * 60)
                                    let currentDuration = resizingBlock.duration
                                    let newDuration = currentDuration + TimeInterval(minutesChanged * 60)
                                    
                                    print("🟣 [ResizeGesture] Current: \(currentDuration/60)min, New: \(newDuration/60)min")
                                    
                                    // Call ViewModel to resize task
                                    _Concurrency.Task {
                                        let success = await viewModel.resizeScheduledTask(resizingBlock, newDuration: newDuration)
                                        
                                        await MainActor.run {
                                            if success {
                                                print("✅ [ResizeGesture] Task resized successfully")
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                            } else {
                                                print("❌ [ResizeGesture] Invalid resize")
                                                let generator = UINotificationFeedbackGenerator()
                                                generator.notificationOccurred(.warning)
                                            }
                                            
                                            resetResizeState()
                                        }
                                    }
                                }
                        )
                    }
                }
            )
            .cornerRadius(block.type == .empty ? 6 : 8)
            .shadow(radius: block.type == .empty ? 0 : 2, x: 0, y: 1)
            .scaleEffect(isBeingDragged ? 1.05 : 1.0)
            .opacity(isBeingDragged ? 0.8 : 1.0)
            .shadow(radius: isBeingDragged ? 8 : (block.type == .empty ? 0 : 2))
            .clipped()
            .offset(
                x: 80 + (isBeingDragged ? dragOffset.width : 0),
                y: calculateVerticalPosition(for: block.startTime) + 10 + (isBeingDragged ? dragOffset.height : 0)
            )
            .zIndex(isBeingDragged ? 999 : (block.type == .empty ? 1 : 2))
            .accessibilityLabel(accessibilityLabelForBlock(block))
            .gesture(
                block.type == .task ? DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                        draggedBlock = block
                        draggedTaskId = block.scheduledTaskId
                        
                        // Calculate potential drop slot
                        let newStartTime = calculateNewStartTime(for: block, dragOffset: value.translation)
                        potentialDropSlot = findFreeSlotContaining(time: newStartTime)
                        
                        print("🔵 [DragGesture] onChanged: offset=\(value.translation), potentialDropSlot=\(potentialDropSlot?.formattedTimeRange ?? "none")")
                    }
                    .onEnded { value in
                        print("🔵 [DragGesture] onEnded: finalOffset=\(value.translation)")
                        
                        guard let draggedBlock = draggedBlock else {
                            resetDragState()
                            return
                        }
                        
                        let newStartTime = calculateNewStartTime(for: draggedBlock, dragOffset: value.translation)
                        
                        // Call ViewModel to move task
                        _Concurrency.Task {
                            let success = await viewModel.moveScheduledTask(draggedBlock, to: newStartTime)
                            
                            await MainActor.run {
                                if success {
                                    print("✅ [DragGesture] Task moved successfully")
                                    // Success haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                } else {
                                    print("❌ [DragGesture] Invalid drop - task will bounce back")
                                    // Warning haptic feedback
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.warning)
                                    
                                    // Animate bounce back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        resetDragState()
                                    }
                                }
                                
                                // Reset drag state
                                resetDragState()
                            }
                        }
                    }
                : nil
            )
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
            return Color.green // Green for scheduled tasks (Story 2.3)
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
                .opacity(0.65)  // Semi-transparent so text underneath is visible
                .offset(x: 0, y: viewModel.getCurrentTimeOffset() + 8)
                .zIndex(10)  // Ensure Now indicator is above all blocks
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
        let position = CGFloat(hoursSinceStart) * hourHeight + minuteOffset
        
        // Clamp position to visible timeline bounds (0 to max height)
        let maxHeight = CGFloat(endHour - startHour) * hourHeight
        return max(0, min(position, maxHeight))
    }
    
    private func calculateBlockHeight(from start: Date, to end: Date) -> CGFloat {
        let durationMinutes = end.timeIntervalSince(start) / 60
        return CGFloat(durationMinutes)
    }
    
    private func formatHour(_ hour: Int) -> String {
        // Handle 24 as midnight (12 AM) display
        let displayHour = hour == 24 ? 0 : hour
        let date = Calendar.current.date(bySettingHour: displayHour, minute: 0, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
    
    // MARK: - Drag Gesture Helpers
    
    private func calculateNewStartTime(for block: TimeBlock, dragOffset: CGSize) -> Date {
        // Convert vertical drag offset to time change
        let minutesMoved = Int(dragOffset.height / hourHeight * 60)
        let calendar = Calendar.current
        return calendar.date(byAdding: .minute, value: minutesMoved, to: block.startTime) ?? block.startTime
    }
    
    private func findFreeSlotContaining(time: Date) -> FreeTimeSlot? {
        return viewModel.freeTimeSlots.first { slot in
            time >= slot.startTime && time < slot.endTime
        }
    }
    
    private func resetDragState() {
        isDragging = false
        dragOffset = .zero
        draggedBlock = nil
        draggedTaskId = nil
        potentialDropSlot = nil
    }
    
    private func resetResizeState() {
        isResizing = false
        resizeOffset = 0
        resizingBlock = nil
    }
}
