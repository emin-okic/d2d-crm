//
//  CustomerActionsController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import SwiftUI
import SwiftData
import PhoneNumberKit

@MainActor
final class CustomerActionsController: ObservableObject {

    // MARK: - Dependencies
    let customer: Customer
    let modelContext: ModelContext
    var onClose: (() -> Void)?

    // MARK: - UI State
    @Published var showAddPhoneSheet = false
    @Published var showCallConfirmation = false
    @Published var showAddEmailSheet = false
    @Published var showEmailConfirmation = false
    @Published var showCallSheet = false
    @Published var showCustomerLostConfirmation = false

    @Published var newPhone = ""
    @Published var newEmail = ""
    @Published var phoneError: String?

    @Published var originalPhone: String?

    // MARK: - Init
    init(
        customer: Customer,
        modelContext: ModelContext,
        onClose: (() -> Void)? = nil
    ) {
        self.customer = customer
        self.modelContext = modelContext
        self.onClose = onClose
    }

    // MARK: - Actions

    func callTapped() {
        if customer.contactPhone.isEmpty {
            originalPhone = nil
            showAddPhoneSheet = true
        } else {
            showCallSheet = true
        }
    }

    func emailTapped() {
        if customer.contactEmail.nilIfEmpty == nil {
            showAddEmailSheet = true
        } else {
            showEmailConfirmation = true
        }
    }

    func confirmCustomerLost() {
        showCustomerLostConfirmation = true
    }

    // MARK: - Call Flow

    func performCall() {
        logCustomerCallNote()

        if let url = URL(string: "tel://\(customer.contactPhone.filter(\.isNumber))") {
            UIApplication.shared.open(url)
        }
    }

    func savePhoneAndCall() {
        guard validatePhoneNumber() else { return }

        let previous = originalPhone
        customer.contactPhone = newPhone
        try? modelContext.save()

        logCustomerPhoneChangeNote(old: previous, new: newPhone)

        performCall()
        showAddPhoneSheet = false
    }

    // MARK: - Email Flow

    func saveEmail() {
        
        customer.contactEmail = newEmail
        
        try? modelContext.save()

        showAddEmailSheet = false
    }
    
    func logCustomerEmailNote() {
        let content = "Composed email to \(customer.contactEmail) on \(Date().formatted(date: .abbreviated, time: .shortened))."
        customer.notes.append(Note(content: content, date: Date()))
        try? modelContext.save()
    }

    // MARK: - Customer Lost

    func markCustomerLost() {
        convertCustomerToProspect(customer: customer)
        onClose?()
    }

    // MARK: - Helpers

    func logCustomerCallNote() {
        
        let formatted = PhoneValidator.formatted(customer.contactPhone)
        
        let content = "Called customer at \(formatted) on \(Date().formatted(date: .abbreviated, time: .shortened))."
        
        customer.notes.append(Note(content: content, date: Date()))
        
        try? modelContext.save()
    }

    func logCustomerPhoneChangeNote(old: String?, new: String) {
        
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

        guard oldNormalized != newNormalized else { return }

        let formattedNew = PhoneValidator.formatted(new)
        
        let content = oldNormalized.isEmpty
            ? "Added phone number \(formattedNew)."
            : "Updated phone number from \(PhoneValidator.formatted(old ?? "")) to \(formattedNew)."

        customer.notes.append(Note(content: content, date: Date()))
        
        try? modelContext.save()
    }

    func validatePhoneNumber() -> Bool {
        if let error = PhoneValidator.validate(newPhone) {
            phoneError = error
            return false
        }
        phoneError = nil
        return true
    }

    private func convertCustomerToProspect(customer: Customer) {
        let prospect = Prospect(
            fullName: customer.fullName,
            address: customer.address,
            count: customer.knockCount,
            list: "Prospects"
        )

        prospect.contactPhone = customer.contactPhone
        prospect.contactEmail = customer.contactEmail
        prospect.notes = customer.notes
        prospect.appointments = customer.appointments
        prospect.knockHistory = customer.knockHistory

        prospect.knockHistory.append(
            Knock(
                date: .now,
                status: "Customer Lost",
                latitude: customer.latitude ?? 0,
                longitude: customer.longitude ?? 0
            )
        )

        prospect.latitude = customer.latitude
        prospect.longitude = customer.longitude

        modelContext.insert(prospect)
        modelContext.delete(customer)
        try? modelContext.save()
    }
}
