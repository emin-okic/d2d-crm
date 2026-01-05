//
//  DeleteContactButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import SwiftUI

struct DeleteContactButton: View {
    
    @Binding var isDeleting: Bool
    var selectedCount: Int
    var onDeleteConfirmed: () -> Void
    
    @State private var trashPulse = false
    
    var body: some View {
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
}

struct DeleteContactButton_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var isDeleting = false

        var body: some View {
            DeleteContactButton(isDeleting: $isDeleting, selectedCount: 2) {
                print("Delete confirmed")
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
