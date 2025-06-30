//
//  WaveformView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI

struct WaveformView: View {
    var samples: [CGFloat]
    var currentProgress: CGFloat // 0.0 to 1.0
    var onSeek: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(samples.count)
            HStack(alignment: .center, spacing: 1) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    Rectangle()
                        .fill(indexToProgress(index) < currentProgress ? .blue : .gray)
                        .frame(width: barWidth, height: sample * geometry.size.height)
                }
            }
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

    func indexToProgress(_ index: Int) -> CGFloat {
        CGFloat(index) / CGFloat(samples.count)
    }
}
