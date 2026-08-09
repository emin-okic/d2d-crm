//
//  AdImagePopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//

import SwiftUI

public struct AdImagePopupView: View {
    let ad: Ad
    let onDismiss: () -> Void
    let onClick: (Ad) -> Void
    @Environment(\.openURL) private var openURL

    public init(ad: Ad, onDismiss: @escaping () -> Void, onClick: @escaping (Ad) -> Void) {
        self.ad = ad
        self.onDismiss = onDismiss
        self.onClick = onClick
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Sponsored")
                        .font(.system(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)

                    Circle()
                        .fill(.secondary.opacity(0.35))
                        .frame(width: 3, height: 3)

                    Text(ad.ctaText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 12)
                }
                .padding(.leading, 12)
                .padding(.trailing, 48)
                .padding(.top, 12)

                adCreative
                    .padding(.bottom, 12)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.38), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 24, y: 14)

            closeButton
        }
        .onAppear { AdEngine.shared.notify(.impression, ad: ad) }
        .frame(maxWidth: 360)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var adCreative: some View {
        if let imageName = ad.imageName {
            let tapAll = ad.tapEntireImage ?? true

            Image(imageName)
                .resizable()
                .scaledToFit()
                .accessibilityLabel(Text(ad.title))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onTapGesture {
                    guard tapAll else { return }
                    onClick(ad)
                    openURL(ad.destination)
                }
                .padding(.horizontal, 10)
        } else {
            AdPopupView(
                ad: ad,
                onDismiss: onDismiss,
                onClick: onClick
            )
            .padding(.horizontal, 10)
        }
    }

    private var closeButton: some View {
        Button(action: {
            AdManagerHapticsController.shared.lightTap()
            AdManagerSoundController.shared.playSubtleSuccessSound()

            onDismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.45), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .padding(8)
        .accessibilityLabel(Text("Close"))
    }
}
