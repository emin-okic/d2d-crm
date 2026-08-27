//
//  ProspectActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/21/25.
//

import SwiftUI
import MessageUI
import Contacts
import PhoneNumberKit
import SwiftData

struct ProspectActionsToolbar: View {
    @Bindable var prospect: Prospect
    @Environment(\.modelContext) private var modelContext

    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    
    @State private var showCallSheet = false
    
    @State private var showCreateSaleSheet = false
    @State private var showManualKnockSheet = false
    
    @State private var phoneError: String?
    
    // This variable is used for keeping track of the original phone # on changing it for note taking purposes
    @State private var originalPhone: String?
    
    private let customerController: CustomerController
    
    @State private var showEmailSheet = false
    
    private var phoneCallController: PhoneCallController {
        PhoneCallController(modelContext: modelContext)
    }
    
    init(prospect: Prospect, modelContext: ModelContext) {
        self._prospect = Bindable(prospect)
        self.customerController = CustomerController(modelContext: modelContext)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 24) {
                
                // Phone
                ContactDetailsActionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: .blue
                ) {
                    
                    // ✅ Haptic + sound
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    if prospect.contactPhone.isEmpty {
                        // Set the original phone number to nil for note taking purposes
                        originalPhone = nil
                        showAddPhoneSheet = true
                    } else {
                        showCallSheet = true
                    }
                }

                ContactDetailsActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .purple
                ) {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    showEmailSheet = true
                    
                }

                if prospect.list == "Prospects" {
                    ContactDetailsActionButton(
                        icon: "hand.tap.fill",
                        title: "Log Knock",
                        color: .orange
                    ) {
                        ContactScreenHapticsController.shared.successConfirmationTap()
                        ContactScreenSoundController.shared.playSound1()
                        showManualKnockSheet = true
                    }
                }

            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .center)

        }

        .sheet(isPresented: $showCallSheet) {
            PhoneActionSheet(
                context: .prospect(prospect),
                controller: phoneCallController,
                onCall: {
                    phoneCallController.call(
                        context: .prospect(prospect)
                    )
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
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
        
        // Add phone sheet
        .sheet(isPresented: $showAddPhoneSheet) {
            AddPhoneBottomSheet(
                mode: originalPhone == nil ? .add : .edit,
                phone: $newPhone,
                error: $phoneError,
                onSave: {
                    if validatePhoneNumber() {
                        let previous = originalPhone
                        prospect.contactPhone = newPhone
                        try? modelContext.save()

                        logPhoneChangeNote(old: previous, new: newPhone)

                        if let url = URL(string: "tel://\(newPhone.filter(\.isNumber))") {
                            UIApplication.shared.open(url)
                        }

                        showAddPhoneSheet = false
                    }
                },
                onCancel: {
                    showAddPhoneSheet = false
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }

        .sheet(isPresented: $showManualKnockSheet) {
            ManualKnockLogSheet(
                contactName: prospect.fullName,
                contactType: "Prospect",
                outcomes: manualKnockOutcomes,
                onLog: { result in
                    logManualKnock(result)
                    showManualKnockSheet = false
                },
                onCancel: {
                    showManualKnockSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }

        // Convert to Customer sheet using common stepper form
        .sheet(isPresented: $showCreateSaleSheet) {
            NavigationStack {
                CustomerCreateStepperView(
                    initialName: prospect.fullName,
                    initialAddress: prospect.address,
                    initialPhone: prospect.contactPhone,
                    initialEmail: prospect.contactEmail,
                    onComplete: { newCustomer in
                        // Transfer notes, knocks, appointments
                        transferProspectData(to: newCustomer)
                        
                        showCreateSaleSheet = false
                    },
                    onCancel: {
                        showCreateSaleSheet = false
                    }
                )
            }
            .presentationDetents([.fraction(0.5)])      // Limit to 50% of the screen
            .presentationDragIndicator(.visible)        // Show drag indicator
        }
        
        .sheet(isPresented: $showEmailSheet) {
            EmailActionSheet(
                context: .prospect(prospect)
            )
        }
        
    }
    
    /// Logs when an email is added or changed
    private func logEmailChangeNote(old: String?, new: String) {
        let oldNormalized = old?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let newNormalized = new.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 🚫 Prevent logging if nothing changed
        guard oldNormalized != newNormalized else {
            return
        }

        let content: String
        if !oldNormalized.isEmpty {
            content = "Updated email from \(oldNormalized) to \(newNormalized)."
        } else {
            content = "Added email address \(newNormalized)."
        }

        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)
        try? modelContext.save()
    }
    
    private var manualKnockOutcomes: [ManualKnockOutcome] {
        if prospect.isUnqualified {
            return [
                ManualKnockOutcome(title: "Wasn't Home", systemName: "house.slash.fill", color: .gray),
                ManualKnockOutcome(title: "Requalified", systemName: "arrow.uturn.backward.circle.fill", color: .green)
            ]
        }

        return [
            ManualKnockOutcome(title: "Unqualified", systemName: "xmark.octagon.fill", color: .red),
            ManualKnockOutcome(title: "Wasn't Home", systemName: "house.slash.fill", color: .gray),
            ManualKnockOutcome(title: "Follow Up Later", systemName: "calendar.badge.clock", color: .orange),
            ManualKnockOutcome(title: "Converted To Sale", systemName: "checkmark.seal.fill", color: .green)
        ]
    }

    private func logManualKnock(_ result: ManualKnockLogResult) {
        let location = LocationManager.shared.currentLocation
        let latitude = location?.latitude ?? 0
        let longitude = location?.longitude ?? 0
        let status = result.outcome.title

        if status == "Requalified" {
            prospect.isUnqualified = false
            prospect.fullName = prospect.fullName.replacingOccurrences(of: " - Unqualified", with: "")
        }

        prospect.knockCount += 1
        prospect.knockHistory.append(
            Knock(
                date: result.date,
                status: status,
                latitude: latitude,
                longitude: longitude
            )
        )

        if status == "Unqualified" {
            prospect.isUnqualified = true
            if !prospect.fullName.contains("Unqualified") {
                prospect.fullName = "\(prospect.fullName) - Unqualified"
            }
        }

        if let followUpDate = result.followUpDate {
            saveManualFollowUp(date: followUpDate)
        }

        if !result.note.isEmpty {
            prospect.notes.append(Note(content: result.note, date: result.date, prospect: prospect))
        }

        saveManualTripIfNeeded(result)
        try? modelContext.save()

        if result.completionAction == .convertToSale {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showCreateSaleSheet = true
            }
        }
    }

    private func saveManualFollowUp(date: Date) {
        let appointment = Appointment(
            title: "Follow-Up",
            location: prospect.address,
            clientName: prospect.fullName,
            date: date,
            type: "Follow-Up",
            notes: prospect.notes.map { $0.content },
            prospect: prospect
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

    private func transferProspectData(to customer: Customer) {
        // Deep copy notes, knocks, appointments
        customer.notes = prospect.notes.map {
            Note(content: $0.content, date: $0.date)
        }
        
        customer.knockHistory = prospect.knockHistory.map {
            Knock(date: $0.date, status: $0.status, latitude: $0.latitude, longitude: $0.longitude)
        }
        
        for appt in prospect.appointments {
            appt.prospect = nil // break old link
            customer.appointments.append(appt)
        }
        
        customer.applyDemographics(prospect.demographicsFormData)
        
        // Transfer phone calls back to prospect
        customer.phoneCalls = prospect.phoneCalls
        
        // Update ownership metadata
        for call in customer.phoneCalls {
            call.recipientUUID = customer.uuid
            call.recipientType = .customer
        }
        
        customer.emailsSent = prospect.emailsSent
        
        for email in customer.emailsSent {
            email.recipientUUID = customer.uuid
            email.recipientType = .customer
        }

        // Insert new customer and delete old prospect
        modelContext.insert(customer)
        modelContext.delete(prospect)

        do {
            try modelContext.save()
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.dismiss(animated: true)
                }
            }
        } catch {
            print("❌ Failed to convert prospect to customer:", error)
        }
    }
    
    /// This function is intended to log call activity for prospects
    private func logCallNote() {
        
        let formatted = PhoneValidator.formatted(prospect.contactPhone)
        
        let content = "Called prospect at \(formatted) on \(Date().formatted(date: .abbreviated, time: .shortened))."

        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)

        try? modelContext.save()
    }
    
    /// Logs when an email is composed
    private func logEmailNote() {
        let content = "Composed email to \(prospect.contactEmail) on \(Date().formatted(date: .abbreviated, time: .shortened))."
        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)
        try? modelContext.save()
    }
    
    /// Logs when a phone number is added or changed
    private func logPhoneChangeNote(old: String?, new: String) {
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

        // 🚫 Prevent logging if nothing actually changed
        guard oldNormalized != newNormalized else {
            return
        }

        let formattedNew = PhoneValidator.formatted(new)

        let content: String
        if !oldNormalized.isEmpty {
            
            let formattedOld = PhoneValidator.formatted(old ?? "")
            
            content = "Updated phone number from \(formattedOld) to \(formattedNew)."
            
        } else {
            content = "Added phone number \(formattedNew)."
        }

        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)

        try? modelContext.save()
    }
    
    private func validatePhoneNumber() -> Bool {
        if let error = PhoneValidator.validate(newPhone) {
            phoneError = error
            return false
        } else {
            phoneError = nil
            return true
        }
    }

    
}
