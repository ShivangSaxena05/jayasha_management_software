# School Management System - Final Production Report

This report outlines the technical issues, bugs, and solutions for the **Jayasha Children's Academy** management system (Principal Purpose).

---

## 1. Deployment Issues (Step-by-Step)

### Step 1: Database Connection Mismatch
*   **Location:** `Backend/config/db.js` vs `render.yaml`
*   **Issue:** The backend code expects `process.env.MONGODB_URI`, but the deployment environment provides `MONGO_URI`.
*   **Impact:** The server starts but cannot talk to the database. All API calls fail immediately.

### Step 2: Render Free Tier "Cold Start"
*   **Issue:** The free instance on Render spins down after 15 minutes of inactivity.
*   **Impact:** When the Principal opens the app, the first request triggers a "Wake Up" that takes 30+ seconds. The Flutter app's default timeout is shorter, causing the "Connection Error" screen.

### Step 3: Sequential Sync Failure
*   **Location:** `lib/features/auth/data/repositories/onboarding_repository_impl.dart`
*   **Issue:** `syncOnboardingData` calls 3-4 separate APIs one after another.
*   **Impact:** If the first call (Academic Session) fails or hangs, the app stops syncing. This is why Teachers and Fee data are missing on the dashboard.

---

## 2. Production-Level Bugs

### Security Bugs
*   **Hardcoded Setup Key:** In `login_page.dart`, the administrative setup key is `123456`. This is easily guessable and hardcoded in the source code.
*   **PIN Update Logic:** The `updateProfile` function in `userController.js` updates the Principal's bio but does **not** update the `securityPin` in the `User` collection.

### Styling & Responsive Bugs
*   **Onboarding Layout:** The `PrincipalOnboardingPage` uses a horizontal `Row` for the form. This will cause a **Pixel Overflow** crash on mobile phones (Android/iOS). It only works on Web/Tablet currently.
*   **Keyboard Overlap:** In the "Contact Information" step, the text fields for address are at the bottom. When the keyboard opens, it covers the "Next" button.

### Error Handling Bugs
*   **Generic Messages:** Most repositories return `Connection error: ${e.toString()}`. This is not helpful for the Principal. It should say "Server is starting up, please wait..."

---

## 3. Recommended Solutions

### Solution 1: Backend Connection Fix
Modify `Backend/config/db.js` to handle both naming conventions:
```javascript
const conn = await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);
```

### Solution 2: Prevent Server Sleep
*   Use a free service like **Cron-job.org** to hit your backend URL every 10 minutes. This keeps the server "warm" so the Principal never sees a connection error.

### Solution 3: Robust Onboarding Sync
*   Wrap each sync step in a separate `try-catch` block.
*   Add a "Syncing..." overlay in the UI with a progress bar so the user knows to wait.

### Solution 4: Responsive UI Fix
Update `PrincipalOnboardingPage.dart` to use a `Column` if the screen width is less than 600 pixels:
```dart
// Suggestion
child: MediaQuery.of(context).size.width > 600 
    ? Row(children: [...]) 
    : Column(children: [...])
```

### Solution 5: Secure Setup
*   Move the `123456` key to a Backend environment variable.
*   The `isSchoolSetup` API should return whether setup is allowed based on a secret key.
