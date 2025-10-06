# Epic 1: Foundation & Data Management
**Epic Goal:** This epic establishes the fundamental building blocks of the application. It includes setting up the iOS project, connecting to the backend service, implementing user authentication, and creating the core UI for managing tasks and fixed commitments. By the end of this epic, the user will have a functional, standalone task and schedule management app, ready for the intelligent features to be built on top.

### Story 1.1: Project Initialization
* **As a** developer, **I want** a new, configured SwiftUI project, **so that** I have a clean foundation for building the app.
* **Acceptance Criteria:** 1. A new Xcode project is created using the SwiftUI App template. 2. A Git repository is initialized. 3. A basic folder structure (e.g., Views, ViewModels, Models, Services) is created.

### Story 1.2: Backend & Authentication Setup
* **As a** developer, **I want** to set up and connect a BaaS, **so that** user data can be stored and managed securely.
* **Acceptance Criteria:** 1. A new project is created in the chosen BaaS provider. 2. The iOS app is configured to connect to the BaaS project. 3. The Authentication and Database services are enabled.

### Story 1.3: User Onboarding
* **As a** new user, **I want** to create an account and be able to log in and out, **so that** my schedule and tasks are saved securely.
* **Acceptance Criteria:** 1. A user can create an account using an email and password. 2. A user can log in with their credentials. 3. Upon login, the user is navigated to the main app screen. 4. An authenticated user can log out.

### Story 1.4: Manage Fixed Commitments
* **As a** user, **I want** to add, view, and manage my fixed schedule, **so that** the app knows when I am busy.
* **Acceptance Criteria:** 1. A user can create a commitment with a title, start time, and end time. 2. Commitments are displayed in a list. 3. A user can edit or delete a commitment. 4. All changes are saved to the backend.

### Story 1.5: Manage Task Inbox
* **As a** user, **I want** to add and manage all my flexible tasks, **so that** the app has a list of things it can schedule for me.
* **Acceptance Criteria:** 1. A user can create a task with a title and priority ("Must-Do" or "Flexible"). 2. Tasks are displayed in a master list. 3. A user can edit or delete a task. 4. All changes are saved to the backend.

---