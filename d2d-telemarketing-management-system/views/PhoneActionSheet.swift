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

    private var formattedPhone: String {
        PhoneValidator.formatted(context.getPhone())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            HStack(alignment: .top, spacing: 12) {
                D2DPhoneBadge(systemImage: "phone.connection.fill")

                VStack(alignment: .leading, spacing: 5) {
                    Text("D2D Studio")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)

                    Text("Call \(context.displayName)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(formattedPhone)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Button(action: {
                    TelemarketingManagerHapticsController.shared.lightTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onCancel()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemGroupedBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            HStack(spacing: 10) {
                PhoneActionStatCard(
                    title: "Calls logged",
                    value: "\(controller.totalCallsMade(for: context))",
                    systemImage: "waveform.path.ecg",
                    tint: .blue
                )

                PhoneActionStatCard(
                    title: "Next step",
                    value: "Call",
                    systemImage: "arrow.up.right.circle.fill",
                    tint: .green
                )
            }

            HStack(spacing: 12) {
                Button(action: {
                    TelemarketingManagerHapticsController.shared.lightTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onEdit()
                }) {
                    Label("Edit Number", systemImage: "pencil")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    TelemarketingManagerHapticsController.shared.successConfirmationTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onCall()
                }) {
                    Label("Call Now", systemImage: "phone.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .presentationDetents([.fraction(0.36)])
        .presentationDragIndicator(.hidden)
    }
}

private struct D2DPhoneBadge: View {
    let systemImage: String

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.14))
                .frame(width: 50, height: 50)

            Image(systemName: systemImage)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.blue)

            Text("d2d")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue, in: Capsule())
                .offset(y: 5)
        }
        .frame(width: 56, height: 56)
    }
}

private struct PhoneActionStatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        )
    }
}
