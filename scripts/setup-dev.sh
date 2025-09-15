#!/bin/bash

# WealthWise - Development Environment Setup Script
# Automatically sets up development environment for all platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MACOS_VERSION=$(sw_vers -productVersion)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 WealthWise - Development Setup${NC}"
echo -e "${BLUE}macOS Version: ${MACOS_VERSION}${NC}"
echo ""

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_and_install_homebrew() {
    log_info "Checking for Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_info "Homebrew already installed ✅"
        brew update
    fi
}

setup_ios_development() {
    log_info "Setting up iOS development environment..."
    
    # Check for Xcode
    if ! xcode-select -p &> /dev/null; then
        log_error "Xcode not found. Please install Xcode from the App Store."
        exit 1
    fi
    
    # Install Xcode command line tools
    xcode-select --install 2>/dev/null || true
    
    # Accept Xcode license
    sudo xcodebuild -license accept 2>/dev/null || true
    
    # Install CocoaPods
    if ! command -v pod &> /dev/null; then
        log_info "Installing CocoaPods..."
        sudo gem install cocoapods
    else
        log_info "CocoaPods already installed ✅"
    fi
    
    # Update CocoaPods repo
    log_info "Updating CocoaPods repository..."
    pod repo update --silent
    
    # Install iOS dependencies
    if [ -f "${PROJECT_ROOT}/ios/Podfile" ]; then
        cd "${PROJECT_ROOT}/ios"
        pod install
        cd "${PROJECT_ROOT}"
    fi
    
    log_info "iOS development setup complete ✅"
}

setup_android_development() {
    log_info "Setting up Android development environment..."
    
    # Install Java 17 (required for Android)
    if ! java -version 2>&1 | grep -q "17\|18\|19\|20\|21"; then
        log_info "Installing Java 17..."
        brew install openjdk@17
        
        # Link Java for system use
        sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
        
        # Add to shell profile
        echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zprofile
        echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"' >> ~/.zprofile
        source ~/.zprofile
    else
        log_info "Java already installed ✅"
    fi
    
    # Install Android Studio or Android SDK
    if [ ! -d "$HOME/Library/Android/sdk" ] && [ ! -d "/Applications/Android Studio.app" ]; then
        log_info "Installing Android Studio..."
        brew install --cask android-studio
        
        log_warn "Please complete Android Studio setup manually:"
        log_warn "1. Open Android Studio"
        log_warn "2. Complete the setup wizard"
        log_warn "3. Install Android SDK (API 34, 35)"
        log_warn "4. Install Android SDK Build Tools"
        log_warn "5. Set ANDROID_HOME environment variable"
        
        read -p "Press Enter after completing Android Studio setup..."
    fi
    
    # Set Android environment variables
    if [ -d "$HOME/Library/Android/sdk" ]; then
        ANDROID_HOME="$HOME/Library/Android/sdk"
    elif [ -d "/Applications/Android Studio.app/Contents/bin" ]; then
        ANDROID_HOME="/Applications/Android Studio.app/Contents/sdk"
    fi
    
    if [ -n "$ANDROID_HOME" ]; then
        echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> ~/.zprofile
        echo "export PATH=\"\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$PATH\"" >> ~/.zprofile
        source ~/.zprofile
        log_info "Android environment variables set ✅"
    else
        log_error "Could not find Android SDK. Please set ANDROID_HOME manually."
    fi
    
    log_info "Android development setup complete ✅"
}

setup_windows_development() {
    log_info "Setting up Windows/.NET development environment..."
    
    # Install .NET SDK
    if ! command -v dotnet &> /dev/null; then
        log_info "Installing .NET SDK..."
        brew install dotnet
    else
        log_info ".NET SDK already installed ✅"
        dotnet --version
    fi
    
    # Install additional .NET templates
    log_info "Installing .NET templates..."
    dotnet new install Microsoft.WindowsDesktop.ProjectTemplates
    
    log_info "Windows/.NET development setup complete ✅"
}

setup_common_tools() {
    log_info "Setting up common development tools..."
    
    # Install Node.js (for shared TypeScript models)
    if ! command -v node &> /dev/null; then
        log_info "Installing Node.js..."
        brew install node
    else
        log_info "Node.js already installed ✅"
    fi
    
    # Install TypeScript globally
    if ! command -v tsc &> /dev/null; then
        log_info "Installing TypeScript..."
        npm install -g typescript
    else
        log_info "TypeScript already installed ✅"
    fi
    
    # Install Git (should be available but ensure latest)
    brew install git || true
    
    # Install Firebase CLI
    if ! command -v firebase &> /dev/null; then
        log_info "Installing Firebase CLI..."
        npm install -g firebase-tools
    else
        log_info "Firebase CLI already installed ✅"
    fi
    
    # Install fastlane (for mobile app deployment)
    if ! command -v fastlane &> /dev/null; then
        log_info "Installing fastlane..."
        brew install fastlane
    else
        log_info "fastlane already installed ✅"
    fi
    
    # Install VS Code extensions (if VS Code is installed)
    if command -v code &> /dev/null; then
        log_info "Installing VS Code extensions..."
        
        # iOS development
        code --install-extension ms-vscode.vscode-ios-debug
        
        # Android development
        code --install-extension ms-vscode.vscode-android
        
        # .NET development
        code --install-extension ms-dotnettools.csharp
        code --install-extension ms-dotnettools.vscode-dotnet-runtime
        
        # Common development
        code --install-extension ms-vscode.vscode-typescript-next
        code --install-extension ms-vscode.vscode-json
        code --install-extension ms-vscode.vscode-eslint
        code --install-extension ms-vscode.vscode-prettier
        
        log_info "VS Code extensions installed ✅"
    fi
    
    log_info "Common tools setup complete ✅"
}

setup_firebase() {
    log_info "Setting up Firebase configuration..."
    
    if [ ! -f "${PROJECT_ROOT}/firebase.json" ]; then
        log_info "Initializing Firebase project..."
        cd "${PROJECT_ROOT}"
        
        # Create basic firebase.json
        cat > firebase.json << EOF
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "predeploy": [
      "npm --prefix \"\$RESOURCE_DIR\" run lint",
      "npm --prefix \"\$RESOURCE_DIR\" run build"
    ],
    "source": "functions"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
EOF
        
        # Create basic Firestore rules
        cat > firestore.rules << EOF
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Nested collections under user document
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
EOF
        
        # Create basic Storage rules
        cat > storage.rules << EOF
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
EOF
        
        log_info "Firebase configuration files created ✅"
    else
        log_info "Firebase already configured ✅"
    fi
}

create_development_scripts() {
    log_info "Creating development helper scripts..."
    
    mkdir -p "${PROJECT_ROOT}/scripts"
    
    # Create iOS development script
    cat > "${PROJECT_ROOT}/scripts/dev-ios.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/../ios"
pod install
xcodebuild -workspace UnifiedBanking.xcworkspace -scheme UnifiedBanking -destination "platform=iOS Simulator,name=iPhone 15 Pro" build
EOF
    
    # Create Android development script
    cat > "${PROJECT_ROOT}/scripts/dev-android.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/../android"
./gradlew assembleDebug
EOF
    
    # Create Windows development script
    cat > "${PROJECT_ROOT}/scripts/dev-windows.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/../windows"
dotnet restore
dotnet build --configuration Debug
EOF
    
    # Make scripts executable
    chmod +x "${PROJECT_ROOT}/scripts/"*.sh
    
    log_info "Development scripts created ✅"
}

verify_installation() {
    log_info "Verifying installation..."
    
    echo ""
    echo -e "${BLUE}=== Installation Verification ===${NC}"
    
    # Check iOS tools
    if command -v xcodebuild &> /dev/null; then
        echo -e "${GREEN}✅ Xcode:${NC} $(xcodebuild -version | head -1)"
    else
        echo -e "${RED}❌ Xcode not found${NC}"
    fi
    
    if command -v pod &> /dev/null; then
        echo -e "${GREEN}✅ CocoaPods:${NC} $(pod --version)"
    else
        echo -e "${RED}❌ CocoaPods not found${NC}"
    fi
    
    # Check Android tools
    if command -v java &> /dev/null; then
        echo -e "${GREEN}✅ Java:${NC} $(java -version 2>&1 | head -1)"
    else
        echo -e "${RED}❌ Java not found${NC}"
    fi
    
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
        echo -e "${GREEN}✅ Android SDK:${NC} $ANDROID_HOME"
    else
        echo -e "${RED}❌ Android SDK not found${NC}"
    fi
    
    # Check .NET tools
    if command -v dotnet &> /dev/null; then
        echo -e "${GREEN}✅ .NET SDK:${NC} $(dotnet --version)"
    else
        echo -e "${RED}❌ .NET SDK not found${NC}"
    fi
    
    # Check common tools
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✅ Node.js:${NC} $(node --version)"
    else
        echo -e "${RED}❌ Node.js not found${NC}"
    fi
    
    if command -v tsc &> /dev/null; then
        echo -e "${GREEN}✅ TypeScript:${NC} $(tsc --version)"
    else
        echo -e "${RED}❌ TypeScript not found${NC}"
    fi
    
    if command -v firebase &> /dev/null; then
        echo -e "${GREEN}✅ Firebase CLI:${NC} $(firebase --version)"
    else
        echo -e "${RED}❌ Firebase CLI not found${NC}"
    fi
    
    echo ""
}

create_vscode_settings() {
    log_info "Creating VS Code workspace settings..."
    
    mkdir -p "${PROJECT_ROOT}/.vscode"
    
    # Create settings.json
    cat > "${PROJECT_ROOT}/.vscode/settings.json" << EOF
{
  "typescript.preferences.includePackageJsonAutoImports": "auto",
  "typescript.suggest.autoImports": true,
  "typescript.updateImportsOnFileMove.enabled": "always",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "files.associations": {
    "*.swift": "swift",
    "*.kt": "kotlin",
    "*.cs": "csharp"
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/ios/Pods": true,
    "**/android/build": true,
    "**/windows/bin": true,
    "**/windows/obj": true,
    "**/build": true
  },
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/ios/Pods/**": true,
    "**/android/build/**": true,
    "**/windows/bin/**": true,
    "**/windows/obj/**": true,
    "**/build/**": true
  }
}
EOF
    
    # Create extensions.json
    cat > "${PROJECT_ROOT}/.vscode/extensions.json" << EOF
{
  "recommendations": [
    "ms-vscode.vscode-ios-debug",
    "ms-vscode.vscode-android",
    "ms-dotnettools.csharp",
    "ms-dotnettools.vscode-dotnet-runtime",
    "ms-vscode.vscode-typescript-next",
    "ms-vscode.vscode-json",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-eslint",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-firebase"
  ]
}
EOF
    
    log_info "VS Code workspace configured ✅"
}

main() {
    local start_time=$(date +%s)
    
    check_and_install_homebrew
    setup_common_tools
    setup_ios_development
    setup_android_development
    setup_windows_development
    setup_firebase
    create_development_scripts
    create_vscode_settings
    verify_installation
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo -e "${GREEN}🎉 Development environment setup complete!${NC}"
    echo -e "${GREEN}⏱️  Setup time: ${duration} seconds${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "${BLUE}1. Restart your terminal to load new environment variables${NC}"
    echo -e "${BLUE}2. Open the project in VS Code: code ${PROJECT_ROOT}${NC}"
    echo -e "${BLUE}3. Run platform-specific builds:${NC}"
    echo -e "${BLUE}   • iOS: ./scripts/dev-ios.sh${NC}"
    echo -e "${BLUE}   • Android: ./scripts/dev-android.sh${NC}"
    echo -e "${BLUE}   • Windows: ./scripts/dev-windows.sh${NC}"
    echo -e "${BLUE}4. Use ./scripts/build.sh for full builds${NC}"
    echo ""
}

# Handle script interruption
trap 'log_error "Setup interrupted"; exit 1' INT TERM

# Run main function
main "$@"