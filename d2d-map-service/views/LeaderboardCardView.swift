//
//  LeaderboardCard.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//
import SwiftUI
struct LeaderboardCardView: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .top)

            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
