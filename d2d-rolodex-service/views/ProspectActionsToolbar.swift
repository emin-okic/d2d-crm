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
    @State private var showCallConfirmation = false

    @State private var showAddEmailSheet = false
    @State private var newEmail = ""
    @State private var showEmailConfirmation = false
    
    @State private var showDeleteConfirmation = false
    
    @State private var showCreateSaleSheet = false
    
    @State private var phoneError: String?
    
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            HStack(spacing: 24) {
                // Phone
                iconButton(systemName: "phone.fill") {
                    if prospect.contactPhone.isEmpty {
                        showAddPhoneSheet = true
                    } else {
                        showCallConfirmation = true
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
                    iconButton(systemName: "cart.fill.badge.plus") {
                        showCreateSaleSheet = true
                    }
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
        .confirmationDialog(
            "Call \(formattedPhone(prospect.contactPhone))?",
            isPresented: $showCallConfirmation,
            titleVisibility: .visible
        ) {
            Button("Call") {
                if let url = URL(string: "tel://\(prospect.contactPhone.filter(\.isNumber))") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Number") {
                newPhone = prospect.contactPhone // Pre-fill current value
                showAddPhoneSheet = true
            }
            Button("Cancel", role: .cancel) { }
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
            CreateSaleView(prospect: prospect, isPresented: $showCreateSaleSheet)
        }

        // Add phone sheet
        .sheet(isPresented: $showAddPhoneSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Phone Number")
                        .font(.headline)

                    TextField("Enter phone number", text: $newPhone)
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .onChange(of: newPhone) { _ in
                            validatePhoneNumber()
                        }

                    if let error = phoneError {
                        Text(error)
                            .foregroundColor(.red)
                    }

                    Button("Save Number") {
                        if validatePhoneNumber() {
                            prospect.contactPhone = newPhone
                            try? modelContext.save()

                            if let url = URL(string: "tel://\(newPhone.filter(\.isNumber))") {
                                UIApplication.shared.open(url)
                            }

                            showAddPhoneSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
                .navigationTitle("Phone Number")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddPhoneSheet = false
                        }
                    }
                }
            }
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
    
    private func validatePhoneNumber() -> Bool {
        let raw = newPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            phoneError = nil
            return true
        }

        let utility = PhoneNumberUtility()

        do {
            _ = try utility.parse(raw)
            phoneError = nil
            return true
        } catch {
            phoneError = "Invalid phone number."
            return false
        }
    }

    private func iconButton(systemName: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(Color.clear)
                .clipShape(Circle())
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
    
    private func deleteProspect() {
        deleteProspectAndAppointments()

        do {
            try modelContext.save()
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.dismiss(animated: true)
                }
            }
        } catch {
            print("❌ Failed to delete contact: \(error)")
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
