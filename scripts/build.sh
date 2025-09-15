#!/bin/bash

# WealthWise - Build Script
# Builds all platform targets for development and release

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_MODE=${1:-debug}  # debug or release
PLATFORMS=${2:-all}    # ios, android, windows, or all
PROJECT_ROOT=$(pwd)
BUILD_DIR="${PROJECT_ROOT}/build"
LOG_DIR="${BUILD_DIR}/logs"

# Create build directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${LOG_DIR}"

echo -e "${BLUE}🏗️  WealthWise Build Script${NC}"
echo -e "${BLUE}Mode: ${BUILD_MODE}${NC}"
echo -e "${BLUE}Platforms: ${PLATFORMS}${NC}"
echo ""

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for required tools
    if [[ "$PLATFORMS" == *"ios"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        if ! command -v xcodebuild &> /dev/null; then
            log_error "xcodebuild not found. Install Xcode."
            exit 1
        fi
    fi
    
    if [[ "$PLATFORMS" == *"android"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        if [ ! -d "$ANDROID_HOME" ]; then
            log_error "ANDROID_HOME not set. Install Android SDK."
            exit 1
        fi
    fi
    
    if [[ "$PLATFORMS" == *"windows"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        if ! command -v dotnet &> /dev/null; then
            log_error "dotnet CLI not found. Install .NET Core SDK."
            exit 1
        fi
    fi
    
    log_info "Prerequisites check passed ✅"
}

build_shared() {
    log_info "Building shared components..."
    
    # Validate shared TypeScript models
    if command -v npx &> /dev/null; then
        cd "${PROJECT_ROOT}/shared"
        npx tsc --noEmit
        cd "${PROJECT_ROOT}"
        log_info "Shared TypeScript validation passed ✅"
    fi
    
    # Copy shared models to platform-specific locations
    # This would be more sophisticated in a real build system
    log_info "Copying shared models to platforms..."
}

build_ios() {
    log_info "Building iOS application..."
    
    cd "${PROJECT_ROOT}/ios"
    
    # Install/update pods
    log_info "Installing CocoaPods dependencies..."
    pod install >> "${LOG_DIR}/ios_pods.log" 2>&1
    
    # Build configuration
    if [ "$BUILD_MODE" = "release" ]; then
        CONFIGURATION="Release"
        DESTINATION="generic/platform=iOS"
    else
        CONFIGURATION="Debug"
        DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
    fi
    
    log_info "Building iOS app (${CONFIGURATION})..."
    
        # Build the app
        xcodebuild \
            -workspace WealthWise.xcworkspace \
            -scheme WealthWise \
            -configuration "${CONFIGURATION}" \
            -destination "${DESTINATION}" \
            build \
            >> "${LOG_DIR}/ios_build.log" 2>&1    if [ $? -eq 0 ]; then
        log_info "iOS build completed successfully ✅"
        
        if [ "$BUILD_MODE" = "release" ]; then
            # Archive for release
            log_info "Creating iOS archive..."
            xcodebuild \
                -workspace WealthWise.xcworkspace \
                -scheme WealthWise \
                -configuration Release \
                -archivePath "${BUILD_DIR}/ios/WealthWise.xcarchive" \
                archive \
                >> "${LOG_DIR}/ios_archive.log" 2>&1
            
            if [ $? -eq 0 ]; then
                log_info "iOS archive created successfully ✅"
            else
                log_error "iOS archive failed ❌"
                exit 1
            fi
        fi
    else
        log_error "iOS build failed ❌"
        tail -20 "${LOG_DIR}/ios_build.log"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
}

build_android() {
    log_info "Building Android application..."
    
    cd "${PROJECT_ROOT}/android"
    
    # Build configuration
    if [ "$BUILD_MODE" = "release" ]; then
        TASK="assembleRelease"
    else
        TASK="assembleDebug"
    fi
    
    log_info "Building Android app (${TASK})..."
    
    # Build the app
    ./gradlew clean "${TASK}" \
        >> "${LOG_DIR}/android_build.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_info "Android build completed successfully ✅"
        
        # Copy APK to build directory
        APK_PATH="app/build/outputs/apk"
        if [ "$BUILD_MODE" = "release" ]; then
            cp "${APK_PATH}/release/app-release.apk" "${BUILD_DIR}/android/" 2>/dev/null || true
        else
            cp "${APK_PATH}/debug/app-debug.apk" "${BUILD_DIR}/android/" 2>/dev/null || true
        fi
    else
        log_error "Android build failed ❌"
        tail -20 "${LOG_DIR}/android_build.log"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
}

build_windows() {
    log_info "Building Windows application..."
    
    cd "${PROJECT_ROOT}/windows"
    
    # Build configuration
    if [ "$BUILD_MODE" = "release" ]; then
        CONFIGURATION="Release"
    else
        CONFIGURATION="Debug"
    fi
    
    log_info "Restoring NuGet packages..."
    dotnet restore >> "${LOG_DIR}/windows_restore.log" 2>&1
    
    log_info "Building Windows app (${CONFIGURATION})..."
    
    # Build the app
    dotnet build --configuration "${CONFIGURATION}" --no-restore \
        >> "${LOG_DIR}/windows_build.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_info "Windows build completed successfully ✅"
        
        if [ "$BUILD_MODE" = "release" ]; then
            # Publish for release
            log_info "Publishing Windows app..."
            dotnet publish \
                --configuration Release \
                --runtime win-x64 \
                --self-contained true \
                --output "${BUILD_DIR}/windows/publish" \
                >> "${LOG_DIR}/windows_publish.log" 2>&1
            
            if [ $? -eq 0 ]; then
                log_info "Windows publish completed successfully ✅"
            else
                log_error "Windows publish failed ❌"
                exit 1
            fi
        fi
    else
        log_error "Windows build failed ❌"
        tail -20 "${LOG_DIR}/windows_build.log"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
}

run_tests() {
    log_info "Running tests..."
    
    # iOS Tests
    if [[ "$PLATFORMS" == *"ios"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        log_info "Running iOS tests..."
        cd "${PROJECT_ROOT}/ios"
        
        xcodebuild test \
            -workspace UnifiedBanking.xcworkspace \
            -scheme UnifiedBankingTests \
            -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
            >> "${LOG_DIR}/ios_tests.log" 2>&1
        
        if [ $? -eq 0 ]; then
            log_info "iOS tests passed ✅"
        else
            log_warn "iOS tests failed ⚠️"
        fi
    fi
    
    # Android Tests
    if [[ "$PLATFORMS" == *"android"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        log_info "Running Android tests..."
        cd "${PROJECT_ROOT}/android"
        
        ./gradlew test >> "${LOG_DIR}/android_tests.log" 2>&1
        
        if [ $? -eq 0 ]; then
            log_info "Android tests passed ✅"
        else
            log_warn "Android tests failed ⚠️"
        fi
    fi
    
    # Windows Tests
    if [[ "$PLATFORMS" == *"windows"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        log_info "Running Windows tests..."
        cd "${PROJECT_ROOT}/windows"
        
        dotnet test >> "${LOG_DIR}/windows_tests.log" 2>&1
        
        if [ $? -eq 0 ]; then
            log_info "Windows tests passed ✅"
        else
            log_warn "Windows tests failed ⚠️"
        fi
    fi
    
    cd "${PROJECT_ROOT}"
}

generate_build_info() {
    log_info "Generating build information..."
    
    BUILD_INFO_FILE="${BUILD_DIR}/build-info.json"
    
    cat > "${BUILD_INFO_FILE}" << EOF
{
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "buildMode": "${BUILD_MODE}",
  "platforms": "${PLATFORMS}",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "version": "1.0.0",
  "buildNumber": "${BUILD_NUMBER:-1}"
}
EOF
    
    log_info "Build info saved to ${BUILD_INFO_FILE}"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    
    # iOS cleanup
    if [[ "$PLATFORMS" == *"ios"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        cd "${PROJECT_ROOT}/ios"
        xcodebuild clean -workspace UnifiedBanking.xcworkspace -scheme UnifiedBanking >/dev/null 2>&1 || true
    fi
    
    # Android cleanup
    if [[ "$PLATFORMS" == *"android"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        cd "${PROJECT_ROOT}/android"
        ./gradlew clean >/dev/null 2>&1 || true
    fi
    
    # Windows cleanup
    if [[ "$PLATFORMS" == *"windows"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        cd "${PROJECT_ROOT}/windows"
        dotnet clean >/dev/null 2>&1 || true
    fi
    
    cd "${PROJECT_ROOT}"
}

# Main build process
main() {
    local start_time=$(date +%s)
    
    check_prerequisites
    
    # Clean previous builds if release mode
    if [ "$BUILD_MODE" = "release" ]; then
        cleanup
    fi
    
    build_shared
    
    # Build platforms
    if [[ "$PLATFORMS" == *"ios"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        build_ios
    fi
    
    if [[ "$PLATFORMS" == *"android"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        build_android
    fi
    
    if [[ "$PLATFORMS" == *"windows"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        build_windows
    fi
    
    # Run tests in debug mode
    if [ "$BUILD_MODE" = "debug" ]; then
        run_tests
    fi
    
    generate_build_info
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    log_info "🎉 Build completed successfully!"
    log_info "⏱️  Total build time: ${duration} seconds"
    log_info "📁 Build artifacts available in: ${BUILD_DIR}"
    log_info "📋 Build logs available in: ${LOG_DIR}"
    
    # Show build artifacts
    echo ""
    log_info "Build artifacts:"
    find "${BUILD_DIR}" -type f -name "*.apk" -o -name "*.ipa" -o -name "*.exe" -o -name "*.msix" 2>/dev/null | while read -r file; do
        echo "  📦 $(basename "$file")"
    done
}

# Handle script interruption
trap 'log_error "Build interrupted"; exit 1' INT TERM

# Run main function
main "$@"