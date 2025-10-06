# Fix Multiple Simulators Issue in Xcode

## Problem
Xcode is launching multiple simulator instances when running tests, causing system freeze.

## Solution

### Option 1: Run Tests on Single Device (Recommended)
1. **Open Xcode**
2. **Select target device:**
   - Click device dropdown in toolbar (top left)
   - Choose **ONE** specific simulator (e.g., "iPhone 15")
   - Avoid "Any iOS Device (arm64)" or multiple device options

3. **Run tests:**
   - Product → Test (Cmd+U)
   - Tests will run on ONLY the selected simulator

### Option 2: Disable Parallel Testing
1. **Edit Scheme:**
   - Product → Scheme → Edit Scheme... (or Cmd+<)
   - Select "Test" in left sidebar
   - Click "Options" tab
   - **UNCHECK** "Execute in parallel" or "Execute in parallel on Simulator"
   - Click "Close"

2. **Run tests:**
   - Product → Test (Cmd+U)
   - Tests will run sequentially on one simulator

### Option 3: Run Tests from Command Line
```bash
cd /Users/adib/Desktop/Code/iOS-Productivity-App

# Run on specific simulator (no parallel execution)
xcodebuild test \
  -project iOS-Productivity-App.xcodeproj \
  -scheme iOS-Productivity-App \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -only-testing:iOS-Productivity-AppTests/SchedulingEngineTests \
  -only-testing:iOS-Productivity-AppTests/ScheduleViewModelTests
```

### Option 4: Quit Existing Simulators First
```bash
# Kill all running simulators before testing
killall Simulator

# Then run tests in Xcode
```

## Recommended Workflow

1. **Kill all simulators:** `killall Simulator`
2. **Open Xcode**
3. **Select ONE device** (e.g., iPhone 15)
4. **Disable parallel testing** (Edit Scheme → Test → Options)
5. **Run tests** (Cmd+U)

This will prevent multiple simulators from launching.

## Quick Fix Now

Run this command to kill all simulators:
```bash
killall Simulator
```

Then in Xcode:
- Edit Scheme (Cmd+<)
- Test → Options → Uncheck "Execute in parallel"
- Run tests again
