# Story 2.4: Bug Fix - Resize Handle Visibility

**Date:** 2025-10-08
**Issue:** Resize handle disappeared for 15-minute tasks
**Status:** ✅ Fixed

## Problem Description

During manual testing, it was discovered that when a task block was resized down to the minimum duration (15 minutes), the resize handle would disappear. This created a UX dead-end where users could shrink a task but had no way to make it larger again.

### Root Cause
The resize handle visibility was controlled by the condition:
```swift
if block.type == .task && !isVerySmallBlock
```

Where `isVerySmallBlock = blockHeight < 35`. Since a 15-minute task has a height of exactly 15 points, it was considered "very small" and the resize handle was hidden.

## Solution

Changed the resize handle to **always** be visible for task blocks, regardless of size. For very small blocks, the handle is scaled down to fit:

```swift
if block.type == .task {
    // Always show resize handle for tasks
    Image(systemName: "line.3.horizontal")
        .font(.system(size: isVerySmallBlock ? 8 : 10))  // Smaller icon for small blocks
        .foregroundColor(.white.opacity(0.7))
        .padding(isVerySmallBlock ? 4 : 6)              // Less padding for small blocks
        .background(Color.clear)
```

### Changes Made
- **File:** `Features/Schedule/Views/TimelineView.swift`
- **Line:** ~218
- **Change:** Removed `&& !isVerySmallBlock` condition
- **Enhancement:** Added dynamic sizing based on block height

## Testing Results

### Before Fix
- ✅ 30-min task: Resize handle visible
- ✅ Resize down to 15 min: Handle disappears
- ❌ 15-min task: No way to resize larger

### After Fix
- ✅ 30-min task: Resize handle visible (10pt icon, 6pt padding)
- ✅ Resize down to 15 min: Handle scales smaller but remains visible
- ✅ 15-min task: Resize handle visible (8pt icon, 4pt padding) - can resize larger

## Impact

- **UX:** Resolved dead-end scenario where users couldn't expand 15-minute tasks
- **Visual:** Resize handle scales appropriately for small blocks
- **Functionality:** All resize operations now work bidirectionally
- **Accessibility:** Users can always access resize functionality

## Verification

Manual testing confirmed:
1. ✅ 15-minute tasks show visible (smaller) resize handle
2. ✅ Users can drag handle to expand 15-minute tasks
3. ✅ Handle scales smoothly during resize operations
4. ✅ No visual clutter on small blocks

---

**QA Sign-off:** Ready for re-testing
