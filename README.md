# iOS Productivity App

A native iOS productivity application built with SwiftUI that helps users manage tasks and schedules efficiently.

## Project Structure

This project follows the MVVM (Model-View-ViewModel) architectural pattern:

```
iOS-Productivity-App/
├── Firebase/
│   └── GoogleService-Info.plist # Firebase configuration
│
├── App/
│   ├── App.swift               # Main app entry point (Firebase initialized here)
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
- **Backend:** Firebase (Authentication & Firestore)
- **Architecture:** MVVM with Repository Pattern
- **Testing:** XCTest
- **Dependency Management:** Swift Package Manager

## Requirements

- Xcode 15.0+
- iOS 16.0+ deployment target
- macOS for development
- Firebase account (Google account)

## Firebase Setup

This project uses Firebase for backend services (Authentication and Firestore Database).

### Firebase Configuration

- **Project:** iOS-Productivity-App-Dev
- **Project ID:** ios-productivity-app-dev
- **Region:** us-central1
- **Services Enabled:**
  - Firebase Authentication (Email/Password)
  - Firestore Database (Test mode for development)

### For New Developers

If you're setting up this project for the first time:

1. **Firebase Project Access:**
   - Contact the project administrator for access to the Firebase project
   - Or create your own Firebase project for local development

2. **Create Your Own Firebase Project (Alternative):**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project with any name (e.g., "iOS-Productivity-App-Local")
   - Add an iOS app with bundle ID: `com.productivityapp.iOS-Productivity-App`
   - Download the `GoogleService-Info.plist` file
   - Replace the file in `Firebase/GoogleService-Info.plist`
   - Enable Authentication (Email/Password sign-in method)
   - Enable Firestore Database (Start in test mode)

3. **Firebase SDK:**
   - Firebase packages are managed via Swift Package Manager
   - When you open the project in Xcode, SPM will automatically resolve dependencies
   - If packages are missing, add them manually:
     - Go to File > Add Package Dependencies
     - Add: `https://github.com/firebase/firebase-ios-sdk`
     - Select: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift

### Security Note

The `GoogleService-Info.plist` file in this repository is for the development environment. For production deployments, use a separate Firebase project with appropriate security rules.

## Getting Started

1. Clone the repository
2. Open `iOS-Productivity-App.xcodeproj` in Xcode
3. Wait for Swift Package Manager to resolve dependencies
4. Ensure you have access to the Firebase project or set up your own (see Firebase Setup)
5. Select your target device or simulator
6. Build and run the project (⌘+R)

## Development Status

- ✅ Story 1.1: Project initialization complete
- ✅ Story 1.2: Firebase backend & authentication setup complete

## Contributing

This project follows MVVM architecture and Firebase best practices. Please ensure all code follows the established patterns before submitting changes.

## License

Copyright © 2025. All rights reserved.
