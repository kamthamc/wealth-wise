# WealthWise - Development Instructions

## Project Overview
WealthWise is a comprehensive personal finance management application that makes you smarter about money. Targeting Indian users initially with global expansion, built natively for iOS 18+, Android 15+, and Windows 11.

## Key Features
- Smart transaction management (import, manual entry, intelligent linking)
- Automatic transaction categorization (when device supports on-device AI)
- Multi-platform account management (banks, credit cards, UPI, brokerages)
- Budget planning and tracking with smart insights
- Asset management (offline assets, investments, properties)
- Loans and lending tracking with EMI calculators
- Comprehensive reporting and analytics
- Natural language interface for easy interaction
- Optional local backup with iCloud/Google Drive export
- Premium features with ad-free experience

## Smart Features (Device-Dependent)
- On-device AI for transaction categorization (iOS 17+ with Neural Engine, Android with ML Kit)
- Smart spending insights and recommendations
- Automatic merchant recognition from transaction data
- Natural language processing for voice commands (when available)

## Development Guidelines
- Security and privacy first: All financial data encrypted and stored locally
- Platform-native design: Follow iOS, Android, and Windows design principles
- Offline-first architecture: Core features work without internet
- India-focused initially: Support Indian banking patterns, UPI, and financial year
- Regulatory compliance: GDPR, data protection, and financial regulations
- Smart features optional: On-device AI enhances experience but never required
- Graceful degradation: Full functionality available even without AI capabilities

## Architecture
- iOS: Swift/SwiftUI with Core Data, Core ML (optional on-device AI)
- Android: Kotlin with Room/Jetpack Compose, ML Kit (optional smart features)
- Windows: .NET Core 10 with WPF/WinUI, ML.NET (optional intelligence)
- Shared: TypeScript models and local repository contracts
- Storage: Local-only with optional cloud backup export
- AI/ML: On-device processing only, enhances but never blocks core functionality