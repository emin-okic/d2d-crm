//
//  ProspectActionsController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/25/26.
//

import SwiftUI
import SwiftData
import PhoneNumberKit

final class ProspectActionsController {

    private let modelContext: ModelContext
    private let prospect: Prospect

    init(prospect: Prospect, modelContext: ModelContext) {
        self.prospect = prospect
        self.modelContext = modelContext
    }

    // MARK: - Phone

    func validatePhone(_ phone: String) -> String? {
        PhoneValidator.validate(phone)
    }

    func savePhoneChange(old: String?, new: String) {
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

        guard oldNormalized != newNormalized else { return }

        prospect.contactPhone = new

        let content: String
        if !oldNormalized.isEmpty {
            content = "Updated phone number from \(PhoneValidator.formatted(old ?? "")) to \(PhoneValidator.formatted(new))."
        } else {
            content = "Added phone number \(PhoneValidator.formatted(new))."
        }

        logNote(content)
        try? modelContext.save()
    }

    func logCall() {
        let formatted = PhoneValidator.formatted(prospect.contactPhone)
        logNote("Called prospect at \(formatted) on \(Date().formatted(date: .abbreviated, time: .shortened)).")
    }

    func callPhone() {
        let digits = prospect.contactPhone.filter(\.isNumber)
        if let url = URL(string: "tel://\(digits)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Email

    func logEmailComposed() {
        logNote("Composed email to \(prospect.contactEmail) on \(Date().formatted(date: .abbreviated, time: .shortened)).")
    }

    func logEmailChange(old: String?, new: String) {
        let oldNormalized = old?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let newNormalized = new.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard oldNormalized != newNormalized else { return }

        let content = oldNormalized.isEmpty
            ? "Added email address \(newNormalized)."
            : "Updated email from \(oldNormalized) to \(newNormalized)."

        logNote(content)
    }

    // MARK: - Conversion

    func convertToCustomer(_ customer: Customer) {
        customer.notes = prospect.notes.map { Note(content: $0.content, date: $0.date) }
        customer.knockHistory = prospect.knockHistory.map {
            Knock(date: $0.date, status: $0.status, latitude: $0.latitude, longitude: $0.longitude)
        }

        for appt in prospect.appointments {
            appt.prospect = nil
            customer.appointments.append(appt)
        }

        modelContext.insert(customer)
        modelContext.delete(prospect)

        do {
            try modelContext.save()
            dismissAllSheets()
        } catch {
            print("❌ Failed to convert prospect:", error)
        }
    }

    // MARK: - Helpers

    private func logNote(_ content: String) {
        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)
        try? modelContext.save()
    }

    private func dismissAllSheets() {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.dismiss(animated: true)
            }
        }
    }
}
