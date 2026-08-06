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
        mode == .add ? "Add phone number" : "Edit phone number"
    }

    private var subtitle: String {
        mode == .add
            ? "Capture the best number before the next touchpoint."
            : "Keep this contact reachable from the CRM."
    }

    private var primaryButtonTitle: String {
        "Save Phone Number"
    }

    private var isSaveDisabled: Bool {
        phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || error != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            HStack(alignment: .top, spacing: 12) {
                D2DEditPhoneBadge()

                VStack(alignment: .leading, spacing: 5) {
                    Text("D2D Studio")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)

                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Phone")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.12), in: Circle())

                    TextField(
                        mode == .add ? "Enter phone number" : "Update phone number",
                        text: $phone
                    )
                    .keyboardType(.phonePad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.headline)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(error == nil ? Color(.separator).opacity(0.35) : Color.red.opacity(0.75), lineWidth: 0.8)
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
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                } else {
                    Label("After saving, confirm the call on the next screen.", systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    TelemarketingManagerHapticsController.shared.lightTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    TelemarketingManagerHapticsController.shared.successConfirmationTap()
                    TelemarketingManagerSoundController.shared.playSound1()
                    onSave()
                }) {
                    Label(primaryButtonTitle, systemImage: "phone.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaveDisabled)
                .opacity(isSaveDisabled ? 0.55 : 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.hidden)
    }
}

private struct D2DEditPhoneBadge: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.14))
                .frame(width: 50, height: 50)

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.green)

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
