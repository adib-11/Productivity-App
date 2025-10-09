# Instructions: Add Story 3.3 Files to Xcode Project

## Files Created for Story 3.3

The following files have been created and need to be added to the Xcode project:

### New Files:
1. **Core/Models/SuggestedTask.swift**
2. **Core/Services/TaskSuggestionEngine.swift**
3. **Features/Schedule/ViewModels/TaskSuggestionViewModel.swift**
4. **Features/Schedule/Views/TaskSuggestionView.swift**

### New Test Files:
1. **iOS-Productivity-AppTests/TaskSuggestionEngineTests.swift**
2. **iOS-Productivity-AppTests/TaskSuggestionViewModelTests.swift**

### Modified Files:
1. **Core/Services/DataRepository.swift** - Added `getFlexibleTasks()` method
2. **Features/Schedule/Views/TimelineView.swift** - Added suggestion flow integration
3. **iOS-Productivity-AppTests/TestMocks.swift** - Added mock methods for testing
4. **iOS-Productivity-AppTests/DataRepositoryTests.swift** - Added flexible task query tests

## Steps to Add Files in Xcode:

1. **Open the Xcode project:**
   - Open `iOS-Productivity-App.xcodeproj` in Xcode

2. **Add SuggestedTask.swift:**
   - Right-click on `Core/Models/` in the Project Navigator
   - Select "Add Files to 'iOS-Productivity-App'..."
   - Navigate to and select `iOS-Productivity-App/Core/Models/SuggestedTask.swift`
   - Ensure "Copy items if needed" is UNCHECKED (file is already in correct location)
   - Ensure target "iOS-Productivity-App" is CHECKED
   - Click "Add"

3. **Add TaskSuggestionEngine.swift:**
   - Right-click on `Core/Services/` in the Project Navigator
   - Select "Add Files to 'iOS-Productivity-App'..."
   - Navigate to and select `iOS-Productivity-App/Core/Services/TaskSuggestionEngine.swift`
   - Ensure "Copy items if needed" is UNCHECKED
   - Ensure target "iOS-Productivity-App" is CHECKED
   - Click "Add"

4. **Add TaskSuggestionViewModel.swift:**
   - Right-click on `Features/Schedule/ViewModels/` in the Project Navigator
   - Select "Add Files to 'iOS-Productivity-App'..."
   - Navigate to and select `iOS-Productivity-App/Features/Schedule/ViewModels/TaskSuggestionViewModel.swift`
   - Ensure "Copy items if needed" is UNCHECKED
   - Ensure target "iOS-Productivity-App" is CHECKED
   - Click "Add"

5. **Add TaskSuggestionView.swift:**
   - Right-click on `Features/Schedule/Views/` in the Project Navigator
   - Select "Add Files to 'iOS-Productivity-App'..."
   - Navigate to and select `iOS-Productivity-App/Features/Schedule/Views/TaskSuggestionView.swift`
   - Ensure "Copy items if needed" is UNCHECKED
   - Ensure target "iOS-Productivity-App" is CHECKED
   - Click "Add"

6. **Add TaskSuggestionEngineTests.swift:**
   - Right-click on `iOS-Productivity-AppTests/` in the Project Navigator
   - Select "Add Files to 'iOS-Productivity-App'..."
   - Navigate to and select `iOS-Productivity-AppTests/TaskSuggestionEngineTests.swift`
   - Ensure "Copy items if needed" is UNCHECKED
   - Ensure target "iOS-Productivity-AppTests" is CHECKED (NOT the main app target)
   - Click "Add"

7. **Add TaskSuggestionViewModelTests.swift:**
   - Right-click on `iOS-Productivity-AppTests/` in the Project Navigator
   - Select "Add Files to 'iOS-Productivity-App'..."
   - Navigate to and select `iOS-Productivity-AppTests/TaskSuggestionViewModelTests.swift`
   - Ensure "Copy items if needed" is UNCHECKED
   - Ensure target "iOS-Productivity-AppTests" is CHECKED (NOT the main app target)
   - Click "Add"

8. **Build the project:**
   - Press Cmd+B to build
   - Verify there are no compilation errors
   - Modified files (DataRepository.swift, TimelineView.swift, TestMocks.swift, DataRepositoryTests.swift) should automatically reflect changes

## Verification:

After adding all files, verify in Project Navigator that:
- All source files appear in their correct folder locations
- All test files appear in the iOS-Productivity-AppTests folder
- All source files have the iOS-Productivity-App target checkbox checked
- All test files have the iOS-Productivity-AppTests target checkbox checked
- No red file names (indicating missing files)
- Build succeeds with Cmd+B

## Running Tests:

1. **Run unit tests:**
   - Press Cmd+U to run all tests
   - Or select Product > Test from the menu
   - Verify TaskSuggestionEngineTests pass (10 tests)
   - Verify TaskSuggestionViewModelTests pass (6 tests)
   - Verify DataRepositoryTests flexible task tests (3 tests - will skip if emulator not running)

2. **Check test results:**
   - Open Test Navigator (Cmd+6)
   - Expand test classes to see individual test results
   - All tests should pass or skip gracefully

## Next Steps:

Once files are added and project builds successfully:
- Run unit tests (Tasks 9-11)
- Perform manual testing (Tasks 12-13)
- Complete code review and cleanup (Task 14)

