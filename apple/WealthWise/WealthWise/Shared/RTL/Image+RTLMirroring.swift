//
//  Image+RTLMirroring.swift
//  WealthWise
//
//  SwiftUI Image extensions for comprehensive RTL mirroring support
//

import SwiftUI

public extension Image {
    
    /// Apply RTL-aware mirroring based on image type
    func rtlMirrored(_ shouldMirror: Bool = true) -> some View {
        self.modifier(RTLImageMirrorModifier(shouldMirror: shouldMirror))
    }
    
    /// Apply smart RTL mirroring based on image content type
    func smartRTLMirroring(type: RTLImageType = .auto) -> some View {
        self.modifier(SmartRTLMirrorModifier(imageType: type))
    }
    
    /// Apply directional mirroring with animation
    func rtlMirroredAnimated(
        _ shouldMirror: Bool = true,
        animation: Animation = .easeInOut(duration: 0.3)
    ) -> some View {
        self.modifier(AnimatedRTLMirrorModifier(shouldMirror: shouldMirror, animation: animation))
    }
    
    /// Apply conditional RTL mirroring based on layout direction
    func conditionalRTLMirroring(when condition: Bool = true) -> some View {
        self.modifier(ConditionalRTLMirrorModifier(condition: condition))
    }
    
    /// Apply RTL-aware icon mirroring with accessibility support
    func rtlIcon(type: RTLIconType = .navigational) -> some View {
        self.modifier(RTLIconModifier(iconType: type))
    }
}

// MARK: - RTL Image Types

/// Types of images for RTL mirroring decisions
public enum RTLImageType {
    case auto
    case navigational    // Arrows, chevrons - should mirror
    case directional     // Progress indicators - should mirror
    case content         // Photos, logos - should not mirror
    case symbol          // UI symbols - context dependent
    case text            // Text-based images - should mirror
    case decorative      // Decorative elements - may mirror
}

/// Types of icons for RTL support
public enum RTLIconType {
    case navigational    // Back/forward arrows
    case directional     // Progress, sorting
    case action          // Share, settings
    case status          // Success, error
    case content         // Profile, document icons
}

// MARK: - RTL Image Modifiers

/// Basic RTL image mirror modifier
struct RTLImageMirrorModifier: ViewModifier {
    let shouldMirror: Bool
    @Environment(\.layoutDirection) private var layoutDirection
    
    func body(content: Content) -> some View {
        if shouldMirror && layoutDirection == .rightToLeft {
            content
                .scaleEffect(x: -1, y: 1)
        } else {
            content
        }
    }
}

/// Smart RTL mirror modifier with image type awareness
struct SmartRTLMirrorModifier: ViewModifier {
    let imageType: RTLImageType
    @Environment(\.layoutDirection) private var layoutDirection
    @StateObject private var layoutManager = RTLLayoutManager()
    
    private var shouldMirror: Bool {
        guard layoutDirection == .rightToLeft else { return false }
        
        switch imageType {
        case .auto:
            return true
        case .navigational, .directional, .text:
            return true
        case .content:
            return false
        case .symbol:
            return true // Default to mirroring symbols in RTL
        case .decorative:
            return false // Decorative elements typically don't mirror
        }
    }
    
    func body(content: Content) -> some View {
        if shouldMirror {
            content
                .scaleEffect(x: -1, y: 1)
        } else {
            content
        }
    }
}

/// Animated RTL mirror modifier
struct AnimatedRTLMirrorModifier: ViewModifier {
    let shouldMirror: Bool
    let animation: Animation
    @Environment(\.layoutDirection) private var layoutDirection
    
    @State private var isFlipped = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
            .onAppear {
                if shouldMirror && layoutDirection == .rightToLeft {
                    withAnimation(animation) {
                        isFlipped = true
                    }
                }
            }
            .onChange(of: layoutDirection) { oldDirection, newDirection in
                withAnimation(animation) {
                    isFlipped = shouldMirror && newDirection == .rightToLeft
                }
            }
    }
}

/// Conditional RTL mirror modifier
struct ConditionalRTLMirrorModifier: ViewModifier {
    let condition: Bool
    @Environment(\.layoutDirection) private var layoutDirection
    
    func body(content: Content) -> some View {
        if condition && layoutDirection == .rightToLeft {
            content
                .scaleEffect(x: -1, y: 1)
        } else {
            content
        }
    }
}

/// RTL icon modifier with accessibility
struct RTLIconModifier: ViewModifier {
    let iconType: RTLIconType
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.rtlAccessibilityHelper) private var accessibilityHelper
    
    private var shouldMirror: Bool {
        guard layoutDirection == .rightToLeft else { return false }
        
        switch iconType {
        case .navigational, .directional:
            return true
        case .action:
            return false // Most action icons don't need mirroring
        case .status:
            return false // Status icons typically don't mirror
        case .content:
            return false // Content icons should maintain orientation
        }
    }
    
    private var accessibilityLabel: String {
        switch iconType {
        case .navigational:
            return NSLocalizedString("accessibility.icon.navigation", comment: "Navigation icon")
        case .directional:
            return NSLocalizedString("accessibility.icon.directional", comment: "Directional icon")
        case .action:
            return NSLocalizedString("accessibility.icon.action", comment: "Action icon")
        case .status:
            return NSLocalizedString("accessibility.icon.status", comment: "Status icon")
        case .content:
            return NSLocalizedString("accessibility.icon.content", comment: "Content icon")
        }
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: shouldMirror ? -1 : 1, y: 1)
            .accessibilityLabel(accessibilityHelper.createAccessibilityLabel(
                for: accessibilityLabel,
                context: "icon"
            ))
    }
}

// MARK: - RTL Image Helpers

/// Helper view for RTL-aware SF Symbols
public struct RTLSymbol: View {
    let systemName: String
    let type: RTLImageType
    let size: CGFloat
    let color: Color
    
    public init(
        systemName: String,
        type: RTLImageType = .auto,
        size: CGFloat = 16,
        color: Color = .primary
    ) {
        self.systemName = systemName
        self.type = type
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundColor(color)
            .modifier(SmartRTLMirrorModifier(imageType: type))
    }
}

/// Helper view for RTL-aware custom images
public struct RTLImage: View {
    let imageName: String
    let type: RTLImageType
    let width: CGFloat?
    let height: CGFloat?
    
    public init(
        _ imageName: String,
        type: RTLImageType = .auto,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.imageName = imageName
        self.type = type
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
            .modifier(SmartRTLMirrorModifier(imageType: type))
    }
}

/// Helper for creating navigation arrows that properly mirror
public struct RTLNavigationArrow: View {
    let direction: ArrowDirection
    let size: CGFloat
    let color: Color
    
    public enum ArrowDirection {
        case back, forward, up, down
        
        var systemName: String {
            switch self {
            case .back: return "chevron.left"
            case .forward: return "chevron.right"
            case .up: return "chevron.up"
            case .down: return "chevron.down"
            }
        }
    }
    
    public init(
        direction: ArrowDirection,
        size: CGFloat = 16,
        color: Color = .primary
    ) {
        self.direction = direction
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        RTLSymbol(
            systemName: direction.systemName,
            type: .navigational,
            size: size,
            color: color
        )
    }
}
