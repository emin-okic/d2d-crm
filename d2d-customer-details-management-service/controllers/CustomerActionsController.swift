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

    
    @Published var showCallSheet = false
    @Published var showCustomerLostConfirmation = false

    @Published var newPhone = ""

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
    
    // MARK: - Customer Lost

    func markCustomerLost() {
        convertCustomerToProspect(customer: customer)
        onClose?()
    }

    func logManualKnock(_ result: ManualKnockLogResult) {
        let location = LocationManager.shared.currentLocation
        let latitude = location?.latitude ?? 0
        let longitude = location?.longitude ?? 0
        let status = result.outcome.title

        if result.completionAction == .customerLost {
            convertCustomerToProspect(
                customer: customer,
                knockDate: result.date,
                latitude: latitude,
                longitude: longitude,
                note: result.note,
                followUpDate: result.followUpDate,
                tripStartAddress: result.tripStartAddress,
                tripEndAddress: result.tripEndAddress,
                tripDate: result.tripDate
            )
            onClose?()
            return
        }

        customer.knockCount += 1
        customer.knockHistory.append(
            Knock(
                date: result.date,
                status: status,
                latitude: latitude,
                longitude: longitude
            )
        )

        if let followUpDate = result.followUpDate {
            saveManualFollowUp(date: followUpDate)
        }

        if !result.note.isEmpty {
            customer.notes.append(Note(content: result.note, date: result.date))
        }

        saveManualTripIfNeeded(result)
        try? modelContext.save()
    }

    private func saveManualFollowUp(date: Date) {
        let appointment = Appointment(
            title: "Follow-Up",
            location: customer.address,
            clientName: customer.fullName,
            date: date,
            type: "Follow-Up",
            notes: customer.notes.map { $0.content },
            customer: customer
        )
        modelContext.insert(appointment)
    }

    private func saveManualTripIfNeeded(_ result: ManualKnockLogResult) {
        let endAddress = result.tripEndAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !endAddress.isEmpty else { return }

        let trip = Trip(
            startAddress: result.tripStartAddress,
            endAddress: endAddress,
            miles: 0,
            date: result.tripDate
        )
        modelContext.insert(trip)
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

    private func convertCustomerToProspect(
        customer: Customer,
        knockDate: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil,
        note: String = "",
        followUpDate: Date? = nil,
        tripStartAddress: String = "",
        tripEndAddress: String = "",
        tripDate: Date = .now
    ) {
        let prospect = Prospect(
            fullName: customer.fullName,
            address: customer.address,
            count: customer.knockCount + 1,
            list: "Prospects"
        )

        prospect.contactPhone = customer.contactPhone
        prospect.contactEmail = customer.contactEmail
        prospect.applyDemographics(customer.demographicsFormData)
        prospect.notes = customer.notes
        if !note.isEmpty {
            prospect.notes.append(Note(content: note, date: knockDate, prospect: prospect))
        }
        prospect.appointments = customer.appointments
        if let followUpDate {
            let appointment = Appointment(
                title: "Follow-Up",
                location: prospect.address,
                clientName: prospect.fullName,
                date: followUpDate,
                type: "Follow-Up",
                notes: prospect.notes.map { $0.content },
                prospect: prospect
            )
            prospect.appointments.append(appointment)
            modelContext.insert(appointment)
        }
        prospect.knockHistory = customer.knockHistory
        
        let manualTripEndAddress = tripEndAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualTripEndAddress.isEmpty {
            let trip = Trip(
                startAddress: tripStartAddress,
                endAddress: manualTripEndAddress,
                miles: 0,
                date: tripDate
            )
            modelContext.insert(trip)
        }
        
        // ✅ Transfer emails BEFORE deleting customer
        transferEmailsToProspect(from: customer, to: prospect)
        
        // ✅ Transfer phone calls BEFORE deleting customer
        transferPhoneCallsToProspect(from: customer, to: prospect)

        prospect.knockHistory.append(
            Knock(
                date: knockDate,
                status: "Customer Lost",
                latitude: latitude ?? customer.latitude ?? 0,
                longitude: longitude ?? customer.longitude ?? 0
            )
        )

        prospect.latitude = customer.latitude
        prospect.longitude = customer.longitude

        modelContext.insert(prospect)
        modelContext.delete(customer)
        try? modelContext.save()
    }
    
    private func transferEmailsToProspect(from customer: Customer, to prospect: Prospect) {
        prospect.emailsSent = customer.emailsSent

        for email in prospect.emailsSent {
            email.recipientUUID = prospect.uuid
            email.recipientType = .prospect
        }
    }
    
    private func transferPhoneCallsToProspect(from customer: Customer, to prospect: Prospect) {
        prospect.phoneCalls = customer.phoneCalls
        for call in prospect.phoneCalls {
            call.recipientUUID = prospect.uuid
            call.recipientType = .prospect
        }
    }
    
}
