//
//  ProgressHeader.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ProgressHeader: View {
    let step: Int
    let total: Int

    var body: some View {
        VStack(spacing: 6) {
            ProgressView(value: Double(step), total: Double(total))
                .tint(.green)

            Text("Practice • Step \(step) of \(total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
