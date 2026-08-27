//
//  PhoneActionSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//

import SwiftUI

struct PhoneActionSheet: View {

    let context: PhoneActionContext
    let controller: PhoneCallController

    let onCall: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    private var formattedPhone: String {
        PhoneValidator.formatted(context.getPhone())
    }

    private var totalCalls: Int {
        controller.totalCallsMade(for: context)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 38, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 14)

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                    Image(systemName: "phone.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text(context.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(formattedPhone)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Label("\(totalCalls) previous calls", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                Spacer(minLength: 8)

                Button(action: cancelTapped) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray6), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)

            HStack(spacing: 10) {
                Button(action: editTapped) {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button(action: callTapped) {
                    Label("Call", systemImage: "phone.fill")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.hidden)
    }

    private func cancelTapped() {
        TelemarketingManagerHapticsController.shared.lightTap()
        TelemarketingManagerSoundController.shared.playSound1()
        onCancel()
    }

    private func editTapped() {
        TelemarketingManagerHapticsController.shared.lightTap()
        TelemarketingManagerSoundController.shared.playSound1()
        onEdit()
    }

    private func callTapped() {
        TelemarketingManagerHapticsController.shared.successConfirmationTap()
        TelemarketingManagerSoundController.shared.playSound1()
        onCall()
    }
}
