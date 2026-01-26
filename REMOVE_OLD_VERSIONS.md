# How to Remove Old App Bundles from Google Play Console

## Current Situation

You have 3 app bundles in your release:
- ✅ **Version 114** - This is the active one (highest version code)
- ❌ **Version 112** - Being shadowed (remove this)
- ❌ **Version 111** - Being shadowed (remove this)

## Solution: Remove Versions 111 and 112

### Step-by-Step Instructions

1. **Go to Your Release**
   - In Google Play Console, you're already on the release page
   - Scroll down to the "New app bundles" section

2. **Remove Version 111**
   - Find the app bundle with version code **111 (11.14.3)**
   - Click the **three dots (⋮)** or **menu icon** next to it
   - Select **"Remove"** or **"Delete"**
   - Confirm the removal

3. **Remove Version 112**
   - Find the app bundle with version code **112 (11.14.3)**
   - Click the **three dots (⋮)** or **menu icon** next to it
   - Select **"Remove"** or **"Delete"**
   - Confirm the removal

4. **Keep Version 114**
   - Leave version **114 (11.14.3)** in the release
   - This is your active version

5. **Save the Release**
   - Click **"Save"** or **"Review release"** at the bottom
   - The errors should disappear once you remove the old versions

## Visual Guide

**Before (Current):**
```
App bundle 111 (11.14.3) ❌ Remove this
App bundle 112 (11.14.3) ❌ Remove this  
App bundle 114 (11.14.3) ✅ Keep this
```

**After (Fixed):**
```
App bundle 114 (11.14.3) ✅ Only this one
```

## About the Warnings

The warnings about "deobfuscation file" are **not critical errors**. They're just recommendations:
- They help with crash reporting
- Your app will work fine without them
- You can address these later if needed

**For now, focus on removing the old versions to fix the errors.**

## After Removing Old Versions

Once you remove versions 111 and 112:
- ✅ The 2 errors will disappear
- ✅ Only version 114 will remain (the active one)
- ✅ You can proceed with your release
- ⚠️ The 3 warnings will remain (but they're not blocking)

## Next Steps After Fixing

1. Remove versions 111 and 112
2. Save the release
3. Review and confirm the release
4. Your app will be ready to publish!

---

**Note:** If you can't find the remove/delete option, look for:
- Three dots menu (⋮)
- Trash icon
- "Remove from release" option
- Or try editing the release and unchecking the old versions

