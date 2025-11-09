# Native Application Strategy: Kotlin Multiplatform

## 1. Overview

This document outlines the long-term strategy for developing and maintaining the WealthWise native applications for Apple, Android, and Windows platforms. To maximize code reuse, reduce development effort, and ensure consistent business logic, we will adopt **Kotlin Multiplatform (KMP)** for our shared logic layer.

## 2. The Challenge: Duplicated Logic

As we expand to support more native platforms, building each application entirely from scratch leads to significant code duplication. Key business logic must be rewritten and maintained in Swift, Kotlin (for Android), and C# (for Windows).

This approach is:
- **Inefficient:** Triples the development and testing effort for any shared feature.
- **Error-Prone:** Inconsistencies in logic can emerge across platforms.
- **Slow to Iterate:** A single change to business logic requires coordinated updates across three different codebases.

## 3. The Solution: A Shared Core with KMP

Kotlin Multiplatform allows us to write code once in Kotlin and compile it into native libraries for each target platform.

- For **iOS**, it compiles into a **Swift framework**.
- For **Android**, it compiles into a **JVM library**.
- For **Windows**, it can compile to a JVM or native library.

This shared core will be responsible for everything **except the User Interface**. The UI will remain fully native on each platform to provide the best possible user experience.

```
┌─────────────────────────────────────────────────┐
│      iOS App (SwiftUI)         │      Android App (Jetpack Compose)     │
└─────────────────────────────────────────────────┘
                        │ (Native Bridge)
                        ▼
┌─────────────────────────────────────────────────┐
│      Shared Core (Kotlin Multiplatform)         │
│  ┌──────────────────────────────────────────┐   │
│  │        Repository Layer                │   │
│  │   (Firestore API, Local Cache)         │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │        Business Logic                  │   │
│  │   (Calculations, Validation)           │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │        Data Models & Services          │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## 4. What to Share in the KMP Module

The KMP module will contain the following components:

- **Data Models:** All core data structures (`Account`, `Transaction`, `Budget`, `Goal`).
- **Repository Layer:** The complete logic for fetching data from Firebase and managing the local SQLDelight database cache.
- **Synchronization Logic:** The service responsible for syncing local and remote data and resolving conflicts.
- **Business Logic:**
  - All financial calculations (e.g., net worth, budget progress).
  - Data validation rules.
  - Currency and date formatting logic.
- **Service Integrations:** Abstracted connections to Firebase (Authentication, Firestore).

## 5. What Remains Native

- **User Interface:**
  - **iOS/macOS:** SwiftUI
  - **Android:** Jetpack Compose
  - **Windows:** .NET MAUI or other native framework
- **Platform-Specific APIs:**
  - Biometric authentication (Face ID, Touch ID).
  - Secure storage (Keychain, Android Keystore).
  - Push notifications.

## 6. Implementation Plan

1.  **Create a KMP Module:** Add a new `shared-kmp` module to our monorepo.
2.  **Migrate Logic:** Gradually migrate the existing data and business logic from the Swift application into the KMP module.
3.  **Integrate with iOS:** Create a Swift Package that wraps the compiled KMP framework and replace the existing Swift implementation with calls to the shared module.
4.  **Build Android App:** Begin development of the Android application, using the KMP module from the start for all data and business logic.

This strategy provides the best of both worlds: a single, maintainable source of truth for our complex business logic, and a no-compromise, fully native user experience on every platform.
