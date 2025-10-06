# iOS Productivity App Product Requirements Document (PRD)

| Date | Version | Description | Author |
| :--- | :--- | :--- | :--- |
| Oct 5, 2025 | 1.0 | Initial PRD Draft from Project Brief | John (PM) |

## Goals and Background Context
#### Goals
* Validate the core hypothesis that users will value automated scheduling combined with mood-based task suggestions.
* Achieve a Week 1 user retention rate of 20% to demonstrate early product-market fit.
* Empower users to feel more in control of their daily schedule and improve their task completion rate.

#### Background Context
This document outlines the requirements for a new iOS productivity app designed for users with dynamic schedules, such as university students. Existing tools are often too rigid or too passive to meet their needs, leading to stress and lost productivity. This product aims to fill that gap by acting as an intelligent assistant that not only schedules a user's day but also considers their well-being and energy levels, a key differentiator in the crowded productivity market.

---
## Requirements
#### Functional
1.  **FR1:** The system shall allow users to input, view, and manage a list of their fixed commitments (e.g., classes, appointments) with specific start and end times.
2.  **FR2:** The system shall allow users to create, view, edit, and delete tasks for their to-do list.
3.  **FR3:** The system shall allow users to assign a priority level to each task (e.g., "Must-Do" or "Flexible").
4.  **FR4:** The system shall automatically generate a daily schedule by placing "Must-Do" tasks into available time windows.
5.  **FR5:** The system shall allow a user to self-report their current mood/energy level from a predefined list (e.g., "Energetic," "Tired," "Focused").
6.  **FR6:** The system shall suggest "Flexible" tasks to the user for open time blocks, based on their reported mood.
7.  **FR7:** The system shall allow users to manually edit, move, or delete any task block on the generated schedule.
8.  **FR8:** The system shall display a positive, reinforcing message when a user marks a task as complete.
9.  **FR9:** The scheduling engine shall intelligently schedule blocks for rest or breaks.

#### Non-Functional
1.  **NFR1:** The application shall be a native iOS application, fully compatible with iOS 17 and later.
2.  **NFR2:** The application must feel responsive, with a cold-start launch time of under 2 seconds.
3.  **NFR3:** All user data (schedules, tasks, account information) must be securely stored and encrypted in transit.
4.  **NFR4:** The user interface must be intuitive and simple, requiring minimal onboarding for a new user to understand the core functionality.

---
## User Interface Design Goals
#### Overall UX Vision
The user experience should be simple, engaging, and encouraging. The app should feel less like a rigid planner and more like an empathetic assistant that helps users feel in control and productive without causing stress. The primary goal is to reduce the cognitive load of daily planning.

#### Key Interaction Paradigms
* **Visual Timeline:** The main view will be a clear, scrollable timeline of the user's day.
* **Drag-and-Drop:** Users will be able to manually adjust their schedule by dragging and dropping task blocks.
* **Simple Check-in:** A non-intrusive modal or prompt will ask for the user's mood/energy at key moments.
* **Quick-Add:** A persistent, easily accessible button (e.g., a floating action button) will allow for frictionless task entry.

#### Core Screens and Views
* **Today View:** The main dashboard showing the generated schedule for the current day.
* **Task Inbox:** A separate screen to view, add, and manage the master list of all tasks.
* **Task Detail/Entry Screen:** A form for adding or editing a task's title and priority.
* **Mood Selector:** The simple interface for the user's daily energy check-in.
* **Settings:** For managing fixed commitments, account details, and preferences.

#### Accessibility
* **Target:** WCAG AA compliance.

#### Branding
* The UI should feel clean, simple, and engaging, taking inspiration from the simplicity and positive reinforcement loops seen in apps like **Duolingo**. The aesthetic should be encouraging and visually satisfying.

#### Target Device and Platforms
* **iOS (Responsive):** The initial launch will be for iOS, with a design that works seamlessly across all modern iPhone screen sizes.

---
## Technical Assumptions
#### Repository Structure: Polyrepo
* The project will start with a single repository for the native iOS application. The backend is managed by a third-party BaaS provider, so a separate backend repository is not needed for the MVP.

#### Service Architecture: Serverless
* The application will use a Backend-as-a-Service (BaaS) platform (e.g., Firebase, Supabase). This serverless approach aligns with the MVP's goal of rapid development.

#### Testing Requirements: Unit + Integration
* The testing strategy will include both unit tests for individual components and integration tests to verify communication with the BaaS backend.

#### Additional Technical Assumptions and Requests
* **Platform & Framework:** The application MUST be a native iOS app built with **SwiftUI**.
* **Architecture Pattern:** The codebase MUST follow the **MVVM (Model-View-ViewModel)** pattern.
* **Backend:** A BaaS is REQUIRED for the MVP.

---
## Epic List
* **Epic 1: Foundation & Data Management**
    * **Goal:** Establish the core application, user accounts, and the ability for users to input and manage all their tasks and fixed commitments.
* **Epic 2: The Automated Scheduler**
    * **Goal:** Implement the core scheduling engine that automatically arranges tasks on a visual timeline and gives users full manual control to adjust the plan.
* **Epic 3: Mood-Based Intelligence & Engagement**
    * **Goal:** Introduce the key differentiation by suggesting tasks based on user's mood and add simple rewards to encourage task completion.

---
## Epic 1: Foundation & Data Management
**Epic Goal:** This epic establishes the fundamental building blocks of the application. It includes setting up the iOS project, connecting to the backend service, implementing user authentication, and creating the core UI for managing tasks and fixed commitments. By the end of this epic, the user will have a functional, standalone task and schedule management app, ready for the intelligent features to be built on top.

#### Story 1.1: Project Initialization
* **As a** developer, **I want** a new, configured SwiftUI project, **so that** I have a clean foundation for building the app.
* **Acceptance Criteria:** 1. A new Xcode project is created using the SwiftUI App template. 2. A Git repository is initialized. 3. A basic folder structure (e.g., Views, ViewModels, Models, Services) is created.

#### Story 1.2: Backend & Authentication Setup
* **As a** developer, **I want** to set up and connect a BaaS, **so that** user data can be stored and managed securely.
* **Acceptance Criteria:** 1. A new project is created in the chosen BaaS provider. 2. The iOS app is configured to connect to the BaaS project. 3. The Authentication and Database services are enabled.

#### Story 1.3: User Onboarding
* **As a** new user, **I want** to create an account and be able to log in and out, **so that** my schedule and tasks are saved securely.
* **Acceptance Criteria:** 1. A user can create an account using an email and password. 2. A user can log in with their credentials. 3. Upon login, the user is navigated to the main app screen. 4. An authenticated user can log out.

#### Story 1.4: Manage Fixed Commitments
* **As a** user, **I want** to add, view, and manage my fixed schedule, **so that** the app knows when I am busy.
* **Acceptance Criteria:** 1. A user can create a commitment with a title, start time, and end time. 2. Commitments are displayed in a list. 3. A user can edit or delete a commitment. 4. All changes are saved to the backend.

#### Story 1.5: Manage Task Inbox
* **As a** user, **I want** to add and manage all my flexible tasks, **so that** the app has a list of things it can schedule for me.
* **Acceptance Criteria:** 1. A user can create a task with a title and priority ("Must-Do" or "Flexible"). 2. Tasks are displayed in a master list. 3. A user can edit or delete a task. 4. All changes are saved to the backend.

---
## Epic 2: The Automated Scheduler
**Epic Goal:** This epic introduces the app's primary value proposition. It takes the commitments and tasks from Epic 1 and uses them to build a visual, interactive daily schedule, establishing the balance between automation and user control.

#### Story 2.1: Visual Daily Timeline
* **As a** user, **I want** to see my day visually represented as a timeline, **so that** I can understand my availability at a glance.
* **Acceptance Criteria:** 1. The "Today" view displays a vertical timeline. 2. Fixed commitments are rendered as static blocks in their correct time slots. 3. A line indicates the current time.

#### Story 2.2: Free Time Identification Algorithm
* **As a** developer, **I want** an algorithm that identifies all open time windows in a user's schedule, **so that** tasks can be placed within them.
* **Acceptance Criteria:** 1. The algorithm identifies all free time blocks between fixed commitments. 2. The algorithm can be configured to leave a minimum gap between events. 3. The output is a list of available time windows.

#### Story 2.3: Schedule "Must-Do" Tasks
* **As a** user, **I want** the app to automatically find time for my most important tasks, **so that** I don't have to schedule them manually.
* **Acceptance Criteria:** 1. The engine places "Must-Do" tasks into the first available time windows. 2. Each task is assigned a default duration. 3. Scheduled tasks are displayed on the visual timeline. 4. The user is notified if there isn't enough free time.

#### Story 2.4: Manually Adjust Schedule
* **As a** user, **I want** to be able to drag-and-drop my scheduled tasks, **so that** I have full control over my final plan.
* **Acceptance Criteria:** 1. A user can tap, hold, and drag a task block. 2. The task can be moved to another empty time slot. 3. A user can resize a block to change its duration. 4. All changes are saved.

#### Story 2.5: Interact with Scheduled Tasks
* **As a** user, **I want** to mark a task as complete directly from my schedule, **so that** I can track my progress.
* **Acceptance Criteria:** 1. Tapping a task block reveals a "Mark Complete" option. 2. Marking a task visually distinguishes it on the timeline. 3. The simple reward message is displayed upon completion.

---
## Epic 3: Mood-Based Intelligence & Engagement
**Epic Goal:** This final epic for the MVP introduces the app's signature feature: mood-based task suggestions. It builds upon the functional scheduler from Epic 2, adding a layer of intelligence and empathy to boost genuine productivity and user satisfaction.

#### Story 3.1: Mood & Energy Check-in
* **As a** user, **I want** a simple way to tell the app how I'm feeling, **so that** I can get relevant task suggestions.
* **Acceptance Criteria:** 1. A user can open a simple mood/energy selector. 2. The selector presents clear options (e.g., "Energetic", "Tired"). 3. The selection is captured for generating suggestions.

#### Story 3.2: Associate Tasks with Energy Levels
* **As a** user, **I want** to optionally categorize my tasks by the energy they require, **so that** the app can make smart suggestions.
* **Acceptance Criteria:** 1. When creating/editing a task, a user can optionally assign an energy level. 2. The default is "Any". 3. The energy level is saved to the backend.

#### Story 3.3: Task Suggestion Engine
* **As a** user with free time, **I want** the app to suggest what to do based on my current mood, **so that** I can avoid decision fatigue.
* **Acceptance Criteria:** 1. After a user reports their mood, the app filters their "Flexible" tasks. 2. The app presents a short list (1-3) of tasks matching the mood and energy tag. 3. A friendly message is shown if no tasks match.

#### Story 3.4: Add Suggested Task to Schedule
* **As a** user, **I want** to quickly add a suggested task to my schedule with a single tap, **so that** I can easily act on the recommendation.
* **Acceptance Criteria:** 1. Tapping a suggested task adds it to the corresponding time block on the schedule. 2. The new task block is saved. 3. The block can be moved, edited, or marked complete.