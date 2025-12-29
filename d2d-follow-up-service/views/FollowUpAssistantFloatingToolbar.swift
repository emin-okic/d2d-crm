//
//  FloatingToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI

struct FollowUpAssistantFloatingToolbar: View {

    @Binding var showRecordingsSheet: Bool
    @Binding var showPromo: Bool
    
    @Binding var showTripsSheet: Bool

    // Feature gating
    var studioUnlocked: Bool
    var recordingFeaturesActive: Bool

    var body: some View {
        VStack(spacing: 12) {
            
            // Mic button (opens RecordingsView when unlocked, promo otherwise)
            Button {
                if studioUnlocked {
                    showRecordingsSheet = true
                } else {
                    showPromo = true
                }
            } label: {
                Group {
                    if studioUnlocked {
                        Image(systemName: "mic.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, recordingFeaturesActive ? .blue : .red)
                            .shadow(radius: 4)
                    } else {
                        Image(systemName: "mic.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(Color(.darkGray))
                            .shadow(radius: 4)
                    }
                }
            }

            // Car button (smaller icon, same circle size)
            Button {
                showTripsSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50) // circle size same as mic

                    Image(systemName: "car.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // slightly smaller than before
                        .foregroundColor(.white)
                }
                .shadow(radius: 4)
            }
            .buttonStyle(.plain)

        }
        .padding(.bottom, 30)
        .padding(.leading, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
