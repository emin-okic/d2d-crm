//
//  ProgressBarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/21/25.
//

import SwiftUI

enum ContactListType {
    case prospects
}

struct ProspectProgressBarView: View {
    let current: Int
    let listType: ContactListType

    private var breakpoints: [Int] {
        switch listType {
        case .prospects:
            return [0, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000]
        }
    }

    // MARK: - State
    @State private var displayedNext: Int = 0
    @State private var displayedPrev: Int = 0

    @State private var animateLevelUp = false
    @State private var showConfetti = false
    @State private var draining = false
    @State private var drainFraction: Double = 1.0

    // MARK: - Progress Calculation
    private var fractionInDisplayedTier: Double {
        let prev = Double(displayedPrev)
        let next = Double(displayedNext)
        guard next > prev else { return 0.0 }
        let progress = Double(current) - prev
        return min(max(progress / (next - prev), 0.0), 1.0)
    }

    private var effectiveFraction: Double {
        draining ? drainFraction : fractionInDisplayedTier
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width

            ZStack {
                VStack(alignment: .leading, spacing: 4) {
                    
                    // Counter
                    // Tier bounds
                    HStack {
                        Text("\(displayedPrev)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(displayedNext)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    // Progress bar
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

                // Confetti
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Initialize to the correct tier
                setTier(for: current)
            }
            .onChange(of: current) { newValue in
                if newValue == displayedNext {   // ✅ Only fire when exactly hitting milestone
                    if let idx = breakpoints.firstIndex(of: displayedNext),
                       idx + 1 < breakpoints.count {
                        let newPrev = displayedNext
                        let newNext = breakpoints[idx + 1]

                        // Trigger animations
                        animateLevelUp = true
                        showConfetti = true
                        draining = true
                        drainFraction = 1.0

                        // Update tier immediately (e.g. 5/5 → 5/10)
                        displayedPrev = newPrev
                        displayedNext = newNext

                        // Drain effect
                        withAnimation(.easeInOut(duration: 1.0)) {
                            drainFraction = 0.0
                        }

                        // Cleanup
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            draining = false
                            animateLevelUp = false
                            showConfetti = false
                        }
                    }
                } else {
                    // Just recalc tier if not exactly at milestone
                    setTier(for: newValue)
                }
            }
        }
        .frame(height: 40)
    }

    // Helper to pick the right tier based on current value
    private func setTier(for value: Int) {
        for i in 1..<breakpoints.count {
            if value < breakpoints[i] {
                displayedPrev = breakpoints[i - 1]
                displayedNext = breakpoints[i]
                return
            }
        }
        displayedPrev = breakpoints[breakpoints.count - 2]
        displayedNext = breakpoints.last ?? 0
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
