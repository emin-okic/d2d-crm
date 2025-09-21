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
        case .prospects:
            return [1, 2, 3, 5, 8, 10]
        case .customers:
            return [1, 2, 3, 5, 10]
        }
    }

    private var currentLevelIndex: Int {
        for (i, bp) in breakpoints.enumerated() {
            if current < bp {
                return i
            }
        }
        return breakpoints.count - 1
    }

    private var previousBreakpoint: Int {
        if currentLevelIndex == 0 {
            return 0
        } else {
            return breakpoints[currentLevelIndex - 1]
        }
    }

    private var nextBreakpoint: Int {
        breakpoints[min(currentLevelIndex, breakpoints.count - 1)]
    }

    private var fractionInLevel: Double {
        let prev = Double(previousBreakpoint)
        let next = Double(nextBreakpoint)
        guard next > prev else { return 1.0 }
        let progress = Double(current) - prev
        return min(max(progress / (next - prev), 0.0), 1.0)
    }

    @State private var displayedNext: Int = 0
    @State private var animateLevelUp: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width

            VStack(alignment: .leading, spacing: 4) {
                // Label
                Text("\(current)/\(displayedNext > 0 ? displayedNext : nextBreakpoint)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(
                        current >= (displayedNext > 0 ? displayedNext : nextBreakpoint)
                         ? Color.green
                         : Color.primary
                    )

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)

                    Capsule()
                        .fill(
                            (current >= (displayedNext > 0 ? displayedNext : nextBreakpoint))
                            ? Color.green
                            : Color.blue
                        )
                        .frame(
                            width: totalWidth * fractionInLevel,
                            height: 12
                        )
                        .scaleEffect(animateLevelUp ? 1.1 : 1.0, anchor: .center)
                        .animation(.easeInOut(duration: 0.3), value: animateLevelUp)
                }
            }
            .padding(.horizontal)
            .onAppear {
                // initialize displayedNext
                displayedNext = nextBreakpoint
            }
            .onChange(of: current) { newValue in
                let lvl = currentLevelIndex
                let newNext = breakpoints[lvl]
                if newValue >= newNext && displayedNext < newNext {
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

// Preview
struct ProgressBarWrapper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBarWrapper(current: 0, listType: .prospects)
            ProgressBarWrapper(current: 1, listType: .prospects)
            ProgressBarWrapper(current: 2, listType: .prospects)
            ProgressBarWrapper(current: 3, listType: .prospects)
            ProgressBarWrapper(current: 4, listType: .prospects)
            ProgressBarWrapper(current: 5, listType: .prospects)
            ProgressBarWrapper(current: 8, listType: .prospects)
            ProgressBarWrapper(current: 10, listType: .prospects)
            ProgressBarWrapper(current: 12, listType: .prospects)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
