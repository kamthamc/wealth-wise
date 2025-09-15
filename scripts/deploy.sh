#!/bin/bash

# WealthWise - Deployment Script
# Handles deployment to various environments and app stores

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-staging}  # staging, production
PLATFORMS=${2:-all}       # ios, android, windows, or all
PROJECT_ROOT=$(pwd)
BUILD_DIR="${PROJECT_ROOT}/build"
DEPLOY_DIR="${BUILD_DIR}/deploy"

echo -e "${BLUE}🚀 WealthWise - Deployment Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Platforms: ${PLATFORMS}${NC}"
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

check_prerequisites() {
    log_info "Checking deployment prerequisites..."
    
    # Check for required environment variables
    if [ "$ENVIRONMENT" = "production" ]; then
        if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
            log_error "Apple ID credentials not set for production deployment"
            exit 1
        fi
        
        if [ -z "$PLAY_STORE_KEY_FILE" ]; then
            log_error "Google Play Store key file not set for production deployment"
            exit 1
        fi
    fi
    
    # Check for fastlane
    if ! command -v fastlane &> /dev/null; then
        log_error "fastlane not found. Run setup-dev.sh first."
        exit 1
    fi
    
    # Check for Firebase CLI
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI not found. Run setup-dev.sh first."
        exit 1
    fi
    
    log_info "Prerequisites check passed ✅"
}

setup_deployment_environment() {
    log_info "Setting up deployment environment..."
    
    mkdir -p "${DEPLOY_DIR}"
    
    # Create deployment configuration
    cat > "${DEPLOY_DIR}/deploy-config.json" << EOF
{
  "environment": "${ENVIRONMENT}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "version": "1.0.0",
  "buildNumber": "${BUILD_NUMBER:-$(date +%s)}",
  "platforms": "${PLATFORMS}",
  "firebase": {
    "project": "${ENVIRONMENT === 'production' ? 'unified-banking-prod' : 'unified-banking-dev'}"
  }
}
EOF
    
    log_info "Deployment environment configured ✅"
}

deploy_firebase() {
    log_info "Deploying Firebase backend..."
    
    cd "${PROJECT_ROOT}"
    
    # Set Firebase project
    if [ "$ENVIRONMENT" = "production" ]; then
        firebase use wealthwise-prod || firebase use --add wealthwise-prod
    else
        firebase use wealthwise-dev || firebase use --add wealthwise-dev
    fi
    
    # Deploy Firestore rules and indexes
    log_info "Deploying Firestore rules and indexes..."
    firebase deploy --only firestore
    
    # Deploy Storage rules
    log_info "Deploying Storage rules..."
    firebase deploy --only storage
    
    # Deploy Functions (if they exist)
    if [ -d "functions" ]; then
        log_info "Deploying Cloud Functions..."
        firebase deploy --only functions
    fi
    
    log_info "Firebase deployment completed ✅"
}

deploy_ios() {
    log_info "Deploying iOS application..."
    
    cd "${PROJECT_ROOT}/ios"
    
    # Initialize fastlane if not already done
    if [ ! -f "fastlane/Fastfile" ]; then
        log_info "Initializing fastlane for iOS..."
        fastlane init
    fi
    
    # Create/update Fastfile
    mkdir -p fastlane
    cat > fastlane/Fastfile << 'EOF'
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "UnifiedBanking.xcodeproj")
    
    # Build the app
    build_app(
      workspace: "UnifiedBanking.xcworkspace",
      scheme: "UnifiedBanking",
      configuration: "Release",
      export_method: "app-store"
    )
    
    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      skip_submission: true
    )
  end
  
  desc "Build and upload to App Store"
  lane :release do
    # Increment build number
    increment_build_number(xcodeproj: "UnifiedBanking.xcodeproj")
    
    # Build the app
    build_app(
      workspace: "UnifiedBanking.xcworkspace",
      scheme: "UnifiedBanking",
      configuration: "Release",
      export_method: "app-store"
    )
    
    # Upload to App Store
    upload_to_app_store(
      force: true,
      reject_if_possible: true,
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: false,
      automatic_release: false
    )
  end
end
EOF
    
    # Deploy based on environment
    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Deploying to App Store..."
        fastlane release
    else
        log_info "Deploying to TestFlight..."
        fastlane beta
    fi
    
    log_info "iOS deployment completed ✅"
    cd "${PROJECT_ROOT}"
}

deploy_android() {
    log_info "Deploying Android application..."
    
    cd "${PROJECT_ROOT}/android"
    
    # Initialize fastlane if not already done
    if [ ! -f "fastlane/Fastfile" ]; then
        log_info "Initializing fastlane for Android..."
        fastlane init
    fi
    
    # Create/update Fastfile
    mkdir -p fastlane
    cat > fastlane/Fastfile << 'EOF'
default_platform(:android)

platform :android do
  desc "Build and upload to Google Play Internal Testing"
  lane :internal do
    # Build the app
    gradle(
      task: "clean bundleRelease",
      project_dir: "."
    )
    
    # Upload to Google Play Internal Testing
    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      skip_upload_apk: true,
      skip_upload_metadata: true,
      skip_upload_changelogs: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
  
  desc "Build and upload to Google Play Beta"
  lane :beta do
    # Build the app
    gradle(
      task: "clean bundleRelease",
      project_dir: "."
    )
    
    # Upload to Google Play Beta
    upload_to_play_store(
      track: "beta",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      skip_upload_apk: true,
      skip_upload_metadata: true,
      skip_upload_changelogs: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
  
  desc "Build and upload to Google Play Production"
  lane :release do
    # Build the app
    gradle(
      task: "clean bundleRelease",
      project_dir: "."
    )
    
    # Upload to Google Play Production
    upload_to_play_store(
      track: "production",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      skip_upload_apk: true,
      skip_upload_metadata: false,
      skip_upload_changelogs: false,
      skip_upload_images: false,
      skip_upload_screenshots: false
    )
  end
end
EOF
    
    # Deploy based on environment
    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Deploying to Google Play Production..."
        fastlane release
    else
        log_info "Deploying to Google Play Internal Testing..."
        fastlane internal
    fi
    
    log_info "Android deployment completed ✅"
    cd "${PROJECT_ROOT}"
}

deploy_windows() {
    log_info "Deploying Windows application..."
    
    cd "${PROJECT_ROOT}/windows"
    
    # Build for release
    log_info "Building Windows release package..."
    dotnet publish \
        --configuration Release \
        --runtime win-x64 \
        --self-contained true \
        --output "${DEPLOY_DIR}/windows" \
        -p:PublishSingleFile=true \
        -p:IncludeNativeLibrariesForSelfExtract=true
    
    # Create installer (using WiX if available)
    if command -v candle &> /dev/null && command -v light &> /dev/null; then
        log_info "Creating Windows installer..."
        
        # Create basic WiX configuration
        cat > installer.wxs << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="Unified Banking" Language="1033" Version="1.0.0.0" 
           Manufacturer="Unified Banking Inc." UpgradeCode="{YOUR-UPGRADE-CODE}">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />
    
    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />
    <MediaTemplate EmbedCab="yes" />
    
    <Feature Id="ProductFeature" Title="Unified Banking" Level="1">
      <ComponentRef Id="ProductComponent" />
    </Feature>
    
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="Unified Banking" />
      </Directory>
    </Directory>
    
    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="ProductComponent" Guid="*">
        <File Id="UnifiedBankingExe" Source="${DEPLOY_DIR}/windows/UnifiedBanking.exe" 
              KeyPath="yes" Checksum="yes" />
      </Component>
    </DirectoryRef>
  </Product>
</Wix>
EOF
        
        candle installer.wxs
        light installer.wixobj -o "${DEPLOY_DIR}/UnifiedBankingSetup.msi"
        
        log_info "Windows installer created ✅"
    else
        log_warn "WiX Toolset not found. Skipping installer creation."
    fi
    
    # Create ZIP package
    log_info "Creating Windows ZIP package..."
    cd "${DEPLOY_DIR}"
    zip -r "UnifiedBanking-Windows-${ENVIRONMENT}.zip" windows/
    
    log_info "Windows deployment completed ✅"
    cd "${PROJECT_ROOT}"
}

create_deployment_manifest() {
    log_info "Creating deployment manifest..."
    
    MANIFEST_FILE="${DEPLOY_DIR}/deployment-manifest.json"
    
    cat > "${MANIFEST_FILE}" << EOF
{
  "deployment": {
    "id": "$(uuidgen | tr '[:upper:]' '[:lower:]')",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "environment": "${ENVIRONMENT}",
    "version": "1.0.0",
    "buildNumber": "${BUILD_NUMBER:-$(date +%s)}",
    "platforms": "${PLATFORMS}",
    "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  },
  "artifacts": {
    "ios": {
      "available": $([ "$PLATFORMS" = "all" ] || [ "$PLATFORMS" = "ios" ] && echo "true" || echo "false"),
      "testflight": "${ENVIRONMENT != 'production'}",
      "appstore": "${ENVIRONMENT == 'production'}"
    },
    "android": {
      "available": $([ "$PLATFORMS" = "all" ] || [ "$PLATFORMS" = "android" ] && echo "true" || echo "false"),
      "playstore_track": "${ENVIRONMENT == 'production' ? 'production' : 'internal'}"
    },
    "windows": {
      "available": $([ "$PLATFORMS" = "all" ] || [ "$PLATFORMS" = "windows" ] && echo "true" || echo "false"),
      "installer": "UnifiedBankingSetup.msi",
      "portable": "UnifiedBanking-Windows-${ENVIRONMENT}.zip"
    }
  },
  "firebase": {
    "project": "${ENVIRONMENT == 'production' ? 'unified-banking-prod' : 'unified-banking-dev'}",
    "deployed": true
  }
}
EOF
    
    log_info "Deployment manifest created: ${MANIFEST_FILE}"
}

send_deployment_notification() {
    log_info "Sending deployment notification..."
    
    # This would typically integrate with Slack, Discord, or email
    # For now, just create a notification file
    
    NOTIFICATION_FILE="${DEPLOY_DIR}/deployment-notification.md"
    
    cat > "${NOTIFICATION_FILE}" << EOF
# 🚀 Deployment Complete

## Deployment Details
- **Environment**: ${ENVIRONMENT}
- **Version**: 1.0.0
- **Build**: ${BUILD_NUMBER:-$(date +%s)}
- **Timestamp**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Platforms**: ${PLATFORMS}

## Artifacts Deployed
$([ "$PLATFORMS" = "all" ] || [ "$PLATFORMS" = "ios" ] && echo "- 📱 **iOS**: Uploaded to $([ "$ENVIRONMENT" = "production" ] && echo "App Store" || echo "TestFlight")")
$([ "$PLATFORMS" = "all" ] || [ "$PLATFORMS" = "android" ] && echo "- 🤖 **Android**: Uploaded to Google Play $([ "$ENVIRONMENT" = "production" ] && echo "Production" || echo "Internal Testing")")
$([ "$PLATFORMS" = "all" ] || [ "$PLATFORMS" = "windows" ] && echo "- 🪟 **Windows**: Package created and ready for distribution")

## Firebase Backend
- **Project**: ${ENVIRONMENT == 'production' ? 'unified-banking-prod' : 'unified-banking-dev'}
- **Firestore**: Rules and indexes deployed
- **Storage**: Rules deployed
- **Functions**: $([ -d "functions" ] && echo "Deployed" || echo "N/A")

## Git Information
- **Commit**: $(git rev-parse HEAD 2>/dev/null || echo 'unknown')
- **Branch**: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')

---
*Generated by deployment script at $(date)*
EOF
    
    log_info "Deployment notification saved: ${NOTIFICATION_FILE}"
}

rollback_deployment() {
    log_error "Deployment failed! Starting rollback process..."
    
    # This would implement rollback logic for each platform
    # For now, just log the rollback request
    
    ROLLBACK_FILE="${DEPLOY_DIR}/rollback-$(date +%s).log"
    
    cat > "${ROLLBACK_FILE}" << EOF
ROLLBACK REQUESTED
==================
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Environment: ${ENVIRONMENT}
Platforms: ${PLATFORMS}
Reason: Deployment script failure

Required Actions:
1. Revert Firebase deployment if completed
2. Remove failed app store uploads
3. Restore previous version if necessary

EOF
    
    log_error "Rollback information saved: ${ROLLBACK_FILE}"
}

main() {
    local start_time=$(date +%s)
    
    # Set up error handling for rollback
    trap rollback_deployment ERR
    
    check_prerequisites
    setup_deployment_environment
    
    # Build first (using the build script)
    log_info "Building applications for deployment..."
    "${PROJECT_ROOT}/scripts/build.sh" release "${PLATFORMS}"
    
    # Deploy Firebase backend
    deploy_firebase
    
    # Deploy platforms
    if [[ "$PLATFORMS" == *"ios"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        deploy_ios
    fi
    
    if [[ "$PLATFORMS" == *"android"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        deploy_android
    fi
    
    if [[ "$PLATFORMS" == *"windows"* ]] || [[ "$PLATFORMS" == "all" ]]; then
        deploy_windows
    fi
    
    create_deployment_manifest
    send_deployment_notification
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    log_info "🎉 Deployment completed successfully!"
    log_info "⏱️  Total deployment time: ${duration} seconds"
    log_info "📁 Deployment artifacts: ${DEPLOY_DIR}"
    log_info "📋 Deployment manifest: ${DEPLOY_DIR}/deployment-manifest.json"
    
    # Clear error trap
    trap - ERR
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; rollback_deployment; exit 1' INT TERM

# Show usage if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <environment> [platforms]"
    echo "  environment: staging, production"
    echo "  platforms: ios, android, windows, all (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0 staging ios"
    echo "  $0 production all"
    exit 1
fi

# Run main function
main "$@"