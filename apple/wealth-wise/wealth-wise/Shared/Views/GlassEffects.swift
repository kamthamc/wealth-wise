import SwiftUI
import Foundation

/// Glass effect utilities for modern macOS and iOS versions
@available(macOS 14.0, iOS 17.0, *)
struct GlassEffectHelpers {
    
    /// Check if the current OS supports advanced glass effects
    static var supportsAdvancedGlassEffects: Bool {
        return PlatformInfo.Features.advancedGlassEffects
    }
    
    /// Check if the current OS supports basic glass effects
    static var supportsBasicGlassEffects: Bool {
        return PlatformInfo.Features.basicGlassEffects
    }
}

/// ViewModifier for applying glass effects with strict version detection
@available(macOS 15.0, iOS 18.0, *)
struct GlassEffectModifier: ViewModifier {
    let intensity: Double
    let tint: Color?
    let isProminent: Bool
    
    init(intensity: Double = 0.8, tint: Color? = nil, isProminent: Bool = false) {
        self.intensity = intensity
        self.tint = tint
        self.isProminent = isProminent
    }
    
    func body(content: Content) -> some View {
        if GlassEffectHelpers.supportsAdvancedGlassEffects {
            // Advanced glass effects for macOS 26+ and iOS 26+
            if #available(macOS 26.0, iOS 26.0, *) {
                content
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
            } else {
                // Basic glass effects for macOS 15+ / iOS 18+
                basicGlassEffect(content)
            }
        } else {
            // No glass effects - unsupported OS version
            // This should not happen since we require macOS 15+ / iOS 18+
            content
                .background(
                    Color(NSColor.controlBackgroundColor),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private func basicGlassEffect(_ content: Content) -> some View {
        // Basic glass effects for macOS 15+ / iOS 18+ (but not 26+)
        content
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
}

/// Extension for easy glass effect application
@available(macOS 15.0, iOS 18.0, *)
extension View {
    
    /// Apply glass effect with automatic version detection
    /// - Parameters:
    ///   - intensity: Effect intensity (0.0 to 1.0)
    ///   - tint: Optional tint color
    ///   - isProminent: Whether to use prominent styling
    /// - Returns: Modified view with appropriate glass effect
    func glassEffect(
        intensity: Double = 0.8,
        tint: Color? = nil,
        isProminent: Bool = false
    ) -> some View {
        self.modifier(
            GlassEffectModifier(
                intensity: intensity,
                tint: tint,
                isProminent: isProminent
            )
        )
    }
    
    /// Apply card-style glass effect for dashboard cards
    func cardGlassEffect() -> some View {
        self.glassEffect(intensity: 0.9, isProminent: false)
    }
    
    /// Apply sidebar glass effect
    func sidebarGlassEffect() -> some View {
        if GlassEffectHelpers.supportsAdvancedGlassEffects {
            self.glassEffect(intensity: 0.7, isProminent: true)
        } else {
            self.glassEffect(intensity: 0.5)
        }
    }
    
    /// Apply modal glass effect
    func modalGlassEffect() -> some View {
        self.glassEffect(intensity: 0.95, isProminent: true)
    }
}

/// Glass effect background for large areas
@available(macOS 15.0, iOS 18.0, *)
struct GlassBackground: View {
    let style: GlassStyle
    
    enum GlassStyle {
        case card
        case sidebar  
        case modal
        case window
    }
    
    var body: some View {
        if GlassEffectHelpers.supportsAdvancedGlassEffects {
            advancedGlassBackground
        } else {
            basicGlassBackground
        }
    }
    
    @ViewBuilder
    private var advancedGlassBackground: some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            Rectangle()
                .fill(
                    .regularMaterial.opacity(materialOpacity),
                    style: FillStyle()
                )
                .overlay(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.1)
                )
                .overlay(
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        } else {
            basicGlassBackground
        }
    }
    
    @ViewBuilder
    private var basicGlassBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(materialOpacity)
    }
    
    private var materialOpacity: Double {
        switch style {
        case .card: return 0.9
        case .sidebar: return 0.8
        case .modal: return 0.95
        case .window: return 0.7
        }
    }
    
    private var gradientColors: [Color] {
        switch style {
        case .card:
            return [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]
        case .sidebar:
            return [Color.gray.opacity(0.1), Color.clear]
        case .modal:
            return [Color.white.opacity(0.2), Color.gray.opacity(0.1)]
        case .window:
            return [Color.primary.opacity(0.05), Color.clear]
        }
    }
}

/// Preview helper for glass effects
@available(macOS 15.0, iOS 18.0, *)
struct GlassEffectPreviews: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Glass Effect Showcase")
                .font(.largeTitle)
                .bold()
            
            HStack(spacing: 15) {
                VStack {
                    Text("Card Style")
                        .font(.headline)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 120, height: 80)
                }
                .cardGlassEffect()
                
                VStack {
                    Text("Sidebar Style")
                        .font(.headline)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 120, height: 80)
                }
                .sidebarGlassEffect()
                
                VStack {
                    Text("Modal Style")
                        .font(.headline)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 120, height: 80)
                }
                .modalGlassEffect()
            }
            
            Text("OS Support: \(GlassEffectHelpers.supportsAdvancedGlassEffects ? "Advanced" : "Basic")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#if DEBUG
@available(macOS 15.0, iOS 18.0, *)
#Preview("Glass Effects") {
    GlassEffectPreviews()
}
#endif