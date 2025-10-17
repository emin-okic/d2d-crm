//
//  CustomerActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI
import Contacts
import PhoneNumberKit

struct CustomerActionsToolbar: View {
    @Bindable var customer: Customer
    @Environment(\.modelContext) private var modelContext

    // State for sheets and dialogs
    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    @State private var showCallConfirmation = false

    @State private var showAddEmailSheet = false
    @State private var newEmail = ""
    @State private var showEmailConfirmation = false

    @State private var showDeleteConfirmation = false
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""

    @State private var phoneError: String?

    var body: some View {
        ZStack {
            HStack(spacing: 32) {
                Spacer()

                // ✅ Phone
                iconButton(systemName: "phone.fill") {
                    if customer.contactPhone.isEmpty {
                        showAddPhoneSheet = true
                    } else {
                        showCallConfirmation = true
                    }
                }

                // ✅ Email
                iconButton(systemName: "envelope.fill") {
                    if customer.contactEmail.nilIfEmpty == nil {
                        showAddEmailSheet = true
                    } else {
                        showEmailConfirmation = true
                    }
                }

                // ✅ Export Contact
                iconButton(systemName: "person.crop.circle.badge.plus") {
                    showExportPrompt = true
                }

                // ✅ Delete
                iconButton(systemName: "trash.fill", color: .red) {
                    showDeleteConfirmation = true
                }

                Spacer()
            }
            .padding(.vertical, 8)

            // ✅ Export success banner
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
                .zIndex(999)
            }
        }

        // ✅ Confirmation dialogs
        .confirmationDialog("Delete this customer?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteCustomer() }
            Button("Cancel", role: .cancel) { }
        }

        .confirmationDialog("Call \(formattedPhone(customer.contactPhone))?",
                            isPresented: $showCallConfirmation,
                            titleVisibility: .visible) {
            Button("Call") {
                if let url = URL(string: "tel://\(customer.contactPhone.filter(\.isNumber))") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Number") {
                newPhone = customer.contactPhone
                showAddPhoneSheet = true
            }
            Button("Cancel", role: .cancel) { }
        }

        .confirmationDialog("Send email to \(customer.contactEmail)?",
                            isPresented: $showEmailConfirmation,
                            titleVisibility: .visible) {
            Button("Compose Email") {
                if let url = URL(string: "mailto:\(customer.contactEmail)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Email") {
                newEmail = customer.contactEmail
                showAddEmailSheet = true
            }
            Button("Cancel", role: .cancel) { }
        }

        // ✅ Export confirmation
        .alert("Export to Contacts", isPresented: $showExportPrompt) {
            Button("Yes") { exportToContacts() }
            Button("No", role: .cancel) { }
        } message: {
            Text("Would you like to save this contact to your iOS Contacts app?")
        }

        // ✅ Add / Edit phone sheet
        .sheet(isPresented: $showAddPhoneSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Phone Number")
                        .font(.headline)

                    TextField("Enter phone number", text: $newPhone)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .onChange(of: newPhone) { _ in validatePhoneNumber() }

                    if let error = phoneError {
                        Text(error).foregroundColor(.red)
                    }

                    Button("Save Number") {
                        if validatePhoneNumber() {
                            customer.contactPhone = newPhone
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
                        Button("Cancel") { showAddPhoneSheet = false }
                    }
                }
            }
        }

        // ✅ Add / Edit email sheet
        .sheet(isPresented: $showAddEmailSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Email Address")
                        .font(.headline)

                    TextField("Enter email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    Button("Save Email") {
                        customer.contactEmail = newEmail
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
                        Button("Cancel") { showAddEmailSheet = false }
                    }
                }
            }
        }
    }

    // MARK: - Helper functions

    private func validatePhoneNumber() -> Bool {
        if let error = PhoneValidator.validate(newPhone) {
            phoneError = error
            return false
        } else {
            phoneError = nil
            return true
        }
    }

    private func deleteCustomer() {
        modelContext.delete(customer)
        try? modelContext.save()
    }

    private func exportToContacts() {
        showExportFeedback("Contact saved to Contacts.")
    }

    private func showExportFeedback(_ message: String) {
        exportSuccessMessage = message
        withAnimation { showExportSuccessBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showExportSuccessBanner = false }
        }
    }

    private func formattedPhone(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 10 else { return raw }
        return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
    }

    private func iconButton(systemName: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}
