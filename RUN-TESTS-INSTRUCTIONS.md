# How to Run Tests in Xcode

## The Error You're Seeing

The alert "Cannot test target 'iOS-Productivity-AppTests' on 'Any iOS Device'" means you need to select a specific simulator device.

## Solution: Run Tests in Xcode Properly

### Method 1: Using Xcode GUI (Recommended)

1. **Open the project in Xcode:**
   - The project should already be open
   - Or: `open iOS-Productivity-App.xcodeproj`

2. **Select a Simulator Device:**
   - At the top of Xcode, click the device dropdown (currently shows "Any iOS Device")
   - Select a specific simulator like:
     - iPhone 15 Pro
     - iPhone 15
     - iPhone 14 Pro
     - Any other iOS simulator

3. **Run All Tests:**
   - Press `Cmd + U` (Command + U)
   - Or: Menu → Product → Test
   - Or: Click and hold the Play button → "Test"

4. **Run Specific Test File:**
   - Open the test file (e.g., `ScheduleViewModelTests.swift`)
   - Click the diamond icon next to the test class or specific test method
   - Or: Right-click in the file → "Run Tests"

### Method 2: Using Test Navigator

1. **Open Test Navigator:**
   - Press `Cmd + 6` (Command + 6)
   - Or: Click the diamond icon in the left sidebar

2. **You'll see test groups:**
   - iOS-Productivity-AppTests
     - ScheduleViewModelTests (7 new tests for Story 2.5)
     - DataRepositoryTests (1 new test for Story 2.5)
     - TaskViewModelTests
     - CommitmentViewModelTests
     - AuthViewModelTests
     - SchedulingEngineTests

3. **Run tests:**
   - Hover over any test and click the ▶️ play icon
   - Or: Right-click → "Run"

### Expected Test Results for Story 2.5

**New Tests (Should All Pass):**
1. ✅ `testMarkScheduledTaskComplete_UpdatesTask`
2. ✅ `testMarkScheduledTaskComplete_DeletesScheduledTask`
3. ✅ `testMarkScheduledTaskComplete_ShowsRewardMessage`
4. ✅ `testMarkScheduledTaskComplete_RegeneratesTimeBlocks`
5. ✅ `testMarkScheduledTaskComplete_CreatesNewFreeTime`
6. ✅ `testMarkScheduledTaskComplete_HandlesError`
7. ✅ `testGenerateRewardMessage_ReturnsValidString`
8. ✅ `testUpdateTask_CompletionStatus` (DataRepositoryTests)

**Note:** Some DataRepository tests may be skipped if Firebase Emulator is not running - this is expected and normal.

### What to Look For

- **Green checkmarks ✅** = Tests passed
- **Red X ❌** = Tests failed (should not happen)
- **Gray dash ➖** = Tests skipped (normal for emulator tests)

### Troubleshooting

**If tests fail:**
1. Check the failure message in the test navigator
2. Click on the failed test to see details
3. Review the error log at the bottom of Xcode

**If you get build errors:**
1. Clean build folder: `Cmd + Shift + K`
2. Rebuild: `Cmd + B`
3. Try tests again: `Cmd + U`

**If simulator won't launch:**
1. Close all simulators
2. In Xcode: Window → Devices and Simulators
3. Select a simulator and click the play button
4. Wait for it to boot fully
5. Run tests again

## Quick Test Checklist

- [ ] Select a specific simulator device (not "Any iOS Device")
- [ ] Press Cmd + U to run all tests
- [ ] Verify 8 new tests pass for Story 2.5
- [ ] Check test results in Test Navigator (Cmd + 6)
- [ ] Note: Some DataRepository tests may skip (requires Firebase Emulator)

## After Tests Pass

Proceed to **Manual Testing** (Tasks 13-18):
1. Build and run app (Cmd + R)
2. Test task completion flow (tap task, mark complete, see reward message)
3. Test gesture disambiguation (tap vs drag)
4. Complete remaining manual test scenarios

See `STORY-2.5-IMPLEMENTATION-STATUS.md` for detailed manual testing instructions.
