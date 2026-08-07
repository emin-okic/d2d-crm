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
    
    @State private var showEmailSheet = false
    
    private var phoneCallController: PhoneCallController {
        PhoneCallController(modelContext: controller.modelContext)
    }

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
        Button {
            ContactScreenHapticsController.shared.successConfirmationTap()
            ContactScreenSoundController.shared.playSound1()
            controller.confirmCustomerLost()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Mark Sale Lost")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Move this customer back into prospect follow-up.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.red)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)

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
        
        .sheet(isPresented: $controller.showCallSheet) {
            PhoneActionSheet(
                context: .customer(controller.customer),
                controller: phoneCallController,
                onCall: {
                    phoneCallController.call(
                        context: .customer(controller.customer)
                    )
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
        
        .sheet(isPresented: $showEmailSheet) {
            EmailActionSheet(
                context: .customer(controller.customer)
            )
            .environment(\.modelContext, controller.modelContext)
        }

    }
    
}
