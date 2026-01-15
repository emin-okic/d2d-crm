//
//  ExportCSVButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import SwiftUI

struct ExportCSVButton: View {

    let isUnlocked: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .bottomTrailing) {
                // Base button
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.white)
                    .padding(15)
                    .background(
                        LinearGradient(
                            colors: isUnlocked
                                ? [Color.blue, Color.blue.opacity(0.7)]
                                : [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .opacity(isUnlocked ? 1.0 : 0.85)

                // Lock overlay
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.65)))
                        .offset(x: 6, y: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Interaction

    private func handleTap() {
        
        // Tap feedback always
        ContactDetailsHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isPressed = true
        }

        onTap()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}
