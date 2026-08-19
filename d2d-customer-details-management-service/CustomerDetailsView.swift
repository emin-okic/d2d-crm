//
//  CustomerDetailsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData
import MapKit
@preconcurrency import Contacts

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
    
    @State private var showContactExportOptions = false
    @State private var showExportPrompt = false
    @State private var contactSharePayload: ContactSharePayload?
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    @State private var showNotesSheet = false
    
    @State private var showAppointmentsSheet = false
    @State private var showKnocksSheet = false
    @State private var showDemographicsSheet = false
    @State private var demographicsSheetDetent: PresentationDetent = .fraction(0.68)

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
                    DetailsScorecardCustomizationView(
                        storagePrefix: "customerDetails",
                        items: customerScorecardItems
                    )
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
                
                Section {
                    DemographicsSummaryRow(summary: customer.demographicsSummary) {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        showDemographicsSheet = true
                    }
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
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showNotesSheet) {
            CustomerNotesThreadFullView(customer: customer)
                .onAppear {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                }
        }
        .sheet(isPresented: $showAppointmentsSheet) {
            NavigationStack {
                CustomerAppointmentsView(
                    customer: customer
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
            }
        }
        .sheet(isPresented: $showDemographicsSheet) {
            DemographicsEditorView(
                title: "Customer Demographics",
                initialData: customer.demographicsFormData,
                onSave: { data in
                    let oldData = customer.demographicsFormData
                    customer.applyDemographics(data)
                    if let noteContent = customer.companyInfoChangeNote(from: oldData, to: data) {
                        customer.notes.append(Note(content: noteContent, date: Date()))
                    }
                    try? modelContext.save()
                    showDemographicsSheet = false
                },
                onCancel: {
                    showDemographicsSheet = false
                },
                onExpandedContentChange: { isExpanded in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        demographicsSheetDetent = isExpanded ? .large : .fraction(0.68)
                    }
                }
            )
            .presentationDetents([.fraction(0.68), .large], selection: $demographicsSheetDetent)
            .presentationDragIndicator(.visible)
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
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        showNotesSheet = true
                    } label: {
                        Image(systemName: "note.text")
                    }

                    Button(role: .destructive) {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }

                    Button {
                        
                        // ⚡ Haptic + Sound when tapping export
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        showContactExportOptions = true
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
        .sheet(isPresented: $showContactExportOptions) {
            ContactExportOptionsSheet(
                contactName: customer.fullName,
                onSaveToContacts: {
                    showContactExportOptions = false
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    showExportPromptAfterOptionsDismiss()
                },
                onShareContact: {
                    showContactExportOptions = false
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    shareCustomerAfterOptionsDismiss()
                },
                onCancel: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showContactExportOptions = false
                }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExportPrompt) {
            ContactExportConfirmationSheet(
                contactName: customer.fullName,
                onConfirm: {
                    showExportPrompt = false
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    exportToContacts()
                },
                onCancel: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showExportPrompt = false
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $contactSharePayload) { payload in
            ShareSheet(activityItems: [payload.message])
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
    
    private var customerScorecardItems: [DetailsScorecardItem] {
        [
            DetailsScorecardItem(
                kind: .meetings,
                title: "Meetings",
                value: "\(customer.appointments.filter { $0.date >= Date() }.count)",
                icon: "calendar.badge.clock",
                color: .blue,
                action: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showAppointmentsSheet = true
                }
            ),
            DetailsScorecardItem(
                kind: .knocks,
                title: "Knocks",
                value: "\(customer.knockHistory.count)",
                icon: "hand.tap.fill",
                color: .orange,
                action: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showKnocksSheet = true
                }
            )
        ]
    }

    private func showExportPromptAfterOptionsDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showExportPrompt = true
        }
    }

    private func shareCustomerAfterOptionsDismiss() {
        let fullName = customer.fullName
        let address = customer.address
        let phone = customer.contactPhone
        let email = customer.contactEmail

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            contactSharePayload = ContactSharePresenter.payload(
                fullName: fullName,
                address: address,
                phone: phone,
                email: email
            )
        }
    }

    private func exportToContacts() {
        let store = CNContactStore()
        
        // ✅ Capture immutable snapshots for thread-safe access
        let customerFullName = customer.fullName
        let customerAddress = customer.address
        let customerPhone = customer.contactPhone
        let customerEmail = customer.contactEmail
        
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                Task { @MainActor in
                    showExportFeedback("Contacts access denied.")
                }
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: customerFullName)
            
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
                    $0.postalAddresses.first?.value.street == customerAddress
                }

                let contact: CNMutableContact
                let saveRequest = CNSaveRequest()

                if let existing = existing {
                    contact = existing.mutableCopy() as! CNMutableContact
                    saveRequest.update(contact)
                } else {
                    contact = CNMutableContact()
                    contact.givenName = customerFullName
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                }

                if !customerPhone.isEmpty {
                    contact.phoneNumbers = [
                        CNLabeledValue(
                            label: CNLabelPhoneNumberMobile,
                            value: CNPhoneNumber(stringValue: customerPhone)
                        )
                    ]
                }

                if !customerEmail.isEmpty {
                    contact.emailAddresses = [
                        CNLabeledValue(
                            label: CNLabelHome,
                            value: NSString(string: customerEmail)
                        )
                    ]
                }

                let postal = CNMutablePostalAddress()
                postal.street = customerAddress
                contact.postalAddresses = [
                    CNLabeledValue(label: CNLabelHome, value: postal)
                ]

                try store.execute(saveRequest)

                Task { @MainActor in
                    showExportFeedback("Contact saved to Contacts.")
                }

            } catch {
                Task { @MainActor in
                    showExportFeedback("Failed to save contact.")
                }
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

            // Use iOS 26+ non-deprecated APIs
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmedAddress
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                
                if let firstItem = response?.mapItems.first {
                    let location = firstItem.location
                    customer.latitude = location.coordinate.latitude
                    customer.longitude = location.coordinate.longitude
                    
                    print("📍 Updated customer coordinates:")
                    print("   → Latitude: \(location.coordinate.latitude)")
                    print("   → Longitude: \(location.coordinate.longitude)")
                } else {
                    print("❌ Failed to geocode customer address: \(error?.localizedDescription ?? "Unknown error")")
                }

                // Save AFTER geocoding
                saveCustomer(changeNotes: changeNotes)
            }
        } else {
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
