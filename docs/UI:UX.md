# UI/UX Specification: iOS Productivity App  

## Introduction  This document defines the user experience goals, information architecture, user flows, and visual design specifications for the iOS Productivity App's user interface. It serves as the foundation for visual design and frontend development, ensuring a cohesive and user-centered experience.  

### Overall UX Goals & Principles  

#### Target User Personas. 
* **Primary:** The University Student (18-24) who is tech-savvy but feels overwhelmed balancing a hybrid schedule of fixed classes and flexible study time.
  * **Secondary:** The Young Professional / Freelancer (23-35) who needs to optimize their focus and manage a blend of meetings and project work.

  #### Usability Goals
  * **Ease of Learning:** A new user should be able to set up their schedule and get their first task suggestion within 5 minutes.
  * **Efficiency:** Daily planning and check-ins should take no more than 60 seconds.
  * **Satisfaction:** The user should feel less stressed and more in control of their day, as measured by in-app feedback.

  #### Design Principles
  1.  **Clarity Over Cleverness:** Prioritize clear, simple interfaces over complex or novel ones.
  2.  **Encourage, Don't Command:** The app's tone and interactions should feel like a supportive assistant, not a rigid boss.
  3.  **Progressive Disclosure:** Show only what is necessary for the current step to avoid overwhelming the user.
  4.  **Frictionless Input:** Make adding tasks and commitments as fast and easy as possible.  

---  

## Information Architecture (IA)  

#### Site Map / Screen Inventory  

This diagram shows the primary screens of the application and how they relate to one another.  

```mermaid
graph TD
    subgraph Onboarding
        A[Login / Signup] --> B[Today View];
    end


    subgraph Main App
        B --> C[Task Inbox];
        B --> D[Settings];
        B -- Taps empty block --> E[Mood Selector Modal];
    end
    
    C --> F[Task Detail/Entry Screen];
    D --> G[Manage Fixed Commitments];
    D --> H[Account Settings];
    E -- Selects Mood --> I{Suggestion Engine};

#### Navigation Structure

*   **Primary Navigation:** A simple tab bar at the bottom of the screen will provide access to the main sections: **"Today"** (the schedule view) and **"Task Inbox"** (the master task list).
    
*   **Secondary Navigation:** Navigation within deeper sections, like "Settings," will use standard list-based navigation.
    
*   **Hierarchical Navigation:** Standard iOS navigation bar "back" buttons will be used to move backward through a screen hierarchy (e.g., from "Settings" back to "Today").
    

User Flows
----------

#### Flow 1: Onboarding & Initial Setup

User Goal: To create an account and provide the app with the minimum information required to generate the first daily schedule.

Entry Points: Opening the app for the very first time.

Success Criteria: The user has a valid account, is logged in, and has added at least one fixed commitment and one flexible task.

**Flow Diagram:**

Code snippet

graph TD
    A[Launch App] --> B{Existing User?};
    B -->|No| C[Present Signup Screen];
    C --> D[Create Account];
    D --> E{Account Created};
    E -->|Success| F[Prompt to Add First Fixed Commitment];
    B -->|Yes| G[Present Login Screen];
    G --> H[Login];
    H --> I{Login Success};
    I -->|Success| J[Navigate to Today View];
    F --> K[User Adds Commitment];
    K --> L[Prompt to Add First Flexible Task];
    L --> M[User Adds Task];
    M --> J;
    
    E -->|Error| N[Show Signup Error];
    I -->|Error| O[Show Login Error];

**Edge Cases & Error Handling:**

*   User provides an invalid email or weak password during signup.
    
*   User enters incorrect login credentials.
    
*   Network connection fails during account creation or login.
    
*   User tries to skip the initial setup prompts.
    

#### Flow 2: Daily Planning & Task Engagement

User Goal: To see the day's automated plan, get a relevant task suggestion for a free moment, and easily act on it.

Entry Points: Opening the app on any day after the initial setup is complete.

Success Criteria: The user successfully adds a mood-based task suggestion to their schedule.

**Flow Diagram:**

Code snippet

graph TD
    A[User Opens App] --> B[Display 'Today View' with schedule];
    B --> C[User identifies and taps an empty time block];
    C --> D[Present Mood Selector];
    D --> E[User selects current mood/energy];
    E --> F[App suggests 1-3 matching flexible tasks];
    F --> G{User selects a task?};
    G -- Yes --> H[Add task to the selected time block on the schedule];
    H --> B;
    G -- No/Dismiss --> B;

**Edge Cases & Error Handling:**

*   User has no "Flexible" tasks in their inbox.
    
*   No tasks in the inbox match the selected mood.
    
*   The selected time block is too short for any available tasks.
    
*   Network error occurs when trying to save the new task to the schedule.
    

#### Flow 3: Manually Adjusting the Schedule

User Goal: To easily modify the app's suggested plan to better fit their immediate needs, mood, or unexpected changes in their day.

Entry Points: Viewing the "Today View" screen where a schedule has already been generated.

Success Criteria: The user has successfully moved, resized, or deleted a task block, and the change is reflected and saved.

**Flow Diagram:**

Code snippet

graph TD
    A[User Views Today's Schedule] --> B{Selects a Task Block};
    B -- Tap & Hold --> C[Enter 'Edit Mode'];
    C --> D[User Drags Block to New Time];
    D --> E[Release to Confirm New Time];
    E --> F[Save Changes];
    
    C --> G[User Drags Resize Handle];
    G --> H[Adjust Task Duration];
    H --> I[Release to Confirm New Duration];
    I --> F;


    B -- Single Tap --> J[Show Task Options];
    J --> K[User Selects 'Delete'];
    K --> L[Confirmation Prompt];
    L -- Confirms --> M[Remove Block from Schedule];
    M --> F;

**Edge Cases & Error Handling:**

*   User attempts to drag a task to a time slot that conflicts with a fixed commitment.
    
*   User tries to resize a task to be shorter than a minimum duration (e.g., 15 minutes).
    
*   User attempts to drag a task to overlap with another task block.
    
*   Network error when saving the updated schedule.
    

Wireframes & Mockups
--------------------

This section outlines the basic structure of the app's main screens. The high-fidelity, pixel-perfect visual designs will be created in a dedicated design tool.

#### Primary Design Files

*   **Design Tool:** We will use a tool like **Figma** for the detailed visual design and prototyping. A link to the final project will be placed here once it's created.
    

#### Key Screen Layouts

##### Screen: Today View / Daily Schedule

*   **Purpose:** To provide the user with a clear, at-a-glance overview of their day. It will display their fixed commitments, automatically scheduled tasks, and open time slots, serving as the app's main interactive dashboard.
    
*   **Key Elements:**
    
    *   **Date Header:** Displays the current date with simple navigation to view past or future days.
        
    *   **Vertical Timeline:** A vertically scrollable view showing the hours of the day.
        
    *   **Commitment Blocks:** Visually distinct, static blocks representing fixed events like classes or meetings.
        
    *   **Task Blocks:** Interactive blocks representing tasks scheduled by the app or user. These can be tapped, held, and dragged.
        
    *   **Empty Time Slots:** Tappable empty areas on the timeline that trigger the task suggestion flow.
        
    *   **Quick-Add Button:** A floating action button for quickly adding a new task to the inbox.
        
*   **Interaction Notes:**
    
    *   The timeline is the primary interactive surface.
        
    *   Tapping an empty slot initiates the **"Daily Planning"** user flow.
        
    *   Tapping and holding a task block initiates the **"Manual Adjustment"** user flow.
        

Component Library / Design System
---------------------------------

#### Design System Approach

For the MVP, we will prioritize speed and a native feel. Instead of building a custom design system from scratch, our approach will be to **leverage the comprehensive set of standard components provided by Apple's SwiftUI framework**. We will then create a custom theme (colors, typography, spacing) to apply to these native components. This ensures a unique brand identity while maintaining platform conventions and accelerating development.

#### Core Components

*   **Button**
    
    *   **Purpose:** To trigger all primary actions like "Save," "Log In," or "Add Task."
        
    *   **Variants:** We will need at least a Primary (filled) and Secondary (outline or plain) style.
        
    *   **States:** Default, Tapped, and Disabled states must be visually distinct.
        
*   **Task Block**
    
    *   **Purpose:** The visual representation of a task on the daily timeline. This will be a custom composite component.
        
    *   **Variants:** Needs styles to differentiate between "Must-Do" and "Flexible" tasks.
        
    *   **States:** Default, Selected, Being Dragged, and Completed.
        
*   **Input Field**
    
    *   **Purpose:** For all text entry, including login credentials, task titles, and commitment details.
        
    *   **Variants:** Standard and Password (secure text entry).
        
    *   **States:** Default, Focused, and Error (with a clear message).
        

Branding & Style Guide
----------------------

As this is a new product, we will establish the initial style guide here. The goal is a clean, modern, and encouraging aesthetic that feels native to iOS.

#### Visual Identity

*   **Brand Guidelines:** This document will serve as the initial brand guidelines.
    

#### Color Palette

Color Type Hex Code Usage
* **Primary #007AFF Core interactive elements, buttons, active tabs.
* **Secondary#F2F2F7Backgrounds for content areas, cards.
* **Accent #FFD60A Special callouts, rewards, highlights.
* **Success #34C759 Confirmation messages, completed states.
* **Warning #FF9500 Non-critical alerts, prompts.
* **Error #FF3B30 Error messages, destructive action confirmation.
* **Neutral #8E8E93 Body text, borders, dividers, icons.

#### Typography

*   **Font Families:**
    
    *   **Primary:** **SF Pro.** As the native iOS system font, it ensures perfect readability, performance, and consistency.
        
    *   **Monospace:** **SF Mono.** For any areas that might need to display data or code snippets.
        
*   **Type Scale:**
    
    *   **H1 (Large Title):** 34pt, Bold
        
    *   **H2 (Title 1):** 28pt, Bold
        
    *   **H3 (Headline):** 17pt, Semibold
        
    *   **Body:** 17pt, Regular
        
    *   **Small (Caption):** 12pt, Regular
        

#### Iconography

*   **Icon Library:** We will exclusively use **SF Symbols**, Apple's extensive icon library.
    
*   **Usage Guidelines:** Icons should be used with labels whenever possible and follow Apple's Human Interface Guidelines for weight and scale.
    

#### Spacing & Layout

*   **Grid System:** We will adhere to an **8-point grid system**. All spacing and component dimensions will be in multiples of 8 (8pt, 16pt, 24pt, etc.) to ensure consistent and rhythmic layouts.
    

Accessibility Requirements
--------------------------

#### Compliance Target

*   **Standard:** The application will target **WCAG 2.1 Level AA** compliance.
    

#### Key Requirements

*   **Visual:**
    
    *   **Color Contrast:** All text and essential UI elements must meet a minimum contrast ratio of 4.5:1.
        
    *   **Focus Indicators:** All interactive elements must have a clear and highly visible focus state.
        
    *   **Text Sizing:** The app must fully support iOS's Dynamic Type.
        
*   **Interaction:**
    
    *   **Screen Reader Support:** All controls must be properly labeled for Apple's VoiceOver.
        
    *   **Touch Targets:** All tappable controls must have a minimum target size of 44x44 points.
        
*   **Content:**
    
    *   **Form Labels:** All input fields will have clear, programmatically associated labels.
        
    *   **Alternative Text:** All meaningful icons and images will have descriptive alternative text.
        

#### Testing Strategy

*   **Automated Testing:** We will use Xcode's Accessibility Inspector to catch common issues.
    
*   **Manual Testing:** Regular manual testing will be performed using **VoiceOver**.
    

Responsiveness Strategy
-----------------------

The app will leverage SwiftUI's adaptive layout capabilities to ensure a great experience on all supported iOS devices.

#### Device Classes & Breakpoints

Device ClassExample DevicesGeneral LayoutCompact WidthAll iPhones in PortraitSingle-column, stacked layout.Regular WidthAll iPads; larger iPhones in LandscapeMulti-column layouts (e.g., sidebar or grid).

#### Adaptation Patterns

*   **Layout:** The app will be designed "mobile-first," prioritizing a clean, single-column layout for the portrait iPhone experience. On larger screens like an iPad, key screens will adapt to a two-column (master-detail) layout.
    
*   **Navigation:** On iPhone, the primary navigation will be the bottom tab bar. On iPad, this may adapt into a persistent sidebar.
    

Animation & Micro-interactions
------------------------------

#### Motion Principles

*   **Informative:** Animations should guide the user and provide feedback.
    
*   **Responsive:** Every user tap should have immediate visual feedback.
    
*   **Subtle & Quick:** Motion should be understated and brief, never making the user wait.
    
*   **Respectful:** The app must respect the iOS "Reduce Motion" accessibility setting.
    

#### Key Animations & Micro-interactions

*   **Task Completion:** A satisfying but brief animation (e.g., a checkmark drawing itself) will provide positive reinforcement.
    
*   **Drag-and-Drop Feedback:** When a user drags a task block, it should lift slightly with a soft shadow. Drop targets should subtly highlight.
    
*   **Mood Selection:** As the user selects their mood, the interface should respond with a gentle animation, confirming their choice.
    
*   **State Transitions:** All screen transitions will use standard, subtle iOS animations.
    

Performance Considerations
--------------------------

#### Performance Goals

*   **App Launch:** The cold start launch time should be under 2 seconds.
    
*   **Interaction Response:** All user interactions must provide visual feedback in under 100ms.
    
*   **Animation FPS:** All animations and scrolling must maintain a consistent 60 frames per second (FPS).
    

#### Design Strategies to Enhance Performance

*   **Perceived Performance:** We will use techniques like placeholder UIs (skeleton loaders) and "optimistic updates," where the UI updates instantly while data saves in the background.
    
*   **Efficient Data Loading:** The app will only fetch the data needed for the current view.
    
*   **Asset Optimization:** All images and visual assets will be optimized for the smallest possible file sizes.