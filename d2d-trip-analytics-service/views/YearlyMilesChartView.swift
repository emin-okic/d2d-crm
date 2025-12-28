//
//  YearlyMilesChartView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI

struct YearlyMilesChartView: View {
    let segments: [YearlyMilesSegment]
    
    private let chartHeight: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let total = segments.reduce(0) { $0 + $1.miles }
            Text("Total miles this year: \(total, specifier: "%.1f")")
                .font(.headline)
                .bold()
            
            HStack(spacing: 6) {
                let maxMiles = segments.map { $0.miles }.max() ?? 1
                ForEach(segments) { segment in
                    VStack {
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 20, height: chartHeight)
                            
                            Capsule()
                                .fill(Color.green)
                                .frame(
                                    width: 20,
                                    height: normalizedHeight(for: segment.miles, maxMiles: maxMiles)
                                )
                        }
                        
                        Text(segment.month.prefix(3))
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
        guard maxMiles > 0 else { return 0 }
        return CGFloat(miles / maxMiles) * chartHeight
    }
}
