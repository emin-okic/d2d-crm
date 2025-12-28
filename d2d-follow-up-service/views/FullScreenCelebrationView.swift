//
//  FullScreenCelebrationView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//

import SwiftUI

struct FullScreenCelebrationView: View {
    var dimOpacity: Double = 0.12   // <- super light; tweak 0.04–0.12 as you like

    var body: some View {
        ZStack {

            // Confetti sits on top, no background of its own
            ConfettiBurstView()
        }
        .background(Color.clear)
        .ignoresSafeArea()
        // For iOS 17+, keeps any system backgrounds from bleeding in
        .presentationBackground(.clear)
    }
}
