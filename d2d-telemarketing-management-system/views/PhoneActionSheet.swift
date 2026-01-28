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

            // Top toolbar with back chevron
            HStack {
                Button(action: {
                    TelemarketingManagerHapticsController.shared.lightTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onCancel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                Spacer()
            }

            // Title & Phone number
            VStack(spacing: 4) {
                Text("Call \(context.displayName)?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(PhoneValidator.formatted(context.getPhone()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Total Calls: \(controller.totalCallsMade(for: context))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Horizontal buttons with haptics + sound
            HStack(spacing: 12) {
                Button(action: {
                    TelemarketingManagerHapticsController.shared.lightTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onEdit()
                }) {
                    Text("Edit")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }

                Button(action: {
                    TelemarketingManagerHapticsController.shared.successConfirmationTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onCall()
                }) {
                    Text("Call")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
        }
        .padding()
        .presentationDetents([.fraction(0.25)]) // smaller sheet
        .presentationDragIndicator(.visible)
    }
}
