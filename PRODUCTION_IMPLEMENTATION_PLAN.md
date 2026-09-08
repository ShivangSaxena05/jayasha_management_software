# Structured Implementation Plan: Jayasha Children's Academy
**Focus:** Principal-Centric Synchronization (Onboarding to Production App)

This plan ensures a seamless connection between the initial school setup (Onboarding) and the operational pages within the app, strictly following the existing frontend architecture and backend schemas.

---

## 1. Onboarding to Schema Mapping (Direct Sync)
Ensure every form field in the onboarding flow correctly updates the corresponding MongoDB document.

### 1.1 Authentication & Principal Setup
*   **Source:** `SecurityPinOnboardingPage` & `PrincipalOnboardingPage`
*   **Targets:** `User.js` (Auth) and `Principal.js` (Profile)
*   **Sync Logic:**
    - The `SecurityPin` from the first screen must be hashed and stored in `User.securityPin`.
    - `PrincipalProfile` fields (Name, Phone, Qualification, etc.) must be linked via `principalSchema.user` ObjectId.
    - **Action:** Modify `setupPrincipal` in `onboarding_repository_impl.dart` to be the final trigger that sends the *entire* collected local state to the backend in a single transaction or sequential verified calls.

### 1.2 Academic Structure Sync
*   **Source:** `AcademicOnboardingPage`
*   **Targets:** `AcademicSession.js` and `Class.js`
*   **Sync Logic:**
    - `sessionName` (e.g., 2024-25) maps to `AcademicSession.sessionName`.
    - The list of `selectedClasses` must create multiple `Class` documents, each referencing the `AcademicSession` ID.
    - **Action:** Ensure the `Class` documents in the backend include the `sections` array as defined in the frontend dialog (Section A, B, etc.).

### 1.3 Staff & Fee Integration
*   **Source:** `TeacherOnboardingPage` & `FeeStructureOnboardingPage`
*   **Targets:** `Teacher.js` and `FeeStructure.js`
*   **Sync Logic:**
    - Teachers added during onboarding must be automatically assigned the `active` status in the DB.
    - Fee components (Tuition, Admission, Exam) must be linked to both the `AcademicSession` ID and the `Class` ID generated in step 1.2.

---

## 2. Global State & Page Synchronization
Bridging the gap so that internal pages reflect onboarding data immediately.

### 2.1 Admission Module Sync
*   **Dependency:** `Student.js` requires a `Class` and `AcademicSession`.
*   **Implementation:**
    - The `AdmissionPage` dropdowns for "Class" and "Section" must fetch data directly from the `Class.js` collection created during onboarding.
    - If no classes were selected in onboarding, the `AdmissionPage` should redirect the Principal back to Academic Setup.

### 2.2 Dashboard Financials
*   **Dependency:** `FeeStructure.js` and `FeePayment.js`.
*   **Implementation:**
    - The Dashboard "Expected Collection" must calculate: `(Number of Students in Class X) * (FeeStructure for Class X)`.
    - This ensures the Principal sees immediate financial projections based on the onboarding fee configuration.

### 2.3 Staff & Payroll Sync
*   **Dependency:** `Teacher.js` baseSalary and `SalaryRecord.js`.
*   **Implementation:**
    - The "Staff Management" list must populate from the onboarding teachers.
    - The "Process Salary" button should use the `baseSalary` defined during the onboarding step for each teacher.

---

## 3. Connection & Data Integrity (Error Handling)
Ensure the connection between the "First Login" and the app doesn't break.

### 3.1 The "Setup Flag" Check
*   The app must check `isSchoolSetup()` on every launch. 
*   If `User` exists but `Principal` details or `AcademicSession` are missing (incomplete onboarding), the app must resume at the specific missing step.

### 3.2 Secure PIN Re-auth
*   `loginWithPin` must not just return a token, but also verify the `role` is 'principal'.
*   Upon login, the app should sync `Principal` details from the server to local `SharedPreferences` to ensure the "Inside App" profile pages are always up-to-date with the database.

---

## 4. Technical Checklist for Implementation

### Backend (Node.js/MongoDB)
- [x] **Validation:** Update `userController.js` to ensure a Principal cannot be created without valid profile details (Implemented with Transactions).
- [x] **Cascading Deletes:** The `reset-setup` route must clean all 14 schemas to prevent orphan records during development testing.
- [x] **Unique Constraints:** Ensure `admissionNumber` and `rollNumber` are scoped within the `AcademicSession`.

### Frontend (Flutter)
- [x] **Model Alignment:** Refactor `lib/core/models/student.dart` and `student_admission.dart` to match `Student.js` (Father/Mother Name, DOB, Guardian Phone) to ensure Admission sync doesn't fail.
- [x] **Session Recovery:** Implement auto-logout and redirect on `401 Unauthorized` (Token Expired) to prevent dashboard hangs.
- [x] **Repository Refactor:** Update `syncOnboardingData` in `OnboardingRepositoryImpl` to handle sequential dependencies (Session -> Classes -> Fees).
- [x] **UI Safety:** Implement "Finalizing Setup" loading overlay in `SecurityPinOnboardingPage` to protect sync operations.
