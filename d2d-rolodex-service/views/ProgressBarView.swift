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

    // Work out what tier we’re in
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

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width

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
                        .frame(width: totalWidth * fractionInLevel, height: 12)
                        .scaleEffect(animateLevelUp ? 1.1 : 1.0, anchor: .center)
                        .animation(.easeInOut(duration: 0.3), value: animateLevelUp)
                }
            }
            .padding(.horizontal)
            .onAppear {
                displayedNext = nextBreakpoint
            }
            .onChange(of: current) { newValue in
                let newNext = nextBreakpoint
                if newValue >= displayedNext && displayedNext < newNext {
                    // level up
                    animateLevelUp = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animateLevelUp = false
                        displayedNext = newNext
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Preview
struct ProgressBarWrapper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBarWrapper(current: 0, listType: .prospects)   // 0/5
            ProgressBarWrapper(current: 5, listType: .prospects)   // 5/10
            ProgressBarWrapper(current: 9, listType: .prospects)   // 9/10
            ProgressBarWrapper(current: 10, listType: .prospects)  // 10/25
            ProgressBarWrapper(current: 20, listType: .prospects)  // 20/25
            ProgressBarWrapper(current: 25, listType: .prospects)  // capped
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
