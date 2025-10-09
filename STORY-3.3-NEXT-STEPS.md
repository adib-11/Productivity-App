# Story 3.3: Task Suggestion Engine - What You Need to Do Next

## 🎯 Current Status
**Implementation: 78% Complete (Tasks 1-11 of 14)**
**Your Action Required: Add files to Xcode and complete manual testing**

---

## ⚡ Quick Start (5 Steps)

### Step 1: Add Files to Xcode Project
Open `ADD_FILES_TO_XCODE_3.3.md` and follow the instructions to add these files:

**Source Files (4):**
- Core/Models/SuggestedTask.swift
- Core/Services/TaskSuggestionEngine.swift
- Features/Schedule/ViewModels/TaskSuggestionViewModel.swift
- Features/Schedule/Views/TaskSuggestionView.swift

**Test Files (2):**
- iOS-Productivity-AppTests/TaskSuggestionEngineTests.swift
- iOS-Productivity-AppTests/TaskSuggestionViewModelTests.swift

### Step 2: Build the Project
```bash
# In Xcode, press Cmd+B or:
Product > Build
```
Verify: Zero compilation errors

### Step 3: Run Tests
```bash
# In Xcode, press Cmd+U or:
Product > Test
```
Expected Results:
- ✅ TaskSuggestionEngineTests: 10 tests pass
- ✅ TaskSuggestionViewModelTests: 6 tests pass
- ⏭️ DataRepositoryTests (3 new): Skip if no emulator (expected)

### Step 4: Manual Testing
Run the app in simulator and test the suggestion flow:

1. Create test data:
   - 5+ flexible tasks with mixed energy levels (high, low, any)
   - 2+ must-do tasks
   - Mix of priority levels (1-5)

2. Schedule 2 flexible tasks on today's timeline

3. Test the flow:
   - Tap mood selector FAB button
   - Select "⚡️ High Energy"
   - Verify suggestion sheet appears
   - Check only flexible, unscheduled, incomplete tasks shown
   - Check only "high" or "any" energy tasks appear
   - Verify match reasons displayed
   - Test close button

4. Repeat for "🔋 Medium" and "😴 Low" energy

5. Edge cases:
   - No flexible tasks → See friendly "no match" message
   - All tasks scheduled → See "no match" message
   - Only 1 match → See 1 suggestion
   - 10+ matches → See top 3 only

### Step 5: Mark Complete
If all tests pass and manual testing successful:
- ✅ Update story status to "Ready for Review"
- ✅ Push changes to GitHub
- ✅ Notify QA team

---

## 📁 Files Created (All Ready in Filesystem)

| File | Location | Status |
|------|----------|--------|
| SuggestedTask.swift | Core/Models/ | ✅ Created |
| TaskSuggestionEngine.swift | Core/Services/ | ✅ Created |
| TaskSuggestionViewModel.swift | Features/Schedule/ViewModels/ | ✅ Created |
| TaskSuggestionView.swift | Features/Schedule/Views/ | ✅ Created |
| TaskSuggestionEngineTests.swift | iOS-Productivity-AppTests/ | ✅ Created |
| TaskSuggestionViewModelTests.swift | iOS-Productivity-AppTests/ | ✅ Created |
| DataRepository.swift | Core/Services/ | ✅ Modified |
| TimelineView.swift | Features/Schedule/Views/ | ✅ Modified |
| TestMocks.swift | iOS-Productivity-AppTests/ | ✅ Modified |
| DataRepositoryTests.swift | iOS-Productivity-AppTests/ | ✅ Modified |

---

## 🧪 What Gets Tested

### Automated Tests (19 total):
**TaskSuggestionEngine (10 tests):**
- ✅ High energy filtering
- ✅ Medium energy filtering
- ✅ Low energy filtering
- ✅ Must-do tasks excluded
- ✅ Scheduled tasks excluded
- ✅ Completed tasks excluded
- ✅ Top 3 limit
- ✅ Score calculation
- ✅ Empty results
- ✅ Age bonus

**TaskSuggestionViewModel (6 tests):**
- ✅ Suggestions populated
- ✅ No match message
- ✅ Error handling
- ✅ Loading state
- ✅ Task IDs passed
- ✅ Multiple suggestions

**DataRepository (3 tests):**
- ✅ Flexible task filtering
- ✅ Completed tasks excluded
- ✅ Authentication required

### Manual Tests:
- End-to-end suggestion flow
- All 3 energy levels
- Edge cases (no tasks, all scheduled, etc.)
- UI/UX quality
- Accessibility

---

## 💡 What This Feature Does

**User Perspective:**
1. User taps mood FAB button in schedule view
2. Selects current energy level (⚡️ High, 🔋 Medium, 😴 Low)
3. App shows 1-3 smart task suggestions matching their energy
4. Each suggestion shows match quality, duration, priority
5. User can add suggested task to schedule (Story 3.4)

**Technical Perspective:**
- Filters flexible, incomplete, unscheduled tasks from Firestore
- Matches task energy level to user's current mood
- Scores tasks based on: energy match, priority level, age
- Returns top 3 suggestions to reduce decision fatigue
- Beautiful UI with match quality indicators

---

## �� Important Notes

1. **"Add to Schedule" Button:** Currently disabled - will be enabled in Story 3.4
2. **Firestore Index:** May need to create compound index on (priority, isCompleted) in Firebase Console
3. **Regression Testing:** Ensure all previous features still work (Epic 1, 2, 3.1, 3.2)
4. **Test Data:** Create diverse flexible tasks for realistic testing

---

## 📚 Documentation References

| Document | Purpose |
|----------|---------|
| ADD_FILES_TO_XCODE_3.3.md | Step-by-step Xcode instructions |
| STORY-3.3-IMPLEMENTATION-STATUS.md | Detailed technical summary |
| STORY-3.3-NEXT-STEPS.md | This file - quick guide |

---

## ❓ Troubleshooting

**Build Errors:**
- Check all files added to correct targets
- Verify modified files reflect changes
- Clean build folder (Cmd+Shift+K)

**Tests Failing:**
- Check MockTaskSuggestionEngine in TestMocks.swift
- Verify test targets set correctly
- Check for typos in test names

**UI Not Showing:**
- Verify TimelineView integration
- Check selectedMoodEnergyLevel binding
- Ensure repository passed correctly

**No Suggestions Appearing:**
- Check Firestore has flexible tasks
- Verify tasks not all completed/scheduled
- Check energy levels match mood

---

## 🎉 Success Criteria

You're done when:
- ✅ All 19 tests pass (or skip gracefully)
- ✅ Zero build warnings
- ✅ Mood selector triggers suggestion sheet
- ✅ Suggestions show correct filtered tasks
- ✅ Match quality indicators display
- ✅ Empty state shows when no matches
- ✅ Close button dismisses sheet
- ✅ All edge cases handled gracefully

---

**Need Help?** Check STORY-3.3-IMPLEMENTATION-STATUS.md for detailed technical info.

**Ready for Story 3.4?** Once this is marked "Ready for Review" and passes QA, you can proceed to implement "Add Suggested Task to Schedule" functionality!
