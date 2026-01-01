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

    @State private var trashPulse = false

    var body: some View {
        
        ZStack {
            
            VStack(spacing: 10) {
                
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
                
                Button {
                    if isDeleting {
                        if selectedCount == 0 {
                            withAnimation {
                                isDeleting = false
                                trashPulse = false
                            }
                        } else {
                            onDeleteConfirmed()
                        }
                    } else {
                        withAnimation {
                            isDeleting = true
                            trashPulse = true
                        }
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle().fill(isDeleting ? Color.red : Color.blue)
                        )
                        .scaleEffect(isDeleting ? (trashPulse ? 1.06 : 1.0) : 1.0)
                        .rotationEffect(.degrees(isDeleting ? (trashPulse ? 2 : -2) : 0))
                        .animation(
                            isDeleting
                            ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                            : .default,
                            value: trashPulse
                        )
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.bottom, 16)
            .padding(.leading, 20)
            .zIndex(998)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
