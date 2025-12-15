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

struct ProspectActionsToolbar: View {
    @Bindable var prospect: Prospect
    @Environment(\.modelContext) private var modelContext

    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    
    @State private var showCallSheet = false

    @State private var showAddEmailSheet = false
    @State private var newEmail = ""
    @State private var showEmailConfirmation = false
    
    @State private var showDeleteConfirmation = false
    
    @State private var showCreateSaleSheet = false
    
    @State private var phoneError: String?
    
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    // This variable is used for keeping track of the original phone # on changing it for note taking purposes
    @State private var originalPhone: String?

    var body: some View {
        ZStack {
            HStack(spacing: 24) {
                // Phone
                iconButton(systemName: "phone.fill") {
                    if prospect.contactPhone.isEmpty {
                        
                        // Set the original phone number to nil for note taking purposes
                        originalPhone = nil

                        showAddPhoneSheet = true
                    } else {
                        showCallSheet = true
                    }
                }

                // Email
                iconButton(systemName: "envelope.fill") {
                    if prospect.contactEmail.nilIfEmpty == nil {
                        showAddEmailSheet = true
                    } else {
                        showEmailConfirmation = true
                    }
                }

                // Create Sale
                if prospect.list == "Prospects" {
                    Button(action: {
                        showCreateSaleSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 34, height: 34)   // same as other icons

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))        // ~25% smaller than .title2
                                .foregroundColor(.white)
                                .scaleEffect(0.75)              // shrink inside the circle
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Export Contact
                iconButton(systemName: "person.crop.circle.badge.plus") {
                    showExportPrompt = true
                }

                // Delete Contact
                iconButton(systemName: "trash.fill", color: .red) {
                    showDeleteConfirmation = true
                }
            }
            .padding(.vertical, 8)

            // ✅ Floating banner at top
            if showExportSuccessBanner {
                VStack {
                    Spacer().frame(height: 60)
                    Text(exportSuccessMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .zIndex(999)
            }
        }

        // Delete confirmation
        .confirmationDialog(
            "Are you sure you want to delete this contact?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProspect()
            }
            Button("Cancel", role: .cancel) { }
        }

        // Phone confirmation
        .sheet(isPresented: $showCallSheet) {
            CallActionBottomSheet(
                phone: formattedPhone(prospect.contactPhone),
                onCall: {
                    logCallNote()

                    if let url = URL(string: "tel://\(prospect.contactPhone.filter(\.isNumber))") {
                        UIApplication.shared.open(url)
                    }

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

        // Email confirmation
        .confirmationDialog(
            "Send email to \(prospect.contactEmail)?",
            isPresented: $showEmailConfirmation,
            titleVisibility: .visible
        ) {
            Button("Compose Email") {
                if let url = URL(string: "mailto:\(prospect.contactEmail)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Email") {
                newEmail = prospect.contactEmail // Pre-fill current value
                showAddEmailSheet = true
            }
            Button("Cancel", role: .cancel) { }
        }

        // Export confirmation
        .alert("Export to Contacts", isPresented: $showExportPrompt) {
            Button("Yes") {
                exportToContacts()
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Would you like to save this contact to your iOS Contacts app?")
        }

        // Create sale sheet
        .sheet(isPresented: $showCreateSaleSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Confirm Customer Info")) {
                        TextField("Full Name", text: $prospect.fullName)
                        TextField("Address", text: $prospect.address)
                        TextField("Phone", text: Binding(
                            get: { prospect.contactPhone },
                            set: { prospect.contactPhone = $0 }
                        ))
                        TextField("Email", text: Binding(
                            get: { prospect.contactEmail },
                            set: { prospect.contactEmail = $0 }
                        ))
                    }

                    Section {
                        
                        Button("Confirm Sale") {
                            createCustomer(from: prospect)
                            showCreateSaleSheet = false
                        }
                        .disabled(prospect.fullName.isEmpty || prospect.address.isEmpty)
                        
                    }
                }
                .navigationTitle("Create Sale")
                .navigationBarTitleDisplayMode(.inline)
            }
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
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }

        // Add email sheet
        .sheet(isPresented: $showAddEmailSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Email Address")
                        .font(.headline)

                    TextField("Enter email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    Button("Save Email") {
                        prospect.contactEmail = newEmail
                        try? modelContext.save()

                        if let url = URL(string: "mailto:\(newEmail)") {
                            UIApplication.shared.open(url)
                        }

                        showAddEmailSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
                .navigationTitle("Email Address")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddEmailSheet = false
                        }
                    }
                }
            }
        }
    }
    
    /// This function is intended to log call activity for prospects
    private func logCallNote() {
        let formatted = formattedPhone(prospect.contactPhone)
        let content = "Called prospect at \(formatted) on \(Date().formatted(date: .abbreviated, time: .shortened))."

        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)

        try? modelContext.save()
    }
    
    /// Logs when a phone number is added or changed
    private func logPhoneChangeNote(old: String?, new: String) {
        let oldNormalized = normalizedPhone(old)
        let newNormalized = normalizedPhone(new)

        // 🚫 Prevent logging if nothing actually changed
        guard oldNormalized != newNormalized else {
            return
        }

        let formattedNew = formattedPhone(new)

        let content: String
        if !oldNormalized.isEmpty {
            let formattedOld = formattedPhone(old ?? "")
            content = "Updated phone number from \(formattedOld) to \(formattedNew)."
        } else {
            content = "Added phone number \(formattedNew)."
        }

        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)

        try? modelContext.save()
    }
    
    /// This normalizes the phone # for comparing changes for note taking purposes
    private func normalizedPhone(_ value: String?) -> String {
        return value?.filter(\.isNumber) ?? ""
    }
    
    // MARK: - Core: Convert to Customer (Appointments Clone Fix)
    private func createCustomer(from prospect: Prospect) {
        // ✅ Deep copy notes, knocks, and appointments
        let clonedNotes = prospect.notes.map { Note(content: $0.content, date: $0.date) }
        let clonedKnocks = prospect.knockHistory.map {
            Knock(date: $0.date, status: $0.status, latitude: $0.latitude, longitude: $0.longitude)
        }
        let clonedAppointments = prospect.appointments.map { appt in
            Appointment(
                title: appt.title,
                location: appt.location,
                clientName: appt.clientName,
                date: appt.date,
                type: appt.type,
                notes: appt.notes,
                prospect: prospect // temporary, rebind below
            )
        }

        // ✅ Create Customer record
        let customer = Customer(fullName: prospect.fullName, address: prospect.address, count: prospect.knockCount)
        customer.contactEmail = prospect.contactEmail
        customer.contactPhone = prospect.contactPhone
        customer.notes = clonedNotes
        customer.knockHistory = clonedKnocks

        // ✅ Link cloned appointments to the new customer
        for appointment in clonedAppointments {
            appointment.prospect = nil // break old link
            customer.appointments.append(appointment)
        }

        // ✅ Insert & delete old records
        modelContext.insert(customer)
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }
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
            print("❌ Failed to create customer: \(error)")
        }
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

    // MARK: - Utility buttons & validation
    private func iconButton(systemName: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private func formattedPhone(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 10 else { return raw }
        return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
    }

    private func exportToContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                showExportFeedback("Contacts access denied.")
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: prospect.fullName)
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]

            do {
                let matches = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                let existing = matches.first(where: {
                    $0.postalAddresses.first?.value.street == prospect.address
                })

                let contact: CNMutableContact
                let saveRequest = CNSaveRequest()

                if let existing = existing {
                    contact = existing.mutableCopy() as! CNMutableContact
                    saveRequest.update(contact)
                } else {
                    contact = CNMutableContact()
                    contact.givenName = prospect.fullName
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                }

                contact.phoneNumbers = prospect.contactPhone.isEmpty ? [] : [
                    CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: prospect.contactPhone))
                ]

                contact.emailAddresses = prospect.contactEmail.isEmpty ? [] : [
                    CNLabeledValue(label: CNLabelHome, value: NSString(string: prospect.contactEmail))
                ]

                let postal = CNMutablePostalAddress()
                postal.street = prospect.address
                contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postal)]

                try store.execute(saveRequest)
                showExportFeedback("Contact saved to Contacts.")
            } catch {
                showExportFeedback("Failed to save contact.")
            }
        }
    }
    
    private func showExportFeedback(_ message: String) {
        DispatchQueue.main.async {
            exportSuccessMessage = message
            withAnimation {
                showExportSuccessBanner = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showExportSuccessBanner = false
                }
            }
        }
    }
    
    // MARK: - Delete customer and their appointments
    private func deleteProspect() {
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }
        modelContext.delete(prospect)
        try? modelContext.save()
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.dismiss(animated: true)
            }
        }
    }
    
    private func deleteProspectAndAppointments() {
        // Delete all appointments linked to the prospect
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }

        // Now delete the prospect itself
        modelContext.delete(prospect)

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to delete prospect or appointments: \(error)")
        }

    }

    
}
