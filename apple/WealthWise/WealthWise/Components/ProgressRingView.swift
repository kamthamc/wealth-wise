//
//  ProgressRingView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Circular progress ring component
//

import SwiftUI

struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    let showPercentage: Bool
    
    init(
        progress: Double,
        color: Color = .blue,
        lineWidth: CGFloat = 12,
        size: CGFloat = 100,
        showPercentage: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Percentage text
            if showPercentage {
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Progress Ring - Various States") {
    VStack(spacing: 30) {
        HStack(spacing: 30) {
            VStack {
                ProgressRingView(progress: 0.25, color: .red)
                Text("25%").font(.caption)
            }
            
            VStack {
                ProgressRingView(progress: 0.5, color: .orange)
                Text("50%").font(.caption)
            }
            
            VStack {
                ProgressRingView(progress: 0.75, color: .blue)
                Text("75%").font(.caption)
            }
            
            VStack {
                ProgressRingView(progress: 1.0, color: .green)
                Text("100%").font(.caption)
            }
        }
        
        HStack(spacing: 30) {
            ProgressRingView(progress: 0.65, color: .purple, lineWidth: 16, size: 140)
            ProgressRingView(progress: 0.45, color: .mint, lineWidth: 8, size: 80, showPercentage: false)
        }
    }
    .padding()
}
#endif
