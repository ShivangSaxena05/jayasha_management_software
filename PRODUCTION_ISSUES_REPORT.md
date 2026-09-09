# School Management System - Production Issue Report

## Priority 1: Critical Deployment Issues

### 1. Database Connection Failure (Backend)
- **Issue:** Mismatch between defined environment variable in `render.yaml` (`MONGO_URI`) and the code in `config/db.js` (`MONGODB_URI`).
- **Status:** Critical - Prevents all data operations.
- **Solution:** Rename the variable to `MONGODB_URI` in the Render dashboard.

### 2. Connection Timeout (Frontend)
- **Issue:** "Connection error" appears because the Render Free tier spins down. The app times out before the server wakes up.
- **Solution:** Add a ping/heartbeat mechanism or upgrade to a 'Starter' plan. Implement a retry mechanism in `StudentRepositoryImpl`.

### 3. Onboarding Data Reflection
- **Issue:** Data entered during onboarding is saved locally but the server sync fails silently if the network is unstable.
- **Solution:** Implement a Sync Queue that retries failed uploads in the background.

## Priority 2: Security & Logic Bugs

### 1. Hardcoded Access Key
- **File:** `lib/features/auth/presentation/pages/login_page.dart`
- **Issue:** Setup key `123456` is hardcoded.
- **Risk:** Anyone who downloads the app can reset the school data if they find this key.

### 2. PIN Update Lag
- **Issue:** When the PIN is updated, the local `SharedPreferences` is updated immediately, but the server response isn't verified.
- **Solution:** Only update local state AFTER a successful `200 OK` response from the `/api/users/profile` endpoint.

## Priority 3: UI & UX (Production Level)

### 1. Responsiveness
- **Issue:** Fixed max-widths on containers might cause issues on extremely small devices or landscape mode.
- **Solution:** Use `MediaQuery` to calculate width percentages instead of fixed pixels (450px).

### 2. Error Handling
- **Issue:** Generic "Connection error" message gives no info to the Principal on how to fix it.
- **Solution:** Replace with: "Server is waking up, please wait a moment..." with a progress bar.

---

## Suggested Solutions Summary

1. **Backend:** Change `process.env.MONGODB_URI` to `process.env.MONGO_URI || process.env.MONGODB_URI` in `config/db.js` for compatibility.
2. **Frontend:** Update `ApiConfig` to include a timeout duration using `http.Client`.
3. **Onboarding:** In `OnboardingRepositoryImpl`, add `await` for each sync step and verify `isSetup` after every step.
