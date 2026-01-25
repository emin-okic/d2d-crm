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
    
    @State private var showCreateSaleSheet = false
    
    @State private var phoneError: String?
    
    // This variable is used for keeping track of the original phone # on changing it for note taking purposes
    @State private var originalPhone: String?
    
    private let customerController: CustomerController
    
    @State private var showEmailSheet = false
    
    private let actions: ProspectActionsController
    
    init(prospect: Prospect, modelContext: ModelContext) {
        self._prospect = Bindable(prospect)
        self.customerController = CustomerController(modelContext: modelContext)
        self.actions = ProspectActionsController(
            prospect: prospect,
            modelContext: modelContext
        )
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

                ContactDetailsActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .purple
                ) {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    showEmailSheet = true
                    
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
                    actions.logCall()
                    actions.callPhone()
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

        // Convert to Customer sheet using common stepper form
        .sheet(isPresented: $showCreateSaleSheet) {
            NavigationStack {
                CustomerCreateStepperView(
                    initialName: prospect.fullName,
                    initialAddress: prospect.address,
                    initialPhone: prospect.contactPhone,
                    initialEmail: prospect.contactEmail,
                    onComplete: { newCustomer in
                        actions.convertToCustomer(newCustomer)
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
                    if let error = actions.validatePhone(newPhone) {
                        phoneError = error
                        return
                    }

                    actions.savePhoneChange(old: originalPhone, new: newPhone)
                    actions.callPhone()
                    showAddPhoneSheet = false
                },
                onCancel: {
                    showAddPhoneSheet = false
                }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }
        
        .sheet(isPresented: $showEmailSheet) {
            EmailActionSheet(
                context: .prospect(prospect)
            )
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
    
    /// Logs when an email is composed
    private func logEmailNote() {
        let content = "Composed email to \(prospect.contactEmail) on \(Date().formatted(date: .abbreviated, time: .shortened))."
        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)
        try? modelContext.save()
    }
    
}
