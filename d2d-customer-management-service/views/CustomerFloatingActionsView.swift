//
//  CustomerFloatingActionsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI

struct CustomerFloatingActionsView: View {
    let onDeleteTapped: () -> Void
    let onNotesTapped: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                // Align to left
                LiquidGlassToolbarBackground {
                    VStack(spacing: 16) {
                        // Notes button above trash
                        Button(action: onNotesTapped) {
                            Image(systemName: "note.text")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 5)
                        }

                        // Trash button
                        Button(action: onDeleteTapped) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.red))
                                .shadow(radius: 5)
                        }
                    }
                }
                .padding(.bottom, 16)
                .padding(.leading, 16) // bottom-left corner

                Spacer() // push to left
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
