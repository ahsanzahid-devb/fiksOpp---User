# Chat Module Testing Guide

## 📱 How to Access Chat Screen

### Method 1: From Chat List
1. Navigate to the **Chat List Screen** in your app
2. Tap on any user from the list
3. This will open the `UserChatScreen` with that user

### Method 2: Direct Navigation (For Testing)
You can also test directly by navigating to a chat screen programmatically.

---

## 🧪 Test Scenarios

### ✅ Test 1: Basic Message Sending
**Steps:**
1. Open chat screen with a user
2. Type a message in the text field
3. Tap the send button

**What to Check in Logs:**
```
🔵 [CHAT DEBUG] ========== INIT STARTED ==========
🔵 [CHAT DEBUG] Receiver User Email: ...
🔵 [CHAT DEBUG] Receiver User UID: ...
🔵 [CHAT DEBUG] Sender User Email: ...
🔵 [CHAT DEBUG] Sender User UID: ...
🟢 [CHAT DEBUG] ========== SEND MESSAGE STARTED ==========
🟢 [CHAT DEBUG] Message Text: [your message]
🟢 [CHAT DEBUG] ✅ Message Successfully Added to Firebase
```

**Expected Result:**
- Message appears in the chat
- No error logs
- Message document reference is logged

---

### ✅ Test 2: Empty Message Handling
**Steps:**
1. Open chat screen
2. Don't type anything
3. Tap send button

**What to Check in Logs:**
```
🟡 [CHAT DEBUG] ⚠️ Message is empty and not a file, requesting focus
```

**Expected Result:**
- Message is NOT sent
- Focus returns to text field
- No Firebase operations

---

### ✅ Test 3: First Time Contact (New Chat)
**Steps:**
1. Open chat with a user you've never chatted with before
2. Send a message

**What to Check in Logs:**
```
🟢 [CHAT DEBUG] Is receiver in contacts: false
🟢 [CHAT DEBUG] ========== Adding To Contacts ==========
🟢 [CHAT DEBUG] ✅ Successfully added to contacts
🟢 [CHAT DEBUG] Setting up online status listener...
```

**Expected Result:**
- Contact is automatically added
- Online status listener is set up
- Message is sent successfully

---

### ✅ Test 4: File Upload (Images)
**Steps:**
1. Open chat screen
2. Tap the camera icon
3. Take a photo or select from gallery
4. Send the file

**What to Check in Logs:**
```
🟡 [CHAT DEBUG] ========== HANDLE UPLOAD FILES STARTED ==========
🟡 [CHAT DEBUG] Files count: 1
🟡 [CHAT DEBUG] File 0: [path] ([size] bytes)
🟡 [CHAT DEBUG] ✅ Files uploaded successfully
🟡 [CHAT DEBUG] Attached files count: 1
🟢 [CHAT DEBUG] ✅ Message with attachments sent
```

**Expected Result:**
- File is uploaded
- Attachment URL is logged
- Message with file is sent

---

### ✅ Test 5: Document Upload
**Steps:**
1. Open chat screen
2. Tap the attachment icon
3. Select a document (PDF, DOC, etc.)
4. Send the file

**What to Check in Logs:**
```
🟡 [CHAT DEBUG] ========== HANDLE UPLOAD FILES STARTED ==========
🟡 [CHAT DEBUG] Files count: 1
🟡 [CHAT DEBUG] File 0: [path] ([size] bytes)
🟡 [CHAT DEBUG] ✅ Files uploaded successfully
```

**Expected Result:**
- Document is uploaded
- File URL is generated
- Message with document is sent

---

### ✅ Test 6: Message Receiving
**Steps:**
1. Open chat screen
2. Have another user send you a message
3. Watch the logs

**What to Check in Logs:**
```
🟣 [CHAT DEBUG] Message loaded - Index: 0, IsMe: false, Type: TEXT, Message: [message text]
```

**Expected Result:**
- Messages appear in real-time
- Each message is logged as it loads
- No parsing errors

---

### ✅ Test 7: Online Status
**Steps:**
1. Open chat screen
2. Have the other user go online/offline
3. Watch the logs

**What to Check in Logs:**
```
🔵 [CHAT DEBUG] ====== Online Status Changed: 1 ======  (Online)
🔵 [CHAT DEBUG] ====== Online Status Changed: 0 ======  (Offline)
```

**Expected Result:**
- Online status updates in real-time
- Status changes are logged

---

### ✅ Test 8: Error Handling
**Steps:**
1. Turn off internet connection
2. Try to send a message
3. Check logs

**What to Check in Logs:**
```
🔴 [CHAT DEBUG] ❌ Error adding message: [error details]
🔴 [CHAT DEBUG] Stack Trace: [stack trace]
```

**Expected Result:**
- Error is caught and logged
- User sees error toast
- App doesn't crash

---

## 📊 How to View Debug Logs

### Android (Android Studio / Logcat)
1. Open **Android Studio**
2. Go to **View → Tool Windows → Logcat**
3. Filter by: `CHAT DEBUG` or search for `[CHAT DEBUG]`
4. You'll see all debug messages with emoji indicators

### VS Code / Command Line
```bash
# For Android
adb logcat | grep "CHAT DEBUG"

# For iOS (if using Xcode)
# Check Xcode console output
```

### Flutter DevTools
1. Run app in debug mode
2. Open Flutter DevTools
3. Go to **Logging** tab
4. Filter by `CHAT DEBUG`

---

## 🔍 Debug Log Indicators

| Emoji | Meaning | Example |
|-------|---------|---------|
| 🔵 | Initialization/Setup | User data loading, contact checks |
| 🟢 | Success Operations | Message sent, file uploaded |
| 🟡 | Warnings/Info | Empty message, file selection |
| 🔴 | Errors | Failed operations, exceptions |
| 🟣 | Message Loading | Messages received from Firebase |

---

## 🐛 Common Issues & Troubleshooting

### Issue 1: Messages Not Sending
**Check Logs For:**
```
🔴 [CHAT DEBUG] ❌ Error adding message: ...
```

**Possible Causes:**
- Firebase not initialized
- Network connection issues
- Invalid user UIDs
- Firebase permissions

**Solution:**
- Check Firebase configuration
- Verify internet connection
- Check user authentication

---

### Issue 2: Receiver UID is Empty
**Check Logs For:**
```
🔵 [CHAT DEBUG] Receiver UID is empty, fetching user by email...
🔴 [CHAT DEBUG] ❌ Error fetching receiver user: ...
```

**Possible Causes:**
- User doesn't exist in Firebase
- Email is incorrect
- Firebase query failed

**Solution:**
- Verify receiver user exists
- Check email address
- Check Firebase user collection

---

### Issue 3: Files Not Uploading
**Check Logs For:**
```
🔴 [CHAT DEBUG] ❌ ChatServices().uploadFiles Error: ...
```

**Possible Causes:**
- Storage permissions not granted
- File size too large
- Storage bucket not configured
- Network issues

**Solution:**
- Check storage permissions
- Verify Firebase Storage setup
- Check file size limits

---

### Issue 4: Messages Not Appearing
**Check Logs For:**
```
🔴 [CHAT DEBUG] ❌ Error parsing message at index X: ...
```

**Possible Causes:**
- Malformed message data
- Missing required fields
- Data type mismatches

**Solution:**
- Check Firebase data structure
- Verify message model matches data
- Check for null values

---

### Issue 5: Online Status Not Updating
**Check Logs For:**
```
🔴 [CHAT DEBUG] ❌ Error in online status stream: ...
```

**Possible Causes:**
- Stream subscription failed
- Firebase realtime database not configured
- Permission issues

**Solution:**
- Check Firebase Realtime Database setup
- Verify stream permissions
- Check network connectivity

---

## ✅ Success Checklist

After testing, verify:
- [ ] Messages send successfully
- [ ] Messages receive in real-time
- [ ] Files upload correctly
- [ ] Online status updates
- [ ] Contacts are added automatically
- [ ] Error handling works
- [ ] No crashes occur
- [ ] All debug logs are visible

---

## 📝 Testing Checklist Template

```
Date: ___________
Tester: ___________

Test 1: Basic Message Sending
[ ] Pass [ ] Fail
Notes: _________________________________

Test 2: Empty Message Handling
[ ] Pass [ ] Fail
Notes: _________________________________

Test 3: First Time Contact
[ ] Pass [ ] Fail
Notes: _________________________________

Test 4: File Upload (Images)
[ ] Pass [ ] Fail
Notes: _________________________________

Test 5: Document Upload
[ ] Pass [ ] Fail
Notes: _________________________________

Test 6: Message Receiving
[ ] Pass [ ] Fail
Notes: _________________________________

Test 7: Online Status
[ ] Pass [ ] Fail
Notes: _________________________________

Test 8: Error Handling
[ ] Pass [ ] Fail
Notes: _________________________________

Issues Found:
1. _________________________________
2. _________________________________
3. _________________________________
```

---

## 🚀 Quick Test Commands

### Filter Logs by Type
```bash
# Only errors
adb logcat | grep "🔴"

# Only initialization
adb logcat | grep "🔵"

# Only success messages
adb logcat | grep "🟢"

# All chat debug
adb logcat | grep "CHAT DEBUG"
```

### Save Logs to File
```bash
adb logcat | grep "CHAT DEBUG" > chat_debug_logs.txt
```

---

## 💡 Tips for Effective Testing

1. **Test with Real Users**: Use two different devices/accounts
2. **Test Network Conditions**: Try with WiFi, mobile data, and offline
3. **Test Different File Types**: Images, PDFs, documents
4. **Test Edge Cases**: Very long messages, special characters, empty messages
5. **Monitor Logs Continuously**: Keep logcat open while testing
6. **Document Issues**: Note any errors with timestamps
7. **Test on Different Devices**: Android and iOS if applicable

---

## 📞 Need Help?

If you encounter issues:
1. Check the debug logs first
2. Look for 🔴 error messages
3. Check the stack traces
4. Verify Firebase configuration
5. Check network connectivity
6. Verify user authentication

Happy Testing! 🎉

