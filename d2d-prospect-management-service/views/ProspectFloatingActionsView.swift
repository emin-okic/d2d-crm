//
//  ProspectFloatingActionsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct ProspectFloatingActionsView: View {
    let onDeleteTapped: () -> Void
    let onNotesTapped: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                // Delete button (left)
                Button(action: onDeleteTapped) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }

                Spacer()

                // Notes button (right)
                Button(action: onNotesTapped) {
                    Image(systemName: "note.text")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
