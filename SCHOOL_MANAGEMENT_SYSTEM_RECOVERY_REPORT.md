# School Management System - Technical Recovery Report

This report documents the issues found in the school management system during deployment and provides a roadmap for production-level fixes.

---

## 1. Deployment Issues (Step-by-Step)

### Step 1: Backend Environment Variable Mismatch
*   **The Issue:** In `Backend/config/db.js`, the application attempts to connect using `process.env.MONGODB_URI`. However, the `render.yaml` file (and likely your Render dashboard) defines the variable as `MONGO_URI`.
*   **Result:** The backend fails to connect to MongoDB on deployment. Every request from the app returns a "Connection Error".
*   **Fix:** Ensure both the code and the deployment platform use the same name: `MONGODB_URI`.

### Step 2: Render Free Tier "Cold Start"
*   **The Issue:** Render's Free tier puts your backend to sleep after 15 minutes of inactivity. 
*   **Result:** When the Principal opens the app, the server takes ~30 seconds to wake up. The Flutter app's default timeout is shorter, causing a "Connection Error" before the server is even ready.
*   **Fix:** Use a keep-alive service (like Cron-job.org) to ping your backend every 10 minutes.

### Step 3: Incomplete Data Synchronization
*   **The Issue:** The `OnboardingRepositoryImpl.dart` tries to sync all data (Academic Sessions, Teachers, Fees) immediately after setup. 
*   **Result:** If the server is slow to respond to the first request (due to waking up), the subsequent sync calls for Teachers and Fees are never executed. This is why onboarding data isn't reflecting.

---

## 2. Production Level Bugs

### Styling & Responsiveness
*   **Mobile Overflow Error:** The `PrincipalOnboardingPage` uses a horizontal `Row` for the layout. This works on Web/Desktop but will crash on Android/iOS phones with a "Pixel Overflow" because the screen is too narrow.
*   **Keyboard Overlap:** In several forms, the "Next" button is covered by the software keyboard on smaller devices because the `SingleChildScrollView` does not account for the `bottomInset`.

### Security & Logic
*   **Hardcoded Setup Key:** The access key `123456` is hardcoded in `login_page.dart`. A production system should use a backend-generated or environment-based key.
*   **PIN Update Failure:** The backend controller `updateProfile` updates the `Principal` model but ignores the `User` model where the `securityPin` is actually stored.

### Error Handling
*   **Generic Error Messages:** Returning `Connection error: ${e.toString()}` to the Principal is unprofessional. It should offer a "Retry" button or explain that the server is waking up.

---

## 3. Solutions

### Backend Fixes
1.  **Unified DB Connection:** Update `Backend/config/db.js` to handle both naming conventions:
    `const conn = await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);`
2.  **Fix PIN Update:** Modify `updateProfile` in `userController.js` to also find the `User` and update their `securityPin` if provided.

### Frontend Fixes
1.  **Responsive Layout:** Wrap the `Row` in onboarding pages with a `LayoutBuilder`. If the screen width is less than 600px, use a `Column` instead of a `Row`.
2.  **Retry Logic:** Add a "Retry Sync" button on the Dashboard if local data hasn't been successfully pushed to the server.
3.  **Waking Up Screen:** Implement a "Waking up server..." splash screen that pings the backend and waits for a response before showing the login.

### Infrastructure Fixes
1.  **Keep-Alive:** Set up a free heartbeat monitor to ping your Render URL every 10 minutes to prevent sleep cycles.
2.  **Environment Sync:** Ensure `NODE_ENV` is set to `production` in the Render dashboard.
