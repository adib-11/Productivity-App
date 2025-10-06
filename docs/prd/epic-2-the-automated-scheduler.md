# Epic 2: The Automated Scheduler
**Epic Goal:** This epic introduces the app's primary value proposition. It takes the commitments and tasks from Epic 1 and uses them to build a visual, interactive daily schedule, establishing the balance between automation and user control.

### Story 2.1: Visual Daily Timeline
* **As a** user, **I want** to see my day visually represented as a timeline, **so that** I can understand my availability at a glance.
* **Acceptance Criteria:** 1. The "Today" view displays a vertical timeline. 2. Fixed commitments are rendered as static blocks in their correct time slots. 3. A line indicates the current time.

### Story 2.2: Free Time Identification Algorithm
* **As a** developer, **I want** an algorithm that identifies all open time windows in a user's schedule, **so that** tasks can be placed within them.
* **Acceptance Criteria:** 1. The algorithm identifies all free time blocks between fixed commitments. 2. The algorithm can be configured to leave a minimum gap between events. 3. The output is a list of available time windows.

### Story 2.3: Schedule "Must-Do" Tasks
* **As a** user, **I want** the app to automatically find time for my most important tasks, **so that** I don't have to schedule them manually.
* **Acceptance Criteria:** 1. The engine places "Must-Do" tasks into the first available time windows. 2. Each task is assigned a default duration. 3. Scheduled tasks are displayed on the visual timeline. 4. The user is notified if there isn't enough free time.

### Story 2.4: Manually Adjust Schedule
* **As a** user, **I want** to be able to drag-and-drop my scheduled tasks, **so that** I have full control over my final plan.
* **Acceptance Criteria:** 1. A user can tap, hold, and drag a task block. 2. The task can be moved to another empty time slot. 3. A user can resize a block to change its duration. 4. All changes are saved.

### Story 2.5: Interact with Scheduled Tasks
* **As a** user, **I want** to mark a task as complete directly from my schedule, **so that** I can track my progress.
* **Acceptance Criteria:** 1. Tapping a task block reveals a "Mark Complete" option. 2. Marking a task visually distinguishes it on the timeline. 3. The simple reward message is displayed upon completion.

---