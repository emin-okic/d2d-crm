//
//  CustomerProgressBarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI

struct CustomerProgressBarView: View {
    let current: Int

    private var breakpoints: [Int] {
        [0, 1, 3, 5, 10]   // 👈 milestones for customers
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
                    Text("\(current)/\(displayedNext)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(current >= displayedNext ? .green : .primary)

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

                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .onAppear {
                setTier(for: current)
            }
            .onChange(of: current) { newValue in
                if newValue == displayedNext {
                    if let idx = breakpoints.firstIndex(of: displayedNext),
                       idx + 1 < breakpoints.count {
                        let newPrev = displayedNext
                        let newNext = breakpoints[idx + 1]

                        animateLevelUp = true
                        showConfetti = true
                        draining = true
                        drainFraction = 1.0

                        displayedPrev = newPrev
                        displayedNext = newNext

                        withAnimation(.easeInOut(duration: 1.0)) {
                            drainFraction = 0.0
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            draining = false
                            animateLevelUp = false
                            showConfetti = false
                        }
                    }
                } else {
                    setTier(for: newValue)
                }
            }
        }
        .frame(height: 40)
    }

    // MARK: - Helper
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
