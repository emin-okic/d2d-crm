//
//  AdPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//


import SwiftUI

public struct AdPopupView: View {
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
                HStack(spacing: 10) {
                    if let icon = ad.iconSystemName {
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ad.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let subtitle = ad.subtitle {
                            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                }

                if let body = ad.body {
                    Text(body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Button {
                    onClick(ad)
                    openURL(ad.destination) // opens your funnel in Safari
                } label: {
                    HStack(spacing: 8) {
                        Text(ad.ctaText).font(.callout.weight(.semibold))
                        Image(systemName: "arrow.up.right.square.fill")
                            .imageScale(.small)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 0.5)
                    )
            )

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .onAppear { AdEngine.shared.notify(.impression, ad: ad) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(ad.title))
    }
}
