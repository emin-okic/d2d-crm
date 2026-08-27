//
//  ProspectRowFull.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI
import SwiftData

struct ProspectRowView: View {
    @Environment(\.modelContext) private var modelContext

    let prospect: Prospect
    private let minRowHeight: CGFloat = 104

    @State private var showCallSheet = false
    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    @State private var phoneError: String?
    @State private var originalPhone: String?

    private var phoneCallController: PhoneCallController {
        PhoneCallController(modelContext: modelContext)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(prospect.fullName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(ContactRowAddressFormatter.displayAddress(from: prospect.address))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel(prospect.address)
                }

                Spacer(minLength: 6)

                callButton
            }

            ContactActivityMetricsView(
                knockCount: prospect.sortedKnocks.count,
                emailCount: prospect.emailsSent.count,
                phoneCallCount: prospect.phoneCallCount
            )
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .sheet(isPresented: $showCallSheet) {
            PhoneActionSheet(
                context: .prospect(prospect),
                controller: phoneCallController,
                onCall: {
                    phoneCallController.call(context: .prospect(prospect))
                    showCallSheet = false
                },
                onEdit: {
                    originalPhone = prospect.contactPhone
                    newPhone = prospect.contactPhone
                    showCallSheet = false
                    showAddPhoneSheet = true
                },
                onCancel: {
                    showCallSheet = false
                }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddPhoneSheet) {
            AddPhoneBottomSheet(
                mode: originalPhone == nil ? .add : .edit,
                phone: $newPhone,
                error: $phoneError,
                onSave: savePhoneAndCall,
                onCancel: {
                    showAddPhoneSheet = false
                }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }
    }

    private var callButton: some View {
        Button(action: handleCallTapped) {
            Image(systemName: prospect.contactPhone.isEmpty ? "phone.badge.plus" : "phone.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.09), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            prospect.contactPhone.isEmpty
                ? "Add phone number"
                : "Call \(formatPhoneNumber(prospect.contactPhone))"
        )
    }

    private func handleCallTapped() {
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()

        if prospect.contactPhone.isEmpty {
            originalPhone = nil
            newPhone = ""
            showAddPhoneSheet = true
        } else {
            showCallSheet = true
        }
    }

    private func savePhoneAndCall() {
        guard validatePhoneNumber() else { return }

        let previous = originalPhone
        prospect.contactPhone = newPhone
        try? modelContext.save()

        logPhoneChangeNote(old: previous, new: newPhone)
        phoneCallController.call(context: .prospect(prospect))
        showAddPhoneSheet = false
    }

    private func logPhoneChangeNote(old: String?, new: String) {
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

        guard oldNormalized != newNormalized else { return }

        let formattedNew = PhoneValidator.formatted(new)
        let content: String

        if oldNormalized.isEmpty {
            content = "Added phone number \(formattedNew)."
        } else {
            content = "Updated phone number from \(PhoneValidator.formatted(old ?? "")) to \(formattedNew)."
        }

        prospect.notes.append(Note(content: content, date: Date(), prospect: prospect))
        try? modelContext.save()
    }

    private func validatePhoneNumber() -> Bool {
        if let error = PhoneValidator.validate(newPhone) {
            phoneError = error
            return false
        }

        phoneError = nil
        return true
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        }
        return raw
    }
}
