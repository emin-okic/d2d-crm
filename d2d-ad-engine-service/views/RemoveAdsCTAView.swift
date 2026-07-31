//
//  RemoveAdsCTAView.swift
//  d2d-studio
//
//  Created by Emin Okic on 6/13/26.
//

import SwiftUI

struct RemoveAdsCTAView: View {
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "nosign")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.44, blue: 0.92), Color(red: 0.02, green: 0.65, blue: 0.58)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Remove Ads Forever")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("One-time unlock · $0.69")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                trailingAccessory
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.92))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text("Remove Ads Forever, one-time unlock, $0.69"))
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else {
            Text("Unlock")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.44, blue: 0.92), Color(red: 0.02, green: 0.65, blue: 0.58)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
        }
    }
}
