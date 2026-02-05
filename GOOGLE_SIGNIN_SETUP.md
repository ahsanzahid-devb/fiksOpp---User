# Google Sign-In Setup (Fix "ApiException: 10" / sign_in_failed)

**Error:** `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)`  
**Meaning:** **DEVELOPER_ERROR** – the app's signing certificate (SHA-1) is not registered in your Firebase/Google Cloud project.

---

## Do this now (one-time)

1. Open Firebase: **https://console.firebase.google.com/project/fiksopp-bb927/settings/general**
2. Scroll to **Your apps** → select the Android app with package **`buzz.inoor.fiksopp`**.
3. Click **Add fingerprint** and add each of these **four** fingerprints (one at a time):

   **Debug (development / `flutter run`):**
   - SHA-1: `D1:38:15:CE:7D:66:1F:0D:A2:D4:EA:91:88:B3:55:B7:2A:3A:3D:56`
   - SHA-256: `   `

   **Release (Play Store / production):**
   - SHA-1: `D2:62:F2:83:23:8A:77:EC:32:15:12:79:F9:04:7C:B7:BA:42:4C:C7`
   - SHA-256: `D4:AA:06:63:14:5B:8F:59:78:D1:06:C9:B7:B2:A9:C2:67:54:E0:06:DF:5C:D7:AF:7D:85:A3:B9:44:88:F0:49`

4. Save. Wait 2–5 minutes, then rebuild and try **Sign In With Google** again.

---

## About the BLASTBufferQueue log spam

Logs like:
```text
E/BLASTBufferQueue(...): acquireNextBufferLocked: Can't acquire next buffer. Already acquired max frames 4 max:2 + 2
```
appear when the app switches to the Google Sign-In screen and back. This comes from the Android graphics stack (SurfaceView/Flutter) and is **harmless** – it does not affect Google Sign-In or app behavior. You can ignore these errors or filter them out in logcat (e.g. exclude tag `BLASTBufferQueue`). There is no code change needed to “fix” them.

---

## Fix (Android) – reference

### 1. Get your app's SHA-1 and SHA-256

**Debug builds (development):**
```bash
cd android
./gradlew signingReport
```
In the output, under **Variant: debug**, copy **SHA-1** and **SHA-256**.

Or with keytool (default debug keystore):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release builds (when you have a release keystore):**
- Use the same `signingReport` with a release build, or  
- Run keytool with your release keystore file and alias.

### 2. Add fingerprints in Firebase

1. Open [Firebase Console](https://console.firebase.google.com/) → your project (**fiksopp-bb927**).
2. Click the gear → **Project settings**.
3. Under **Your apps**, select the Android app with package name **`buzz.inoor.fiksopp`**.
4. Click **Add fingerprint** and add SHA-1 and SHA-256 (see **Do this now** above for your values).
5. Save. If you use Google Sign-In, you may need to wait a few minutes for changes to apply.

### 3. (Optional) Download updated `google-services.json`

- In the same **Project settings** → **Your apps** → your Android app.
- Download **google-services.json** and replace `android/app/google-services.json` in this project.

### 4. Rebuild and test

```bash
flutter clean
flutter pub get
flutter run
```

Then try **Sign In With Google** again.

---

**Summary:** ApiException 10 means Google does not recognize your app's certificate. Register the correct **SHA-1** (and SHA-256) for the build you're using (debug or release) in Firebase for the app **buzz.inoor.fiksopp**, then rebuild.
