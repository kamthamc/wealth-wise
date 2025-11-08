# Firebase Configuration for WealthWise

## Setup Instructions

### 1. Add Firebase to Your Project

#### Option A: Using Xcode (Recommended)
1. Open `WealthWise.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "WealthWise" target
4. Go to "General" tab
5. Scroll to "Frameworks, Libraries, and Embedded Content"
6. Click "+" and select "Add Package Dependency"
7. Enter: `https://github.com/firebase/firebase-ios-sdk`
8. Select version: `10.0.0` or later
9. Add these products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFunctions (optional for cloud functions)
   - FirebaseAnalytics (optional)

#### Option B: Using Swift Package Manager
Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
],
targets: [
    .target(
        name: "WealthWise",
        dependencies: [
            .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
        ]
    )
]
```

### 2. Download GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your "wealth-wise" project
3. Click on iOS app (or add new iOS app if needed)
4. Download `GoogleService-Info.plist`
5. Add it to the Xcode project:
   - Drag into the `WealthWise/` folder
   - Ensure "Copy items if needed" is checked
   - Add to all targets (iOS, macOS, watchOS)

### 3. Configure Info.plist

Add URL scheme for Firebase Auth (if using phone auth or OAuth):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### 4. Initialize Firebase

Already done in `FirebaseService.swift`:

```swift
if FirebaseApp.app() == nil {
    FirebaseApp.configure()
}
```

### 5. Test Connection

Build and run the app. Check Xcode console for:
```
[Firebase/Core] Successfully configured Firebase
```

## Firebase Project Configuration

### Firestore Database
- **Mode**: Production (with security rules)
- **Location**: `asia-south1` (Mumbai) for Indian users
- **Collections**:
  - `users`
  - `accounts`
  - `transactions`
  - `budgets`
  - `goals`
  - `categories` (optional)

### Authentication
- **Providers Enabled**:
  - Email/Password ✓
  - Google Sign-In (optional)
  - Apple Sign-In (recommended for iOS)

### Security Rules

Apply these Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Accounts collection
    match /accounts/{accountId} {
      allow read, write: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read, write: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
    
    // Budgets collection
    match /budgets/{budgetId} {
      allow read, write: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
    
    // Goals collection
    match /goals/{goalId} {
      allow read, write: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Cloud Functions Integration

If using the existing webapp Cloud Functions:

### Configure Functions Region
```swift
// In FirebaseService.swift
let functions = Functions.functions(region: "asia-south1")
```

### Available Functions
- `createOrUpdateBudget`
- `createOrUpdateGoal`
- `generateBudgetReport`
- `calculateBalances`
- `bulkDeleteTransactions`
- `exportTransactions`

### Example Usage
```swift
let functions = Functions.functions()
let data = ["budgetId": budgetId]
let result = try await functions.httpsCallable("generateBudgetReport").call(data)
```

## Troubleshooting

### "No such module 'FirebaseCore'" Error
- Ensure Firebase package is added via Xcode
- Clean build folder: Cmd+Shift+K
- Rebuild: Cmd+B

### "GoogleService-Info.plist not found"
- Download from Firebase Console
- Add to Xcode project (not just file system)
- Verify it's in "Copy Bundle Resources" build phase

### Connection Issues
- Check Firebase project is active
- Verify API keys are correct
- Ensure billing is enabled (if using Cloud Functions)

## Environment Configuration

### Development
- Use Firebase Emulator Suite for local testing
- Set environment variable: `USE_FIREBASE_EMULATOR=true`

### Production
- Use production Firebase project
- Enable App Check for additional security
- Monitor usage in Firebase Console

## Next Steps

1. ✅ Add Firebase SDK via SPM
2. ✅ Download GoogleService-Info.plist
3. ✅ Configure security rules
4. ✅ Test authentication
5. ✅ Verify Firestore connection
6. ✅ Test Cloud Functions (optional)
