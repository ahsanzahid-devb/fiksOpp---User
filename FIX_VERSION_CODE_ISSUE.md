# Fix: Version Code Shadowing Issue

## Problem
Your APK/AAB is being "shadowed" by an existing version with a higher version code in Google Play Console.

## Solution

### Step 1: Check Current Version Codes in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (FiksOpp)
3. Go to **"Release"** → **"Production"** (or **"Testing"** if you're in testing)
4. Check what version codes are already uploaded
5. Note the **highest version code** you see

### Step 2: Update Version Code to Higher Number

You need to set your version code to be **higher** than any existing version in Google Play Console.

**Current status:**
- `pubspec.yaml`: version code 113
- `build.gradle`: version code 112
- **These need to match and be higher than what's in Google Play**

**Recommended:** Use version code **114** or higher (depending on what's in Google Play)

### Step 3: Remove Old APKs (If Needed)

If you have multiple APKs/AABs with conflicting version codes:

1. In Google Play Console, go to **"Release"** → **"Production"** (or your release track)
2. Click on the release
3. Find APKs/AABs with lower version codes
4. Click **"Remove"** or **"Delete"** on the old ones
5. Keep only the one with the highest version code

### Step 4: Update Your Build Files

✅ **Updated both files to version code 114:**
- `pubspec.yaml`: Changed to `11.14.3+114`
- `android/app/build.gradle`: Changed to `versionCode 114`

**If version 114 is still too low**, increase it further (115, 116, etc.) based on what you see in Google Play Console.

### Step 5: Rebuild Your App

1. Clean your build:
   ```bash
   flutter clean
   ```

2. Build the app bundle:
   ```bash
   flutter build appbundle
   ```

3. The AAB file will be in: `build/app/outputs/bundle/release/app-release.aab`

### Step 6: Upload to Google Play Console

1. Go to Google Play Console → Your App → Release
2. Create a new release or edit existing one
3. Upload the new AAB file (version code 114)
4. Make sure to remove any old APKs/AABs with lower version codes from the same release

## Understanding Version Codes

- **Version Code** = Internal number (must always increase)
- **Version Name** = User-visible version (e.g., "11.14.3")

**Rule:** Each new upload must have a version code **higher** than all previous uploads.

## Common Scenarios

### Scenario 1: You have version 111 in Production
- ✅ Use version code 112 or higher
- Current fix: Using 114 (safe)

### Scenario 2: You have version 113 in Testing
- ✅ Use version code 114 or higher
- Current fix: Using 114 (matches)

### Scenario 3: You accidentally uploaded multiple versions
- Remove all old versions from the release
- Keep only the highest version code
- Upload new one with even higher code

## Quick Checklist

- [ ] Checked version codes in Google Play Console
- [ ] Updated `pubspec.yaml` to version code 114 (or higher)
- [ ] Updated `build.gradle` to version code 114 (or higher)
- [ ] Removed old APKs/AABs with lower version codes (if any)
- [ ] Rebuilt app with `flutter build appbundle`
- [ ] Uploaded new AAB to Google Play Console
- [ ] Verified new version code is higher than all existing ones

## If Still Getting Error

1. **Check all release tracks:**
   - Production
   - Testing (Internal, Closed, Open)
   - Any draft releases

2. **Increase version code further:**
   - If highest in console is 115, use 116
   - If highest is 120, use 121
   - Always go higher!

3. **Remove conflicting versions:**
   - Delete/remove all APKs/AABs from the release
   - Upload fresh with new version code

---

**Files Updated:**
- ✅ `pubspec.yaml`: Now `11.14.3+114`
- ✅ `android/app/build.gradle`: Now `versionCode 114`

**Next Step:** Rebuild and upload!

