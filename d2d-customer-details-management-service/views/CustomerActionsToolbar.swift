//
//  CustomerActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI
import SwiftData

struct CustomerActionsToolbar: View {
    
    @StateObject private var controller: CustomerActionsController

    init(customer: Customer, onClose: (() -> Void)? = nil, modelContext: ModelContext) {
        _controller = StateObject(
            wrappedValue: CustomerActionsController(
                customer: customer,
                modelContext: modelContext,
                onClose: onClose
            )
        )
    }

    var body: some View {
        ZStack {
            HStack(spacing: 32) {
                Spacer()

                ContactDetailsActionButton(icon: "phone.fill", title: "Call", color: .blue) {
                    
                    // ✅ Haptic + sound
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    controller.callTapped()
                }

                ContactDetailsActionButton(icon: "envelope.fill", title: "Email", color: .purple) {
                    
                    // ✅ Haptic + sound
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    controller.emailTapped()
                }

                ContactDetailsActionButton(icon: "person.crop.circle.badge.xmark", title: "Sale Lost", color: .red) {
                    
                    // ✅ Haptic + sound
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    controller.confirmCustomerLost()
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .center)

        }

        .confirmationDialog("Call \(PhoneValidator.formatted(controller.customer.contactPhone))?",
                            isPresented: $controller.showCallConfirmation,
                            titleVisibility: .visible) {
            Button("Call") {
                if let url = URL(string: "tel://\(controller.customer.contactPhone.filter(\.isNumber))") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Number") {
                controller.newPhone = controller.customer.contactPhone
                controller.showAddPhoneSheet = true
            }
            Button("Cancel", role: .cancel) {}
        }

        .confirmationDialog("Send email to \(controller.customer.contactEmail)?",
                            isPresented: $controller.showEmailConfirmation,
                            titleVisibility: .visible) {
            Button("Compose Email") {
                
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                controller.logCustomerEmailNote()   // ✅ log it

                if let url = URL(string: "mailto:\(controller.customer.contactEmail)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Email") {
                
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                
                controller.originalEmail = controller.customer.contactEmail
                
                controller.newEmail = controller.customer.contactEmail
                
                controller.showAddEmailSheet = true
            }
            Button("Cancel", role: .cancel) { }
        }
        
        .sheet(isPresented: $controller.showCallSheet) {
            CallActionBottomSheet(
                phone: PhoneValidator.formatted(controller.customer.contactPhone),
                onCall: {
                    controller.logCustomerCallNote()
                    if let url = URL(string: "tel://\(controller.customer.contactPhone.filter(\.isNumber))") {
                        UIApplication.shared.open(url)
                    }
                    controller.showCallSheet = false
                },
                onEdit: {
                    controller.originalPhone = controller.customer.contactPhone
                    controller.newPhone = controller.customer.contactPhone
                    controller.showCallSheet = false
                    controller.showAddPhoneSheet = true
                },
                onCancel: {
                    controller.showCallSheet = false
                }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }

        .sheet(isPresented: $controller.showAddPhoneSheet) {
            AddPhoneBottomSheet(
                mode: controller.originalPhone == nil ? .add : .edit,
                phone: $controller.newPhone,
                error: $controller.phoneError,
                onSave: {
                    if controller.validatePhoneNumber() {
                        let previous = controller.originalPhone
                        controller.customer.contactPhone = controller.newPhone
                        try? controller.modelContext.save()

                        controller.logCustomerPhoneChangeNote(old: previous, new: controller.newPhone)

                        if let url = URL(string: "tel://\(controller.newPhone.filter(\.isNumber))") {
                            UIApplication.shared.open(url)
                        }

                        controller.showAddPhoneSheet = false
                    }
                },
                onCancel: {
                    controller.showAddPhoneSheet = false
                }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }
        
        .confirmationDialog(
            "Mark this customer as lost?",
            isPresented: $controller.showCustomerLostConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes, mark as lost", role: .destructive) {
                controller.markCustomerLost()

            }
            Button("Cancel", role: .cancel) { }
        }

        .sheet(isPresented: $controller.showAddEmailSheet) {
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

                Text("Update or add the customer’s email.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("name@example.com", text: $controller.newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: controller.newEmail) { _ in
                        _ = controller.validateEmail()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                
                if let error = controller.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Actions
                HStack(spacing: 12) {
                    Button("Cancel") {

                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()

                        controller.showAddEmailSheet = false
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)

                    Button("Save") {

                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()

                        controller.saveEmail()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        controller.newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        controller.emailError != nil
                    )
                }

                Spacer()
            }
            .padding()
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }
    }
    
}
