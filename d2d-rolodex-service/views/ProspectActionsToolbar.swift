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

    var body: some View {
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
                exportToContacts()
            }
            
            // Delete Contact
            iconButton(systemName: "trash.fill", color: .red) {
                showDeleteConfirmation = true
            }
        }
        .padding(.vertical, 8)
        
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
            Button("Cancel", role: .cancel) { }
        }
        
        // Sign Up Sheet
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
                            prospect.list = "Customers"
                            try? modelContext.save()
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
        .sheet(isPresented: $showCreateSaleSheet) {
            CreateSaleView(
                fullName: $prospect.fullName,
                address: $prospect.address,
                contactPhone: $prospect.contactPhone,
                contactEmail: $prospect.contactEmail,
                onConfirm: {
                    prospect.list = "Customers"
                    try? modelContext.save()
                    showCreateSaleSheet = false
                },
                onCancel: {
                    showCreateSaleSheet = false
                }
            )
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

                    Button("Save & Compose") {
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
        
        // Add Phone Validation
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

                    Button("Save & Call") {
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
        let contact = CNMutableContact()
        contact.givenName = prospect.fullName

        if !prospect.contactPhone.isEmpty {
            contact.phoneNumbers = [CNLabeledValue(
                label: CNLabelPhoneNumberMobile,
                value: CNPhoneNumber(stringValue: prospect.contactPhone)
            )]
        }

        if !prospect.contactEmail.isEmpty {
            contact.emailAddresses = [CNLabeledValue(
                label: CNLabelHome,
                value: NSString(string: prospect.contactEmail)
            )]
        }

        let postal = CNMutablePostalAddress()
        postal.street = prospect.address
        contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postal)]

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                print("❌ Access to contacts denied")
                return
            }

            do {
                try store.execute(saveRequest)
                print("✅ Contact saved")
            } catch {
                print("❌ Failed to save contact: \(error)")
            }
        }
    }
    
    private func deleteProspect() {
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
            print("❌ Failed to delete contact: \(error)")
        }
    }
}
