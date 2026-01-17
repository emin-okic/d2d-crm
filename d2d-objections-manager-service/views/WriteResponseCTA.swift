//
//  WriteResponseCTA.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct WriteResponseCTA: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Haptics + sound when tapping the "Write a Response" button
            ObjectionManagerHapticsController.shared.screenTap()
            ObjectionManagerSoundController.shared.playActionSound()
            
            action()
        }) {
            HStack {
                Image(systemName: "pencil.line")
                Text("Write a Response")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}
