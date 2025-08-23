//
//  AdPresenter.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//

import SwiftUI

public struct AdPresenter: ViewModifier {
    @ObservedObject private var engine = AdEngine.shared

    public func body(content: Content) -> some View {
        ZStack {
            content

            if let ad = engine.currentAd {
                // Dim background slightly (non-blocking outside the card)
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(998)
                    .allowsHitTesting(false)

                // Centered popup so it doesn't touch the bottom-left floating tools
                AdImagePopupView(
                    ad: ad,
                    onDismiss: {
                        AdEngine.shared.notify(.dismiss, ad: ad)
                        // Briefly stop; the timer in AdEngine will rotate next time you start
                        AdEngine.shared.stop()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            AdEngine.shared.start(inventory: AdDemoInventory.defaultAds)
                        }
                    },
                    onClick: { clicked in
                        AdEngine.shared.notify(.click, ad: clicked)
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

public extension View {
    func presentRotatingAdsCentered() -> some View {
        self.modifier(AdPresenter())
    }
}
