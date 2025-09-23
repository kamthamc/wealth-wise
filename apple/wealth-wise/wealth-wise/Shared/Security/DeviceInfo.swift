//
//  DeviceInfo.swift
//  WealthWise
//
//  Cross-platform device information utility for Security & Authentication Foundation System
//  Created: Part of Issue #4 - Authentication & Security Layer implementation
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Cross-platform device information provider
/// Provides consistent device information across iOS, macOS, and other Apple platforms
@MainActor
public final class DeviceInfo: @unchecked Sendable {
    
    // MARK: - Singleton
    public static let shared = DeviceInfo()
    
    private init() {}
    
    // MARK: - Device Properties
    
    /// Device model identifier (e.g., "iPhone", "iPad", "Mac")
    public var model: String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        return "Mac"
        #elseif os(watchOS)
        return "Apple Watch"
        #elseif os(tvOS)
        return "Apple TV"
        #else
        return "Unknown Device"
        #endif
    }
    
    /// System version string (e.g., "18.6.1", "15.2")
    public var systemVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(tvOS)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }
    
    /// Operating system name
    public var systemName: String {
        #if os(iOS)
        return UIDevice.current.systemName
        #elseif os(macOS)
        return "macOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #else
        return "Unknown OS"
        #endif
    }
    
    /// Vendor-specific device identifier
    public var identifierForVendor: String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(macOS)
        // Use hardware UUID for macOS
        return getHardwareUUID() ?? UUID().uuidString
        #elseif os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(tvOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        return UUID().uuidString
        #endif
    }
    
    /// User interface idiom (phone, pad, mac, etc.)
    public var userInterfaceIdiom: UserInterfaceIdiom {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .phone
        case .pad:
            return .pad
        case .tv:
            return .tv
        case .carPlay:
            return .carPlay
        case .mac:
            return .mac
        case .vision:
            return .vision
        @unknown default:
            return .unspecified
        }
        #elseif os(macOS)
        return .mac
        #elseif os(watchOS)
        return .watch
        #elseif os(tvOS)
        return .tv
        #else
        return .unspecified
        #endif
    }
    
    /// Whether the device is running in a simulator
    public var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return model.contains("Simulator")
        #endif
    }
    
    /// Device hardware architecture
    public var architecture: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        return machine
    }
    
    // MARK: - Security Specific Properties
    
    /// Enhanced device fingerprint for security validation
    public var securityFingerprint: String {
        let components = [
            model,
            systemVersion,
            architecture,
            identifierForVendor
        ]
        return components.joined(separator: "|")
    }
    
    /// Device capabilities assessment for security features
    public var securityCapabilities: SecurityCapabilities {
        var capabilities = SecurityCapabilities()
        
        #if os(iOS)
        capabilities.hasBiometrics = true
        capabilities.hasSecureEnclave = !isSimulator // Assume real devices have Secure Enclave
        capabilities.supportsPasskeys = true
        
        // Enhanced iOS 18.6+ capabilities
        if #available(iOS 18.6, *) {
            capabilities.hasAdvancedBiometrics = true
            capabilities.supportsOpticID = userInterfaceIdiom == .vision
            capabilities.supportsVoiceID = true
        }
        
        #elseif os(macOS)
        capabilities.hasBiometrics = hasTouchID() || hasFaceID()
        capabilities.hasSecureEnclave = hasSecureEnclave()
        capabilities.supportsPasskeys = true
        
        if #available(macOS 15.6, *) {
            capabilities.hasAdvancedBiometrics = true
        }
        
        #endif
        
        return capabilities
    }
    
    // MARK: - Private Helpers
    
    #if os(macOS)
    private func getHardwareUUID() -> String? {
        let platformExpertRef = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        guard platformExpertRef != 0 else {
            return nil
        }
        
        defer {
            IOObjectRelease(platformExpertRef)
        }
        
        let serialNumberKey = "IOPlatformSerialNumber"
        let serialNumberRef = IORegistryEntryCreateCFProperty(
            platformExpertRef,
            serialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        )
        
        return serialNumberRef?.takeRetainedValue() as? String
    }
    
    private func hasTouchID() -> Bool {
        // Check for Touch ID availability on macOS
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    private func hasFaceID() -> Bool {
        // Face ID is not available on macOS as of 2024
        return false
    }
    
    private func hasSecureEnclave() -> Bool {
        // Check if the Mac has a Secure Enclave (T2, T3, or Apple Silicon)
        let architecture = self.architecture
        return architecture.hasPrefix("arm64") || // Apple Silicon
               architecture.contains("T2") ||      // Intel with T2
               architecture.contains("T3")         // Future T3 chip
    }
    #endif
}

// MARK: - Supporting Types

/// Cross-platform user interface idiom enumeration
public enum UserInterfaceIdiom: String, CaseIterable, Sendable {
    case phone
    case pad
    case tv
    case carPlay
    case mac
    case watch
    case vision
    case unspecified
    
    /// Localized display name for the idiom
    public var displayName: String {
        switch self {
        case .phone: return "iPhone"
        case .pad: return "iPad"
        case .tv: return "Apple TV"
        case .carPlay: return "CarPlay"
        case .mac: return "Mac"
        case .watch: return "Apple Watch"
        case .vision: return "Apple Vision Pro"
        case .unspecified: return "Unknown Device"
        }
    }
}

/// Device security capabilities assessment
public struct SecurityCapabilities: Sendable {
    public var hasBiometrics: Bool = false
    public var hasSecureEnclave: Bool = false
    public var hasAdvancedBiometrics: Bool = false
    public var supportsOpticID: Bool = false
    public var supportsVoiceID: Bool = false
    public var supportsPasskeys: Bool = false
    
    public init() {}
    
    /// Overall security level assessment
    public var securityLevel: SecurityLevel {
        if hasAdvancedBiometrics && hasSecureEnclave && supportsPasskeys {
            return .maximum
        } else if hasBiometrics && hasSecureEnclave {
            return .high
        } else if hasBiometrics || hasSecureEnclave {
            return .medium
        } else {
            return .basic
        }
    }
}

// MARK: - Required Imports for Platform-Specific Features

#if os(watchOS)
import WatchKit
#endif

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

#if canImport(IOKit)
import IOKit
#endif