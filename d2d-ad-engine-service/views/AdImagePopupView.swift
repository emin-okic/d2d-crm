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

            VStack(spacing: 12) {
                if let imageName = ad.imageName {
                    let tapAll = ad.tapEntireImage ?? true

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(Text(ad.title))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard tapAll else { return }
                            onClick(ad)
                            openURL(ad.destination)
                        }
                } else {
                    AdPopupView(
                        ad: ad,
                        onDismiss: onDismiss,
                        onClick: onClick
                    )
                }

                // 👇 Remove Ads button appears below the ad
                if !AdEngine.shared.adsRemoved {
                    Button {
                        Task {
                            await AdEngine.shared.purchaseRemoveAds()
                        }
                    } label: {
                        Label("$0.69", systemImage: "sparkles")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Capsule())
                }
            }

            // ✅ White X with depth (inner stroke + shadow) for light/white backgrounds
            Button(action: {
                // Haptics + sound on close
                AdManagerHapticsController.shared.lightTap()
                AdManagerSoundController.shared.playSubtleSuccessSound()
                
                onDismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                    Circle()
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                }
                .frame(width: 28, height: 28)
                .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))
            
        }
        .onAppear { AdEngine.shared.notify(.impression, ad: ad) }
        .frame(maxWidth: 360)
        .padding(.horizontal, 16)
    }
}
