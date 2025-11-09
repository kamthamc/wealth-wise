# Firebase Configuration Security Notice

## ⚠️ IMPORTANT: Sensitive Configuration Files

The `GoogleService-Info.plist` file contains sensitive Firebase API keys and should **NEVER** be committed to git.

## Setup Instructions

### 1. Download Your Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Scroll to "Your apps" section
5. Select your iOS app (or add one if it doesn't exist)
6. Download `GoogleService-Info.plist`

### 2. Add to Xcode Project

1. Place the downloaded file in: `apple/WealthWise/WealthWise/`
2. Open `WealthWise.xcodeproj` in Xcode
3. Drag `GoogleService-Info.plist` into the project navigator
4. In the dialog:
   - ✅ Check "Copy items if needed"
   - ✅ Check "WealthWise" target
   - Click "Finish"

### 3. Verify .gitignore Protection

The file is already protected by `.gitignore`:
```
# Firebase Configuration (contains sensitive API keys)
GoogleService-Info.plist
**/GoogleService-Info.plist
```

## Security Best Practices

### ✅ DO:
- Keep `GoogleService-Info.plist` in local project only
- Add it to `.gitignore` (already done)
- Use Firebase App Check for additional security
- Implement proper security rules in Firebase Console
- Rotate API keys if accidentally exposed

### ❌ DON'T:
- Commit `GoogleService-Info.plist` to git
- Share the file publicly
- Include API keys in screenshots
- Hardcode API keys in source code
- Push to public repositories without .gitignore

## Template File

A template file is provided at:
```
apple/WealthWise/WealthWise/GoogleService-Info.plist.template
```

This shows the structure but contains placeholder values.

## If API Keys Were Exposed

If you accidentally committed this file:

1. **Remove from git history immediately**:
   ```bash
   git rm --cached apple/WealthWise/WealthWise/GoogleService-Info.plist
   git commit -m "security: remove Firebase config from git"
   git push --force
   ```

2. **Rotate API keys in Firebase Console**:
   - Go to Project Settings → General
   - Delete the app configuration
   - Create a new one
   - Download new `GoogleService-Info.plist`

3. **Review Firebase Security Rules**:
   - Ensure Firestore rules are properly configured
   - Check Authentication settings
   - Review Function permissions

4. **Enable App Check** (recommended):
   - Go to Project Settings → App Check
   - Enable for your iOS app
   - Follow setup instructions

## Current Status

✅ **Protected**: The file is NOT currently tracked by git  
✅ **Ignored**: Added to `.gitignore`  
✅ **Template**: Template file provided for reference  
⚠️ **Action Required**: Each developer must download their own copy from Firebase Console

## Firebase Security Configuration

### Firestore Rules
Location: `firestore.rules`

Ensure rules require authentication:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Cloud Functions Security
All Cloud Functions should:
- Verify authentication token
- Check user ownership of data
- Validate input data
- Use region-specific deployment (asia-south1)

### Storage Rules
If using Firebase Storage:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Additional Resources

- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/basics)
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [iOS Security Guide](https://firebase.google.com/docs/ios/setup#security)
- [Securing Firebase Projects](https://firebase.google.com/docs/projects/learn-more#security)

---

**Remember**: Security is everyone's responsibility. Keep API keys private!
