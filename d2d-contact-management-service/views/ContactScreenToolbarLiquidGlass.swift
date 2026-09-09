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
                .fill(.regularMaterial)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground).opacity(0.58))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 8)
        .shadow(color: Color.blue.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}
