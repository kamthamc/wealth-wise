# macOS WealthWise - Project Documentation

## Overview

This document describes how to build and run the macOS version of WealthWise using the existing Xcode project.

## Project Structure

The macOS app is built as an additional target within the existing `wealth-wise.xcodeproj` located at `apple/wealth-wise/wealth-wise.xcodeproj`.

### File Organization
```
apple/wealth-wise/
├── wealth-wise.xcodeproj/          # Main Xcode project
├── wealth-wise/                    # iOS target files
│   ├── wealth_wiseApp.swift        # iOS app entry point
│   ├── ContentView.swift           # Cross-platform content view
│   └── Item.swift                  # Sample data model
├── macOS/                          # macOS-specific files
│   ├── WealthWiseMacApp.swift      # macOS app entry point with menu commands
│   ├── MacContentView.swift        # macOS-optimized UI
│   └── Info.plist                  # macOS app configuration
├── Shared/                         # Shared code between platforms
│   └── DataModels.swift            # SwiftData models for assets and portfolios
├── wealth-wiseTests/               # iOS unit tests
└── wealth-wiseUITests/             # iOS UI tests
```

## How to Open and Build

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Apple Developer account for code signing (for distribution)

### Opening the Project
1. Navigate to `apple/wealth-wise/`
2. Double-click `wealth-wise.xcodeproj` to open in Xcode
3. In Xcode, you'll see multiple targets in the project navigator

### Building for macOS
1. Select the **WealthWise macOS** target from the scheme selector
2. Choose your Mac as the destination device
3. Click the build and run button (⌘+R)

### Building for iOS
1. Select the **wealth-wise** target from the scheme selector  
2. Choose an iOS simulator or connected device
3. Click the build and run button (⌘+R)

## Architecture Overview

### App Structure

The macOS app follows the standard SwiftUI app lifecycle:

- **WealthWiseMacApp.swift**: Main app entry point with native macOS features
  - Window management with minimum size constraints
  - Native menu bar integration
  - Settings window support
  - Keyboard shortcuts for common actions

- **MacContentView.swift**: Main interface optimized for macOS
  - Three-pane NavigationSplitView layout
  - Sidebar navigation with financial categories
  - Detail view that adapts based on selection
  - Native macOS styling and behaviors

### Data Models

The app uses SwiftData for local data persistence with the following models:

- **Asset**: Individual financial assets (stocks, real estate, etc.)
- **Portfolio**: Collections of assets
- **Transaction**: Financial transactions linked to assets
- **AssetType**: Enumeration of supported asset categories

### Features Implemented

#### Navigation & UI
- ✅ Native macOS three-pane interface
- ✅ Sidebar with financial categories
- ✅ Menu bar integration with File/View/Tools menus
- ✅ Keyboard shortcuts for common actions
- ✅ Settings window support

#### Data Management
- ✅ SwiftData integration for local storage
- ✅ Asset and portfolio data models
- ✅ Transaction tracking capability
- 🚧 Core Data encryption (planned)

#### User Interface
- ✅ Dashboard with financial overview cards
- ✅ Placeholder views for major sections
- 🚧 Detailed asset management (in development)
- 🚧 Reporting and analytics (planned)

### Menu Commands

The app includes native macOS menu commands:

**File Menu**
- Import Data... (⇧⌘I)
- Export Data... (⇧⌘E)

**View Menu**  
- Dashboard (⌘1)
- Portfolio (⌘2)
- Assets (⌘3)
- Reports (⌘R)

**Tools Menu**
- Security Settings...
- Backup & Restore...

## Development Notes

### SwiftData vs Core Data
Currently using SwiftData for simplicity, but the app will migrate to Core Data with encryption for production use.

### Cross-Platform Code Sharing
The `ContentView.swift` includes conditional compilation to show platform-appropriate interfaces:
- iOS: Standard NavigationSplitView
- macOS: Enhanced three-pane layout with native styling

### Planned Enhancements
1. **Core Data Integration**: Replace SwiftData with encrypted Core Data
2. **Biometric Authentication**: Touch ID/Face ID support
3. **Data Import/Export**: CSV and banking statement support  
4. **Advanced Reporting**: Tax calculations and portfolio analytics
5. **UI Polish**: Native macOS styling and animations

## Building and Distribution

### Development Build
1. Open project in Xcode
2. Select macOS target
3. Build and run (⌘R)

### Archive Build (for distribution)
1. Select macOS target
2. Choose "Any Mac" as destination
3. Product → Archive
4. Follow code signing and notarization steps

## Troubleshooting

### Common Issues
- **Build errors**: Ensure macOS 14.0+ deployment target
- **Code signing**: Configure Apple Developer account in Xcode preferences
- **SwiftData errors**: Clean build folder and rebuild

### Getting Help
- Check Xcode console for detailed error messages
- Verify all file references are correct in project navigator
- Ensure proper target membership for shared files