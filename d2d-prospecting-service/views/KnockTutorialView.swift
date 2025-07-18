//
//  KnockTutorialView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//


import SwiftUI

struct KnockTutorialView: View {
    let totalKnocks: Int
    let onDismiss: () -> Void

    var body: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            Spacer()

            RejectionTrackerView(count: totalKnocks)
                .scaleEffect(1.1)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow, lineWidth: 3)
                )

            Text("This is your knock counter. Every door matters.\nWatch it grow with every interaction.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)

            Button("Got it!") {
                onDismiss()
            }
            .padding()
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(10)
            .padding(.bottom, 40)
        }
        .transition(.scale)
    }
}
