# Fullstack Architecture Document: iOS Productivity App


## Introduction & Starter Template
This document outlines the complete fullstack architecture for the iOS Productivity App, including the iOS frontend, the serverless backend, and their integration. It will serve as the single source of truth for the development team.


**Starter Template or Existing Project:**
Based on the PRD, this is a greenfield project. No specific starter template was mentioned. To accelerate development and ensure best practices, we recommend basing the project on a template or quickstart guide provided by our chosen Backend-as-a-Service provider (e.g., the official Firebase or Supabase SwiftUI quickstart guides). This will provide pre-configured modules for authentication and database connectivity, which aligns with our goal of a rapid MVP launch.


---
## High Level Architecture


#### Technical Summary
The application will be a native iOS client built with SwiftUI, following the MVVM pattern. It will operate on a serverless architecture, utilizing a Backend-as-a-Service (BaaS) for all backend functionality, including authentication and data persistence. The initial project will be contained within a single repository for simplicity. This user-centric architecture prioritizes a responsive frontend experience and rapid MVP development by offloading server management.


#### Platform and Infrastructure Choice
* **Platform:** **Firebase (Google Cloud)**.
* **Key Services:** Firebase Authentication, Firestore Database, and potentially Cloud Storage for any user-generated content in the future.
* **Rationale:** Firebase is recommended for its mature and comprehensive native iOS SDK, real-time data synchronization capabilities with Firestore, and tightly integrated authentication. This platform choice significantly accelerates development, which is a primary goal for the MVP. Supabase is a strong alternative if a relational (PostgreSQL) database is preferred.


#### Repository Structure
* **Structure:** **Single Repository**.
* **Rationale:** As the MVP consists of a single iOS application codebase with the backend managed by a third party, a single repository is the simplest and most efficient approach.


#### High Level Architecture Diagram

```mermaid
graph TD
    A[User] --> B[iOS App (SwiftUI on iPhone)];
    
    subgraph "Firebase (BaaS)"
        C[Authentication];
        D[Firestore Database];
    end


    B <--> C;
    B <--> D;


#### Architectural Patterns

*   **Serverless Architecture:** We will use a BaaS provider to handle all backend logic, which eliminates the need for server management and allows the team to focus exclusively on the application features.
    
*   **MVVM (Model-View-ViewModel):** This pattern will be strictly followed for the iOS application to ensure a clear separation between the UI (View), presentation logic (ViewModel), and data (Model). This is a requirement from the PRD.
    
*   **Repository Pattern:** A repository layer will be implemented in the iOS app to abstract data operations. The ViewModels will interact with the repository, which will in turn handle the specific calls to the Firebase SDK. This decouples our application logic from the backend provider, making future testing and potential migrations easier.
    

Tech Stack
----------

This table is the definitive source of truth for all technologies, libraries, and services to be used in the project.

Category Technology Version Purpose & Rationale

**Language**
Swift5.9+The native language for modern iOS development.

**UI Framework**
SwiftUI5.0+Required by the PRD; enables rapid, declarative UI development.

**State Mgt.**
Native SwiftUIN/AUsing built-in tools (@State, @ObservedObject) is simplest for the MVP.

**Backend**
FirebaseN/AA managed BaaS to handle all server-side needs for the MVP.

**Database**
FirestoreN/AFirebase's NoSQL, real-time database, ideal for syncing data to the app.

**Authentication**
Firebase AuthN/AProvides a complete, secure authentication system out of the box.

**Testing**
XCTestN/AApple's native framework for unit and integration testing of the iOS app.

**Local Testing
**Firebase EmulatorlatestAllows local testing of Firestore security rules and backend logic.

**CI/CD**
GitHub ActionsN/AA pragmatic choice for automating the build and test process on every push.

**Monitoring**
CrashlyticsN/AFirebase's tool for real-time crash reporting and stability monitoring.

Data Models
-----------

These data models represent the "nouns" of our application. They will be stored in the Firestore database and used throughout the iOS client.

#### User Model

*   **Note:** The primary user record (UID, email, etc.) will be managed by **Firebase Authentication**. We do not need a separate User collection in Firestore for the MVP.
    

#### FixedCommitment

*   **Purpose:** Represents a non-negotiable block of time in a user's schedule.
    
*   Swiftstruct FixedCommitment: Codable, Identifiable { var id: String var userId: String var title: String var startTime: Date var endTime: Date}
    
*   **Relationships:** Many-to-One with the User.
    

#### Task

*   **Purpose:** Represents a single, completable to-do item in the user's "inbox."
    
*   Swiftstruct Task: Codable, Identifiable { var id: String var userId: String var title: String var priority: String // "must-do" or "flexible" var energyLevel: String // "high", "low", "any" var isCompleted: Bool}
    
*   **Relationships:** Many-to-One with the User.
    

#### ScheduledTask

*   **Purpose:** Represents a specific Task placed into a time slot for a given day.
    
*   Swiftstruct ScheduledTask: Codable, Identifiable { var id: String var taskId: String var date: Date var startTime: Date var endTime: Date}
    
*   **Relationships:** One-to-One with a Task for a given day.
    

API Specification
-----------------

This application will not use a traditional REST or GraphQL API. Instead, all communication between the iOS client and the backend will be handled directly and securely through the native **Firebase SDK for iOS**.

#### Authentication

User authentication (signup, login, session management) will be managed entirely through the methods provided by the Firebase/Auth SDK.

#### Data Operations (CRUD)

All Create, Read, Update, and Delete operations for our data models will be performed using the Firebase/Firestore SDK, utilizing a combination of one-time fetches and real-time listeners for live data synchronization.

Components
----------

This section defines the primary logical components of the iOS application.

#### Component List

*   **AuthManager (Service):** Manages user authentication state and wraps all FirebaseAuth SDK calls.
    
*   **DataRepository (Service):** Centralizes all Firestore data operations (CRUD) for all data models.
    
*   **SchedulingEngine (Service):** Contains the pure business logic for the scheduling algorithm.
    
*   **ScheduleViewModel (ViewModel):** Manages the state and business logic for the main "Today View."
    

#### Component Interaction Diagram

Code snippet

graph TD
    subgraph "UI (Views)"
        A[TodayView];
        B[LoginView];
    end
    
    subgraph "Presentation Logic (ViewModels)"
        C[ScheduleViewModel];
        D[AuthViewModel];
    end


    subgraph "Business Logic & Data (Services)"
        E[SchedulingEngine];
        F[DataRepository];
        G[AuthManager];
    end


    subgraph "Backend (Firebase)"
        H[Firestore Database];
        I[Firebase Auth];
    end


    A --> C;
    B --> D;
    
    C --> E;
    C --> F;
    D --> G;


    F --> H;
    G --> I;

External APIs
-------------

For the scope of the Minimum Viable Product (MVP), there are **no external third-party API integrations required**. All backend communication is handled directly through the integrated Firebase SDK.

Core Workflows
--------------

This sequence diagram illustrates the component interactions for the "Daily Planning & Task Engagement" user flow.

Code snippet

sequenceDiagram
    participant User
    participant TodayView
    participant ScheduleViewModel
    participant DataRepository
    participant SchedulingEngine
    participant Firestore


    User->>TodayView: 1. Taps an empty time block
    TodayView->>ScheduleViewModel: 2. Requests suggestions for the block
    ScheduleViewModel->>User: 3. Presents Mood Selector UI
    User->>ScheduleViewModel: 4. Selects a mood (e.g., 'Focused')
    
    ScheduleViewModel->>DataRepository: 5. fetchTasks()
    activate DataRepository
    DataRepository->>Firestore: 6. Asynchronously get tasks
    activate Firestore
    Firestore-->>DataRepository: 7. Returns task data
    deactivate Firestore
    DataRepository-->>ScheduleViewModel: 8. Returns [Task]
    deactivate DataRepository
    
    ScheduleViewModel->>SchedulingEngine: 9. suggestTasks(tasks, mood: 'Focused')
    activate SchedulingEngine
    SchedulingEngine-->>ScheduleViewModel: 10. Returns filtered [SuggestedTask]
    deactivate SchedulingEngine


    ScheduleViewModel->>User: 11. Displays suggestions in UI
    User->>ScheduleViewModel: 12. Taps to select a suggested task
    
    ScheduleViewModel->>DataRepository: 13. save(new ScheduledTask)
    activate DataRepository
    DataRepository->>Firestore: 14. Asynchronously save new document
    activate Firestore
    Firestore-->>DataRepository: 15. Confirms save
    deactivate Firestore
    DataRepository-->>ScheduleViewModel: 16. Confirms save
    deactivate DataRepository


    Note over ScheduleViewModel, TodayView: 17. ViewModel updates its state, UI refreshes automatically.


Database Schema
---------------

This schema for Firestore is structured as a series of collections and sub-collections for security and efficient querying.

#### Collection: users

Each document ID is the user's Firebase Auth UID. All user data is nested within this document.

*   **Path:** /users/{userId}
    

##### Sub-collection: tasks

*   **Path:** /users/{userId}/tasks/{taskId}
    
*   **Document Structure:** { "title": "String", "priority": "String", "energyLevel": "String", "isCompleted": "Boolean", "createdAt": "Timestamp" }
    

##### Sub-collection: fixedCommitments

*   **Path:** /users/{userId}/fixedCommitments/{commitmentId}
    
*   **Document Structure:** { "title": "String", "startTime": "Timestamp", "endTime": "Timestamp" }
    

##### Sub-collection: scheduledTasks

*   **Path:** /users/{userId}/scheduledTasks/{scheduledTaskId}
    
*   **Document Structure:** { "taskId": "String", "date": "Timestamp", "startTime": "Timestamp", "endTime": "Timestamp" }
    

Unified Project Structure
-------------------------

This structure is a standard, pragmatic choice for a feature-sliced SwiftUI application.

/iOS-Productivity-App/
|
├── App/
│   ├── App.swift               # Main app entry point
│   └── Assets.xcassets         # App icons, images, colors
│
├── Core/
│   ├── Models/                 # Data structures
│   ├── Services/               # Backend logic (Repository, Engine)
│   └── Utils/                  # Helper functions
│
├── Features/                   # Feature-specific UI and logic
│   ├── Authentication/
│   │   ├── Views/ & ViewModels/
│   ├── Schedule/
│   │   ├── Views/ & ViewModels/
│   └── TaskInbox/
│       ├── Views/ & ViewModels/
│
├── Firebase/                   # Firebase configuration file
│   └── GoogleService-Info.plist
│
└── Tests/                      # Unit and UI tests


Development Workflow
--------------------

#### Local Development Setup

*   **Prerequisites:** Xcode 15.0+, Swift Package Manager, Git, Firebase Account.
    
*   **Initial Setup:**
    
    1.  Clone the repository.
        
    2.  Open in Xcode to resolve packages.
        
    3.  Create a Firebase project and add a new iOS app.
        
    4.  Download GoogleService-Info.plist and place it in the Firebase/ folder.
        
    5.  Enable Authentication and Firestore in the Firebase Console.
        
*   **Development Commands:**
    
    *   **Build & Run:** Cmd + R in Xcode.
        
    *   **Run Tests:** Cmd + U in Xcode.
        

#### Environment Configuration

Configuration is managed by the GoogleService-Info.plist file, which should be treated as a secret and not committed to public version control.

Deployment Architecture
-----------------------

#### Deployment Strategy

*   **iOS Application:** The app will be built, signed, and archived using Xcode, then uploaded to **App Store Connect** for release.
    
*   **Backend:** Deployment consists of manually updating **Firestore security rules** and **database indexes** via the Firebase Console.
    

#### CI/CD Pipeline

We will use **GitHub Actions** for Continuous Integration to build and test the app on every push to the main branch.

#### Environments

EnvironmentiOS Build TypeBackend Firebase ProjectPurpose**Development**Debugproductivity-app-devFor all development and testing.**Production**Releaseproductivity-app-prodFor the live App Store version.

Security and Performance
------------------------

#### Security Requirements

*   **Frontend:** Authentication tokens MUST be stored in the **iOS Keychain**.
    
*   **Backend:** All data access MUST be protected by comprehensive **Firestore Security Rules**.
    
*   **Authentication:** Session management will be handled by the **Firebase Auth SDK**.
    

#### Performance Optimization

*   **Frontend:** We will use placeholder (skeleton) views for perceived performance and enable **Firestore's offline persistence** for caching and offline functionality.
    
*   **Backend:** Performance relies on proper **Firestore indexing** and efficient query design.
    

Implementation Guidance (Testing, Standards, & Error Handling)
--------------------------------------------------------------

#### Testing Strategy

*   **Unit Tests (XCTest):** All ViewModels and services with business logic MUST have unit tests.
    
*   **Integration Tests (XCTest + Firebase Emulator):** The DataRepository MUST have integration tests that run against the local Firebase Emulator.
    

#### Critical Coding Standards

1.  **Always Use the Repository:** UI and ViewModel layers MUST NOT call Firebase SDK methods directly.
    
2.  **Manage State Properly:** All UI state MUST be managed within SwiftUI Views or their corresponding ViewModels.
    
3.  **Handle Errors Explicitly:** All failable operations MUST return a Swift Result type (Result).
    

#### Error Handling Strategy

*   The application will use Swift's Result type to enforce explicit error handling. ViewModels are responsible for catching errors and translating them into user-friendly UI states.
    

Final Report & Next Steps
-------------------------

#### Checklist Results Report

The architecture has been validated and is comprehensive, pragmatic, and aligned with all requirements.

Final Decision: READY FOR DEVELOPMENT