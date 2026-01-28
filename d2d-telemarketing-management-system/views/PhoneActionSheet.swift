//
//  PhoneActionSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//

import SwiftUI
import PhoneNumberKit

struct PhoneActionSheet: View {

    let context: PhoneActionContext
    let controller: PhoneCallController

    let onCall: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Top toolbar with circular chevron
            HStack {
                Button(action: {
                    
                    // ✅ Haptic + sound
                    TelemarketingManagerHapticsController.shared.lightTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    
                    onCancel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.bottom, 4)

            // Title & Phone number
            Text("Call \(context.displayName)?")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(PhoneValidator.formatted(context.getPhone()))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Total calls made
            Text("Total Calls Made: \(controller.totalCallsMade(for: context))")
                .font(.caption)
                .foregroundColor(.secondary)

            // Action buttons
            HStack(spacing: 12) {
                Button("Edit Number") { onEdit() }
                    .buttonStyle(.bordered)

                Button("Call") { onCall() }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
    }
}
