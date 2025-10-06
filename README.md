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
│   │   └── User.swift          # User model
│   ├── Services/               # Backend logic (Repository, Engine)
│   │   └── AuthManager.swift   # Authentication service
│   └── Utils/                  # Helper functions
│
└── Features/                   # Feature-specific UI and logic
    ├── Authentication/
    │   ├── Views/
    │   │   ├── AuthenticationView.swift  # Root auth view
    │   │   ├── LoginView.swift           # Login screen
    │   │   └── SignUpView.swift          # Registration screen
    │   └── ViewModels/
    │       └── AuthViewModel.swift       # Auth UI state management
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

## Firebase Emulator (Local Testing)

The project includes Firebase Emulator Suite configuration for local testing without affecting production data.

### Setup

The emulator configuration is already set up in `firebase.json`. To use it:

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Start the Emulator:**
   ```bash
   cd iOS-Productivity-App
   firebase emulators:start
   ```

3. **Access Emulator UI:**
   - Open http://localhost:4000 in your browser
   - Firestore data is visible and manageable through the UI
   - Firestore API runs on localhost:8080

### Using Emulator in Tests

Integration tests can be configured to use the emulator:

```swift
// In test setUp()
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings
```

See `DataRepositoryTests.swift` for example implementation.

### Benefits

- Test CRUD operations without affecting production data
- Fast local database operations
- Easy data inspection and debugging
- No Firebase quota consumption during testing

**Important:** Emulator data is not persisted between restarts and should only be used for testing.

## Getting Started

1. Clone the repository
2. Open `iOS-Productivity-App.xcodeproj` in Xcode
3. Wait for Swift Package Manager to resolve dependencies
4. Ensure you have access to the Firebase project or set up your own (see Firebase Setup)
5. Select your target device or simulator
6. Build and run the project (⌘+R)

## Authentication

The app uses Firebase Authentication with email/password sign-in.

### Authentication Architecture

The authentication system follows a service-layer pattern:

- **AuthManager (Service Layer):** Manages all Firebase Auth SDK interactions
  - Handles sign-up, sign-in, and sign-out operations
  - Implements auth state listener for automatic session persistence
  - Maps Firebase User objects to app's User model
  - Conforms to `ObservableObject` for SwiftUI reactivity

- **AuthViewModel (UI Layer):** Manages authentication view state
  - Handles form input validation
  - Maps Firebase errors to user-friendly messages
  - Provides loading states for async operations
  - Delegates authentication operations to AuthManager

- **User Model:** Lightweight representation of authenticated user
  - Contains: `id` (Firebase UID) and `email`
  - Primary user record is managed by Firebase Authentication

### Session Persistence

Firebase Auth SDK automatically handles session persistence via iOS Keychain:
- Users remain logged in across app launches
- No manual token management required
- Auth state listener updates UI automatically on auth state changes

### Features

- ✅ Email/password registration
- ✅ Email/password login
- ✅ Sign out
- ✅ Session persistence across app launches
- ✅ Input validation with user-friendly error messages
- ✅ Loading states during async operations

### Known Limitations (MVP)

The following features are not implemented in the current MVP:
- Password reset/forgot password flow
- Email verification
- Social login providers (Google, Apple, etc.)
- Profile management
- Password change functionality

These features are planned for future releases.

## Development Status

- ✅ Story 1.1: Project initialization complete
- ✅ Story 1.2: Firebase backend & authentication setup complete
- ✅ Story 1.3: User authentication (sign-up, login, logout, persistence) complete
- ✅ Story 1.4: Manage Fixed Commitments complete

## Features

### Authentication
- Email/password registration and login
- Automatic session persistence
- User-friendly error messages

### Schedule Management
- Create, view, edit, and delete fixed commitments
- Commitments stored in Firestore with user isolation
- Input validation for commitment data
- Settings integration for easy access

## Architecture

This project follows the **MVVM (Model-View-ViewModel)** pattern with a **Repository service layer**:

- **Models:** Data structures (User, FixedCommitment)
- **Services:** Backend abstractions (AuthManager, DataRepository)
- **ViewModels:** UI state management and business logic
- **Views:** SwiftUI views for user interface

### Key Patterns

- **Repository Pattern:** DataRepository abstracts all Firestore operations
- **Dependency Injection:** Services injected via @EnvironmentObject
- **Async/await:** Modern concurrency for Firebase operations
- **@MainActor:** Ensures UI updates on main thread

## Contributing

This project follows MVVM architecture and Firebase best practices. Please ensure all code follows the established patterns before submitting changes.

## License

Copyright © 2025. All rights reserved.
