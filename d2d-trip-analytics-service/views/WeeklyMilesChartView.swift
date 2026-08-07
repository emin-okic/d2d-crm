//
//  WeeklyMilesChartView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI

struct WeeklyMilesChartView: View {
    let segments: [WeeklyMilesSegment]
    private let chartHeight: CGFloat = 112
    private let barWidth: CGFloat = 24

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            let total = segments.reduce(0) { $0 + $1.miles }

            VStack(spacing: 2) {
                Text("This Week")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Text("\(total, specifier: "%.1f") miles")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .bottom, spacing: 10) {
                let maxMiles = segments.map { $0.miles }.max() ?? 1
                ForEach(segments) { segment in
                    VStack(spacing: 8) {
                        Text("\(segment.miles, specifier: "%.1f")")
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundColor(.secondary)

                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: barWidth, height: chartHeight)

                            Capsule()
                                .fill(Color.blue)
                                .frame(
                                    width: barWidth,
                                    height: normalizedHeight(for: segment.miles, maxMiles: maxMiles)
                                )
                        }

                        Text(segment.day.prefix(3))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    private func normalizedHeight(for miles: Double, maxMiles: Double) -> CGFloat {
        guard maxMiles > 0 else { return 0 }
        guard miles > 0 else { return 4 }
        return max(8, CGFloat(miles / maxMiles) * chartHeight)
    }
}
