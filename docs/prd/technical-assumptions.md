# Technical Assumptions
### Repository Structure: Polyrepo
* The project will start with a single repository for the native iOS application. The backend is managed by a third-party BaaS provider, so a separate backend repository is not needed for the MVP.

### Service Architecture: Serverless
* The application will use a Backend-as-a-Service (BaaS) platform (e.g., Firebase, Supabase). This serverless approach aligns with the MVP's goal of rapid development.

### Testing Requirements: Unit + Integration
* The testing strategy will include both unit tests for individual components and integration tests to verify communication with the BaaS backend.

### Additional Technical Assumptions and Requests
* **Platform & Framework:** The application MUST be a native iOS app built with **SwiftUI**.
* **Architecture Pattern:** The codebase MUST follow the **MVVM (Model-View-ViewModel)** pattern.
* **Backend:** A BaaS is REQUIRED for the MVP.

---