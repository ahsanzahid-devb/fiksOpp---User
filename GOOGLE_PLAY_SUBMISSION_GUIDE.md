# Google Play Console Submission Guide for FiksOpp

## App Information Summary

**App Name:** FiksOpp  
**Package Name (Android / Google Play):** `buzz.inoor.fiksopp` — **must match** the app already in Play Console (you cannot change this for an existing listing).  
**iOS bundle ID (App Store):** `com.fiksopp.fiksopp` — different from Android; that is normal.  
**Current Version:** see `pubspec.yaml` (`version: x.y.z+build` → `build` is the Play **version code**).  
**App Type:** Service Booking/Handyman Platform  
**Pricing:** Free

### Can I change the package name on Google Play?

**No.** The application ID is fixed for that store listing forever. To use `com.fiksopp.fiksopp` on Play you would need a **new** app (new listing; users would install a separate app).

**Firebase:** Register an Android app with package **`buzz.inoor.fiksopp`** in the same Firebase project (or keep one Android client per package). Download **`google-services.json`** from Firebase after adding that app and replace `android/app/google-services.json`. Add your **release SHA-1/SHA-256** (and Play App Signing certificate) under that Android app.

**Version code:** Each upload must use a **new, higher** `version` build number in `pubspec.yaml` than any version already uploaded to Play.

---

## Google Play Console Form - Detailed Answers

### 1. App Details

#### App Name
```
FiksOpp
```
*(8 characters - within 30 character limit)*

#### Default Language
```
English (United Kingdom) – en-GB
```

#### App or Game
```
App
```
*(This is a service booking application, not a game)*

#### Free or Paid
```
Free
```
*(You can change this later if needed)*

---

## 2. App Description (Short - 80 characters max)

```
Connect with trusted service providers. Book, chat, and pay seamlessly.
```

---

## 3. Release Notes (500 characters max)

**IMPORTANT:** Release notes are different from the app description. They should be short and tell users what's new in this version.

**For Initial Release:**
```
<en-GB>
FiksOpp - Your trusted service booking platform. Find verified providers, post job requests, browse services by category, chat in real-time, and pay securely. Features include wallet system, booking management, ratings, Google Maps integration, and multi-language support. Start booking services today!
</en-GB>
```

*See RELEASE_NOTES.md for more options and future update examples.*

---

## 4. Full Description (4000 characters max)

```
FiksOpp - Your Trusted Service Booking Platform

FiksOpp is a comprehensive service booking application that connects users with verified service providers and handymen. Whether you need home repairs, maintenance, cleaning, or any professional service, FiksOpp makes it easy to find, book, and manage services all in one place.

KEY FEATURES:

📋 Post Job Requests
Create detailed job postings with descriptions, categories, and budget. Service providers can bid on your requests, giving you the power to choose the best professional for your needs.

🔍 Browse Services
Explore a wide range of services organized by categories and subcategories. View detailed service information, pricing, provider profiles, and customer reviews before making a booking.

👥 Find Trusted Providers
Browse verified service providers and handymen in your area. View their profiles, ratings, reviews, service history, and portfolio to make informed decisions.

💬 Real-Time Chat
Communicate directly with service providers through our built-in chat system. Share images, files, and discuss service details before and during the booking.

💳 Multiple Payment Options
Pay securely using various payment methods including:
• Credit/Debit Cards (Stripe)
• Digital Wallets (Razorpay, PhonePe, PayPal)
• Cash on Delivery
• In-App Wallet
• And many more regional payment gateways

💰 Wallet System
Top up your in-app wallet for quick and easy payments. Track your transaction history and manage your balance effortlessly.

📅 Booking Management
Track all your bookings in one place. View booking status, service details, provider information, and manage your appointments with ease.

⭐ Ratings & Reviews
Rate and review service providers after completion. Help build a trusted community by sharing your experiences.

🗺️ Location Services
Find nearby service providers using integrated Google Maps. Get accurate location-based results and directions.

🔔 Push Notifications
Stay updated with real-time notifications about booking status, provider responses, payment confirmations, and more.

🌙 Dark Mode
Enjoy a comfortable viewing experience with our dark mode feature, perfect for low-light environments.

🌍 Multi-Language Support
Use the app in your preferred language for a personalized experience.

🔐 Secure Authentication
Sign in using email, Google, Apple ID, or phone number (OTP) for quick and secure access.

📱 User-Friendly Interface
Experience a modern, intuitive interface designed for seamless navigation and optimal user experience.

PRIVACY & SECURITY:
Your data security is our priority. We use industry-standard encryption and follow best practices to protect your personal information and payment details.

SUPPORT:
Need help? Our dedicated support team is available through the in-app help desk feature. Get assistance with bookings, payments, or any other queries.

Download FiksOpp today and experience the convenience of booking professional services at your fingertips!
```

---

## 5. Privacy Policy URL

You need to provide a publicly accessible privacy policy URL. This should be hosted on your website and include:
- What data you collect
- How you use the data
- Data sharing practices
- User rights
- Contact information

**Example format:**
```
https://yourwebsite.com/privacy-policy
```

---

## 6. App Category

**Primary Category:**
```
Lifestyle
```
OR
```
Productivity
```

**Secondary Category (Optional):**
```
Business
```

---

## 7. Content Rating Questionnaire

You'll need to answer questions about:
- **Violence:** None (Service booking app)
- **Sexual Content:** None
- **Profanity:** None
- **Alcohol/Tobacco:** None
- **Gambling:** None
- **Location Sharing:** Yes (for finding nearby providers)
- **User Communication:** Yes (in-app chat)
- **User-Generated Content:** Yes (reviews, ratings, job posts)
- **Purchases:** Yes (service bookings, in-app wallet)

**Expected Rating:** Everyone / 3+

---

## 8. Target Audience

**Age Group:**
```
18+ (or All Ages if appropriate)
```

**Target Audience:**
```
General public looking for service providers and handymen
```

---

## 9. Store Listing Assets Required

### App Icon
- **Size:** 512 x 512 pixels
- **Format:** PNG (32-bit)
- **Location:** `assets/images/app_logo.png`

### Feature Graphic
- **Size:** 1024 x 500 pixels
- **Format:** PNG or JPG
- **Purpose:** Banner shown at the top of your Play Store listing

### Screenshots
- **Phone:** At least 2, up to 8 screenshots
- **Size:** 16:9 or 9:16 aspect ratio
- **Minimum:** 320px, **Maximum:** 3840px
- **Format:** PNG or JPG (24-bit)

**Recommended Screenshots:**
1. Home/Dashboard screen
2. Service listing screen
3. Booking details screen
4. Chat interface
5. Payment screen
6. Provider profile screen
7. Job posting screen
8. Booking history screen

### Promotional Video (Optional)
- **Format:** YouTube URL
- **Length:** 30 seconds to 2 minutes
- **Purpose:** Showcase app features

---

## 10. Declarations

### Developer Programme Policies
✅ **Confirm:** The application meets the Developer Programme Policies

**Key Points to Ensure:**
- No misleading content
- Accurate app description
- Proper permissions usage
- Privacy policy accessible
- No prohibited content
- Proper handling of user data

### US Export Laws
✅ **Accept:** I acknowledge that my software application may be subject to United States export laws...

**Note:** Since your app uses encryption (HTTPS, Firebase, payment gateways), you may need to complete the US Export Compliance form.

---

## 11. Permissions Justification

Your app requests these permissions (from AndroidManifest.xml):

| Permission | Justification |
|------------|---------------|
| INTERNET | Required for API calls, Firebase, and online features |
| ACCESS_NETWORK_STATE | Check network connectivity |
| CAMERA | Take photos for profile, service images, and chat |
| ACCESS_FINE_LOCATION | Find nearby service providers using Google Maps |
| ACCESS_COARSE_LOCATION | Approximate location for service matching |
| POST_NOTIFICATIONS | Send push notifications for bookings and messages |
| RECORD_AUDIO | Voice messages in chat (if implemented) |
| BLUETOOTH / BLUETOOTH_ADMIN / BLUETOOTH_CONNECT | For Bluetooth devices (if needed for services) |

**Privacy Policy Must Include:**
- Why you collect location data
- How location data is used
- Whether location is shared with third parties
- How users can control location sharing

---

## 12. Data Safety Section

You'll need to declare:

**Data Collected:**
- ✅ Personal info (name, email, phone)
- ✅ Financial info (payment methods, transaction history)
- ✅ Location (for finding nearby providers)
- ✅ Photos and videos (profile, service images)
- ✅ Files and docs (chat attachments)
- ✅ App activity (booking history, interactions)

**Data Sharing:**
- Payment processors (Stripe, Razorpay, etc.)
- Firebase (analytics, crash reporting)
- Google Maps (location services)

**Data Security:**
- Data encrypted in transit (HTTPS)
- Data encrypted at rest (Firebase)
- Users can request data deletion

---

## 13. App Content Rating

Based on your app's features:
- **PEGI:** 3
- **ESRB:** Everyone
- **No age restrictions** (unless you have specific content that requires it)

---

## 14. Pricing & Distribution

### Pricing
- **Free:** Yes (with in-app purchases for services)

### Countries/Regions
- Select all countries where you want to distribute
- Or select specific regions based on your target market

### Device Categories
- ✅ Phones
- ✅ Tablets (if supported)
- ✅ TV (if supported)
- ✅ Wear OS (if supported)
- ✅ Chrome OS (if supported)

---

## 15. Pre-Launch Checklist

Before submitting, ensure:

- [ ] App is fully tested on multiple devices
- [ ] All features work correctly
- [ ] No crashes or critical bugs
- [ ] Privacy policy is published and accessible
- [ ] Terms of service are available
- [ ] App icon and screenshots are ready
- [ ] Feature graphic is designed
- [ ] App description is proofread
- [ ] All permissions are justified
- [ ] Data safety section is completed
- [ ] Content rating questionnaire is completed
- [ ] App signing key is properly configured
- [ ] Version code and name are correct
- [ ] Firebase configuration is correct
- [ ] Google Maps API key is configured
- [ ] Payment gateways are properly configured
- [ ] Test accounts are created (if needed for review)

---

## 16. Post-Submission

After submitting:

1. **Review Process:** Typically takes 1-3 days
2. **Status Updates:** Check Play Console for updates
3. **Rejections:** If rejected, address issues and resubmit
4. **Updates:** You can update the app after publication

---

## 17. Additional Resources

### App Store Optimization (ASO) Tips

**Keywords to Include:**
- Service booking
- Handyman app
- Home services
- Service provider
- Book services
- Local services
- Professional services

**Title Optimization:**
- Keep it under 30 characters
- Include main keyword
- Make it memorable

**Description Optimization:**
- Use bullet points
- Include relevant keywords naturally
- Highlight unique features
- Call-to-action at the end

---

## 18. Support Information

**Support Email:**
```
[Your support email]
```

**Support Website:**
```
[Your website URL]
```

**Support Phone (Optional):**
```
[Your support phone number]
```

---

## Notes

1. **App Name:** "FiksOpp" is already set and within limits
2. **Language:** English (UK) is appropriate
3. **App Type:** Definitely an App, not a Game
4. **Free/Paid:** Free is good for initial launch; you can add paid features later
5. **Privacy Policy:** Must be created and hosted before submission
6. **Screenshots:** Need to be prepared from actual app screens
7. **Feature Graphic:** Should be designed to showcase the app

---

## Next Steps

1. ✅ Complete the Google Play Console form with the information above
2. ⚠️ Create and publish a privacy policy
3. ⚠️ Prepare app screenshots (at least 2, recommended 4-8)
4. ⚠️ Design feature graphic (1024x500)
5. ⚠️ Complete Data Safety section
6. ⚠️ Fill Content Rating questionnaire
7. ⚠️ Build and upload your app bundle (AAB file)
8. ⚠️ Submit for review

Good luck with your submission! 🚀

