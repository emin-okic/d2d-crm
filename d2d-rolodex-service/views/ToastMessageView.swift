//
//  ToastMessageView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI

struct ToastMessageView: View {
    let message: String
    var backgroundColor: Color = Color.green.opacity(0.95)

    var body: some View {
        VStack {
            Text(message)
                .padding()
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 6)
                .transition(.scale.combined(with: .opacity))
                .zIndex(9999)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .allowsHitTesting(false) // so it doesn’t block taps
    }
}
