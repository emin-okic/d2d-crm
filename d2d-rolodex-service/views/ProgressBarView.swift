//
//  ProgressBarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/21/25.
//

import SwiftUI

enum ContactListType {
    case prospects
    case customers
}

struct ProgressBarWrapper: View {
    let current: Int
    let listType: ContactListType

    private var breakpoints: [Int] {
        switch listType {
        case .prospects: return [0, 5, 10, 25]
        case .customers: return [0, 5, 10, 25]
        }
    }

    // Which tier are we in now?
    private var currentLevelIndex: Int {
        for (i, bp) in breakpoints.enumerated() {
            if current < bp {
                return max(i - 1, 0)
            }
        }
        return breakpoints.count - 1
    }

    private var previousBreakpoint: Int {
        breakpoints[currentLevelIndex]
    }

    private var nextBreakpoint: Int {
        if currentLevelIndex + 1 < breakpoints.count {
            return breakpoints[currentLevelIndex + 1]
        }
        return breakpoints.last ?? previousBreakpoint
    }

    private var fractionInLevel: Double {
        let prev = Double(previousBreakpoint)
        let next = Double(nextBreakpoint)
        guard next > prev else { return 1.0 }
        let progress = Double(current) - prev
        return min(max(progress / (next - prev), 0.0), 1.0)
    }

    @State private var displayedNext: Int = 0
    @State private var animateLevelUp = false
    @State private var showConfetti = false
    @State private var draining = false
    @State private var drainFraction: Double = 1.0

    private var effectiveFraction: Double {
        draining ? drainFraction : fractionInLevel
    }

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width

            ZStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Label
                    Text("\(current)/\(displayedNext)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(current >= displayedNext ? .green : .primary)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)

                        Capsule()
                            .fill(current >= displayedNext ? .green : .blue)
                            .frame(width: totalWidth * effectiveFraction, height: 12)
                            .scaleEffect(animateLevelUp ? 1.1 : 1.0, anchor: .center)
                            .animation(.easeInOut(duration: 0.3), value: animateLevelUp)
                    }
                }
                .padding(.horizontal)

                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .onAppear {
                displayedNext = nextBreakpoint
            }
            .onChange(of: current) { newValue in
                let newNext = nextBreakpoint
                let newPrev = previousBreakpoint

                if newValue == displayedNext {   // ✅ trigger on exact milestone
                    animateLevelUp = true
                    showConfetti = true
                    draining = true
                    drainFraction = 1.0

                    // Drain animation
                    withAnimation(.easeInOut(duration: 1.0)) {
                        drainFraction = 0.0
                    }

                    // After drain, expand tier
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        draining = false
                        animateLevelUp = false
                        displayedNext = newNext   // now 5/10 instead of stuck at 5/5
                        showConfetti = false
                    }
                } else if newValue < newPrev {
                    // ⬇️ Downgrade tier
                    withAnimation(.easeInOut(duration: 0.5)) {
                        displayedNext = newNext
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Confetti
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<20).map { _ in ConfettiParticle.random }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 6, height: 6)
                    .position(particle.start(in: geo.size))
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(Double.random(in: 0...0.3)),
                        value: particles
                    )
            }
        }
    }
}

struct ConfettiParticle: Identifiable, Equatable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let y: CGFloat

    static var random: ConfettiParticle {
        ConfettiParticle(
            color: [Color.red, .green, .blue, .yellow, .purple, .orange].randomElement()!,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1)
        )
    }

    func start(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height / 4)
    }
}
