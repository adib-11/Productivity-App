# Story 2.2: Free Time Identification - Manual Testing Checklist

**Date:** October 6, 2025  
**Story:** 2.2 - Free Time Identification Algorithm  
**Status:** Ready for Manual Testing ✅

---

## Prerequisites
- [x] All 112 automated tests passing (100%)
- [x] Build successful
- [ ] Simulator launched (iPhone 15 Pro or similar)
- [ ] User authenticated

---

## Test Scenario 1: Empty Schedule (No Commitments)

**Expected Behavior:** Should show ONE large "Available" block from 6 AM to midnight

### Steps:
1. Launch app in simulator (Cmd+R in Xcode)
2. Sign in or create test account
3. Navigate to Schedule view (Timeline view)
4. Ensure no commitments exist for today
5. Observe the timeline display

### Expected Results:
- [ ] ONE "Available" block displayed
- [ ] Block spans full work day: 6:00 AM - 12:00 AM (midnight)
- [ ] Block has GRAY background
- [ ] Block has DASHED border pattern
- [ ] Block shows "Available" as title
- [ ] Duration is 18 hours (6 AM to midnight)
- [ ] No solid blue commitment blocks visible

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 2: Single Commitment

**Expected Behavior:** Should show free time BEFORE and AFTER commitment with 15-minute gaps

### Steps:
1. Add a commitment: "Team Meeting" from 10:00 AM - 11:00 AM
2. Observe the timeline updates

### Expected Results:
- [ ] THREE blocks total displayed
- [ ] Block 1: "Available" 6:00 AM - 10:00 AM (gray, dashed)
- [ ] Block 2: "Team Meeting" 10:00 AM - 11:00 AM (blue, solid)
- [ ] Block 3: "Available" 11:15 AM - 12:00 AM (gray, dashed) — Note 15-min gap
- [ ] All blocks in chronological order
- [ ] No gaps or overlaps in timeline

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 3: Multiple Commitments

**Expected Behavior:** Free time slots between multiple commitments with proper gaps

### Steps:
1. Add commitments:
   - "Morning Standup" 9:00 AM - 9:30 AM
   - "Lunch" 12:00 PM - 1:00 PM
   - "Client Call" 3:00 PM - 4:00 PM
2. Observe timeline

### Expected Results:
- [ ] SEVEN blocks total (4 free + 3 commitments)
- [ ] "Available" 6:00 AM - 9:00 AM
- [ ] "Morning Standup" 9:00 AM - 9:30 AM
- [ ] "Available" 9:45 AM - 12:00 PM (15-min gap after standup)
- [ ] "Lunch" 12:00 PM - 1:00 PM
- [ ] "Available" 1:15 PM - 3:00 PM (15-min gap after lunch)
- [ ] "Client Call" 3:00 PM - 4:00 PM
- [ ] "Available" 4:15 PM - 12:00 AM (15-min gap after call)
- [ ] All gaps are 15 minutes
- [ ] Blocks sorted chronologically

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 4: Back-to-Back Commitments

**Expected Behavior:** Adjacent commitments are treated as one continuous block with no gap between them

### Steps:
1. Add commitments:
   - "Workshop Part 1" 10:00 AM - 11:00 AM
   - "Workshop Part 2" 11:00 AM - 12:00 PM
2. Observe timeline

### Expected Results:
- [ ] THREE blocks visible (not five!)
- [ ] "Available" 6:00 AM - 10:00 AM
- [ ] "Workshop Part 1" 10:00 AM - 11:00 AM
- [ ] "Workshop Part 2" 11:00 AM - 12:00 PM (shown at original time, no shift)
- [ ] "Available" 12:15 PM - 12:00 AM (15-minute gap AFTER the last commitment)
- [ ] NO "Available" block between the two workshops (they're back-to-back)
- [ ] Small blocks (15-30 min) show only title with smaller font, no time range

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 5: Visual Styling Verification

**Expected Behavior:** Empty blocks should have distinct visual appearance

### Steps:
1. Ensure at least one empty block is visible
2. Compare styling between commitment and empty blocks

### Expected Results:
- [ ] **Empty blocks:**
  - Gray background (light gray in light mode, dark gray in dark mode)
  - Dashed border [5, 3] pattern
  - No shadow/elevation
  - Text color: secondary label (gray text)
  - Title: "Available"
  
- [ ] **Commitment blocks:**
  - Blue background
  - Solid border
  - Has shadow
  - White text
  - Custom title

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 6: Dark Mode Support

**Expected Behavior:** Colors adapt properly in dark mode

### Steps:
1. Enable dark mode: Settings → Appearance → Dark
2. Observe timeline colors

### Expected Results:
- [ ] Empty blocks use semantic colors (adapt to dark mode)
- [ ] Text remains readable
- [ ] Contrast is sufficient
- [ ] Gray background darkens appropriately
- [ ] Border remains visible

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 7: Accessibility - VoiceOver

**Expected Behavior:** Screen reader announces block information correctly

### Steps:
1. Enable VoiceOver: Settings → Accessibility → VoiceOver → ON
2. Swipe through timeline blocks
3. Listen to announcements

### Expected Results:
- [ ] Empty blocks announced as: "Available. Duration: [X] hours [Y] minutes. From [start time] to [end time]"
- [ ] Commitment blocks announced with title and time range
- [ ] All blocks are focusable
- [ ] Navigation is logical (top to bottom)

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 8: Dynamic Type Support

**Expected Behavior:** Text scales with system font size preferences

### Steps:
1. Go to Settings → Display & Brightness → Text Size
2. Increase text size to largest
3. Check timeline layout

### Expected Results:
- [ ] Text scales up appropriately
- [ ] Layout doesn't break
- [ ] All text remains readable
- [ ] No text truncation issues

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 9: Edge Case - Full Day Commitment

**Expected Behavior:** No free time blocks when day is fully booked

### Steps:
1. Add commitment: "All Day Conference" 6:00 AM - 12:00 AM (midnight)
2. Observe timeline

### Expected Results:
- [ ] Only ONE block visible: the commitment
- [ ] NO "Available" blocks shown
- [ ] Timeline shows the full-day commitment

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 10: Edge Case - Very Short Free Time

**Expected Behavior:** Free time slots shorter than 15 minutes should be filtered out

### Steps:
1. Add commitments very close together:
   - "Meeting A" 10:00 AM - 10:45 AM
   - "Meeting B" 10:50 AM - 11:30 AM
   (Only 5 minutes apart - less than minimum 15 min)
2. Observe timeline

### Expected Results:
- [ ] NO "Available" block between Meeting A and Meeting B
- [ ] The 5-minute gap is ignored (too short)
- [ ] Free time before and after shows normally

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 11: Performance Check

**Expected Behavior:** Timeline updates smoothly when adding/removing commitments

### Steps:
1. Add multiple commitments rapidly
2. Delete commitments
3. Observe UI responsiveness

### Expected Results:
- [ ] Timeline updates within 1 second
- [ ] No visible lag or freezing
- [ ] Smooth animations (if any)
- [ ] No flickering or layout jumps

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Test Scenario 12: Data Persistence

**Expected Behavior:** Free time calculation persists across app restarts

### Steps:
1. Add commitments and verify free time displays correctly
2. Force quit app (swipe up in app switcher)
3. Reopen app
4. Navigate back to schedule view

### Expected Results:
- [ ] Commitments still visible
- [ ] Free time blocks recalculated correctly
- [ ] Timeline looks identical to before restart

### Actual Results:
```
[Document what you see here]
```

**Status:** [ ] Pass / [ ] Fail  
**Notes:**

---

## Summary

**Total Tests:** 12  
**Passed:** [ ] / 12  
**Failed:** [ ] / 12  
**Blocked:** [ ] / 12

### Critical Issues Found:
```
[List any critical bugs that block release]
```

### Minor Issues Found:
```
[List any minor issues or improvements]
```

### Overall Assessment:
- [ ] **PASS** - Story 2.2 is ready for production
- [ ] **FAIL** - Critical issues must be fixed before release
- [ ] **CONDITIONAL PASS** - Minor issues can be addressed in follow-up

---

## Next Steps

1. [ ] Address any critical issues found
2. [ ] File tickets for minor improvements
3. [ ] Update Story 2.2 status to "Complete" or "Needs Fixes"
4. [ ] Mark all story tasks as complete
5. [ ] Update Story 2.2 file with test results

---

**Tested By:** [Your Name]  
**Date:** October 6, 2025  
**Simulator:** iPhone 15 Pro, iOS 17.0  
**Build:** [Build number from Xcode]
