//
//  ContactExportOptionsSheet.swift
//  d2d-studio
//

import SwiftUI

struct ContactExportOptionsSheet: View {
    let contactName: String
    let onSaveToContacts: () -> Void
    let onShareContact: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Export Contact")
                    .font(.headline)

                Text(contactName.isEmpty ? "Choose how to use this contact." : "Choose how to use \(contactName).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            VStack(spacing: 10) {
                ContactExportOptionButton(
                    iconName: "person.crop.circle.badge.plus",
                    title: "Save to iPhone Contacts",
                    subtitle: "Add or update this person in the Contacts app.",
                    tint: .blue,
                    action: onSaveToContacts
                )

                ContactExportOptionButton(
                    iconName: "square.and.arrow.up",
                    title: "Share Contact",
                    subtitle: "Send an import link to a friend.",
                    tint: .green,
                    action: onShareContact
                )
            }

            Spacer(minLength: 18)

            Button("Cancel", role: .cancel, action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

struct ContactExportConfirmationSheet: View {
    let contactName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(spacing: 6) {
                Text("Save to iPhone Contacts")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text("Save Contact")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Cancel", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var message: String {
        if contactName.isEmpty {
            return "Save this contact to your iPhone Contacts app?"
        }

        return "Save \(contactName) to your iPhone Contacts app?"
    }
}

private struct ContactExportOptionButton: View {
    let iconName: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContactExportOptionsSheet(
        contactName: "Taylor Morgan",
        onSaveToContacts: {},
        onShareContact: {},
        onCancel: {}
    )
}
