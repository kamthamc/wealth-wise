//
//  WealthCardView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Reusable card wrapper with consistent styling across the app
//

import SwiftUI

@available(iOS 18, macOS 15, *)
struct WealthCardView<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let backgroundColor: Color
    
    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.05,
        backgroundColor: Color = Color(.systemBackground),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Style Variants

@available(iOS 18, macOS 15, *)
extension WealthCardView {
    /// Compact card with reduced padding
    static func compact<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> WealthCardView<Content> {
        WealthCardView(
            padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
            content: content
        )
    }
    
    /// Prominent card with increased shadow
    static func prominent<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> WealthCardView<Content> {
        WealthCardView(
            shadowRadius: 12,
            shadowOpacity: 0.08,
            content: content
        )
    }
    
    /// Subtle card with minimal shadow
    static func subtle<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> WealthCardView<Content> {
        WealthCardView(
            shadowRadius: 4,
            shadowOpacity: 0.03,
            content: content
        )
    }
    
    /// Colored card with custom background
    static func colored<Content: View>(
        color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> WealthCardView<Content> {
        WealthCardView(
            backgroundColor: color.opacity(0.1),
            content: content
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Wealth Card - Default") {
    VStack(spacing: 20) {
        WealthCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("₹1,25,000")
                    .font(.title.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        WealthCardView {
            HStack {
                VStack(alignment: .leading) {
                    Text("Monthly Budget")
                        .font(.subheadline)
                    Text("₹50,000")
                        .font(.title2.bold())
                }
                Spacer()
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text("78%")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
            }
        }
    }
    .padding()
}

#Preview("Wealth Card - Variants") {
    VStack(spacing: 20) {
        // Compact
        WealthCardView.compact {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Payment successful")
                    .font(.subheadline)
            }
        }
        
        // Prominent
        WealthCardView.prominent {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                Text("Your portfolio is growing")
                    .font(.headline)
                Text("Up 12% this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        // Subtle
        WealthCardView.subtle {
            HStack {
                Text("Last updated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("2 mins ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}

#Preview("Wealth Card - Colored") {
    VStack(spacing: 20) {
        WealthCardView.colored(color: .green) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₹1,25,000")
                        .font(.title3.bold())
                }
            }
        }
        
        WealthCardView.colored(color: .red) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                VStack(alignment: .leading) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₹85,000")
                        .font(.title3.bold())
                }
            }
        }
        
        WealthCardView.colored(color: .blue) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Savings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("32%")
                        .font(.title3.bold())
                }
            }
        }
    }
    .padding()
}

#Preview("Wealth Card - Complex Content") {
    ScrollView {
        VStack(spacing: 16) {
            WealthCardView.prominent {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Emergency Fund")
                                .font(.headline)
                            Text("Savings Goal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("45%")
                                .font(.caption.bold())
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 8)
                                    .clipShape(Capsule())
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * 0.45, height: 8)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 8)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("₹2,25,000")
                                .font(.subheadline.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("₹5,00,000")
                                .font(.subheadline.bold())
                        }
                    }
                }
            }
            
            HStack(spacing: 16) {
                WealthCardView.compact {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("3 Paid")
                            .font(.caption)
                    }
                }
                
                WealthCardView.compact {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text("2 Pending")
                            .font(.caption)
                    }
                }
                
                WealthCardView.compact {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        Text("1 Overdue")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}
#endif
