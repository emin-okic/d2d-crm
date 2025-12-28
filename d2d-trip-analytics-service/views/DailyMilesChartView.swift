//
//  DailyMilesChartView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI

struct DailyMilesChartView: View {
    let segments: [DailyMilesSegment]
    
    // Fixed chart height
    private let chartHeight: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Total miles headline
            let total = segments.reduce(0) { $0 + $1.miles }
            Text("Total miles today: \(total, specifier: "%.1f")")
                .font(.headline)
                .bold()
            
            // Horizontal bars
            HStack(spacing: 12) {
                let maxMiles = segments.map { $0.miles }.max() ?? 1
                ForEach(segments, id: \.period) { segment in
                    VStack {
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 20, height: chartHeight)
                            
                            Capsule()
                                .fill(color(for: segment.period))
                                .frame(
                                    width: 20,
                                    height: normalizedHeight(for: segment.miles, maxMiles: maxMiles)
                                )
                        }
                        Text(segment.period.prefix(1)) // M, A, E
                            .font(.caption2)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    func normalizedHeight(for miles: Double, maxMiles: Double) -> CGFloat {
        // Prevent division by zero
        guard maxMiles > 0 else { return 0 }
        // Scale proportionally within chartHeight
        return CGFloat(miles / maxMiles) * chartHeight
    }
    
    func color(for period: String) -> Color {
        switch period {
        case "Morning": return .blue
        case "Afternoon": return .orange
        case "Evening": return .purple
        default: return .gray
        }
    }
}
