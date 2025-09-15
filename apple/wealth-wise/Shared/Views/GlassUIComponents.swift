import SwiftUI

/// Enhanced modal/sheet views with glass effects for macOS 15+ and iOS 18+
@available(macOS 15.0, iOS 18.0, *)
struct GlassModalView<Content: View>: View {
    let title: String
    let content: Content
    let onDismiss: () -> Void
    
    init(
        title: String,
        @ViewBuilder content: () -> Content,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.content = content()
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with glass effect
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background {
                if GlassEffectHelpers.supportsAdvancedGlassEffects {
                    if #available(macOS 26.0, iOS 26.0, *) {
                        Rectangle()
                            .fill(.thinMaterial)
                            .overlay(
                                Rectangle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    } else {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                } else {
                    Rectangle().fill(.ultraThinMaterial)
                }
            }
            
            Divider()
            
            // Content area
            ScrollView {
                content
                    .padding()
            }
        }
        .modalGlassEffect()
    }
}

/// Glass effect toolbar for enhanced UI
@available(macOS 15.0, iOS 18.0, *)
struct GlassToolbar<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background {
            if GlassEffectHelpers.supportsAdvancedGlassEffects {
                if #available(macOS 26.0, iOS 26.0, *) {
                    Capsule()
                        .fill(.regularMaterial)
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            } else {
                Capsule()
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
}

/// Enhanced card view with context-aware glass effects
@available(macOS 15.0, iOS 18.0, *)
struct GlassCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    
    enum CardStyle {
        case standard
        case prominent
        case subtle
        case floating
    }
    
    init(style: CardStyle = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background {
                cardBackground
            }
            .overlay {
                cardOverlay
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if GlassEffectHelpers.supportsAdvancedGlassEffects {
            if #available(macOS 26.0, iOS 26.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.1)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius - 4)
                    .fill(.ultraThinMaterial)
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius - 4)
                .fill(Color.primary.opacity(0.03))
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        if GlassEffectHelpers.supportsAdvancedGlassEffects {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: strokeColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: strokeWidth
                )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius - 4)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return 12
        case .prominent: return 16
        case .subtle: return 8
        case .floating: return 20
        }
    }
    
    private var backgroundMaterial: Material {
        switch style {
        case .standard: return .regularMaterial
        case .prominent: return .thickMaterial
        case .subtle: return .ultraThinMaterial
        case .floating: return .regularMaterial
        }
    }
    
    private var gradientColors: [Color] {
        switch style {
        case .standard: return [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]
        case .prominent: return [Color.white.opacity(0.2), Color.blue.opacity(0.1)]
        case .subtle: return [Color.gray.opacity(0.05), Color.clear]
        case .floating: return [Color.white.opacity(0.15), Color.cyan.opacity(0.1)]
        }
    }
    
    private var strokeColors: [Color] {
        if GlassEffectHelpers.supportsAdvancedGlassEffects {
            return [Color.white.opacity(0.3), Color.white.opacity(0.0)]
        } else {
            return [Color.primary.opacity(0.2), Color.clear]
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .standard, .subtle: return 1
        case .prominent, .floating: return 1.5
        }
    }
    
    private var shadowColor: Color {
        Color.black.opacity(style == .floating ? 0.15 : 0.1)
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .standard, .subtle: return 6
        case .prominent: return 8
        case .floating: return 12
        }
    }
    
    private var shadowOffset: CGFloat {
        switch style {
        case .standard, .subtle: return 2
        case .prominent: return 4
        case .floating: return 6
        }
    }
}

/// Example usage and preview
@available(macOS 15.0, iOS 18.0, *)
struct GlassUIShowcase: View {
    @State private var showModal = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("WealthWise Glass UI")
                .font(.largeTitle)
                .bold()
            
            // Card examples
            HStack(spacing: 16) {
                GlassCard(style: .standard) {
                    VStack {
                        Text("Standard Card")
                            .font(.headline)
                        Text("₹1,25,000")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
                
                GlassCard(style: .prominent) {
                    VStack {
                        Text("Prominent Card")
                            .font(.headline)
                        Text("₹85,000")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                
                GlassCard(style: .floating) {
                    VStack {
                        Text("Floating Card")
                            .font(.headline)
                        Text("₹2,45,000")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Toolbar example
            GlassToolbar {
                Button("Add Asset") { }
                    .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Import") { }
                Button("Export") { }
                Button("Settings") { showModal = true }
            }
            
            Spacer()
        }
        .padding()
        .background {
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.1),
                    Color.blue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showModal) {
            GlassModalView(
                title: "Settings",
                content: {
                    VStack(spacing: 16) {
                        Text("Application Settings")
                            .font(.title2)
                        
                        Text("Platform: \(PlatformInfo.platformString)")
                        Text("Glass Effects: \(GlassEffectHelpers.supportsAdvancedGlassEffects ? "Advanced" : "Basic")")
                        
                        Spacer()
                    }
                },
                onDismiss: { showModal = false }
            )
        }
    }
}

#if DEBUG
@available(macOS 15.0, iOS 18.0, *)
#Preview("Glass UI Showcase") {
    GlassUIShowcase()
}
#endif