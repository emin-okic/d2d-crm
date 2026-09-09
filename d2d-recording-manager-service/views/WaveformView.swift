//
//  WaveformView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI

struct WaveformView: View {
    var samples: [CGFloat]
    var currentProgress: CGFloat // 0.0 to 1.0
    var onSeek: (CGFloat) -> Void
    
    private let barSpacing: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let sampleCount = samples.count
            let totalSpacing = CGFloat(max(sampleCount - 1, 0)) * barSpacing
            let barWidth = sampleCount > 0
                ? max((geometry.size.width - totalSpacing) / CGFloat(sampleCount), 0)
                : 0
            let clampedProgress = min(max(currentProgress, 0), 1)
            
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    let clampedSample = min(max(sample, 0), 1)
                    
                    Rectangle()
                        .fill(indexToProgress(index, sampleCount: sampleCount) < clampedProgress ? .blue : .gray)
                        .frame(width: barWidth, height: clampedSample * geometry.size.height)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let progress = min(max(0, value.location.x / geometry.size.width), 1)
                        onSeek(progress)
                    }
            )
        }
    }

    func indexToProgress(_ index: Int, sampleCount: Int) -> CGFloat {
        guard sampleCount > 0 else { return 0 }
        return CGFloat(index) / CGFloat(sampleCount)
    }
}
