# Story 2.4: Manual Testing Guide

## Quick Start

### Prerequisites
1. Firebase Emulator running OR connected to Firebase project
2. iOS Simulator with iPhone 15 (iOS 17+)
3. Test user account created (from Story 1.3)
4. At least 2 commitments and 2-3 scheduled tasks

### Test Data Setup

```swift
// Run these in app to create test data:
1. Add Commitment: "Morning Meeting" 9:00 AM - 10:00 AM
2. Add Commitment: "Lunch" 12:00 PM - 1:00 PM
3. Add Task: "Write Report" (must-do, high energy)
4. Add Task: "Review Code" (must-do, high energy)
5. Tap "Auto-Schedule" button
```

## Test Scenarios

### ✅ Scenario 1: Basic Drag-and-Drop
**Steps:**
1. Long-press on a scheduled task block
2. Drag vertically to an empty time slot
3. Release to drop

**Expected:**
- Block lifts with scale increase and shadow
- Block follows finger during drag
- On release, block moves to new time
- Change persists (reload app to verify)

**Pass Criteria:** Task successfully moves to new time slot

---

### ✅ Scenario 2: Invalid Drop on Commitment
**Steps:**
1. Long-press on a scheduled task
2. Drag onto a blue commitment block
3. Release

**Expected:**
- Warning haptic feedback
- Block animates back to original position with bounce
- Task remains at original time

**Pass Criteria:** Task does not overlap with commitment

---

### ✅ Scenario 3: Basic Resize
**Steps:**
1. Locate a scheduled task block
2. Tap and drag the 3-line handle at bottom of block
3. Drag downward to extend duration
4. Release

**Expected:**
- Block height increases during drag
- On release, task duration updates
- Change persists (reload app to verify)

**Pass Criteria:** Task duration successfully extends

---

### ✅ Scenario 4: Resize Below Minimum
**Steps:**
1. Find a 30-minute task
2. Drag resize handle upward to shrink below 15 minutes
3. Release

**Expected:**
- Warning haptic feedback
- Block snaps back to minimum 15-minute height
- Duration unchanged

**Pass Criteria:** Task cannot be resized below 15 minutes

---

### ✅ Scenario 5: Resize Into Next Block
**Steps:**
1. Find a task with commitment immediately after
2. Try to resize task to extend into commitment
3. Release

**Expected:**
- Warning haptic feedback
- Block cannot extend past commitment boundary
- Duration unchanged

**Pass Criteria:** Task cannot overlap with adjacent block

---

### ✅ Scenario 6: Multiple Operations
**Steps:**
1. Move task A to 2:00 PM
2. Move task B to 3:00 PM
3. Resize task A to 45 minutes
4. Reload app

**Expected:**
- All operations succeed independently
- All changes persist after reload
- No overlapping tasks

**Pass Criteria:** Multiple operations work correctly

---

## Debug Logging

Watch Xcode console for these log patterns:

### Successful Drag
```
🔵 [DragGesture] onChanged: offset=(0.0, 120.0), potentialDropSlot=2:00 PM - 3:00 PM
🔵 [DragGesture] onEnded: finalOffset=(0.0, 120.0)
🔵 [moveScheduledTask] Attempting to move task from 11:00 AM to 2:00 PM
✅ [moveScheduledTask] Task moved successfully
✅ [DragGesture] Task moved successfully
```

### Failed Drag (Overlap)
```
🔵 [DragGesture] onEnded: finalOffset=(0.0, 60.0)
🔵 [moveScheduledTask] Attempting to move task from 11:00 AM to 12:00 PM
❌ [isTimeSlotAvailable] Overlaps with commitment: Lunch
❌ [moveScheduledTask] Time slot not available
❌ [DragGesture] Invalid drop - task will bounce back
```

### Successful Resize
```
🟣 [ResizeGesture] onChanged: offset=30.0
🟣 [ResizeGesture] onEnded: finalOffset=30.0
🟣 [ResizeGesture] Current: 30.0min, New: 45.0min
🔵 [resizeScheduledTask] Attempting to resize task to duration: 45.0 minutes
✅ [resizeScheduledTask] Task resized successfully
✅ [ResizeGesture] Task resized successfully
```

## Known Issues / Expected Behavior

1. **Drag Near Screen Edge:** May trigger scroll - this is expected, use center of screen
2. **Very Small Tasks (15-min):** Resize handle shown smaller but always visible - users can still resize
3. **Offline Mode:** Operations queue locally, sync when reconnected
4. **Debug Prints:** All log statements present for troubleshooting

## Performance Benchmarks

- **Gesture Recognition:** < 100ms (should feel instant)
- **Animation Frame Rate:** 60 FPS (smooth, no stuttering)
- **Firestore Update:** < 500ms (background operation)
- **UI Refresh:** Immediate after operation completes

## Accessibility Testing

### VoiceOver
1. Enable VoiceOver in Settings
2. Focus on task block
3. Verify announcement: "Task title, scheduled from X to Y"
4. **TODO:** Alternative input method for drag/resize

### Dynamic Type
1. Settings > Accessibility > Display & Text Size
2. Increase text size to largest
3. Verify all text remains readable
4. Verify resize handle still visible

---

## Quick Regression Test (5 min)

1. ✅ Drag task to new slot → Success
2. ✅ Drag task onto commitment → Fails gracefully
3. ✅ Resize task larger → Success
4. ✅ Resize task below 15min → Fails gracefully
5. ✅ Reload app → Changes persist

**All 5 pass?** ✅ Ready for QA sign-off

---

**Questions?** Check `STORY-2.4-IMPLEMENTATION-STATUS.md` for technical details
