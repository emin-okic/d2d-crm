//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import Contacts

struct ProspectDetailsView: View {
    @Bindable var prospect: Prospect
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    @StateObject private var controller = ProspectDetailsController()
    
    @StateObject private var searchViewModel = SearchCompleterViewModel()
    @FocusState private var isAddressFieldFocused: Bool

    // 🔑 Local editable copies for deferred saving
    @State private var tempFullName: String = ""
    @State private var tempAddress: String = ""
    
    @State private var showDeleteConfirmation = false
    
    @State private var showRevertConfirmation = false
    
    @State private var actionsToolbarProxy: ProspectActionsToolbar?
    
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    @State private var showAppointmentsSheet = false
    @State private var showKnocksSheet = false

    var body: some View {
        ZStack {
            
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
                .zIndex(1000)
            }
            
            Form {
                Section {
                    Text("Prospect Details")
                        .font(.largeTitle)
                        .bold()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                
                Section {
                    HStack(spacing: 12) {
                        ProspectScorecard(
                            title: "Meetings",
                            value: "\(prospect.appointments.filter { $0.date >= Date() }.count)",
                            icon: "calendar.badge.clock",
                            color: .blue
                        ) {
                            
                            // ✅ Play haptic + sound when opening knocking history
                            ContactDetailsHapticsController.shared.mapTap()
                            ContactScreenSoundController.shared.playPropertyOpen()
                            
                            showAppointmentsSheet = true
                            
                        }

                        ProspectScorecard(
                            title: "Knocks",
                            value: "\(prospect.knockHistory.count)",
                            icon: "hand.tap.fill",
                            color: .orange
                        ) {
                            
                            // ✅ Play haptic + sound when opening knocking history
                            ContactDetailsHapticsController.shared.mapTap()
                            ContactScreenSoundController.shared.playPropertyOpen()
                            
                            showKnocksSheet = true
                        }
                    }
                    .padding(.horizontal, 10) // ← give horizontal breathing room
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                .listRowBackground(Color.clear)
                
                // Prospect info
                Section() {
                    TextField("Full Name", text: $tempFullName)
                    
                    // Address with autocomplete
                    AddressAutocompleteField(
                        addressText: $tempAddress,
                        isFocused: $isAddressFieldFocused,
                        searchViewModel: searchViewModel
                    )
                }
                
                // ✅ Actions Toolbar (unchanged)
                Section {
                    ProspectActionsToolbar(
                        prospect: prospect,
                        modelContext: modelContext
                    )
                }
                
            }
            
            // Bottom floating buttons
            ProspectFloatingActionsView(
                onDeleteTapped: {
                    showDeleteConfirmation = true
                },
                onNotesTapped: {
                    controller.showNotesSheet = true
                }
            )
            .sheet(isPresented: $showDeleteConfirmation) {
                
                DeleteProspectSheet(
                    prospectName: prospect.fullName,
                    onDelete: {
                        controller.deleteProspect(prospect, modelContext: modelContext)
                    }
                )
                .presentationDetents([.fraction(0.25)])
                .presentationDragIndicator(.visible)
            }

            .sheet(isPresented: $controller.showNotesSheet) {
                NotesThreadFullView(prospect: prospect)
            }
        }
        // .navigationTitle("Edit Contact")
        .toolbar {
            // Back Button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    
                    // ✅ Play haptic + sound when closing the details screen
                    ContactDetailsHapticsController.shared.propertyAdded()
                    ContactScreenSoundController.shared.playPropertyAdded()
                    
                    // Then dismiss the screen
                    presentationMode.wrappedValue.dismiss()
                    
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
            }
            
            // Export + Share (hidden while editing)
            if !hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    // ✅ Export to Contacts
                    Button {
                        
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        showExportPrompt = true
                        
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }

                    // Share
                    Button {
                        
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        controller.shareProspect(prospect)
                        
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }

            // Save Button (only appears if name/address changed)
            if hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                    // Revert button
                    Button {
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        showRevertConfirmation = true
                    } label: {
                        Image(systemName: "arrow.uturn.backward") // ⬅ curved backward arrow
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }

                    Button("Save") {
                        
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.successFeedbackConfirmation()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        withAnimation(.easeInOut(duration: 0.25)) {
                            commitEdits()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
        }
        .alert("Export to Contacts", isPresented: $showExportPrompt) {
            Button("Yes") {
                
                // ⚡ Haptics & Sound when confirming export
                ContactDetailsHapticsController.shared.propertyAdded()
                ContactScreenSoundController.shared.playPropertyAdded()
                
                exportToContacts()
                
            }
            Button("Cancel", role: .cancel) {
                
                // ⚡ Optional subtle feedback on cancel
                ContactDetailsHapticsController.shared.mapTap()
                ContactScreenSoundController.shared.playPropertyOpen()
                
            }
            
        } message: {
            Text("Would you like to save this contact to your iOS Contacts app?")
        }
        .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
            Button("Revert Changes", role: .destructive) {
                
                // ⚡ Subtle feedback on cancel
                ContactDetailsHapticsController.shared.mapTap()
                ContactScreenSoundController.shared.playPropertyOpen()
                
                revertEdits()
            }
            Button("Cancel", role: .cancel) {
                
                // ⚡ Subtle feedback on cancel
                ContactDetailsHapticsController.shared.mapTap()
                ContactScreenSoundController.shared.playPropertyOpen()
                
            }
        } message: {
            Text("This will discard all unsaved changes and restore the original prospect details.")
        }
        .onAppear {
            controller.captureBaseline(from: prospect)
            // Initialize local edit copies
            tempFullName = prospect.fullName
            tempAddress = prospect.address
        }
        .sheet(isPresented: $showAppointmentsSheet) {
            NavigationStack {
                ProspectAppointmentsView(
                    prospect: prospect,
                    controller: controller
                )
                // .navigationTitle("Upcoming Meetings")
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showKnocksSheet) {
            NavigationStack {
                ProspectKnockingHistoryView(prospect: prospect)
                    .navigationTitle("Knocking History")
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $controller.showConversionSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Confirm Customer Info")) {
                        TextField("Full Name", text: $prospect.fullName)
                        TextField("Address", text: $prospect.address)
                        TextField("Phone", text: $controller.tempPhone)
                        TextField("Email", text: $controller.tempEmail)
                    }
                    Section {
                        Button("Confirm Sign Up") {
                            controller.convertToCustomer(prospect, modelContext: modelContext)
                            controller.showConversionSheet = false
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(prospect.fullName.isEmpty || prospect.address.isEmpty)
                    }
                }
                .navigationTitle("Convert to Customer")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { controller.showConversionSheet = false }
                    }
                }
            }
        }
    }
    
    private func exportToContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                showExportFeedback("Contacts access denied.")
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: prospect.fullName)
            
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor
            ]

            do {
                let matches = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                let existing = matches.first {
                    $0.postalAddresses.first?.value.street == prospect.address
                }

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

                if !prospect.contactPhone.isEmpty {
                    contact.phoneNumbers = [
                        CNLabeledValue(
                            label: CNLabelPhoneNumberMobile,
                            value: CNPhoneNumber(stringValue: prospect.contactPhone)
                        )
                    ]
                }

                if !prospect.contactEmail.isEmpty {
                    contact.emailAddresses = [
                        CNLabeledValue(
                            label: CNLabelHome,
                            value: NSString(string: prospect.contactEmail)
                        )
                    ]
                }

                let postal = CNMutablePostalAddress()
                postal.street = prospect.address
                contact.postalAddresses = [
                    CNLabeledValue(label: CNLabelHome, value: postal)
                ]

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
    
    private func revertEdits() {
        withAnimation(.easeInOut(duration: 0.2)) {
            tempFullName = prospect.fullName
            tempAddress = prospect.address
            isAddressFieldFocused = false
        }
    }

    // MARK: - Logic
    private var hasUnsavedEdits: Bool {
        tempFullName.trimmingCharacters(in: .whitespacesAndNewlines) != prospect.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ||
        tempAddress.trimmingCharacters(in: .whitespacesAndNewlines) != prospect.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commitEdits() {
        let trimmedName = tempFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = tempAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        var changeNotes: [String] = []

        // Detect name change
        if trimmedName != prospect.fullName {
            let note = "Name changed from \(prospect.fullName.isEmpty ? "Unknown" : prospect.fullName) to \(trimmedName)."
            changeNotes.append(note)
            prospect.fullName = trimmedName
        }

        // Detect address change
        if trimmedAddress != prospect.address {
            let note = "Address changed from \(prospect.address.isEmpty ? "Unknown" : prospect.address) to \(trimmedAddress)."
            changeNotes.append(note)
            prospect.address = trimmedAddress

            // ✅ Geocode the new address to update latitude/longitude
            CLGeocoder().geocodeAddressString(trimmedAddress) { placemarks, error in
                if let coord = placemarks?.first?.location?.coordinate {
                    prospect.latitude = coord.latitude
                    prospect.longitude = coord.longitude
                    print("📍 Updated prospect coordinates: \(coord.latitude), \(coord.longitude)")
                } else {
                    print("❌ Failed to geocode address: \(error?.localizedDescription ?? "Unknown error")")
                }

                // Save prospect + notes after geocoding
                controller.saveProspect(prospect, modelContext: modelContext)
            }
        } else {
            // Save immediately if only the name changed
            controller.saveProspect(prospect, modelContext: modelContext)
        }

        // Append automatic notes (if any)
        for change in changeNotes {
            let autoNote = Note(content: change, date: Date(), prospect: prospect)
            prospect.notes.append(autoNote)
        }
    }
    
}
