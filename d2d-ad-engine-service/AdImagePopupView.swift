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
            // Card container for depth + rounded corners
            VStack(spacing: 0) {
                if let imageName = ad.imageName {
                    let tapAll = ad.tapEntireImage ?? true
                    ZStack {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel(Text(ad.title))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.1), radius: 14, y: 8)
                        // Optional: subtle gradient at bottom if you ever add inline CTA button text
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard tapAll else { return }
                        onClick(ad)
                        openURL(ad.destination)
                    }
                } else {
                    // Fallback to text version if no imageName present
                    AdPopupView(ad: ad, onDismiss: onDismiss, onClick: onClick)
                }
            }
            .padding(0)

            // Close (X)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.clear)
            }
            .buttonStyle(.plain)
        }
        .onAppear { AdEngine.shared.notify(.impression, ad: ad) }
        .frame(maxWidth: 360)   // good for 300x250 / 320x200 creative sizes
        .padding(.horizontal, 16)
    }
}
