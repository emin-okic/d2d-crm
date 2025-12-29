//
//  LeaderboardTextCardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/16/25.
//

import SwiftUI

struct LeaderboardTextCardView: View {
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .top)

            Text(text.isEmpty ? "—" : text)
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90) // medium widget-ish
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
