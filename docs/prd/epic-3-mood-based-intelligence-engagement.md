# Epic 3: Mood-Based Intelligence & Engagement
**Epic Goal:** This final epic for the MVP introduces the app's signature feature: mood-based task suggestions. It builds upon the functional scheduler from Epic 2, adding a layer of intelligence and empathy to boost genuine productivity and user satisfaction.

### Story 3.1: Mood & Energy Check-in
* **As a** user, **I want** a simple way to tell the app how I'm feeling, **so that** I can get relevant task suggestions.
* **Acceptance Criteria:** 1. A user can open a simple mood/energy selector. 2. The selector presents clear options (e.g., "Energetic", "Tired"). 3. The selection is captured for generating suggestions.

### Story 3.2: Associate Tasks with Energy Levels
* **As a** user, **I want** to optionally categorize my tasks by the energy they require, **so that** the app can make smart suggestions.
* **Acceptance Criteria:** 1. When creating/editing a task, a user can optionally assign an energy level. 2. The default is "Any". 3. The energy level is saved to the backend.

### Story 3.3: Task Suggestion Engine
* **As a** user with free time, **I want** the app to suggest what to do based on my current mood, **so that** I can avoid decision fatigue.
* **Acceptance Criteria:** 1. After a user reports their mood, the app filters their "Flexible" tasks. 2. The app presents a short list (1-3) of tasks matching the mood and energy tag. 3. A friendly message is shown if no tasks match.

### Story 3.4: Add Suggested Task to Schedule
* **As a** user, **I want** to quickly add a suggested task to my schedule with a single tap, **so that** I can easily act on the recommendation.
* **Acceptance Criteria:** 1. Tapping a suggested task adds it to the corresponding time block on the schedule. 2. The new task block is saved. 3. The block can be moved, edited, or marked complete.