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
    
    // Closure to dismiss the details view
    var onClose: (() -> Void)? = nil

    // State for sheets and dialogs
    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    @State private var showCallConfirmation = false

    @State private var showAddEmailSheet = false
    @State private var newEmail = ""
    @State private var showEmailConfirmation = false

    @State private var phoneError: String?
    
    // This is for the new call action workflow
    @State private var showCallSheet = false
    @State private var originalPhone: String?
    
    @State private var showCustomerLostConfirmation = false

    var body: some View {
        ZStack {
            HStack(spacing: 32) {
                Spacer()

                // ✅ Phone
                actionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: .blue
                ) {
                    if customer.contactPhone.isEmpty {
                        originalPhone = nil
                        showAddPhoneSheet = true
                    } else {
                        showCallSheet = true
                    }
                }

                // ✅ Email
                actionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .purple
                ) {
                    if customer.contactEmail.nilIfEmpty == nil {
                        showAddEmailSheet = true
                    } else {
                        showEmailConfirmation = true
                    }
                }
                
                // Customer Lost
                actionButton(
                    icon: "person.crop.circle.badge.xmark",
                    title: "Sale Lost",
                    color: .red
                ) {
                    showCustomerLostConfirmation = true
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .center)

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
        
        // New Phone Workflow
        .sheet(isPresented: $showCallSheet) {
            CallActionBottomSheet(
                phone: formattedPhone(customer.contactPhone),
                onCall: {
                    logCustomerCallNote()

                    if let url = URL(string: "tel://\(customer.contactPhone.filter(\.isNumber))") {
                        UIApplication.shared.open(url)
                    }

                    showCallSheet = false
                },
                onEdit: {
                    originalPhone = customer.contactPhone
                    newPhone = customer.contactPhone
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

        // ✅ Add / Edit phone sheet (detented)
        .sheet(isPresented: $showAddPhoneSheet) {
            AddPhoneBottomSheet(
                mode: originalPhone == nil ? .add : .edit,
                phone: $newPhone,
                error: $phoneError,
                onSave: {
                    if validatePhoneNumber() {
                        let previous = originalPhone
                        customer.contactPhone = newPhone
                        try? modelContext.save()

                        logCustomerPhoneChangeNote(old: previous, new: newPhone)

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
        .confirmationDialog(
            "Mark this customer as lost?",
            isPresented: $showCustomerLostConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes, mark as lost", role: .destructive) {
                convertCustomerToProspect(customer: customer)
                
                // Close the details view immediately
                onClose?()
            }
            Button("Cancel", role: .cancel) { }
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
    
    @MainActor
    private func convertCustomerToProspect(customer: Customer) {
        // 1️⃣ Create Prospect from Customer
        let prospect = Prospect(
            fullName: customer.fullName,
            address: customer.address,
            count: customer.knockCount,
            list: "Prospects"
        )
        
        // 2️⃣ Carry over details
        prospect.contactPhone = customer.contactPhone
        prospect.contactEmail = customer.contactEmail
        prospect.notes = customer.notes
        prospect.appointments = customer.appointments
        prospect.knockHistory = customer.knockHistory
        
        // 2.5 LOG THE STATE TRANSITION
        prospect.knockHistory.append(
            Knock(
                date: .now,
                status: "Customer Lost",
                latitude: prospect.latitude ?? customer.latitude ?? 0,
                longitude: prospect.longitude ?? customer.longitude ?? 0
            )
        )
        
        // 3️⃣ Preserve spatial identity
        prospect.latitude = customer.latitude
        prospect.longitude = customer.longitude
        
        // 4️⃣ Persist new Prospect
        modelContext.insert(prospect)
        
        // 5️⃣ Delete old Customer
        modelContext.delete(customer)
        
        // 6️⃣ Save context
        try? modelContext.save()
        
        // Optional: update UI / selection if needed
        // selectedList = "Prospects"
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

    // MARK: - Helper functions
    
    private func logCustomerCallNote() {
        let formatted = formattedPhone(customer.contactPhone)
        let content = "Called customer at \(formatted) on \(Date().formatted(date: .abbreviated, time: .shortened))."

        let note = Note(content: content, date: Date())
        customer.notes.append(note)

        try? modelContext.save()
    }
    
    private func logCustomerPhoneChangeNote(old: String?, new: String) {
        let oldNormalized = PhoneValidator.normalized(old)
        let newNormalized = PhoneValidator.normalized(new)

        // 🚫 Skip if unchanged
        guard oldNormalized != newNormalized else { return }

        let formattedNew = formattedPhone(new)

        let content: String
        if !oldNormalized.isEmpty {
            let formattedOld = formattedPhone(old ?? "")
            content = "Updated phone number from \(formattedOld) to \(formattedNew)."
        } else {
            content = "Added phone number \(formattedNew)."
        }

        let note = Note(content: content, date: Date())
        customer.notes.append(note)

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
