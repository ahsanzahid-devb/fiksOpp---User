# Google Sign-In Setup (Fix "ApiException: 10" / SHA key configuration)

**Error:** `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)`  
**Meaning:** **DEVELOPER_ERROR** – the app's signing certificate (SHA-1/SHA-256) is not registered in Firebase/Google Cloud for this build.

---

## Your fingerprints (add these in Firebase)

Add **all four** below in Firebase → Project settings → Your apps → **Android** app **`buzz.inoor.fiksopp`** (Google Play package) → **Add fingerprint** (one at a time), then **Save**.

| Variant  | Type    | Fingerprint |
|----------|---------|-------------|
| **Debug**  | SHA-1   | `B3:DB:69:75:8B:A3:66:BA:D0:5C:77:2D:67:67:B0:26:AA:BE:40:26` |
| **Debug**  | SHA-256 | `0C:BB:4C:A5:14:49:44:B0:A0:C0:AC:E0:CC:48:6D:DE:34:8E:37:53:B1:3C:9C:F5:FA:45:A6:DB:F1:27:78:96` |
| **Release** | SHA-1   | `D2:62:F2:83:23:8A:77:EC:32:15:12:79:F9:04:7C:B7:BA:42:4C:C7` |
| **Release** | SHA-256 | `D4:AA:06:63:14:5B:8F:59:78:D1:06:C9:B7:B2:A9:C2:67:54:E0:06:DF:5C:D7:AF:7D:85:A3:B9:44:88:F0:49` |

---

## Quick fix (do this first)

### 1. Get your app’s SHA-1 and SHA-256 (if you need to re-run)

From the **project root** (directory that contains the `android` folder), run this **single** command (do not combine with `flutter clean`):

```bash
cd android && ./gradlew signingReport
```

In the output, find the variant you’re using:

- **Debug** (e.g. `flutter run`) → use **Variant: debug** → copy **SHA-1** and **SHA-256**.
- **Release** (e.g. Play Store build) → use **Variant: release** → copy **SHA-1** and **SHA-256**.

If you use both, add **all four** fingerprints (debug SHA-1, debug SHA-256, release SHA-1, release SHA-256).

### 2. Add them in Firebase

1. Open [Firebase Console](https://console.firebase.google.com/) → your project.
2. Click the **gear** → **Project settings**.
3. Under **Your apps**, select the **Android** app with package **`buzz.inoor.fiksopp`** (must match Play Store / `applicationId`).
4. Click **Add fingerprint** and add **SHA-1** (paste the value from step 1).
5. Click **Add fingerprint** again and add **SHA-256**.
6. Repeat for the other variant (debug/release) if needed.
7. **Save**.

### 3. Wait and test

Wait **2–5 minutes**, then:

```bash
flutter clean && flutter pub get && flutter run
```

Try **Sign in with Google** again.

---

## Alternative: get SHA with keytool

**Debug (default Flutter debug keystore):**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release:** use the same command with your release keystore path, alias, and passwords (e.g. from `android/key.properties`).

Copy the **SHA1** and **SHA-256** lines from the output and add them as fingerprints in Firebase as in step 2 above.

---

## Summary

- **ApiException: 10** = Google doesn’t recognise your app’s certificate.
- Fix: run `cd android && ./gradlew signingReport`, then add the shown **SHA-1** and **SHA-256** in Firebase → Project settings → Your apps → Android app → **Add fingerprint**.
- Use the **debug** variant fingerprints when testing with `flutter run`, and **release** when testing a signed release/Play build.

---

## iOS: Fix “Sign In With Google” crash on App Store review

If the app **crashes when tapping “Sign In With Google”** on iPhone/iPad (e.g. crash in `GIDSignIn signInWithOptions:`), do the following.

### 1. Add GoogleService-Info.plist (required)

1. In [Firebase Console](https://console.firebase.google.com/) → your project → **Project settings**.
2. Under **Your apps**, select your **iOS** app (bundle ID `com.fiksopp.fiksopp` or whatever your iOS bundle ID is). If you don’t have an iOS app, click **Add app** → **iOS**, register the bundle ID, then download the config.
3. Download **GoogleService-Info.plist**.
4. Put it in: **`ios/Runner/GoogleService-Info.plist`** (same folder as `Info.plist`).
5. In Xcode: right‑click **Runner** → **Add Files to "Runner"** → select `GoogleService-Info.plist` and ensure **Copy items if needed** and **Runner** target are checked.

### 2. Set the URL scheme in Info.plist

1. Open **GoogleService-Info.plist** and find the key **`REVERSED_CLIENT_ID`** (or `CLIENT_ID`; the scheme is the reversed client ID, e.g. `com.googleusercontent.apps.123456-xxxx.apps.googleusercontent.com` → use the value as in the plist).
2. Open **`ios/Runner/Info.plist`**.
3. Find **`CFBundleURLTypes`** → **`CFBundleURLSchemes`** → the string that looks like `com.googleusercontent.apps.REPLACE_WITH_YOUR_IOS_CLIENT_ID`.
4. **Replace** that string with the **exact** value of **`REVERSED_CLIENT_ID`** from **GoogleService-Info.plist** (e.g. `com.googleusercontent.apps.123456789-abcdefg`).
5. Save and rebuild: `flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run`.

Without step 1 and 2, Google Sign-In on iOS will crash as soon as the user taps “Sign In With Google”.
