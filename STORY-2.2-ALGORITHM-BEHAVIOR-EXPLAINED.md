# Story 2.2: Algorithm Behavior - Important Clarifications

## 🎯 How the Free Time Algorithm Works

### Core Principle
The algorithm identifies **AVAILABLE time for scheduling tasks**, not a strict scheduling engine that moves commitments around.

---

## 📋 Key Behaviors

### 1. Commitments Are Displayed at Their Actual Times
**Commitments are NOT shifted or moved.** They appear at the exact times they were scheduled.

Example:
- Meeting at 10:00 AM - 11:00 AM → Shows at 10:00 AM - 11:00 AM
- Even if there's a 15-min gap requirement, the meeting stays at its original time

### 2. The 15-Minute Gap is Buffer Time AFTER Commitments
The `minimumGapBetweenEvents` creates buffer time **AFTER each commitment ends** before free time begins.

**Purpose:** Transition time, travel time, bio breaks, context switching

Example:
```
10:00 AM - 11:00 AM: Team Meeting (commitment)
11:00 AM - 11:15 AM: [BUFFER TIME - not shown]
11:15 AM - 12:00 PM: "Available" (free time slot)
```

### 3. Back-to-Back Commitments (Adjacent Times)
When commitments are scheduled back-to-back with **no gap between them**, they are displayed as-is.

**No free time block appears between them** because there's no room.

Example:
```
10:00 AM - 11:00 AM: Workshop Part 1
11:00 AM - 12:00 PM: Workshop Part 2
[No "Available" block between them]
12:15 PM - onwards: "Available" (buffer after Part 2)
```

**Timeline Display:**
- Workshop Part 1 at 10:00-11:00
- Workshop Part 2 at 11:00-12:00 (directly adjacent)
- Available 12:15-midnight (15-min buffer after Part 2)

### 4. Overlapping Commitments
If commitments overlap (e.g., 10-12 PM and 11-1 PM), they are **merged into one continuous block** before calculating free time.

**Merged Example:**
```
Before merge:
- Meeting A: 10:00 AM - 12:00 PM
- Meeting B: 11:00 AM - 1:00 PM

After merge:
- [Merged Block]: 10:00 AM - 1:00 PM

Free time:
- Available: 1:15 PM onwards (15-min buffer after merged end)
```

### 5. Minimum Slot Duration (15 minutes)
Free time slots **shorter than 15 minutes are filtered out** as they're too small for meaningful task scheduling.

Example:
```
Meeting A: 10:00 AM - 10:45 AM
Meeting B: 10:50 AM - 11:30 AM

Gap = 5 minutes (10:45-10:50)
After 15-min buffer = -10 minutes (not viable)

Result: NO "Available" block shown between them
```

---

## 🎨 Visual Display Improvements (Just Fixed!)

### Small Block Handling
For blocks **less than 40px height** (~15-20 minute duration):
- ✅ Smaller font size (11pt instead of 15pt)
- ✅ Shows ONLY title (no time range)
- ✅ Reduced padding (4px instead of 8px)
- ✅ Text scales down to 70% if needed (`.minimumScaleFactor(0.7)`)
- ✅ Single line only (`.lineLimit(1)`)

This prevents text truncation and makes small blocks readable!

---

## 📊 Test Scenario Corrections

### ❌ INCORRECT Expectation (Old Test):
"Back-to-back commitments should create a gap between them and shift the second one"

### ✅ CORRECT Expectation (Updated Test):
"Back-to-back commitments are displayed at their original times with NO gap between them. The 15-minute buffer appears AFTER the last commitment."

---

## 🤔 Why This Design?

### Use Case: Realistic Scheduling
Users schedule commitments at specific times (meetings, appointments, etc.). The app should:
1. **Display commitments at their actual times** (not move them)
2. **Show when you're FREE to schedule tasks** (between/after commitments)
3. **Account for buffer time** (15 min for transitions)

### Analogy: Calendar + Task Scheduler
- **Commitments** = Fixed appointments (like Google Calendar)
- **Free Time Slots** = When you can add tasks (like a to-do app)
- **Buffer Time** = Realistic transition period

---

## 🧪 Testing Implications

When testing, verify:
1. ✅ Commitments appear at their scheduled times
2. ✅ Free time starts 15 minutes AFTER commitment ends
3. ✅ Adjacent commitments don't have "Available" blocks between them
4. ✅ Small blocks display cleanly without text truncation
5. ✅ Overlapping commitments are merged
6. ✅ Gaps < 15 minutes are filtered out

---

## 💡 Future Enhancements (Not in Story 2.2)

Possible future features:
- Configurable gap duration per commitment type
- Smart scheduling that suggests optimal task placement
- Conflict detection for overlapping commitments
- Auto-adjustment when commitments change

**For now:** The algorithm provides a solid foundation for identifying available time windows! ✨

---

**Updated:** October 6, 2025  
**Story:** 2.2 - Free Time Identification Algorithm
