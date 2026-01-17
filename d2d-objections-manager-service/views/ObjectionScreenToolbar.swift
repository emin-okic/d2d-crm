//
//  ObjectionScreenToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//

import SwiftUI

struct ObjectionScreenToolbar: View {
    var onAddTapped: () -> Void
    @Binding var isDeleting: Bool
    var selectedCount: Int
    var onDeleteConfirmed: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Spacer()

                HStack {
                    // Wrap buttons in a liquid glass container for consistency
                    ContactScreenToolbarLiquidGlass {
                        VStack(spacing: 12) {
                            // Add objection button
                            Button {
                                RecordingScreenHapticsController.shared.lightTap()
                                RecordingScreenSoundController.shared.playSound1()
                                onAddTapped()
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.blue))
                                    .shadow(radius: 5)
                            }

                            // Delete objection button
                            Button {
                                RecordingScreenHapticsController.shared.mediumTap()
                                RecordingScreenSoundController.shared.playSound1()
                                if selectedCount > 0 {
                                    onDeleteConfirmed()
                                } else {
                                    isDeleting.toggle()
                                }
                            } label: {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(isDeleting || selectedCount > 0 ? Color.red : Color.blue))
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(8)
                    }

                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 16)
            }
        }
        .allowsHitTesting(true)
        .zIndex(998)
    }
}
