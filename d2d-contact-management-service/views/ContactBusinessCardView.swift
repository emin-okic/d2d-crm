//
//  ContactBusinessCardView.swift
//  d2d-studio
//
//  Created by Codex on 8/6/26.
//

import SwiftUI
import SwiftData

enum ContactBusinessCardKind {
    case prospect(Prospect)
    case customer(Customer)

    var title: String {
        switch self {
        case .prospect:
            return "Prospect"
        case .customer:
            return "Customer"
        }
    }

    var fullName: String {
        switch self {
        case .prospect(let prospect):
            return prospect.fullName
        case .customer(let customer):
            return customer.fullName
        }
    }

    var address: String {
        switch self {
        case .prospect(let prospect):
            return prospect.address
        case .customer(let customer):
            return customer.address
        }
    }

    var contactPhone: String {
        switch self {
        case .prospect(let prospect):
            return prospect.contactPhone
        case .customer(let customer):
            return customer.contactPhone
        }
    }

    var contactEmail: String {
        switch self {
        case .prospect(let prospect):
            return prospect.contactEmail
        case .customer(let customer):
            return customer.contactEmail
        }
    }

    var knockCount: Int {
        switch self {
        case .prospect(let prospect):
            return prospect.knockCount
        case .customer(let customer):
            return customer.knockCount
        }
    }

    var callCount: Int {
        switch self {
        case .prospect(let prospect):
            return prospect.phoneCalls.count
        case .customer(let customer):
            return customer.phoneCalls.count
        }
    }

    var emailCount: Int {
        switch self {
        case .prospect(let prospect):
            return prospect.emailsSent.count
        case .customer(let customer):
            return customer.emailsSent.count
        }
    }

    var phoneContext: PhoneActionContext {
        switch self {
        case .prospect(let prospect):
            return .prospect(prospect)
        case .customer(let customer):
            return .customer(customer)
        }
    }
}

struct ContactBusinessCardView: View {
    let contact: ContactBusinessCardKind
    let onOpenDetails: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showCallSheet = false
    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    @State private var phoneError: String?
    @State private var originalPhone: String?

    private var phoneCallController: PhoneCallController {
        PhoneCallController(modelContext: modelContext)
    }

    private var hasPhone: Bool {
        !contact.contactPhone.filter(\.isNumber).isEmpty
    }

    private var hasEmail: Bool {
        !trimmed(contact.contactEmail).isEmpty
    }

    private var hasAddress: Bool {
        !trimmed(contact.address).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.22))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(contact.title.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(hasAddress ? "Ready to visit" : "Needs address")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hasAddress ? .green : .secondary)
                }

                Text(contact.fullName.isEmpty ? "Unnamed contact" : contact.fullName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Label(hasAddress ? contact.address : "No address on file", systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(hasAddress ? .primary : .secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                ContactCardMetricTile(
                    title: "Knocks",
                    value: contact.knockCount,
                    systemImage: "hand.tap.fill",
                    tint: .green
                )

                ContactCardMetricTile(
                    title: "Calls",
                    value: contact.callCount,
                    systemImage: "phone.fill",
                    tint: .blue
                )

                ContactCardMetricTile(
                    title: "Emails",
                    value: contact.emailCount,
                    systemImage: "envelope.fill",
                    tint: .purple
                )
            }

            HStack(spacing: 10) {
                ContactCardAvailabilityPill(
                    systemImage: "phone.fill",
                    text: hasPhone ? PhoneValidator.formatted(contact.contactPhone) : "Add phone",
                    isAvailable: hasPhone,
                    action: handlePhoneTapped
                )

                ContactCardAvailabilityPill(
                    systemImage: "envelope.fill",
                    text: hasEmail ? contact.contactEmail : "No email",
                    isAvailable: hasEmail
                )
            }

            Button {
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                onOpenDetails()
                dismiss()
            } label: {
                Label("Open Details", systemImage: "person.text.rectangle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 24)
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
        .sheet(isPresented: $showCallSheet) {
            PhoneActionSheet(
                context: contact.phoneContext,
                controller: phoneCallController,
                onCall: {
                    phoneCallController.call(context: contact.phoneContext)
                    showCallSheet = false
                },
                onEdit: {
                    originalPhone = contact.contactPhone
                    newPhone = contact.contactPhone
                    phoneError = nil
                    showCallSheet = false
                    showAddPhoneSheet = true
                },
                onCancel: {
                    showCallSheet = false
                }
            )
            .presentationDetents([.fraction(0.36)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showAddPhoneSheet) {
            AddPhoneBottomSheet(
                mode: originalPhone == nil ? .add : .edit,
                phone: $newPhone,
                error: $phoneError,
                onSave: savePhoneAndShowCallSheet,
                onCancel: {
                    showAddPhoneSheet = false
                }
            )
            .presentationDetents([.fraction(0.42)])
            .presentationDragIndicator(.hidden)
        }
    }

    private func handlePhoneTapped() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()

        if hasPhone {
            showCallSheet = true
        } else {
            originalPhone = nil
            newPhone = ""
            phoneError = nil
            showAddPhoneSheet = true
        }
    }

    private func savePhoneAndShowCallSheet() {
        guard validatePhoneNumber() else { return }

        let previous = originalPhone
        contact.phoneContext.setPhone(newPhone)
        try? modelContext.save()

        logPhoneChangeNote(old: previous, new: newPhone)
        showAddPhoneSheet = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showCallSheet = true
        }
    }

    private func validatePhoneNumber() -> Bool {
        if let error = PhoneValidator.validate(newPhone) {
            phoneError = error
            return false
        }

        phoneError = nil
        return true
    }

    private func logPhoneChangeNote(old: String?, new: String) {
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

        guard oldNormalized != newNormalized else { return }

        let formattedNew = PhoneValidator.formatted(new)
        let content = oldNormalized.isEmpty
            ? "Added phone number \(formattedNew)."
            : "Updated phone number from \(PhoneValidator.formatted(old ?? "")) to \(formattedNew)."

        switch contact {
        case .prospect(let prospect):
            prospect.notes.append(Note(content: content, date: Date(), prospect: prospect))
        case .customer(let customer):
            customer.notes.append(Note(content: content, date: Date()))
        }

        try? modelContext.save()
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ContactCardMetricTile: View {
    let title: String
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

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

private struct ContactCardAvailabilityPill: View {
    let systemImage: String
    let text: String
    let isAvailable: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .accessibilityLabel(text)
    }

    private var content: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isAvailable ? .primary : .secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
