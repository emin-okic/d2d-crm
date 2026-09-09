//
//  ContactScreenToolbarLiquidGlass.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import SwiftUI

struct ContactScreenToolbarLiquidGlass<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(width: 52)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 7)
    }
}
