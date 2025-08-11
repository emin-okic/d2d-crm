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
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100)
        .padding(5)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 3)
        .contentShape(Rectangle()) // makes tap target full card
    }
}
