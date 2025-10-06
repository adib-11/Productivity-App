# Adding New Files to Xcode Project

## Files That Need to Be Added to Xcode

The following files were created but need to be manually added to the Xcode project:

### Source Files (4 files):
1. **TimeBlock.swift**
   - Path: `iOS-Productivity-App/Core/Models/TimeBlock.swift`
   - Target: iOS-Productivity-App
   - Group: Core/Models

2. **ScheduleViewModel.swift**
   - Path: `iOS-Productivity-App/Features/Schedule/ViewModels/ScheduleViewModel.swift`
   - Target: iOS-Productivity-App
   - Group: Features/Schedule/ViewModels

3. **TimelineView.swift**
   - Path: `iOS-Productivity-App/Features/Schedule/Views/TimelineView.swift`
   - Target: iOS-Productivity-App
   - Group: Features/Schedule/Views

### Test Files (1 file):
4. **ScheduleViewModelTests.swift**
   - Path: `iOS-Productivity-AppTests/ScheduleViewModelTests.swift`
   - Target: iOS-Productivity-AppTests
   - Group: iOS-Productivity-AppTests

## Step-by-Step Instructions

### Method 1: Drag and Drop (Recommended)

1. **Open Xcode** with the project already open
2. **Show Project Navigator** (Cmd+1)
3. **Add TimeBlock.swift:**
   - Locate the file in Finder: `iOS-Productivity-App/Core/Models/TimeBlock.swift`
   - Drag it into the "Core/Models" folder in Xcode's Project Navigator
   - In the dialog that appears:
     - ✅ Check "Copy items if needed" (if it's not already in the right location)
     - ✅ Check "Add to targets: iOS-Productivity-App"
     - Click "Finish"

4. **Add ScheduleViewModel.swift:**
   - Locate: `iOS-Productivity-App/Features/Schedule/ViewModels/ScheduleViewModel.swift`
   - Drag into "Features/Schedule/ViewModels" folder
   - ✅ Add to target: iOS-Productivity-App

5. **Add TimelineView.swift:**
   - Locate: `iOS-Productivity-App/Features/Schedule/Views/TimelineView.swift`
   - Drag into "Features/Schedule/Views" folder
   - ✅ Add to target: iOS-Productivity-App

6. **Add ScheduleViewModelTests.swift:**
   - Locate: `iOS-Productivity-AppTests/ScheduleViewModelTests.swift`
   - Drag into "iOS-Productivity-AppTests" folder
   - ✅ Add to target: iOS-Productivity-AppTests

### Method 2: Right-Click Add Files

1. Right-click on the appropriate group in Project Navigator
2. Select "Add Files to 'iOS-Productivity-App'..."
3. Navigate to the file location
4. Select the file
5. Ensure correct target is checked
6. Click "Add"

## Verification

After adding the files:

1. **Build the project** (Cmd+B)
   - Should complete with no errors
   
2. **Check file targets:**
   - Select each file in Project Navigator
   - In File Inspector (right panel), verify "Target Membership" is correct
   
3. **Run tests** (Cmd+U)
   - All tests should run successfully

## Current Build Errors

The errors you're seeing are because Xcode can't find the types:
- `ScheduleViewModel` - needs ScheduleViewModel.swift added
- `TimelineView` - needs TimelineView.swift added
- These files reference `TimeBlock` - needs TimeBlock.swift added

Once all files are added to the Xcode project, the build errors will be resolved.

## Quick Command to Verify Files Exist

Run this in terminal to confirm all files are present:
```bash
ls -la iOS-Productivity-App/Core/Models/TimeBlock.swift
ls -la iOS-Productivity-App/Features/Schedule/ViewModels/ScheduleViewModel.swift
ls -la iOS-Productivity-App/Features/Schedule/Views/TimelineView.swift
ls -la iOS-Productivity-AppTests/ScheduleViewModelTests.swift
```

All should show file details if created successfully.
