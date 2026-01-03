//
//  LiquidGlassToolbarContainer.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI


struct LiquidGlassToolbarContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                content
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
