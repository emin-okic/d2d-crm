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

    private var callHistory: [PhoneCall] {
        controller.callHistory(for: context)
    }

    private var totalCalls: Int {
        callHistory.count
    }

    private var recentCalls: [PhoneCall] {
        Array(callHistory.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 38, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 14)

            header
                .padding(.horizontal, 18)
                .padding(.bottom, 14)

            callHistorySection
                .padding(.horizontal, 18)
                .padding(.bottom, 14)

            actionButtons
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
    }

    private var header: some View {
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
    }

    private var callHistorySection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("Recent Calls", systemImage: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if totalCalls > recentCalls.count {
                    Text("Latest \(recentCalls.count) of \(totalCalls)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if recentCalls.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "phone.down.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray6), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No calls logged yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Start a call to create the first history entry.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 7) {
                    ForEach(recentCalls, id: \.id) { call in
                        callHistoryRow(call)
                    }
                }
            }
        }
    }

    private func callHistoryRow(_ call: PhoneCall) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "phone.arrow.up.right.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
                .frame(width: 28, height: 28)
                .background(Color.green.opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(call.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(relativeDate(call.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
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

    private func relativeDate(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }
}
