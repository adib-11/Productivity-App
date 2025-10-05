# iOS Productivity App

A native iOS productivity application built with SwiftUI that helps users manage tasks and schedules efficiently.

## Project Structure

This project follows the MVVM (Model-View-ViewModel) architectural pattern:

```
iOS-Productivity-App/
├── App/
│   ├── App.swift               # Main app entry point
│   └── Assets.xcassets         # App icons, images, colors
│
├── Core/
│   ├── Models/                 # Data structures
│   ├── Services/               # Backend logic (Repository, Engine)
│   └── Utils/                  # Helper functions
│
└── Features/                   # Feature-specific UI and logic
    ├── Authentication/
    │   ├── Views/
    │   └── ViewModels/
    ├── Schedule/
    │   ├── Views/
    │   └── ViewModels/
    └── TaskInbox/
        ├── Views/
        └── ViewModels/
```

## Technical Stack

- **Platform:** iOS 16.0+
- **Framework:** SwiftUI 5.0+
- **Language:** Swift 5.9+
- **Backend:** Firebase (to be integrated in Story 1.2)
- **Architecture:** MVVM with Repository Pattern
- **Testing:** XCTest

## Requirements

- Xcode 15.0+
- iOS 16.0+ deployment target
- macOS for development

## Getting Started

1. Open `iOS-Productivity-App.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## Development Status

- ✅ Story 1.1: Project initialization complete
- 🔄 Story 1.2: Firebase integration (upcoming)

## License

Copyright © 2025. All rights reserved.
