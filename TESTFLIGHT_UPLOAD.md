# Upload App to TestFlight

## Prerequisites

- **Apple Developer account** (enrolled in Apple Developer Program, $99/year)
- **Mac** with Xcode installed (latest stable recommended)
- App configured in **App Store Connect** with the same bundle ID: `buzz.inoor.bookingSystemFlutter`

---

## Step 1: Create the app in App Store Connect (if not done)

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**.
2. Click **+** → **New App**.
3. Choose **iOS**, enter **App Name**, **Primary Language**, **Bundle ID** = `buzz.inoor.bookingSystemFlutter`, **SKU** (e.g. `fiksopp-user-ios`).
4. Create the app. You do **not** need to submit for review to use TestFlight.

---

## Step 2: Build the iOS app (IPA)

From the project root:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build release IPA (this runs pod install and builds for release)
flutter build ipa
```

- First time: Xcode may ask you to **Sign in with Apple ID** and set **Team** (your development team).
- If you see code signing errors, open the project in Xcode and set signing there (see Step 3).

Output IPA is at:  
`build/ios/ipa/booking_system_flutter.ipa`

---

## Step 3: Fix signing in Xcode (if needed)

If `flutter build ipa` fails with signing errors:

1. Open the workspace (not the project):
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select the **Runner** project in the left sidebar → **Signing & Capabilities**.
3. Check **Automatically manage signing**.
4. Select your **Team** (your Apple Developer team).
5. Ensure **Bundle Identifier** is `buzz.inoor.bookingSystemFlutter` and matches App Store Connect.
6. Repeat for the **Runner** target if needed.

Then run again:

```bash
flutter build ipa
```

---

## Step 4: Upload to TestFlight

### Option A: Using Xcode (recommended for first upload)

1. In Xcode: **Product** → **Archive**.
2. When the archive finishes, the **Organizer** window opens.
3. Select the new archive → **Distribute App**.
4. Choose **App Store Connect** → **Upload**.
5. Follow the prompts (default options are fine).
6. Wait for the upload to complete.

### Option B: Using command line (Transporter or xcrun)

1. Install **Transporter** from the Mac App Store, or use `xcrun altool`.
2. Open **Transporter**, sign in with your Apple ID, and drag `build/ios/ipa/booking_system_flutter.ipa` into the window.
3. Click **Deliver** to upload.

### Option C: Using Flutter’s built-in upload (when available)

```bash
flutter build ipa
# Then use Xcode Organizer as in Option A, or Transporter
```

---

## Step 5: After upload

1. In **App Store Connect** → your app → **TestFlight** tab.
2. Wait 5–30 minutes for **Processing** to finish.
3. When the build appears, add **Internal Testing** and/or **External Testing**.
4. For **External Testing**, complete **Export Compliance** and any other required fields (e.g. encryption, content rights).
5. Add testers by email (Internal) or create a public link / group (External).

---

## Quick checklist

- [ ] App created in App Store Connect with bundle ID `buzz.inoor.bookingSystemFlutter`
- [ ] `flutter build ipa` succeeds
- [ ] IPA uploaded via Xcode Organizer or Transporter
- [ ] Build processed in TestFlight
- [ ] Testers added and (if external) compliance info completed

---

## Troubleshooting

| Issue | What to do |
|-------|------------|
| **Code signing errors** | Open `ios/Runner.xcworkspace` in Xcode, set Team and “Automatically manage signing” for Runner. |
| **“No valid signing identity”** | In Xcode: **Xcode** → **Settings** → **Accounts** → select Apple ID → **Download Manual Profiles**. |
| **“Bundle ID already in use”** | Create the app in App Store Connect with this bundle ID, or change the bundle ID in Xcode to match an existing app. |
| **Build not appearing in TestFlight** | Wait up to 30 minutes; check **Activity** in App Store Connect for processing/errors. |
