//
//  RecordingStatsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI

struct RecordingStatsView: View {
    let total: Int
    let avg: Double

    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Total", value: "\(total)")
            StatCard(title: "Avg Score", value: String(format: "%.1f", avg))
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
