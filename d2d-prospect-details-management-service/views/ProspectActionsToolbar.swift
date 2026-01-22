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

    @State private var showAddEmailSheet = false
    @State private var newEmail = ""
    @State private var showEmailConfirmation = false
    
    @State private var showCreateSaleSheet = false
    
    @State private var phoneError: String?
    
    // This variable is used for keeping track of the original phone # on changing it for note taking purposes
    @State private var originalPhone: String?
    
    private let customerController: CustomerController
    
    @State private var originalEmail: String?
    
    @State private var emailError: String?
    
    @State private var showEmailTemplates = false
    
    @State private var showCreateEmailTemplate = false
    
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

                // Email
                ContactDetailsActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .purple
                ) {
                    
                    // ✅ Haptic + sound
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    if prospect.contactEmail.nilIfEmpty == nil {
                        
                        originalEmail = nil
                        
                        showAddEmailSheet = true
                        
                    } else {
                        showEmailConfirmation = true
                    }
                }

                if prospect.list == "Prospects" {
                    ContactDetailsActionButton(
                        icon: "checkmark.seal.fill",
                        title: "Convert",
                        color: .green
                    ) {
                        
                        // ✅ Haptic + sound
                        ContactScreenHapticsController.shared.successConfirmationTap()
                        ContactScreenSoundController.shared.playSound1()
                        
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
                phone: PhoneValidator.formatted(prospect.contactPhone),
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
                
                // Haptic + sound
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                logEmailNote()

                showEmailTemplates = true
            }

            Button("Edit Email") {
                
                // Haptic + sound
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                originalEmail = prospect.contactEmail
                newEmail = prospect.contactEmail
                
                showAddEmailSheet = true
            }

            Button("Cancel", role: .cancel) { }
        }
        
        .sheet(isPresented: $showEmailTemplates) {
            EmailTemplatePickerSheet(
                controller: EmailTemplatesController(
                    modelContext: modelContext,
                    prospect: prospect
                ),
                onClose: { showEmailTemplates = false }
            )
        }
        .sheet(isPresented: $showCreateEmailTemplate, onDismiss: {
            showEmailTemplates = true
        }) {
            CreateEmailTemplateSheet()
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

        // Add email sheet (modern CRM style)
        .sheet(isPresented: $showAddEmailSheet) {
            VStack(spacing: 16) {

                // Drag indicator
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                // Header
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.purple)
                        .font(.title3)

                    Text("Email Address")
                        .font(.headline)
                }

                Text("Update or add the prospect’s email.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Input
                TextField("name@example.com", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: newEmail) { _ in _ = validateEmail() }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                
                if let emailError = emailError {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        
                        // Haptic + sound
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        
                        showAddEmailSheet = false
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)

                    Button("Save") {
                        
                        // Haptic + sound
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        
                        guard validateEmail() else { return }
                        
                        let previous = originalEmail
                        
                        prospect.contactEmail = newEmail
                        
                        try? modelContext.save()
                        
                        
                        logEmailChangeNote(old: previous, new: newEmail)
                        
                        showAddEmailSheet = false
                        
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emailError != nil
                    )
                }

                Spacer()
            }
            .padding()
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
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
    
    @discardableResult
    private func validateEmail() -> Bool {
        let raw = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            emailError = nil
            return true   // optional
        }

        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let isValid = raw.range(of: pattern, options: .regularExpression) != nil

        if isValid {
            emailError = nil
            return true
        } else {
            emailError = "Invalid email address."
            return false
        }
    }

    
}
