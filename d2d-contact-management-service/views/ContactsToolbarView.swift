//
//  ContactsToolbarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/13/25.
//

import SwiftUI

struct ContactsToolbarView: View {

    var onAddTapped: () -> Void
    @Binding var isDeleting: Bool
    var selectedCount: Int
    var onDeleteConfirmed: () -> Void

    var body: some View {
        ZStack {
            // Positioning container (fills screen)
            VStack {
                Spacer()

                HStack {
                    // 🔹 Liquid glass only wraps the buttons
                    ContactScreenToolbarLiquidGlass {
                        VStack(spacing: 10) {

                            Button(action: onAddTapped) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.blue))
                                    .shadow(radius: 4)
                            }
                            
                            
                            DeleteContactButton(
                                isDeleting: $isDeleting,
                                selectedCount: selectedCount,
                                onDeleteConfirmed: onDeleteConfirmed
                            )

                        }
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
