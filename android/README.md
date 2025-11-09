# WealthWise Android Application

Modern Android application for personal finance management built with Kotlin, Jetpack Compose, and Material Design 3.

## 📱 Features

- **Multi-Account Management**: Bank accounts, credit cards, UPI wallets, and brokerage accounts
- **Transaction Tracking**: Comprehensive transaction management with categories and search
- **Budget Management**: Period-based budgets with real-time spending tracking
- **Goal Tracking**: Savings goals with progress visualization and contribution history
- **Offline-First**: Full offline support with automatic sync
- **Secure**: Encrypted local storage and biometric authentication
- **Material Design 3**: Modern, beautiful UI following Material Design guidelines

## 🏗️ Architecture

### Tech Stack

- **Language**: Kotlin 2.1.0
- **UI**: Jetpack Compose with Material Design 3
- **Architecture**: MVVM + Repository pattern
- **Database**: Room 2.6.1 with encryption
- **Dependency Injection**: Hilt 2.54
- **Async**: Kotlin Coroutines + Flow
- **Backend**: Firebase (Auth, Firestore, Functions)
- **Networking**: Retrofit + OkHttp
- **Serialization**: Kotlinx Serialization

### Project Structure

```
com.wealthwise.android/
├── data/                   # Data layer
│   ├── local/             # Room database, DAOs, converters
│   ├── remote/            # Firebase, API services
│   ├── model/             # Data models and entities
│   └── repository/        # Repository implementations
├── domain/                 # Business logic layer
│   ├── model/             # Domain models
│   ├── repository/        # Repository interfaces
│   └── usecase/           # Use cases
├── features/              # Feature modules
│   ├── accounts/          # Account management
│   ├── transactions/      # Transaction management
│   ├── budgets/           # Budget tracking
│   ├── goals/             # Goal management
│   └── dashboard/         # Main dashboard
└── ui/                    # UI layer
    ├── components/        # Reusable Compose components
    ├── theme/             # Material Design theme
    └── navigation/        # Navigation setup
```

## 🚀 Getting Started

### Prerequisites

- Android Studio Ladybug | 2024.2.1 or later
- JDK 17
- Android SDK 26+
- Firebase project configured

### Setup

1. **Clone the repository**
   ```bash
   cd android
   ```

2. **Configure Firebase**
   - Download `google-services.json` from Firebase Console
   - Place it in `app/` directory

3. **Build the project**
   ```bash
   ./gradlew assembleDebug
   ```

4. **Run on device/emulator**
   ```bash
   ./gradlew installDebug
   ```

### Firebase Setup

Required Firebase services:
- Authentication (Email/Password, Google Sign-In)
- Firestore Database
- Cloud Functions

See [Firebase Setup Guide](../docs/firebase-setup.md) for detailed instructions.

## 📦 Build Variants

### Debug
- Debug symbols enabled
- Logging enabled
- No code obfuscation
- Application ID: `com.wealthwise.android.debug`

### Release
- Code obfuscation with R8
- Logging disabled
- Optimized APK size
- Requires signing configuration

## 🧪 Testing

### Unit Tests
```bash
./gradlew test
```

### Instrumented Tests
```bash
./gradlew connectedAndroidTest
```

### Test Coverage
```bash
./gradlew testDebugUnitTestCoverage
```

## 🔒 Security

- **Data Encryption**: All sensitive data encrypted at rest using Android Keystore
- **Network Security**: Certificate pinning for API calls
- **Biometric Auth**: Fingerprint/Face authentication support
- **Code Obfuscation**: ProGuard/R8 rules applied in release builds

## 📝 Code Quality

### Linting
```bash
./gradlew ktlintCheck
```

### Formatting
```bash
./gradlew ktlintFormat
```

### Static Analysis
- ktlint for Kotlin code style
- Android Lint for Android-specific issues
- Detekt for code smell detection (to be added)

## 🌍 Localization

Currently supported languages:
- English (default)
- Hindi (in progress)
- Tamil (in progress)
- Telugu (in progress)

String resources located in `src/main/res/values-*/strings.xml`

## 📊 Performance

- **App Startup**: < 2 seconds cold start
- **Database Queries**: Indexed for optimal performance
- **UI Rendering**: 60 FPS with Jetpack Compose
- **Memory**: < 100MB typical usage

## 🤝 Contributing

1. Follow [Android Development Instructions](../.github/instructions/android.instructions.md)
2. Use Kotlin coding conventions
3. Write tests for new features
4. Update documentation

## 📄 License

Copyright © 2025 WealthWise Team. All rights reserved.

## 🔗 Related Documentation

- [Apple Platform](../apple/README.md)
- [Web Application](../packages/webapp/README.md)
- [Architecture Guide](../docs/ARCHITECTURE.md)
- [Security Framework](../docs/security-framework.md)
