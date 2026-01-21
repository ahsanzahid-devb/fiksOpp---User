# Privacy Policy Requirement - Google Play Console

## Issue
Your app uses the `CAMERA` permission, which requires a privacy policy URL in Google Play Console.

## Solution

### Step 1: Create Your Privacy Policy

1. **Use the template:** `PRIVACY_POLICY_TEMPLATE.md` (already created)
2. **Customize it** with your actual information:
   - Replace `[Your Contact Email]` with your support email
   - Replace `[Your Business Address]` with your address
   - Replace `[Date]` with current date
   - Add any other specific details about your app

### Step 2: Host Your Privacy Policy

You need to publish your privacy policy on a publicly accessible website. Options:

**Option A: Your Own Website**
- Upload the privacy policy to your website
- Example: `https://yourwebsite.com/privacy-policy`
- Make sure it's accessible without login

**Option B: Free Hosting Services**
- **GitHub Pages** (free)
  - Create a repository
  - Enable GitHub Pages
  - Upload your privacy policy as `privacy-policy.html` or `privacy-policy.md`
  - URL will be: `https://yourusername.github.io/repository-name/privacy-policy`

- **Google Sites** (free)
  - Create a Google Site
  - Add your privacy policy content
  - Publish and get the URL

- **Notion** (free)
  - Create a public Notion page
  - Add your privacy policy
  - Share as public link

**Option C: Use a Privacy Policy Generator**
- Search for "free privacy policy generator" online
- Fill in your app details
- Generate and host the policy

### Step 3: Add Privacy Policy URL to Google Play Console

1. Go to **Google Play Console**
2. Navigate to **Policy** → **App content**
3. Find **Privacy Policy** section
4. Enter your privacy policy URL
5. Click **Save**

### Step 4: Required Permissions Justification

Since you're using `CAMERA` permission, make sure your privacy policy explains:

✅ **Why you collect camera data:**
- Taking profile pictures
- Uploading service images
- Sharing photos in chat
- Document scanning (if applicable)

✅ **How you use camera data:**
- Stored securely on Firebase/your servers
- Only used for app functionality
- Not shared with third parties (except as needed for app functionality)

✅ **User control:**
- Users can deny camera permission
- Users can delete photos they upload
- Camera is only accessed when user explicitly takes a photo

## Quick Privacy Policy URL Format

Your privacy policy URL should look like:
```
https://yourwebsite.com/privacy-policy
```

Or if using GitHub Pages:
```
https://yourusername.github.io/fiksOpp-privacy/privacy-policy
```

## Important Notes

⚠️ **The privacy policy must be:**
- Publicly accessible (no login required)
- Accessible via HTTPS (secure connection)
- Written in the same language as your app (or include English)
- Complete and accurate

⚠️ **You cannot submit your app without a privacy policy URL** if you use sensitive permissions like:
- CAMERA
- LOCATION
- CONTACTS
- MICROPHONE
- etc.

## Next Steps

1. ✅ Update version code (already done - changed to 112)
2. ⚠️ Create and host privacy policy
3. ⚠️ Add privacy policy URL to Google Play Console
4. ⚠️ Rebuild your app with new version code (112)
5. ⚠️ Upload the new build to Google Play Console

## Version Code Updated

✅ **Version code changed from 111 to 112**
- `pubspec.yaml`: Updated to `11.14.3+112`
- `android/app/build.gradle`: Updated to `versionCode 112`

Now rebuild your app and upload the new version!

