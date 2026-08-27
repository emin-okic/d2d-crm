//
//  AddPhoneBottomSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/15/25.
//

import SwiftUI
import PhoneNumberKit

struct AddPhoneBottomSheet: View {
    let mode: PhoneSheetMode

    @Binding var phone: String
    @Binding var error: String?

    let onSave: () -> Void
    let onCancel: () -> Void

    private var title: String {
        mode == .add ? "Add Phone Number" : "Edit Phone Number"
    }

    private var subtitle: String {
        mode == .add
            ? "Save a reachable number before starting the call."
            : "Update the number used for calls and activity tracking."
    }

    private var primaryButtonTitle: String {
        mode == .add ? "Save and Call" : "Save Changes"
    }

    private var canSave: Bool {
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && error == nil
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
                    Image(systemName: mode == .add ? "phone.badge.plus" : "phone.connection")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 7) {
                Text("Phone")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    TextField(
                        mode == .add ? "Enter phone number" : "Update phone number",
                        text: $phone
                    )
                    .keyboardType(.phonePad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.body.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(error == nil ? Color(.systemGray5) : Color.red.opacity(0.65), lineWidth: 1)
                )
                .onChange(of: phone) { _, _ in
                    if let errorMessage = PhoneValidator.validate(phone) {
                        error = errorMessage
                    } else {
                        error = nil
                    }
                }

                if let error {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)

            HStack(spacing: 10) {
                Button(action: cancelTapped) {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button(action: saveTapped) {
                    Text(primaryButtonTitle)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!canSave)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }

    private func cancelTapped() {
        TelemarketingManagerHapticsController.shared.lightTap()
        TelemarketingManagerSoundController.shared.playSound1()
        onCancel()
    }

    private func saveTapped() {
        TelemarketingManagerHapticsController.shared.successConfirmationTap()
        TelemarketingManagerSoundController.shared.playSound1()
        onSave()
    }
}
