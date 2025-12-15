//
//  AddPhoneBottomSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/15/25.
//
import SwiftUI
import PhoneNumberKit

enum PhoneSheetMode {
    case add
    case edit
}

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
            ? "Add a phone number for this contact."
            : "Update the existing phone number."
    }

    private var primaryButtonTitle: String {
        mode == .add ? "Add Number" : "Save Changes"
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            TextField(
                mode == .add ? "Enter phone number" : "Update phone number",
                text: $phone
            )
            .keyboardType(.phonePad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .onChange(of: phone) { _ in
                // ✅ Live validation
                if let errorMessage = PhoneValidator.validate(phone) {
                    error = errorMessage
                } else {
                    error = nil
                }
            }

            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)

                Button(primaryButtonTitle) {
                    onSave()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(
                    phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    error != nil
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}
