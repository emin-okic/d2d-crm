//
//  ProspectScorecard.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/7/26.
//

import SwiftUI

struct ProspectScorecard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(value)
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
