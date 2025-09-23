//
//  HapticFeedbackManager.swift
//  WealthWise
//
//  Created by WealthWise Development Team on 12/28/24.
//  Copyright © 2024 WealthWise. All rights reserved.
//

import Foundation
import os.log

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Cross-platform haptic feedback manager for security and user interactions
/// Provides consistent haptic feedback across iOS and macOS platforms
/// Replaces direct UIKit generator usage for better platform abstraction
@MainActor
public final class HapticFeedbackManager: @unchecked Sendable {
    
    /// Shared singleton instance
    public static let shared = HapticFeedbackManager()
    
    /// Logger for haptic feedback operations
    private let logger = Logger(subsystem: "com.wealthwise.app", category: "HapticFeedback")
    
    #if os(iOS)
    // iOS Haptic Generators
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    #endif
    
    /// Initialize haptic feedback manager
    private init() {
        #if os(iOS)
        // Prepare generators for better performance
        impactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        #endif
        
        logger.info("HapticFeedbackManager initialized")
    }
    
    // MARK: - Impact Feedback
    
    /// Generate light impact feedback
    public func impactLight() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        logger.debug("Light impact feedback triggered")
        #else
        // macOS fallback - system sound
        NSSound.beep()
        logger.debug("Light impact feedback (macOS beep) triggered")
        #endif
    }
    
    /// Generate medium impact feedback
    public func impactMedium() {
        #if os(iOS)
        impactGenerator.impactOccurred()
        logger.debug("Medium impact feedback triggered")
        #else
        // macOS fallback - system sound
        NSSound.beep()
        logger.debug("Medium impact feedback (macOS beep) triggered")
        #endif
    }
    
    /// Generate heavy impact feedback
    public func impactHeavy() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        logger.debug("Heavy impact feedback triggered")
        #else
        // macOS fallback - system sound
        NSSound.beep()
        logger.debug("Heavy impact feedback (macOS beep) triggered")
        #endif
    }
    
    /// Generate impact feedback with specified intensity
    /// - Parameter intensity: The intensity level for the feedback
    public func impact(_ intensity: HapticIntensity) {
        switch intensity {
        case .light:
            impactLight()
        case .medium:
            impactMedium()
        case .heavy:
            impactHeavy()
        }
    }
    
    // MARK: - Selection Feedback
    
    /// Generate selection feedback for UI interactions
    public func selection() {
        #if os(iOS)
        selectionGenerator.selectionChanged()
        logger.debug("Selection feedback triggered")
        #else
        // macOS fallback - subtle system sound
        if let sound = NSSound(named: NSSound.Name("Tink")) {
            sound.play()
        } else {
            NSSound.beep()
        }
        logger.debug("Selection feedback (macOS sound) triggered")
        #endif
    }
    
    // MARK: - Notification Feedback
    
    /// Generate success notification feedback
    public func notificationSuccess() {
        #if os(iOS)
        notificationGenerator.notificationOccurred(.success)
        logger.debug("Success notification feedback triggered")
        #else
        // macOS fallback - success sound
        if let sound = NSSound(named: NSSound.Name("Glass")) {
            sound.play()
        } else {
            NSSound.beep()
        }
        logger.debug("Success notification feedback (macOS sound) triggered")
        #endif
    }
    
    /// Generate warning notification feedback
    public func notificationWarning() {
        #if os(iOS)
        notificationGenerator.notificationOccurred(.warning)
        logger.debug("Warning notification feedback triggered")
        #else
        // macOS fallback - warning sound
        if let sound = NSSound(named: NSSound.Name("Sosumi")) {
            sound.play()
        } else {
            NSSound.beep()
        }
        logger.debug("Warning notification feedback (macOS sound) triggered")
        #endif
    }
    
    /// Generate error notification feedback
    public func notificationError() {
        #if os(iOS)
        notificationGenerator.notificationOccurred(.error)
        logger.debug("Error notification feedback triggered")
        #else
        // macOS fallback - error sound
        if let sound = NSSound(named: NSSound.Name("Basso")) {
            sound.play()
        } else {
            NSSound.beep()
        }
        logger.debug("Error notification feedback (macOS sound) triggered")
        #endif
    }
    
    /// Generate notification feedback with specified type
    /// - Parameter type: The type of notification feedback
    public func notification(_ type: HapticNotificationType) {
        switch type {
        case .success:
            notificationSuccess()
        case .warning:
            notificationWarning()
        case .error:
            notificationError()
        }
    }
    
    // MARK: - Security-Specific Feedback
    
    /// Trigger haptic feedback for authentication success
    public func authenticationSuccess() {
        #if os(iOS)
        // Double success pattern for security actions
        notificationSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactLight()
        }
        #else
        notificationSuccess()
        #endif
    }
    
    /// Trigger haptic feedback for authentication failure
    public func authenticationFailure() {
        #if os(iOS)
        // Triple error pattern for failed security actions
        notificationError()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notificationError()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.notificationError()
        }
        #else
        notificationError()
        #endif
    }
    
    /// Trigger haptic feedback for biometric prompt
    public func biometricPrompt() {
        #if os(iOS)
        impactLight()
        #else
        selection()
        #endif
    }
}

// MARK: - Supporting Types

/// Haptic feedback intensity levels
public enum HapticIntensity: CaseIterable, Sendable {
    case light
    case medium
    case heavy
    
    /// Display name for the intensity
    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
}

/// Haptic notification feedback types
public enum HapticNotificationType: CaseIterable, Sendable {
    case success
    case warning
    case error
    
    /// Display name for the notification type
    public var displayName: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI View extension for easy haptic feedback
@available(iOS 16.0, macOS 13.0, *)
extension View {
    /// Add haptic feedback to button tap
    public func hapticFeedback(_ intensity: HapticIntensity = .medium) -> some View {
        self.onTapGesture {
            HapticFeedbackManager.shared.impact(intensity)
        }
    }
    
    /// Add haptic feedback with custom action
    public func hapticFeedback<T>(_ intensity: HapticIntensity = .medium, value: T) -> some View where T: Equatable {
        self.onChange(of: value) { _, _ in
            HapticFeedbackManager.shared.impact(intensity)
        }
    }
}
#endif