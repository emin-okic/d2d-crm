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
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(998)
                    .allowsHitTesting(false)

                AdImagePopupView(
                    ad: ad,
                    onDismiss: { engine.closeForSession(ad) },
                    onClick:   { clicked in engine.notifyClickAndClose(clicked) }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

public extension View {
    func presentRotatingAdsCentered() -> some View { self.modifier(AdPresenter()) }
}
