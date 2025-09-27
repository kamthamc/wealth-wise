# Development Setup Guide

## Prerequisites

### System Requirements

#### For iOS Development
- macOS 14.0 or later
- Xcode 15.0 or later
- iOS 18.0 SDK
- CocoaPods 1.15.0 or later
- Swift 5.9 or later

#### For Android Development
- Android Studio 2024.1.1 or later
- Android SDK API 35 (Android 15)
- Kotlin 1.9.0 or later
- Gradle 8.0 or later
- Java Development Kit 17

#### For Windows Development
- Visual Studio 2022 17.8 or later
- .NET Core 10 SDK
- Windows 11 SDK (10.0.22621.0)
- Git for Windows

### Development Tools
- Node.js 18+ (for build scripts)
- Python 3.9+ (for ML model training)
- Firebase CLI
- Git LFS (for large assets)

## Project Setup

### 1. Clone Repository
```bash
git clone https://github.com/kamthamc/wealth-wise.git
cd wealth-wise
```

### 2. Install Dependencies

#### Shared Dependencies
```bash
npm install
pip install -r requirements.txt
```

#### iOS Dependencies
```bash
cd ios
pod install
cd ..
```

#### Android Dependencies
```bash
cd android
./gradlew build
cd ..
```

#### Windows Dependencies
```bash
cd windows
dotnet restore
cd ..
```

## Configuration

### 1. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project: "wealth-wise-app"
3. Enable Authentication, Firestore, Storage, Analytics

#### Download Configuration Files
```bash
# iOS
# Download GoogleService-Info.plist to ios/UnifiedBanking/

# Android
# Download google-services.json to android/app/

# Web (for admin)
# Download firebase-config.js to web/src/config/
```

#### Configure Environment Variables
```bash
# Create .env file in project root
cp .env.example .env

# Edit with your values
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
```

### 2. Platform-Specific Configuration

#### iOS Configuration
```bash
# Configure Xcode project
cd ios
open UnifiedBanking.xcworkspace

# Set up signing & capabilities
# - Automatic signing with your Apple ID
# - Enable Keychain Sharing
# - Enable Background App Refresh
# - Add Core Data capability
```

#### Android Configuration
```bash
# Configure local.properties
cd android
echo "sdk.dir=/Users/$USER/Library/Android/sdk" > local.properties

# Configure signing (for release builds)
# Create keystore.properties in android/app/
storeFile=../keystore/release.keystore
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

#### Windows Configuration
```bash
# Configure appsettings.json
cd windows/UnifiedBanking
cp appsettings.json.example appsettings.json

# Edit connection strings and Firebase config
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=unified_banking.db"
  },
  "Firebase": {
    "ProjectId": "your-project-id",
    "ApiKey": "your-api-key"
  }
}
```

## Development Environment

### 1. IDE Setup

#### Xcode (iOS)
```bash
# Install required Xcode tools
sudo xcode-select --install

# Install iOS simulators
# Xcode → Preferences → Components → Simulators
# Install iOS 18.0 simulators for various devices
```

#### Android Studio
```bash
# Install required SDKs
# SDK Manager → Install Android 15 (API 35)
# SDK Manager → Install Android SDK Build-Tools 35.0.0
# SDK Manager → Install Android Emulator

# Create AVD (Android Virtual Device)
# AVD Manager → Create Virtual Device
# Choose Pixel 8 with Android 15
```

#### Visual Studio (Windows)
```bash
# Install workloads
# .NET desktop development
# Universal Windows Platform development
# Mobile development with .NET (optional)

# Install extensions
# SQLite/SQL Server Compact Toolbox
# Firebase Tools
```

### 2. Database Setup

#### Development Databases
```bash
# iOS - Core Data will create automatically
# No additional setup required

# Android - Room will create automatically
# No additional setup required

# Windows - Entity Framework setup
cd windows/UnifiedBanking
dotnet ef database update
```

### 3. Machine Learning Setup

#### Model Training Environment
```bash
# Create Python virtual environment
python3 -m venv ml-env
source ml-env/bin/activate  # On Windows: ml-env\Scripts\activate

# Install ML dependencies
pip install tensorflow==2.13.0
pip install scikit-learn==1.3.0
pip install pandas==2.0.3
pip install numpy==1.24.3

# Download training data
python scripts/download_training_data.py
```

#### Convert Models for Each Platform
```bash
# Convert to Core ML (iOS)
python scripts/convert_to_coreml.py

# Convert to TensorFlow Lite (Android)
python scripts/convert_to_tflite.py

# Convert to ONNX (Windows)
python scripts/convert_to_onnx.py
```

## Building and Running

### 1. iOS Development

#### Debug Build
```bash
cd ios
xcodebuild -workspace UnifiedBanking.xcworkspace \
           -scheme UnifiedBanking \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build
```

#### Run on Simulator
```bash
# Open Xcode and run directly, or use command line
ios-sim launch build/Debug-iphonesimulator/UnifiedBanking.app \
    --device "iPhone 15 Pro"
```

#### Run on Device
```bash
# Connect device via USB and trust computer
# Select device in Xcode and run
# Or use Xcode Organizer for wireless debugging
```

### 2. Android Development

#### Debug Build
```bash
cd android
./gradlew assembleDebug
```

#### Run on Emulator
```bash
# Start emulator
emulator -avd Pixel_8_API_35

# Install and run
./gradlew installDebug
adb shell am start -n com.unifiedbanking/.MainActivity
```

#### Run on Device
```bash
# Enable Developer Options and USB Debugging
# Connect device via USB
./gradlew installDebug
```

### 3. Windows Development

#### Debug Build
```bash
cd windows
dotnet build --configuration Debug
```

#### Run Application
```bash
# Run directly
dotnet run --project UnifiedBanking

# Or run executable
./UnifiedBanking/bin/Debug/net10.0-windows/UnifiedBanking.exe
```

## Testing

### 1. Unit Tests

#### iOS Tests
```bash
cd ios
xcodebuild test -workspace UnifiedBanking.xcworkspace \
                -scheme UnifiedBankingTests \
                -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

#### Android Tests
```bash
cd android
./gradlew test
./gradlew connectedAndroidTest  # For instrumented tests
```

#### Windows Tests
```bash
cd windows
dotnet test
```

### 2. Integration Tests

#### Firebase Integration
```bash
# Test Firebase connection
npm run test:firebase

# Test authentication flows
npm run test:auth

# Test data synchronization
npm run test:sync
```

#### ML Model Tests
```bash
# Test categorization accuracy
python tests/test_categorization.py

# Test model inference speed
python tests/test_performance.py
```

### 3. UI Tests

#### iOS UI Tests
```bash
xcodebuild test -workspace UnifiedBanking.xcworkspace \
                -scheme UnifiedBankingUITests \
                -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

#### Android UI Tests
```bash
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.unifiedbanking.uitests.MainActivityTest
```

#### Windows UI Tests
```bash
dotnet test --filter "Category=UITest"
```

## Debugging

### 1. iOS Debugging

#### Debug Console
```bash
# View console logs
xcrun simctl spawn booted log stream --predicate 'processImagePath endswith "UnifiedBanking"'

# Core Data debugging
# Add launch argument: -com.apple.CoreData.SQLDebug 1
```

#### Memory Debugging
```bash
# Use Instruments
# Product → Profile → Leaks
# Product → Profile → Allocations
```

### 2. Android Debugging

#### ADB Debugging
```bash
# View logs
adb logcat -s UnifiedBanking

# Debug database
adb shell
run-as com.unifiedbanking
sqlite3 databases/unified_banking.db
```

#### Memory Profiling
```bash
# Use Android Studio Profiler
# View → Tool Windows → Profiler
```

### 3. Windows Debugging

#### Debug Console
```bash
# Enable console logging
dotnet run --configuration Debug --verbosity diagnostic
```

#### Database Debugging
```bash
# View EF Core logs
# Add to appsettings.Development.json
{
  "Logging": {
    "Microsoft.EntityFrameworkCore.Database.Command": "Information"
  }
}
```

## Performance Optimization

### 1. Database Performance

#### iOS Core Data
```swift
// Enable persistent history
container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
    forKey: NSPersistentHistoryTrackingKey)

// Batch operations
let batchRequest = NSBatchInsertRequest(entity: Transaction.entity()) { ... }
```

#### Android Room
```kotlin
// Use transactions for bulk operations
@Transaction
suspend fun insertTransactions(transactions: List<Transaction>) {
    transactionDao.insertAll(transactions)
}

// Enable WAL mode
Room.databaseBuilder(context, AppDatabase::class.java, "database")
    .setJournalMode(RoomDatabase.JournalMode.WRITE_AHEAD_LOGGING)
```

#### Windows Entity Framework
```csharp
// Bulk operations
context.BulkInsert(transactions);

// Query optimization
var accounts = context.Accounts
    .Include(a => a.Transactions.Where(t => t.Date >= startDate))
    .ToList();
```

### 2. Memory Optimization

#### Image Caching
```bash
# Configure image caching
# iOS: Use NSCache with memory pressure handling
# Android: Use Glide or Coil with LRU cache
# Windows: Implement custom image cache with weak references
```

#### Data Pagination
```bash
# Implement pagination for large datasets
# iOS: NSFetchedResultsController with batch size
# Android: Paging 3 library
# Windows: Skip/Take with Entity Framework
```

## Deployment

### 1. Build for Release

#### iOS Release Build
```bash
cd ios
xcodebuild -workspace UnifiedBanking.xcworkspace \
           -scheme UnifiedBanking \
           -configuration Release \
           -archivePath build/UnifiedBanking.xcarchive \
           archive

# Export IPA
xcodebuild -exportArchive \
           -archivePath build/UnifiedBanking.xcarchive \
           -exportPath build/Release \
           -exportOptionsPlist exportOptions.plist
```

#### Android Release Build
```bash
cd android
./gradlew assembleRelease

# Sign APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
          -keystore keystore/release.keystore \
          app/build/outputs/apk/release/app-release-unsigned.apk \
          release

# Align APK
zipalign -v 4 app-release-unsigned.apk app-release.apk
```

#### Windows Release Build
```bash
cd windows
dotnet publish -c Release -r win-x64 --self-contained true

# Create installer package
"C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" \
    UnifiedBanking.wixproj /p:Configuration=Release
```

### 2. App Store Preparation

#### iOS App Store
```bash
# Validate archive
xcrun altool --validate-app \
             --file build/Release/UnifiedBanking.ipa \
             --username your-apple-id \
             --password your-app-password

# Upload to App Store Connect
xcrun altool --upload-app \
             --file build/Release/UnifiedBanking.ipa \
             --username your-apple-id \
             --password your-app-password
```

#### Google Play Store
```bash
# Upload AAB (Android App Bundle)
./gradlew bundleRelease

# Upload using Play Console or Play Developer API
```

#### Microsoft Store
```bash
# Create MSIX package
makeappx pack /d output /p UnifiedBanking.msix

# Sign package
signtool sign /fd SHA256 /a /f certificate.pfx UnifiedBanking.msix
```

## Troubleshooting

### Common Issues

#### iOS Build Issues
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean CocoaPods cache
pod cache clean --all
pod deintegrate && pod install
```

#### Android Build Issues
```bash
# Clean project
./gradlew clean

# Clear Gradle cache
rm -rf ~/.gradle/caches/
```

#### Windows Build Issues
```bash
# Clear NuGet cache
dotnet nuget locals all --clear

# Clean solution
dotnet clean && dotnet restore
```

### Performance Issues

#### Database Slow Queries
```bash
# iOS: Enable Core Data debug logging
# Android: Use Database Inspector
# Windows: Enable EF Core query logging
```

#### Memory Leaks
```bash
# iOS: Use Instruments Leaks tool
# Android: Use Memory Profiler
# Windows: Use PerfView or dotMemory
```

#### Sync Issues
```bash
# Check Firebase console for errors
# Verify network connectivity
# Check authentication status
# Review sync conflict logs
```

For additional support, refer to the platform-specific documentation or create an issue in the project repository.