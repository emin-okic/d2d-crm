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
    
    @State private var showCreateSaleSheet = false
    
    @State private var phoneError: String?
    
    // This variable is used for keeping track of the original phone # on changing it for note taking purposes
    @State private var originalPhone: String?

    var body: some View {
        ZStack {
            HStack(spacing: 24) {
                
                // Phone
                actionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: .blue
                ) {
                    if prospect.contactPhone.isEmpty {
                        // Set the original phone number to nil for note taking purposes
                        originalPhone = nil
                        showAddPhoneSheet = true
                    } else {
                        showCallSheet = true
                    }
                }

                // Email
                actionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .purple
                ) {
                    if prospect.contactEmail.nilIfEmpty == nil {
                        showAddEmailSheet = true
                    } else {
                        showEmailConfirmation = true
                    }
                }

                if prospect.list == "Prospects" {
                    actionButton(
                        icon: "checkmark.seal.fill",
                        title: "Convert",
                        color: .green
                    ) {
                        showCreateSaleSheet = true
                    }
                }

            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .center)

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
    
    private func transferProspectData(to customer: Customer) {
        // Deep copy notes, knocks, appointments
        customer.notes = prospect.notes.map { Note(content: $0.content, date: $0.date) }
        customer.knockHistory = prospect.knockHistory.map {
            Knock(date: $0.date, status: $0.status, latitude: $0.latitude, longitude: $0.longitude)
        }
        
        for appt in prospect.appointments {
            appt.prospect = nil // break old link
            customer.appointments.append(appt)
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
    
    // MARK: - Modern CRM style button
    @ViewBuilder
    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(4)
        }
        .buttonStyle(.plain)
        .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: UUID())
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
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

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
        let customer = Customer.fromProspect(prospect)

        // overwrite with cloned data (safe)
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

    
}
