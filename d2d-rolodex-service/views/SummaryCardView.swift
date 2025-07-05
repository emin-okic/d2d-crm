//
//  SummaryCardView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/5/25.
//
import SwiftUI

struct SummaryCardView: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(count)")
                .font(.title2)
                .bold()
                .foregroundColor(.primary)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 80)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
