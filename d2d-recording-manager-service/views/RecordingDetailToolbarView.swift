//
//  RecordingDetailToolbarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/6/26.
//

import SwiftUI

struct RecordingDetailToolbarView: View {
    let onDeleteTapped: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                VStack(spacing: 16) {
                    
                    Button(action: {
                        
                        RecordingScreenHapticsController.shared.mediumTap()
                        RecordingScreenSoundController.shared.playSound1()
                        
                        onDeleteTapped()
                        
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle().fill(Color.red)
                            )
                            .shadow(radius: 5)
                    }
                    
                }
                .padding(.bottom, 16)
                .padding(.leading, 16)

                Spacer()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
