//
//  DotStepBar.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/11/25.
//
import SwiftUI
import SwiftData
import MapKit

struct DotStepBar: View {
    let total: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= index ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityLabel("Step \(index+1) of \(total)")
    }
}
