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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }

                Text(value)
                    .font(.system(size: 28, weight: .bold))

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}
