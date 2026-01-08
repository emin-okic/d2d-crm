//
//  TripManagerScorecardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/7/26.
//

import SwiftUI

struct TripManagerScorecardView: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: "map.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: 72)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
