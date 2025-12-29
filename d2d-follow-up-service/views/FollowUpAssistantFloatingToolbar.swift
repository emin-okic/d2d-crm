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

        }
        .padding(.bottom, 30)
        .padding(.leading, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
