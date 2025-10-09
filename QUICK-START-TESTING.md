# Quick Start: Testing Story 2.5

## Step-by-Step: Fix "Cannot test on Any iOS Device" Error

### 🔴 The Problem
You see this error: **"Cannot test target 'iOS-Productivity-AppTests' on 'Any iOS Device': Tests must be run on a concrete device"**

### ✅ The Solution (3 Easy Steps)

#### Step 1: Select a Simulator Device
At the top of Xcode window, you'll see a dropdown that says **"Any iOS Device"**

**Click it and select:**
- iPhone 15 Pro ⭐ (Recommended)
- iPhone 15
- iPhone 14 Pro
- Or any other iOS Simulator

#### Step 2: Run Tests
Press: **`Cmd + U`** (Command + U)

Or:
- Menu Bar → **Product** → **Test**
- Test Navigator (Cmd + 6) → Click ▶️ play button

#### Step 3: Wait for Results
- Tests will compile and run (takes 30-60 seconds)
- Look for green checkmarks ✅ in Test Navigator
- All 8 new tests should pass!

---

## What Tests Were Added for Story 2.5?

### ScheduleViewModelTests (7 new tests)
1. ✅ **testMarkScheduledTaskComplete_UpdatesTask**
   - Verifies task.isCompleted set to true

2. ✅ **testMarkScheduledTaskComplete_DeletesScheduledTask**
   - Verifies scheduled task removed from Firestore

3. ✅ **testMarkScheduledTaskComplete_ShowsRewardMessage**
   - Verifies success message displayed

4. ✅ **testMarkScheduledTaskComplete_RegeneratesTimeBlocks**
   - Verifies timeline refreshed

5. ✅ **testMarkScheduledTaskComplete_CreatesNewFreeTime**
   - Verifies free time expands

6. ✅ **testMarkScheduledTaskComplete_HandlesError**
   - Verifies error handling

7. ✅ **testGenerateRewardMessage_ReturnsValidString**
   - Verifies reward messages work

### DataRepositoryTests (1 new test)
8. ✅ **testUpdateTask_CompletionStatus**
   - Verifies completion field persists in Firestore

---

## After Tests Pass ✅

### Next: Manual Testing (Tasks 13-18)

**Build and Run the App:**
1. Press **`Cmd + R`** (Command + R)
2. App launches in simulator

**Test Task Completion Flow:**
1. Navigate to Schedule/Today View
2. Add a commitment (e.g., "Meeting" 9-10 AM)
3. Add 2-3 tasks in Task Inbox
4. Tap **"Auto-Schedule"** button (sparkles icon)
5. **Tap on a green task block**
6. Action sheet appears → Tap **"Mark Complete"**
7. Watch for:
   - ✅ Success message appears (green, with emoji)
   - ✅ Message auto-dismisses after 2 seconds
   - ✅ Task disappears from timeline
   - ✅ Free time appears where task was

**Expected Behavior:**
- Quick tap → Shows action sheet ✅
- Long drag → Moves task (no action sheet) ✅
- Success message randomized ✅
- Timeline refreshes instantly ✅

---

## Troubleshooting

### Problem: "Build Failed"
**Solution:**
1. Clean Build: `Cmd + Shift + K`
2. Rebuild: `Cmd + B`
3. Try again: `Cmd + U`

### Problem: Simulator Won't Launch
**Solution:**
1. Close all simulator windows
2. In Xcode: **Window** → **Devices and Simulators**
3. Select iPhone 15 Pro
4. Click ▶️ play button to boot it
5. Wait for it to fully load
6. Run tests again: `Cmd + U`

### Problem: Tests Failing
**Solution:**
1. Open Test Navigator: `Cmd + 6`
2. Click on failed test to see error details
3. Check error message in console (bottom panel)
4. Review test code if needed

---

## Summary

✅ **8 new tests added for Story 2.5**  
✅ **Zero compilation errors**  
✅ **All unit tests should pass**  

🎯 **Next:** Manual testing in simulator (Tasks 13-18)

📄 **See also:**
- `RUN-TESTS-INSTRUCTIONS.md` - Detailed testing guide
- `STORY-2.5-IMPLEMENTATION-STATUS.md` - Complete implementation summary
- Story file: `docs/stories/2.5.story.md` - Full requirements
