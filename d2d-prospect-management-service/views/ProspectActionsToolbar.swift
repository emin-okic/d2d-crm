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
                    if prospect.contactEmail.nilIfEmpty == nil {
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
    
    /// This function is intended to log call activity for prospects
    private func logCallNote() {
        
        let formatted = PhoneValidator.formatted(prospect.contactPhone)
        
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
