# CRITICAL: Add New Files to Xcode Project - Story 2.2

## ⚠️ Before Running Tests or Building

The following files were created but need to be added to the Xcode project:

### NEW SOURCE FILES (Add to iOS-Productivity-App target)

1. **FreeTimeSlot.swift**
   - Path: `iOS-Productivity-App/Core/Models/FreeTimeSlot.swift`
   - Target: ✅ iOS-Productivity-App

2. **SchedulingConfiguration.swift**
   - Path: `iOS-Productivity-App/Core/Models/SchedulingConfiguration.swift`
   - Target: ✅ iOS-Productivity-App

3. **SchedulingEngine.swift**
   - Path: `iOS-Productivity-App/Core/Services/SchedulingEngine.swift`
   - Target: ✅ iOS-Productivity-App

### NEW TEST FILES (Add to iOS-Productivity-AppTests target)

4. **SchedulingEngineTests.swift**
   - Path: `iOS-Productivity-AppTests/SchedulingEngineTests.swift`
   - Target: ✅ iOS-Productivity-AppTests

---

## �� HOW TO ADD FILES IN XCODE

### Method 1: Drag & Drop (Recommended)
1. Open Xcode project
2. In Finder, navigate to the file location
3. Drag file into appropriate folder in Xcode Project Navigator
4. In dialog that appears:
   - ✅ Ensure correct target is checked
   - ❌ UNCHECK "Copy items if needed" (file already in place)
   - Click "Finish"

### Method 2: Add Files Menu
1. Open Xcode project
2. Right-click on folder (e.g., Core/Models)
3. Select "Add Files to 'iOS-Productivity-App'..."
4. Navigate to file location
5. Select file
6. In dialog:
   - ✅ Ensure correct target is checked
   - ❌ UNCHECK "Copy items if needed"
   - Click "Add"

---

## ✅ VERIFICATION CHECKLIST

After adding files, verify:

1. **Files appear in Project Navigator** with no red icons
2. **Build project** (Cmd+B) → Should succeed with 0 errors
3. **Run tests** (Cmd+U) → All tests should pass
4. **Check file membership:**
   - Select file in Project Navigator
   - View File Inspector (right panel)
   - Verify correct target is checked under "Target Membership"

---

## 🔍 TROUBLESHOOTING

**If build fails with "No such module" error:**
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Rebuild: Product → Build (Cmd+B)

**If tests don't appear:**
- Ensure SchedulingEngineTests.swift has iOS-Productivity-AppTests target checked
- Product → Test (Cmd+U) to force test discovery

**If files show in red:**
- File is missing or in wrong location
- Right-click file → Show in Finder
- Verify path matches expected location
- Remove reference and re-add file

---

## 🎯 NEXT STEPS AFTER ADDING FILES

1. ✅ Build project (Cmd+B)
2. ✅ Run all tests (Cmd+U) - expect 16+ tests to pass
3. ✅ Run app in simulator (Cmd+R)
4. ✅ Navigate to Today tab
5. ✅ Verify empty blocks appear with gray dashed borders
6. ✅ Test dark mode
7. ✅ Test VoiceOver accessibility

**See STORY-2.2-IMPLEMENTATION-STATUS.md for full testing guide**
