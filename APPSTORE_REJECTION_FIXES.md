# App Store Rejection Fixes (Guidelines 4.8, 2.1, 2.1a)

This file summarizes the three rejection reasons and what was done (or what you must do) to fix them.

---

## 1. Guideline 4.8 – Sign in with Apple (Design – Login Services)

**Issue:** The app uses a third-party login (Google) and must offer an **equivalent** login option that meets Apple’s privacy requirements. **Sign in with Apple** qualifies.

**What was done in code:**

- Sign in with Apple was already implemented.
- The sign-in screen was updated so that **on iOS**, the **Sign in with Apple** button is shown whenever **Sign in with Google** is available (in addition to when Apple login is enabled in your app config). So reviewers (and users) on iPhone/iPad always see Apple as an equivalent option next to Google.

**What you should do:**

- In your backend/app configuration, ensure **Apple login is enabled** for the app (so the Apple button is shown).
- In App Store Connect → App Review, you can reply:  
  *“We offer Sign in with Apple as an equivalent login option on the login screen (visible on iOS whenever Google sign-in is shown). Sign in with Apple limits data to name and email, allows users to hide their email, and does not use app interactions for advertising without consent, satisfying Guideline 4.8.”*

---

## 2. Guideline 2.1 – Demo account (Information Needed)

**Issue:** The demo account (e.g. `demouser2@gmail.com` / `12345678`) did not work, so reviewers could not sign in and test the app.

**What you must do:**

1. In **App Store Connect** → your app → **App Information** (or the version’s **Review Information**), open **Sign-in required** / **Demo account**.
2. Enter a **valid** username and password that:
   - Successfully signs in to the app, and
   - Gives **full access** to the features you want reviewed (bookings, payments, etc.).
3. If the previous account was locked or the password wrong, create a new test user in your backend and use those credentials.
4. Optionally add a short note for the reviewer (e.g. “Use this account to test booking and payment flows”).

---

## 3. Guideline 2.1(a) – Crash when tapping “Sign In With Google” (Performance)

**Issue:** The app crashed when the reviewer tapped **Sign In With Google** on iPad/iPhone (crash in `GIDSignIn signInWithOptions:`).

**Cause:** On iOS, Google Sign-In requires:

1. **GoogleService-Info.plist** in the app (with your iOS client config).
2. A **URL scheme** in **Info.plist** set to the **REVERSED_CLIENT_ID** from that plist.

If either is missing or wrong, the native Google Sign-In SDK can crash.

**What was done in code:**

- **Info.plist** was updated to include **CFBundleURLTypes** / **CFBundleURLSchemes** with a **placeholder** value:  
  `com.googleusercontent.apps.REPLACE_WITH_YOUR_IOS_CLIENT_ID`

**What you must do:**

1. **Add GoogleService-Info.plist**
   - Firebase Console → your project → Project settings → iOS app (bundle ID e.g. `com.fiksopp.fiksopp`).
   - Download **GoogleService-Info.plist** and add it to **`ios/Runner/`** and to the Xcode **Runner** target.

2. **Set the correct URL scheme**
   - Open **GoogleService-Info.plist** and copy the value of **`REVERSED_CLIENT_ID`**.
   - Open **`ios/Runner/Info.plist`**, find **CFBundleURLTypes** → **CFBundleURLSchemes** → the string that contains `REPLACE_WITH_YOUR_IOS_CLIENT_ID`.
   - Replace that **entire** scheme string with the **exact** **REVERSED_CLIENT_ID** value (e.g. `com.googleusercontent.apps.123456789-abcdefg`).
   - Save.

3. **Test on a real device**
   - Build and run on an iPhone or iPad:  
     `flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run`
   - Tap **Sign In With Google** and complete the flow. It should no longer crash.

Detailed steps are also in **GOOGLE_SIGNIN_SETUP.md** (iOS section).

---

## Checklist before resubmitting

- [ ] **GoogleService-Info.plist** is in `ios/Runner/` and in the Runner target.
- [ ] **Info.plist** URL scheme is set to your real **REVERSED_CLIENT_ID** (no placeholder).
- [ ] **Sign in with Google** tested on a real iOS device – no crash.
- [ ] **Sign in with Apple** visible on the login screen on iOS and working.
- [ ] **Demo account** in App Store Connect is valid and has full access; note for reviewer added if helpful.

After that, resubmit the app and, if needed, reply in App Review with the points above (especially 4.8 and the demo account).
