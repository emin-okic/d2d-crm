//
//  ContactDetailsBusinessCardView.swift
//  d2d-studio
//
//  Created by Codex on 8/7/26.
//

import SwiftUI
import SwiftData

@available(iOS 18.0, *)
enum ContactDetailsBusinessCardKind {
    case prospect(Prospect)
    case customer(Customer)

    var title: String {
        switch self {
        case .prospect: "Prospect"
        case .customer: "Customer"
        }
    }

    var fullName: String {
        switch self {
        case .prospect(let prospect): prospect.fullName
        case .customer(let customer): customer.fullName
        }
    }

    var address: String {
        switch self {
        case .prospect(let prospect): prospect.address
        case .customer(let customer): customer.address
        }
    }

    var contactPhone: String {
        switch self {
        case .prospect(let prospect): prospect.contactPhone
        case .customer(let customer): customer.contactPhone
        }
    }

    var contactEmail: String {
        switch self {
        case .prospect(let prospect): prospect.contactEmail
        case .customer(let customer): customer.contactEmail
        }
    }

    var knockCount: Int {
        switch self {
        case .prospect(let prospect): prospect.knockCount
        case .customer(let customer): customer.knockCount
        }
    }

    var callCount: Int {
        switch self {
        case .prospect(let prospect): prospect.phoneCalls.count
        case .customer(let customer): customer.phoneCalls.count
        }
    }

    var emailCount: Int {
        switch self {
        case .prospect(let prospect): prospect.emailsSent.count
        case .customer(let customer): customer.emailsSent.count
        }
    }

    var phoneContext: PhoneActionContext {
        switch self {
        case .prospect(let prospect): .prospect(prospect)
        case .customer(let customer): .customer(customer)
        }
    }

    var emailContext: EmailContactContext {
        switch self {
        case .prospect(let prospect): .prospect(prospect)
        case .customer(let customer): .customer(customer)
        }
    }
}

@available(iOS 18.0, *)
struct ContactDetailsBusinessCardView: View {
    let contact: ContactDetailsBusinessCardKind
    @Binding var editableName: String
    @Binding var editableAddress: String
    @FocusState.Binding var isAddressFocused: Bool
    @ObservedObject var searchViewModel: SearchCompleterViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var isEditingName = false
    @State private var isEditingAddress = false
    @State private var showCallSheet = false
    @State private var showAddPhoneSheet = false
    @State private var showEmailSheet = false
    @State private var newPhone = ""
    @State private var phoneError: String?
    @State private var originalPhone: String?

    private var phoneCallController: PhoneCallController {
        PhoneCallController(modelContext: modelContext)
    }

    private var hasAddress: Bool {
        !trimmed(editableAddress).isEmpty
    }

    private var hasPhone: Bool {
        !contact.contactPhone.filter(\.isNumber).isEmpty
    }

    private var hasEmail: Bool {
        !trimmed(contact.contactEmail).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            identityEditor
            metricGrid
            contactMethods
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        )
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
        .sheet(isPresented: $showEmailSheet) {
            EmailActionSheet(context: contact.emailContext)
                .environment(\.modelContext, modelContext)
        }
    }

    private var identityEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(contact.title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(hasAddress ? "Ready to visit" : "Needs address")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasAddress ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                if isEditingName {
                    iconTextField(
                        systemImage: "person.fill",
                        placeholder: "Full name",
                        text: $editableName,
                        submit: { isEditingName = false }
                    )
                } else {
                    editableRow(
                        systemImage: "person.fill",
                        text: editableName.isEmpty ? "Unnamed contact" : editableName,
                        tint: .blue
                    ) {
                        isEditingName = true
                    }
                }

                if isEditingAddress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 32)

                            TextField("Address", text: $editableAddress)
                                .focused($isAddressFocused)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .font(.subheadline.weight(.semibold))
                                .onSubmit {
                                    isEditingAddress = false
                                    isAddressFocused = false
                                }
                                .onChange(of: editableAddress) { _, newValue in
                                    searchViewModel.updateQuery(newValue)
                                }
                        }

                        if isAddressFocused, let suggestion = searchViewModel.results.first {
                            Button {
                                SearchBarController.resolveAndSelectAddress(from: suggestion) { resolved in
                                    editableAddress = resolved
                                    searchViewModel.clear()
                                    isAddressFocused = false
                                    isEditingAddress = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkle.magnifyingglass")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Autofill top match")
                                            .font(.caption.weight(.semibold))
                                        Text(suggestion.subtitle.isEmpty ? suggestion.title : "\(suggestion.title), \(suggestion.subtitle)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                } else {
                    editableRow(
                        systemImage: "mappin.and.ellipse",
                        text: editableAddress.isEmpty ? "No address on file" : editableAddress,
                        tint: .secondary
                    ) {
                        isEditingAddress = true
                        isAddressFocused = true
                    }
                }
            }
        }
    }

    private var metricGrid: some View {
        HStack(spacing: 10) {
            ContactDetailsMetricTile(title: "Knocks", value: contact.knockCount, systemImage: "hand.tap.fill", tint: .green)
            ContactDetailsMetricTile(title: "Calls", value: contact.callCount, systemImage: "phone.fill", tint: .blue)
            ContactDetailsMetricTile(title: "Emails", value: contact.emailCount, systemImage: "envelope.fill", tint: .purple)
        }
    }

    private var contactMethods: some View {
        HStack(spacing: 10) {
            ContactDetailsAvailabilityPill(
                systemImage: "phone.fill",
                text: hasPhone ? PhoneValidator.formatted(contact.contactPhone) : "Add phone",
                isAvailable: hasPhone,
                action: handlePhoneTapped
            )

            ContactDetailsAvailabilityPill(
                systemImage: "envelope.fill",
                text: hasEmail ? contact.contactEmail : "Add email",
                isAvailable: hasEmail,
                action: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showEmailSheet = true
                }
            )
        }
    }

    private func editableRow(systemImage: String, text: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func iconTextField(systemImage: String, placeholder: String, text: Binding<String>, submit: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(.subheadline.weight(.semibold))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onSubmit(submit)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
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

private struct ContactDetailsMetricTile: View {
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
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ContactDetailsAvailabilityPill: View {
    let systemImage: String
    let text: String
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(text, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isAvailable ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
