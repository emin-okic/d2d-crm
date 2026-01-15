//
//  CustomerDetailsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData
import MapKit
import Contacts

@available(iOS 18.0, *)
struct CustomerDetailsView: View {
    @Bindable var customer: Customer
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: CustomerDetailsTab = .appointments

    // Local editable copies
    @State private var tempFullName: String = ""
    @State private var tempAddress: String = ""

    // For address autocomplete
    @StateObject private var searchViewModel = SearchCompleterViewModel()
    @FocusState private var isAddressFieldFocused: Bool
    
    @State private var showDeleteConfirmation = false

    // Detect unsaved edits
    private var hasUnsavedEdits: Bool {
        tempFullName.trimmingCharacters(in: .whitespacesAndNewlines) != customer.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ||
        tempAddress.trimmingCharacters(in: .whitespacesAndNewlines) != customer.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @State private var showRevertConfirmation = false
    
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    @State private var showNotesSheet = false
    
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
                    Text("Customer Details")
                        .font(.largeTitle)
                        .bold()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                
                Section {
                    HStack(spacing: 12) {
                        CustomerDetailsScorecard(
                            title: "Meetings",
                            value: "\(customer.appointments.filter { $0.date >= Date() }.count)",
                            icon: "calendar.badge.clock",
                            color: .blue
                        ) {
                            
                            // ✅ Play haptic + sound when opening knocking history
                            ContactScreenHapticsController.shared.lightTap()
                            ContactScreenSoundController.shared.playSound1()
                            
                            showAppointmentsSheet = true
                            
                        }

                        CustomerDetailsScorecard(
                            title: "Knocks",
                            value: "\(customer.knockHistory.count)",
                            icon: "hand.tap.fill",
                            color: .orange
                        ) {
                            
                            // ✅ Play haptic + sound when opening knocking history
                            ContactScreenHapticsController.shared.lightTap()
                            ContactScreenSoundController.shared.playSound1()
                            
                            showKnocksSheet = true
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                .listRowBackground(Color.clear)
                
                Section() {
                    TextField("Full Name", text: $tempFullName)
                    
                    // 👇 Autocomplete-enabled address field
                    AddressAutocompleteField(
                        addressText: $tempAddress,
                        isFocused: $isAddressFieldFocused,
                        searchViewModel: searchViewModel
                    )
                }
                
                // ✅ Actions Toolbar
                Section {
                    CustomerActionsToolbar(
                        customer: customer,
                        onClose: { presentationMode.wrappedValue.dismiss() },
                        modelContext: modelContext
                    )
                }
                
            }
            
            CustomerFloatingActionsView(
                onDeleteTapped: {
                    
                    // Haptic + Sound for Trash button
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    showDeleteConfirmation = true
                    
                },
                onNotesTapped: {
                    
                    // Haptic + Sound for Trash button
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    showNotesSheet = true
                    
                }
            )
            
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $showNotesSheet) {
                
                CustomerNotesThreadFullView(customer: customer)
                    .onAppear {
                        // Haptic + Sound on sheet appear
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                    }
                
            }
            .sheet(isPresented: $showAppointmentsSheet) {
                NavigationStack {
                    CustomerAppointmentsView(
                        customer: customer
                    )
                    // .navigationTitle("Upcoming Meetings")
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showKnocksSheet) {
                NavigationStack {
                    CustomerKnockingHistoryView(customer: customer)
                        .navigationTitle("Knocking History")
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                
                DeleteCustomerSheet(
                    customerName: customer.fullName,
                    onDelete: deleteCustomer
                )
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
                .onAppear {
                    // Haptic + Sound on sheet appear
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                }
            }
            
        }
        .toolbar {
            // Back Button
            ToolbarItem(placement: .navigationBarLeading) {
                
                Button {
                    
                    // ✅ Play haptic + sound when closing the details screen
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    // Then dismiss the screen
                    presentationMode.wrappedValue.dismiss()
                    
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
            }
            
            if !hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    Button {
                        
                        // ⚡ Haptic + Sound when tapping export
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        showExportPrompt = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                }
            }

            // Revert + Save (only when editing)
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
                        
                        // ⚡ Haptic + Sound when tapping export
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        commitEdits()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
        }
        .alert("Export to Contacts", isPresented: $showExportPrompt) {
            Button("Yes") {
                
                // ⚡ Haptic + Sound when confirming export
                ContactScreenHapticsController.shared.successConfirmationTap()
                ContactScreenSoundController.shared.playSound1()
                
                exportToContacts()
            }
            Button("Cancel", role: .cancel) {
                
                // ⚡ Haptic + Sound when confirming export
                ContactScreenHapticsController.shared.successConfirmationTap()
                ContactScreenSoundController.shared.playSound1()
                
            }
        } message: {
            Text("Would you like to save this contact to your iOS Contacts app?")
        }
        .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
            Button("Revert Changes", role: .destructive) {
                
                // ⚡ Haptic + Sound when confirming export
                ContactScreenHapticsController.shared.successConfirmationTap()
                ContactScreenSoundController.shared.playSound1()
                
                revertEdits()
            }
            Button("Cancel", role: .cancel) {
                
                // ⚡ Haptic + Sound when confirming export
                ContactScreenHapticsController.shared.successConfirmationTap()
                ContactScreenSoundController.shared.playSound1()
                
            }
        } message: {
            Text("This will discard all unsaved changes and restore the original customer details.")
        }
        .onAppear {
            tempFullName = customer.fullName
            tempAddress = customer.address
        }
    }
    
    private func exportToContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                showExportFeedback("Contacts access denied.")
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: customer.fullName)
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
                    $0.postalAddresses.first?.value.street == customer.address
                }

                let contact: CNMutableContact
                let saveRequest = CNSaveRequest()

                if let existing = existing {
                    contact = existing.mutableCopy() as! CNMutableContact
                    saveRequest.update(contact)
                } else {
                    contact = CNMutableContact()
                    contact.givenName = customer.fullName
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                }

                if !customer.contactPhone.isEmpty {
                    contact.phoneNumbers = [
                        CNLabeledValue(
                            label: CNLabelPhoneNumberMobile,
                            value: CNPhoneNumber(stringValue: customer.contactPhone)
                        )
                    ]
                }

                if !customer.contactEmail.isEmpty {
                    contact.emailAddresses = [
                        CNLabeledValue(
                            label: CNLabelHome,
                            value: NSString(string: customer.contactEmail)
                        )
                    ]
                }

                let postal = CNMutablePostalAddress()
                postal.street = customer.address
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
            tempFullName = customer.fullName
            tempAddress = customer.address
            isAddressFieldFocused = false
        }
    }
    
    private func deleteCustomer() {
        // ✅ Delete all appointments belonging to this customer
        for appointment in customer.appointments {
            modelContext.delete(appointment)
        }

        // ✅ Delete the customer itself
        modelContext.delete(customer)
        try? modelContext.save()

        // ✅ Dismiss the details view
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.dismiss(animated: true)
            }
        }
    }

    // MARK: - Logic
    private func commitEdits() {
        
        let trimmedName = tempFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = tempAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var changeNotes: [String] = []

        if trimmedName != customer.fullName {
            let note = "Name changed from \(customer.fullName.isEmpty ? "Unknown" : customer.fullName) to \(trimmedName)."
            changeNotes.append(note)
            customer.fullName = trimmedName
        }

        // Address change
        if trimmedAddress != customer.address {
            let note = "Address changed from \(customer.address.isEmpty ? "Unknown" : customer.address) to \(trimmedAddress)."
            changeNotes.append(note)
            customer.address = trimmedAddress

            // ✅ Re-geocode address
            CLGeocoder().geocodeAddressString(trimmedAddress) { placemarks, error in
                if let coord = placemarks?.first?.location?.coordinate {
                    customer.latitude = coord.latitude
                    customer.longitude = coord.longitude

                    print("📍 Updated customer coordinates:")
                    print("   → Latitude: \(coord.latitude)")
                    print("   → Longitude: \(coord.longitude)")
                } else {
                    print("❌ Failed to geocode customer address:")
                    print("   → \(error?.localizedDescription ?? "Unknown error")")
                }

                // Save AFTER geocoding
                saveCustomer(changeNotes: changeNotes)
            }
        } else {
            // No address change → save immediately
            saveCustomer(changeNotes: changeNotes)
        }

    }
    
    /// This replaces modelContext.save() with an async approach for geocoding lat/long coordinates
    private func saveCustomer(changeNotes: [String]) {
        for note in changeNotes {
            customer.notes.append(
                Note(content: note, date: Date())
            )
        }

        do {
            try modelContext.save()
            print("✅ Customer saved successfully")
        } catch {
            print("❌ Failed to save customer: \(error)")
        }
    }

}
