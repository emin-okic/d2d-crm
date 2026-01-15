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
                if let url = URL(string: "mailto:\(controller.customer.contactEmail)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Edit Email") {
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
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Email Address")
                        .font(.headline)

                    TextField("Enter email", text: $controller.newEmail)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    Button("Save Email") {
                        controller.saveEmail()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(controller.newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
                .navigationTitle("Email Address")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { controller.showAddEmailSheet = false }
                    }
                }
            }
        }
    }
    
}
