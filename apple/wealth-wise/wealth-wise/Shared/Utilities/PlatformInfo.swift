import SwiftUI
import Foundation

/// Platform and version detection utilities for WealthWise
struct PlatformInfo {
    
    /// Current operating system information
    static let osInfo = ProcessInfo.processInfo.operatingSystemVersion
    
    /// Check if running on macOS
    static var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Check if running on iOS
    static var isIOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Check if running on macOS 26 or later
    static var isMacOS26OrLater: Bool {
        #if os(macOS)
        if #available(macOS 26.0, *) {
            return true
        }
        #endif
        return false
    }
    
    /// Check if running on iOS 26 or later  
    static var isIOS26OrLater: Bool {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }
    
    /// Check if running on macOS 15 or later (minimum supported for WealthWise)
    static var supportsMacOSGlassEffects: Bool {
        #if os(macOS)
        if #available(macOS 26.0, *) {
            return true
        }
        #endif
        return false
    }
    
    /// Check if running on iOS 18 or later (minimum supported for WealthWise)
    static var supportsIOSGlassEffects: Bool {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }
    
    /// Get OS version string for logging/debugging
    static var osVersionString: String {
        let version = osInfo
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    /// Get platform name with version
    static var platformString: String {
        #if os(macOS)
        return "macOS \(osVersionString)"
        #elseif os(iOS)
        return "iOS \(osVersionString)"
        #else
        return "Unknown \(osVersionString)"
        #endif
    }
    
    /// Features available based on platform and version
    struct Features {
        static var advancedGlassEffects: Bool {
            return isMacOS26OrLater || isIOS26OrLater
        }
        
        static var basicGlassEffects: Bool {
            return supportsMacOSGlassEffects || supportsIOSGlassEffects
        }
        
        static var metalPerformanceShaders: Bool {
            // Only supported on our minimum OS versions
            #if os(macOS)
            if #available(macOS 15.0, *) { return true }
            #elseif os(iOS)
            if #available(iOS 18.0, *) { return true }
            #endif
            return false
        }
        
        static var coreML: Bool {
            // Only supported on our minimum OS versions
            #if os(macOS)
            if #available(macOS 15.0, *) { return true }
            #elseif os(iOS)
            if #available(iOS 18.0, *) { return true }
            #endif
            return false
        }
        
        static var widgetKit: Bool {
            // Only supported on our minimum OS versions
            #if os(macOS)
            if #available(macOS 15.0, *) { return true }
            #elseif os(iOS)  
            if #available(iOS 18.0, *) { return true }
            #endif
            return false
        }
        
        static var swiftData: Bool {
            // Only supported on our minimum OS versions
            #if os(macOS)
            if #available(macOS 15.0, *) { return true }
            #elseif os(iOS)
            if #available(iOS 18.0, *) { return true }
            #endif
            return false
        }
    }
}

/// Environment values for platform detection
private struct PlatformInfoEnvironmentKey: EnvironmentKey {
    static let defaultValue = PlatformInfo.self
}

extension EnvironmentValues {
    var platformInfo: PlatformInfo.Type {
        get { self[PlatformInfoEnvironmentKey.self] }
        set { self[PlatformInfoEnvironmentKey.self] = newValue }
    }
}

/// Conditional compilation helpers
extension View {
    
    /// Apply modifiers only on specific platforms
    @ViewBuilder
    func iOS<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        content()
        #else
        self
        #endif
    }
    
    @ViewBuilder  
    func macOS<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(macOS)
        content()
        #else
        self
        #endif
    }
    
    /// Apply modifiers based on version availability
    @ViewBuilder
    func onAdvancedPlatforms<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if PlatformInfo.Features.advancedGlassEffects {
            content()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func onBasicGlassPlatforms<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if PlatformInfo.Features.basicGlassEffects {
            content()
        } else {
            self
        }
    }
}

#if DEBUG
/// Debug view showing platform information
struct PlatformInfoDebugView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                Text("Platform Information")
                    .font(.title2)
                    .bold()
                
                Text("Platform: \(PlatformInfo.platformString)")
                Text("macOS: \(PlatformInfo.isMacOS ? "Yes" : "No")")
                Text("iOS: \(PlatformInfo.isIOS ? "Yes" : "No")")
                
                Divider()
                
                Text("Glass Effect Support")
                    .font(.headline)
                
                Text("Advanced Glass: \(PlatformInfo.Features.advancedGlassEffects ? "Yes" : "No")")
                Text("Basic Glass: \(PlatformInfo.Features.basicGlassEffects ? "Yes" : "No")")
                
                Divider()
                
                Text("Other Features")
                    .font(.headline)
                
                Text("SwiftData: \(PlatformInfo.Features.swiftData ? "Yes" : "No")")
                Text("Core ML: \(PlatformInfo.Features.coreML ? "Yes" : "No")")
                Text("WidgetKit: \(PlatformInfo.Features.widgetKit ? "Yes" : "No")")
                Text("Metal: \(PlatformInfo.Features.metalPerformanceShaders ? "Yes" : "No")")
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Platform Info") {
    PlatformInfoDebugView()
}
#endif