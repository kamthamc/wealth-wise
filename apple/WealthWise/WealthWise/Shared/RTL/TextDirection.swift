//
//  TextDirection.swift
//  WealthWise
//
//  Comprehensive text direction detection and management for RTL support
//

import Foundation
import SwiftUI
import Combine

/// Text direction enumeration for comprehensive RTL/LTR support
public enum TextDirection: String, CaseIterable, Codable, Sendable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"
    case auto = "auto"
    
    /// Display name for the text direction
    public var displayName: String {
        switch self {
        case .leftToRight:
            return NSLocalizedString("textDirection.leftToRight", comment: "Left-to-Right text direction")
        case .rightToLeft:
            return NSLocalizedString("textDirection.rightToLeft", comment: "Right-to-Left text direction")
        case .auto:
            return NSLocalizedString("textDirection.auto", comment: "Automatic text direction detection")
        }
    }
    
    /// SwiftUI layout direction equivalent
    public var layoutDirection: LayoutDirection {
        switch self {
        case .leftToRight:
            return .leftToRight
        case .rightToLeft:
            return .rightToLeft
        case .auto:
            return .leftToRight // Default fallback
        }
    }
    
    /// Check if this direction is RTL
    public var isRTL: Bool {
        return self == .rightToLeft
    }
    
    /// Check if this direction is LTR
    public var isLTR: Bool {
        return self == .leftToRight
    }
}

/// Text direction detector for automatic RTL/LTR detection
@MainActor
public final class TextDirectionDetector: ObservableObject {
    @Published public private(set) var currentDirection: TextDirection = .auto
    @Published public private(set) var detectedDirection: TextDirection = .leftToRight
    
    private let rtlLanguageCodes: Set<String> = [
        "ar", "he", "fa", "ur", "yi", "ji", "iw", "dv", "ha", "ps"
    ]
    
    private let rtlScripts: Set<String> = [
        "Arab", "Hebr", "Thaa", "Nkoo", "Syrc"
    ]
    
    public init() {
        detectSystemDirection()
        observeLocaleChanges()
    }
    
    /// Detect text direction from system locale
    public func detectSystemDirection() {
        let locale = Locale.current
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        
        if rtlLanguageCodes.contains(languageCode) {
            detectedDirection = .rightToLeft
        } else {
            detectedDirection = .leftToRight
        }
        
        if currentDirection == .auto {
            currentDirection = detectedDirection
        }
    }
    
    /// Detect text direction from specific text content
    public func detectDirection(from text: String) -> TextDirection {
        guard !text.isEmpty else { return detectedDirection }
        
        let rtlCharacterSet = CharacterSet(charactersIn: "\u{0600}-\u{06FF}\u{0750}-\u{077F}\u{08A0}-\u{08FF}\u{FB50}-\u{FDFF}\u{FE70}-\u{FEFF}\u{0590}-\u{05FF}")
        
        let rtlCount = text.unicodeScalars.filter { rtlCharacterSet.contains($0) }.count
        let totalCount = text.unicodeScalars.count
        
        if rtlCount > totalCount / 2 {
            return .rightToLeft
        } else if rtlCount > 0 {
            return .auto // Mixed content
        } else {
            return .leftToRight
        }
    }
    
    /// Detect text direction from specific text content (alias for consistency)
    public func detectDirection(for text: String) -> TextDirection {
        return detectDirection(from: text)
    }
    
    /// Set explicit text direction
    public func setDirection(_ direction: TextDirection) {
        currentDirection = direction
        if direction == .auto {
            detectSystemDirection()
        }
    }
    
    /// Check if current locale uses RTL
    public func isCurrentLocaleRTL() -> Bool {
        let locale = Locale.current
        return Locale.Language(identifier: locale.identifier).characterDirection == .rightToLeft
    }
    
    private func observeLocaleChanges() {
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.detectSystemDirection()
            }
        }
    }
}

/// Environment key for text direction
struct TextDirectionKey: EnvironmentKey {
    static let defaultValue: TextDirection = .auto
}

public extension EnvironmentValues {
    var textDirection: TextDirection {
        get { self[TextDirectionKey.self] }
        set { self[TextDirectionKey.self] = newValue }
    }
}

/// SwiftUI View extension for text direction support
public extension View {
    func textDirection(_ direction: TextDirection) -> some View {
        environment(\.textDirection, direction)
    }
    
    func autoTextDirection() -> some View {
        environment(\.textDirection, .auto)
    }
}
