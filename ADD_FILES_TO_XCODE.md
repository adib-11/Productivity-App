# How to Add New Files to Xcode Project

The implementation created new Swift files that need to be added to your Xcode project.

## Steps to Add Files:

### 1. Open Your Project in Xcode
- Open `iOS-Productivity-App.xcodeproj` in Xcode

### 2. Add Files to Project

For each file location below:
1. Right-click the folder in Xcode's Project Navigator
2. Select "Add Files to 'iOS-Productivity-App'..."
3. Navigate to the file location
4. Select the file(s)
5. Make sure "Copy items if needed" is UNCHECKED (files are already in place)
6. Make sure "Add to targets: iOS-Productivity-App" is CHECKED
7. Click "Add"

### Files to Add:

#### Core/Models/ folder:
- `FixedCommitment.swift`
  - Location: `iOS-Productivity-App/Core/Models/FixedCommitment.swift`

#### Core/Services/ folder:
- `DataRepository.swift`
  - Location: `iOS-Productivity-App/Core/Services/DataRepository.swift`

#### Features/Schedule/ folder:
You may need to create "Schedule" group first:
1. Right-click "Features" folder
2. Select "New Group"
3. Name it "Schedule"
4. Create "ViewModels" and "Views" subgroups

Then add:
- **ViewModels subfolder:**
  - `CommitmentViewModel.swift`
    - Location: `iOS-Productivity-App/Features/Schedule/ViewModels/CommitmentViewModel.swift`

- **Views subfolder:**
  - `ManageCommitmentsView.swift`
    - Location: `iOS-Productivity-App/Features/Schedule/Views/ManageCommitmentsView.swift`
  - `CommitmentFormView.swift`
    - Location: `iOS-Productivity-App/Features/Schedule/Views/CommitmentFormView.swift`

#### Test target (iOS-Productivity-AppTests):
Right-click the test folder and add:
- `CommitmentViewModelTests.swift`
  - Location: `iOS-Productivity-AppTests/CommitmentViewModelTests.swift`
  - Target: iOS-Productivity-AppTests (NOT main app)
- `DataRepositoryTests.swift`
  - Location: `iOS-Productivity-AppTests/DataRepositoryTests.swift`
  - Target: iOS-Productivity-AppTests (NOT main app)

### 3. Verify Files Are Added

After adding all files:
1. Build the project (⌘+B)
2. All errors should be resolved
3. You should see all new files in the Project Navigator with proper folder structure

### Alternative: Use Finder to Add Files

If you prefer:
1. In Xcode, select the target folder in Project Navigator
2. Open Finder to the file location
3. Drag and drop the file from Finder into Xcode's Project Navigator
4. In the dialog, ensure:
   - "Copy items if needed" is UNCHECKED
   - Correct target is selected
   - Click "Finish"

## Troubleshooting

**If files still show errors after adding:**
1. Clean Build Folder: Product > Clean Build Folder (⌘+Shift+K)
2. Restart Xcode
3. Rebuild project (⌘+B)

**If you see duplicate files:**
- Delete the duplicate reference (select file, press Delete, choose "Remove Reference")
- Only keep the one in the correct folder

## Expected Project Structure After Adding Files:

```
iOS-Productivity-App/
├── App/
│   └── App.swift (modified)
├── Core/
│   ├── Models/
│   │   ├── User.swift (existing)
│   │   └── FixedCommitment.swift (NEW)
│   └── Services/
│       ├── AuthManager.swift (existing)
│       └── DataRepository.swift (NEW)
└── Features/
    ├── Authentication/ (existing)
    └── Schedule/
        ├── ViewModels/
        │   └── CommitmentViewModel.swift (NEW)
        └── Views/
            ├── ManageCommitmentsView.swift (NEW)
            └── CommitmentFormView.swift (NEW)
```

Once files are added, all compilation errors will be resolved!
